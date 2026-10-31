import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../../models/ChatInfoModel.dart';
import '../../../state management/getx/communication/message_screen_getx.dart';
import 'chat_screen.dart';

const Color _Emerald = Color(0xFF22C55E);
const Color _Warn = Color(0xFFFBBF24);
const Color _Danger = Color(0xFFEF4444);

// =============================================================================
// SCREEN (StatefulWidget only for controller lifecycle, zero setState)
// =============================================================================
class ChatMessageScreen extends StatefulWidget {
  final int ReceiverNumber;
  final String ReceiverName;
  final int CurrentUserNumber;
  final String User_JwtToken;

  const ChatMessageScreen({
    super.key,
    required this.ReceiverNumber,
    required this.ReceiverName,
    required this.CurrentUserNumber,
    required this.User_JwtToken,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {

  MessageScreenGetx? Controller;
  String? _tag;

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
        ),
        tag: _tag,
      );
    } catch (e) {
      print('ChatMessageScreen initState error: $e');
    }
  }

  @override
  void dispose() {
    try {
      if (_tag != null) {
        Get.delete<MessageScreenGetx>(tag: _tag);
      }
    } catch (e) {
      print('ChatMessageScreen dispose error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MessageScreenGetx? c = Controller;

    return Scaffold(
      backgroundColor: ChatBackground,
      appBar: _buildAppBar(c),
      body: c == null
          ? _buildFallback()
          : Stack(
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
                        Expanded(
                          child: _buildMessageArea(c, maxBubble, hPad),
                        ),
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
            child: _CallErrorBanner(controller: c),
          ),
          // Call overlay: IgnorePointer when idle so it never blocks taps.
          Positioned.fill(
            child: Obx(() {
              final CallStage stage = c.callStage.value;
              if (stage == CallStage.idle) {
                return const IgnorePointer(child: SizedBox.shrink());
              }
              return _VideoCallView(controller: c, name: _name);
            }),
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
              print('Fallback back error: $e');
            }
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR: bordered back arrow, name, live online/offline, video call action
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(MessageScreenGetx? c) {
    return AppBar(
      backgroundColor: ChatHeader,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
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
                print('Back navigation error: $e');
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
          _Avatar(name: widget.ReceiverName, size: 38),
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
                _buildPresence(c),
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
                    c?.startCall();
                  } catch (e) {
                    print('Start call tap error: $e');
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

  Widget _buildPresence(MessageScreenGetx? c) {
    if (c == null) {
      return const _PresenceLabel(online: false);
    }
    return Obx(() => _PresenceLabel(online: c.isOnlineNow.value));
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
      final bool loading = c.isLoading.value;
      final String error = c.loadError.value;
      final List<ChatInfoModel> list = c.messages.toList();

      if (loading && list.isEmpty) {
        return _buildSkeleton(maxBubble, hPad);
      }

      if (list.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(hPad),
            child: _StateCard(
              icon: error.isNotEmpty
                  ? Icons.cloud_off_rounded
                  : Icons.chat_bubble_outline_rounded,
              title: error.isNotEmpty
                  ? 'Could not load messages'
                  : 'No data available',
              subtitle: error.isNotEmpty
                  ? error
                  : 'Say hello to start the conversation.',
              buttonText: 'Refresh',
              onPressed: () {
                try {
                  c.refreshMessages();
                } catch (e) {
                  print('Refresh tap error: $e');
                }
              },
            ),
          ),
        );
      }

      // List is sorted oldest to newest. A reversed ListView shows the newest
      // message at the bottom, next to the composer.
      return ListView.builder(
        reverse: true,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 14),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final int index = list.length - 1 - i;
          final ChatInfoModel m = list[index];

          return _Reveal(
            index: math.min(i, 6),
            child: _MessageBubble(
              message: m,
              mine: m.senderNumber == c.myNumber,
              maxWidth: maxBubble,
            ),
          );
        },
      );
    });
  }

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

  // ---------------------------------------------------------------------------
  // COMPOSER
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
              child: TextField(
                controller: c.textCont,
                onChanged: (value) => c.draft.value = value,
                minLines: 1,
                maxLines: 5,
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
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Obx(() => _SendButton(
                hasText: c.draft.value.trim().isNotEmpty,
                sending: c.isSending.value,
                onTap: () {
                  try {
                    c.requestSend();
                    c.textCont.clear();
                  } catch (e) {
                    print('Send tap error: $e');
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
// CALL ERROR BANNER
// =============================================================================
class _CallErrorBanner extends StatelessWidget {
  final MessageScreenGetx controller;

  const _CallErrorBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String msg = controller.callError.value;
      final bool inCall = controller.callStage.value != CallStage.idle;

      if (msg.isEmpty || inCall) {
        return const SizedBox.shrink();
      }

      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _Danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _Danger.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: _Danger, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(
                      color: ChatText,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded,
                      color: ChatMuted, size: 18),
                  onPressed: () {
                    try {
                      controller.callError.value = '';
                    } catch (e) {
                      print('Dismiss banner error: $e');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// =============================================================================
// VIDEO CALL VIEW
// =============================================================================
class _VideoCallView extends StatelessWidget {
  final MessageScreenGetx controller;
  final String name;

  const _VideoCallView({required this.controller, required this.name});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        color: ChatBackground,
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: _MessageAmbientBackground()),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, box) {
                  final bool landscape = box.maxWidth > box.maxHeight;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: Column(
                          children: [
                            _CallHeader(controller: controller, name: name),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _RemoteStage(
                                controller: controller,
                                name: name,
                                landscape: landscape,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _CallControls(controller: controller),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallHeader extends StatelessWidget {
  final MessageScreenGetx controller;
  final String name;

  const _CallHeader({required this.controller, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(name: name, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ChatText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Obx(() {
                final CallStage s = controller.callStage.value;
                final Color tone = s == CallStage.connected
                    ? ChatAccent
                    : s == CallStage.incoming
                    ? _Warn
                    : ChatMuted;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tone,
                        boxShadow: [
                          BoxShadow(
                              color: tone.withOpacity(0.6), blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.callStatusText,
                      style: TextStyle(
                        color: tone,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _RemoteStage extends StatelessWidget {
  final MessageScreenGetx controller;
  final String name;
  final bool landscape;

  const _RemoteStage({
    required this.controller,
    required this.name,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ChatBorder),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF193A29), Color(0xFF0C1A13)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              if (controller.remoteVideoReady.value) {
                return RTCVideoView(
                  controller.remoteRenderer,
                  objectFit:
                  RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                );
              }
              return Center(
                child: _PulseAvatar(
                  name: name,
                  active: controller.callStage.value != CallStage.connected,
                ),
              );
            }),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: _NameTag(name: name),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _LocalTile(controller: controller, landscape: landscape),
          ),
        ],
      ),
    );
  }
}

class _LocalTile extends StatelessWidget {
  final MessageScreenGetx controller;
  final bool landscape;

  const _LocalTile({required this.controller, required this.landscape});

  @override
  Widget build(BuildContext context) {
    final double w = landscape ? 150 : 108;
    final double h = landscape ? 96 : 146;

    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ChatHeader,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChatAccent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              if (!controller.camOn.value) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off_rounded,
                          color: ChatMuted, size: 22),
                      SizedBox(height: 4),
                      Text(
                        'Camera off',
                        style: TextStyle(color: ChatMuted, fontSize: 10),
                      ),
                    ],
                  ),
                );
              }
              return RTCVideoView(
                controller.localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              );
            }),
          ),
          const Positioned(
            left: 8,
            bottom: 6,
            child: Text(
              'You',
              style: TextStyle(
                color: ChatText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Obx(() => Icon(
              controller.micOn.value
                  ? Icons.mic_rounded
                  : Icons.mic_off_rounded,
              size: 15,
              color: controller.micOn.value ? ChatAccent : _Danger,
            )),
          ),
        ],
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final MessageScreenGetx controller;

  const _CallControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double size = (math.min(screen.width, screen.height) * 0.16)
        .clamp(48.0, 66.0)
        .toDouble();

    return Obx(() {
      if (controller.callStage.value == CallStage.incoming) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CallControl(
              icon: Icons.call_end_rounded,
              label: 'Decline',
              danger: true,
              size: size,
              onTap: controller.declineCall,
            ),
            const SizedBox(width: 40),
            _CallControl(
              icon: Icons.videocam_rounded,
              label: 'Accept',
              positive: true,
              size: size,
              onTap: controller.acceptCall,
            ),
          ],
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CallControl(
            icon: controller.micOn.value
                ? Icons.mic_rounded
                : Icons.mic_off_rounded,
            label: 'Mic',
            active: controller.micOn.value,
            size: size,
            onTap: controller.toggleMic,
          ),
          const SizedBox(width: 18),
          _CallControl(
            icon: controller.camOn.value
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: 'Camera',
            active: controller.camOn.value,
            size: size,
            onTap: controller.toggleCamera,
          ),
          const SizedBox(width: 18),
          _CallControl(
            icon: controller.speakerOn.value
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: 'Speaker',
            active: controller.speakerOn.value,
            size: size,
            onTap: controller.toggleSpeaker,
          ),
          const SizedBox(width: 18),
          _CallControl(
            icon: Icons.call_end_rounded,
            label: 'End',
            danger: true,
            size: size + 4,
            onTap: controller.endCall,
          ),
        ],
      );
    });
  }
}

class _CallControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final bool positive;
  final double size;
  final VoidCallback onTap;

  const _CallControl({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.size,
    this.active = true,
    this.danger = false,
    this.positive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool filled = danger || positive;
    final Color fill = danger
        ? _Danger
        : positive
        ? _Emerald
        : (active ? ChatSurface : ChatText);
    final Color iconColor =
    filled ? Colors.white : (active ? ChatText : ChatBackground);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                try {
                  onTap();
                } catch (e) {
                  print('Call control "$label" error: $e');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    color: filled ? Colors.transparent : ChatBorder,
                  ),
                  boxShadow: filled
                      ? [
                    BoxShadow(
                      color: fill.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                      : const [],
                ),
                child: Icon(icon, size: size * 0.42, color: iconColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: ChatMuted, fontSize: 11),
        ),
      ],
    );
  }
}

// =============================================================================
// SMALL SHARED PIECES
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
        const SizedBox(width: 6),
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

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final String t = name.trim();
    final String initial = t.isEmpty ? '?' : t[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Emerald, ChatAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: _Emerald.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: ChatBackground,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class _NameTag extends StatelessWidget {
  final String name;

  const _NameTag({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ChatHeader.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ChatBorder),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ChatText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PulseAvatar extends StatefulWidget {
  final String name;
  final bool active;

  const _PulseAvatar({required this.name, required this.active});

  @override
  State<_PulseAvatar> createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<_PulseAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double size = (math.min(screen.width, screen.height) * 0.25)
        .clamp(84.0, 150.0)
        .toDouble();

    return SizedBox(
      width: size * 2.2,
      height: size * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active)
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _ac,
                builder: (context, child) {
                  final double t = (_ac.value + i / 3) % 1.0;
                  final double d = size + t * size * 1.2;
                  return Container(
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ChatAccent.withOpacity((1 - t) * 0.35),
                        width: 1.5,
                      ),
                    ),
                  );
                },
              );
            }),
          _Avatar(name: widget.name, size: size),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool hasText;
  final bool sending;
  final VoidCallback onTap;

  const _SendButton({
    required this.hasText,
    required this.sending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = hasText || sending;

    return Tooltip(
      message: 'Send',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: active
              ? const LinearGradient(colors: [_Emerald, ChatAccent])
              : null,
          color: active ? null : ChatBorder,
          boxShadow: active
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
            onTap: (hasText && !sending) ? onTap : null,
            child: Center(
              child: sending
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ChatBackground,
                ),
              )
                  : Icon(
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
  final ChatInfoModel message;
  final bool mine;
  final double maxWidth;

  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final String text = '${message.message ?? ''}'.trim();
    final DateTime? sentAt = parseServerTime('${message.storeAt ?? ''}');
    final bool empty = text.isEmpty;

    const Radius big = Radius.circular(20);
    const Radius small = Radius.circular(6);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
          decoration: BoxDecoration(
            gradient: mine
                ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_Emerald, ChatAccent],
            )
                : null,
            color: mine ? null : ChatSurface,
            borderRadius: BorderRadius.only(
              topLeft: big,
              topRight: big,
              bottomLeft: mine ? big : small,
              bottomRight: mine ? small : big,
            ),
            border: mine ? null : Border.all(color: ChatBorder),
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
              Text(
                empty ? 'No data available' : text,
                style: TextStyle(
                  color: empty
                      ? ChatMuted
                      : (mine ? ChatBackground : ChatText),
                  fontSize: 14.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timeLabel(sentAt),
                      style: TextStyle(
                        color: mine
                            ? ChatBackground.withOpacity(0.65)
                            : ChatMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: ChatBackground.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime? t) {
    if (t == null) return 'No data available';
    final int h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String mm = t.minute.toString().padLeft(2, '0');
    final String ap = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$mm $ap';
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

class _Reveal extends StatelessWidget {
  final int index;
  final Widget child;

  const _Reveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + index * 40),
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
              _blob(
                left: -w * 0.2,
                top: -h * 0.1,
                size: base * 0.65,
                color: _Emerald,
                opacity: 0.14,
              ),
              _blob(
                right: -w * 0.25,
                bottom: h * 0.05,
                size: base * 0.6,
                color: ChatAccent,
                opacity: 0.10,
              ),
              _blob(
                left: w * 0.1,
                bottom: -h * 0.2,
                size: base * 0.7,
                color: _Emerald,
                opacity: 0.10,
              ),
              _bubble(
                right: w * 0.12,
                top: h * 0.12,
                size: (small * 0.16).clamp(40.0, 150.0).toDouble(),
              ),
              _bubble(
                left: w * 0.05,
                top: h * 0.45,
                size: (small * 0.10).clamp(28.0, 100.0).toDouble(),
              ),
              _bubble(
                right: w * 0.2,
                bottom: h * 0.12,
                size: (small * 0.18).clamp(50.0, 180.0).toDouble(),
              ),
            ],
          );
        },
      ),
    );
  }
}