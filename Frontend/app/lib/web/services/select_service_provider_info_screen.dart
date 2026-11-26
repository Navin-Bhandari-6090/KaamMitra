import 'package:app/web/common%20widget/GreenTextfield.dart';
import 'package:app/web/services/services_provider_service_select.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constant/Server_Database.dart';
import '../../models/NoticeUserModel.dart';
import '../../models/ServiceScreenServiceModel.dart';
import '../../models/ServiceScreenUserInfoModel.dart';
import '../../state management/getx/services/select_service_provider_info_screen_getx.dart';
import '../../constant/variable.dart';
import '../common method/Commmon_Method.dart';
import '../common method/date_time.dart';
import '../common widget/design/bolbs_background.dart';

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

    // Load notices for this provider + provider service.
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadNotices();
      });
    } catch (e) {
      // debugPrint("Schedule notices failed: $e");
    }
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

  /// Loads notices for this provider and this provider service.
  void _loadNotices() {
    try {
      providerCont.loadNotices(
        context: context,
        jwtToken: widget.Current_User_JwtToken,
        providerNumber: widget.Providernumber,
        providerServiceId: widget.ServiceId,
      );
    } catch (e) {
      // debugPrint("Load notices failed: $e");
    }
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
        fit: StackFit.expand,
        children: [
          // Fixed background gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_Theme.bgTop, _Theme.bgMid, _Theme.bgBottom],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Ambient blobs + glass bubbles (full width and height, behind content)
          const Positioned.fill(
            child: IgnorePointer(
              child: AmbientBackground(),
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
                                SizedBox(height: isMobile ? 18 : 24),

                                // NEW: notices for this provider + service
                                _animatedSection(
                                  animation: _actionsAnim,
                                  child: _buildNoticesCard(isMobile: isMobile),
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
          border:
          Border.all(color: _Theme.emerald.withOpacity(0.35), width: 1.5),
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
            trailing:
            widget.Rating > 0 ? _starRow(fullStars, hasHalfStar) : null,
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
                        fontStyle:
                        missing ? FontStyle.italic : FontStyle.normal,
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
          _noticeCard(
            icon: Icons.lock_outline_rounded,
            title: "Final once submitted",
            message:
            "Describe all the details of the service you want to book. "
                "The description cannot be changed later.",
          ),

          const SizedBox(height: 22),

          _stepHeader(number: "1", title: "Describe what you need"),
          const SizedBox(height: 12),

          GreenField(
            controller: UserBookingDescriptionTextCont,
            label: "Enter all the details that you need.",
            icon: Icons.info,
            keyboardType: TextInputType.multiline,
            obscure: false,
            multiline: true,
            height: 200, // chan
          ),

          const SizedBox(height: 24),

          _stepHeader(
              number: "2", title: "Attach file or video", optional: true),
          const SizedBox(height: 12),

          _noticeCard(
            icon: Icons.tips_and_updates_rounded,
            title: "Quick tip",
            message:
            "Use the CamScanner app to convert photos into a file (.pdf). "
                "You can skip file and video. They are optional.",
            subtle: true,
          ),

          const SizedBox(height: 14),

          LayoutBuilder(
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

              final videoPicker = _mediaPickerCard(
                icon: Icons.videocam_rounded,
                title: "Attach video",
                hint: "Short video that explains your needs.",
                onPick: () async => await PickVideo(),
                isSelected: () =>
                change_video_cont_getx.videoBytes.value != null &&
                    change_video_cont_getx.videoBytes.value!.isNotEmpty,
                selectedText: () {
                  final ext = change_video_cont_getx.videoExtension.value;
                  return ext.isEmpty
                      ? "Video selected"
                      : "Video selected (.$ext)";
                },
              );

              if (twoCol) {
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

          if (widget.Current_User_Role == "user") ...[
            const SizedBox(height: 24),
            _supportCard(),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Modern notice card (replaces the old yellow text blocks)
  // ------------------------------------------------------------
  Widget _noticeCard({
    required IconData icon,
    required String title,
    required String message,
    bool subtle = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _Theme.surfaceBar,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _Theme.emerald.withOpacity(subtle ? 0.14 : 0.30),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _Theme.emerald.withOpacity(subtle ? 0.05 : 0.12),
              _Theme.surfaceBar,
            ],
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_Theme.emerald, _Theme.mint],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _Theme.emerald.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: _Theme.mint, size: 17),
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
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: TextStyle(
                                color: _Theme.primaryText.withOpacity(0.72),
                                fontSize: 12.5,
                                height: 1.55,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Numbered step header
  // ------------------------------------------------------------
  Widget _stepHeader({
    required String number,
    required String title,
    bool optional = false,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_Theme.emerald, _Theme.mint]),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: _Theme.bgTop,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _Theme.primaryText,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: _Theme.surfaceBar,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _Theme.border),
            ),
            child: const Text(
              "Optional",
              style: TextStyle(
                color: _Theme.mutedTextAlt,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // Friendly support message (users only)
  // ------------------------------------------------------------
  Widget _supportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4330), Color(0xFF12261C), Color(0xFF101F18)],
        ),
        border: Border.all(color: _Theme.emerald.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: _Theme.emerald.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                  color: _Theme.emerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "A small request, a big support",
                  style: TextStyle(
                    color: _Theme.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "KaamMitra is free for users. Once your provider has completed "
                "the task or you have received the service, please update your "
                "task status to Yes (Completed).",
            style: TextStyle(
              color: _Theme.primaryText.withOpacity(0.75),
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _flowChip(Icons.receipt_long_rounded, "Booking Screen"),
              const Icon(Icons.arrow_forward_rounded,
                  color: _Theme.mutedTextAlt, size: 15),
              _flowChip(Icons.check_circle_rounded, "Completed: Yes"),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Your small action helps us grow and bring you more useful "
                "services. Thank you for being a part of KaamMitra. Together, we grow.",
            style: TextStyle(
              color: _Theme.primaryText.withOpacity(0.60),
              fontSize: 12,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _Theme.emerald.withOpacity(0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _Theme.emerald.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _Theme.mint, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Theme.mint,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
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
                color:
                selected ? _Theme.emerald.withOpacity(0.6) : _Theme.border,
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
        try {
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
        } catch (e) {
          // debugPrint("Open gallery failed: $e");
        }
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
        try {
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
          if (!mounted) return;

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
        } catch (e) {
          // debugPrint("Book now failed: $e");
        }
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
                    ? const LinearGradient(
                    colors: [_Theme.emerald, _Theme.mint])
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
  // PROVIDER NOTICES (below Book now / Provider gallery)
  // ============================================================

  Widget _buildNoticesCard({required bool isMobile}) {
    return _sectionCard(
      isMobile: isMobile,
      icon: Icons.campaign_rounded,
      title: "Provider notices",
      child: Obx(() {
        try {
          if (providerCont.isNoticeLoading.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: _Theme.emerald,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            );
          }

          if (providerCont.noticeLoadFailed.value) {
            return Row(
              children: [
                const Expanded(
                  child: Text(
                    "Couldn't load notices.",
                    style: TextStyle(color: _Theme.mutedText, fontSize: 12.5),
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadNotices,
                  icon: const Icon(Icons.refresh_rounded,
                      color: _Theme.mint, size: 16),
                  label: const Text(
                    "Retry",
                    style: TextStyle(color: _Theme.mint),
                  ),
                ),
              ],
            );
          }

          final List<NoticeUserModel> list = providerCont.notices.toList();
          if (list.isEmpty) {
            return _emptyState("No notices from this provider yet.");
          }

          return Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                if (i != 0) const SizedBox(height: 12),
                _noticeTile(list[i]),
              ],
            ],
          );
        } catch (e) {
          // debugPrint("Notices card failed: $e");
          return _emptyState(kDataNotAvailable);
        }
      }),
    );
  }

  Widget _noticeTile(NoticeUserModel n) {
    try {
      final String name =
      valueOrNA("${n.firstName ?? ""} ${n.lastName ?? ""}".trim());
      final String message = valueOrNA(n.message);
      final String service = valueOrNA(n.serviceName);

      final String formattedDate = formatDateTime(n.createdAt ?? "");
      final String date =
      formattedDate.isEmpty ? kDataNotAvailable : formattedDate;

      final String photoUrl = GetPhotoUrl(n.photo ?? "");

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Theme.surfaceBar,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Theme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _Theme.emerald.withOpacity(0.35)),
              ),
              child: ClipOval(
                child: Container(
                  color: _Theme.surface,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person_rounded,
                      color: _Theme.mint, size: 20)
                      : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person_rounded,
                        color: _Theme.mint, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: name == kDataNotAvailable
                          ? _Theme.mutedText
                          : _Theme.primaryText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      fontStyle: name == kDataNotAvailable
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        icon: Icons.design_services_rounded,
                        text: service,
                        color: service == kDataNotAvailable
                            ? _Theme.mutedText
                            : _Theme.mint,
                      ),
                      _pill(
                        icon: Icons.tag_rounded,
                        text: "Provider #${n.providerNumber ?? ""}",
                        color: _Theme.mutedTextAlt,
                      ),
                      _pill(
                        icon: Icons.schedule_rounded,
                        text: date,
                        color: date == kDataNotAvailable
                            ? _Theme.mutedText
                            : _Theme.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      color: message == kDataNotAvailable
                          ? _Theme.mutedText
                          : _Theme.primaryText.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.55,
                      fontStyle: message == kDataNotAvailable
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // debugPrint("Notice tile failed: $e");
      return const SizedBox.shrink();
    }
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