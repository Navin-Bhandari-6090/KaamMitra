import 'dart:convert';

import 'package:app/web/footer/Footer.dart';
import 'package:app/web/header/Header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../constant/Server_Database.dart';
import '../../models/RatingInfoModel.dart';
import '../../models/ServiceScreenServiceModel.dart';

import '../../models/ServiceScreenUserInfoModel.dart';
import '../../state management/getx/services/service_screen_getx.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';
// TODO: point this at the real location of SelectServiceProviderInfoScreen.
import 'select_service_provider_info_screen.dart';

/// ---------------------------------------------------------------------------
/// THEME TOKENS (dark green, modern) — matches Header.dart / ProviderProfile.dart
/// / ProviderAddService.dart
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
}

class ServicesScreen extends StatefulWidget
{

  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const ServicesScreen(
      {super.key,
        required this.User_Email,
        required this.User_JwtToken,
        required this.User_Role});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // GetX controller — all interactive state lives here, no setState.
  // ============================================================
  final ServiceScreenGetx serviceCont = Get.put(ServiceScreenGetx());

  final TextEditingController SearchCont = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ============================================================
  // ENTRANCE ANIMATION (UI-only, no business logic)
  // ============================================================

  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _searchAnim;
  late final Animation<double> _listAnim;
  late final Animation<double> _footerAnim;

  @override
  void initState() {
    super.initState();

    Provider_User_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);

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

    _searchFocusNode.addListener(() {
      serviceCont.setSearchFocused(_searchFocusNode.hasFocus);
    });

    _loadEverything();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _searchFocusNode.dispose();
    SearchCont.dispose();
    super.dispose();
  }



  List<RatingInfoModel> RatingInfoList = [];

  Future<int> GetRatingInfo({required String email}) async {
    try {
      final Map<String, dynamic> userData = {"Email": email};
      const String url = Backend_Server_Url + "api/Service/getratinginfo";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        RatingInfoList.clear();
        RatingInfoList.addAll(responseData
            .map((data) => RatingInfoModel.fromJson(data))
            .toList());
        print("Rating info get success.");
        return 1;
      } else if (response.statusCode == 500) {
        RatingInfoList.clear();
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
      } else if (response.statusCode == 501) {
        RatingInfoList.clear();
        print("Exception caught in backend.");
        return 4;
      } else {
        RatingInfoList.clear();
        print("Rating info get fail.");
        print("Status code = ${response.statusCode}");
        return 2;
      }
    } catch (Obj) {
      RatingInfoList.clear();
      print("Exception caight in login user method in http method.");
      print(Obj.toString());
      return 0;
    }
  }

  List<ServiceScreenServiceModel> ServiceInfoList = [];

  Future<int> GetServiceInfo({required String email}) async {
    try {
      final Map<String, dynamic> userData = {"Email": email};
      const String url = Backend_Server_Url + "api/Service/getserviceinfo";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        ServiceInfoList.clear();
        ServiceInfoList.addAll(responseData
            .map((data) => ServiceScreenServiceModel.fromJson(data))
            .toList());
        print("Service info get success.");
        return 1;
      } else if (response.statusCode == 404) {
        ServiceInfoList.clear();
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
      } else if (response.statusCode == 501) {
        ServiceInfoList.clear();
        print("Exception caught in backend.");
        return 4;
      } else if (response.statusCode == 502) {
        ServiceInfoList.clear();
        print("Incorrect data format.");
        return 4;
      } else {
        ServiceInfoList.clear();
        print("Rating info get fail.");
        print("Status code = ${response.statusCode}");
        return 2;
      }
    } catch (Obj) {
      ServiceInfoList.clear();
      print("Exception caight..");
      print(Obj.toString());
      return 0;
    }
  }

  List<ServiceScreenUserInfoModel> ProviderInfoList = [];

  Future<int> GetProviderInfo({required String email}) async {
    try {
      final Map<String, dynamic> userData = {"Email": email};
      const String url = Backend_Server_Url + "api/Service/getuserinfo";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        ProviderInfoList.clear();
        ProviderInfoList.addAll(responseData
            .map((data) => ServiceScreenUserInfoModel.fromJson(data))
            .toList());
        print("Service info get success.");
        return 1;
      } else if (response.statusCode == 404) {
        ProviderInfoList.clear();
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
      } else if (response.statusCode == 501) {
        ProviderInfoList.clear();
        print("Exception caught in backend.");
        return 4;
      } else if (response.statusCode == 502) {
        ProviderInfoList.clear();
        print("Incorrect data format.");
        return 4;
      } else {
        ProviderInfoList.clear();
        print("Rating info get fail.");
        print("Status code = ${response.statusCode}");
        return 2;
      }
    } catch (Obj) {
      ProviderInfoList.clear();
      print("Exception caight..");
      print(Obj.toString());
      return 0;
    }
  }


  Future<void> _loadEverything() async
  {
    serviceCont.setLoading(true);
    serviceCont.setLoadError(false);

    final results = await Future.wait(
        [
      GetServiceInfo(email: widget.User_Email),
      GetProviderInfo(email: widget.User_Email),
      GetRatingInfo(email: widget.User_Email),

    ]
    );

    final bool anyFailed = results.any((r) => r != 1);

    double currentLat = 0.0;
    double currentLong = 0.0;
    bool locationKnown = false;

    for (final p in ProviderInfoList)
    {
      if (p.email == widget.User_Email)
      {

        currentLat = asDouble(p.latitude);
        currentLong = asDouble(p.longitude);
        locationKnown = true;
        break;

      }
    }

    serviceCont.buildCombinedList(
      services: ServiceInfoList,
      providers: ProviderInfoList,
      ratings: RatingInfoList,
      currentUserLat: currentLat,
      currentUserLong: currentLong,
      currentUserLocationKnown: locationKnown,
    );

    serviceCont.setLoadError(anyFailed && ServiceInfoList.isEmpty);
    serviceCont.setLoading(false);
  }

  void _onCardTap(CombinedServiceCard card,{required String ProviderEmail,required String ServiceName,required num ProviderNumber,required num ServiceId,required String ProRegServiceDescription })
  {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectServiceProviderInfoScreen
          (
          Current_User_Email: widget.User_Email,
          Current_User_JwtToken: widget.User_JwtToken,
          Current_User_Role: widget.User_Role,
          Distance: card.distanceKm,
          Rating: card.rating,
          Provider_User_Email: ProviderEmail,
          Service_info_List: ServiceInfoList,
          Provider_info_List: ProviderInfoList,
          Provider_Service_Name: ServiceName,
          Providernumber: ProviderNumber,
          ServiceId:ServiceId,
          ProRegServiceDescription:ProRegServiceDescription,
        ),
      ),
    );
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
      backgroundColor: _Theme.bgTop,
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
                    // Pins the shared Footer to the bottom of the screen
                    // on short content, same as HomeScreenUi.
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          // ====================================================
                          // SITE HEADER (shared component — replaces the old
                          // custom app-bar-style header)
                          // NOTE: assumes this screen is only reachable once
                          // logged in. If that's not always true, wire
                          // UserLogin to real state instead of `true`.
                          // ====================================================
                          Header(
                            UserLogin: true,
                            User_JwtToken: widget.User_JwtToken,
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
                                    // ============================================
                                    // BACK ROW (bordered arrow, primary text
                                    // color — no boxed app-bar shell)
                                    // ============================================
                                    _buildBackRow(context, isMobile),

                                    SizedBox(height: isMobile ? 20 : 28),

                                    _animatedSection(
                                      animation: _heroAnim,
                                      child: _buildHero(isMobile),
                                    ),

                                    SizedBox(height: isMobile ? 20 : 26),

                                    // ============================================
                                    // SEARCH + SORT
                                    // ============================================
                                    _animatedSection(
                                      animation: _searchAnim,
                                      child: _buildSearchSortCard(isMobile),
                                    ),

                                    SizedBox(height: isMobile ? 18 : 24),

                                    // ============================================
                                    // RESULTS
                                    // ============================================
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

                      // ====================================================
                      // SITE FOOTER (shared component)
                      // ====================================================
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
  // BACK ROW — bordered back arrow, primary text color (no boxed
  // app-bar shell; the shared Header component above handles nav).
  // ============================================================

  Widget _buildBackRow(BuildContext context, bool isMobile) {
    return Row(
      children: [


        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Services",
                style: TextStyle(
                  color: _Theme.primaryText,
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.User_Email,
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
            "Find a trusted provider",
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
            "Search by service name or provider ID, then sort by distance "
                "or rating to find the best match near you.",
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
  // SEARCH + SORT
  // ============================================================

  Widget _buildSearchSortCard(bool isMobile) {
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

          Obx(
                () => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _Theme.surfaceBar,
                border: Border.all(
                  color: serviceCont.isSearchFocused.value
                      ? _Theme.emerald.withOpacity(0.55)
                      : _Theme.border,
                  width: 1.4,
                ),
                boxShadow: serviceCont.isSearchFocused.value
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
                style: const TextStyle(
                  color: _Theme.primaryText,
                  fontSize: 14,
                ),
                onChanged: (value) => serviceCont.changeSearchText(value),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintText: "Search by service name or provider Id(#)",
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
                        () => serviceCont.searchText.value.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _Theme.mutedTextAlt,
                        size: 18,
                      ),
                      onPressed: () {
                        SearchCont.clear();
                        serviceCont.changeSearchText("");
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isMobile ? 14 : 16),


          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.tune_rounded,
                  color: _Theme.mutedTextAlt, size: 15),
              const Text(
                "Sort by",
                style: TextStyle(
                  color: _Theme.mutedTextAlt,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _sortChip(
                label: "Nearest",
                icon: Icons.near_me_rounded,
                mode: ServiceSortMode.distance,
              ),
              _sortChip(
                label: "Top rated",
                icon: Icons.star_rounded,
                mode: ServiceSortMode.rating,
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _sortChip({
    required String label,
    required IconData icon,
    required ServiceSortMode mode,
  }) {
    return Obx(() {
      final bool selected = serviceCont.sortMode.value == mode;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => serviceCont.changeSortMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: selected
                  ? const LinearGradient(
                  colors: [_Theme.emerald, _Theme.mint])
                  : null,
              color: selected ? null : _Theme.surfaceBar,
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : _Theme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : _Theme.mutedTextAlt,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _Theme.mutedText,
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
  // RESULTS
  // ============================================================

  Widget _buildResultsSection({required bool isMobile, required int columns})

  {
    return Obx(() {
      if (serviceCont.isLoading.value) {
        return _resultsShell(
          child: const Center(
            child: CircularProgressIndicator(
              color: _Theme.emerald,
              strokeWidth: 2.4,
            ),
          ),
        );
      }

      if (serviceCont.hasLoadError.value) {
        return _resultsShell(
          child: _emptyState(
            icon: Icons.error_outline_rounded,
            title: "Couldn't load services",
            message: "Pull down or come back and try again.",
          ),
        );
      }

      final cards = serviceCont.displayedCards;

      if (cards.isEmpty) {
        final bool searching = serviceCont.searchText.value.trim().isNotEmpty;
        return _resultsShell(
          child: _emptyState(
            icon: searching
                ? Icons.search_off_rounded
                : Icons.inbox_rounded,
            title: searching ? "No matches" : "No providers yet",
            message: searching
                ? "Try a different service name or provider number."
                : "Check back soon — new providers appear here.",
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "${cards.length} provider${cards.length == 1 ? '' : 's'} found",
              style: const TextStyle(
                color: _Theme.mutedTextAlt,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),


          LayoutBuilder(
            builder: (context, box) {
              const double gap = 14;
              final double raw = (box.maxWidth - gap * (columns - 1)) / columns;
              final double cardW = raw < 0 ? 0 : raw;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (int i = 0; i < cards.length; i++)
                    SizedBox(width: cardW, child: _providerCard(cards[i], i)),
                ],
              );
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
  // PROVIDER CARD
  // ------------------------------------------------------------

  Widget _providerAvatar(String? photoPath, {double size = 58}) {
    final String url = _buildPhotoUrl(photoPath);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_Theme.emerald, _Theme.mint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _Theme.emerald.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _Theme.surface,
        ),
        child: ClipOval(
          child: url.isEmpty
              ? _avatarFallback(size)
              : Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) => progress == null
                ? child
                : _avatarFallback(size, loading: true),
            errorBuilder: (ctx, e, st) => _avatarFallback(size),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(double size, {bool loading = false}) {
    return Container(
      width: size,
      height: size,
      color: _Theme.surfaceBar,
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
        width: size * 0.35,
        height: size * 0.35,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: _Theme.mint,
        ),
      )
          : Icon(Icons.person_rounded, color: _Theme.mint, size: size * 0.45),
    );
  }

  String _buildPhotoUrl(String? path) {
    try {
      final String p = (path ?? '').trim();
      if (p.isEmpty || p.toLowerCase() == 'null') return '';
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      final String base = Backend_Server_Url.replaceFirst(RegExp(r'/$'), '');
      return p.startsWith('/') ? '$base$p' : '$base/$p';
    } catch (_) {
      return '';
    }
  }

  Widget _providerCard(CombinedServiceCard card, int index) {
    const String noData = 'No data available';

    String clean(String? v) {
      final String t = (v ?? '').trim();
      return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t;
    }

    final String firstName = clean(card.provider?.firstName);
    final String lastName = clean(card.provider?.lastName);
    final String providerName =
    [firstName, lastName].where((e) => e.isNotEmpty).join(' ');

    final String? providerPhoto = card.provider?.photo;
    final String serviceName = clean(card.service.serviceName);
    final String description = clean(card.service.proRegServiceDescription);
    final num? serviceId = card.service.providerServiceId;
    final num? userNumber = card.service.userNumber;
    final String providerEmail = clean(card.provider?.email);

    final bool canOpen = userNumber != null &&
        serviceId != null &&
        providerEmail.isNotEmpty;

    final double avatarSize = MediaQuery.sizeOf(context).width >= 700 ? 66 : 58;

    return Obx(() {
      final bool hovered = serviceCont.hoveredCardIndex.value == index;
      final bool pressed = serviceCont.pressedCardIndex.value == index;

      return MouseRegion(
        onEnter: (_) => serviceCont.setHoveredCard(index),
        onExit: (_) => serviceCont.clearHoveredCard(),
        cursor: canOpen ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: canOpen ? (_) => serviceCont.setPressedCard(index) : null,
          onTapCancel: () => serviceCont.clearPressedCard(),
          onTapUp: (_) => serviceCont.clearPressedCard(),
          onTap: (userNumber == null || serviceId == null || !canOpen)
              ? null
              : () => _onCardTap(
            card,
            ServiceName: serviceName,
            ProviderNumber: userNumber,
            ServiceId: serviceId,
            ProRegServiceDescription: description,
            ProviderEmail: providerEmail,
          ),
          child: AnimatedScale(
            scale: pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hovered ? _Theme.surface.withOpacity(0.9) : _Theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hovered
                      ? _Theme.emerald.withOpacity(0.45)
                      : _Theme.border,
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- title row ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _providerAvatar(providerPhoto, size: avatarSize),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceName.isEmpty ? noData : serviceName,
                              softWrap: true,
                              style: TextStyle(
                                color: serviceName.isEmpty
                                    ? _Theme.mutedTextAlt
                                    : _Theme.primaryText,
                                fontSize: 15.5,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              providerName.isEmpty
                                  ? "Provider Name = $noData"
                                  : "Provider Name = $providerName",
                              softWrap: true,
                              style: const TextStyle(
                                color: _Theme.mutedTextAlt,
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ---------- description ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _Theme.surfaceBar,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _Theme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.notes_rounded,
                                size: 13, color: _Theme.mint),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "SERVICE DESCRIPTION",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _Theme.mutedTextAlt,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description.isEmpty ? noData : description,
                          softWrap: true,
                          style: TextStyle(
                            color: description.isEmpty
                                ? _Theme.mutedTextAlt
                                : _Theme.primaryText,
                            fontSize: 13,
                            height: 1.5,
                            fontStyle: description.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- stat pills ----------
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statPill(
                        icon: Icons.badge_rounded,
                        label: userNumber == null
                            ? noData
                            : "Provider ID #${userNumber.toInt()}",
                      ),
                      _statPill(
                        icon: Icons.location_on_rounded,
                        label: card.hasLocation
                            ? "${card.distanceKm.toStringAsFixed(1)} km"
                            : noData,
                      ),
                      _statPill(
                        icon: Icons.star_rounded,
                        label: card.rating > 0
                            ? card.rating.toStringAsFixed(1)
                            : "New",
                        iconColor: const Color(0xFFFBBF24),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ---------- call to action ----------
                  if (canOpen)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.play_circle_fill_rounded,
                              color: _Theme.mint, size: 16),
                          SizedBox(width: 5),
                          Text(
                            "Start work",
                            style: TextStyle(
                              color: _Theme.mint,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

  Widget _statPill({
    required IconData icon,
    required String label,
    Color iconColor = _Theme.mint,
  }) {
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
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Theme.primaryText,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

}