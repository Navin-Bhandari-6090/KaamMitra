import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state management/getx/profile/provider/change_video_getx.dart';
import '../../common widget/single_video_pick_getx.dart';

/// =============================================================================
/// DARK GREEN PALETTE (kept identical across the app for brand consistency)
/// =============================================================================
class _Palette {
  static const Color bodyBg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color textPrimary = Color(0xFFE6F4EA);
  static const Color textMuted = Color(0xFF8A9A90);
  static const Color headerFooter = Color(0xFF12261C);
  static const Color accent = Color(0xFF22C55E);
  static const Color accentMint = Color(0xFF34D399);
  static const Color borderColor = Color(0xFF234232);
}

class ProUpdSerResVideoScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const ProUpdSerResVideoScreen({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
  });

  @override
  State<ProUpdSerResVideoScreen> createState() => _ProUpdSerResVideoScreenState();
}

class _ProUpdSerResVideoScreenState extends State<ProUpdSerResVideoScreen>
    with SingleTickerProviderStateMixin {
  late final ChangeVideoGetx controller;
  final String _tag = UniqueKey().toString();

  // PickSingleVideoController is already a GetX controller in your codebase
  // — kept exactly as-is, just tagged so it's scoped to this screen instance.
  late final PickSingleVideoController change_video_cont_getx;
  final String _videoTag = UniqueKey().toString();

  final TextEditingController ProviderServiceIdCont = TextEditingController();
  final TextEditingController ProviderServiceResIdCont = TextEditingController();
  final FocusNode _serviceIdFocus = FocusNode();
  final FocusNode _serviceResIdFocus = FocusNode();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _serviceIdHasFocus = false;
  bool _serviceResIdHasFocus = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChangeVideoGetx(), tag: _tag);
    controller.init(email: widget.User_Email, jwtToken: widget.User_JwtToken);

    change_video_cont_getx = Get.put(PickSingleVideoController(), tag: _videoTag);

    _serviceIdFocus.addListener(() {
      setState(() => _serviceIdHasFocus = _serviceIdFocus.hasFocus);
    });
    _serviceResIdFocus.addListener(() {
      setState(() => _serviceResIdHasFocus = _serviceResIdFocus.hasFocus);
    });

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    ProviderServiceIdCont.dispose();
    ProviderServiceResIdCont.dispose();
    _serviceIdFocus.dispose();
    _serviceResIdFocus.dispose();
    Get.delete<ChangeVideoGetx>(tag: _tag);
    Get.delete<PickSingleVideoController>(tag: _videoTag);
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Responsive helpers (identical to the photo screen)
  // ---------------------------------------------------------------------
  double _horizontalPadding(double width) {
    if (width < 420) return 18;
    if (width < 700) return 32;
    if (width < 1100) return 60;
    return (width - 1100) / 2 + 80;
  }

  double _cardMaxWidth(double width, Orientation orientation) {
    if (width < 500) return double.infinity;
    if (orientation == Orientation.landscape && width < 900) return 480;
    return 520;
  }

  Widget _glowBlob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: 130, spreadRadius: 46)],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF16301F),
                _Palette.bodyBg,
                Color(0xFF0B1712),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(top: -70, right: -60, child: _glowBlob(_Palette.accent.withOpacity(0.15), 250)),
        Positioned(top: 260, left: -100, child: _glowBlob(_Palette.accentMint.withOpacity(0.09), 220)),
        Positioned(bottom: -100, right: -70, child: _glowBlob(_Palette.accent.withOpacity(0.11), 250)),
        Positioned(bottom: 120, left: -70, child: _glowBlob(_Palette.accentMint.withOpacity(0.09), 220)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _Palette.headerFooter,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 14,
      leadingWidth: 64,
      leading: Builder(
        builder: (context) {
          if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Center(
              child: Material(
                color: _Palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _Palette.accent.withOpacity(0.55), width: 1.4),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    // Bordered container + primary-text-colored arrow so the
                    // back action stays clearly visible on the dark surface.
                    child: Icon(Icons.arrow_back_rounded, color: _Palette.textPrimary, size: 20),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_Palette.accent, _Palette.accentMint]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: _Palette.accent.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.video_camera_back_rounded, color: _Palette.bodyBg, size: 19),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Update Resource Video',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: _Palette.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickVideo() async {
    try {
      int VideoResult = await change_video_cont_getx.pickVideo();
      if (VideoResult == 1) {
        controller.Toast.Toastmsg("Pick video for service resources success.");
        return;
      } else if (VideoResult == 3) {
        controller.Toast.Toastmsg("Invalid video extension(format only .mp4)");
        return;
      } else if (VideoResult == 2) {
        controller.Toast.Toastmsg("Video is larger than 1 GB.");
        return;
      } else {
        controller.Toast.Toastmsg("Pick Video for service resources fail.");
        return;
      }
    } catch (e) {
      controller.Toast.Toastmsg("Pick Video for service resources fail.");
      return;
    }
  }

  Future<void> _handleUpdate() async {
    try {
      if (change_video_cont_getx.videoBytes.value != null) {
        await controller.UpdateServiceResourcesVideo(
          VideoBytes: change_video_cont_getx.videoBytes.value!,
          ServiceResourcesId: ProviderServiceIdCont.text.trim(),
          ProviderServiceId: ProviderServiceIdCont.text.trim(),
          VideoExtension: change_video_cont_getx.videoExtension.value!,
        );
        return;
      } else {
        controller.Toast.Toastmsg(
          "Pick photo(.png,.jpg,.jpeg) and video(.mp4) in correct format and then try again.",
        );
        return;
      }
    } catch (exception) {
      return;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(0)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bodyBg,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, outer) {
          final Orientation orientation = MediaQuery.of(context).orientation;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double horizontalPadding = _horizontalPadding(width);
                final double cardMaxWidth = _cardMaxWidth(width, orientation);

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: outer.maxHeight),
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildBackground()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 28,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: cardMaxWidth),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildCard(width),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(color: _Palette.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600));
  }

  Widget _styledField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool hasFocus,
    required String hint,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: _Palette.bodyBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFocus ? _Palette.accent.withOpacity(0.75) : _Palette.borderColor,
          width: hasFocus ? 1.6 : 1.2,
        ),
        boxShadow: hasFocus
            ? [BoxShadow(color: _Palette.accent.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: false,
        style: const TextStyle(color: _Palette.textPrimary, fontSize: 14.5),
        cursorColor: _Palette.accentMint,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _Palette.textMuted.withOpacity(0.6), fontSize: 14),
          prefixIcon: Icon(icon, color: _Palette.textMuted, size: 19),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildCard(double width) {
    return Container(
      padding: EdgeInsets.all(width < 420 ? 20 : 30),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Icon badge ---
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_Palette.accent.withOpacity(0.22), _Palette.accentMint.withOpacity(0.12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _Palette.accent.withOpacity(0.4)),
            ),
            child: const Icon(Icons.smart_display_rounded, color: _Palette.accentMint, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            'Replace resource video',
            style: TextStyle(
              color: _Palette.textPrimary,
              fontSize: width < 420 ? 20 : 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the service and resource IDs, pick a new video, then confirm the update.',
            style: TextStyle(color: _Palette.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 26),

          // --- Service ID field ---
          _fieldLabel('Service ID'),
          const SizedBox(height: 8),
          _styledField(
            controller: ProviderServiceIdCont,
            focusNode: _serviceIdFocus,
            hasFocus: _serviceIdHasFocus,
            hint: 'Enter service ID',
            icon: Icons.tag_rounded,
          ),

          const SizedBox(height: 18),

          // --- Service Resource ID field ---
          _fieldLabel('Service Resource ID'),
          const SizedBox(height: 8),
          _styledField(
            controller: ProviderServiceResIdCont,
            focusNode: _serviceResIdFocus,
            hasFocus: _serviceResIdHasFocus,
            hint: 'Enter service resource ID',
            icon: Icons.badge_outlined,
          ),

          const SizedBox(height: 22),

          // --- Video preview / picker ---
          Obx(() {
            final bytes = change_video_cont_getx.videoBytes.value;
            final extension = change_video_cont_getx.videoExtension.value;
            final bool hasVideo = bytes != null;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _handlePickVideo,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _Palette.bodyBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasVideo ? _Palette.accentMint.withOpacity(0.5) : _Palette.borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _Palette.surface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: hasVideo ? _Palette.accentMint.withOpacity(0.5) : _Palette.borderColor,
                          ),
                        ),
                        child: Icon(
                          hasVideo ? Icons.movie_rounded : Icons.video_call_outlined,
                          color: hasVideo ? _Palette.accentMint : _Palette.textMuted,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasVideo ? 'Video selected' : 'Pick video for service resources',
                              style: TextStyle(
                                color: hasVideo ? _Palette.textPrimary : _Palette.textMuted,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasVideo
                                  ? '${extension?.toUpperCase() ?? 'MP4'} · ${_formatBytes(bytes!.length)} · tap to change'
                                  : 'Supported format: mp4 (max 1 GB).',
                              style: TextStyle(color: _Palette.textMuted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        hasVideo ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                        color: hasVideo ? _Palette.accentMint : _Palette.textMuted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          // --- Hint above the button ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: _Palette.textMuted.withOpacity(0.85), size: 15),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Make sure a video is selected above before tapping update.',
                  style: TextStyle(color: _Palette.textMuted, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // --- Update button ---
          Obx(() {
            final bool submitting = controller.isSubmitting.value;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: submitting ? null : _handleUpdate,
                child: Ink(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: submitting
                          ? [_Palette.accent.withOpacity(0.5), _Palette.accentMint.withOpacity(0.5)]
                          : [_Palette.accent, _Palette.accentMint],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: submitting
                        ? []
                        : [
                      BoxShadow(
                        color: _Palette.accent.withOpacity(0.32),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: submitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(_Palette.bodyBg),
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.cloud_upload_rounded, color: _Palette.bodyBg, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Update Resource',
                          style: TextStyle(
                            color: _Palette.bodyBg,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // --- Footer note ---
          Row(
            children: [
              Icon(Icons.video_file_outlined, color: _Palette.textMuted.withOpacity(0.8), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Only mp4 videos up to 1 GB are accepted.",
                  style: TextStyle(color: _Palette.textMuted, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}