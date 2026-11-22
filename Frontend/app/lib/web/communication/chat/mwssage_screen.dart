import 'dart:math' as math;
import 'dart:ui';

import 'package:app/web/communication/chat/video_call.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../state management/getx/communication/message_screen_getx.dart';
import '../../../state management/getx/communication/video_call_getx.dart';

import '../../common method/communicationcommonmethod.dart';
import 'chat_screen.dart';


const Color _Emerald = Color(0xFF22C55E);
const Color _Warn = Color(0xFFFBBF24);
const Color _Danger = Color(0xFFEF4444);
const Color _ReadTick = Color(0xFF0C4A6E); // deep blue, readable on green

// =============================================================================
// SCREEN (StatefulWidget only for controller lifecycle, zero setState)
// =============================================================================
class ChatMessageScreen extends StatefulWidget {
  final int ReceiverNumber;
  final String ReceiverName;
  final int CurrentUserNumber;
  final String CurrentUserName;
  final String CurrentUserPhotoPath;
  final String ReceiverPhotoPath;

  final String User_JwtToken;

  const ChatMessageScreen({
    super.key,
    required this.ReceiverNumber,
    required this.ReceiverName,
    required this.CurrentUserNumber,
    required this.User_JwtToken,
    required this.CurrentUserName,
    required this.CurrentUserPhotoPath,
    required this.ReceiverPhotoPath,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  MessageScreenGetx? Controller;
  VideoCallGetx? Call;
  String? _tag;

  // The list is reversed: offset 0 is the newest message (bottom).
  final ScrollController _scroll = ScrollController();

  String get _name {
    final String n = widget.ReceiverName.trim();
    return n.isEmpty ? 'No data available' : n;
  }

  @override
  void initState() {
    super.initState();

    try {
      _tag = 'Chat_${widget.CurrentUserNumber}_${widget.ReceiverNumber}';

      Controller = Get.put(
        MessageScreenGetx(
          myNumber: widget.CurrentUserNumber,
          otherNumber: widget.ReceiverNumber,
          otherName: _name,
          jwtToken: widget.User_JwtToken,
          otherPhotoPath: widget.ReceiverPhotoPath,
          myPhotoPath: widget.CurrentUserPhotoPath,
        ),
        tag: _tag,
      );

      Call = Get.put(
        VideoCallGetx(
          myNumber: widget.CurrentUserNumber,
          otherNumber: widget.ReceiverNumber,
        ),
        tag: _tag,
      );

      Controller!.ScrollToLatest = _scrollToLatest;
      _scroll.addListener(_onScroll);
    } catch (e) {
      // print('ChatMessageScreen initState error: $e');
    }
  }

  @override
  void dispose() {
    try {
      Controller?.ScrollToLatest = null;
      _scroll.removeListener(_onScroll);
      _scroll.dispose();

      if (_tag != null) {
        Get.delete<VideoCallGetx>(tag: _tag);
        Get.delete<MessageScreenGetx>(tag: _tag);
      }
    } catch (e) {
      // print('ChatMessageScreen dispose error: $e');
    }
    super.dispose();
  }

  void _onScroll() {
    try {
      if (!_scroll.hasClients) return;
      final ScrollPosition p = _scroll.position;

      Controller?.SetAtBottom(p.pixels <= 80);

      // Near the top (oldest loaded message): load the page before it.
      if (p.maxScrollExtent - p.pixels < 300) Controller?.LoadOlder();
    } catch (e) {
      // print('ChatMessageScreen scroll error: $e');
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      } catch (e) {
        // print('ChatMessageScreen scroll to latest error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final MessageScreenGetx? c = Controller;
    final VideoCallGetx? call = Call;

    if (c == null || call == null) {
      return Scaffold(
        backgroundColor: ChatBackground,
        body: _buildFallback(),
      );
    }

    return Scaffold(
      backgroundColor: ChatBackground,
      appBar: _buildAppBar(c, call),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _MessageAmbientBackground()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final bool isWide = box.maxWidth >= 760;
                final double hPad = isWide ? 24 : 12;
                final double maxBubble =
                (box.maxWidth * 0.74).clamp(220.0, 520.0).toDouble();

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        _buildConnectionBanner(c, hPad),
                        Expanded(
                          child: Stack(
                            children: [
                              _buildMessageArea(c, maxBubble, hPad),
                              Positioned(
                                right: hPad + 4,
                                bottom: 10,
                                child: _buildJumpButton(c),
                              ),
                            ],
                          ),
                        ),
                        _buildNotice(c, hPad),
                        _buildComposer(c, hPad),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Call error banner (shown when the call is idle again).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CallErrorBanner(controller: call),
          ),
          // Call window: draws nothing while idle, never blocks taps.
          Positioned.fill(
            child: Obx(() => VideoCallOverlay(
              controller: call,
              name: _name,
              photoUrl: MsgPhotoUrl(c.OtherPhoto.value),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _StateCard(
          icon: Icons.cloud_off_rounded,
          title: 'Could not open this chat',
          subtitle: 'Please go back and try again.',
          buttonText: 'Go back',
          onPressed: () {
            try {
              Get.back();
            } catch (e) {
              // print('Fallback back error: $e');
            }
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR: back arrow, photo, full name, ID, live online/offline, video call
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(MessageScreenGetx c, VideoCallGetx call) {
    return AppBar(
      backgroundColor: ChatHeader,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      titleSpacing: 0,
      toolbarHeight: 64,
      leading: Center(
        child: Tooltip(
          message: 'Back',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              try {
                Get.back();
              } catch (e) {
                // print('Back navigation error: $e');
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
          Obx(() => _PhotoAvatar(
            photoUrl: MsgPhotoUrl(c.OtherPhoto.value),
            online: c.IsOnline.value,
            size: 42,
          )),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _name == 'No data available' ? ChatMuted : ChatText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    fontStyle: _name == 'No data available'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'ID: ${widget.ReceiverNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ChatMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() => _PresenceLabel(online: c.IsOnline.value)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Tooltip(
              message: 'Video call',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  try {
                    call.startCall();
                  } catch (e) {
                    // print('Start call tap error: $e');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_Emerald, ChatAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _Emerald.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: ChatBackground,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: ChatBorder),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BANNERS (connection lost, send error)
  // ---------------------------------------------------------------------------
  Widget _buildConnectionBanner(MessageScreenGetx c, double hPad) {
    return Obx(() {
      if (c.IsConnected.value) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _Warn.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Warn.withOpacity(0.40)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: _Warn),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Reconnecting... new messages may arrive late. '
                    'Your messages still send.',
                style: TextStyle(color: ChatText, fontSize: 12, height: 1.3),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNotice(MessageScreenGetx c, double hPad) {
    return Obx(() {
      final String text = c.Notice.value;
      if (text.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(hPad, 6, hPad, 0),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: _Danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Danger.withOpacity(0.45)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _Danger, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                    color: ChatText, fontSize: 12.5, height: 1.3),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              icon:
              const Icon(Icons.close_rounded, color: ChatMuted, size: 16),
              onPressed: c.ClearNotice,
            ),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // MESSAGE LIST
  // ---------------------------------------------------------------------------
  Widget _buildMessageArea(
      MessageScreenGetx c,
      double maxBubble,
      double hPad,
      ) {
    return Obx(() {
      final bool loading = c.IsLoading.value;
      final String error = c.LoadError.value;
      final List<MsgItem> items = c.Items.toList();
      final bool hasMoreOlder = c.HasMoreOlder.value;
      final bool loadingOlder = c.IsLoadingOlder.value;

      if (loading && items.isEmpty) {
        return _buildSkeleton(maxBubble, hPad);
      }

      if (items.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(hPad),
            child: _StateCard(
              icon: error.isNotEmpty
                  ? Icons.cloud_off_rounded
                  : Icons.chat_bubble_outline_rounded,
              title: error.isNotEmpty
                  ? 'Could not load messages'
                  : 'No messages yet',
              subtitle: error.isNotEmpty
                  ? error
                  : 'Say hello to start the conversation.',
              buttonText: error.isNotEmpty ? 'Try again' : null,
              onPressed: error.isNotEmpty ? c.Refresh : null,
            ),
          ),
        );
      }

      // items are oldest -> newest. The reversed list shows the newest at the
      // bottom, next to the composer. One extra row at the top shows the
      // "loading older" spinner or the start of the conversation.
      return ListView.builder(
        controller: _scroll,
        reverse: true,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 14),
        itemCount: items.length + 1,
        findChildIndexCallback: (Key key) {
          if (key is ValueKey<String>) {
            final int idx = items.indexWhere((m) => _keyOf(m) == key.value);
            if (idx >= 0) return items.length - 1 - idx;
          }
          return null;
        },
        itemBuilder: (context, i) {
          // The top row (oldest side).
          if (i == items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: loadingOlder
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: ChatAccent,
                  ),
                )
                    : hasMoreOlder
                    ? const SizedBox.shrink()
                    : const Text(
                  'Start of the conversation',
                  style: TextStyle(color: ChatMuted, fontSize: 11.5),
                ),
              ),
            );
          }

          final int index = items.length - 1 - i;
          final MsgItem m = items[index];
          final MsgItem? older = index > 0 ? items[index - 1] : null;

          // A day label above the first message of every day.
          final bool showDay = older == null
              ? !hasMoreOlder
              : !c.SameDay(older.time, m.time);

          // Messages of one sender close in time sit closer together.
          final bool tight = older != null &&
              !showDay &&
              older.senderNumber == m.senderNumber &&
              m.time.difference(older.time).inMinutes.abs() < 5;

          return Column(
            key: ValueKey<String>(_keyOf(m)),
            children: [
              if (showDay) _DayChip(label: c.DayLabel(m.time)),
              _Reveal(
                animate: i < 3,
                child: _MessageBubble(
                  item: m,
                  mine: m.senderNumber == c.myNumber,
                  maxWidth: maxBubble,
                  tight: tight,
                  timeLabel: c.TimeLabel(m.time),
                  onRetry: () => c.Retry(m.clientId),
                  onDelete: () => c.DiscardFailed(m.clientId),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  String _keyOf(MsgItem m) => m.chatId > 0 ? 'm${m.chatId}' : 'p${m.clientId}';

  Widget _buildSkeleton(double maxBubble, double hPad) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 14),
      children: [
        _SkeletonBubble(width: maxBubble * 0.6, height: 52, mine: false),
        _SkeletonBubble(width: maxBubble * 0.45, height: 40, mine: true),
        _SkeletonBubble(width: maxBubble * 0.7, height: 64, mine: false),
        _SkeletonBubble(width: maxBubble * 0.5, height: 44, mine: true),
      ],
    );
  }

  // "Jump to latest" with the number of new messages while scrolled up.
  Widget _buildJumpButton(MessageScreenGetx c) {
    return Obx(() {
      if (c.IsAtBottom.value) return const SizedBox.shrink();

      final int unseen = c.UnseenCount.value;

      return Tooltip(
        message: 'Latest messages',
        child: Material(
          color: ChatSurface,
          shape: const CircleBorder(side: BorderSide(color: ChatBorder)),
          elevation: 6,
          shadowColor: Colors.black,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              try {
                _scrollToLatest();
              } catch (e) {
                // print('Jump to latest error: $e');
              }
            },
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: ChatAccent, size: 26),
                  if (unseen > 0)
                    Positioned(
                      top: -6,
                      right: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ChatAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          unseen > 99 ? '99+' : '$unseen',
                          style: const TextStyle(
                            color: ChatBackground,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // COMPOSER (Enter sends, Shift+Enter makes a new line)
  // ---------------------------------------------------------------------------
  Widget _buildComposer(MessageScreenGetx c, double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
        decoration: BoxDecoration(
          color: ChatSurface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: ChatBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.enter): () {
                    try {
                      c.SendMessage();
                    } catch (e) {
                      // print('Enter send error: $e');
                    }
                  },
                },
                child: TextField(
                  controller: c.textCont,
                  onChanged: (value) => c.Draft.value = value,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 4000,
                  buildCounter: (context,
                      {required currentLength,
                        required isFocused,
                        maxLength}) =>
                  null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: ChatAccent,
                  style: const TextStyle(color: ChatText, fontSize: 14.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: ChatMuted, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Obx(() => _SendButton(
                hasText: c.Draft.value.trim().isNotEmpty,
                onTap: () {
                  try {
                    c.SendMessage();
                  } catch (e) {
                    // print('Send tap error: $e');
                  }
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SMALL PIECES
// =============================================================================
class _PresenceLabel extends StatelessWidget {
  final bool online;

  const _PresenceLabel({required this.online});

  @override
  Widget build(BuildContext context) {
    final Color tone = online ? ChatAccent : ChatMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tone,
            boxShadow: online
                ? [BoxShadow(color: tone.withOpacity(0.6), blurRadius: 6)]
                : const [],
          ),
        ),
        const SizedBox(width: 5),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            online ? 'Online' : 'Offline',
            key: ValueKey<bool>(online),
            style: TextStyle(
              color: tone,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// Photo when there is one, people icon when empty / null / broken.
class _PhotoAvatar extends StatelessWidget {
  final String photoUrl;
  final bool online;
  final double size;

  const _PhotoAvatar({
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
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? ChatAccent : ChatMuted,
                border: Border.all(color: ChatHeader, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;

  const _DayChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: ChatSurface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ChatBorder),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: ChatMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool hasText;
  final VoidCallback onTap;

  const _SendButton({required this.hasText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Send',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasText
              ? const LinearGradient(colors: [_Emerald, ChatAccent])
              : null,
          color: hasText ? null : ChatBorder,
          boxShadow: hasText
              ? [
            BoxShadow(
              color: _Emerald.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: hasText ? onTap : null,
            child: Center(
              child: Icon(
                Icons.send_rounded,
                color: hasText ? ChatBackground : ChatMuted,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MsgItem item;
  final bool mine;
  final double maxWidth;
  final bool tight;
  final String timeLabel;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.item,
    required this.mine,
    required this.maxWidth,
    required this.tight,
    required this.timeLabel,
    required this.onRetry,
    required this.onDelete,
  });

  Widget _statusIcon() {
    switch (item.state) {
      case MsgSendState.sending:
        return Icon(Icons.schedule_rounded,
            size: 12, color: ChatBackground.withOpacity(0.65));
      case MsgSendState.failed:
        return const Icon(Icons.error_outline_rounded,
            size: 13, color: _Danger);
      case MsgSendState.sent:
        return item.isRead
            ? const Icon(Icons.done_all_rounded, size: 14, color: _ReadTick)
            : Icon(Icons.done_rounded,
            size: 14, color: ChatBackground.withOpacity(0.7));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool failed = item.state == MsgSendState.failed;
    final String text = item.text.trim();

    const Radius big = Radius.circular(20);
    const Radius small = Radius.circular(6);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment:
          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: tight ? 2 : 8, bottom: 2),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
              decoration: BoxDecoration(
                gradient: (mine && !failed)
                    ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_Emerald, ChatAccent],
                )
                    : null,
                color: failed
                    ? _Danger.withOpacity(0.20)
                    : (mine ? null : ChatSurface),
                borderRadius: BorderRadius.only(
                  topLeft: big,
                  topRight: big,
                  bottomLeft: mine ? big : small,
                  bottomRight: mine ? small : big,
                ),
                border: failed
                    ? Border.all(color: _Danger.withOpacity(0.6))
                    : (mine ? null : Border.all(color: ChatBorder)),
                boxShadow: [
                  BoxShadow(
                    color: mine
                        ? _Emerald.withOpacity(0.22)
                        : Colors.black.withOpacity(0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    text,
                    style: TextStyle(
                      color: failed
                          ? ChatText
                          : (mine ? ChatBackground : ChatText),
                      fontSize: 14.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeLabel,
                          style: TextStyle(
                            color: failed
                                ? ChatMuted
                                : (mine
                                ? ChatBackground.withOpacity(0.65)
                                : ChatMuted),
                            fontSize: 10,
                          ),
                        ),
                        if (mine) ...[
                          const SizedBox(width: 4),
                          _statusIcon(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (failed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Not sent',
                    style: TextStyle(color: _Danger, fontSize: 11.5),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: ChatAccent,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: ChatMuted,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBubble extends StatefulWidget {
  final double width;
  final double height;
  final bool mine;

  const _SkeletonBubble({
    required this.width,
    required this.height,
    required this.mine,
  });

  @override
  State<_SkeletonBubble> createState() => _SkeletonBubbleState();
}

class _SkeletonBubbleState extends State<_SkeletonBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.4, end: 1)
            .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut)),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.mine
                ? _Emerald.withOpacity(0.12)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ChatBorder),
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: ChatSurface.withOpacity(0.9),
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ChatAccent.withOpacity(0.10),
                border: Border.all(color: ChatAccent.withOpacity(0.28)),
              ),
              child: Icon(icon, color: ChatAccent, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ChatText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ChatMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 18),
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
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Slides a new message in. Older rows (scrolled into view) appear at once.
class _Reveal extends StatelessWidget {
  final bool animate;
  final Widget child;

  const _Reveal({required this.animate, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 14),
          child: ch,
        ),
      ),
      child: child,
    );
  }
}

// =============================================================================
// AMBIENT BACKGROUND: blurred emerald blobs and glass bubbles, never interactive
// =============================================================================
class _MessageAmbientBackground extends StatelessWidget {
  const _MessageAmbientBackground();

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
        ImageFilter.blur(sigmaX: 40, sigmaY: 40, tileMode: TileMode.decal),
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
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.01),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.hasBoundedWidth ? box.maxWidth : 800;
          final double h = box.hasBoundedHeight ? box.maxHeight : 800;
          final double base = math.max(w, h);
          final double small = math.min(w, h);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              _blob(left: -w * 0.2, top: -h * 0.1, size: base * 0.65, color: _Emerald, opacity: 0.14),
              _blob(right: -w * 0.25, bottom: h * 0.05, size: base * 0.6, color: ChatAccent, opacity: 0.10),
              _blob(left: w * 0.1, bottom: -h * 0.2, size: base * 0.7, color: _Emerald, opacity: 0.10),
              _bubble(right: w * 0.12, top: h * 0.12, size: (small * 0.16).clamp(40.0, 150.0).toDouble()),
              _bubble(left: w * 0.05, top: h * 0.45, size: (small * 0.10).clamp(28.0, 100.0).toDouble()),
              _bubble(right: w * 0.2, bottom: h * 0.12, size: (small * 0.18).clamp(50.0, 180.0).toDouble()),
            ],
          );
        },
      ),
    );
  }
}