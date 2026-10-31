import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state management/getx/profile/provider/Provider_Sel_Pho_Vid_Fil_Gallery_getx.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../provider_user/Provider_Ser_Res_Video_Screen.dart';
import '../provider_user/Provider_Service_File.dart';
import '../provider_user/Provider_Service_Photo.dart';
import '../provider_user/view_serv_res_file_screen.dart';

class MyGalleryScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;

  const MyGalleryScreen({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.Service_Name,
  });

  @override
  State<MyGalleryScreen> createState() => _MyGalleryScreenState();
}

class _MyGalleryScreenState extends State<MyGalleryScreen> {
  // ---------------- Dark Green Palette ----------------
  static const Color bodyBg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color textPrimary = Color(0xFFE6F4EA);
  static const Color textMuted = Color(0xFF8A9A90);
  static const Color headerFooter = Color(0xFF12261C);
  static const Color accent = Color(0xFF22C55E);
  static const Color accentMint = Color(0xFF34D399);
  static const Color borderColor = Color(0xFF234232);
  static const Color borderStrong = Color(0xFF2F5A43);
  // ------------------------------------------------------

  late final ProviderSelPhoVidFilGalleryGetx controller;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProviderSelPhoVidFilGalleryGetx(), tag: _tag);

    // The animation lists are sized from the ACTUAL number of actions below,
    // so you can add / remove items in _galleryItems() freely.
    try {
      controller.setCardCount(_galleryItems().length);
    } catch (e) {
      debugPrint('setCardCount error: $e');
    }

    _verify();
  }

  Future<void> _verify() async {
    try {
      await controller.verifyJwt(jwtToken: widget.User_JwtToken);
      if (!mounted) return;
      if (!controller.isSessionValid.value) {
        await Clear_User_Data();
        await Random_token_Clear();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('MyGalleryScreen verify error: $e');
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

  // ======================================================================
  // THE ACTIONS — add / remove / reorder items here, nothing else to change.
  // ======================================================================
  List<_GalleryItem> _galleryItems() {
    void open(Widget Function() page) {
      try {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page()));
      } catch (e) {
        debugPrint('navigation error: $e');
      }
    }

    return [
      _GalleryItem(
        icon: Icons.insert_drive_file_rounded,
        title: 'Service File',
        subtitle: 'Access documents and other files',
        onTap: () => open(() => ProviderServiceFile(
          User_Email: widget.User_Email,
          User_JwtToken: widget.User_JwtToken,
          User_Role: widget.User_Role,
          Service_Name: widget.Service_Name,
        )),
      ),
      _GalleryItem(
        icon: Icons.folder_copy_rounded,
        title: 'Resource File',
        subtitle: 'Browse and review your video content',
        onTap: () => open(() => ViewServResFileScreen(
          User_Email: widget.User_Email,
          User_JwtToken: widget.User_JwtToken,
          Service_Name: widget.Service_Name,
        )),
      ),
      _GalleryItem(
        icon: Icons.photo_camera_rounded,
        title: 'Resource Photo',
        subtitle: 'View & manage your uploaded photos',
        onTap: () => open(() => ProviderServicePhoto(
          User_Email: widget.User_Email,
          User_JwtToken: widget.User_JwtToken,
          User_Role: widget.User_Role,
          Service_Name: widget.Service_Name,
        )),
      ),
      _GalleryItem(
        icon: Icons.videocam_rounded,
        title: 'Resource Video',
        subtitle: 'Browse and review your video content',
        onTap: () => open(() => ProviderSerResVideoScreen(
          User_Email: widget.User_Email,
          User_JwtToken: widget.User_JwtToken,
          User_Role: widget.User_Role,
          Service_Name: widget.Service_Name,
        )),
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // APP BAR (transparent over the forest background)
  // ---------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(bool canPop) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      leadingWidth: canPop ? 64 : 0,
      titleSpacing: canPop ? 4 : 20,
      leading: canPop
          ? Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        child: Builder(
          builder: (context) => Tooltip(
            message: 'Back',
            child: Material(
              color: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: borderStrong, width: 1.3),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: textPrimary, size: 18),
                ),
              ),
            ),
          ),
        ),
      )
          : null,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [accent, accentMint]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.photo_library_rounded,
                color: bodyBg, size: 19),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'My Gallery',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SCROLL SHELL — full width at every size, never overflows.
  // ---------------------------------------------------------------------
  Widget _scrollShell({required BoxConstraints c, required Widget child}) {
    final double w = c.maxWidth.isFinite ? c.maxWidth : 360;
    final double h = c.maxHeight.isFinite ? c.maxHeight : 600;
    const double minW = 260;

    final Widget vertical = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: h),
        child: child,
      ),
    );

    if (w >= minW) return vertical;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: minW, height: h, child: vertical),
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showSpinner = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _Reveal(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _Glass(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSpinner)
                    const SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(accent)),
                    )
                  else
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.09),
                        border: Border.all(color: accent.withOpacity(0.4)),
                      ),
                      child: Icon(icon,
                          color: accentMint.withOpacity(0.95), size: 34),
                    ),
                  const SizedBox(height: 18),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: textMuted, fontSize: 13.5, height: 1.45)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HERO
  // ---------------------------------------------------------------------
  Widget _buildHero(double width, int count) {
    final bool small = width < 480;
    final String name = widget.Service_Name.trim().isEmpty
        ? 'Unknown service'
        : widget.Service_Name;

    return _Glass(
      radius: 24,
      padding: EdgeInsets.all(small ? 18 : 24),
      tint: accent.withOpacity(0.08),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Text(
                    '$count action${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: accentMint,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Manage Your Media',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: small ? 22 : 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Organize photos, videos and files for',
                      style: TextStyle(
                          color: textMuted, fontSize: small ? 13 : 15),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: math.max(width - 80, 120)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.35)),
                        ),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: accentMint,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (width >= 620) ...[
            const SizedBox(width: 20),
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  accent.withOpacity(0.22),
                  accent.withOpacity(0.02),
                  Colors.transparent,
                ]),
              ),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border:
                  Border.all(color: accent.withOpacity(0.3), width: 1.4),
                ),
                child: const Icon(Icons.perm_media_rounded,
                    color: accentMint, size: 26),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CARDS GRID — adapts to ANY number of items
  // ---------------------------------------------------------------------
  Widget _buildCardsLayout(double contentWidth, List<_GalleryItem> items) {
    int columns = contentWidth >= 760 ? 3 : (contentWidth >= 480 ? 2 : 1);
    columns = math.max(1, math.min(columns, items.length));

    const double spacing = 18.0;
    final double cardWidth = columns == 1
        ? contentWidth
        : (contentWidth - spacing * (columns - 1)) / columns;

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

  Widget _buildContent(double width) {
    final List<_GalleryItem> items = _galleryItems();
    final double pad = _horizontalPadding(width);
    final double contentWidth = math.max(width - pad * 2, 180);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 18),
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Reveal(child: _buildHero(contentWidth, items.length)),
              const SizedBox(height: 22),
              if (items.isEmpty)
                _buildStateMessage(
                  icon: Icons.inbox_rounded,
                  title: 'No data available',
                  subtitle: 'There are no actions available for this service.',
                )
              else
                _buildCardsLayout(contentWidth, items),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    final bool canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: bodyBg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(canPop),
      body: _ForestBackdrop(
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, c) {
                return Obx(() {
                  Widget body;

                  if (controller.isVerifying.value) {
                    body = _buildStateMessage(
                      icon: Icons.shield_outlined,
                      title: 'Verifying session...',
                      subtitle: 'Please wait a moment',
                      showSpinner: true,
                    );
                  } else if (!controller.isSessionValid.value) {
                    body = _buildStateMessage(
                      icon: Icons.shield_outlined,
                      title: 'Session ended',
                      subtitle: 'Redirecting you to login...',
                      showSpinner: true,
                    );
                  } else {
                    body = _buildContent(c.maxWidth.isFinite ? c.maxWidth : 360);
                  }

                  return _scrollShell(c: c, child: body);
                });
              },
            ),
          ),
        ),
      ),
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

// ===========================================================================
// ACTION CARD — safe for ANY index (no fixed-size list assumptions)
// ===========================================================================
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
    const Color accent = _MyGalleryScreenState.accent;
    const Color mint = _MyGalleryScreenState.accentMint;

    return Obx(() {
      // Bounds-checked: a missing entry can never crash the build.
      final bool visible = index < controller.cardVisible.length
          ? controller.cardVisible[index]
          : true;
      final bool hovered = index < controller.cardHover.length
          ? controller.cardHover[index]
          : false;

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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, hovered ? -6.0 : 0.0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: hovered
                    ? [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: hovered
                                ? accent.withOpacity(0.65)
                                : _MyGalleryScreenState.borderStrong
                                .withOpacity(0.8),
                            width: 1.4,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              hovered
                                  ? accent.withOpacity(0.13)
                                  : Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                            ],
                          ),
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
                                      ? [accent, mint]
                                      : [
                                    accent.withOpacity(0.16),
                                    mint.withOpacity(0.10),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: accent.withOpacity(0.35)),
                              ),
                              child: Icon(
                                icon,
                                color: hovered
                                    ? _MyGalleryScreenState.bodyBg
                                    : mint,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _MyGalleryScreenState.textPrimary,
                                      fontSize: 16.5,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    subtitle,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _MyGalleryScreenState.textMuted,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              transform: Matrix4.translationValues(
                                  hovered ? 3.0 : 0.0, 0, 0),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: hovered
                                    ? mint
                                    : _MyGalleryScreenState.textMuted,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ===========================================================================
// SHARED UI PIECES
// ===========================================================================

/// Fade + slide-up entrance.
class _Reveal extends StatelessWidget {
  final Widget child;
  const _Reveal({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
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
  final Color? tint;
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.tint,
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
                (tint ?? Colors.white.withOpacity(0.08)),
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

// ===========================================================================
// BACKGROUND (fixed full-screen layer behind everything — private to this file)
// ===========================================================================

/// Dark forest base + soft emerald/mint ambient blobs + blurred glass bubbles.
/// - Purely decorative: wrapped in IgnorePointer, never blocks taps/text.
/// - Animation is driven by an AnimationController (no setState).
/// - Painted inside a RepaintBoundary so only the background repaints.
class _ForestBackdrop extends StatefulWidget {
  final Widget child;
  const _ForestBackdrop({super.key, required this.child});

  @override
  State<_ForestBackdrop> createState() => _ForestBackdropState();
}

class _ForestBackdropState extends State<_ForestBackdrop>
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
            child: CustomPaint(painter: _ForestBackdropPainter(_ctrl), size: Size.infinite),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ForestBackdropPainter extends CustomPainter {
  final Animation<double> t;
  _ForestBackdropPainter(this.t) : super(repaint: t);

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
  bool shouldRepaint(covariant _ForestBackdropPainter old) => false; // driven by `repaint`
}