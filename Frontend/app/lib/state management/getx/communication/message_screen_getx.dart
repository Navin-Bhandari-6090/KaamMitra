import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust the relative import segment counts if your folder depth differs.
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
    this.status = MsgStatus.sent,
    this.state = MsgSendState.sent,
  });

  final int chatId;
  final String clientId;
  final String text;
  final DateTime time;
  final int senderNumber;

  // 1 Sent (single tick), 2 Delivered (double tick), 3 Read (blue double tick).
  final int status;
  final MsgSendState state;

  bool get isPending => chatId == 0;
  bool get isRead => status >= MsgStatus.read;
  bool get isDelivered => status == MsgStatus.delivered;

  factory MsgItem.fromServer(MsgMessage m) {
    return MsgItem(
      chatId: m.chatId,
      clientId: m.clientId,
      text: m.message,
      time: m.time ?? DateTime.now(),
      senderNumber: m.senderNumber,
      status: m.status,
      state: MsgSendState.sent,
    );
  }

  MsgItem copyWith({int? status, MsgSendState? state}) {
    return MsgItem(
      chatId: chatId,
      clientId: clientId,
      text: text,
      time: time,
      senderNumber: senderNumber,
      status: status ?? this.status,
      state: state ?? this.state,
    );
  }

  // Moves the status forward only (never Read -> Delivered).
  MsgItem withStatusAtLeast(int newStatus) {
    if (newStatus <= status) return this;
    return copyWith(status: newStatus);
  }
}

// =============================================================================
// MESSAGE SCREEN GETX (one per open chat)
//
//  - newest 30 messages first, older ones load when you scroll up
//  - messages arrive live over SignalR
//  - tells the server when this chat screen is open (OpenChat / CloseChat),
//    and when the tab is hidden or visible again (Pause / Resume), so:
//        screen open + visible  -> new messages are saved as READ (blue tick)
//        other screen / hidden  -> only DELIVERED (grey double tick)
//  - ticks of my messages: clock (sending), 1 grey tick (sent),
//    2 grey ticks (delivered), 2 blue ticks (read). Status only moves forward.
//  - a failed message can be retried
//  - after a reconnect the newest page is fetched again, so nothing is missed
//
// Video calls are in VideoCallGetx (global service, works on every screen).
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

  // True while the app / browser tab is in front. A hidden tab must not turn
  // messages blue.
  bool _visible = true;

  // Messages waiting to be sent, one after the other (keeps the order).
  final List<String> _queue = <String>[];
  bool _sending = false;
  Timer? _noticeTimer;
  Timer? _markReadTimer;

  bool get IsVisible => _visible;

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

    // The server now knows I am on this chat's screen: earlier messages
    // become Read and new ones arrive as Read. (If SignalR is not connected
    // yet, the service sends it right after connecting.)
    try {
      _signal?.OpenChat(OtherNumber: otherNumber);
    } catch (e) {
      // print('MessageScreenGetx OpenChat error: $e');
    }

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

      // Only close when this screen is still the open one (another chat may
      // have opened already).
      final SignalRService? s = _signal;
      if (s != null && s.OpenChatUserNumber.value == otherNumber) {
        s.CloseChat();
      }

      if (Get.isRegistered<ChatScreenController>()) {
        Get.find<ChatScreenController>().ClearOpenChat(otherNumber);
      }
    } catch (e) {
      // print('MessageScreenGetx onClose error: $e');
    }
    super.onClose();
  }

  // The screen reports when the app / tab is hidden or shown again.
  void OnVisibilityChanged(bool visible) {
    try {
      if (_visible == visible) return;
      _visible = visible;

      final SignalRService? s = _signal;
      if (s == null) return;

      if (visible) {
        // Back in front: everything that arrived meanwhile is read now.
        s.ResumeOpenChat();
        LoadInitial(silent: true);
      } else {
        s.PauseOpenChat();
      }
    } catch (e) {
      // print('MessageScreenGetx visibility error: $e');
    }
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

  // New servers send "status" (1, 2 or 3). Old pushes only have "isRead".
  int _statusOf(Map<String, dynamic> e) {
    final int s = _i(e['status']);
    if (s >= MsgStatus.sent && s <= MsgStatus.read) return s;
    return _b(e['isRead']) ? MsgStatus.read : MsgStatus.sent;
  }

  void _onChatEvent(Map<String, dynamic> e) {
    try {
      final String type = '${e['type']}';

      if (type == 'ReceiveMessage') {
        _onReceive(e);
      } else if (type == 'MessagesDelivered') {
        // The other person came online: my Sent messages are Delivered.
        if (_i(e['receiverNumber']) == otherNumber) {
          _raiseMine(MsgStatus.delivered);
        }
      } else if (type == 'MessagesRead') {
        // Some of my messages were read (listed in chatIds).
        if (_i(e['readerNumber']) == otherNumber) {
          final dynamic raw = e['chatIds'];
          final List<int> ids = raw is List ? raw.map(_i).toList() : <int>[];
          if (ids.isNotEmpty) _raiseMine(MsgStatus.read, onlyChatIds: ids);
        }
      } else if (type == 'ConversationRead') {
        // The other person opened this chat: everything I sent is Read.
        if (_i(e['readerNumber']) == otherNumber) _raiseMine(MsgStatus.read);
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
    final int status = _statusOf(e);

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
          status: status,
          deliveredAt: '${e['deliveredAt'] ?? ''}',
          readAt: '${e['readAt'] ?? ''}',
          clientId: '${e['clientId'] ?? ''}',
        ),
      ],
    );

    if (!mine) {
      // The server saves it as Read when this screen is open and visible.
      // If it did not (race, or hidden tab that came back), ask for it.
      if (status < MsgStatus.read) _markIncomingReadSoon();
      if (!IsAtBottom.value) UnseenCount.value = UnseenCount.value + 1;
    }
  }

  // Raises the status of MY saved messages (forward only).
  void _raiseMine(int newStatus, {List<int>? onlyChatIds}) {
    bool changed = false;

    final List<MsgItem> next = Items.map((i) {
      if (i.senderNumber != myNumber || i.isPending) return i;
      if (onlyChatIds != null && !onlyChatIds.contains(i.chatId)) return i;

      final MsgItem updated = i.withStatusAtLeast(newStatus);
      if (!identical(updated, i)) changed = true;
      return updated;
    }).toList();

    if (changed) Items.assignAll(next);
  }

  // ---------------------------------------------------------------------------
  // LOADING
  // ---------------------------------------------------------------------------
  // 525 (user not valid) already started the logout inside the API call.
  // 401 comes from the token check before the controller runs.
  void _checkAuth(int statusCode) {
    try {
      if (statusCode == 401) MsgOnNotValidated?.call();
    } catch (e) {
      // print('MessageScreenGetx auth check error: $e');
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
        _checkAuth(r.statusCode);
        if (Items.isEmpty) {
          LoadError.value = r.notValidated
              ? 'Your session has expired. Please login again.'
              : 'Could not load messages. Please try again.';
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

      _markIncomingReadSoon();
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
        _checkAuth(r.statusCode);
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
  // A message already shown never loses a tick (forward-only status).
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

      final MsgItem? existing = byId[m.chatId];
      if (existing == null && m.chatId > maxKnown) newer.add(m.chatId);

      MsgItem item = MsgItem.fromServer(m);
      if (existing != null && existing.status > item.status) {
        item = item.copyWith(status: existing.status);
      }
      byId[m.chatId] = item;
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
  // MARK READ (safety net: the server normally saves messages as Read by
  // itself while this screen is open and visible)
  // ---------------------------------------------------------------------------
  void _markIncomingReadSoon() {
    try {
      _markReadTimer?.cancel();
      _markReadTimer = Timer(const Duration(milliseconds: 250), () {
        _markIncomingRead();
      });
    } catch (e) {
      // print('MessageScreenGetx markIncomingReadSoon error: $e');
    }
  }

  Future<void> _markIncomingRead() async {
    try {
      // A hidden tab must not mark anything as read.
      if (!_visible) return;

      final List<MsgItem> unread = Items
          .where((i) => i.senderNumber == otherNumber && !i.isPending && !i.isRead)
          .toList();
      if (unread.isEmpty) return;

      final SignalRService? s = _signal;

      if (s != null && s.IsSignalRConnected) {
        if (unread.length == 1) {
          await s.MarkMessageRead(ChatId: unread.first.chatId);
        } else {
          // Several at once: open the chat again, the server marks them all.
          await s.OpenChat(OtherNumber: otherNumber);
        }
        _setIncomingRead();
        return;
      }

      // SignalR is down: use the REST call instead.
      final bool ok = await MsgMarkRead(jwt: jwtToken, userNumber: otherNumber);
      if (ok) _setIncomingRead();
    } catch (e) {
      // print('MessageScreenGetx markIncomingRead error: $e');
    }
  }

  // Incoming messages are stored as read after the request, so the next check
  // does not call the server again.
  void _setIncomingRead() {
    final List<MsgItem> next = Items
        .map((i) => (i.senderNumber == otherNumber && !i.isPending && !i.isRead)
        ? i.withStatusAtLeast(MsgStatus.read)
        : i)
        .toList();
    Items.assignAll(next);
  }

  // ---------------------------------------------------------------------------
  // SENDING (instant bubble, then ticks, retry when it fails)
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
          // The answer already has the first status (Sent, Delivered or Read).
          _mergeServer(<MsgMessage>[r.message!]);
        } else {
          _setState(id, MsgSendState.failed);

          _checkAuth(r.statusCode);

          if (r.notValidated || r.statusCode == 401) {
            // Logging out: no extra message needed.
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