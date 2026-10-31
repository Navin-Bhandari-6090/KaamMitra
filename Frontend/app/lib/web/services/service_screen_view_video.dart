import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../models/ProviderSerResVideoModel.dart';
import '../../../state management/getx/profile/provider_user/video_view_getx.dart';

// =============================================================================
// IMPORTANT ONE-TIME SETUP (main.dart):
//
//   void main() {
//     WidgetsFlutterBinding.ensureInitialized();
//     MediaKit.ensureInitialized();
//     runApp(const MyApp());
//   }
//
// pubspec.yaml:
//   media_kit: ^1.2.6
//   media_kit_video: ^2.0.1
//   media_kit_libs_video: ^1.0.7
// =============================================================================

// ===========================================================================
// PALETTE
// ===========================================================================
class _V {
  static const Color bg = Color(0xFF07110C);
  static const Color surface = Color(0xFF0F1D15);
  static const Color card = Color(0xFF13241A);
  static const Color green = Color(0xFF00E676);
  static const Color greenDim = Color(0xFF0C6B3B);
  static const Color muted = Color(0xFF9AA59D);
}

class ServiceScreenProviderSerResVideoScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;
  final String Provider_Email;

  const ServiceScreenProviderSerResVideoScreen({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.Service_Name,
    required this.Provider_Email,
  });

  @override
  State<ServiceScreenProviderSerResVideoScreen> createState() =>
      _ServiceScreenProviderSerResVideoScreenState();
}

class _ServiceScreenProviderSerResVideoScreenState
    extends State<ServiceScreenProviderSerResVideoScreen> {
  late final VideoViewGetx controller;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    controller = Get.put(VideoViewGetx(), tag: _tag);
    // Videos belong to the PROVIDER, so the provider's email is used here.
    controller.init(
      email: widget.Provider_Email,
      jwtToken: widget.User_JwtToken,
      serviceName: widget.Service_Name,
    );
  }

  @override
  void dispose() {
    Get.delete<VideoViewGetx>(tag: _tag);
    super.dispose();
  }

  Future<void> _retry() async {
    try {
      await controller.GetProviderServiceResourceVideos(
        Email: widget.Provider_Email,
        jwttoken: widget.User_JwtToken,
      );
    } catch (e) {
      debugPrint('retry error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _V.bg,
      appBar: AppBar(
        backgroundColor: _V.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Service Videos',
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final ScreenState state = controller.screenState.value;
          final bool loaded = state == ScreenState.loaded;

          return Column(
            children: [
              if (loaded) _Toolbar(c: controller, onRefresh: _retry),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildBody(state),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBody(ScreenState state) {
    switch (state) {
      case ScreenState.checkingSession:
      case ScreenState.loading:
        return const _StatusView(
          key: ValueKey('loading'),
          spinner: true,
          title: "Loading videos...",
          message: "Please wait while we fetch the videos.",
        );

      case ScreenState.empty:
        return _StatusView(
          key: const ValueKey('empty'),
          icon: Icons.videocam_off_outlined,
          title: "No videos found",
          message: "No videos have been uploaded yet for this service.",
          actionLabel: "Refresh",
          onAction: _retry,
        );

      case ScreenState.error:
        return _StatusView(
          key: const ValueKey('error'),
          icon: Icons.error_outline_rounded,
          title: "Couldn't load videos",
          message: controller.screenErrorText.value,
          actionLabel: "Retry",
          onAction: _retry,
        );

      case ScreenState.loaded:
        final List<ProviderSerResVideoModel> list = controller.filteredVideos;
        if (list.isEmpty) {
          return const _StatusView(
            key: ValueKey('nomatch'),
            icon: Icons.search_off_rounded,
            title: "No match found",
            message: "No video matches your search.",
          );
        }
        return _VideoListView(
          key: const ValueKey('loaded'),
          videos: list,
          c: controller,
          jwtToken: widget.User_JwtToken,
        );
    }
  }
}

// =============================================================================
// TOOLBAR — header with count + refresh, and search by resource ID / title
// =============================================================================
class _Toolbar extends StatelessWidget {
  final VideoViewGetx c;
  final Future<void> Function() onRefresh;

  const _Toolbar({required this.c, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: const BoxDecoration(
        color: _V.surface,
        border: Border(bottom: BorderSide(color: _V.greenDim, width: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _V.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _V.green.withOpacity(0.4)),
                ),
                child: const Icon(Icons.video_library_rounded,
                    color: _V.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resource Videos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Obx(() => Text(
                      'Showing ${c.filteredVideos.length} of ${c.ProviderServiceVideoList.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: _V.green.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    )),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => onRefresh(),
                icon: const Icon(Icons.refresh_rounded, color: _V.green),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: c.searchCtrl,
            onChanged: (v) => c.query.value = v,
            cursorColor: _V.green,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              hintText: 'Search by resource ID or title',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13.5),
              prefixIcon: const Icon(Icons.search_rounded, color: _V.green),
              suffixIcon: Obx(() => c.query.value.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded, color: _V.muted),
                onPressed: () {
                  c.searchCtrl.clear();
                  c.query.value = '';
                },
              )),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _V.greenDim.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _V.greenDim.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _V.green, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STATUS VIEW (scrollable so it never overflows on small screens)
// =============================================================================
class _StatusView extends StatelessWidget {
  final IconData? icon;
  final bool spinner;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _StatusView({
    super.key,
    this.icon,
    this.spinner = false,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
                offset: Offset(0, (1 - v) * 12), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spinner)
                const SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_V.green),
                  ),
                )
              else if (icon != null)
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _V.green.withOpacity(0.08),
                    border: Border.all(
                        color: _V.green.withOpacity(0.4), width: 1.5),
                  ),
                  child:
                  Icon(icon, color: _V.green.withOpacity(0.85), size: 38),
                ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 13.5),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => onAction!(),
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: Text(actionLabel!,
                      style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _V.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// VIDEO LIST — each card sized to 80% width x 80% height of the viewport
// =============================================================================
class _VideoListView extends StatelessWidget {
  final List<ProviderSerResVideoModel> videos;
  final VideoViewGetx c;
  final String jwtToken;

  const _VideoListView({
    super.key,
    required this.videos,
    required this.c,
    required this.jwtToken,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final ProviderSerResVideoModel v = videos[index];
            // Stable key per model object, so a filtered list never reuses
            // a player that is showing a different video.
            final int stableKey = identityHashCode(v);
            return TweenAnimationBuilder<double>(
              key: ValueKey(stableKey),
              tween: Tween(begin: 0, end: 1),
              duration:
              Duration(milliseconds: 400 + (index * 90).clamp(0, 500)),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(
                    offset: Offset(0, (1 - val) * 26), child: child),
              ),
              child: _VideoResourceCard(
                cardTag: 'video_card_$stableKey',
                model: v,
                c: c,
                url: c.videoUrlOf(v),
                jwtToken: jwtToken,
                viewportWidth: constraints.maxWidth,
                viewportHeight: constraints.maxHeight,
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// SINGLE VIDEO CARD — header (title / IDs) + player
// =============================================================================
class _VideoResourceCard extends StatefulWidget {
  final String cardTag;
  final ProviderSerResVideoModel model;
  final VideoViewGetx c;
  final String url;
  final String jwtToken;
  final double viewportWidth;
  final double viewportHeight;

  const _VideoResourceCard({
    required this.cardTag,
    required this.model,
    required this.c,
    required this.url,
    required this.jwtToken,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  @override
  State<_VideoResourceCard> createState() => _VideoResourceCardState();
}

class _VideoResourceCardState extends State<_VideoResourceCard> {
  late final Player _player;
  late final VideoController _controller;
  late final VideoCardController _cardController;
  StreamSubscription? _errorSub;

  @override
  void initState() {
    super.initState();
    _cardController = Get.put(VideoCardController(), tag: widget.cardTag);
    _player = Player();
    _controller = VideoController(_player);

    _errorSub = _player.stream.error.listen((e) {
      // The raw error can contain the video URL, so it is logged only.
      debugPrint('Playback error: $e');
      _cardController.setError("This video could not be played.");
    });

    if (widget.url.isNotEmpty) {
      _player.open(
        Media(widget.url,
            httpHeaders: {"Authorization": "Bearer ${widget.jwtToken}"}),
        play: false,
      );
    }
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _player.dispose();
    Get.delete<VideoCardController>(tag: widget.cardTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double vw =
    widget.viewportWidth.isFinite ? widget.viewportWidth : 360;
    final double vh =
    widget.viewportHeight.isFinite ? widget.viewportHeight : 640;

    // Never wider than the viewport, never narrower than 240 (unless the
    // viewport itself is narrower).
    final double minW = vw < 240 ? vw : 240;
    final double maxW = (vw * 0.8).clamp(minW, double.infinity);
    final double maxH = (vh * 0.8).clamp(120.0, double.infinity);

    double playerW = maxW;
    double playerH = playerW * 9 / 16;
    if (playerH > maxH) {
      playerH = maxH;
      playerW = playerH * 16 / 9;
      if (playerW < minW) playerW = minW;
    }

    final String titleText =
    widget.c.displayOr(widget.c.titleOf(widget.model));

    return Center(
      child: Container(
        width: playerW,
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: _V.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _V.greenDim.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header: title + IDs ---
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _V.surface,
                border: Border(
                    bottom: BorderSide(color: _V.greenDim.withOpacity(0.35))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _V.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _V.green.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.play_circle_outline_rounded,
                        color: _V.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Title: ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: titleText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _InfoChip(
                              label: 'Resource ID',
                              value: widget.c
                                  .displayOr(widget.c.idOf(widget.model)),
                            ),
                            _InfoChip(
                              label: 'Service ID',
                              value: widget.c.displayOr(
                                  widget.c.serviceIdOf(widget.model)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Player ---
            SizedBox(
              width: playerW,
              height: playerH,
              child: widget.url.isEmpty
                  ? const _InlineMessage(
                  text: "No video is available for this resource.")
                  : Obx(() {
                final String? errorText =
                    _cardController.errorText.value;
                if (errorText != null) {
                  return _ErrorOverlay(
                    text: errorText,
                    onRetry: () {
                      _cardController.clearError();
                      _player.open(
                        Media(widget.url, httpHeaders: {
                          "Authorization": "Bearer ${widget.jwtToken}"
                        }),
                        play: false,
                      );
                    },
                  );
                }
                return _PlayerSurface(
                  surfaceTag: '${widget.cardTag}_surface',
                  player: _player,
                  controller: _controller,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _V.green.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _V.green.withOpacity(0.30)),
        ),
        child: Text(
          '$label: $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String text;
  const _InlineMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _V.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style:
            TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  const _ErrorOverlay({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _V.bg,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: _V.green.withOpacity(0.7), size: 30),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: _V.green, size: 18),
                label: const Text("Retry", style: TextStyle(color: _V.green)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PLAYER SURFACE — video (contained, never cropped) + overlay controls
// Responsive: controls scale down (FittedBox) instead of overflowing.
// =============================================================================
class _PlayerSurface extends StatefulWidget {
  final String surfaceTag;
  final Player player;
  final VideoController controller;
  const _PlayerSurface({
    required this.surfaceTag,
    required this.player,
    required this.controller,
  });

  @override
  State<_PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends State<_PlayerSurface> {
  late final PlayerControlsController _controlsController;

  @override
  void initState() {
    super.initState();
    _controlsController =
        Get.put(PlayerControlsController(), tag: widget.surfaceTag);
    _controlsController.scheduleHide();
  }

  @override
  void dispose() {
    Get.delete<PlayerControlsController>(tag: widget.surfaceTag);
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPage(
          player: widget.player,
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _controlsController.toggle,
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
            stream: widget.player.stream.buffering,
            initialData: false,
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return const Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_V.green),
                  ),
                ),
              );
            },
          ),

          // Controls overlay (responsive: scales down instead of overflowing)
          Positioned.fill(
            child: Obx(() {
              final bool controlsVisible =
                  _controlsController.controlsVisible.value;
              return AnimatedOpacity(
                opacity: controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: !controlsVisible,
                  child: LayoutBuilder(
                    builder: (context, cons) {
                      final double w =
                      cons.maxWidth.isFinite ? cons.maxWidth : 260;
                      final double h =
                      cons.maxHeight.isFinite ? cons.maxHeight : 146;
                      if (w < 24 || h < 24) return const SizedBox.shrink();

                      // Play button size follows the available space.
                      final double shortest = w < h ? w : h;
                      final double btn =
                      shortest * 0.4 > 58 ? 58 : shortest * 0.4;

                      // Bottom bar is laid out at a minimum design width and
                      // scaled down by FittedBox when the player is narrower.
                      const double designW = 260;
                      final double barW = w < designW ? designW : w;

                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0, 0.25, 0.6, 1],
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // ---- Center play / pause ----
                            Center(
                              child: StreamBuilder<bool>(
                                stream: widget.player.stream.playing,
                                initialData: widget.player.state.playing,
                                builder: (context, snap) {
                                  final bool playing = snap.data ?? false;
                                  return GestureDetector(
                                    onTap: () {
                                      widget.player.playOrPause();
                                      _controlsController.scheduleHide();
                                    },
                                    child: Container(
                                      width: btn,
                                      height: btn,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.35),
                                        border: Border.all(
                                            color: _V.green.withOpacity(0.7),
                                            width: 1.5),
                                      ),
                                      child: Icon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: btn * 0.52,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // ---- Bottom bar (slider + time + icons) ----
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  width: barW,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 0, 10, 6),
                                    child: _buildBottomBar(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      initialData: widget.player.state.position,
      builder: (context, posSnap) {
        final Duration pos = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          initialData: widget.player.state.duration,
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
                    activeTrackColor: _V.green,
                    inactiveTrackColor: Colors.white.withOpacity(0.25),
                    thumbColor: _V.green,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs.toDouble(),
                    value: curMs.toDouble(),
                    onChanged: (v) {
                      widget.player.seek(Duration(milliseconds: v.round()));
                      _controlsController.scheduleHide();
                    },
                  ),
                ),
                Row(
                  children: [
                    // Time text can shrink instead of overflowing
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_fmt(pos)} / ${_fmt(dur)}',
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    StreamBuilder<double>(
                      stream: widget.player.stream.volume,
                      initialData: widget.player.state.volume,
                      builder: (context, vSnap) {
                        final bool muted = (vSnap.data ?? 100) <= 0;
                        return GestureDetector(
                          onTap: () {
                            widget.player.setVolume(muted ? 100 : 0);
                            _controlsController.scheduleHide();
                          },
                          child: Icon(
                            muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: _openFullscreen,
                      child: const Icon(Icons.fullscreen_rounded,
                          color: Colors.white, size: 20),
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

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

// =============================================================================
// FULLSCREEN PAGE — landscape, immersive, same player instance
// =============================================================================
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _PlayerSurface(
              surfaceTag: _surfaceTag,
              player: widget.player,
              controller: widget.controller,
            ),
            Positioned(
              top: 10,
              left: 10,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}