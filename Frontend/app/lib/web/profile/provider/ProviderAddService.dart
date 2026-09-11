import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import '../../../constant/Server_Database.dart';
import '../../../constant/Style.dart';
import '../../../models/RegisterServiceInfo.dart';
import '../../../state management/getx/profile/provider/add_service_getx.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/GreenTextfield.dart';
import '../../common widget/single_file_pick_getx_cont.dart';
import '../../common widget/toast.dart';

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

  static const Color border = Color(0xFF234232);
}

class ProviderAddService extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const ProviderAddService(
      {super.key,
        required this.User_Email,
        required this.User_JwtToken,
        required this.User_Role});

  @override
  State<ProviderAddService> createState() => _ProviderAddServiceState();
}

class _ProviderAddServiceState extends State<ProviderAddService>
    with SingleTickerProviderStateMixin {
  final Toast = Toastget();
  final change_file_cont_getx = Get.put(FilePickerController());
  final AvailableServiceCont = TextEditingController();
  final SearchTextGetxCont = Get.put(AddServiceGetx());
  final ProviderAddServiceNameCont = TextEditingController();

  // ============================================================
  // ENTRANCE ANIMATION (UI-only addition, no business logic)
  // ============================================================

  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _searchAnim;
  late final Animation<double> _formAnim;
  late final Animation<double> _submitAnim;

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);

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
    _formAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.85, curve: Curves.easeOutCubic),
    );
    _submitAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();

    // GetX-driven focus tracking (search glow border) — replaces setState.
    _searchFocusNode.addListener(() {
      SearchTextGetxCont.setSearchFocused(_searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _searchFocusNode.dispose();
    change_file_cont_getx.fileExtension.value="";
    change_file_cont_getx.fileBytes.value=null;
    change_file_cont_getx.filePath.value="";
    super.dispose();
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ErrorPage()));
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  Future<int> AddService({
    required List<int> FileBytes,
    required String ServiceName,
  }) async {
    try {
      // =========================================================
      // 2. Print information
      // =========================================================

      print("========== ADD SERVICE ==========");
      print("Service Name: $ServiceName");
      print("Email: ${widget.User_Email}");
      print("Document Size: ${FileBytes.length} bytes");

      // =========================================================
      // 3. Validate document bytes
      // =========================================================

      if (FileBytes.isEmpty) {
        Toast.Toastmsg(
          'File data is required',
        );

        print(
          'File data is required',
        );

        return 1;
      }

      // =========================================================
      // 4. Validate service name
      // =========================================================

      if (ServiceName.isEmpty) {
        Toast.Toastmsg(
          'ServiceName is required',
        );

        print(
          'ServiceName is required',
        );

        return 2;
      }

      // =========================================================
      // 5. API URL
      // =========================================================

      const String url = Backend_Server_Url + "api/Profile/addservice";

      print("API URL: $url");

      // =========================================================
      // 6. Create multipart request
      // =========================================================

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      );

      // =========================================================
      // 7. Authorization
      // =========================================================

      request.headers["Authorization"] = "Bearer ${widget.User_JwtToken}";

      // =========================================================
      // 8. Add normal form fields
      // =========================================================

      request.fields["ServiceName"] = ServiceName.trim().toLowerCase();

      request.fields["Email"] = widget.User_Email;

      // =========================================================
      // 9. Add document bytes
      // =========================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          "ServiceDocument",
          FileBytes,
          filename: "service_document.pdf",
        ),
      );

      // =========================================================
      // 10. Send request
      // =========================================================

      print(
        "Multipart request created.",
      );

      print(
        "Uploading service document...",
      );

      final streamedResponse = await request.send();

      // =========================================================
      // 11. Convert response
      // =========================================================

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      // =========================================================
      // 12. Print response
      // =========================================================

      print(
        "Response status: ${response.statusCode}",
      );

      print(
        "Response body: ${response.body}",
      );

      // =========================================================
      // 13. Success
      // =========================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          'Add service success.',
        );

        print(
          'Add service success.',
        );

        return 1;
      }

      // =========================================================
      // 14. Bad request
      // =========================================================

      if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body,
        );

        print(
          "Bad request: ${response.body}",
        );

        return 3;
      }

      // =========================================================
      // 15. Duplicate service
      // =========================================================

      if (response.statusCode == 409) {
        Toast.Toastmsg(
          response.body,
        );

        print(
          "Service already exists: ${response.body}",
        );

        return 4;
      }

      // =========================================================
      // 16. Unauthorized
      // =========================================================

      if (response.statusCode == 401) {
        Toast.Toastmsg(
          "Unauthorized. Please login again.",
        );

        print(
          "Unauthorized.",
        );

        return 5;
      }

      // =========================================================
      // 17. Forbidden
      // =========================================================

      if (response.statusCode == 403) {
        Toast.Toastmsg(
          "You are not authorized to add a service.",
        );

        print(
          "Forbidden.",
        );

        return 6;
      }

      // =========================================================
      // 18. Server error
      // =========================================================

      if (response.statusCode == 500) {
        Toast.Toastmsg(
          "Server error while adding service.",
        );

        print(
          "Server error: ${response.body}",
        );

        return 7;
      }

      // =========================================================
      // 19. Other status
      // =========================================================

      print(
        "Unexpected status code: ${response.statusCode}",
      );

      Toast.Toastmsg(
        'Add service failed.',
      );

      return 8;
    } catch (obj) {
      // =========================================================
      // 20. Exception
      // =========================================================

      print(
        "Exception caught while adding service.",
      );

      print(
        "Exception: ${obj.toString()}",
      );

      Toast.Toastmsg(
        'Add service failed.',
      );

      return 0;
    }
  }

  List<RegisterServiceInfo> RegisterSearchlList = [];

  Future<void> GetRegisterServiceInfo({
    required String Email,
    required String jwttoken,
    required SearchText,
  }) async {
    try {
      print("profile user info method called");
      const String url = Backend_Server_Url + "api/Profile/getserviceinfo";
      Map<String, dynamic> UserDetails = {"Email": Email};
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwttoken'
        },
        body: json.encode(UserDetails),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        RegisterSearchlList.clear();
        RegisterSearchlList.addAll(
            responseData.map((data) => RegisterServiceInfo.fromJson(data)).toList());
        return;
      } else {
        RegisterSearchlList.clear();
        print("Data get from service info failed.");
        return;
      }
    } catch (obj) {
      RegisterSearchlList.clear();
      print("Exception caught while fetching service data from profile screen");
      print(obj.toString());
      return;
    }
  }

  // ============================================================
  // SUBMIT HANDLER — same logic/branches as before, wrapped with
  // a GetX-driven loading state instead of any setState.
  // ============================================================

  Future<void> _onSubmitPressed() async {
    if (SearchTextGetxCont.isSubmitting.value) return;

    SearchTextGetxCont.setSubmitting(true);
    try {
      int Result = await change_file_cont_getx.pickFile();
      if (Result == 1) {
        int Result = await AddService(
            FileBytes: change_file_cont_getx.fileBytes.value!,
            ServiceName: ProviderAddServiceNameCont.text.toString().trim());
        if (Result == 1) {
          return;
        } else {
          return;
        }
      } else {
        return;
      }
    } catch (exception) {
      return;
    } finally {
      SearchTextGetxCont.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double widthval = media.size.width;
    final double heightval = media.size.height;
    final double shortestval = media.size.shortestSide;
    final bool isLandscape = media.orientation == Orientation.landscape;

    final bool isMobile = widthval < 700;
    final bool isTablet = widthval >= 700 && widthval < 1100;

    final double horizontalPadding = isMobile ? 18 : (isTablet ? 32 : 48);
    final double contentMaxWidth = widthval > 1100 ? 880 : double.infinity;

    final double listMaxHeight =
    (isLandscape ? heightval * 0.34 : heightval * 0.42).clamp(180.0, 420.0);

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
                            // ================================================
                            // TOP BAR — back button + title
                            // ================================================
                            _buildTopBar(context, isMobile),

                            SizedBox(height: isMobile ? 20 : 28),

                            // ================================================
                            // HERO SECTION
                            // ================================================
                            _animatedSection(
                              animation: _heroAnim,
                              child: _buildHero(isMobile),
                            ),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ================================================
                            // BROWSE / SEARCH SECTION
                            // ================================================
                            _animatedSection(
                              animation: _searchAnim,
                              child: _buildBrowseCard(
                                widthval: widthval,
                                listMaxHeight: listMaxHeight,
                                isMobile: isMobile,
                              ),
                            ),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ================================================
                            // SERVICE DETAILS FORM
                            // ================================================
                            _animatedSection(
                              animation: _formAnim,
                              child: _buildDetailsCard(isMobile),
                            ),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ================================================
                            // SUBMIT ACTION
                            // ================================================
                            _animatedSection(
                              animation: _submitAnim,
                              child: _buildSubmitCard(isMobile),
                            ),

                            SizedBox(height: isMobile ? 24 : 36),
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
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(BuildContext context, bool isMobile) {
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
            "Add Service",
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 560;

          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment:
            compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 0 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _Theme.emerald.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: _Theme.emerald.withOpacity(0.20)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_rounded,
                              color: _Theme.mint, size: 14),
                          SizedBox(width: 7),
                          Text(
                            "Grow your reach",
                            style: TextStyle(
                              color: _Theme.mint,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "List a new service",
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: isMobile ? 26 : 32,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Search the catalogue for an existing service, or "
                          "name your own and attach a supporting document to "
                          "submit it for review.",
                      style: TextStyle(
                        color: _Theme.mutedText,
                        fontSize: isMobile ? 13 : 14.5,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: 26),
              if (compact) const SizedBox(height: 20),
              if (!compact)
                Container(
                  height: 108,
                  width: 108,
                  alignment: Alignment.center,
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
                  child: Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      color: _Theme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: _Theme.emerald.withOpacity(0.30), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _Theme.emerald.withOpacity(0.12),
                          blurRadius: 24,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
                      color: _Theme.mint,
                      size: 34,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // BROWSE / SEARCH CARD
  // ============================================================

  Widget _buildBrowseCard({
    required double widthval,
    required double listMaxHeight,
    required bool isMobile,
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
                child: const Icon(Icons.search_rounded,
                    color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Browse existing services",
                  style: TextStyle(
                    color: _Theme.primaryText,
                    fontSize: isMobile ? 15.5 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            "Find a matching service instead of creating a duplicate.",
            style: TextStyle(
              color: _Theme.mutedTextAlt,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // SEARCH FIELD — glow border reacts to focus via GetX
          // ------------------------------------------------------
          Obx(
                () => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: SearchTextGetxCont.isSearchFocused.value
                      ? _Theme.emerald.withOpacity(0.55)
                      : Colors.transparent,
                  width: 1.4,
                ),
                boxShadow: SearchTextGetxCont.isSearchFocused.value
                    ? [
                  BoxShadow(
                    color: _Theme.emerald.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
                    : [],
              ),
              child: GreenField(
                controller: AvailableServiceCont,
                label: "Search services",
                icon: Icons.work,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  SearchTextGetxCont.ChangeSearchText(value);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // RESULTS
          // ------------------------------------------------------
          Obx(
                () => FutureBuilder(
              future: GetRegisterServiceInfo(
                Email: widget.User_Email,
                jwttoken: widget.User_JwtToken,
                SearchText: SearchTextGetxCont.SearchText.value,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildResultsShell(
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: _Theme.emerald,
                        strokeWidth: 2.4,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return _buildResultsShell(
                    child: _emptyState(
                      icon: Icons.error_outline_rounded,
                      message: "No data available",
                    ),
                  );
                } else if (snapshot.connectionState == ConnectionState.done) {
                  if (RegisterSearchlList.isNotEmpty) {
                    if (AvailableServiceCont.text.toString().isEmpty) {
                      return Container(
                        width: widthval,
                        height: listMaxHeight,
                        decoration: BoxDecoration(
                          color: _Theme.surfaceBar,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _Theme.border),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          itemBuilder: (context, index) {
                            return _serviceListTile(
                              index: index,
                              name: RegisterSearchlList[index].serviceName,
                              description: RegisterSearchlList[index]
                                  .serviceDescription,
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Divider(
                              color: _Theme.border,
                              height: 1,
                              thickness: 1,
                              indent: 12,
                              endIndent: 12,
                            );
                          },
                          scrollDirection: Axis.vertical,
                          itemCount: RegisterSearchlList.length,
                        ),
                      );
                    } else {
                      final searchText =
                      AvailableServiceCont.text.trim().toLowerCase();

                      final matchingServices = RegisterSearchlList.where(
                            (element) =>
                        element.serviceName
                            ?.toLowerCase()
                            .contains(searchText) ??
                            false,
                      ).toList();

                      if (matchingServices.isEmpty) {
                        return _buildResultsShell(
                          child: _emptyState(
                            icon: Icons.search_off_rounded,
                            message: "Service name doesn't match",
                          ),
                        );
                      }

                      return Container(
                        width: widthval,
                        height: listMaxHeight * 0.75,
                        decoration: BoxDecoration(
                          color: _Theme.surfaceBar,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _Theme.border),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          itemCount: matchingServices.length,
                          itemBuilder: (context, index) {
                            final service = matchingServices[index];
                            return _serviceListTile(
                              index: index,
                              name: service.serviceName,
                              description: service.serviceDescription,
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Divider(
                              color: _Theme.border,
                              height: 1,
                              thickness: 1,
                              indent: 12,
                              endIndent: 12,
                            );
                          },
                        ),
                      );
                    }
                  }
                  return _buildResultsShell(
                    child: _emptyState(
                      icon: Icons.inbox_rounded,
                      message: "No service data available",
                    ),
                  );
                }
                return _buildResultsShell(
                  child: _emptyState(
                    icon: Icons.error_outline_rounded,
                    message: "Error. Relogin.",
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsShell({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Theme.border),
      ),
      child: child,
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _Theme.mutedTextAlt, size: 26),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: _Theme.mutedText,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SERVICE LIST TILE — hover highlight driven by GetX, not setState
  // ------------------------------------------------------------

  Widget _serviceListTile({
    required int index,
    required String? name,
    required String? description,
  }) {
    return Obx(() {
      final bool isHovered =
          SearchTextGetxCont.hoveredServiceIndex.value == index;

      return MouseRegion(
        onEnter: (_) => SearchTextGetxCont.setHoveredService(index),
        onExit: (_) => SearchTextGetxCont.clearHoveredService(),
        cursor: SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHovered
                ? _Theme.emerald.withOpacity(0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Theme.emerald.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_rounded,
                    color: _Theme.mint, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? "",
                      style: const TextStyle(
                        color: _Theme.primaryText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Description = ${description ?? ""}",
                      style: const TextStyle(
                        color: _Theme.mutedText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ============================================================
  // SERVICE DETAILS CARD
  // ============================================================

  Widget _buildDetailsCard(bool isMobile) {
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
                child: const Icon(Icons.edit_note_rounded,
                    color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Service details",
                  style: TextStyle(
                    color: _Theme.primaryText,
                    fontSize: isMobile ? 15.5 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "This is the name customers will see once your service is approved.",
            style: TextStyle(
              color: _Theme.mutedTextAlt,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GreenField(
              controller: ProviderAddServiceNameCont,
              label: "Enter service name.",
              icon: Icons.work),
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT CARD
  // ============================================================

  Widget _buildSubmitCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            _Theme.emerald.withOpacity(0.12),
            _Theme.mint.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: _Theme.emerald.withOpacity(0.18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 480;

          final Widget info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _Theme.emerald.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.upload_file_rounded,
                    color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Attach document & submit",
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: isMobile ? 14.5 : 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You'll be asked to choose a supporting PDF before this "
                          "service is submitted for review.",
                      style: TextStyle(
                        color: _Theme.mutedText,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget buttonWithCaption = Column(
            crossAxisAlignment:
            compact ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                  compact ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: _Theme.mutedTextAlt,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "On clicking add service select PDF file that contains certificate achievements",
                        textAlign: compact ? TextAlign.left : TextAlign.right,
                        style: const TextStyle(
                          color: _Theme.mutedTextAlt,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _submitButton(isMobile: isMobile),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 16),
                buttonWithCaption,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: info),
              const SizedBox(width: 18),
              buttonWithCaption,
            ],
          );
        },
      ),
    );
  }

  Widget _submitButton({required bool isMobile}) {
    return Obx(() {
      final bool submitting = SearchTextGetxCont.isSubmitting.value;
      final bool pressed = SearchTextGetxCont.isButtonPressed.value;

      return AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: submitting ? null : _onSubmitPressed,
            onTapDown: (_) => SearchTextGetxCont.setButtonPressed(true),
            onTapCancel: () => SearchTextGetxCont.setButtonPressed(false),
            onTapUp: (_) => SearchTextGetxCont.setButtonPressed(false),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 26,
                vertical: isMobile ? 14 : 15,
              ),
              decoration: BoxDecoration(
                gradient: submitting
                    ? null
                    : const LinearGradient(
                  colors: [_Theme.emerald, _Theme.mint],
                ),
                color: submitting ? _Theme.surface : null,
                borderRadius: BorderRadius.circular(14),
                border: submitting
                    ? Border.all(color: _Theme.border)
                    : null,
                boxShadow: submitting
                    ? []
                    : [
                  BoxShadow(
                    color: _Theme.emerald.withOpacity(0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (submitting) ...[
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: _Theme.mint,
                        strokeWidth: 2.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Submitting...",
                      style: TextStyle(
                        fontFamily: semibold,
                        color: _Theme.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 13.5 : 14.5,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.add_business_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 9),
                    Text(
                      "Add service",
                      style: TextStyle(
                        fontFamily: semibold,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 13.5 : 14.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}