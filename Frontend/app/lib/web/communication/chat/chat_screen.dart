import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state management/getx/communication/chat_screen_getx.dart';

import '../../common method/communicationcommonmethod.dart';
import 'mwssage_screen.dart';

// Public palette (kept with the same names/values: other chat files use them).
const Color ChatBackground = Color(0xFF0F1F17);
const Color ChatSurface = Color(0xFF162E22);
const Color ChatHeader = Color(0xFF12261C);
const Color ChatAccent = Color(0xFF34D399);
const Color ChatText = Color(0xFFE6F4EA);
const Color ChatMuted = Color(0xFF9AA99E);
const Color ChatBorder = Color(0xFF234232);

const Color _Emerald = Color(0xFF22C55E);
const Color _Warn = Color(0xFFFBBF24);
const Color _ReadBlue = Color(0xFF38BDF8);

// =============================================================================
// SCREEN (StatefulWidget only for controller lifecycle, zero setState)
// =============================================================================
class ChatScreen extends StatefulWidget {
  final String User_JwtToken;
  final int CurrentUserNumber;

  const ChatScreen({
    super.key,
    required this.User_JwtToken,
    required this.CurrentUserNumber,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // The controller is global (permanent): it keeps live data while this
  // screen is closed, so reopening it is instant.
  late final ChatScreenController Controller;

  final TextEditingController _searchCont = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    try {
      Controller = ChatScreenController.Ensure();
      Controller.ResetSearch();
      Controller.Start(
        JwtToken: widget.User_JwtToken,
        UserNumber: widget.CurrentUserNumber,
      );

      _scroll.addListener(_onScroll);
    } catch (e) {
      // print('ChatScreen initState error: $e');
    }
  }

  @override
  void dispose() {
    try {
      _scroll.removeListener(_onScroll);
      _scroll.dispose();
      _searchCont.dispose();
    } catch (e) {
      // print('ChatScreen dispose error: $e');
    }

    // The controller and the SignalR connection stay alive on purpose.
    super.dispose();
  }

  void _onScroll() {
    try {
      if (!_scroll.hasClients) return;
      final ScrollPosition p = _scroll.position;
      Controller.OnScroll(p.pixels, p.maxScrollExtent);
    } catch (e) {
      // print('ChatScreen scroll error: $e');
    }
  }

  void _clearSearch() {
    try {
      _searchCont.clear();
      Controller.OnSearchChanged('');
    } catch (e) {
      // print('ChatScreen clear search error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatBackground,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _ChatAmbientBackground()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                final bool isWide = w >= 760;
                final double hPad = isWide ? 28 : 14;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Obx(() => _buildScrollBody(isWide, hPad)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OPEN A CHAT
  // ---------------------------------------------------------------------------
  Future<void> _openChat(MsgConversation c) async {
    try {
      final NavigatorState nav = Navigator.of(context);

      // Messages from this person are now read: the badge clears at once and
      // the server tells them (read ticks).
      Controller.SetOpenChat(c.userNumber);

      final String myName = Controller.MyName.value.trim();

      await nav.push(
        MaterialPageRoute(
          builder: (_) => ChatMessageScreen(
            ReceiverNumber: c.userNumber,
            ReceiverName: c.name,
            CurrentUserNumber: widget.CurrentUserNumber,
            CurrentUserName:
            myName.isEmpty ? 'User ${widget.CurrentUserNumber}' : myName,
            CurrentUserPhotoPath: Controller.MyPhoto.value,
            ReceiverPhotoPath: c.photo,
            User_JwtToken: widget.User_JwtToken,
          ),
        ),
      );
    } catch (e) {
      // print('Open chat error: $e');
    } finally {
      try {
        Controller.ClearOpenChat(c.userNumber);
      } catch (e) {
        // print('Close chat error: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // APP BAR: bordered back arrow, title, live connection status
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: ChatHeader,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: false,
      leadingWidth: 64,
      titleSpacing: 0,
      leading: Center(
        child: Tooltip(
          message: 'Back',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              try {
                Get.back();
              } catch (e) {
                // print('ChatScreen back navigation error: $e');
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ChatSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ChatText, width: 1.4),
              ),
              child: const Icon(Icons.arrow_back, color: ChatText, size: 20),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_Emerald, ChatAccent]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _Emerald.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.forum_rounded,
                color: ChatBackground, size: 19),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KaamMitra Connect',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ChatText,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Your conversations start here',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ChatMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: _buildConnectionPill(context)),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: ChatBorder),
      ),
    );
  }

  Widget _buildConnectionPill(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.width < 430;

    return Obx(() {
      final bool connected = Controller.IsConnected.value;
      final Color tone = connected ? ChatAccent : _Warn;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: tone.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: tone.withOpacity(0.40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone,
                boxShadow: [
                  BoxShadow(color: tone.withOpacity(0.6), blurRadius: 6),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 7),
              Text(
                connected ? 'Connected' : 'Offline',
                style: TextStyle(
                  color: tone,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // BODY: one scroll view, works at any size
  // ---------------------------------------------------------------------------
  Widget _buildScrollBody(bool isWide, double hPad) {
    // Reading these registers the reactive dependencies.
    final bool loading = Controller.IsInitialLoading;
    final String error = Controller.ErrorText;
    final bool searching = Controller.IsSearchMode;
    final List<MsgConversation> items = Controller.GetVisibleItems();
    final String sectionTitle = Controller.SectionTitle;
    final bool loadingMore = Controller.IsLoadingMoreItems;

    Widget content;

    if (loading && items.isEmpty) {
      content = SliverToBoxAdapter(
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (int i = 0; i < (isWide ? 6 : 4); i++)
              const SizedBox(
                width: 340,
                height: 116,
                child: _SkeletonBox(),
              ),
          ],
        ),
      );
    } else if (error.isNotEmpty && items.isEmpty) {
      content = SliverToBoxAdapter(
        child: _buildEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load people',
          subtitle: error,
          buttonText: 'Try again',
          onPressed: Controller.RefreshAll,
        ),
      );
    } else if (items.isEmpty) {
      content = SliverToBoxAdapter(
        child: _buildEmptyState(
          icon: searching
              ? Icons.person_search_rounded
              : Icons.people_outline_rounded,
          title: searching ? 'No matching people' : 'No people available',
          subtitle: searching
              ? 'Try a different username or user ID.'
              : 'There are no other registered users to display yet.',
          buttonText: searching ? 'Clear search' : 'Refresh',
          onPressed: searching ? _clearSearch : Controller.RefreshAll,
        ),
      );
    } else {
      content = SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 440,
          mainAxisExtent: 116,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final MsgConversation c = items[index];

            return _Entrance(
              key: ValueKey<String>('c_${c.userNumber}'),
              index: math.min(index, 8),
              child: _buildUserCard(c),
            );
          },
          childCount: items.length,
          // Keeps each card's state when the order changes (live reorder).
          findChildIndexCallback: (Key key) {
            if (key is ValueKey<String>) {
              final int i =
              items.indexWhere((u) => 'c_${u.userNumber}' == key.value);
              return i < 0 ? null : i;
            }
            return null;
          },
        ),
      );
    }

    return RefreshIndicator(
      color: ChatAccent,
      backgroundColor: ChatSurface,
      onRefresh: Controller.RefreshAll,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
            sliver: SliverToBoxAdapter(
              child: _Entrance(index: 0, child: _buildWelcome(isWide)),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 0),
            sliver: SliverToBoxAdapter(
              child: _Entrance(index: 1, child: _buildSearch()),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 10),
            sliver:
            SliverToBoxAdapter(child: _buildSectionHeader(sectionTitle)),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
            sliver: content,
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: Center(
                child: loadingMore
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: ChatAccent,
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WELCOME CARD
  // ---------------------------------------------------------------------------
  Widget _buildWelcome(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 26 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ChatBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF193A29).withOpacity(0.96),
            const Color(0xFF12261C).withOpacity(0.96),
            const Color(0xFF101F18).withOpacity(0.96),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good connections.\nBetter opportunities.',
                  style: TextStyle(
                    color: ChatText,
                    fontSize: isWide ? 26 : 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Find people on KaamMitra and start a conversation.',
                  style: TextStyle(
                    color: ChatText.withOpacity(0.72),
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final int unread = Controller.UnreadTotal.value;
                  final int online = Controller.OnlineCount;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        icon: Icons.mark_chat_unread_rounded,
                        text: unread > 0 ? '$unread unread' : 'All caught up',
                        color: unread > 0 ? ChatAccent : ChatMuted,
                      ),
                      _Chip(
                        icon: Icons.circle,
                        text: '$online online',
                        color: online > 0 ? _Emerald : ChatMuted,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: 0.7 + (0.3 * v), child: child),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _Emerald.withOpacity(0.22),
                      ChatAccent.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(color: ChatAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: _Emerald.withOpacity(0.25),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_chat_unread_rounded,
                  color: ChatAccent,
                  size: 44,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH (username or user id)
  // ---------------------------------------------------------------------------
  Widget _buildSearch() {
    return TextField(
      controller: _searchCont,
      onChanged: Controller.OnSearchChanged,
      style: const TextStyle(color: ChatText, fontSize: 14),
      cursorColor: ChatAccent,
      decoration: InputDecoration(
        hintText: 'Search username or user ID...',
        hintStyle: const TextStyle(color: ChatMuted, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: ChatAccent),
        suffixIcon: Obx(() => Controller.SearchText.value.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.close_rounded,
              color: ChatMuted, size: 18),
          onPressed: _clearSearch,
        )),
        filled: true,
        fillColor: ChatSurface.withOpacity(0.95),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: ChatBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: ChatAccent, width: 1.4),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION HEADER
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        const Icon(Icons.groups_rounded, color: ChatAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ChatText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Obx(() {
          final bool refreshing = Controller.IsRefreshing;
          return TextButton.icon(
            onPressed: refreshing ? null : Controller.RefreshAll,
            icon: refreshing
                ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: ChatAccent),
            )
                : const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: ChatAccent,
              disabledForegroundColor: ChatMuted,
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // USER CARD: photo, name, last date, last message (+ticks), unread badge,
  // user id, online / offline
  // ---------------------------------------------------------------------------
  Widget _buildUserCard(MsgConversation c) {
    final bool unread = c.unreadCount > 0;
    final bool mine = c.lastSenderNumber == widget.CurrentUserNumber;
    final String lastText = Controller.LastMessageText(c);
    final String dateText = Controller.DateText(c);

    return Obx(() {
      final bool online = Controller.IsUserOnline(c.userNumber);
      final bool hovered = Controller.HoveredUser.value == c.userNumber;
      final Color tone = online ? ChatAccent : ChatMuted;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => Controller.HoveredUser.value = c.userNumber,
        onExit: (_) {
          if (Controller.HoveredUser.value == c.userNumber) {
            Controller.HoveredUser.value = -1;
          }
        },
        child: AnimatedScale(
          scale: hovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openChat(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ChatSurface.withOpacity(hovered ? 1 : 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: unread
                        ? ChatAccent.withOpacity(0.75)
                        : hovered
                        ? ChatAccent.withOpacity(0.5)
                        : ChatBorder,
                    width: unread || hovered ? 1.3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hovered
                          ? _Emerald.withOpacity(0.16)
                          : Colors.black.withOpacity(0.14),
                      blurRadius: hovered ? 22 : 12,
                      offset: Offset(0, hovered ? 10 : 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _UserAvatar(
                      photoUrl: c.photoUrl,
                      online: online,
                      size: 54,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ChatText,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                              if (dateText.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  dateText,
                                  style: TextStyle(
                                    color: unread ? ChatAccent : ChatMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              // Read tick for my own last message.
                              if (mine && c.hasMessage) ...[
                                Icon(
                                  Icons.done_all_rounded,
                                  size: 15,
                                  color: c.lastIsRead ? _ReadBlue : ChatMuted,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  lastText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: unread
                                        ? ChatText
                                        : ChatText.withOpacity(0.62),
                                    fontSize: 12.5,
                                    fontWeight: unread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontStyle: c.hasMessage
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                              ),
                              if (unread) ...[
                                const SizedBox(width: 8),
                                _UnreadBadge(count: c.unreadCount),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _MiniPill(
                                icon: Icons.badge_rounded,
                                text: 'ID: ${c.userNumber}',
                              ),
                              _MiniPill(
                                icon: Icons.circle,
                                text: online ? 'Online' : 'Offline',
                                color: tone,
                                iconSize: 8,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 180),
                      offset: Offset(hovered ? 0.2 : 0, 0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: hovered ? ChatAccent : ChatMuted,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // EMPTY / ERROR STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ChatSurface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ChatBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ChatAccent.withOpacity(0.10),
              border: Border.all(color: ChatAccent.withOpacity(0.28)),
            ),
            child: Icon(icon, color: ChatAccent, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ChatText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ChatMuted,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: ChatAccent,
              side: const BorderSide(color: ChatAccent, width: 1.1),
              padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AVATAR: photo when there is one, people icon when empty / null / broken
// =============================================================================
class _UserAvatar extends StatelessWidget {
  final String photoUrl;
  final bool online;
  final double size;

  const _UserAvatar({
    required this.photoUrl,
    required this.online,
    required this.size,
  });

  Widget _fallback() {
    return Container(
      color: ChatHeader,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: ChatMuted, size: size * 0.58),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: online ? ChatAccent.withOpacity(0.7) : ChatBorder,
                  width: 1.4,
                ),
              ),
              child: ClipOval(
                child: photoUrl.isEmpty
                    ? _fallback()
                    : Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  cacheWidth: (size * 2).round(),
                  errorBuilder: (context, error, stack) => _fallback(),
                  loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _fallback(),
                ),
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? ChatAccent : ChatMuted,
                border: Border.all(color: ChatSurface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ChatAccent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: ChatAccent.withOpacity(0.5), blurRadius: 8),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: ChatBackground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// =============================================================================
// SMALL SHARED PIECES
// =============================================================================
class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Chip({
    required this.icon,
    required this.text,
    this.color = ChatAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: icon == Icons.circle ? 8 : 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final double iconSize;
  const _MiniPill({
    required this.icon,
    required this.text,
    this.color = ChatMuted,
    this.iconSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ChatHeader,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChatBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color == ChatMuted ? ChatText : color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 70).clamp(0, 420)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 22), child: ch),
      ),
      child: child,
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox();

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .4, end: 1)
          .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ChatBorder),
        ),
      ),
    );
  }
}

// =============================================================================
// AMBIENT BACKGROUND: blurred emerald/mint blobs + glass bubbles.
// Wrapped in IgnorePointer by the caller, so it can never block taps.
// =============================================================================
class _ChatAmbientBackground extends StatelessWidget {
  const _ChatAmbientBackground();

  Widget _blob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter:
        ImageFilter.blur(sigmaX: 45, sigmaY: 45, tileMode: TileMode.decal),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(opacity), color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(.07),
              Colors.white.withOpacity(.01),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(.07)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(builder: (context, box) {
        final double w = box.hasBoundedWidth ? box.maxWidth : 800;
        final double h = box.hasBoundedHeight ? box.maxHeight : 800;
        final double base = math.max(w, h);
        final double small = math.min(w, h);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            _blob(left: -w * .18, top: -h * .12, size: base * .70, color: _Emerald, opacity: .16),
            _blob(right: -w * .22, top: h * .28, size: base * .60, color: ChatAccent, opacity: .12),
            _blob(left: w * .08, bottom: -h * .22, size: base * .75, color: _Emerald, opacity: .12),
            _bubble(right: w * .10, top: h * .06, size: (small * .16).clamp(40.0, 150.0).toDouble()),
            _bubble(left: w * .06, top: h * .42, size: (small * .10).clamp(28.0, 100.0).toDouble()),
            _bubble(right: w * .18, bottom: h * .10, size: (small * .20).clamp(50.0, 190.0).toDouble()),
            _bubble(left: w * .40, bottom: h * .04, size: (small * .07).clamp(20.0, 70.0).toDouble()),
          ],
        );
      }),
    );
  }
}