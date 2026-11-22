import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/variable.dart';
import '../../../web/common method/Commmon_Method.dart' as common;

import '../../../web/common method/communicationcommonmethod.dart';
import '../../../web/communi_services/services.dart';
import 'chat_screen_getx.dart';

// Kept so any old file that imported it from here still compiles.
DateTime? parseServerTime(String? raw) => MsgParseTime(raw);

// =============================================================================
// ONE BUBBLE: a message from the server, or one that is still being sent.
// =============================================================================
enum MsgSendState { sending, sent, failed }

class MsgItem {
  const MsgItem({
    required this.chatId, // 0 = not saved yet (sending / failed)
    required this.clientId,
    required this.text,
    required this.time,
    required this.senderNumber,
    this.isRead = false,
    this.state = MsgSendState.sent,
  });

  final int chatId;
  final String clientId;
  final String text;
  final DateTime time;
  final int senderNumber;
  final bool isRead;
  final MsgSendState state;

  bool get isPending => chatId == 0;

  factory MsgItem.fromServer(MsgMessage m) {
    return MsgItem(
      chatId: m.chatId,
      clientId: m.clientId,
      text: m.message,
      time: m.time ?? DateTime.now(),
      senderNumber: m.senderNumber,
      isRead: m.isRead,
      state: MsgSendState.sent,
    );
  }

  MsgItem copyWith({bool? isRead, MsgSendState? state}) {
    return MsgItem(
      chatId: chatId,
      clientId: clientId,
      text: text,
      time: time,
      senderNumber: senderNumber,
      isRead: isRead ?? this.isRead,
      state: state ?? this.state,
    );
  }
}

// =============================================================================
// MESSAGE SCREEN GETX (one per open chat)
//
//  - newest 30 messages first, older ones load when you scroll up
//  - messages arrive live over SignalR; the chat is marked read while open
//  - a sent message shows at once (clock), then a tick, then a blue double
//    tick when the other person has read it; a failed one can be retried
//  - after a reconnect the newest page is fetched again, so nothing is missed
//
// Video calls are in VideoCallGetx (own file).
// =============================================================================
class MessageScreenGetx extends GetxController {
  static const int PageSize = 30;

  MessageScreenGetx({
    required this.myNumber,
    required this.otherNumber,
    required this.otherName,
    required this.jwtToken,
    this.otherPhotoPath = '',
    this.myPhotoPath = '',
  });

  final int myNumber;
  final int otherNumber;
  final String otherName;
  final String jwtToken;
  final String otherPhotoPath;
  final String myPhotoPath;

  final TextEditingController textCont = TextEditingController();

  // ---- messages ----
  final RxList<MsgItem> Items = <MsgItem>[].obs;
  final RxBool IsLoading = false.obs;
  final RxBool IsLoadingOlder = false.obs;
  final RxBool HasMoreOlder = false.obs;
  final RxBool HasLoadedOnce = false.obs;
  final RxString LoadError = ''.obs;

  // ---- composer ----
  final RxString Draft = ''.obs;
  final RxString Notice = ''.obs; // short send error, clears by itself

  // ---- header / status ----
  final RxString OtherPhoto = ''.obs; // raw path
  final RxBool IsOnline = false.obs;
  final RxBool IsConnected = false.obs;

  // ---- scrolling ----
  final RxBool IsAtBottom = true.obs;
  final RxInt UnseenCount = 0.obs; // new messages while scrolled up

  // The screen sets this so the controller can scroll to the newest message.
  VoidCallback? ScrollToLatest;

  SignalRService? _signal;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  final List<Worker> _workers = <Worker>[];

  bool _loadingInitial = false;
  bool _loadAgain = false;

  // Messages waiting to be sent, one after the other (keeps the order).
  final List<String> _queue = <String>[];
  bool _sending = false;
  Timer? _noticeTimer;
  Timer? _markReadTimer;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    OtherPhoto.value = otherPhotoPath;

    try {
      // Makes this screen work even when it was not opened from the chat
      // screen: loads my conversations + connects SignalR (both idempotent),
      // and tells the app that this chat is open (no unread badge for it).
      final ChatScreenController chats = ChatScreenController.Ensure();
      chats.Start(JwtToken: jwtToken, UserNumber: myNumber);
      chats.SetOpenChat(otherNumber);
    } catch (e) {
      // print('MessageScreenGetx open chat error: $e');
    }

    _bindSignal();
    LoadInitial();
  }

  @override
  void onClose() {
    try {
      _chatSub?.cancel();
      for (final Worker w in _workers) {
        w.dispose();
      }
      _workers.clear();
      _noticeTimer?.cancel();
      _markReadTimer?.cancel();
      textCont.dispose();

      if (Get.isRegistered<ChatScreenController>()) {
        Get.find<ChatScreenController>().ClearOpenChat(otherNumber);
      }
    } catch (e) {
      // print('MessageScreenGetx onClose error: $e');
    }
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // SIGNALR (presence, connection state, live chat events)
  // ---------------------------------------------------------------------------
  void _bindSignal() {
    try {
      final SignalRService s = Get.isRegistered<SignalRService>()
          ? Get.find<SignalRService>()
          : Get.put(SignalRService(), permanent: true);
      _signal = s;

      IsOnline.value = s.OnlineUserNumbers.contains(otherNumber);
      IsConnected.value = s.IsConnectedRx.value;

      _workers.add(ever(s.OnlineUserNumbers, (_) {
        IsOnline.value = s.OnlineUserNumbers.contains(otherNumber);
      }));
      _workers.add(ever(s.IsConnectedRx, (_) {
        IsConnected.value = s.IsConnectedRx.value;
      }));

      _chatSub = s.ChatEvents.stream.listen(
        _onChatEvent,
        onError: (e) {
          // print('MessageScreenGetx event stream error: $e');
        },
      );
    } catch (e) {
      // print('MessageScreenGetx bind signal error: $e');
      IsOnline.value = false;
    }
  }

  int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  bool _b(dynamic v) {
    if (v is bool) return v;
    return '${v ?? ''}'.toLowerCase() == 'true';
  }

  void _onChatEvent(Map<String, dynamic> e) {
    try {
      final String type = '${e['type']}';

      if (type == 'ReceiveMessage') {
        _onReceive(e);
      } else if (type == 'MessagesRead') {
        // The other person read my messages: every sent message gets the
        // blue double tick.
        if (_i(e['readerNumber']) == otherNumber) _markMineRead();
      } else if (type == 'Reconnected') {
        // Catch up on anything missed while the connection was down.
        LoadInitial(silent: true);
      }
    } catch (err) {
      // print('MessageScreenGetx _onChatEvent error: $err');
    }
  }

  void _onReceive(Map<String, dynamic> e) {
    final int chatId = _i(e['chatId']);
    final int sender = _i(e['senderNumber']);
    final int receiver = _i(e['receiverNumber']);

    final bool mine = sender == myNumber;
    final bool inThisChat = (mine && receiver == otherNumber) ||
        (sender == otherNumber && receiver == myNumber);

    // Other conversations are handled by the chat list, not here.
    if (!inThisChat || chatId <= 0) return;

    // Already shown (the REST answer and the live push both arrive).
    if (Items.any((i) => i.chatId == chatId)) return;

    _mergeServer(
      <MsgMessage>[
        MsgMessage(
          chatId: chatId,
          message: '${e['message'] ?? ''}',
          storeAt: '${e['storeAt'] ?? ''}',
          senderNumber: sender,
          receiverNumber: receiver,
          isRead: _b(e['isRead']),
          clientId: '${e['clientId'] ?? ''}',
        ),
      ],
    );

    if (!mine) {
      // The chat is open: these messages are read right away.
      _markReadSoon();
      if (!IsAtBottom.value) UnseenCount.value = UnseenCount.value + 1;
    }
  }

  void _markMineRead() {
    final List<MsgItem> next = Items
        .map((i) => (i.senderNumber == myNumber && !i.isPending && !i.isRead)
        ? i.copyWith(isRead: true)
        : i)
        .toList();
    Items.assignAll(next);
  }

  // ---------------------------------------------------------------------------
  // LOADING
  // ---------------------------------------------------------------------------
  void _handleSessionExpired() {
    try {
      final ctx = Get.context;
      if (ctx != null) {
      Toast.Toastmsg("Your session has expired. Please login again.");
        common.Logout(context: ctx);
      }
    } catch (e) {
      // print('MessageScreenGetx session expired error: $e');
    }
  }

  // silent = true: background refresh (reconnect), no loading flag.
  Future<void> LoadInitial({bool silent = false}) async {
    if (_loadingInitial) {
      _loadAgain = true;
      return;
    }

    _loadingInitial = true;
    try {
      if (!silent) {
        IsLoading.value = true;
        LoadError.value = '';
      }

      final MsgMessagesResult r = await MsgGetMessages(
        jwt: jwtToken,
        userNumber: otherNumber,
        limit: PageSize,
      );

      if (!r.ok) {
        if (r.statusCode == 401) {
          _handleSessionExpired();
        }
        if (Items.isEmpty) {
          LoadError.value = 'Could not load messages. Please try again.';
        }
        return;
      }

      LoadError.value = '';
      if (OtherPhoto.value.isEmpty && r.otherUserPhoto.isNotEmpty) {
        OtherPhoto.value = r.otherUserPhoto;
      }

      final bool first = !HasLoadedOnce.value;
      _mergeServer(r.messages);
      if (first) HasMoreOlder.value = r.hasMore;
      HasLoadedOnce.value = true;

      _markReadSoon();
    } catch (e) {
      // print('MessageScreenGetx LoadInitial error: $e');
      if (Items.isEmpty) {
        LoadError.value = 'Could not load messages. Please try again.';
      }
    } finally {
      IsLoading.value = false;
      _loadingInitial = false;

      if (_loadAgain) {
        _loadAgain = false;
        LoadInitial(silent: true);
      }
    }
  }

  // Scroll up: loads the page before the oldest saved message.
  Future<void> LoadOlder() async {
    if (IsLoadingOlder.value || !HasMoreOlder.value || !HasLoadedOnce.value) {
      return;
    }

    int oldest = 0;
    for (final MsgItem i in Items) {
      if (i.chatId > 0 && (oldest == 0 || i.chatId < oldest)) oldest = i.chatId;
    }
    if (oldest == 0) return;

    IsLoadingOlder.value = true;
    try {
      final MsgMessagesResult r = await MsgGetMessages(
        jwt: jwtToken,
        userNumber: otherNumber,
        beforeChatId: oldest,
        limit: PageSize,
      );

      if (!r.ok) {
        if (r.statusCode == 401) _handleSessionExpired();
        return;
      }

      _mergeServer(r.messages);
      HasMoreOlder.value = r.hasMore;
    } catch (e) {
      // print('MessageScreenGetx LoadOlder error: $e');
    } finally {
      IsLoadingOlder.value = false;
    }
  }

  Future<void> Refresh() async {
    await LoadInitial();
  }

  // Puts server messages into the list: saved messages sorted by ChatId, then
  // the ones still being sent. Removes a "sending" copy once the server has it.
  void _mergeServer(List<MsgMessage> incoming) {
    final Map<int, MsgItem> byId = <int, MsgItem>{
      for (final MsgItem i in Items)
        if (i.chatId > 0) i.chatId: i,
    };
    final List<MsgItem> pending = Items.where((i) => i.isPending).toList();

    int maxKnown = 0;
    for (final int id in byId.keys) {
      if (id > maxKnown) maxKnown = id;
    }

    final List<int> newer = <int>[];
    for (final MsgMessage m in incoming) {
      if (m.chatId <= 0) continue;
      if (!byId.containsKey(m.chatId) && m.chatId > maxKnown) newer.add(m.chatId);
      byId[m.chatId] = MsgItem.fromServer(m);
    }

    // A "sending" message the server already has (matched by ClientId, or by
    // the same text when the answer was lost): drop the local copy.
    for (final int id in newer) {
      final MsgItem saved = byId[id]!;
      if (saved.senderNumber != myNumber) continue;

      int p = -1;
      if (saved.clientId.isNotEmpty) {
        p = pending.indexWhere((x) => x.clientId == saved.clientId);
      }
      if (p < 0) {
        p = pending.indexWhere((x) => x.text.trim() == saved.text.trim());
      }
      if (p >= 0) pending.removeAt(p);
    }

    final List<MsgItem> server = byId.values.toList()
      ..sort((a, b) => a.chatId.compareTo(b.chatId));

    Items.assignAll(<MsgItem>[...server, ...pending]);
  }

  // ---------------------------------------------------------------------------
  // MARK READ (the chat is open, so what arrives is read)
  // ---------------------------------------------------------------------------
  void _markReadSoon() {
    try {
      _markReadTimer?.cancel();
      _markReadTimer = Timer(const Duration(milliseconds: 250), () {
        _markRead();
      });
    } catch (e) {
      // print('MessageScreenGetx markReadSoon error: $e');
    }
  }

  Future<void> _markRead() async {
    try {
      // Only when there is something unread from the other person.
      final bool anyUnread = Items.any(
            (i) => i.senderNumber == otherNumber && !i.isPending && !i.isRead,
      );
      if (!anyUnread) return;

      // The server reply "ConversationRead" is not needed here: the other
      // person's list gets "MessagesRead" and ours is cleared optimistically.
      if (Get.isRegistered<ChatScreenController>()) {
        final ChatScreenController chats = Get.find<ChatScreenController>();
        if (chats.Jwt.isNotEmpty) {
          await chats.MarkRead(otherNumber);
          _setIncomingRead();
          return;
        }
      }

      await MsgMarkRead(jwt: jwtToken, userNumber: otherNumber);
      _setIncomingRead();
    } catch (e) {
      // print('MessageScreenGetx markRead error: $e');
    }
  }

  // Incoming messages are stored as read after the server accepted it, so the
  // next check does not call the server again.
  void _setIncomingRead() {
    final List<MsgItem> next = Items
        .map((i) => (i.senderNumber == otherNumber && !i.isPending && !i.isRead)
        ? i.copyWith(isRead: true)
        : i)
        .toList();
    Items.assignAll(next);
  }

  // ---------------------------------------------------------------------------
  // SENDING (instant bubble, then sent / read ticks, retry when it fails)
  // ---------------------------------------------------------------------------
  bool get HasText => Draft.value.trim().isNotEmpty;

  void SendMessage() {
    try {
      final String text = Draft.value.trim();
      if (text.isEmpty) return;

      if (text.length > 4000) {
        _showNotice('A message can have 4000 characters at most.');
        return;
      }

      textCont.clear();
      Draft.value = '';

      final String clientId = '${DateTime.now().microsecondsSinceEpoch}_$myNumber';

      Items.add(MsgItem(
        chatId: 0,
        clientId: clientId,
        text: text,
        time: DateTime.now(),
        senderNumber: myNumber,
        state: MsgSendState.sending,
      ));

      ScrollToLatest?.call();

      _queue.add(clientId);
      _pump();
    } catch (e) {
      // print('MessageScreenGetx SendMessage error: $e');
    }
  }

  // Sends the waiting messages one after the other.
  Future<void> _pump() async {
    if (_sending) return;
    _sending = true;

    try {
      while (_queue.isNotEmpty) {
        final String id = _queue.first;
        final int idx = Items.indexWhere((i) => i.isPending && i.clientId == id);

        // Deleted by the user while it waited.
        if (idx < 0) {
          _queue.removeAt(0);
          continue;
        }

        final MsgItem item = Items[idx];

        final MsgSendResult r = await MsgSendMessage(
          jwt: jwtToken,
          receiverNumber: otherNumber,
          message: item.text,
          clientId: id,
        );

        _queue.remove(id);

        if (r.ok && r.message != null) {
          _mergeServer(<MsgMessage>[r.message!]);
        } else {
          _setState(id, MsgSendState.failed);

          if (r.statusCode == 401) {
            _handleSessionExpired();
          } else if (r.error.isNotEmpty) {
            _showNotice(r.error);
          } else {
            _showNotice('Message not sent. Check your connection and retry.');
          }
        }
      }
    } catch (e) {
      // print('MessageScreenGetx _pump error: $e');
    } finally {
      _sending = false;
    }
  }

  void _setState(String clientId, MsgSendState state) {
    final int idx = Items.indexWhere((i) => i.isPending && i.clientId == clientId);
    if (idx < 0) return;
    Items[idx] = Items[idx].copyWith(state: state);
  }

  void Retry(String clientId) {
    try {
      final int idx =
      Items.indexWhere((i) => i.isPending && i.clientId == clientId);
      if (idx < 0 || Items[idx].state != MsgSendState.failed) return;

      Items[idx] = Items[idx].copyWith(state: MsgSendState.sending);
      if (!_queue.contains(clientId)) _queue.add(clientId);
      _pump();
    } catch (e) {
      // print('MessageScreenGetx Retry error: $e');
    }
  }

  void DiscardFailed(String clientId) {
    try {
      _queue.remove(clientId);
      Items.removeWhere((i) => i.isPending && i.clientId == clientId);
    } catch (e) {
      // print('MessageScreenGetx Discard error: $e');
    }
  }

  void _showNotice(String text) {
    try {
      Notice.value = text;
      _noticeTimer?.cancel();
      _noticeTimer = Timer(const Duration(seconds: 5), () {
        Notice.value = '';
      });
    } catch (e) {
      // print('MessageScreenGetx notice error: $e');
    }
  }

  void ClearNotice() {
    Notice.value = '';
  }

  // ---------------------------------------------------------------------------
  // SCROLL STATE (the screen reports it)
  // ---------------------------------------------------------------------------
  void SetAtBottom(bool value) {
    if (IsAtBottom.value != value) IsAtBottom.value = value;
    if (value && UnseenCount.value != 0) UnseenCount.value = 0;
  }

  // ---------------------------------------------------------------------------
  // LABELS
  // ---------------------------------------------------------------------------
  String TimeLabel(DateTime t) {
    final int h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String mm = t.minute.toString().padLeft(2, '0');
    return '$h:$mm ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  bool SameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // "Today", "Yesterday" or "05 Nov 2026".
  String DayLabel(DateTime d) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(d.year, d.month, d.day);
    final int diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    final String dd = d.day.toString().padLeft(2, '0');
    return '$dd ${months[math.max(0, math.min(11, d.month - 1))]} ${d.year}';
  }
}