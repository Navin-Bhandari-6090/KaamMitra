import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/AdminUserInfosModel.dart';
import '../../../state management/getx/communication/chat_screen_getx.dart';
import 'mwssage_screen.dart';
// Controller lives in its own file. Adjust the path to where you save it.


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

// =============================================================================
// SCREEN (StatefulWidget only for controller lifecycle — zero setState)
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
  late final ChatScreenController Controller;

  @override
  void initState() {
    super.initState();

    try {
      Controller = Get.put(
        ChatScreenController(),
        tag: 'ChatScreen_${widget.CurrentUserNumber}',
      );

      Controller.Initialize(
        JwtToken: widget.User_JwtToken,
        UserNumber: widget.CurrentUserNumber,
      );
    } catch (e) {
      print('ChatScreen initState error: $e');
    }
  }

  @override
  void dispose() {
    try {
      Get.delete<ChatScreenController>(
        tag: 'ChatScreen_${widget.CurrentUserNumber}',
      );
    } catch (e) {
      print('ChatScreen dispose error: $e');
    }

    // Do not disconnect the shared SignalR connection here.
    super.dispose();
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
  // APP BAR — bordered back arrow (primary text color), title, live status
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
                print('ChatScreen back navigation error: $e');
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

  // Reads Controller.IsConnected (a real observable) -> no more Obx crash.
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
  // BODY — one scroll view, so it works at any height (portrait/landscape)
  // ---------------------------------------------------------------------------
  Widget _buildScrollBody(bool isWide, double hPad) {
    // Reading these registers the reactive dependencies.
    final bool loading = Controller.IsLoading.value;
    final String error = Controller.ErrorMessage.value;
    final bool searching = Controller.SearchText.value.trim().isNotEmpty;
    final List<AdminUserInfosModel> users = Controller.GetFilteredUsers();
    final bool noUsersAtAll = Controller.Users.isEmpty;

    Widget content;

    if (loading && noUsersAtAll) {
      content = SliverToBoxAdapter(
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (int i = 0; i < (isWide ? 6 : 3); i++)
              const SizedBox(
                width: 340,
                height: 116,
                child: _SkeletonBox(),
              ),
          ],
        ),
      );
    } else if (error.isNotEmpty && noUsersAtAll) {
      content = SliverToBoxAdapter(
        child: _buildEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load people',
          subtitle: error,
          buttonText: 'Try again',
          onPressed: Controller.LoadUsers,
        ),
      );
    } else if (users.isEmpty) {
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
          onPressed: searching ? Controller.ClearSearch : Controller.LoadUsers,
        ),
      );
    } else {
      content = SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 440,
          mainAxisExtent: 104,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return _Entrance(
              index: math.min(index, 8),
              child: _buildUserCard(users[index], index),
            );
          },
          childCount: users.length,
        ),
      );
    }

    return RefreshIndicator(
      color: ChatAccent,
      backgroundColor: ChatSurface,
      onRefresh: Controller.LoadUsers,
      child: CustomScrollView(
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
            sliver: SliverToBoxAdapter(child: _buildSectionHeader()),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
            sliver: content,
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
                  final int count = Controller.Users.length;
                  final int online = Controller.OnlineCount;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        icon: Icons.people_alt_rounded,
                        text: '$count ${count == 1 ? 'person' : 'people'} available',
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
  // SEARCH
  // ---------------------------------------------------------------------------
  Widget _buildSearch() {
    return TextField(
      controller: Controller.SearchCont,
      onChanged: (value) => Controller.SearchText.value = value,
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
          onPressed: Controller.ClearSearch,
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
  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Icon(Icons.groups_rounded, color: ChatAccent, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'People',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ChatText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Obx(() {
          final bool loading = Controller.IsLoading.value;
          return TextButton.icon(
            onPressed: loading ? null : Controller.LoadUsers,
            icon: loading
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
  // USER CARD — username, user ID and online status only
  // ---------------------------------------------------------------------------
  Widget _buildUserCard(AdminUserInfosModel user, int index) {
    final String fullName =
    '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final String? name = fullName.isEmpty ? null : fullName;
    final int? userNumber = user.userNumber as int?;

    return Obx(() {
      final bool online = Controller.IsUserOnline(userNumber);
      final bool hovered = Controller.HoveredIndex.value == index;
      final Color tone = online ? ChatAccent : ChatMuted;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => Controller.HoveredIndex.value = index,
        onExit: (_) {
          if (Controller.HoveredIndex.value == index) {
            Controller.HoveredIndex.value = -1;
          }
        },
        child: AnimatedScale(
          scale: hovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                try {
                  if (userNumber == null) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatMessageScreen(
                        ReceiverNumber: userNumber,
                        ReceiverName: name ?? 'User $userNumber',
                        CurrentUserNumber: widget.CurrentUserNumber,
                        User_JwtToken: widget.User_JwtToken,
                      ),
                    ),
                  );
                } catch (e) {
                  print('Open chat error: $e');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: ChatSurface.withOpacity(hovered ? 1 : 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hovered
                        ? ChatAccent.withOpacity(0.5)
                        : ChatBorder,
                    width: hovered ? 1.3 : 1,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // status accent bar (replaces the old circular avatar)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: online
                            ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_Emerald, ChatAccent],
                        )
                            : null,
                        color: online ? null : ChatBorder,
                        boxShadow: online
                            ? [
                          BoxShadow(
                            color: ChatAccent.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? 'No data available',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: name == null ? ChatMuted : ChatText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  fontStyle: name == null
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                              const SizedBox(height: 10),

                              Wrap (
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _MiniPill(
                                    icon: Icons.badge_rounded,
                                    text: userNumber == null
                                        ? 'ID: No data'
                                        : 'ID: $userNumber',
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Center(
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 180),
                        offset: Offset(hovered ? 0.2 : 0, 0),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: hovered ? ChatAccent : ChatMuted,
                          size: 14,
                        ),
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
  const _Entrance({required this.index, required this.child});

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
// AMBIENT BACKGROUND — heavily blurred emerald/mint blobs + glass bubbles.
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