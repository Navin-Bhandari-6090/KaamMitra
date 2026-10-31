import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../state management/getx/booking/view_video_getx.dart';

// Palette

class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color borderStrong = Color(0xFF2F5A43);
  static const Color danger = Color(0xFFF87171);
}

// SCREEN

class ViewBookVideo extends StatefulWidget {
  final String Current_User_JwtToken;
  final String VideoPath;
  const ViewBookVideo(
      {super.key, required this.Current_User_JwtToken, required this.VideoPath});

  @override
  State<ViewBookVideo> createState() => _ViewBookVideoState();
}

class _ViewBookVideoState extends State<ViewBookVideo> {
  late final ViewVideoGetx controller;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    All_User_Jwt_Verify(
        Jwt_Token: widget.Current_User_JwtToken, context: context);
    super.initState();
    controller = Get.put(ViewVideoGetx(), tag: _tag);
    controller.init(
      jwtToken: widget.Current_User_JwtToken,
      videoPath: widget.VideoPath,
    );
  }

  @override
  void dispose() {
    Get.delete<ViewVideoGetx>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _BorderIconButton(
            tooltip: 'Back',
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const Text(
          'View Booking Video',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: Obx(() => _BorderIconButton(
              tooltip: 'Download',
              icon: Icons.download_rounded,
              onTap: (controller.hasValidPath.value && !controller.isBusy)
                  ? controller.requestDownload
                  : null,
            )),
          ),
        ],
      ),
      body: ForestBackground(
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SafeArea(
            top: false,
            child: _Body(controller: controller),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// BODY - responsive shell (never overflows, even at tiny sizes)
// ===========================================================================
class _Body extends StatelessWidget {
  final ViewVideoGetx controller;
  const _Body({required this.controller});

  static const double _minW = 280;
  static const double _minH = 460;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth.isFinite ? c.maxWidth : 360;
      final double h = c.maxHeight.isFinite ? c.maxHeight : 640;
      final double contentW = math.max(w, _minW);
      final double contentH = math.max(h, _minH);
      final double pad = w < 600 ? 12 : 24;
      final bool compact = h < 560;

      final Widget content = SizedBox(
        width: contentW,
        height: contentH,
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 12),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Obx(() {
                if (!controller.hasValidPath.value) {
                  return const _EmptyState();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Reveal(
                        child:
                        _FileHeader(c: controller, compact: compact)),
                    _DownloadBanner(c: controller),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _Reveal(
                          delayMs: 120, child: _ViewerCard(c: controller)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      );

      // Normal screens: NO outer scroll views at all, so the PDF viewer
      // receives every horizontal / vertical scroll and drag by itself.
      // Outer scrolling is only added when the window is smaller than the
      // minimum layout size.
      if (w >= _minW && h >= _minH) return content;

      Widget scrollable = content;
      if (h < _minH) {
        scrollable = SingleChildScrollView(child: scrollable);
      }
      if (w < _minW) {
        scrollable = SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: scrollable);
      }
      return scrollable;
    });
  }
}

// ===========================================================================
// REUSABLE PIECES
// ===========================================================================

/// Fade + slide-up entrance.
class _Reveal extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _Reveal({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    final int total = 500 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
      ),
      child: child,
    );
  }
}

/// Frosted-glass container.
class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bordered square icon button (used for the AppBar back arrow too).
class _BorderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _BorderIconButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: enabled ? _C.borderStrong : _C.border, width: 1.3),
            ),
            child: Icon(icon,
                size: 18,
                color: enabled ? _C.text : _C.text.withOpacity(0.35)),
          ),
        ),
      ),
    );
  }
}

/// Small tool button used inside the toolbar pills.
class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _MiniBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon,
              size: 20,
              color: enabled ? _C.text : _C.text.withOpacity(0.3)),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final List<Widget> children;
  const _Pill({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ===========================================================================
// EMPTY STATE
// ===========================================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: _Reveal(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _Glass(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.accent.withOpacity(0.09),
                      border: Border.all(color: _C.accent.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.folder_off_outlined,
                        size: 38, color: _C.accent.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 18),
                  const Text('No data available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _C.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'No video is attached to this booking, so there is nothing to play or download.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _C.muted, fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Go back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.text,
                      side: const BorderSide(color: _C.borderStrong, width: 1.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// FILE HEADER
// ===========================================================================
String _fmtDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final int h = d.inHours;
  final int m = d.inMinutes.remainder(60);
  final int s = d.inSeconds.remainder(60);
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

class _FileHeader extends StatelessWidget {
  final ViewVideoGetx c;
  final bool compact;
  const _FileHeader({required this.c, required this.compact});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 8 : 12),
      child: LayoutBuilder(builder: (context, hc) {
        final bool showIcon = hc.maxWidth >= 170;
        return Row(
          children: [
            if (showIcon) ...[
              Container(
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _C.accent.withOpacity(0.28),
                    _C.mint.withOpacity(0.10),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.accent.withOpacity(0.45)),
                ),
                child: Icon(Icons.play_circle_outline_rounded,
                    color: _C.mint, size: compact ? 18 : 22),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => Text(
                    c.fileName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  )),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Obx(() {
                      final String ext = c.extension.toUpperCase();
                      final Duration d = c.duration.value;
                      final String sub = d > Duration.zero
                          ? '$ext video  •  ${_fmtDuration(d)}'
                          : '$ext video';
                      return Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _C.mint.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500));
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ===========================================================================
// DOWNLOAD BANNER - progress / success / error / cancelled (all reactive)
// ===========================================================================
class _DownloadBanner extends StatelessWidget {
  final ViewVideoGetx c;
  const _DownloadBanner({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final DownloadStatus s = c.status.value;
      Widget body;

      switch (s) {
        case DownloadStatus.downloading:
        case DownloadStatus.saving:
          body = Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s == DownloadStatus.saving
                          ? 'Saving file...'
                          : c.progressKnown.value
                          ? 'Downloading...  ${c.percent}%'
                          : 'Downloading...',
                      style: const TextStyle(
                          color: _C.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: c.progressKnown.value ? c.progress.value : null,
                        color: _C.accent,
                        backgroundColor: _C.border,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: s == DownloadStatus.downloading ? c.requestCancel : null,
                style: TextButton.styleFrom(foregroundColor: _C.danger),
                child: const Text('Cancel'),
              ),
            ],
          );
          break;

        case DownloadStatus.success:
          body = _msgRow(Icons.check_circle_rounded, _C.accent,
              'Downloaded successfully', c);
          break;

        case DownloadStatus.error:
          body = _msgRow(
              Icons.error_outline_rounded,
              _C.danger,
              c.errorText.value.isEmpty
                  ? 'Download failed.'
                  : c.errorText.value,
              c,
              retry: true);
          break;

        case DownloadStatus.cancelled:
          body = _msgRow(
              Icons.cancel_outlined, _C.muted, 'Download cancelled', c);
          break;

        case DownloadStatus.idle:
          body = const SizedBox.shrink();
          break;
      }

      return AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: s == DownloadStatus.idle
              ? const SizedBox(key: ValueKey('idle'), width: double.infinity)
              : Padding(
            key: ValueKey(s),
            padding: const EdgeInsets.only(top: 10),
            child: _Glass(
              radius: 14,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: body,
            ),
          ),
        ),
      );
    });
  }

  Widget _msgRow(IconData icon, Color color, String text, ViewVideoGetx c,
      {bool retry = false}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: color == _C.muted ? _C.muted : _C.text, fontSize: 13)),
        ),
        if (retry)
          TextButton(
            onPressed: c.requestDownload,
            style: TextButton.styleFrom(foregroundColor: _C.accent),
            child: const Text('Retry'),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Dismiss',
          onPressed: c.resetStatus,
          icon: const Icon(Icons.close_rounded, size: 18, color: _C.muted),
        ),
      ],
    );
  }
}

// ===========================================================================
// VIDEO AREA  (player box + toolbar) - same media_kit mechanism as your
// ProviderSerResVideoScreen: contained 16:9 box, custom controls, fullscreen.
// ===========================================================================
class _ViewerCard extends StatefulWidget {
  final ViewVideoGetx c;
  const _ViewerCard({required this.c});

  @override
  State<_ViewerCard> createState() => _ViewerCardState();
}

class _ViewerCardState extends State<_ViewerCard> {
  Player? _player;
  VideoController? _video;
  late final VideoCardController _card;
  final String _cardTag = UniqueKey().toString();

  StreamSubscription? _errSub;
  StreamSubscription? _durSub;
  StreamSubscription? _widthSub;
  Timer? _fallback;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _card = Get.put(VideoCardController(), tag: _cardTag);
    try {
      final Player p = Player();
      _player = p;
      _video = VideoController(p);

      _errSub = p.stream.error.listen((e) {
        _card.setError(e.isNotEmpty ? e : 'Playback error.');
      });
      _durSub = p.stream.duration.listen((d) {
        if (d > Duration.zero) {
          widget.c.duration.value = d;
          _card.loaded.value = true;
        }
      });
      _widthSub = p.stream.width.listen((w) {
        if ((w ?? 0) > 0) _card.loaded.value = true;
      });
      // Streams with unknown duration: never leave the loader up forever.
      _fallback = Timer(const Duration(seconds: 12), () {
        if (!_card.isClosed) _card.loaded.value = true;
      });

      _open();
    } catch (e) {
      debugPrint('Player init error: $e');
      _card.setError('The video player could not start.');
    }
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _errSub?.cancel();
    _durSub?.cancel();
    _widthSub?.cancel();
    try {
      _player?.dispose();
    } catch (_) {}
    Get.delete<VideoCardController>(tag: _cardTag);
    super.dispose();
  }

  Future<void> _open() async {
    final Player? p = _player;
    if (p == null) return;
    try {
      _card.loaded.value = false;
      await p.open(
        Media(widget.c.fileUrl.value, httpHeaders: widget.c.authHeaders),
        play: false,
      );
    } catch (e) {
      debugPrint('Player open error: $e');
      _card.setError('Could not load this video.');
    }
  }

  void _retry() {
    _card.clearError();
    _open();
  }

  void _openFullscreen() {
    final Player? p = _player;
    final VideoController? v = _video;
    if (p == null || v == null) return;
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _FullscreenVideoPage(player: p, controller: v),
        ),
      );
    } catch (e) {
      debugPrint('fullscreen error: $e');
    }
  }

  void _seekBy(int seconds) {
    final Player? p = _player;
    if (p == null) return;
    try {
      final Duration dur = p.state.duration;
      Duration t = p.state.position + Duration(seconds: seconds);
      if (t < Duration.zero) t = Duration.zero;
      if (dur > Duration.zero && t > dur) t = dur;
      p.seek(t);
    } catch (e) {
      debugPrint('seek error: $e');
    }
  }

  void _cycleSpeed(double current) {
    final Player? p = _player;
    if (p == null) return;
    try {
      double next = _speeds.first;
      for (final double s in _speeds) {
        if (s > current + 0.001) {
          next = s;
          break;
        }
      }
      p.setRate(next);
    } catch (e) {
      debugPrint('speed error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ViewVideoGetx c = widget.c;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, bc) {
            final double w = bc.maxWidth;
            final double h = bc.maxHeight;
            if (!w.isFinite || !h.isFinite || w < 120 || h < 80) {
              return const _Spinner();
            }

            // Largest 16:9 box that fits - never cropped, never overflows.
            double pw = w;
            double ph = pw * 9 / 16;
            if (ph > h) {
              ph = h;
              pw = ph * 16 / 9;
            }

            return Center(
              child: Container(
                width: pw,
                height: ph,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildPlayerBody(),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        _buildToolbar(c),
      ],
    );
  }

  Widget _buildPlayerBody() {
    return Obx(() {
      final String? err = _card.errorText.value;
      final Player? p = _player;
      final VideoController? v = _video;

      if (p == null || v == null) {
        return _ErrorOverlay(
          text: err ?? 'The video player could not start.',
          onRetry: null,
          onDownload: widget.c.requestDownload,
        );
      }
      if (err != null) {
        return _ErrorOverlay(
          text: err,
          onRetry: _retry,
          onDownload: widget.c.requestDownload,
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          _PlayerSurface(
            surfaceTag: '${_cardTag}_surface',
            player: p,
            controller: v,
            isFullscreen: false,
            onToggleFullscreen: _openFullscreen,
          ),
          Positioned.fill(
            child: Obx(() =>
            _card.loaded.value ? const SizedBox.shrink() : const _VideoLoading()),
          ),
        ],
      );
    });
  }

  // ----- toolbar: play/seek, speed, fullscreen, download -----
  Widget _buildToolbar(ViewVideoGetx c) {
    final Player? p = _player;

    return _Glass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: LayoutBuilder(builder: (context, bc) {
        final bool wide = bc.maxWidth >= 430;

        final ButtonStyle dlStyle = ElevatedButton.styleFrom(
          backgroundColor: _C.accent,
          foregroundColor: _C.bg,
          disabledBackgroundColor: _C.accent.withOpacity(0.45),
          disabledForegroundColor: _C.bg.withOpacity(0.7),
          minimumSize: const Size(46, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        );

        const Widget spinner = SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _C.bg));

        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            if (p != null) ...[
              _Pill(children: [
                _MiniBtn(
                    icon: Icons.replay_10_rounded,
                    tooltip: 'Back 10 seconds',
                    onTap: () => _seekBy(-10)),
                StreamBuilder<bool>(
                  stream: p.stream.playing,
                  initialData: p.state.playing,
                  builder: (context, snap) {
                    final bool playing = snap.data ?? false;
                    return _MiniBtn(
                      icon: playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      tooltip: playing ? 'Pause' : 'Play',
                      onTap: () {
                        try {
                          p.playOrPause();
                        } catch (_) {}
                      },
                    );
                  },
                ),
                _MiniBtn(
                    icon: Icons.forward_10_rounded,
                    tooltip: 'Forward 10 seconds',
                    onTap: () => _seekBy(10)),
              ]),
              _Pill(children: [
                StreamBuilder<double>(
                  stream: p.stream.rate,
                  initialData: p.state.rate,
                  builder: (context, snap) {
                    final double r = snap.data ?? 1.0;
                    return Tooltip(
                      message: 'Playback speed',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _cycleSpeed(r),
                        child: Container(
                          height: 38,
                          constraints: const BoxConstraints(minWidth: 52),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${r}x',
                              style: const TextStyle(
                                  color: _C.mint,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    );
                  },
                ),
                _MiniBtn(
                    icon: Icons.fullscreen_rounded,
                    tooltip: 'Full screen',
                    onTap: _openFullscreen),
              ]),
            ],
            Obx(() {
              final bool busy = c.isBusy;
              return wide
                  ? ElevatedButton.icon(
                onPressed: busy ? null : c.requestDownload,
                icon: busy
                    ? spinner
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(busy ? 'Downloading...' : 'Download'),
                style: dlStyle,
              )
                  : Tooltip(
                message: 'Download',
                child: ElevatedButton(
                  onPressed: busy ? null : c.requestDownload,
                  style: dlStyle,
                  child: busy
                      ? spinner
                      : const Icon(Icons.download_rounded, size: 20),
                ),
              );
            }),
          ],
        );
      }),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(_C.accent)),
    ),
  );
}

class _VideoLoading extends StatelessWidget {
  const _VideoLoading();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: const Color(0xFF0B1812),
        alignment: Alignment.center,
        child: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_C.accent)),
              ),
              SizedBox(height: 12),
              Text('Loading video...',
                  style: TextStyle(
                      color: _C.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  final VoidCallback onDownload;
  const _ErrorOverlay(
      {required this.text, required this.onRetry, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1812),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: _C.accent.withOpacity(0.8), size: 32),
            const SizedBox(height: 8),
            const Text("Couldn't play the video",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _C.text, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(text,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _C.muted, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.accent,
                      foregroundColor: _C.bg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download instead'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.text,
                    side: const BorderSide(color: _C.borderStrong, width: 1.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// PLAYER SURFACE - video (BoxFit.contain, never cropped) + animated overlay
// controls. Used inline and in fullscreen (same Player instance).
// ===========================================================================
class _PlayerSurface extends StatefulWidget {
  final String surfaceTag;
  final Player player;
  final VideoController controller;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  const _PlayerSurface({
    required this.surfaceTag,
    required this.player,
    required this.controller,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  @override
  State<_PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends State<_PlayerSurface> {
  late final PlayerControlsController _controls;

  @override
  void initState() {
    super.initState();
    _controls = Get.put(PlayerControlsController(), tag: widget.surfaceTag);
    _controls.scheduleHide();
  }

  @override
  void dispose() {
    Get.delete<PlayerControlsController>(tag: widget.surfaceTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Player player = widget.player;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _controls.toggle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          Video(
            controller: widget.controller,
            controls: NoVideoControls,
            fit: BoxFit.contain,
          ),

          // Buffering indicator
          StreamBuilder<bool>(
            stream: player.stream.buffering,
            initialData: false,
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return const Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_C.accent),
                  ),
                ),
              );
            },
          ),

          // Controls overlay
          Obx(() {
            final bool visible = _controls.controlsVisible.value;
            return AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !visible,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                      stops: const [0, 0.25, 0.6, 1],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      StreamBuilder<bool>(
                        stream: player.stream.playing,
                        initialData: player.state.playing,
                        builder: (context, snap) {
                          final bool playing = snap.data ?? false;
                          return AnimatedScale(
                            scale: visible ? 1 : 0.8,
                            duration: const Duration(milliseconds: 220),
                            child: GestureDetector(
                              onTap: () {
                                try {
                                  player.playOrPause();
                                } catch (_) {}
                                _controls.scheduleHide();
                              },
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.35),
                                  border: Border.all(
                                      color: _C.accent.withOpacity(0.75),
                                      width: 1.5),
                                ),
                                child: Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                        child: _bottomBar(player),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _bottomBar(Player player) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      initialData: player.state.position,
      builder: (context, posSnap) {
        final Duration pos = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          initialData: player.state.duration,
          builder: (context, durSnap) {
            final Duration dur = durSnap.data ?? Duration.zero;
            final int maxMs = dur.inMilliseconds.clamp(1, 1 << 31);
            final int curMs = pos.inMilliseconds.clamp(0, maxMs);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: _C.accent,
                    inactiveTrackColor: Colors.white.withOpacity(0.25),
                    thumbColor: _C.accent,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs.toDouble(),
                    value: curMs.toDouble(),
                    onChanged: (val) {
                      try {
                        player.seek(Duration(milliseconds: val.round()));
                      } catch (_) {}
                      _controls.scheduleHide();
                    },
                  ),
                ),
                Row(
                  children: [
                    Text(_fmtDuration(pos),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const Spacer(),
                    Text(_fmtDuration(dur),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const SizedBox(width: 10),
                    StreamBuilder<double>(
                      stream: player.stream.volume,
                      initialData: player.state.volume,
                      builder: (context, vSnap) {
                        final bool muted = (vSnap.data ?? 100) <= 0;
                        return InkWell(
                          onTap: () {
                            try {
                              player.setVolume(muted ? 100 : 0);
                            } catch (_) {}
                            _controls.scheduleHide();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: widget.onToggleFullscreen,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          widget.isFullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ===========================================================================
// FULLSCREEN PAGE - edge to edge, landscape lock + hidden system UI on
// mobile, Esc / X / exit icon to leave. Reuses the same Player instance.
// ===========================================================================
class _FullscreenVideoPage extends StatefulWidget {
  final Player player;
  final VideoController controller;
  const _FullscreenVideoPage({required this.player, required this.controller});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  final String _surfaceTag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _PlayerSurface(
                surfaceTag: _surfaceTag,
                player: widget.player,
                controller: widget.controller,
                isFullscreen: true,
                onToggleFullscreen: _close,
              ),
              Positioned(
                top: 10,
                left: 10,
                child: SafeArea(
                  child: _BorderIconButton(
                    tooltip: 'Close',
                    icon: Icons.close_rounded,
                    onTap: _close,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// BACKGROUND
// ===========================================================================

/// Dark forest base + soft emerald/mint ambient blobs + blurred glass bubbles.
/// - Purely decorative: wrapped in IgnorePointer, never blocks taps/text.
/// - Animation is driven by an AnimationController (no setState).
/// - Painted inside a RepaintBoundary so only the background repaints.
class ForestBackground extends StatefulWidget {
  final Widget child;
  const ForestBackground({super.key, required this.child});

  @override
  State<ForestBackground> createState() => _ForestBackgroundState();
}

class _ForestBackgroundState extends State<ForestBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 26))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0F1F17)),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _ForestPainter(_ctrl), size: Size.infinite),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ForestPainter extends CustomPainter {
  final Animation<double> t;
  _ForestPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;

    final double v = Curves.easeInOut.transform(t.value);
    final double rb = math.max(size.shortestSide, 360);

    // ---- Ambient blobs (radial gradients = cheap, very soft, no hard edge) ----
    void blob(double fx, double fy, double radius, Color c, double alpha,
        double dx, double dy) {
      final Offset center = Offset(
        size.width * fx + dx * v * rb * 0.08,
        size.height * fy + dy * v * rb * 0.08,
      );
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      final Paint p = Paint()
        ..shader = RadialGradient(
          colors: [
            c.withOpacity(alpha),
            c.withOpacity(alpha * 0.45),
            c.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, radius, p);
    }

    blob(-0.04, 0.04, rb * 0.80, const Color(0xFF22C55E), 0.22, 1.0, 0.7);
    blob(1.06, 0.32, rb * 0.70, const Color(0xFF34D399), 0.15, -1.0, 0.9);
    blob(0.08, 1.02, rb * 0.85, const Color(0xFF0F766E), 0.26, 0.8, -1.0);
    blob(0.96, 0.96, rb * 0.65, const Color(0xFF22C55E), 0.17, -0.9, -0.6);
    blob(0.50, 0.52, rb * 0.55, const Color(0xFF34D399), 0.05, 0.5, -0.5);

    // ---- Frosted glass bubbles ----
    void bubble(double fx, double fy, double r, double dy, double phase) {
      final double wave = math.sin((v + phase) * math.pi);
      final Offset c = Offset(
        size.width * fx,
        size.height * fy + wave * dy,
      );
      final Rect rect = Rect.fromCircle(center: c, radius: r);

      final Paint fill = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Colors.white.withOpacity(0.12),
            const Color(0xFF34D399).withOpacity(0.05),
            Colors.white.withOpacity(0.015),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
      canvas.drawCircle(c, r, fill);

      final Paint ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withOpacity(0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(c, r, ring);

      final Paint glint = Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(c.translate(-r * 0.35, -r * 0.38), r * 0.14, glint);
    }

    final double u = math.max(size.shortestSide, 320) / 400;
    bubble(0.12, 0.30, 46 * u, 18 * u, 0.0);
    bubble(0.86, 0.14, 30 * u, 14 * u, 0.3);
    bubble(0.92, 0.66, 64 * u, 22 * u, 0.55);
    bubble(0.20, 0.82, 36 * u, 16 * u, 0.8);
    bubble(0.62, 0.92, 22 * u, 10 * u, 0.15);
    bubble(0.05, 0.58, 18 * u, 10 * u, 0.65);
  }

  @override
  bool shouldRepaint(covariant _ForestPainter old) => false; // driven by `repaint`
}