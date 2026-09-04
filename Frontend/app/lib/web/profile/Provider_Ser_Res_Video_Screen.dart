import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../constant/Server_Database.dart';
import '../../models/ProviderSerResVideoModel.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';

// =============================================================================
// IMPORTANT ONE-TIME SETUP (add to main.dart, not this file):
//
//   void main() {
//     WidgetsFlutterBinding.ensureInitialized();
//     MediaKit.ensureInitialized();   // <-- required before any Player() is created
//     runApp(const MyApp());
//   }
//
// pubspec.yaml:
//   media_kit: ^1.2.6
//   media_kit_video: ^2.0.1
//   media_kit_libs_video: ^1.0.7
// =============================================================================

class ProviderSerResVideoScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;

  const ProviderSerResVideoScreen({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.Service_Name,
  });

  @override
  State<ProviderSerResVideoScreen> createState() => _ProviderSerResVideoScreenState();
}

enum _ScreenState { checkingSession, loading, empty, error, loaded }

class _ProviderSerResVideoScreenState extends State<ProviderSerResVideoScreen> {
  static const Color _bg = Color(0xFF07110C);
  static const Color _surface = Color(0xFF0F1D15);
  static const Color _green = Color(0xFF00E676);

  _ScreenState _screenState = _ScreenState.checkingSession;
  String _screenErrorText = "Something went wrong.";

  List<ProviderSerResVideoModel> ProviderServiceVideoList = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bool sessionOk = await JwtVerify(Jwt_Token: widget.User_JwtToken);
    if (!sessionOk) return;
    await GetProviderServiceResourceVideos(
      Email: widget.User_Email,
      jwttoken: widget.User_JwtToken,
    );
  }

  Future<bool> JwtVerify({required String Jwt_Token}) async {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return true;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      if (!mounted) return false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return false;
    }
  }

  Future<int> GetProviderServiceResourceVideos({
    required String Email,
    required String jwttoken,
  }) async {
    if (mounted) setState(() => _screenState = _ScreenState.loading);

    try {
      print('');
      print('================================================');
      print('GET SERVICE RESOURCE VIDEO METHOD CALLED');
      print('================================================');
      print('Email   : $Email');
      print('Service : ${widget.Service_Name}');

      const String url = Backend_Server_Url + "api/Profile/getservicevideoinfo";

      print('API URL: $url');

      final Map<String, dynamic> UserDetails = {
        "Email": Email,
        "ServiceName": widget.Service_Name,
      };

      print('Request body: ${jsonEncode(UserDetails)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode(UserDetails),
      );

      print('Status code: ${response.statusCode}');

      // Your backend returns 404 (not 200 + []) when there's no service or
      // no videos uploaded yet — treat that as "empty", not "error".
      if (response.statusCode == 404) {
        print('No videos found for this service (404).');
        if (mounted) {
          setState(() {
            ProviderServiceVideoList.clear();
            _screenState = _ScreenState.empty;
          });
        }
        return 1;
      }

      if (response.statusCode != 200) {
        print('API FAILED');
        print('Response: ${response.body}');
        if (mounted) {
          setState(() {
            ProviderServiceVideoList.clear();
            _screenErrorText =
            "Failed to load videos for \"${widget.Service_Name}\" "
                "(${response.statusCode}).";
            _screenState = _ScreenState.error;
          });
        }
        return 0;
      }

      final dynamic responseData = jsonDecode(response.body);

      if (responseData is! List) {
        print('ERROR: Response is not a List.');
        if (mounted) {
          setState(() {
            _screenErrorText = "Unexpected response format from server.";
            _screenState = _ScreenState.error;
          });
        }
        return 0;
      }

      print('Number of videos: ${responseData.length}');

      final List<ProviderSerResVideoModel> loadedVideos = responseData
          .map((data) => ProviderSerResVideoModel.fromJson(data))
          .toList();

      for (int i = 0; i < loadedVideos.length; i++) {
        final v = loadedVideos[i];
        print('');
        print('--------------- VIDEO $i ---------------');
        print('Service Name: ${v.serviceName}');
        print('Service ID: ${v.providerServiceId}');
        print('Resource ID: ${v.providerServiceResourcesId}');
        print('Video Path: ${v.serviceVideo}');
      }

      if (!mounted) return 0;

      setState(() {
        ProviderServiceVideoList = loadedVideos;
        _screenState =
        loadedVideos.isEmpty ? _ScreenState.empty : _ScreenState.loaded;
      });

      print('');
      print('SERVICE VIDEO API PROCESS SUCCESS');
      print('================================================');

      return 1;
    } catch (e, stackTrace) {
      print('');
      print('================================================');
      print('SERVICE VIDEO API EXCEPTION');
      print('================================================');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('================================================');

      if (mounted) {
        setState(() {
          ProviderServiceVideoList.clear();
          _screenErrorText = "Network error while loading videos.";
          _screenState = _ScreenState.error;
        });
      }
      return 0;
    }
  }

  String _resolveUrl(String relativePath) {
    String base = Backend_Server_Url;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    String rel = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$base$rel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          widget.Service_Name,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case _ScreenState.checkingSession:
      case _ScreenState.loading:
        return _StatusView(
          key: const ValueKey('loading'),
          spinner: true,
          title: "Loading videos...",
          message: "Fetching \"${widget.Service_Name}\" videos.",
        );

      case _ScreenState.empty:
        return _StatusView(
          key: const ValueKey('empty'),
          icon: Icons.videocam_off_outlined,
          title: "No videos found",
          message: "No videos have been uploaded yet for \"${widget.Service_Name}\".",
          actionLabel: "Refresh",
          onAction: () => GetProviderServiceResourceVideos(
            Email: widget.User_Email,
            jwttoken: widget.User_JwtToken,
          ),
        );

      case _ScreenState.error:
        return _StatusView(
          key: const ValueKey('error'),
          icon: Icons.error_outline_rounded,
          title: "Couldn't load videos",
          message: _screenErrorText,
          actionLabel: "Retry",
          onAction: () => GetProviderServiceResourceVideos(
            Email: widget.User_Email,
            jwttoken: widget.User_JwtToken,
          ),
        );

      case _ScreenState.loaded:
        return _VideoListView(
          key: const ValueKey('loaded'),
          videos: ProviderServiceVideoList,
          resolveUrl: _resolveUrl,
          jwtToken: widget.User_JwtToken,
        );
    }
  }
}

// =============================================================================
// STATUS VIEW
// =============================================================================
class _StatusView extends StatelessWidget {
  static const Color _green = Color(0xFF00E676);

  final IconData? icon;
  final bool spinner;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spinner)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(scale: value, child: child),
                  ),
                  child: const SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(_green),
                    ),
                  ),
                )
              else if (icon != null)
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withOpacity(0.08),
                    border: Border.all(color: _green.withOpacity(0.4), width: 1.5),
                  ),
                  child: Icon(icon, color: _green.withOpacity(0.85), size: 38),
                ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13.5),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: Text(actionLabel!, style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
// VIDEO LIST — each card is centered, sized to 80% width x 80% height of the
// available screen viewport (recomputed live, so it adapts on rotation).
// =============================================================================
class _VideoListView extends StatelessWidget {
  final List<ProviderSerResVideoModel> videos;
  final String Function(String relativePath) resolveUrl;
  final String jwtToken;

  const _VideoListView({
    super.key,
    required this.videos,
    required this.resolveUrl,
    required this.jwtToken,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final v = videos[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + (index * 90).clamp(0, 500)),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(offset: Offset(0, (1 - val) * 26), child: child),
              ),
              child: _VideoResourceCard(
                model: v,
                url: (v.serviceVideo == null || v.serviceVideo!.isEmpty)
                    ? ''
                    : resolveUrl(v.serviceVideo!),
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
// SINGLE VIDEO CARD — header (name/service id/resource id) + player,
// player box capped at 80% width x 80% height of the viewport, fully
// contained (no cropping) while preserving the video's own aspect ratio.
// =============================================================================
class _VideoResourceCard extends StatefulWidget {
  final ProviderSerResVideoModel model;
  final String url;
  final String jwtToken;
  final double viewportWidth;
  final double viewportHeight;

  const _VideoResourceCard({
    required this.model,
    required this.url,
    required this.jwtToken,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  @override
  State<_VideoResourceCard> createState() => _VideoResourceCardState();
}

class _VideoResourceCardState extends State<_VideoResourceCard> {
  static const Color _surface = Color(0xFF0F1D15);
  static const Color _card = Color(0xFF13241A);
  static const Color _green = Color(0xFF00E676);
  static const Color _greenDim = Color(0xFF0C6B3B);

  late final Player _player;
  late final VideoController _controller;
  StreamSubscription? _errorSub;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _errorSub = _player.stream.error.listen((e) {
      if (!mounted) return;
      setState(() => _errorText = e.isNotEmpty ? e : "Playback error.");
    });
    if (widget.url.isNotEmpty) {
      _player.open(Media(
        widget.url,
        httpHeaders: {"Authorization": "Bearer ${widget.jwtToken}"},
      ), play: false);
    }
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bounding box: 80% of the available screen width/height.
    final double maxW = widget.viewportWidth * 0.8;
    final double maxH = widget.viewportHeight * 0.8;

    // Fit a 16:9 box inside that bounding box without exceeding either
    // dimension — this is what actually prevents cropping.
    double playerW = maxW;
    double playerH = playerW * 9 / 16;
    if (playerH > maxH) {
      playerH = maxH;
      playerW = playerH * 16 / 9;
    }

    return Center(
      child: Container(
        width: playerW,
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _greenDim.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                border: Border(bottom: BorderSide(color: _greenDim.withOpacity(0.35))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _green.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.play_circle_outline_rounded, color: _green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.model.serviceName ?? 'Unknown Service',
                          style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 12,
                          children: [
                            Text(
                              'Service ID: ${widget.model.providerServiceId ?? '-'}',
                              style: TextStyle(color: _green.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Resource ID: ${widget.model.providerServiceResourcesId ?? '-'}',
                              style: TextStyle(color: _green.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Player, capped to the computed 80%/80% box ---
            SizedBox(
              width: playerW,
              height: playerH,
              child: widget.url.isEmpty
                  ? const _InlineMessage(text: "No video path returned for this file.")
                  : (_errorText != null
                  ? _ErrorOverlay(
                text: _errorText!,
                onRetry: () {
                  setState(() => _errorText = null);
                  _player.open(Media(
                    widget.url,
                    httpHeaders: {"Authorization": "Bearer ${widget.jwtToken}"},
                  ), play: false);
                },
              )
                  : _PlayerSurface(player: _player, controller: _controller)),
            ),
          ],
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
      color: const Color(0xFF07110C),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  static const Color _green = Color(0xFF00E676);
  final String text;
  final VoidCallback onRetry;
  const _ErrorOverlay({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF07110C),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: _green.withOpacity(0.7), size: 30),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: _green, size: 18),
              label: const Text("Retry", style: TextStyle(color: _green)),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PLAYER SURFACE — video (contained, never cropped) + animated
// dark-green overlay controls. Stays this size until fullscreen is tapped.
// =============================================================================
class _PlayerSurface extends StatefulWidget {
  final Player player;
  final VideoController controller;
  const _PlayerSurface({required this.player, required this.controller});

  @override
  State<_PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends State<_PlayerSurface> {
  static const Color _green = Color(0xFF00E676);

  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPage(player: widget.player, controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          // fit: BoxFit.contain — this is what stops the video from being
          // cropped when its native aspect ratio doesn't exactly match the
          // 16:9 box it's placed in.
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
                    valueColor: AlwaysStoppedAnimation<Color>(_green),
                  ),
                ),
              );
            },
          ),

          // Controls overlay
          AnimatedOpacity(
            opacity: _controlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: Container(
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
                child: Column(
                  children: [
                    const Spacer(),
                    StreamBuilder<bool>(
                      stream: widget.player.stream.playing,
                      initialData: widget.player.state.playing,
                      builder: (context, snap) {
                        final playing = snap.data ?? false;
                        return AnimatedScale(
                          scale: _controlsVisible ? 1 : 0.8,
                          duration: const Duration(milliseconds: 220),
                          child: GestureDetector(
                            onTap: () {
                              widget.player.playOrPause();
                              _scheduleHide();
                            },
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.35),
                                border: Border.all(color: _green.withOpacity(0.7), width: 1.5),
                              ),
                              child: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
                      child: StreamBuilder<Duration>(
                        stream: widget.player.stream.position,
                        initialData: widget.player.state.position,
                        builder: (context, posSnap) {
                          final pos = posSnap.data ?? Duration.zero;
                          return StreamBuilder<Duration>(
                            stream: widget.player.stream.duration,
                            initialData: widget.player.state.duration,
                            builder: (context, durSnap) {
                              final dur = durSnap.data ?? Duration.zero;
                              final maxMs = dur.inMilliseconds.clamp(1, 1 << 31);
                              final curMs = pos.inMilliseconds.clamp(0, maxMs);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                      activeTrackColor: _green,
                                      inactiveTrackColor: Colors.white.withOpacity(0.25),
                                      thumbColor: _green,
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: maxMs.toDouble(),
                                      value: curMs.toDouble(),
                                      onChanged: (v) {
                                        widget.player.seek(Duration(milliseconds: v.round()));
                                        _scheduleHide();
                                      },
                                    ),


                                  ),
                                  Row(
                                    children: [
                                      Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      const Spacer(),
                                      Text(_fmt(dur), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      const SizedBox(width: 10),
                                      StreamBuilder<double>(
                                        stream: widget.player.stream.volume,
                                        initialData: widget.player.state.volume,
                                        builder: (context, vSnap) {
                                          final muted = (vSnap.data ?? 100) <= 0;
                                          return GestureDetector(
                                            onTap: () {
                                              widget.player.setVolume(muted ? 100 : 0);
                                              _scheduleHide();
                                            },
                                            child: Icon(
                                              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 14),
                                      GestureDetector(
                                        onTap: _openFullscreen,
                                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

// =============================================================================
// FULLSCREEN PAGE — this is the ONLY place the video actually goes edge to
// edge. Locks landscape, hides system UI, reuses the same player instance.
// =============================================================================
class _FullscreenVideoPage extends StatefulWidget {
  final Player player;
  final VideoController controller;
  const _FullscreenVideoPage({required this.player, required this.controller});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
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
            _PlayerSurface(player: widget.player, controller: widget.controller),
            Positioned(
              top: 10,
              left: 10,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
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