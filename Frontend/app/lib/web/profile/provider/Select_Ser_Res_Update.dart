import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state management/getx/profile/provider/select_ser_res_update_photo_video_getx.dart';
import 'Pro_Upd_Ser_Res_Video_Screen.dart';
import 'Pro_Update_Ser_Res_Photo_Screen.dart';

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

class SelectSerResUpdate extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const SelectSerResUpdate({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
  });

  @override
  State<SelectSerResUpdate> createState() => _SelectSerResUpdateState();
}

class _SelectSerResUpdateState extends State<SelectSerResUpdate>
    with SingleTickerProviderStateMixin {
  late final SelectSerResUpdatePhotoVideoGetx controller;
  final String _tag = UniqueKey().toString();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SelectSerResUpdatePhotoVideoGetx(), tag: _tag);
    controller.init(jwtToken: widget.User_JwtToken);

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
    Get.delete<SelectSerResUpdatePhotoVideoGetx>(tag: _tag);
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Responsive helpers
  // ---------------------------------------------------------------------
  double _horizontalPadding(double width) {
    if (width < 420) return 18;
    if (width < 700) return 32;
    if (width < 1100) return 60;
    return (width - 1100) / 2 + 80;
  }

  double _contentMaxWidth(double width) {
    if (width < 700) return double.infinity;
    return 900;
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
            child: const Icon(Icons.edit_note_rounded, color: _Palette.bodyBg, size: 19),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Update Resources',
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

  void _goToPhoto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProUpdateSerResPhotoScreen(
          User_Email: widget.User_Email,
          User_JwtToken: widget.User_JwtToken,
          User_Role: widget.User_Role,
        ),
      ),
    );
  }

  void _goToVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProUpdSerResVideoScreen(
          User_Email: widget.User_Email,
          User_JwtToken: widget.User_JwtToken,
          User_Role: widget.User_Role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bodyBg,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, outer) {
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double horizontalPadding = _horizontalPadding(width);
                final double contentMaxWidth = _contentMaxWidth(width);
                final bool wideLayout = width >= 700;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: outer.maxHeight),
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildBackground()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 30,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: contentMaxWidth),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildContent(width, wideLayout),
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

  Widget _buildContent(double width, bool wideLayout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header ---
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
          child: const Icon(Icons.collections_bookmark_outlined, color: _Palette.accentMint, size: 28),
        ),
        const SizedBox(height: 18),
        Text(
          'What would you like to update?',
          style: TextStyle(
            color: _Palette.textPrimary,
            fontSize: width < 420 ? 21 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a resource type below to replace its uploaded photo or video.',
          style: TextStyle(color: _Palette.textMuted, fontSize: 13.5, height: 1.5),
        ),
        const SizedBox(height: 28),

        // --- Action cards ---
        wideLayout
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.photo_library_rounded,
                title: 'Update Service Photos',
                description: 'Replace or refresh the photos shown for a registered service.',
                hovered: controller.photoCardHovered,
                onHoverChanged: controller.setPhotoHover,
                onTap: _goToPhoto,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _ActionCard(
                icon: Icons.videocam_rounded,
                title: 'Update Service Videos',
                description: 'Replace or refresh the video uploaded for a registered service.',
                hovered: controller.videoCardHovered,
                onHoverChanged: controller.setVideoHover,
                onTap: _goToVideo,
              ),
            ),
          ],
        )
            : Column(
          children: [
            _ActionCard(
              icon: Icons.photo_library_rounded,
              title: 'Update Service Photos',
              description: 'Replace or refresh the photos shown for a registered service.',
              hovered: controller.photoCardHovered,
              onHoverChanged: controller.setPhotoHover,
              onTap: _goToPhoto,
            ),
            const SizedBox(height: 18),
            _ActionCard(
              icon: Icons.videocam_rounded,
              title: 'Update Service Videos',
              description: 'Replace or refresh the video uploaded for a registered service.',
              hovered: controller.videoCardHovered,
              onHoverChanged: controller.setVideoHover,
              onTap: _goToVideo,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // --- Footer note ---
        Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _Palette.textMuted.withOpacity(0.8), size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "You'll be asked to pick the service and the new file on the next screen.",
                style: TextStyle(color: _Palette.textMuted, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// ACTION CARD — large tappable option with icon, title, description, arrow.
// Hover/press feedback driven entirely by a GetX RxBool (no setState).
// ===========================================================================
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final RxBool hovered;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.hovered,
    required this.onHoverChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isHovered = hovered.value;
      return MouseRegion(
        onEnter: (_) => onHoverChanged(true),
        onExit: (_) => onHoverChanged(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.identity()..translate(0.0, isHovered ? -6.0 : 0.0),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _Palette.bodyBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHovered ? _Palette.accent.withOpacity(0.6) : _Palette.borderColor,
                width: 1.4,
              ),
              boxShadow: isHovered
                  ? [
                BoxShadow(
                  color: _Palette.accent.withOpacity(0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHovered
                          ? [_Palette.accent, _Palette.accentMint]
                          : [
                        _Palette.accent.withOpacity(0.16),
                        _Palette.accentMint.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: isHovered ? _Palette.bodyBg : _Palette.accentMint,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: _Palette.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(color: _Palette.textMuted, fontSize: 12.5, height: 1.45),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        color: isHovered ? _Palette.accentMint : _Palette.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: isHovered ? _Palette.accentMint : _Palette.textMuted,
                      size: 15,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}