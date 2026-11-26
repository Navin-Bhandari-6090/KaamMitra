import 'dart:math' as math;

import 'package:app/web/footer/Footer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constant/Style.dart';
import '../../../constant/variable.dart';
import '../../../models/UserInfo.dart';

import '../../../state management/getx/profile/provider/provider_profile_getx.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/design/bolbs_background.dart';
import '../../common widget/getx_cont_pick_single_photo_int.dart';
import '../../common widget/toast.dart';
import '../../header/Header.dart';
import '../provider_user/Update_Location.dart';
import '../provider_user/Update_Password.dart';
import '../provider_user/select_shared_media.dart';
import '../provider_user/upd_contact_info.dart';
import '../provider_user/update_address.dart';
import '../provider_user/update_user_name.dart';
import 'package:app/web/profile/provider/Provider_add_Sevice_Resources.dart';
import 'package:app/web/profile/provider/update_pro_reg_ser_descp.dart';
import 'package:app/web/profile/provider/update_status.dart';
import 'ProviderAddService.dart';
import 'Provider_Service_Select.dart';
import 'Provider_Update_Service_File.dart';
import 'Select_Ser_Res_Update.dart';
import 'add_update_fonepay_qr.dart';
import 'delete_serv_res.dart';
import 'notice_action_select.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS (dark green) — matches Header.dart / ProviderProfile.dart
// ---------------------------------------------------------------------------
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
  static const Color danger = Color(0xFFF87171);

  static const Color border = Color(0xFF234232);
}

class ProviderProfile extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final bool UserLogin;
  const ProviderProfile({
    super.key,
    req,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.UserLogin,
  });
  @override
  State<ProviderProfile> createState() => _ProviderProfileState();
}

class _ProviderProfileState extends State<ProviderProfile>
    with SingleTickerProviderStateMixin {


  // GetX controller — owns all state and all API calls (provider only).
  final ProviderProfileGetx profileCont = Get.put(ProviderProfileGetx());

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Entrance animation (UI only)
  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _infoAnim;
  late final Animation<double> _noticeAnim;
  late final Animation<double> _actionsAnim;
  late final Animation<double> _footerAnim;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _heroAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.50, curve: Curves.easeOutCubic),
    );
    _infoAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );
    _noticeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.78, curve: Curves.easeOutCubic),
    );
    _actionsAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.40, 0.90, curve: Curves.easeOutCubic),
    );
    _footerAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();

    try {
      profileCont.verifySession(
        jwtToken: widget.User_JwtToken,
        context: context,
      );
      _loadProfile();
    } catch (e) {
      // print("initState failed: $e");
    }
  }

  @override
  void dispose() {
    try {
      _entranceController.dispose();
    } catch (e) {
      // print("dispose failed: $e");
    }
    super.dispose();
  }

  // ============================================================
  // ACTIONS (the screen only forwards to the controller)
  // ============================================================

  Future<void> _loadProfile() {
    return profileCont.loadUserInfo(
      email: widget.User_Email,
      jwtToken: widget.User_JwtToken,
    );
  }

  Future<void> _refreshProfile() {
    return profileCont.loadUserInfo(
      email: widget.User_Email,
      jwtToken: widget.User_JwtToken,
      showLoader: false,
    );
  }

  // Pick -> confirm -> upload (controller) -> profile reloads reactively.
  Future<void> _onChangePhotoPressed() async {
    try {
      if (profileCont.isUploadingPhoto.value) return;

      await PickPhoto();

      final List<int> bytes =
          change_photo_cont_getx.imageBytes.value ?? <int>[];

      if (bytes.isEmpty) {
        Toast.Toastmsg("Fail to change photo.Try again.");
        return;
      }
      if (!mounted) return;

      final bool confirmed = await _confirm(
        title: "Update profile photo?",
        message: "Your new photo will replace the current profile photo.",
        confirmLabel: "Update",
        icon: Icons.photo_camera_rounded,
      );
      if (!confirmed || !mounted) return;

      await profileCont.changePhoto(
        email: widget.User_Email,
        jwtToken: widget.User_JwtToken,
        photoExtension: change_photo_cont_getx.imageExtension.value,
        photoBytes: bytes,
      );
    } catch (e) {
      // print("_onChangePhotoPressed failed: $e");
      Toast.Toastmsg("Fail to change photo.Try again.");
    }
  }

  Future<void> _onLogoutPressed() async {
    try {
      final bool confirmed = await _confirm(
        title: "Log out?",
        message: "You will be signed out and need to log in again.",
        confirmLabel: "Logout",
        icon: Icons.logout_rounded,
        danger: true,
      );
      if (!confirmed || !mounted) return;
      await profileCont.logout(context: context);
    } catch (e) {
      // print("_onLogoutPressed failed: $e");
    }
  }

  void _open(Widget Function(BuildContext) builder) {
    try {
      Navigator.push(context, MaterialPageRoute(builder: builder));
    } catch (e) {
      // print("Navigation failed: $e");
      Toast.Toastmsg("Couldn't open this page. Please try again.");
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    bool danger = false,
  }) async {
    try {
      final Color accent = danger ? _Theme.danger : _Theme.emerald;
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
                Icon(icon, color: danger ? _Theme.danger : _Theme.mint),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _Theme.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
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
                  backgroundColor: accent,
                  foregroundColor: danger ? Colors.white : Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );
      return result == true;
    } catch (e) {
      // print("_confirm failed: $e");
      return false;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;
    final double hPad =
    width < 420 ? 14 : (isMobile ? 20 : (width < 1100 ? 32 : 48));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _Theme.bgTop,
      appBar: _buildAppBar(context),
      endDrawer: _buildToolsDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_Theme.bgTop, _Theme.bgMid, _Theme.bgBottom],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Ambient blobs + glass bubbles, full width and height, behind content.
          const IgnorePointer(child: AmbientBackground()),

          SafeArea(
            child: RefreshIndicator(
              color: _Theme.emerald,
              backgroundColor: _Theme.surface,
              onRefresh: _refreshProfile,
              child: LayoutBuilder(
                builder: (context, outer) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: outer.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Header(
                                UserLogin: widget.UserLogin,
                                User_JwtToken: widget.User_JwtToken,
                              ),
                              Center(
                                child: ConstrainedBox(
                                  constraints:
                                  const BoxConstraints(maxWidth: 1100),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      hPad,
                                      isMobile ? 20 : 32,
                                      hPad,
                                      28,
                                    ),
                                    child: Obx(() => _buildBody(isMobile)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _animatedSection(
                            animation: _footerAnim,
                            child: Footer(User_JwtToken: widget.User_JwtToken),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reactive body: loading / error / no data / profile.
  Widget _buildBody(bool isMobile) {
    try {
      if (profileCont.isLoading.value) {
        return _stateShell(
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  color: _Theme.emerald,
                  strokeWidth: 2.6,
                ),
              ),
              SizedBox(height: 14),
              Text(
                "Loading profile...",
                style: TextStyle(
                  color: _Theme.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      final UserInfo? user = profileCont.userInfo.value;

      if (profileCont.hasLoadError.value || user == null) {
        return _stateShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _Theme.surfaceBar,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _Theme.border),
                ),
                child: const Icon(Icons.person_off_rounded,
                    color: _Theme.mint, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                "No user data available",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _Theme.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Check your connection and try again.",
                textAlign: TextAlign.center,
                style: TextStyle(color: _Theme.mutedText, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Try again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Theme.emerald,
                  foregroundColor: _Theme.bgTop,
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _animatedSection(
            animation: _heroAnim,
            child: _buildHero(user, isMobile),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          _animatedSection(
            animation: _infoAnim,
            child: _buildInfoCard(user, isMobile),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          _animatedSection(
            animation: _noticeAnim,
            child: _buildRecoveryNotice(),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          _animatedSection(
            animation: _actionsAnim,
            child: _buildActions(user, isMobile),
          ),
          SizedBox(height: isMobile ? 18 : 24),
          _animatedSection(
            animation: _footerAnim,
            child: _buildToolsCard(isMobile),
          ),
        ],
      );
    } catch (e) {
      // print("_buildBody failed: $e");
      return _stateShell(
        child: const Text(
          "No user data available",
          style: TextStyle(color: _Theme.mutedText),
        ),
      );
    }
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

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF193A29), Color(0xFF12261C), Color(0xFF101F18)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _Theme.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  // ============================================================
  // APP BAR — bordered back arrow (when possible), title, logout
  // ============================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _Theme.surfaceBar,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: Navigator.of(context).canPop()
          ? Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: Tooltip(
            message: "Back",
            child: Material(
              color: _Theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _Theme.emerald.withOpacity(0.55),
                  width: 1.4,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  try {
                    Navigator.of(context).maybePop();
                  } catch (e) {
                    // print("Back failed: $e");
                  }
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_rounded,
                      color: _Theme.primaryText, size: 20),
                ),
              ),
            ),
          ),
        ),
      )
          : null,
      title: const Text(
        "My Profile",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _Theme.primaryText,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _appBarButton(
                  tooltip: "Provider tools",
                  icon: Icons.apps_rounded,
                  color: _Theme.mint,
                  onTap: _openToolsDrawer,
                ),
                const SizedBox(width: 10),
                _appBarButton(
                  tooltip: "Logout",
                  icon: Icons.logout_rounded,
                  color: _Theme.danger,
                  onTap: _onLogoutPressed,
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _Theme.border),
      ),
    );
  }

  void _openToolsDrawer() {
    try {
      _scaffoldKey.currentState?.openEndDrawer();
    } catch (e) {
      // print("Open drawer failed: $e");
    }
  }

  Widget _appBarButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.55), width: 1.3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO — avatar with edit badge, name, ID and status
  // ============================================================

  Widget _buildHero(UserInfo user, bool isMobile) {
    final double shortest = MediaQuery.of(context).size.shortestSide;
    final double avatar = (shortest * 0.30).clamp(96.0, 150.0).toDouble();

    final String fullName = [
      _cleanOrEmpty(user.firstName),
      _cleanOrEmpty(user.lastName),
    ].where((e) => e.isNotEmpty).join(' ');
    final String name = fullName.isEmpty ? kNoDataAvailable : fullName;
    final bool nameMissing = fullName.isEmpty;
    final String idText = valueOrNoData(user.userNumber);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 28,
        vertical: isMobile ? 24 : 32,
      ),
      decoration: _cardDecoration(radius: 28),
      child: Column(
        children: [
          _buildAvatar(user, avatar),
          const SizedBox(height: 18),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: bold,
              color: nameMissing ? _Theme.mutedText : _Theme.primaryText,
              fontSize: isMobile ? 24 : 30,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontStyle: nameMissing ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                icon: Icons.badge_rounded,
                text: idText == kNoDataAvailable ? idText : "ID  #$idText",
                color: _Theme.mint,
              ),
              _pill(
                icon: Icons.engineering_rounded,
                text: "Provider",
                color: _Theme.mint,
              ),
              _statusPill(user.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserInfo user, double size) {
    final String photoUrl = profileCont.getPhotoUrl(user.photo);

    Widget fallback() => Image.asset(
      'assets/images/profile/u_p_p_1.jpg',
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => const Center(
        child: Icon(Icons.person_rounded, color: _Theme.mint, size: 44),
      ),
    );

    return SizedBox(
      width: size + 14,
      height: size + 14,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // soft glow ring
          Container(
            width: size + 14,
            height: size + 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _Theme.emerald.withOpacity(0.22),
                  _Theme.emerald.withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_Theme.emerald, _Theme.mint],
              ),
              boxShadow: [
                BoxShadow(
                  color: _Theme.emerald.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: _Theme.surface,
                child: photoUrl.isEmpty
                    ? fallback()
                    : Image.network(
                  photoUrl,
                  key: ValueKey(photoUrl),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _Theme.emerald,
                        strokeWidth: 2.4,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // print("Profile image loading failed: $error");
                    return fallback();
                  },
                ),
              ),
            ),
          ),
          // uploading overlay
          Obx(() {
            if (!profileCont.isUploadingPhoto.value) {
              return const SizedBox.shrink();
            }
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.55),
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: _Theme.mint,
                    strokeWidth: 2.6,
                  ),
                ),
              ),
            );
          }),
          // edit badge
          Positioned(
            bottom: 2,
            right: 2,
            child: Tooltip(
              message: "Change photo",
              child: Material(
                color: _Theme.emerald,
                shape: const CircleBorder(
                  side: BorderSide(color: _Theme.bgTop, width: 3),
                ),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _onChangePhotoPressed,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.camera_alt_rounded,
                        size: 18, color: _Theme.bgTop),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanOrEmpty(Object? v) {
    final String s = valueOrNoData(v);
    return s == kNoDataAvailable ? '' : s;
  }

  Widget _statusPill(bool? status) {
    if (status == null) {
      return _pill(
        icon: Icons.info_outline_rounded,
        text: kNoDataAvailable,
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
      text: "Free",
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
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
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
  // INFO CARD — contact + location tiles
  // ============================================================

  Widget _buildInfoCard(UserInfo user, bool isMobile) {
    final String coords = (user.latitude == null || user.longitude == null)
        ? kNoDataAvailable
        : "${user.latitude}, ${user.longitude}";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.contact_page_rounded,
            title: "Account details",
            subtitle: "Your information as saved in KaamMitra.",
          ),
          const SizedBox(height: 16),
          _tileGrid([
            _InfoTile(Icons.alternate_email_rounded, "Email", user.email),
            _InfoTile(Icons.phone_rounded, "Phone number", user.phoneNumber),
            _InfoTile(Icons.chat_rounded, "WhatsApp number",
                user.whatsappPhoneNumber),
            _InfoTile(Icons.home_rounded, "Address", user.address),
            _InfoTile(Icons.north_rounded, "Latitude", user.latitude),
            _InfoTile(Icons.east_rounded, "Longitude", user.longitude),
          ]),
          if (coords == kNoDataAvailable) ...[
            const SizedBox(height: 12),
            _hint("Location is not set yet. Use Update latitude and longitude below."),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _Theme.mint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Theme.mint.withOpacity(0.35)),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _Theme.primaryText,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _Theme.mutedTextAlt, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tileGrid(List<_InfoTile> tiles) {
    return LayoutBuilder(
      builder: (context, box) {
        final int cols = box.maxWidth >= 560 ? 2 : 1;
        const double gap = 12;
        final double w =
        math.max(0.0, (box.maxWidth - gap * (cols - 1)) / cols);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles) SizedBox(width: w, child: _infoTile(t)),
          ],
        );
      },
    );
  }

  Widget _infoTile(_InfoTile t) {
    final String value = valueOrNoData(t.value);
    final bool missing = value == kNoDataAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Theme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _Theme.emerald.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(t.icon, color: _Theme.mint, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.label,
                  style: const TextStyle(
                    color: _Theme.mutedTextAlt,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  softWrap: true,
                  style: TextStyle(
                    color: missing ? _Theme.mutedText : _Theme.primaryText,
                    fontSize: 14,
                    height: 1.35,
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

  Widget _hint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Theme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _Theme.mint, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _Theme.mutedText,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECOVERY NOTICE (replaces the old big bold text block)
  // ============================================================

  Widget _buildRecoveryNotice() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _Theme.emerald.withOpacity(0.30)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Theme.emerald.withOpacity(0.13), _Theme.surfaceBar],
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _Theme.emerald.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.screenshot_rounded,
                                color: _Theme.mint, size: 17),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Save your recovery details",
                              style: TextStyle(
                                color: _Theme.primaryText,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Take a screenshot of your email, phone number and whatsapp number. "
                            "They are needed to recover your password from the "
                            "Login screen. You cannot reset your password without them.",
                        style: TextStyle(
                          color: _Theme.primaryText.withOpacity(0.76),
                          fontSize: 12.8,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(
                              icon: Icons.badge_rounded,
                              text: "ID",
                              color: _Theme.mint),
                          _pill(
                              icon: Icons.phone_rounded,
                              text: "Phone number",
                              color: _Theme.mint),
                          _pill(
                              icon: Icons.alternate_email_rounded,
                              text: "Email",
                              color: _Theme.mint),
                        ],
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

  // ============================================================
  // ACTIONS — responsive grid of tiles (account-level actions only)
  // ============================================================

  // Account-level actions that stay in the profile section
  // (Shared media ... Update status).
  Widget _buildActions(UserInfo user, bool isMobile) {
    final List<_ActionItem> actions = [
      _ActionItem(
        icon: Icons.perm_media_rounded,
        label: "Shared media.",
        onTap: () => _open(
              (context) =>
                  SelectSharedMedia(
            Current_User_Jwt_Token: widget.User_JwtToken,
          ),

        ),
      ),
      _ActionItem(
        icon: Icons.lock_reset_rounded,
        label: "Update password",
        onTap: () {
          final String? phone = user.phoneNumber;
          final String? whatsapp = user.whatsappPhoneNumber;
          if (phone == null || whatsapp == null) {
            Toast.Toastmsg("No data available. Phone details are missing.");
            return;
          }
          _open(
                (context) => UpdatePasswordScreen(
              User_Email: widget.User_Email,
              User_JwtToken: widget.User_JwtToken,
              User_Role: widget.User_Role,
              PhoneNumber: phone,
              WhatsappNumber: whatsapp,
            ),
          );
        },
      ),
      _ActionItem(
        icon: Icons.my_location_rounded,
        label: "Update latitude and longitude",
        onTap: () => _open(
              (context) => UpdateLocation(
            User_Email: widget.User_Email,
            User_JwtToken: widget.User_JwtToken,
            User_Role: widget.User_Role,
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.badge_rounded,
        label: "Update User name",
        onTap: () => _open(
              (context) => UpdateUserName(
            User_Email: widget.User_Email,
            User_JwtToken: widget.User_JwtToken,
            User_Role: widget.User_Role,
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.home_work_rounded,
        label: "Update address.",
        onTap: () => _open(
              (context) => UpdateAddress(
            User_Email: widget.User_Email,
            User_JwtToken: widget.User_JwtToken,
            User_Role: widget.User_Role,
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.contact_phone_rounded,
        label: "Update Contact Info.",
        onTap: () => _open(
              (context) => UpdContactInfo(
            Current_User_Jwt_Token: widget.User_JwtToken,
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.toggle_on_rounded,
        label: "Update status.",
        onTap: () => _open(
              (context) => UpdateStatus(User_JwtToken: widget.User_JwtToken),
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.tune_rounded,
            title: "Manage account",
            subtitle: "Update your details and settings.",
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, box) {
              final double maxW = box.maxWidth;
              final int cols = maxW >= 900 ? 3 : (maxW >= 560 ? 2 : 1);
              const double gap = 12;
              final double w =
              math.max(0.0, (maxW - gap * (cols - 1)) / cols);
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (int i = 0; i < actions.length; i++)
                    SizedBox(width: w, child: _actionTile(actions[i], i)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROVIDER TOOLS — launcher card + end drawer
  // (My gallery ... Delete your service and resources)
  // ============================================================

  List<_ToolSection> _toolSections() {
    return [
      _ToolSection(
        title: "Services",
        icon: Icons.design_services_rounded,
        items: [
          _ActionItem(
            icon: Icons.photo_library_rounded,
            label: "My gallery",
            onTap: () => _open(
                  (context) => ProviderServiceSelect(
                User_Email: widget.User_Email,
                User_JwtToken: widget.User_JwtToken,
                User_Role: widget.User_Role,
              ),
            ),
          ),
          _ActionItem(
            icon: Icons.add_business_rounded,
            label: "Add service",
            onTap: () => _open(
                  (context) => ProviderAddService(
                User_Email: widget.User_Email,
                User_JwtToken: widget.User_JwtToken,
                User_Role: widget.User_Role,
              ),
            ),
          ),
          _ActionItem(
            icon: Icons.edit_note_rounded,
            label: "Update service description",
            onTap: () => _open(
                  (context) =>
                  UpdateProRegSerDescp(User_JwtToken: widget.User_JwtToken),
            ),
          ),
          _ActionItem(
            icon: Icons.upload_file_rounded,
            label: "Update service file",
            onTap: () => _open(
                  (context) => ProviderUpdateServiceFile(
                User_Email: widget.User_Email,
                User_JwtToken: widget.User_JwtToken,
                User_Role: widget.User_Role,
              ),
            ),
          ),
        ],
      ),
      _ToolSection(
        title: "Resources",
        icon: Icons.inventory_2_rounded,
        items: [
          _ActionItem(
            icon: Icons.inventory_2_rounded,
            label: "Add service resources",
            onTap: () => _open(
                  (context) => ProviderAddSeviceResources(
                User_Email: widget.User_Email,
                User_JwtToken: widget.User_JwtToken,
                User_Role: widget.User_Role,
              ),
            ),
          ),
          _ActionItem(
            icon: Icons.build_circle_rounded,
            label: "Update service resources",
            onTap: () => _open(
                  (context) => SelectSerResUpdate(
                User_Email: widget.User_Email,
                User_JwtToken: widget.User_JwtToken,
                User_Role: widget.User_Role,
              ),
            ),
          ),
        ],
      ),

      _ToolSection
        (
        title: "Payments & cleanup",
        icon: Icons.qr_code_2_rounded,
        items: [
          _ActionItem(
            icon: Icons.qr_code_2_rounded,
            label: "Add/Update fonepay QR photo(Advance payment QR).",
            onTap: () => _open(
                  (context) => AddUpdateFonepayQr(
                User_Email: widget.User_Email,
                User_JwtToken: widget.User_JwtToken,
                User_Role: widget.User_Role,
              ),
            ),
          ),
          _ActionItem(
            icon: Icons.delete_sweep_rounded,
            label: "Delete your service and resources.",
            danger: true,
            onTap: () => _open(
                  (context) => DeleteServRes(
                Current_User_JwtToken: widget.User_JwtToken,
              ),
            ),
          ),
        ],
      ),

      _ToolSection
        (
        title: "Notices",
        icon: Icons.qr_code_2_rounded,
        items: [


          _ActionItem(
            icon: Icons.qr_code_2_rounded,
            label: "Manage notices",
            onTap: () => _open(
                  (context) => NoticeActionSelect(

                Current_User_JwtToken: widget.User_JwtToken,

              ),
            ),
          ),

        ],
      ),




    ];
  }

  Widget _buildToolsCard(bool isMobile) {
    final int count =
    _toolSections().fold<int>(0, (sum, s) => sum + s.items.length);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: _cardDecoration(radius: 24),
      child: LayoutBuilder(
        builder: (context, box) {
          final bool stack = box.maxWidth < 520;

          final Widget info = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_Theme.emerald, _Theme.mint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _Theme.emerald.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.handyman_rounded,
                    color: _Theme.bgTop, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Provider tools",
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Gallery, services, resources and payment QR "
                          "($count tools).",
                      style: const TextStyle(
                        color: _Theme.mutedTextAlt,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget button = Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _openToolsDrawer,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [_Theme.emerald, _Theme.mint],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _Theme.emerald.withOpacity(0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_open_rounded,
                          color: _Theme.bgTop, size: 19),
                      SizedBox(width: 8),
                      Text(
                        "Open tools",
                        style: TextStyle(
                          color: _Theme.bgTop,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, const SizedBox(height: 16), button],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolsDrawer() {
    final double width = MediaQuery.of(context).size.width;
    final double drawerWidth = width < 420 ? width * 0.88 : 390;
    final List<_ToolSection> sections = _toolSections();

    // Flat index so each tile keeps its own hover/press state.
    int flat = 100;

    return Drawer(
      backgroundColor: _Theme.surfaceBar,
      width: drawerWidth,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_Theme.emerald, _Theme.mint],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.handyman_rounded,
                        color: _Theme.bgTop, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Provider tools",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: "Close",
                    child: Material(
                      color: _Theme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                        side: BorderSide(
                          color: _Theme.emerald.withOpacity(0.55),
                          width: 1.3,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: () {
                          try {
                            _scaffoldKey.currentState?.closeEndDrawer();
                          } catch (e) {
                            // print("Close drawer failed: $e");
                          }
                        },
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.close_rounded,
                              color: _Theme.primaryText, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: _Theme.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                children: [
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                      child: Row(
                        children: [
                          Icon(section.icon, color: _Theme.mint, size: 15),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              section.title.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _Theme.mint,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final item in section.items) ...[
                      _drawerTile(item, flat++),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(_ActionItem item, int index) {
    final Color tone = item.danger ? _Theme.danger : _Theme.mint;

    return Obx(() {
      final bool hovered = profileCont.hoveredActionIndex.value == index;
      final bool pressed = profileCont.pressedActionIndex.value == index;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => profileCont.setHoveredAction(index),
        onExit: (_) => profileCont.clearHoveredAction(),
        child: AnimatedScale(
          scale: pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                try {
                  _scaffoldKey.currentState?.closeEndDrawer();
                } catch (e) {
                  // print("Close drawer failed: $e");
                }
                item.onTap();
              },
              onTapDown: (_) => profileCont.setPressedAction(index),
              onTapCancel: () => profileCont.clearPressedAction(),
              onTapUp: (_) => profileCont.clearPressedAction(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _Theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hovered
                        ? tone.withOpacity(0.55)
                        : (item.danger
                        ? _Theme.danger.withOpacity(0.30)
                        : _Theme.border),
                    width: hovered ? 1.3 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: item.danger
                            ? null
                            : const LinearGradient(
                          colors: [_Theme.emerald, _Theme.mint],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        color: item.danger
                            ? _Theme.danger.withOpacity(0.14)
                            : null,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.danger ? _Theme.danger : _Theme.bgTop,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.danger
                              ? _Theme.danger
                              : _Theme.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: hovered ? tone : _Theme.mutedTextAlt,
                      size: 13,
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

  Widget _actionTile(_ActionItem item, int index) {
    return Obx(() {
      final bool hovered = profileCont.hoveredActionIndex.value == index;
      final bool pressed = profileCont.pressedActionIndex.value == index;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => profileCont.setHoveredAction(index),
        onExit: (_) => profileCont.clearHoveredAction(),
        child: AnimatedScale(
          scale: pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: item.onTap,
              onTapDown: (_) => profileCont.setPressedAction(index),
              onTapCancel: () => profileCont.clearPressedAction(),
              onTapUp: (_) => profileCont.clearPressedAction(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _Theme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: hovered
                        ? _Theme.emerald.withOpacity(0.55)
                        : _Theme.border,
                    width: hovered ? 1.3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hovered
                          ? _Theme.emerald.withOpacity(0.16)
                          : Colors.black.withOpacity(0.12),
                      blurRadius: hovered ? 22 : 10,
                      offset: Offset(0, hovered ? 8 : 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_Theme.emerald, _Theme.mint],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: _Theme.bgTop, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Theme.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 180),
                      offset: Offset(hovered ? 0.25 : 0, 0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: hovered ? _Theme.mint : _Theme.mutedTextAlt,
                        size: 14,
                      ),
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

  Widget _stateShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Theme.border),
      ),
      child: Center(child: child),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
}

class _ToolSection {
  final String title;
  final IconData icon;
  final List<_ActionItem> items;
  _ToolSection({required this.title, required this.icon, required this.items});
}

class _InfoTile {
  final IconData icon;
  final String label;
  final Object? value;
  _InfoTile(this.icon, this.label, this.value);
}