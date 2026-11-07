import 'package:app/web/common%20widget/GreenTextfield.dart';

import 'package:app/web/services/services_provider_service_select.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constant/Server_Database.dart';
import '../../models/ServiceScreenServiceModel.dart';
import '../../models/ServiceScreenUserInfoModel.dart';
import '../../state management/getx/services/select_service_provider_info_screen_getx.dart';
import '../../constant/variable.dart';
import '../common method/Commmon_Method.dart';

/// ---------------------------------------------------------------------------
/// THEME TOKENS (dark green, modern) — matches Header.dart / ProviderProfile.dart
/// ---------------------------------------------------------------------------
class _Theme {
  static const Color bgTop = Color(0xFF0F1F17);
  static const Color bgMid = Color(0xFF12261C);
  static const Color bgBottom = Color(0xFF0A160F);

  static const Color surface = Color(0xFF162E22);
  static const Color surfaceBar = Color(0xFF12261C);

  static const Color primaryText = Color(0xFFE6F4EA);
  static const Color mutedText = Color(0xFF9AA0A6);
  static const Color mutedTextAlt = Color(0xFF8A9A90);

  static const Color emerald = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color amber = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  static const Color border = Color(0xFF234232);
}

class SelectServiceProviderInfoScreen extends StatefulWidget {
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final double Distance;
  final double Rating;
  final String Provider_User_Email;
  final String Provider_Service_Name;
  final num ServiceId;
  final num Providernumber;
  final String ProRegServiceDescription;
  final List<ServiceScreenServiceModel> Service_info_List;
  final List<ServiceScreenUserInfoModel> Provider_info_List;

  const SelectServiceProviderInfoScreen({
    super.key,
    required this.Current_User_Email,
    required this.Current_User_JwtToken,
    required this.Current_User_Role,
    required this.Distance,
    required this.Rating,
    required this.Provider_User_Email,
    required this.Service_info_List,
    required this.Provider_info_List,
    required this.Provider_Service_Name,
    required this.Providernumber,
    required this.ServiceId,
    required this.ProRegServiceDescription,
  });

  @override
  State<SelectServiceProviderInfoScreen> createState() =>
      _SelectServiceProviderInfoScreenState();
}

class _SelectServiceProviderInfoScreenState
    extends State<SelectServiceProviderInfoScreen>
    with SingleTickerProviderStateMixin {
  final providerCont = Get.put(SelectServiceProviderInfoScreenGetx());

  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _statsAnim;
  late final Animation<double> _servicesAnim;
  late final Animation<double> _actionsAnim;

  final UserBookingDescriptionTextCont = TextEditingController();

  @override
  void initState() {
    super.initState();

    // API call lives in the controller now.
    providerCont.verifySession(
      jwtToken: widget.Current_User_JwtToken,
      context: context,
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _statsAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.70, curve: Curves.easeOutCubic),
    );
    _servicesAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    );
    _actionsAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    UserBookingDescriptionTextCont.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA HELPERS (UI only)
  // ============================================================

  ServiceScreenUserInfoModel? get _provider {
    for (final p in widget.Provider_info_List) {
      if (p.userNumber == widget.Providernumber) return p;
    }
    return null;
  }

  List<ServiceScreenServiceModel> get _providerServices {
    return widget.Service_info_List
        .where((s) => s.userNumber == widget.Providernumber)
        .toList();
  }

  /// Builds a full image URL from a stored relative photo path.
  String GetPhotoUrl(String photoPath) {
    if (photoPath.trim().isEmpty) return "";

    final baseUrl = Backend_Server_Url.endsWith("/")
        ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
        : Backend_Server_Url;

    final path = photoPath.startsWith("/") ? photoPath : "/$photoPath";
    return "$baseUrl$path";
  }

  // ============================================================
  // CONFIRM DIALOG (UI only)
  // ============================================================

  Future<bool> _confirmBooking() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _Theme.surface,
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _Theme.border),
          ),
          title: Row(
            children: [
              const Icon(Icons.event_available_rounded, color: _Theme.mint),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  "Confirm booking?",
                  style: TextStyle(
                    color: _Theme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "You are about to book \"${valueOrNA(widget.Provider_Service_Name)}\" "
                "from provider #${widget.Providernumber}.\n\n"
                "The description you entered cannot be updated later.",
            style: const TextStyle(
              color: _Theme.mutedText,
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: _Theme.mutedTextAlt),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Theme.emerald,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double widthval = media.size.width;
    final double heightval = media.size.height;

    final bool isMobile = widthval < 700;
    final bool isTablet = widthval >= 700 && widthval < 1100;

    final double horizontalPadding = isMobile ? 18 : (isTablet ? 32 : 48);
    final double contentMaxWidth = widthval > 1000 ? 880 : double.infinity;

    final provider = _provider;
    final services = _providerServices;

    final String fullName =
    "${provider?.firstName ?? ""} ${provider?.lastName ?? ""}".trim();
    final String phone = provider?.phoneNumber ?? "";
    final String whatsapp = provider?.whatsappPhoneNumber ?? "";
    final bool? status = provider?.status;

    return Scaffold(
      backgroundColor: _Theme.bgTop,
      body: Stack(
        children: [
          // Fixed background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_Theme.bgTop, _Theme.bgMid, _Theme.bgBottom],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Ambient bubbles
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -heightval * 0.08,
                    left: -widthval * 0.20,
                    child: _bubble(widthval * 0.65, _Theme.emerald, 0.16),
                  ),
                  Positioned(
                    top: heightval * 0.32,
                    right: -widthval * 0.25,
                    child: _bubble(widthval * 0.55, _Theme.mint, 0.10),
                  ),
                  Positioned(
                    bottom: -heightval * 0.10,
                    left: -widthval * 0.15,
                    child: _bubble(widthval * 0.60, _Theme.emerald, 0.12),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, outerConstraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                    BoxConstraints(minHeight: outerConstraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: isMobile ? 20 : 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBackRow(context, isMobile),
                              SizedBox(height: isMobile ? 20 : 28),

                              if (provider == null)
                                _notFoundCard()
                              else ...[
                                _animatedSection(
                                  animation: _heroAnim,
                                  child: _buildHero(
                                    isMobile: isMobile,
                                    fullName: fullName,
                                    status: status,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 18 : 24),

                                _animatedSection(
                                  animation: _statsAnim,
                                  child: _buildStatsRow(
                                    isMobile: isMobile,
                                    serviceCount: services.length,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 18 : 24),

                                _animatedSection(
                                  animation: _statsAnim,
                                  child: _buildAboutCard(
                                    isMobile: isMobile,
                                    phone: phone,
                                    whatsapp: whatsapp,
                                  ),
                                ),

                                SizedBox(height: isMobile ? 18 : 24),

                                _animatedSection(
                                  animation: _servicesAnim,
                                  child: _buildServicesCard(
                                    isMobile: isMobile,
                                    services: services,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 18 : 24),

                                _animatedSection(
                                  animation: _servicesAnim,
                                  child: _buildBookingCard(isMobile: isMobile),
                                ),
                                SizedBox(height: isMobile ? 18 : 24),

                                _animatedSection(
                                  animation: _actionsAnim,
                                  child: _buildActions(isMobile, status),
                                ),
                              ],

                              SizedBox(height: isMobile ? 20 : 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color, double opacity) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _animatedSection({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, builtChild) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 22),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }

  // ============================================================
  // BACK ROW
  // ============================================================

  Widget _buildBackRow(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Material(
          color: _Theme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _Theme.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _Theme.primaryText,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            "Provider Profile",
            style: TextStyle(
              color: _Theme.primaryText,
              fontSize: isMobile ? 19 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NOT FOUND
  // ============================================================

  Widget _notFoundCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Theme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_rounded,
              color: _Theme.mutedTextAlt, size: 34),
          const SizedBox(height: 12),
          const Text(
            "Provider not found",
            style: TextStyle(
              color: _Theme.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "We couldn't find profile details for this provider.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _Theme.mutedText, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero({
    required bool isMobile,
    required String fullName,
    required bool? status,
  }) {
    final String serviceName = valueOrNA(widget.Provider_Service_Name);
    final bool serviceMissing = serviceName == kDataNotAvailable;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF193A29), Color(0xFF12261C), Color(0xFF101F18)],
        ),
        border: Border.all(color: _Theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 520;
          final CrossAxisAlignment align =
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start;
          final TextAlign textAlign =
          compact ? TextAlign.center : TextAlign.start;

          final avatar = _buildAvatar();

          final info = Column(
            crossAxisAlignment: align,
            children: [
              _pill(
                icon: Icons.verified_rounded,
                text: "Provider profile",
                color: _Theme.mint,
              ),
              const SizedBox(height: 14),
              Text(
                fullName.isEmpty ? kDataNotAvailable : fullName,
                textAlign: textAlign,
                style: TextStyle(
                  color: fullName.isEmpty
                      ? _Theme.mutedText
                      : _Theme.primaryText,
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: compact ? WrapAlignment.center : WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusPill(status),
                  _pill(
                    icon: Icons.design_services_rounded,
                    text: serviceName,
                    color: serviceMissing ? _Theme.mutedText : _Theme.mint,
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                avatar,
                const SizedBox(height: 18),
                info,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 24),
              Expanded(child: info),
            ],
          );
        },
      ),
    );
  }


  Widget _buildAvatar() {
    final provider = _provider;
    final photoUrl = GetPhotoUrl(provider?.photo ?? "");

    return Container(
      height: 96,
      width: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(48),
        gradient: RadialGradient(
          colors: [
            _Theme.emerald.withOpacity(0.22),
            _Theme.emerald.withOpacity(0.02),
            Colors.transparent,
          ],
        ),
      ),
      child: Container(
        height: 78,
        width: 78,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(39),
          border: Border.all(color: _Theme.emerald.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _Theme.emerald.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(39),
          child: Container(
            color: _Theme.surface,
            child: photoUrl.isEmpty
                ? const Icon(Icons.person_rounded, color: _Theme.mint, size: 34)
                : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    color: _Theme.emerald,
                    strokeWidth: 2.2,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person_rounded,
                    color: _Theme.mint, size: 34);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(bool? status) {
    if (status == null) {
      return _pill(
        icon: Icons.info_outline_rounded,
        text: kDataNotAvailable,
        color: _Theme.mutedText,
      );
    }
    return status
        ? _pill(
      icon: Icons.lock_clock_rounded,
      text: "Reserved",
      color: _Theme.danger,
    )
        : _pill(
      icon: Icons.check_circle_rounded,
      text: "Available",
      color: _Theme.emerald,
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsRow({required bool isMobile, required int serviceCount}) {
    final int fullStars = widget.Rating.floor().clamp(0, 5);
    final bool hasHalfStar = (widget.Rating - fullStars) >= 0.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stack = constraints.maxWidth < 560;

        final children = [
          _statCard(
            icon: Icons.location_on_rounded,
            label: "Distance",
            value: widget.Distance > 0
                ? "${widget.Distance.toStringAsFixed(1)} km"
                : kDataNotAvailable,
          ),
          _statCard(
            icon: Icons.star_rounded,
            iconColor: _Theme.amber,
            label: "Rating",
            value: widget.Rating > 0
                ? widget.Rating.toStringAsFixed(1)
                : "No ratings yet",
            trailing: widget.Rating > 0 ? _starRow(fullStars, hasHalfStar) : null,
          ),
          _statCard(
            icon: Icons.design_services_rounded,
            label: "Services",
            value: serviceCount > 0 ? "$serviceCount" : kDataNotAvailable,
          ),
        ];

        if (stack) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                children[i],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i != 0) const SizedBox(width: 12),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _starRow(int fullStars, bool hasHalfStar) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (i < fullStars) {
          icon = Icons.star_rounded;
        } else if (i == fullStars && hasHalfStar) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, color: _Theme.amber, size: 13);
      }),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = _Theme.mint,
    Widget? trailing,
  }) {
    final bool missing = value == kDataNotAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _Theme.mutedTextAlt,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: missing ? _Theme.mutedText : _Theme.primaryText,
                        fontSize: missing ? 12.5 : 15,
                        fontWeight: FontWeight.w800,
                        fontStyle: missing ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ABOUT + CONTACT
  // ============================================================

  Widget _buildAboutCard({
    required bool isMobile,
    required String phone,
    required String whatsapp,
  }) {
    final String description = valueOrNA(widget.ProRegServiceDescription);

    return _sectionCard(
      isMobile: isMobile,
      icon: Icons.info_outline_rounded,
      title: "About this service",
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool twoCol = constraints.maxWidth >= 480;

          final descriptionBox = _infoBlock(
            label: "Service description",
            value: description,
          );

          final contactBox = Column(
            children: [
              _contactRow(
                icon: Icons.phone_rounded,
                label: "Phone",
                value: valueOrNA(phone),
              ),
            ],
          );

          if (twoCol) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: descriptionBox),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: contactBox),
              ],
            );
          }

          return Column(
            children: [
              descriptionBox,
              const SizedBox(height: 14),
              contactBox,
            ],
          );
        },
      ),
    );
  }

  Widget _infoBlock({required String label, required String value}) {
    final bool missing = value == kDataNotAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _Theme.mutedTextAlt,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: missing ? _Theme.mutedText : _Theme.primaryText,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontStyle: missing ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final bool missing = value == kDataNotAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Theme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _Theme.mint, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _Theme.mutedTextAlt,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: missing ? _Theme.mutedText : _Theme.primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontStyle: missing ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SERVICES
  // ============================================================

  Widget _buildServicesCard({
    required bool isMobile,
    required List<ServiceScreenServiceModel> services,
  }) {
    return _sectionCard(
      isMobile: isMobile,
      icon: Icons.engineering_rounded,
      title: "Services offered",
      child: services.isEmpty
          ? _emptyState("No services listed yet. $kDataNotAvailable")
          : Wrap(
        spacing: 10,
        runSpacing: 10,
        children: services.map((s) {
          final name = valueOrNA(s.serviceName);
          final bool missing = name == kDataNotAvailable;
          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _Theme.surfaceBar,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _Theme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  missing
                      ? Icons.help_outline_rounded
                      : Icons.check_circle_rounded,
                  color: missing ? _Theme.mutedText : _Theme.mint,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color:
                    missing ? _Theme.mutedText : _Theme.primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontStyle:
                    missing ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // BOOKING FORM
  // ============================================================

  Widget _buildBookingCard({required bool isMobile}) {
    return _sectionCard(
      isMobile: isMobile,
      icon: Icons.event_note_rounded,
      title: "Booking details",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _Theme.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Theme.amber.withOpacity(0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: _Theme.amber, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Describe all the details of the service you want to book. "
                        "The description cannot be changed later. ",
                    style: TextStyle(
                      color: _Theme.amber,
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 16),

          GreenField(
            controller: UserBookingDescriptionTextCont,
            label: "Enter all the details that you need.",
            icon: Icons.info,
            keyboardType: TextInputType.multiline,
            obscure: false,
            height: 100,
          ),

          const SizedBox(height: 16),

          Text(
            "Use CamScanner app to convert photos into file(.pdf).You can skip file and video.That are optional.",
            style: TextStyle(
              color: _Theme.amber,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          LayoutBuilder
            (
            builder: (context, constraints) {
              final bool twoCol = constraints.maxWidth >= 480;

              final filePicker = _mediaPickerCard(
                icon: Icons.attach_file_rounded,
                title: "Attach file",
                hint: "Documents or other files",
                onPick: () async => await PickFile(),
                isSelected: () =>
                change_file_cont_getx.fileBytes.value != null &&
                    change_file_cont_getx.fileBytes.value!.isNotEmpty,
                selectedText: () {
                  final ext = change_file_cont_getx.fileExtension.value;
                  return ext.isEmpty ? "File selected" : "File selected (.$ext)";
                },
              );

              final videoPicker = _mediaPickerCard
                (
                icon: Icons.videocam_rounded,
                title: "Attach video",
                hint: "Short video that explains your needs.",
                onPick: () async => await PickVideo(),
                isSelected: () =>
                change_video_cont_getx.videoBytes.value != null &&
                    change_video_cont_getx.videoBytes.value!.isNotEmpty,
                selectedText: () {
                  final ext = change_video_cont_getx.videoExtension.value;
                  return ext.isEmpty ? "Video selected" : "Video selected (.$ext)";
                },
              );

              if (twoCol)
              {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: filePicker),
                    const SizedBox(width: 14),
                    Expanded(child: videoPicker),
                  ],
                );
              }
              return Column(
                children: [
                  filePicker,
                  const SizedBox(height: 12),
                  videoPicker,
                ],

              );
            },
          ),

          const SizedBox(height: 16),

         if(widget.Current_User_Role=="user")Text
           (
            "A Small Request, A Big Support for KaamMitra.KaamMitra is free for user to use.Once your provider has completed the task or you have received the service, kindly visit your (Booking Screen) and update your task complete status to Yes(Completed).Your small action means a lot to us. It helps us grow and bring more useful services to you in the future.Thank you for being a part of KaamMitra Together, we grow.",
            style: TextStyle(
              color: _Theme.amber,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),



        ],
      ),
    );
  }

  Widget _mediaPickerCard({
    required IconData icon,
    required String title,
    required String hint,
    required Future<void> Function() onPick,
    required bool Function() isSelected,
    required String Function() selectedText,
  }) {
    return Obx(() {
      final bool selected = isSelected();

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onPick(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _Theme.surfaceBar,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _Theme.emerald.withOpacity(0.6) : _Theme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _Theme.emerald.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _Theme.mint, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _Theme.primaryText,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selected ? selectedText() : hint,
                        style: TextStyle(
                          color: selected ? _Theme.mint : _Theme.mutedText,
                          fontSize: 11.5,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: selected ? _Theme.emerald : _Theme.mutedTextAlt,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(bool isMobile, bool? status) {
    final galleryButton = _actionButton(
      icon: Icons.photo_library_rounded,
      label: "Provider gallery",
      primary: false,
      pressed: providerCont.isGalleryPressed,
      onPressDown: () => providerCont.setGalleryPressed(true),
      onPressEnd: () => providerCont.setGalleryPressed(false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicesScreenProviderServiceSelect(
              User_Email: widget.Current_User_Email,
              User_JwtToken: widget.Current_User_JwtToken,
              User_Role: widget.Current_User_Role,
              Provider_Email: widget.Provider_User_Email,
            ),
          ),
        );
      },
    );

    final bookButton = _actionButton(
      icon: Icons.event_available_rounded,
      label: "Book now",
      primary: true,
      pressed: providerCont.isBookPressed,
      onPressDown: () => providerCont.setBookPressed(true),
      onPressEnd: () => providerCont.setBookPressed(false),
      onTap: () async {
        // 1. Validation (controller)
        final String? error = providerCont.validateBooking(
          providerStatus: status,
          role: widget.Current_User_Role,
          description: UserBookingDescriptionTextCont.text,
        );
        if (error != null) {
          Toast.Toastmsg(error);
          return;
        }

        // 2. Confirmation (UI)
        final bool confirmed = await _confirmBooking();
        if (!confirmed) return;

        // 3. Booking + notifications (controller owns all API calls)
        await providerCont.bookService(
          context: context,
          jwtToken: widget.Current_User_JwtToken,
          userEmail: widget.Current_User_Email,
          serviceName: widget.Provider_Service_Name,
          serviceId: widget.ServiceId,
          providerNumber: widget.Providernumber,
          distance: widget.Distance,
          description: UserBookingDescriptionTextCont.text.trim(),
        );
      },
    );

    if (isMobile) {
      return Column(
        children: [
          bookButton,
          const SizedBox(height: 12),
          galleryButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: galleryButton),
        const SizedBox(width: 14),
        Expanded(child: bookButton),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool primary,
    required RxBool pressed,
    required VoidCallback onPressDown,
    required VoidCallback onPressEnd,
    required VoidCallback onTap,
  }) {
    return Obx(() {
      final bool isPressed = pressed.value;

      return AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            onTapDown: (_) => onPressDown(),
            onTapCancel: onPressEnd,
            onTapUp: (_) => onPressEnd(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: primary
                    ? const LinearGradient(colors: [_Theme.emerald, _Theme.mint])
                    : null,
                color: primary ? null : _Theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: primary ? null : Border.all(color: _Theme.border),
                boxShadow: primary
                    ? [
                  BoxShadow(
                    color: _Theme.emerald.withOpacity(0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: primary ? Colors.white : _Theme.mint,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    label,
                    style: TextStyle(
                      color: primary ? Colors.white : _Theme.primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ============================================================
  // SHARED CARD + EMPTY STATE
  // ============================================================

  Widget _sectionCard({
    required bool isMobile,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _Theme.emerald.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _Theme.primaryText,
                    fontSize: isMobile ? 15.5 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Theme.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _Theme.mutedText,
          fontSize: 12.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}