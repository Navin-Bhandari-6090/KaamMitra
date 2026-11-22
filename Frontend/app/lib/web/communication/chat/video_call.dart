import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;

import '../../../state management/getx/communication/video_call_getx.dart';
import 'chat_screen.dart';

const Color _Emerald = Color(0xFF22C55E);
const Color _Warn = Color(0xFFFBBF24);
const Color _Danger = Color(0xFFEF4444);

// =============================================================================
// VIDEO CALL UI (the call window and the call error banner)
// Use VideoCallOverlay on top of any screen: while idle it draws nothing and
// never blocks taps.
// =============================================================================
class VideoCallOverlay extends StatelessWidget {
  final VideoCallGetx controller;
  final String name;
  final String photoUrl;

  const VideoCallOverlay({
    super.key,
    required this.controller,
    required this.name,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final CallStage stage = controller.callStage.value;
      if (stage == CallStage.idle) {
        return const IgnorePointer(child: SizedBox.shrink());
      }
      return _VideoCallView(
        controller: controller,
        name: name,
        photoUrl: photoUrl,
      );
    });
  }
}

// Shown when a call failed and the call window is closed again.
class CallErrorBanner extends StatelessWidget {
  final VideoCallGetx controller;

  const CallErrorBanner({super.key, required this.controller});

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
                      // print('Dismiss banner error: $e');
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
// CALL WINDOW
// =============================================================================
class _VideoCallView extends StatelessWidget {
  final VideoCallGetx controller;
  final String name;
  final String photoUrl;

  const _VideoCallView({
    required this.controller,
    required this.name,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.8),
            radius: 1.4,
            colors: [Color(0xFF193A29), ChatBackground],
          ),
        ),
        child: SafeArea(
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
                        _CallHeader(
                          controller: controller,
                          name: name,
                          photoUrl: photoUrl,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _RemoteStage(
                            controller: controller,
                            name: name,
                            photoUrl: photoUrl,
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
      ),
    );
  }
}

class _CallHeader extends StatelessWidget {
  final VideoCallGetx controller;
  final String name;
  final String photoUrl;

  const _CallHeader({
    required this.controller,
    required this.name,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CallAvatar(photoUrl: photoUrl, size: 42),
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
  final VideoCallGetx controller;
  final String name;
  final String photoUrl;
  final bool landscape;

  const _RemoteStage({
    required this.controller,
    required this.name,
    required this.photoUrl,
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
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                );
              }
              return Center(
                child: _PulseAvatar(
                  photoUrl: photoUrl,
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
  final VideoCallGetx controller;
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
  final VideoCallGetx controller;

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
                  // print('Call control "$label" error: $e');
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

// Photo when there is one, people icon when empty or broken.
class _CallAvatar extends StatelessWidget {
  final String photoUrl;
  final double size;

  const _CallAvatar({required this.photoUrl, required this.size});

  Widget _fallback() {
    return Container(
      color: ChatHeader,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: ChatMuted, size: size * 0.58),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ChatAccent.withOpacity(0.6), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: _Emerald.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
    );
  }
}

class _PulseAvatar extends StatefulWidget {
  final String photoUrl;
  final bool active;

  const _PulseAvatar({required this.photoUrl, required this.active});

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
          _CallAvatar(photoUrl: widget.photoUrl, size: size),
        ],
      ),
    );
  }
}