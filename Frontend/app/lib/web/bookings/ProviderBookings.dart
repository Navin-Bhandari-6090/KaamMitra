import 'dart:convert';
import 'package:app/web/common%20widget/toast.dart';
import 'package:app/web/footer/Footer.dart';
import 'package:app/web/header/Header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../constant/Server_Database.dart';
import '../../models/BookingInfoModel.dart';
import '../../models/NewNotificationsModel.dart';
import '../../models/NotificationsInfoModel.dart';

import '../../state management/getx/booking/ProviderBookingScreenGetX.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
// TODO: point these two imports at the real locations of the details screens.
import 'userbookinginfodetailsscreen.dart';
import 'providerbookinginfodetailsscreen.dart';

// Adjust the provider_bookings_getx.dart import path above to match wherever
// you place that file relative to this one.

/// ---------------------------------------------------------------------------
/// THEME TOKENS (dark green, modern) — matches Header.dart / ServicesScreen
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

  static const Color border = Color(0xFF234232);

  // Reserved strictly for the "new notification" alert state — kept far
  // from the green palette so it reads unmistakably as "something needs
  // your attention", never confusable with a normal/accent element.
  static const Color alert = Color(0xFFEF4444);
}

class ProviderBookingsScreen extends StatefulWidget
{
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final bool UserLogin;
  const ProviderBookingsScreen({super.key, required this.Current_User_Email, required this.Current_User_JwtToken, required this.Current_User_Role, required this.UserLogin});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with TickerProviderStateMixin {

  final Toast=Toastget();

  // ============================================================
  // GetX controller — all interactive UI state lives here, no setState.
  // ============================================================
  final ProviderBookingsGetx bookingCont = Get.put(ProviderBookingsGetx());

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController SearchCont = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ============================================================
  // ANIMATIONS (UI-only)
  // ============================================================

  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _searchAnim;
  late final Animation<double> _listAnim;
  late final Animation<double> _footerAnim;

  // Continuous subtle rotation driver for the bell — only visually applied
  // (via Transform.rotate) while hasNewNotification is true, so the bell
  // sits perfectly still in the normal state and gently "rings" when there
  // is something new to see.
  late final AnimationController _bellShakeController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    try {
      Provider_Jwt_Verify(Jwt_Token: widget.Current_User_JwtToken);

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
      _entranceController.forward();

      _bellShakeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )..repeat(reverse: true);

      _searchFocusNode.addListener(() {
        try {
          bookingCont.setSearchFocused(_searchFocusNode.hasFocus);
        } catch (e) {
          // Defensive fallback only — a focus-listener failure should
          // never take the whole screen down.
        }
      });

      _loadEverything();
    } catch (e) {
      // Defensive fallback only — if anything in setup throws, at least
      // stop the loading spinner and show the empty/error state instead
      // of leaving the screen stuck or crashing.
      try {
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
      // Defensive fallback only.
    }
    super.dispose();
  }


  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    try {
      int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
      if (Result == 1) {
        return;
      } else {
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return;
      }
    } catch (e) {
      // Defensive fallback only — an unexpected failure here shouldn't
      // crash the screen; surface a toast instead so the person knows
      // something went wrong.
      print("Unexpected error in Provider_Jwt_Verify: $e");
      Toastget().Toastmsg("Something went wrong. Please try again.");
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }


  List<BookingInfoModel> BookingInfoList = [];

  Future<int> GetBookingInfo({required String Email}) async {
    try {
      final Map<String, dynamic> userData = {"Email": Email};
      const String url = Backend_Server_Url + "api/Booking/sendbookinginfopro";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        BookingInfoList.clear();
        BookingInfoList.addAll(
          responseData
              .map((data) => BookingInfoModel.fromJson(data))
              .toList(),
        );
        print("Booking info get success.");
        return 1;
      } else if (response.statusCode == 502) {
        BookingInfoList.clear();
        print("Invalid email.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Your register email don't match..");
        return 3;
      } else if (response.statusCode == 500) {
        BookingInfoList.clear();
        print("Exception caught in backend.");
        return 4;
      }
      else if (response.statusCode == 501) {
        BookingInfoList.clear();
        print("Invalid data format.");
        return 4;
      }
      else {
        BookingInfoList.clear();
        print("Booking info get fail.");
        print("Status code = ${response.statusCode}");
        return 2;
      }
    } catch (Obj) {
      BookingInfoList.clear();
      print("Exception caugh while getting booking info.");
      print(Obj.toString());
      return 0;
    }
  }



  List<NotificationsInfoModel> NotificationsInfoList = [];

  Future<int> GetNotificationsInfo({required String Email}) async {
    try {
      final Map<String, dynamic> userData = {"Email": Email};
      const String url = Backend_Server_Url + "api/Booking/sendnotification";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        NotificationsInfoList.clear();
        NotificationsInfoList.addAll(responseData
            .map((data) => NotificationsInfoModel.fromJson(data))
            .toList());
        print("Notification info get success.");
        return 1;
      } else if (response.statusCode == 502) {
        NotificationsInfoList.clear();
        print("Invalid email.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Your register email don't match..");
        return 3;
      } else if (response.statusCode == 500) {
        NotificationsInfoList.clear();
        print("Exception caught in backend.");
        return 4;
      }
      else if (response.statusCode == 501) {
        NotificationsInfoList.clear();
        print("Invalid data format.");
        return 4;
      }
      else {
        NotificationsInfoList.clear();
        print("Notification info get fail.");
        print("Status code = ${response.statusCode}");
        return 2;
      }
    } catch (Obj) {
      NotificationsInfoList.clear();
      print("Exception caugh while getting Notification info.");
      print(Obj.toString());
      return 0;
    }
  }



  List<NewNotificationsModel> NewNotificationsList = [];

  Future<int> GetNewNotificationInfo({required String Email}) async {
    try {
      final Map<String, dynamic> userData = {"Email": Email};
      const String url = Backend_Server_Url + "api/Booking/sendnewnotification";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        NewNotificationsList.clear();
        NewNotificationsList.addAll(responseData
            .map((data) => NewNotificationsModel.fromJson(data))
            .toList());
        print("New notification info get success.");
        return 1;
      } else if (response.statusCode == 502) {
        NewNotificationsList.clear();
        print("Invalid email.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Your register email don't match..");
        return 3;
      } else if (response.statusCode == 500) {
        NewNotificationsList.clear();
        print("Exception caught in backend.");
        return 4;
      }
      else if (response.statusCode == 501) {
        NewNotificationsList.clear();
        print("Invalid data format.");
        return 4;
      }
      else {
        NewNotificationsList.clear();
        print("New notification  info get fail.");
        print("Status code = ${response.statusCode}");
        return 2;
      }
    } catch (Obj) {
      NewNotificationsList.clear();
      print("Exception caugh while getting New notification  info.");
      print(Obj.toString());
      return 0;
    }
  }


  Future<int> UpdateNewNotificationInfo({required String Email}) async
  {
    try {
      final Map<String, dynamic> userData = {"Email": Email};
      const String url = Backend_Server_Url + "api/Booking/updatenewnotification";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update New notification info get success.");
        return 1;
      } else if (response.statusCode == 502) {
        print("Invalid email.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Your register email don't match..");
        return 3;
      } else if (response.statusCode == 500) {
        print("Exception caught in backend.");
        return 4;
      }
      else if (response.statusCode == 501) {
        print("Invalid data format.");
        return 4;
      }
      else {

        print("Update New notification fail.");
        print("Status code = ${response.statusCode}");
        return 2;
      }
    } catch (Obj) {

      print("Exception caugh while getting New notification  info.");
      print(Obj.toString());
      return 0;
    }
  }

  // ============================================================
  // NEW — orchestrates the three (unchanged) GET calls above, then hands
  // the raw lists to the GetX controller for the UI to react to.
  // Wrapped defensively so any unexpected failure still leaves the
  // screen in a safe, visible error state instead of crashing.
  // ============================================================

  Future<void> _loadEverything() async {
    try {
      bookingCont.setLoading(true);
      bookingCont.setLoadError(false);

      final results = await Future.wait([
        GetBookingInfo(Email: widget.Current_User_Email),
        GetNotificationsInfo(Email: widget.Current_User_Email),
        GetNewNotificationInfo(Email: widget.Current_User_Email),
      ]);

      final bool anyFailed = results.any((r) => r != 1);

      bookingCont.setBookingInfoList(BookingInfoList);
      bookingCont.setNotificationsInfoList(NotificationsInfoList);

      bool hasNew = false;
      for (final n in NewNotificationsList) {
        if ((n.status ?? false) == true) {
          hasNew = true;
          break;
        }
      }
      bookingCont.setHasNewNotification(hasNew);

      bookingCont.setLoadError(anyFailed && BookingInfoList.isEmpty);
      bookingCont.setLoading(false);
    } catch (e) {
      // Defensive fallback only — GetBookingInfo/GetNotificationsInfo/
      // GetNewNotificationInfo already catch their own exceptions and
      // return status codes, so this only guards against something truly
      // unexpected (e.g. Future.wait itself failing).
      print("Unexpected error in _loadEverything: $e");
      try {
        bookingCont.setLoadError(true);
        bookingCont.setLoading(false);
      } catch (_) {}
      Toastget().Toastmsg("Couldn't load your bookings. Please try again.");
    }
  }

  // ============================================================
  // NEW — bell tap: opens the notifications drawer immediately, and if
  // there was an unread notification, optimistically flips the bell back
  // to its normal state right away while the (unchanged) update call
  // confirms it on the backend.
  // ============================================================

  Future<void> _handleBellTap() async {
    try {
      _scaffoldKey.currentState?.openEndDrawer();

      if (bookingCont.hasNewNotification.value) {
        bookingCont.setHasNewNotification(false);
        try {
          await UpdateNewNotificationInfo(Email: widget.Current_User_Email);
        } catch (e) {
          // Non-critical for the icon state — the toast/nav-reset logic
          // inside UpdateNewNotificationInfo already handles hard failures.
          print("Unexpected error updating new-notification status: $e");
        }
      }
    } catch (e) {
      // Defensive fallback only — never let opening the drawer crash
      // the screen.
      print("Unexpected error in _handleBellTap: $e");
    }
  }

  // ============================================================
  // NEW — card tap: routes to the provider or user booking-details
  // screen depending on the current user's role, carrying the full
  // booking list across via the mutable public field on each screen.
  // ============================================================

  void _onBookingCardTap(BookingInfoModel booking,{required num BookingId}) {
    try {
      final bool isProvider =
          widget.Current_User_Role.trim().toLowerCase() == 'provider';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {

            List<BookingInfoModel> filteredBookingList =
            bookingCont.bookingInfoList
                .where((element) => element.bookId == BookingId)
                .toList();
            if (isProvider) {
              return Providerbookinginfodetailsscreen(
                Current_User_Email: widget.Current_User_Email,
                Current_User_JwtToken: widget.Current_User_JwtToken,
                Current_User_Role: widget.Current_User_Role,
                BookingInfoListInfo: filteredBookingList,
              );
            } else {
              return Userbookinginfodetailsscreen(
                Current_User_Email: widget.Current_User_Email,
                Current_User_JwtToken: widget.Current_User_JwtToken,
                Current_User_Role: widget.Current_User_Role,
                BookingInfoListInfo: filteredBookingList,
              );
            }
          },
        ),
      );


    } catch (e) {
      // Defensive fallback only — never let a bad navigation attempt
      // crash the screen.
      print("Unexpected error in _onBookingCardTap: $e");
      Toastget().Toastmsg("Couldn't open booking details. Please try again.");
    }
  }

  // ---------------------------------------------------------------------
  // Small date formatter — no intl dependency required.
  // ---------------------------------------------------------------------
  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return "—";
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
      return iso;
    }
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
    final double contentMaxWidth = widthval > 1300 ? 1180 : double.infinity;
    final int columns = widthval < 700 ? 1 : (widthval < 1100 ? 2 : 3);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _Theme.bgTop,
      appBar: _buildAppBar(context),
      endDrawer: _buildNotificationsDrawer(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_Theme.bgTop, _Theme.bgMid, _Theme.bgBottom],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, outerConstraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints:
                  BoxConstraints(minHeight: outerConstraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Header(
                            UserLogin: widget.UserLogin,
                            User_JwtToken: widget.Current_User_JwtToken,
                          ),
                          Center(
                            child: ConstrainedBox(
                              constraints:
                              BoxConstraints(maxWidth: contentMaxWidth),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: isMobile ? 20 : 32,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    _animatedSection(
                                      animation: _heroAnim,
                                      child: _buildHero(isMobile),
                                    ),

                                    SizedBox(height: isMobile ? 20 : 26),

                                    _animatedSection(
                                      animation: _searchAnim,
                                      child: _buildSearchCard(isMobile),
                                    ),

                                    SizedBox(height: isMobile ? 18 : 24),

                                    _animatedSection(
                                      animation: _listAnim,
                                      child: _buildResultsSection(
                                        isMobile: isMobile,
                                        columns: columns,
                                      ),
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
                        child: Footer(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ANIMATED SECTION WRAPPER
  // ============================================================

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
  // APP BAR — bordered back arrow (primary-text-colored, clearly
  // visible), title, and the notification bell action.
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
                  side: BorderSide(color: _Theme.emerald.withOpacity(0.55), width: 1.4),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    try {
                      Navigator.of(context).pop();
                    } catch (e) {
                      // Defensive fallback only.
                    }
                  },
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back_rounded, color: _Theme.primaryText, size: 20),
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
              gradient: const LinearGradient(colors: [_Theme.emerald, _Theme.mint]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: _Theme.emerald.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.event_note_rounded, color: _Theme.bgTop, size: 19),
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
          child: Center(child: _buildNotificationBell()),
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATION BELL — clearly distinct "new" vs "normal" states.
  // Normal: muted bordered box, plain bell.
  // New: red-bordered box, red bell, small red dot badge, gentle ring
  // shake animation — impossible to miss.
  // ============================================================

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
                        border: Border.all(color: _Theme.surfaceBar, width: 1.6),
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
                      gradient: const LinearGradient(colors: [_Theme.emerald, _Theme.mint]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded, color: _Theme.bgTop, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Notifications",
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _Theme.mutedTextAlt, size: 20),
                    onPressed: () {
                      try {
                        Navigator.of(context).pop();
                      } catch (e) {
                        // Defensive fallback only.
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
                          Icon(Icons.inbox_rounded, color: _Theme.mutedTextAlt.withOpacity(0.7), size: 30),
                          const SizedBox(height: 10),
                          const Text(
                            "No notifications yet",
                            style: TextStyle(color: _Theme.primaryText, fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "You'll see booking updates here.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _Theme.mutedText, fontSize: 12),
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
                            child: const Icon(Icons.campaign_rounded, color: _Theme.mint, size: 15),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.message ?? "",
                                  style: const TextStyle(
                                    color: _Theme.primaryText,
                                    fontSize: 12.8,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
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
  // HERO
  // ============================================================

  Widget _buildHero(bool isMobile) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            "Every booking tied to your account, newest activity first. "
                "Search by booking ID or tap a card for full details.",
            style: TextStyle(
              color: _Theme.mutedText,
              fontSize: isMobile ? 13 : 14.5,
              height: 1.55,
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
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: _Theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(
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
                : [],
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
                // Defensive fallback only.
              }
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: "Search by booking ID",
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
                      // Defensive fallback only.
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULTS SECTION
  // ============================================================

  Widget _buildResultsSection({required bool isMobile, required int columns}) {
    return Obx(() {
      if (bookingCont.isLoading.value) {
        return _resultsShell(
          child: const Center(
            child: CircularProgressIndicator(
              color: _Theme.emerald,
              strokeWidth: 2.4,
            ),
          ),
        );
      }

      if (bookingCont.hasLoadError.value) {
        return _resultsShell(
          child: _emptyState(
            icon: Icons.error_outline_rounded,
            title: "Couldn't load bookings",
            message: "Pull down or come back and try again.",
          ),
        );
      }

      final bookings = bookingCont.displayedBookings;

      if (bookings.isEmpty) {
        final bool searching = bookingCont.searchText.value.trim().isNotEmpty;
        return _resultsShell(
          child: _emptyState(
            icon: searching ? Icons.search_off_rounded : Icons.event_busy_rounded,
            title: searching ? "No matching booking" : "No bookings yet",
            message: searching
                ? "Check the booking ID and try again."
                : "New bookings will show up here as they come in.",
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "${bookings.length} booking${bookings.length == 1 ? '' : 's'}",
              style: const TextStyle(
                color: _Theme.mutedTextAlt,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1 ? 2.35 : 1.28,
            ),
            itemBuilder: (context, index) {
              return _bookingCard(bookings[index], index);
            },
          ),
        ],
      );
    });
  }

  Widget _resultsShell({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Theme.border),
      ),
      child: child,
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _Theme.mutedTextAlt, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _Theme.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Theme.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOKING CARD — bookId, providerNumber, userNumber, date, service name
  // ------------------------------------------------------------

  Widget _bookingCard(BookingInfoModel booking, int index) {
    final String serviceName = booking.serviceName ?? "Service";
    final String bookIdLabel = booking.bookId != null ? "#${booking.bookId}" : "#--";
    final String providerNumLabel =
    booking.providerNumber != null ? "${booking.providerNumber}" : "--";
    final String userNumLabel =
    booking.userNumber != null ? "${booking.userNumber}" : "--";
    final String dateLabel = _formatDate(booking.createdAt);

    return Obx(() {
      final bool hovered = bookingCont.hoveredCardIndex.value == index;
      final bool pressed = bookingCont.pressedCardIndex.value == index;

      return MouseRegion(
        onEnter: (_) => bookingCont.setHoveredCard(index),
        onExit: (_) => bookingCont.clearHoveredCard(),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => bookingCont.setPressedCard(index),
          onTapCancel: () => bookingCont.clearPressedCard(),
          onTapUp: (_) => bookingCont.clearPressedCard(),
          onTap: () => _onBookingCardTap(booking, BookingId: booking.bookId!,),
          child: AnimatedScale(
            scale: pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hovered ? _Theme.surface.withOpacity(0.92) : _Theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hovered ? _Theme.emerald.withOpacity(0.45) : _Theme.border,
                  width: hovered ? 1.3 : 1,
                ),
                boxShadow: hovered
                    ? [
                  BoxShadow(
                    color: _Theme.emerald.withOpacity(0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _Theme.emerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.event_available_rounded,
                          color: _Theme.mint,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _Theme.primaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Booking $bookIdLabel",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _Theme.mutedTextAlt,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statPill(icon: Icons.storefront_rounded, label: "Provider #$providerNumLabel"),
                      _statPill(icon: Icons.person_rounded, label: "User #$userNumLabel"),
                      _statPill(icon: Icons.schedule_rounded, label: dateLabel),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.chevron_right_rounded, color: _Theme.mint, size: 18),
                      const SizedBox(width: 2),
                      Text(
                        "Details",
                        style: TextStyle(
                          color: _Theme.mint,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _statPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _Theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _Theme.mint),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Theme.primaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}