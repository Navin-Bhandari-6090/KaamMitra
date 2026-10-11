import 'package:app/web/services/service_screen_view_file.dart';
import 'package:app/web/services/service_screen_view_photo.dart';
import 'package:app/web/services/service_screen_view_video.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state management/getx/profile/provider/Provider_Sel_Pho_Vid_Fil_Gallery_getx.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../profile/provider_user/Provider_Service_Photo.dart';



class ServiceScreenMyGalleryScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;
  final String Provider_Email;

  const ServiceScreenMyGalleryScreen({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.Service_Name,
    required this.Provider_Email,
  });

  @override
  State<ServiceScreenMyGalleryScreen> createState() => _ServiceScreenMyGalleryScreenState();
}

class _ServiceScreenMyGalleryScreenState extends State<ServiceScreenMyGalleryScreen> {
  // ---------------- Dark Green Palette ----------------
  static const Color bodyBg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color textPrimary = Color(0xFFE6F4EA);
  static const Color textMuted = Color(0xFF8A9A90);
  static const Color headerFooter = Color(0xFF12261C);
  static const Color accent = Color(0xFF22C55E);
  static const Color accentMint = Color(0xFF34D399);
  static const Color borderColor = Color(0xFF234232);
  // ------------------------------------------------------

  late final ProviderSelPhoVidFilGalleryGetx controller;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProviderSelPhoVidFilGalleryGetx(), tag: _tag);
    _verify();
  }

  Future<void> _verify() async {
    await controller.verifyJwt(jwtToken: widget.User_JwtToken);
    if (!mounted) return;
    if (!controller.isSessionValid.value) {
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()
        ),
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    Get.delete<ProviderSelPhoVidFilGalleryGetx>(tag: _tag);
    super.dispose();
  }

  double _horizontalPadding(double width) {
    if (width < 420) return 16;
    if (width < 700) return 24;
    if (width < 1100) return 40;
    return (width - 1100) / 2 + 60;
  }

  Widget _glowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 40)],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bodyBg, Color(0xFF0B1712)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Verifying session...',
              style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(double width) {
    final bool isNarrow = width < 480;
    final bool canPop = Navigator.of(context).canPop();
    return Row(
      children: [
        if (canPop) ...[
          Material(
            color: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: accent.withOpacity(0.55), width: 1.4),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: isNarrow ? 38 : 42,
                height: isNarrow ? 38 : 42,
                child: Icon(Icons.arrow_back_rounded, color: textPrimary, size: isNarrow ? 18 : 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [accent, accentMint]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Icon(Icons.photo_library_rounded, color: bodyBg, size: isNarrow ? 20 : 24),
        ),
        const SizedBox(width: 14),
        Text(
          'My Gallery',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: isNarrow ? 20 : 24,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(double width) {
    final bool isNarrow = width < 480;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Your Media',
          style: TextStyle(
            color: textPrimary,
            fontSize: isNarrow ? 22 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Organize photos, videos and files for  ',
              style: TextStyle(color: textMuted, fontSize: isNarrow ? 13 : 15),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(0.35)),
              ),
              child: Text(
                widget.Service_Name,
                style: const TextStyle(color: accentMint, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<_GalleryItem> _buildItems(BuildContext context) {
    return [
      _GalleryItem(
        icon: Icons.photo_camera_rounded,
        title: 'Photo',
        subtitle: 'View & manage your uploaded photos',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceScreenProviderServicePhoto(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
              Service_Name: widget.Service_Name,
              Provider_Email: widget.Provider_Email,
            ),
          ),
        ),
      ),
      _GalleryItem(
        icon: Icons.videocam_rounded,
        title: 'Video',
        subtitle: 'Browse and review your video content',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceScreenProviderSerResVideoScreen(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
              Service_Name: widget.Service_Name, Provider_Email: '${widget.Provider_Email}',
            ),
          ),
        ),
      ),
      _GalleryItem(
        icon: Icons.insert_drive_file_rounded,
        title: 'File',
        subtitle: 'Access documents and other files',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceScreenProviderServiceFile(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
              Service_Name: widget.Service_Name,
              Provider_Email: '${widget.Provider_Email}',
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildCardsLayout(BuildContext context, double contentWidth) {
    final items = _buildItems(context);
    final int columns = contentWidth >= 760 ? 3 : (contentWidth >= 480 ? 2 : 1);
    const double spacing = 20.0;
    final double cardWidth =
    columns == 1 ? contentWidth : (contentWidth - spacing * (columns - 1)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(items.length, (index) {
        final item = items[index];
        return SizedBox(
          width: cardWidth,
          child: _AnimatedGalleryCard(
            index: index,
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            onTap: item.onTap,
            controller: controller,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bodyBg,
      body: Obx(() {
        if (controller.isVerifying.value) {
          return _buildLoadingState();
        }
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bodyBg, Color(0xFF0B1712)],
                ),
              ),
            ),
            Positioned(top: -80, right: -60, child: _glowBlob(accent.withOpacity(0.12), 220)),
            Positioned(bottom: -100, left: -80, child: _glowBlob(accentMint.withOpacity(0.08), 260)),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final double horizontalPadding = _horizontalPadding(width);
                  final double contentWidth = width - horizontalPadding * 2;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(contentWidth),
                        const SizedBox(height: 32),
                        _buildTitleSection(contentWidth),
                        const SizedBox(height: 28),
                        _buildCardsLayout(context, contentWidth),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _GalleryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GalleryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _AnimatedGalleryCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ProviderSelPhoVidFilGalleryGetx controller;

  const _AnimatedGalleryCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool visible = controller.cardVisible[index];
      final bool hovered = controller.cardHover[index];

      return AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.08),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          child: MouseRegion(
            onEnter: (_) => controller.setHover(index, true),
            onExit: (_) => controller.setHover(index, false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                transform: Matrix4.identity()..translate(0.0, hovered ? -6.0 : 0.0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _ServiceScreenMyGalleryScreenState.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hovered
                        ? _ServiceScreenMyGalleryScreenState.accent.withOpacity(0.6)
                        : _ServiceScreenMyGalleryScreenState.borderColor,
                    width: 1.4,
                  ),
                  boxShadow: hovered
                      ? [
                    BoxShadow(
                      color: _ServiceScreenMyGalleryScreenState.accent.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                      : [],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hovered
                              ? [_ServiceScreenMyGalleryScreenState.accent, _ServiceScreenMyGalleryScreenState.accentMint]
                              : [
                            _ServiceScreenMyGalleryScreenState.accent.withOpacity(0.15),
                            _ServiceScreenMyGalleryScreenState.accentMint.withOpacity(0.10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: hovered ? _ServiceScreenMyGalleryScreenState.bodyBg : _ServiceScreenMyGalleryScreenState.accentMint,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: _ServiceScreenMyGalleryScreenState.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: _ServiceScreenMyGalleryScreenState.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: hovered ? _ServiceScreenMyGalleryScreenState.accentMint : _ServiceScreenMyGalleryScreenState.textMuted,
                      size: 16,
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
}