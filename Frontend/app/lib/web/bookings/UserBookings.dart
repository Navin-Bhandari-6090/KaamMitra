import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/BookingInfoModel.dart';
import '../../state management/getx/booking/UserBookingScreenGetX.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/design/bolbs_background.dart';
import '../common widget/toast.dart';
import '../footer/Footer.dart';
import '../header/Header.dart';
// TODO: point this import at the real location of the user booking-details screen.
import 'userbookinginfodetailsscreen.dart';

/// Shown whenever a database value is null, empty, or "null".
const String _noData = "No data available";

String _valueOrNA(Object? value) {
  if (value == null) return _noData;
  final String v = value.toString().trim();
  if (v.isEmpty || v.toLowerCase() == "null") return _noData;
  return v;
}

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

  static const Color border = Color(0xFF234232);

  // Reserved strictly for the "new notification" alert state.
  static const Color alert = Color(0xFFEF4444);
}

class UserBookingScreenUser extends StatefulWidget {
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final bool UserLogin;
  const UserBookingScreenUser({
    super.key,
    required this.Current_User_Email,
    required this.Current_User_JwtToken,
    required this.Current_User_Role,
    required this.UserLogin,
  });

  @override
  State<UserBookingScreenUser> createState() => _UserBookingScreenUserState();
}

class _UserBookingScreenUserState extends State<UserBookingScreenUser>
    with TickerProviderStateMixin {
  final Toast = Toastget();

  // GetX controller — owns all state and all API calls.
  final Userbookingscreengetx bookingCont = Get.put(Userbookingscreengetx());

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController SearchCont = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Animations (UI-only)
  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _searchAnim;
  late final Animation<double> _listAnim;
  late final Animation<double> _footerAnim;

  // Drives the gentle ring of the bell while there is a new notification.
  late final AnimationController _bellShakeController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _searchAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.70, curve: Curves.easeOutCubic),
    );
    _listAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.85, curve: Curves.easeOutCubic),
    );
    _footerAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );
    _bellShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    try {
      User_Jwt_Verify(
        Jwt_Token: widget.Current_User_JwtToken,
        context: context,
      );

      _entranceController.forward();
      _bellShakeController.repeat(reverse: true);

      _searchFocusNode.addListener(() {
        try {
          bookingCont.setSearchFocused(_searchFocusNode.hasFocus);
        } catch (e) {
          // print("Focus listener failed: $e");
        }
      });

      _loadEverything();
    } catch (e) {
      // print("initState failed: $e");
      try {
        _entranceController.forward();
        bookingCont.setLoading(false);
        bookingCont.setLoadError(true);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    try {
      _entranceController.dispose();
      _bellShakeController.dispose();
      SearchCont.dispose();
      _searchFocusNode.dispose();
    } catch (e) {
      // print("dispose failed: $e");
    }
    super.dispose();
  }

  // ============================================================
  // ACTIONS (the screen only forwards to the controller)
  // ============================================================

  Future<void> _loadEverything() {
    return bookingCont.loadEverything(
      email: widget.Current_User_Email,
      jwtToken: widget.Current_User_JwtToken,
      context: context,
    );
  }

  Future<void> _onRefreshTap() async {
    try {
      if (bookingCont.isLoading.value) return;
      await _loadEverything();
      if (!bookingCont.hasLoadError.value) {
        Toast.Toastmsg("Bookings refreshed.");
      }
    } catch (e) {
      // print("Unexpected error in _onRefreshTap: $e");
    }
  }

  Future<void> _handleBellTap() async {
    try {
      _scaffoldKey.currentState?.openEndDrawer();
      await bookingCont.markNotificationsSeen(
        email: widget.Current_User_Email,
        jwtToken: widget.Current_User_JwtToken,
        context: context,
      );
    } catch (e) {
      // print("Unexpected error in _handleBellTap: $e");
    }
  }

  Future<void> _onBookingCardTap({required num BookingId}) async {
    try {
      final filteredBookingList = bookingCont.bookingInfoList
          .where((element) => element.bookId == BookingId)
          .toList();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Userbookinginfodetailsscreen(
            Current_User_Email: widget.Current_User_Email,
            Current_User_JwtToken: widget.Current_User_JwtToken,
            Current_User_Role: widget.Current_User_Role,
            BookingInfoListInfo: filteredBookingList,
          ),
        ),
      );

      // Reload when coming back so any change shows up immediately.
      if (mounted) _loadEverything();
    } catch (e) {
      // print("Unexpected error in _onBookingCardTap: $e");
      Toastget().Toastmsg("Couldn't open booking details. Please try again.");
    }
  }

  // Small date formatter — no intl dependency required.
  String _formatDate(String? iso) {
    if (iso == null || iso.trim().isEmpty || iso.toLowerCase() == "null") {
      return _noData;
    }
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[dt.month - 1];
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return "${dt.day} $month, $hour12:$minute $period";
    } catch (e) {
      return _noData;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double widthval = MediaQuery.of(context).size.width;

    final bool isMobile = widthval < 700;
    final bool isTablet = widthval >= 700 && widthval < 1100;

    final double horizontalPadding =
    widthval < 420 ? 14 : (isMobile ? 18 : (isTablet ? 32 : 48));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _Theme.bgTop,
      appBar: _buildAppBar(context),
      endDrawer: _buildNotificationsDrawer(context),
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
                              User_JwtToken: widget.Current_User_JwtToken,
                            ),
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                const BoxConstraints(maxWidth: 1180),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    isMobile ? 20 : 32,
                                    horizontalPadding,
                                    24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      _animatedSection(
                                        animation: _heroAnim,
                                        child: _buildHero(isMobile),
                                      ),
                                      SizedBox(height: isMobile ? 18 : 24),
                                      _animatedSection(
                                        animation: _searchAnim,
                                        child: _buildSearchCard(isMobile),
                                      ),
                                      SizedBox(height: isMobile ? 18 : 24),
                                      _animatedSection(
                                        animation: _listAnim,
                                        child: _buildResultsSection(),
                                      ),
                                      SizedBox(height: isMobile ? 28 : 40),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        _animatedSection(
                          animation: _footerAnim,
                          child: Footer(
                            User_JwtToken: widget.Current_User_JwtToken,
                          ),
                        ),
                      ],
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

  BoxDecoration _cardDecoration({double radius = 22}) {
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
  // APP BAR — bordered back arrow, title, refresh + notification bell
  // ============================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _Theme.surfaceBar,
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
                      Navigator.of(context).pop();
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
          );
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient:
              const LinearGradient(colors: [_Theme.emerald, _Theme.mint]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _Theme.emerald.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.event_note_rounded,
                color: _Theme.bgTop, size: 19),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Bookings',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: _Theme.primaryText,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRefreshButton(),
                const SizedBox(width: 10),
                _buildNotificationBell(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return Obx(() {
      final bool loading = bookingCont.isLoading.value;

      return Tooltip(
        message: "Refresh bookings",
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: loading ? _Theme.emerald.withOpacity(0.6) : _Theme.border,
              width: 1.3,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: loading ? null : _onRefreshTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _Theme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: _Theme.emerald,
                  ),
                )
                    : const Icon(
                  Icons.refresh_rounded,
                  color: _Theme.mint,
                  size: 21,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // Normal: muted bordered box. New: red border, red bell, dot, gentle ring.
  Widget _buildNotificationBell() {
    return Obx(() {
      final bool hasNew = bookingCont.hasNewNotification.value;

      return Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: hasNew ? _Theme.alert.withOpacity(0.85) : _Theme.border,
            width: hasNew ? 1.6 : 1.3,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleBellTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasNew ? _Theme.alert.withOpacity(0.10) : _Theme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: hasNew
                  ? [
                BoxShadow(
                  color: _Theme.alert.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 0.5,
                ),
              ]
                  : [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _bellShakeController,
                  builder: (context, child) {
                    final double angle = hasNew
                        ? (_bellShakeController.value - 0.5) * 0.5
                        : 0.0;
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: Icon(
                    hasNew
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: hasNew ? _Theme.alert : _Theme.mutedTextAlt,
                    size: 21,
                  ),
                ),
                if (hasNew)
                  Positioned(
                    top: 4,
                    right: 6,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _Theme.alert,
                        border:
                        Border.all(color: _Theme.surfaceBar, width: 1.6),
                        boxShadow: [
                          BoxShadow(
                            color: _Theme.alert.withOpacity(0.6),
                            blurRadius: 6,
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
    });
  }

  // ============================================================
  // NOTIFICATIONS DRAWER
  // ============================================================

  Widget _buildNotificationsDrawer(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double drawerWidth = width < 420 ? width * 0.86 : 380;

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
                          colors: [_Theme.emerald, _Theme.mint]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: _Theme.bgTop, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Notifications",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: _Theme.mutedTextAlt, size: 20),
                    onPressed: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (e) {
                        // print("Close drawer failed: $e");
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: _Theme.border, height: 1),
            Expanded(
              child: Obx(() {
                final notes = bookingCont.notificationsInfoList;

                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              color: _Theme.mutedTextAlt.withOpacity(0.7),
                              size: 30),
                          const SizedBox(height: 10),
                          const Text(
                            "No notifications yet",
                            style: TextStyle(
                              color: _Theme.primaryText,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "You'll see booking updates here.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: _Theme.mutedText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final n = notes[index];
                    final String message = _valueOrNA(n.message);
                    final bool missing = message == _noData;
                    return Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _Theme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _Theme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _Theme.emerald.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.campaign_rounded,
                                color: _Theme.mint, size: 15),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message,
                                  style: TextStyle(
                                    color: missing
                                        ? _Theme.mutedText
                                        : _Theme.primaryText,
                                    fontSize: 12.8,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: missing
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(n.date),
                                  style: const TextStyle(
                                    color: _Theme.mutedTextAlt,
                                    fontSize: 10.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO — title, live stats, friendly support message
  // ============================================================

  Widget _buildHero(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _Theme.emerald.withOpacity(0.10),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _Theme.emerald.withOpacity(0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available_rounded,
                    color: _Theme.mint, size: 14),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    "My bookings",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _Theme.mint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Your bookings",
            style: TextStyle(
              color: _Theme.primaryText,
              fontSize: isMobile ? 24 : 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Every service you've booked, newest activity first. "
                "Search by booking ID or provider ID, or tap a card for full details.",
            style: TextStyle(
              color: _Theme.mutedText,
              fontSize: isMobile ? 13 : 14.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Obx(() {
            int total = 0;
            int providers = 0;
            try {
              total = bookingCont.bookingInfoList.length;
              providers = bookingCont.bookingInfoList
                  .map((b) => b.providerNumber)
                  .where((n) => n != null)
                  .toSet()
                  .length;
            } catch (e) {
              // print("Hero stats failed: $e");
            }
            return Row(
              children: [
                Expanded(
                  child: _heroStat(
                    icon: Icons.receipt_long_rounded,
                    value: "$total",
                    label: "Bookings",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _heroStat(
                    icon: Icons.storefront_rounded,
                    value: "$providers",
                    label: "Providers",
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 18),
          _supportCard(),
        ],
      ),
    );
  }

  Widget _heroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Theme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _Theme.emerald.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _Theme.mint, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: _Theme.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _Theme.mutedTextAlt,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Friendly support message (replaces the old long yellow paragraph).
  Widget _supportCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Theme.emerald.withOpacity(0.28)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _Theme.emerald.withOpacity(0.12),
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
                            child: const Icon(Icons.favorite_rounded,
                                color: _Theme.mint, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "A small request, a big support",
                              style: TextStyle(
                                color: _Theme.primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "KaamMitra is free for users. Once your provider has "
                            "completed the task or you have received the service, "
                            "please open the booking details and update your task "
                            "complete status to Yes (Completed).",
                        style: TextStyle(
                          color: _Theme.primaryText.withOpacity(0.74),
                          fontSize: 12.5,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _flowChip(Icons.touch_app_rounded, "Open a booking"),
                          const Icon(Icons.arrow_forward_rounded,
                              color: _Theme.mutedTextAlt, size: 15),
                          _flowChip(
                              Icons.check_circle_rounded, "Completed: Yes"),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Your small action helps us grow and bring you more "
                            "useful services. Thank you for being a part of "
                            "KaamMitra. Together, we grow.",
                        style: TextStyle(
                          color: _Theme.primaryText.withOpacity(0.58),
                          fontSize: 12,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
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

  // ============================================================
  // SEARCH — filter bookings by booking ID
  // ============================================================

  Widget _buildSearchCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.manage_search_rounded,
                  color: _Theme.mutedTextAlt, size: 17),
              SizedBox(width: 7),
              Text(
                "Find a booking by booking ID or provider ID",
                style: TextStyle(
                  color: _Theme.mutedTextAlt,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
                () => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _Theme.surfaceBar,
                border: Border.all(
                  color: bookingCont.isSearchFocused.value
                      ? _Theme.emerald.withOpacity(0.55)
                      : _Theme.border,
                  width: 1.4,
                ),
                boxShadow: bookingCont.isSearchFocused.value
                    ? [
                  BoxShadow(
                    color: _Theme.emerald.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
                    : const [],
              ),
              child: TextField(
                controller: SearchCont,
                focusNode: _searchFocusNode,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: _Theme.primaryText,
                  fontSize: 14,
                ),
                onChanged: (value) {
                  try {
                    bookingCont.changeSearchText(value);
                  } catch (e) {
                    // print("Search failed: $e");
                  }
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintText: "Search by booking ID or provider ID",
                  hintMaxLines: 1,
                  hintStyle: const TextStyle(
                    color: _Theme.mutedTextAlt,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _Theme.mint,
                    size: 20,
                  ),
                  suffixIcon: Obx(
                        () => bookingCont.searchText.value.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _Theme.mutedTextAlt,
                        size: 18,
                      ),
                      onPressed: () {
                        try {
                          SearchCont.clear();
                          bookingCont.changeSearchText("");
                        } catch (e) {
                          // print("Clear search failed: $e");
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTS — loading, error, empty, data (all reactive)
  // ============================================================

  Widget _buildResultsSection() {
    return Obx(() {
      if (bookingCont.isLoading.value) {
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
                "Loading bookings...",
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

      if (bookingCont.hasLoadError.value) {
        return _stateShell(
          child: _stateContent(
            icon: Icons.error_outline_rounded,
            title: "Couldn't load bookings",
            message: "Check your connection and try again.",
            action: ElevatedButton.icon(
              onPressed: () => _onRefreshTap(),
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
          ),
        );
      }

      final List<BookingInfoModel> bookings = bookingCont.displayedBookings;

      if (bookings.isEmpty) {
        final bool searching = bookingCont.searchText.value.trim().isNotEmpty;
        return _stateShell(
          child: _stateContent(
            icon:
            searching ? Icons.search_off_rounded : Icons.event_busy_rounded,
            title: searching ? "No matching booking" : "No bookings yet",
            message: searching
                ? "Check the booking ID or provider ID and try again."
                : "Bookings you make will show up here.",
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              "${bookings.length} booking${bookings.length == 1 ? '' : 's'}",
              style: const TextStyle(
                color: _Theme.mutedTextAlt,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, box) {
              final double maxW = box.maxWidth;
              final int columns = maxW >= 1000 ? 3 : (maxW >= 640 ? 2 : 1);
              const double gap = 16;
              final double cardW =
              ((maxW - gap * (columns - 1)) / columns).clamp(0.0, maxW);

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (int i = 0; i < bookings.length; i++)
                    SizedBox(
                      width: cardW,
                      child: _bookingCard(bookings[i], i),
                    ),
                ],
              );
            },
          ),
        ],
      );
    });
  }

  Widget _stateShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Theme.border),
      ),
      child: Center(child: child),
    );
  }

  Widget _stateContent({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _Theme.surfaceBar,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Theme.border),
          ),
          child: Icon(icon, color: _Theme.mint, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _Theme.primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _Theme.mutedText,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 18),
          action,
        ],
      ],
    );
  }

  // ============================================================
  // BOOKING CARD — bookId, providerNumber, userNumber, date, service name
  // ============================================================

  Widget _bookingCard(BookingInfoModel booking, int index) {
    final String serviceName = _valueOrNA(booking.serviceName);
    final String bookId = _valueOrNA(booking.bookId);
    final String providerNum = _valueOrNA(booking.providerNumber);
    final String userNum = _valueOrNA(booking.userNumber);
    final String dateLabel = _formatDate(booking.createdAt);

    final bool canOpen = booking.bookId != null;

    return Obx(() {
      final bool hovered = bookingCont.hoveredCardIndex.value == index;
      final bool pressed = bookingCont.pressedCardIndex.value == index;

      return MouseRegion(
        onEnter: (_) => bookingCont.setHoveredCard(index),
        onExit: (_) => bookingCont.clearHoveredCard(),
        cursor: canOpen ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: canOpen ? (_) => bookingCont.setPressedCard(index) : null,
          onTapCancel: () => bookingCont.clearPressedCard(),
          onTapUp: (_) => bookingCont.clearPressedCard(),
          onTap: !canOpen
              ? null
              : () => _onBookingCardTap(BookingId: booking.bookId!),
          child: AnimatedScale(
            scale: pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _Theme.surface,
                borderRadius: BorderRadius.circular(20),
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
                    blurRadius: hovered ? 24 : 12,
                    offset: Offset(0, hovered ? 10 : 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- header ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_Theme.emerald, _Theme.mint],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.event_available_rounded,
                          color: _Theme.bgTop,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: serviceName == _noData
                                    ? _Theme.mutedText
                                    : _Theme.primaryText,
                                fontSize: 15.5,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                fontStyle: serviceName == _noData
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _idChip(bookId),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ---------- metrics ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _Theme.surfaceBar,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _Theme.border),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          icon: Icons.storefront_rounded,
                          label: "Provider",
                          value: providerNum == _noData
                              ? providerNum
                              : "#$providerNum",
                        ),
                        const SizedBox(height: 9),
                        _infoRow(
                          icon: Icons.person_rounded,
                          label: "User",
                          value: userNum == _noData ? userNum : "#$userNum",
                        ),
                        const SizedBox(height: 9),
                        _infoRow(
                          icon: Icons.schedule_rounded,
                          label: "Booked on",
                          value: dateLabel,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- call to action ----------
                  Row(
                    children: [
                      Expanded(
                        child: canOpen
                            ? const SizedBox.shrink()
                            : const Text(
                          "Details unavailable",
                          style: TextStyle(
                            color: _Theme.mutedText,
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      if (canOpen)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View details",
                              style: TextStyle(
                                color: _Theme.mint,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                color: _Theme.mint, size: 14),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _idChip(String bookId) {
    final bool missing = bookId == _noData;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _Theme.emerald.withOpacity(0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _Theme.emerald.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number_rounded,
              color: _Theme.mint, size: 12),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              missing ? bookId : "Booking #$bookId",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: missing ? _Theme.mutedText : _Theme.mint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontStyle: missing ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final bool missing = value == _noData;
    return Row(
      children: [
        Icon(icon, size: 14, color: _Theme.mint),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _Theme.mutedTextAlt,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: missing ? _Theme.mutedText : _Theme.primaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontStyle: missing ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}