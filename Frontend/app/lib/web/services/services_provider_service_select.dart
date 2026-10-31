import 'package:app/web/services/services_screen_MYGallery_screeen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state management/getx/profile/provider/provider_ser_select_getx.dart';
import '../profile/provider/Provider_Sel_Pho_Vid_Fil_Gallery.dart';



class ServicesScreenProviderServiceSelect extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Provider_Email;
  const ServicesScreenProviderServiceSelect({super.key, required this.User_Email, required this.User_JwtToken, required this.User_Role, required this.Provider_Email});

  @override
  State<ServicesScreenProviderServiceSelect> createState() => _ServicesScreenProviderServiceSelectState();
}

class _ServicesScreenProviderServiceSelectState extends State<ServicesScreenProviderServiceSelect> {
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

  late final ProviderSerSelectGetx controller;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProviderSerSelectGetx(), tag: _tag);
    _init();
  }

  Future<void> _init() async {
    await controller.verifyJwt(jwtToken: widget.User_JwtToken);
    if (!controller.isSessionValid.value) return;
    await controller.fetchServices(email: widget.Provider_Email, jwtToken: widget.User_JwtToken);
  }

  @override
  void dispose() {
    Get.delete<ProviderSerSelectGetx>(tag: _tag);
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: headerFooter,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      iconTheme: const IconThemeData(color: textPrimary),
      actionsIconTheme: const IconThemeData(color: textPrimary),
      leading: Builder(
        builder: (context) {
          if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Center(
              child: Material(
                color: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: accent.withOpacity(0.55), width: 1.4),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back_rounded, color: textPrimary, size: 20),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [accent, accentMint]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.dashboard_customize_rounded, color: bodyBg, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Select Service',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  // NOTE: `StackFit.expand` forces every child (including the plain gradient
  // Container, which has no intrinsic size) to fill whatever box this Stack
  // is placed inside. Combined with the ConstrainedBox in build(), this lets
  // the wallpaper stretch to cover the full scrollable content height,
  // not just the visible viewport.
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
                bodyBg,
                Color(0xFF0B1712),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(top: -60, right: -50, child: _glowBlob(accent.withOpacity(0.16), 240)),
        Positioned(top: 260, left: -90, child: _glowBlob(accentMint.withOpacity(0.09), 220)),
        Positioned(bottom: 160, right: -80, child: _glowBlob(accent.withOpacity(0.11), 230)),
        Positioned(bottom: -90, left: -60, child: _glowBlob(accentMint.withOpacity(0.10), 260)),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(accent)),
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Icon(icon, color: accentMint, size: 32),
              ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textMuted, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid(double contentWidth) {
    final int columns =
    contentWidth >= 1000 ? 3 : (contentWidth >= 560 ? 2 : 1);

    const double spacing = 18.0;

    final double cardWidth = columns == 1
        ? contentWidth
        : (contentWidth - spacing * (columns - 1)) / columns;

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(controller.serviceList.length, (index) {
          final service = controller.serviceList[index];

          return SizedBox(
            width: cardWidth,
            child: _ServiceCard(
              index: index,
              label: service.serviceName ?? "Unknown Service",
              controller: controller,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceScreenMyGalleryScreen(
                      User_Email: widget.User_Email,
                      User_JwtToken: widget.User_JwtToken,
                      User_Role: widget.User_Role,
                      Service_Name: service.serviceName!,
                      Provider_Email: widget.Provider_Email,
                    ),
                  ),
                );
              }, Descp: service.proRegServiceDescription!,
            ),
          );
        }),
      ),
    );
  }

  // Wraps whichever "state" body (loading / error / empty / services) is
  // active with a background Stack that is always at least screen-height
  // tall, but can grow with the content when it's the scrollable services
  // view. This is what makes the wallpaper cover the full scroll height
  // instead of stopping at the viewport edge.
  Widget _buildBodyWithBackground({
    required BoxConstraints constraints,
    required Widget child,
    bool scrollable = false,
  }) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          child,
        ],
      ),
    );

    if (scrollable) {
      return SingleChildScrollView(child: content);
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bodyBg,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, outerConstraints) {
          return Obx(() {
            // =========================
            // VERIFYING SESSION
            // =========================
            if (controller.isVerifying.value) {
              return _buildBodyWithBackground(
                constraints: outerConstraints,
                child: _buildStateMessage(
                  icon: Icons.shield_outlined,
                  title: "Verifying session...",
                  subtitle: "Please wait a moment",
                  showSpinner: true,
                ),
              );
            }

            if (!controller.isSessionValid.value) {
              return _buildBodyWithBackground(
                constraints: outerConstraints,
                child: _buildStateMessage(
                  icon: Icons.shield_outlined,
                  title: "Session ended",
                  subtitle: "Redirecting you to login...",
                  showSpinner: true,
                ),
              );
            }

            // =========================
            // LOADING SERVICES
            // =========================
            if (controller.isLoadingServices.value) {
              return _buildBodyWithBackground(
                constraints: outerConstraints,
                child: _buildStateMessage(
                  icon: Icons.hourglass_top_rounded,
                  title: "Loading your services...",
                  subtitle: "Just a moment",
                  showSpinner: true,
                ),
              );
            }

            // =========================
            // ERROR
            // =========================
            if (controller.hasError.value) {
              return _buildBodyWithBackground(
                constraints: outerConstraints,
                child: _buildStateMessage(
                  icon: Icons.error_outline_rounded,
                  title: "Something went wrong",
                  subtitle: "Please try again in a little while.",
                ),
              );
            }

            if (controller.loadFailed.value) {
              return _buildBodyWithBackground(
                constraints: outerConstraints,
                child: _buildStateMessage(
                  icon: Icons.cloud_off_rounded,
                  title: "Failed to load services",
                  subtitle: "Check your connection and try again.",
                ),
              );
            }

            // =========================
            // NO SERVICES
            // =========================
            if (controller.serviceList.isEmpty) {
              return _buildBodyWithBackground(
                constraints: outerConstraints,
                child: _buildStateMessage(
                  icon: Icons.inbox_rounded,
                  title: "No registered services found",
                  subtitle: "Please register a service first to continue.",
                ),
              );
            }


// SERVICES

            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final double horizontalPadding = _horizontalPadding(width);
                  final double contentWidth =
                  (width - horizontalPadding * 2).clamp(0.0, width);

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildBackground(),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 26,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Registered Services',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: width < 480 ? 20 : 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap a service to manage its gallery',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: width < 480 ? 12.5 : 14,
                                    ),
                                  ),
                                  const SizedBox(height: 26),

                                  SizedBox(
                                    width: contentWidth,
                                    child: _buildServiceGrid(contentWidth),
                                  ),

                                  const SizedBox(height: 32),
                                ],
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



          });
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final int index;
  final String label;
  final VoidCallback onTap;
  final ProviderSerSelectGetx controller;
  final String Descp;

  const _ServiceCard({
    required this.index,
    required this.label,
    required this.onTap,
    required this.controller,
    required this.Descp,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool visible = index < controller.cardVisible.length ? controller.cardVisible[index] : true;
      final bool hovered = index < controller.cardHover.length ? controller.cardHover[index] : false;

      return AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.08),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: MouseRegion(
            onEnter: (_) => controller.setHover(index, true),
            onExit: (_) => controller.setHover(index, false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.identity()..translate(0.0, hovered ? -6.0 : 0.0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _ServicesScreenProviderServiceSelectState.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: hovered
                        ? _ServicesScreenProviderServiceSelectState.accent.withOpacity(0.6)
                        : _ServicesScreenProviderServiceSelectState.borderColor,
                    width: 1.4,
                  ),
                  boxShadow: hovered
                      ? [
                    BoxShadow(
                      color: _ServicesScreenProviderServiceSelectState.accent.withOpacity(0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                      : [],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hovered
                              ? [_ServicesScreenProviderServiceSelectState.accent, _ServicesScreenProviderServiceSelectState.accentMint]
                              : [
                            _ServicesScreenProviderServiceSelectState.accent.withOpacity(0.15),
                            _ServicesScreenProviderServiceSelectState.accentMint.withOpacity(0.10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.miscellaneous_services_rounded,
                        color: hovered ? _ServicesScreenProviderServiceSelectState.bodyBg : _ServicesScreenProviderServiceSelectState.accentMint,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ServicesScreenProviderServiceSelectState.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Service Description = $Descp",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ServicesScreenProviderServiceSelectState.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: hovered ? _ServicesScreenProviderServiceSelectState.accentMint : _ServicesScreenProviderServiceSelectState.textMuted,
                      size: 15,
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