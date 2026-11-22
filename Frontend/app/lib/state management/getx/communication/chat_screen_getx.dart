import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/variable.dart';
import '../../../web/common method/Commmon_Method.dart' as common;

import '../../../web/common method/communicationcommonmethod.dart';
import '../../../web/communi_services/services.dart';

// =============================================================================
// CHAT SCREEN GETX (permanent, one per app)
//
// Holds my conversations, the unread total and the live events, so the chat
// screen, the home screen icon and (later) the message screen always agree.
//
//   Start()  safe to call many times (home screen and chat screen both call it)
//   Stop()   call on logout
//
// What the chat screen list shows:
//   - search text typed        -> people matching username / user id (server)
//   - no search, have chats    -> my conversations, newest first
//   - no search, no chats      -> all people (server, paged)
// =============================================================================
class ChatScreenController extends GetxController {
  static const int PageSize = 30;

  static ChatScreenController Ensure() {
    return Get.isRegistered<ChatScreenController>()
        ? Get.find<ChatScreenController>()
        : Get.put(ChatScreenController(), permanent: true);
  }

  // ---- conversations ----
  final RxList<MsgConversation> Conversations = <MsgConversation>[].obs;
  final RxBool IsLoading = false.obs;
  final RxBool IsLoadingMore = false.obs;
  final RxBool HasMore = false.obs;
  final RxBool HasLoaded = false.obs;
  final RxString ErrorMessage = ''.obs;

  final RxString MyName = ''.obs;
  final RxString MyPhoto = ''.obs; // raw path

  // Total unread messages (home screen chat icon).
  final RxInt UnreadTotal = 0.obs;

  // Person whose message screen is open right now (0 = none). Messages from
  // this person are marked read straight away instead of counting as unread.
  final RxInt OpenChatNumber = 0.obs;

  // ---- connection + presence (mirrors of SignalRService) ----
  final RxBool IsConnected = false.obs;
  final RxSet<int> OnlineNumbers = <int>{}.obs;

  // ---- search / browse ----
  final RxString SearchText = ''.obs;
  final RxList<MsgConversation> SearchResults = <MsgConversation>[].obs;
  final RxBool SearchLoading = false.obs;
  final RxBool SearchLoadingMore = false.obs;
  final RxBool SearchHasMore = false.obs;
  final RxString SearchError = ''.obs;
  final RxInt HoveredUser = (-1).obs;

  int MyNumber = 0;
  String Jwt = '';

  SignalRService? _signal;
  StreamSubscription<Map<String, dynamic>>? _sub;
  final List<Worker> _workers = <Worker>[];
  bool _workersReady = false;

  int _pagesLoaded = 0;
  bool _busy = false;
  bool _again = false;

  int _searchPage = 1;
  int _searchSeq = 0; // ignores answers of outdated searches
  String _resultsQuery = ''; // the query the current results belong to

  Timer? _refreshTimer;
  Timer? _unreadTimer;
  final Set<int> _markingRead = <int>{};
  final Set<int> _markAgain = <int>{};

  // ---------------------------------------------------------------------------
  // START / STOP
  // ---------------------------------------------------------------------------
  Future<void> Start({
    required String JwtToken,
    required int UserNumber,
  }) async {
    try {
      if (JwtToken.trim().isEmpty || UserNumber <= 0) return;

      if (MyNumber != UserNumber) {
        _clearData();
        MyNumber = UserNumber;
      }
      Jwt = JwtToken;

      _bindSignal();

      // Does nothing when it is already connected.
      _signal?.ConnectSignalR(User_JwtToken: JwtToken);

      if (!HasLoaded.value) await LoadFirstPage();
      RefreshUnreadSoon();
    } catch (e) {
      // print('ChatScreenController Start error: $e');
    }
  }

  // Call on logout.
  Future<void> Stop() async {
    try {
      _sub?.cancel();
      _sub = null;
      _refreshTimer?.cancel();
      _unreadTimer?.cancel();
      _clearData();
      MyNumber = 0;
      Jwt = '';
      await _signal?.DisconnectSignalR();
    } catch (e) {
      // print('ChatScreenController Stop error: $e');
    }
  }

  @override
  void onClose() {
    try {
      _sub?.cancel();
      _refreshTimer?.cancel();
      _unreadTimer?.cancel();
      for (final Worker w in _workers) {
        w.dispose();
      }
      _workers.clear();
    } catch (e) {
      // print('ChatScreenController onClose error: $e');
    }
    super.onClose();
  }

  void _clearData() {
    Conversations.clear();
    HasLoaded.value = false;
    HasMore.value = false;
    IsLoading.value = false;
    IsLoadingMore.value = false;
    ErrorMessage.value = '';
    MyName.value = '';
    MyPhoto.value = '';
    UnreadTotal.value = 0;
    OpenChatNumber.value = 0;
    _pagesLoaded = 0;
    ResetSearch();
  }

  void _bindSignal() {
    try {
      _signal ??= Get.isRegistered<SignalRService>()
          ? Get.find<SignalRService>()
          : Get.put(SignalRService(), permanent: true);

      final SignalRService s = _signal!;

      _sub ??= s.ChatEvents.stream.listen(
        _onChatEvent,
        onError: (e) {
          // print('ChatScreenController event stream error: $e');
        },
      );

      if (_workersReady) return;
      _workersReady = true;

      // Connection state and online users are mirrored into observables owned
      // here, so every Obx on every screen has something to listen to.
      IsConnected.value = s.IsConnectedRx.value;
      OnlineNumbers.assignAll(s.OnlineUserNumbers);

      _workers.add(ever(s.IsConnectedRx, (_) {
        IsConnected.value = s.IsConnectedRx.value;
      }));
      _workers.add(ever(s.OnlineUserNumbers, (_) {
        OnlineNumbers.assignAll(s.OnlineUserNumbers);
      }));

      _workers.add(debounce(
        SearchText,
            (_) => _syncMode(),
        time: const Duration(milliseconds: 350),
      ));
      _workers.add(ever(HasLoaded, (_) => _syncMode()));
    } catch (e) {
      // print('ChatScreenController bind signal error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PARSERS
  // ---------------------------------------------------------------------------
  int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  bool _b(dynamic v) {
    if (v is bool) return v;
    return '${v ?? ''}'.toLowerCase() == 'true';
  }

  // ---------------------------------------------------------------------------
  // LOADING MY CONVERSATIONS
  // ---------------------------------------------------------------------------
  void _handleFailure(int code) {
    try {
      if (code == 401) {
        ErrorMessage.value = 'Your session has expired.';
        final ctx = Get.context;
        if (ctx != null) {
          Toast.Toastmsg("Your session has expired. Please login again.");
          common.Logout(context: ctx);
        }
        return;
      }
      ErrorMessage.value = 'Unable to load conversations. Please try again.';
    } catch (e) {
      // print('ChatScreenController failure handler error: $e');
    }
  }

  // silent = true: background refresh, no loading flag.
  Future<void> LoadFirstPage({bool silent = false}) async {
    if (Jwt.isEmpty) return;

    if (_busy) {
      _again = true;
      return;
    }

    _busy = true;
    try {
      if (!silent) {
        IsLoading.value = true;
        ErrorMessage.value = '';
      }

      final MsgListResult r = await MsgGetConversations(
        jwt: Jwt,
        page: 1,
        pageSize: PageSize,
      );

      if (!r.ok) {
        _handleFailure(r.statusCode);
        return;
      }

      ErrorMessage.value = '';
      if (r.meName.isNotEmpty) MyName.value = r.meName;
      MyPhoto.value = r.mePhoto;

      _mergeFirstPage(r.items, r.hasMore);
      HasLoaded.value = true;
    } catch (e) {
      // print('ChatScreenController LoadFirstPage error: $e');
      if (Conversations.isEmpty) {
        ErrorMessage.value = 'Unable to load conversations. Please try again.';
      }
    } finally {
      IsLoading.value = false;
      _busy = false;

      if (_again) {
        _again = false;
        LoadFirstPage(silent: true);
      }
    }
  }

  // Page 1 replaces the top of the list. Older pages already loaded are kept.
  void _mergeFirstPage(List<MsgConversation> page, bool more) {
    if (page.isEmpty) {
      Conversations.clear();
      HasMore.value = false;
      _pagesLoaded = 1;
      return;
    }

    final bool keepOlder = _pagesLoaded > 1;
    final List<MsgConversation> merged = List<MsgConversation>.from(page);

    if (keepOlder) {
      final int oldestOnPage = page.map((e) => e.lastChatId).reduce(math.min);
      final Set<int> have = merged.map((e) => e.userNumber).toSet();

      for (final MsgConversation c in Conversations) {
        if (c.lastChatId < oldestOnPage && !have.contains(c.userNumber)) {
          merged.add(c);
        }
      }
    } else {
      HasMore.value = more;
      _pagesLoaded = 1;
    }

    merged.sort((a, b) => b.lastChatId.compareTo(a.lastChatId));
    Conversations.assignAll(merged);
  }

  Future<void> LoadMore() async {
    if (_busy || IsLoadingMore.value || !HasMore.value || !HasLoaded.value) {
      return;
    }
    if (Jwt.isEmpty) return;

    IsLoadingMore.value = true;
    try {
      final int next = _pagesLoaded + 1;

      final MsgListResult r = await MsgGetConversations(
        jwt: Jwt,
        page: next,
        pageSize: PageSize,
      );

      if (!r.ok) {
        _handleFailure(r.statusCode);
        return;
      }

      // New chats insert at the top, so a later page can repeat a person.
      final Set<int> have = Conversations.map((e) => e.userNumber).toSet();
      final List<MsgConversation> fresh =
      r.items.where((e) => !have.contains(e.userNumber)).toList();

      final List<MsgConversation> merged = [...Conversations, ...fresh];
      merged.sort((a, b) => b.lastChatId.compareTo(a.lastChatId));
      Conversations.assignAll(merged);

      _pagesLoaded = next;
      HasMore.value = r.hasMore;
    } catch (e) {
      // print('ChatScreenController LoadMore error: $e');
    } finally {
      IsLoadingMore.value = false;
    }
  }

  void RefreshSoon() {
    try {
      _refreshTimer?.cancel();
      _refreshTimer = Timer(const Duration(milliseconds: 300), () {
        LoadFirstPage(silent: true);
      });
    } catch (e) {
      // print('ChatScreenController RefreshSoon error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UNREAD TOTAL
  // ---------------------------------------------------------------------------
  Future<void> RefreshUnread() async {
    try {
      if (Jwt.isEmpty) return;
      final int t = await MsgGetUnreadTotal(jwt: Jwt);
      if (t >= 0) UnreadTotal.value = t;
    } catch (e) {
      // print('ChatScreenController RefreshUnread error: $e');
    }
  }

  void RefreshUnreadSoon() {
    try {
      _unreadTimer?.cancel();
      _unreadTimer = Timer(const Duration(milliseconds: 600), () {
        RefreshUnread();
      });
    } catch (e) {
      // print('ChatScreenController RefreshUnreadSoon error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LOOKUP + OPEN CHAT + MARK READ
  // ---------------------------------------------------------------------------
  MsgConversation? Find(int userNumber) {
    for (final MsgConversation c in Conversations) {
      if (c.userNumber == userNumber) return c;
    }
    return null;
  }

  void SetOpenChat(int userNumber) {
    try {
      OpenChatNumber.value = userNumber;
      final MsgConversation? c = Find(userNumber);
      if (c != null && c.unreadCount > 0) MarkRead(userNumber);
    } catch (e) {
      // print('ChatScreenController SetOpenChat error: $e');
    }
  }

  void ClearOpenChat(int userNumber) {
    try {
      if (OpenChatNumber.value == userNumber) OpenChatNumber.value = 0;
    } catch (e) {
      // print('ChatScreenController ClearOpenChat error: $e');
    }
  }

  // Unread goes to 0 at once (optimistic), then the server is told.
  Future<void> MarkRead(int userNumber) async {
    if (userNumber <= 0 || Jwt.isEmpty) return;

    if (_markingRead.contains(userNumber)) {
      _markAgain.add(userNumber);
      return;
    }

    _markingRead.add(userNumber);
    try {
      final int idx = Conversations.indexWhere((c) => c.userNumber == userNumber);
      if (idx >= 0 && Conversations[idx].unreadCount > 0) {
        final MsgConversation old = Conversations[idx];
        Conversations[idx] = old.copyWith(unreadCount: 0);
        UnreadTotal.value = math.max(0, UnreadTotal.value - old.unreadCount);
      }

      final bool ok = await MsgMarkRead(jwt: Jwt, userNumber: userNumber);

      // Failed: take the real state from the server.
      if (!ok) RefreshSoon();
      RefreshUnreadSoon();
    } catch (e) {
      // print('ChatScreenController MarkRead error: $e');
    } finally {
      _markingRead.remove(userNumber);
      if (_markAgain.remove(userNumber)) MarkRead(userNumber);
    }
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME EVENTS
  // ---------------------------------------------------------------------------
  void _onChatEvent(Map<String, dynamic> e) {
    try {
      final String type = '${e['type']}';

      if (type == 'ReceiveMessage') {
        _onReceive(e);
      } else if (type == 'MessagesRead') {
        _onMessagesRead(e);
      } else if (type == 'ConversationRead') {
        _onConversationRead(e);
      } else if (type == 'Reconnected') {
        // Catch up on anything missed while the connection was down.
        RefreshSoon();
        RefreshUnreadSoon();
      }
    } catch (err) {
      // print('ChatScreenController _onChatEvent error: $err');
    }
  }

  void _onReceive(Map<String, dynamic> e) {
    final int chatId = _i(e['chatId']);
    final int sender = _i(e['senderNumber']);
    final int receiver = _i(e['receiverNumber']);
    final String message = '${e['message'] ?? ''}';
    final String storeAt = '${e['storeAt'] ?? ''}';
    final bool isRead = _b(e['isRead']);

    if (MyNumber <= 0 || sender <= 0 || receiver <= 0) return;

    final bool mine = sender == MyNumber;
    if (!mine && receiver != MyNumber) return;

    final int partner = mine ? receiver : sender;
    final bool chatOpen = OpenChatNumber.value == partner;
    final bool addUnread = !mine && !chatOpen;

    final int idx = Conversations.indexWhere((c) => c.userNumber == partner);

    // New person: the server knows name + photo, so ask for page 1 again.
    if (idx < 0) {
      if (addUnread) UnreadTotal.value = UnreadTotal.value + 1;
      RefreshSoon();
      RefreshUnreadSoon();
      return;
    }

    final MsgConversation old = Conversations[idx];

    // Same message twice (two paths, or a retry): ignore.
    if (chatId > 0 && chatId <= old.lastChatId) return;

    final MsgConversation updated = old.copyWith(
      lastChatId: chatId > 0 ? chatId : old.lastChatId + 1,
      lastMessage: message,
      lastSenderNumber: sender,
      lastMessageAt: storeAt,
      lastIsRead: mine ? false : isRead,
      unreadCount: addUnread ? old.unreadCount + 1 : old.unreadCount,
    );

    // The card jumps to the top.
    final List<MsgConversation> next = [
      updated,
      ...Conversations.where((c) => c.userNumber != partner),
    ];
    Conversations.assignAll(next);

    if (addUnread) UnreadTotal.value = UnreadTotal.value + 1;
    if (!mine && chatOpen) MarkRead(partner);

    RefreshUnreadSoon();
  }

  // The other person read my messages: my last message gets the read tick.
  void _onMessagesRead(Map<String, dynamic> e) {
    final int reader = _i(e['readerNumber']);
    if (reader <= 0) return;

    final int idx = Conversations.indexWhere((c) => c.userNumber == reader);
    if (idx < 0) return;

    final MsgConversation old = Conversations[idx];
    if (old.lastSenderNumber == MyNumber && !old.lastIsRead) {
      Conversations[idx] = old.copyWith(lastIsRead: true);
    }
  }

  // I read a chat somewhere else (another tab or device): clear the badge.
  void _onConversationRead(Map<String, dynamic> e) {
    final int other = _i(e['userNumber']);
    if (other <= 0) return;

    final int idx = Conversations.indexWhere((c) => c.userNumber == other);
    if (idx >= 0 && Conversations[idx].unreadCount > 0) {
      final MsgConversation old = Conversations[idx];
      Conversations[idx] = old.copyWith(unreadCount: 0);
      UnreadTotal.value = math.max(0, UnreadTotal.value - old.unreadCount);
    }
    RefreshUnreadSoon();
  }

  // ---------------------------------------------------------------------------
  // MODE: what the list shows
  // ---------------------------------------------------------------------------
  bool get IsSearchMode => SearchText.value.trim().isNotEmpty;

  // Nobody has chatted yet: show all people instead of an empty list.
  bool get ShowBrowse =>
      !IsSearchMode && HasLoaded.value && Conversations.isEmpty;

  bool get _useResults => IsSearchMode || ShowBrowse;

  String get SectionTitle {
    if (IsSearchMode) return 'Search results';
    if (ShowBrowse) return 'People';
    return 'Recent chats';
  }

  bool get IsInitialLoading {
    if (_useResults) {
      return SearchLoading.value && SearchResults.isEmpty;
    }
    // Before the first answer there is nothing to show yet: treat as loading.
    if (!HasLoaded.value && ErrorMessage.value.isEmpty) return true;
    return IsLoading.value && Conversations.isEmpty;
  }

  bool get IsLoadingMoreItems =>
      _useResults ? SearchLoadingMore.value : IsLoadingMore.value;

  bool get IsRefreshing => _useResults ? SearchLoading.value : IsLoading.value;

  String get ErrorText => _useResults ? SearchError.value : ErrorMessage.value;

  // Cards to draw. Search results use the live data when the person is
  // already a conversation, so unread count and last message stay current.
  List<MsgConversation> GetVisibleItems() {
    try {
      if (_useResults) {
        return SearchResults.map((r) => Find(r.userNumber) ?? r).toList();
      }
      return Conversations.toList();
    } catch (e) {
      // print('ChatScreenController GetVisibleItems error: $e');
      return <MsgConversation>[];
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------
  // Called on every keystroke.
  void OnSearchChanged(String value) {
    try {
      SearchText.value = value;
      final String q = value.trim();

      // Results of the old query would be wrong: drop them right away.
      if (q != _resultsQuery) {
        _searchSeq++;
        SearchResults.clear();
        SearchHasMore.value = false;
        SearchError.value = '';
        SearchLoading.value = q.isNotEmpty;
      }
    } catch (e) {
      // print('ChatScreenController search changed error: $e');
    }
  }

  // The screen calls this when it opens, so an old search never shows up.
  void ResetSearch() {
    try {
      _searchSeq++;
      _resultsQuery = '';
      SearchText.value = '';
      SearchResults.clear();
      SearchHasMore.value = false;
      SearchLoading.value = false;
      SearchLoadingMore.value = false;
      SearchError.value = '';
      HoveredUser.value = -1;
    } catch (e) {
      // print('ChatScreenController reset search error: $e');
    }
  }

  void _syncMode() {
    try {
      final String q = SearchText.value.trim();

      if (q.isNotEmpty) {
        final bool same = q == _resultsQuery &&
            (SearchResults.isNotEmpty || SearchLoading.value);
        if (!same) _startSearch(q);
      } else if (HasLoaded.value && Conversations.isEmpty) {
        // Browse everyone.
        final bool same = _resultsQuery.isEmpty &&
            (SearchResults.isNotEmpty || SearchLoading.value);
        if (!same) _startSearch('');
      } else if (_resultsQuery.isNotEmpty) {
        _searchSeq++;
        _resultsQuery = '';
        SearchResults.clear();
        SearchHasMore.value = false;
        SearchError.value = '';
        SearchLoading.value = false;
      }
    } catch (e) {
      // print('ChatScreenController sync mode error: $e');
    }
  }

  Future<void> _startSearch(String q) async {
    if (Jwt.isEmpty) return;
    final int seq = ++_searchSeq;

    try {
      _resultsQuery = q;
      _searchPage = 1;
      SearchLoading.value = true;
      SearchError.value = '';

      final MsgListResult r = await MsgSearchUsers(
        jwt: Jwt,
        query: q,
        page: 1,
        pageSize: PageSize,
      );

      if (seq != _searchSeq) return; // a newer search replaced this one

      if (!r.ok) {
        SearchResults.clear();
        SearchHasMore.value = false;
        SearchError.value = 'Could not load people. Please try again.';
        return;
      }

      SearchResults.assignAll(r.items);
      SearchHasMore.value = r.hasMore;
    } catch (e) {
      // print('ChatScreenController search error: $e');
      if (seq == _searchSeq) {
        SearchError.value = 'Could not load people. Please try again.';
      }
    } finally {
      if (seq == _searchSeq) SearchLoading.value = false;
    }
  }

  Future<void> _loadMoreResults() async {
    if (SearchLoading.value || SearchLoadingMore.value || !SearchHasMore.value) {
      return;
    }

    final int seq = _searchSeq;
    SearchLoadingMore.value = true;

    try {
      final int next = _searchPage + 1;

      final MsgListResult r = await MsgSearchUsers(
        jwt: Jwt,
        query: _resultsQuery,
        page: next,
        pageSize: PageSize,
      );

      if (seq != _searchSeq || !r.ok) return;

      final Set<int> have = SearchResults.map((e) => e.userNumber).toSet();
      final List<MsgConversation> fresh =
      r.items.where((e) => !have.contains(e.userNumber)).toList();

      SearchResults.addAll(fresh);
      _searchPage = next;
      SearchHasMore.value = r.hasMore;
    } catch (e) {
      // print('ChatScreenController load more results error: $e');
    } finally {
      SearchLoadingMore.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SCROLL + REFRESH (the screen owns the ScrollController and calls these)
  // ---------------------------------------------------------------------------
  void OnScroll(double pixels, double maxExtent) {
    try {
      if (maxExtent - pixels > 400) return;

      if (_useResults) {
        _loadMoreResults();
      } else {
        LoadMore();
      }
    } catch (e) {
      // print('ChatScreenController scroll error: $e');
    }
  }

  // Pull to refresh, the Refresh button and the Try again button.
  Future<void> RefreshAll() async {
    try {
      if (_useResults) {
        await _startSearch(SearchText.value.trim());
      } else {
        await LoadFirstPage();
      }
    } catch (e) {
      // print('ChatScreenController refresh error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // CARD HELPERS (read observables, so call them inside Obx)
  // ---------------------------------------------------------------------------
  bool IsUserOnline(int userNumber) => OnlineNumbers.contains(userNumber);

  int get OnlineCount {
    int n = 0;
    for (final MsgConversation c in Conversations) {
      if (OnlineNumbers.contains(c.userNumber)) n++;
    }
    return n;
  }

  // Today -> time, yesterday -> "Yesterday", older -> dd/MM/yyyy.
  String DateText(MsgConversation c) {
    try {
      final DateTime? t = c.lastTime;
      if (t == null) return '';

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime day = DateTime(t.year, t.month, t.day);
      final int diff = today.difference(day).inDays;

      if (diff == 0) {
        final int h = t.hour % 12 == 0 ? 12 : t.hour % 12;
        final String mm = t.minute.toString().padLeft(2, '0');
        return '$h:$mm ${t.hour >= 12 ? 'PM' : 'AM'}';
      }
      if (diff == 1) return 'Yesterday';

      final String d = t.day.toString().padLeft(2, '0');
      final String m = t.month.toString().padLeft(2, '0');
      return '$d/$m/${t.year}';
    } catch (e) {
      return '';
    }
  }

  String LastMessageText(MsgConversation c) {
    if (!c.hasMessage) return 'No messages yet';
    final String text = c.lastMessage.trim();
    return c.lastSenderNumber == MyNumber ? 'You: $text' : text;
  }
}