import 'dart:convert';
import 'dart:math';


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../constant/Server_Database.dart';
import '../../constant/variable.dart';
import '../../models/AdminRegSerInfoModel.dart';

import '../../state management/getx/admin/add_del_upd_service_register_getx.dart';
import '../common method/Commmon_Method.dart';


// ============================================================
// PALETTE — Dark Forest / Emerald Glow theme
// ============================================================
class _Palette {
  static const bodyBg = Color(0xFF0F1F17);
  static const surface = Color(0xFF162E22);
  static const primaryText = Color(0xFFE6F4EA);
  static const mutedText = Color(0xFF8A9A90);
  static const headerFooter = Color(0xFF12261C);
  static const accent = Color(0xFF22C55E);
  static const accentMint = Color(0xFF34D399);
  static const borderColor = Color(0xFF234232);
}

class AddDelServices extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  const AddDelServices({super.key, required this.User_Role, required this.User_JwtToken, required this.User_Email});

  @override
  State<AddDelServices> createState() => _AddDelServicesState();
}

class _AddDelServicesState extends State<AddDelServices>
    with TickerProviderStateMixin {
  final NewServiceNameTextCont=TextEditingController();
  final SearchServiceNameTextCont=TextEditingController();
  final ServiceIdTextCont=TextEditingController();
  final ServiceDescpTextCont=TextEditingController();
  final DomesticPriceTextCont=TextEditingController();
  final DomesticPriceDiscountTextCont=TextEditingController();
  final InternationalPriceTextCont=TextEditingController();
  final InternationalPriceDiscountTextCont=TextEditingController();

  // ---- UI-only additions below: GetX controller + entrance/bubble animation ----
  final ServiceCont = Get.put(AddDelUpdServiceRegister());

  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final AnimationController _bubbleCtrl;

  @override
  void initState()
  {
    Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    // TODO: implement initState
    super.initState();

    // ---- UI-only: entrance + bubble animation setup ----
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();

    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // ---- New feature: keep search query in sync with the field ----
    SearchServiceNameTextCont.addListener(() {
      ServiceCont.searchQuery.value = SearchServiceNameTextCont.text.trim();
    });
  }

  @override
  void dispose()
  {
    // ---- UI-only: dispose animation controllers (must happen
    // before super.dispose(), or their Tickers leak/assert) ----
    _entranceCtrl.dispose();
    _bubbleCtrl.dispose();

    super.dispose();
  }


  List<AdminRegSerInfoModel> RegisterSearchlList = [];

  Future<void> GetRegisterServiceInfo() async {
    try {
      print("profile user info method called");
      const String url = Backend_Server_Url + "api/Admin/getservicenormal";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> responseData = await jsonDecode(response.body);
        RegisterSearchlList.clear();
        RegisterSearchlList.addAll(
            responseData.map((data) => AdminRegSerInfoModel.fromJson(data)).toList());
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


  Future<int> UpdateServicePrice({
    required String User_JwtToken,
    required int ServiceId,
    required double DomesticPrice,
    required double DomesticPriceDiscount,
    required double InternationalPrice,
    required double InternationalPriceDiscount,
  }) async {
    try {
      print("========== UPDATE SERVICE PRICE ==========");

      final Map<String, dynamic> data = {
        "ServiceId": ServiceId,
        "DomesticPrice": DomesticPrice,
        "DomesticPriceDiscount": DomesticPriceDiscount,
        "InternationalPrice": InternationalPrice,
        "InternationalPriceDiscount": InternationalPriceDiscount,
      };


      final response = await http.put(
        Uri.parse(
          "${Backend_Server_Url}api/Admin/updateservice",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $User_JwtToken",
        },
        body: jsonEncode(data),
      );


      if (response.statusCode == 200) {
        print("Service price updated successfully.");

        Toast.Toastmsg(
          "Service price updated successfully.",
        );

        return 200;
      }

      else if (response.statusCode == 502) {
        print("No service data available with that ID.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "No service data available with that ID.",
        );

        return 502;
      }

      else if (response.statusCode == 500) {
        print("Data are not in correct format.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Data are not in correct format.",
        );

        return 500;
      }

      else if (response.statusCode == 501) {
        print("Backend exception.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Something went wrong on server.",
        );

        return 501;
      }

      else if (response.statusCode == 401) {
        print("Unauthorized.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Unauthorized.",
        );

        return 401;
      }

      else if (response.statusCode == 403) {
        print("Admin access required.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Admin access required.",
        );

        return 403;
      }

      else {
        print(
          "Unexpected status code: ${response.statusCode}",
        );

        print(
          "Unexpected response: ${response.body}",
        );

        Toast.Toastmsg(
          "Failed to update service price.",
        );

        return response.statusCode;
      }
    }
    catch (obj) {
      print("========== UPDATE SERVICE PRICE ERROR ==========");
      print("Exception: ${obj.toString()}");

      Toast.Toastmsg(
        "Something went wrong.",
      );

      return 501;
    }
  }



  Future<int> AddService({
    required String User_JwtToken,
    required String ServiceName,
    required String ServiceDescription,
    required double DomesticPrice,
    required double DomesticPriceDiscount,
    required double InternationalPrice,
    required double InternationalPriceDiscount,
  }) async {
    try {
      print("========== ADD SERVICE ==========");

      final Map<String, dynamic> data = {
        "ServiceName": ServiceName,
        "ServiceDescription": ServiceDescription,
        "DomesticPrice": DomesticPrice,
        "DomesticPriceDiscount": DomesticPriceDiscount,
        "InternationalPrice": InternationalPrice,
        "InternationalPriceDiscount": InternationalPriceDiscount,
      };



      final response = await http.post(
        Uri.parse(
          "${Backend_Server_Url}api/Admin/registerservice",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $User_JwtToken",
        },
        body: jsonEncode(data),
      );



      if (response.statusCode == 200) {
        print("Service added successfully.");

        Toast.Toastmsg(
          "Service added successfully.",
        );

        return 200;
      }

      else if (response.statusCode == 502) {
        print("Service already registered.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Service already registered in that name.",
        );

        return 502;
      }

      else if (response.statusCode == 500) {
        print("Invalid service data.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Data are not in correct format.",
        );

        return 500;
      }

      else if (response.statusCode == 501) {
        print("Server exception.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Something went wrong on server.",
        );

        return 501;
      }

      else if (response.statusCode == 401) {
        print("Unauthorized.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Unauthorized.",
        );

        return 401;
      }

      else if (response.statusCode == 403) {
        print("Admin access required.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Admin access required.",
        );

        return 403;
      }

      else {
        print(
          "Unexpected Status Code: ${response.statusCode}",
        );

        print(
          "Unexpected Response: ${response.body}",
        );

        Toast.Toastmsg(
          "Failed to add service.",
        );

        return response.statusCode;
      }
    }
    catch (obj) {
      print("========== ADD SERVICE ERROR ==========");
      print("Exception: ${obj.toString()}");

      Toast.Toastmsg(
        "Something went wrong.",
      );

      return 501;
    }
  }

  Future<int> DeleteService({
    required String User_JwtToken,
    required int ServiceId,
  }) async {
    try {
      print("========== DELETE SERVICE ==========");


      final Map<String, dynamic> data = {
        "ServiceId": ServiceId,
      };

      print("Request Data: $data");

      final response = await http.delete(
        Uri.parse(
          "${Backend_Server_Url}api/Admin/deleteservice",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $User_JwtToken",
        },
        body: jsonEncode(data),
      );



      if (response.statusCode == 200) {
        print("Service deleted successfully.");

        Toast.Toastmsg(
          "Service deleted successfully.",
        );

        return 200;
      }

      else if (response.statusCode == 502) {
        print("Service not present with that ID.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Service not present with that ID.",
        );

        return 502;
      }

      else if (response.statusCode == 500) {
        print("Service data is not in correct format.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Data are not in correct format.",
        );

        return 500;
      }

      else if (response.statusCode == 501) {
        print("Server exception.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Something went wrong on server.",
        );

        return 501;
      }

      else if (response.statusCode == 401) {
        print("Unauthorized.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Unauthorized.",
        );

        return 401;
      }

      else if (response.statusCode == 403) {
        print("Admin access required.");
        print("Server Message: ${response.body}");

        Toast.Toastmsg(
          "Admin access required.",
        );

        return 403;
      }

      else {
        print(
          "Unexpected Status Code: ${response.statusCode}",
        );

        print(
          "Unexpected Response: ${response.body}",
        );

        Toast.Toastmsg(
          "Failed to delete service.",
        );

        return response.statusCode;
      }
    }
    catch (obj) {
      print("========== DELETE SERVICE ERROR ==========");
      print("Exception: ${obj.toString()}");

      Toast.Toastmsg(
        "Something went wrong.",
      );

      return 501;
    }
  }

  // ============================================================
  // BUILD — visual redesign only, plus the requested live search
  // filter. Every onPressed body below is the exact original
  // logic, just wrapped in new UI containers.
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final cardMaxWidth = min(size.width * 0.94, 620.0);
    final horizontalPad = size.width < 420 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: _Palette.bodyBg,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // ---- ambient organic bubble background ----
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bubbleCtrl,
              builder: (context, _) => CustomPaint(
                painter: _BubblePainter(progress: _bubbleCtrl.value),
              ),
            ),
          ),

          // ---- main responsive scroll content ----
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: orientation == Orientation.portrait ? 26 : 14,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: max(
                        0.0,
                        constraints.maxHeight -
                            (orientation == Orientation.portrait ? 52 : 28),
                      ),
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildScreenHeader(),
                                const SizedBox(height: 22),

                                _buildSectionCard(
                                  icon: Icons.search_rounded,
                                  title: "Search Services",
                                  subtitle: "Type any part of a service name to filter — matching is case-insensitive.",
                                  child: _buildSearchSection(),
                                ),
                                const SizedBox(height: 16),

                                _buildSectionCard(
                                  icon: Icons.add_business_rounded,
                                  title: "Add New Service",
                                  subtitle: "Register a new service with pricing.",
                                  child: _buildAddServiceSection(),
                                ),
                                const SizedBox(height: 16),

                                _buildSectionCard(
                                  icon: Icons.tune_rounded,
                                  title: "Manage Existing Service",
                                  subtitle: "Delete a service or update its price by ID.",
                                  child: _buildManageServiceSection(),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
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

  // ---------------------------------------------------------
  // App bar — bordered, clearly visible back arrow
  // ---------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _Palette.headerFooter,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Palette.primaryText, width: 1.4),
                  color: _Palette.surface,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: _Palette.primaryText,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        "Add/Delete services.",
        style: TextStyle(
          color: _Palette.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _Palette.borderColor),
      ),
    );
  }

  // ---------------------------------------------------------
  // Screen header badge + title
  // ---------------------------------------------------------
  Widget _buildScreenHeader() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: 0.7 + (0.3 * value), child: child),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_Palette.accent, _Palette.accentMint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _Palette.accent.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.design_services_rounded, color: _Palette.bodyBg, size: 28),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Manage Services",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _Palette.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Search, add, delete and reprice services\nfrom one place.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _Palette.mutedText, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Reusable glass-style section card
  // ---------------------------------------------------------
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: _Palette.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    colors: [
                      _Palette.accent.withOpacity(0.22),
                      _Palette.accentMint.withOpacity(0.16),
                    ],
                  ),
                  border: Border.all(color: _Palette.borderColor),
                ),
                child: Icon(icon, color: _Palette.accentMint, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _Palette.primaryText,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _Palette.mutedText, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Search section — new feature: live substring match on
  // Service ID (e.g. "5" matches 5, 56, 500, 501, ...).
  // Data fetching logic (GetRegisterServiceInfo) is untouched;
  // only the rendered list is filtered, and only the filtered
  // list rebuilds on each keystroke (via the inner Obx) so the
  // API is not re-called while typing.
  // ---------------------------------------------------------
  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextInput(
          controller: SearchServiceNameTextCont,
          label: "Search by service name",
          icon: Icons.search,
          focusedRx: ServiceCont.searchFocused,
          onFocusChange: (v) => ServiceCont.searchFocused.value = v,
        ),
        const SizedBox(height: 14),
        Obx(() {
          // Reading refreshTick here (without using its value) makes
          // this Obx rebuild — and re-run GetRegisterServiceInfo() —
          // whenever Add/Delete/Update bumps it. Independent from the
          // search filter's own Obx below, so typing never refetches.
          ServiceCont.refreshTick.value;

          return FutureBuilder<void>(
            future: GetRegisterServiceInfo(),
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildMediaFrame(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(_Palette.accentMint),
                      ),
                    ),
                  ),
                );
              }

              // Future completed with error
              if (snapshot.hasError) {
                print("FutureBuilder Error: ${snapshot.error}");

                return _buildMediaFrame(
                  child: _buildEmptyMessage("Something went wrong while loading services."),
                );
              }

              // No service information
              if (RegisterSearchlList.isEmpty) {
                return _buildMediaFrame(
                  child: _buildEmptyMessage("No services available."),
                );
              }

              // Service information — filtered reactively by service name
              return Obx(() {
                final query = ServiceCont.searchQuery.value.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? RegisterSearchlList
                    : RegisterSearchlList
                    .where((s) => (s.serviceName ?? "").toLowerCase().contains(query))
                    .toList();

                if (filtered.isEmpty) {
                  return _buildMediaFrame(
                    child: _buildEmptyMessage("No service matches that name."),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < filtered.length; i++) ...[
                      _buildServiceCard(filtered[i]),
                      if (i != filtered.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildServiceCard(AdminRegSerInfoModel service) {
    final String serviceName =
    service.serviceName?.trim().isNotEmpty == true
        ? service.serviceName!.trim()
        : "Service name not available";

    final String serviceDescription =
    service.serviceDescription?.trim().isNotEmpty == true
        ? service.serviceDescription!.trim()
        : "No description available";

    final String domesticPrice =
    service.domesticPrice != null
        ? service.domesticPrice.toString()
        : "Not available";

    final String domesticDiscount =
    service.domesticPriceDiscount != null
        ? service.domesticPriceDiscount.toString()
        : "Not available";

    final String internationalPrice =
    service.internationalPrice != null
        ? service.internationalPrice.toString()
        : "Not available";

    final String internationalDiscount =
    service.internationalPriceDiscount != null
        ? service.internationalPriceDiscount.toString()
        : "Not available";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.headerFooter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  serviceName,
                  style: const TextStyle(
                    color: _Palette.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (service.serviceId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _Palette.accent.withOpacity(0.14),
                    border: Border.all(color: _Palette.borderColor),
                  ),
                  child: Text(
                    "ID ${service.serviceId}",
                    style: const TextStyle(
                      color: _Palette.accentMint,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            serviceDescription,
            style: const TextStyle(color: _Palette.mutedText, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPriceBlock(
                  label: "Domestic",
                  price: domesticPrice,
                  discount: domesticDiscount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceBlock(
                  label: "International",
                  price: internationalPrice,
                  discount: internationalDiscount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBlock({
    required String label,
    required String price,
    required String discount,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.borderColor.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _Palette.accentMint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Price: $price",
            style: const TextStyle(color: _Palette.primaryText, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            "Discount: $discount",
            style: const TextStyle(color: _Palette.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Add new service — logic identical to original onPressed body
  // ---------------------------------------------------------
  Widget _buildAddServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextInput(
          controller: NewServiceNameTextCont,
          label: "Enter the service name.",
          icon: Icons.design_services_rounded,
          focusedRx: ServiceCont.newServiceNameFocused,
          onFocusChange: (v) => ServiceCont.newServiceNameFocused.value = v,
        ),
        const SizedBox(height: 12),
        _buildTextInput(
          controller: ServiceDescpTextCont,
          label: "Enter the service description.",
          icon: Icons.description,
          focusedRx: ServiceCont.serviceDescFocused,
          onFocusChange: (v) => ServiceCont.serviceDescFocused.value = v,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextInput(
                controller: DomesticPriceTextCont,
                label: "Domestic price",
                icon: Icons.price_check,
                focusedRx: ServiceCont.domesticPriceFocused,
                onFocusChange: (v) => ServiceCont.domesticPriceFocused.value = v,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextInput(
                controller: DomesticPriceDiscountTextCont,
                label: "Domestic discount %",
                icon: Icons.price_check,
                focusedRx: ServiceCont.domesticDiscountFocused,
                onFocusChange: (v) => ServiceCont.domesticDiscountFocused.value = v,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextInput(
                controller: InternationalPriceTextCont,
                label: "International price",
                icon: Icons.price_check,
                focusedRx: ServiceCont.internationalPriceFocused,
                onFocusChange: (v) => ServiceCont.internationalPriceFocused.value = v,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextInput(
                controller: InternationalPriceDiscountTextCont,
                label: "International discount %",
                icon: Icons.price_check,
                focusedRx: ServiceCont.internationalDiscountFocused,
                onFocusChange: (v) => ServiceCont.internationalDiscountFocused.value = v,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() => _buildPrimaryButton(
          label: "Add new service.",
          icon: Icons.add_circle_outline_rounded,
          loading: ServiceCont.isAddingService.value,
          onTap: () async {
            if (ServiceCont.isAddingService.value) return;
            ServiceCont.isAddingService.value = true;
            try{
              if(
              NewServiceNameTextCont.text.trim().isEmptyOrNull ||
                  ServiceDescpTextCont.text.trim().isEmptyOrNull ||
                  DomesticPriceTextCont.text.trim().isEmptyOrNull ||
                  DomesticPriceDiscountTextCont.text.trim().isEmptyOrNull ||
                  InternationalPriceTextCont.text.trim().isEmptyOrNull ||
                  InternationalPriceDiscountTextCont.text.trim().isEmptyOrNull
              )
              {
                Toast.Toastmsg("All fields are required.");
                return;
              }

              double? DomesticPriceDiscount=double.tryParse(DomesticPriceDiscountTextCont.text.trim());
              double? InternationalPriceDiscount=double.tryParse(InternationalPriceDiscountTextCont.text.trim());
              double? DomesticPrice=double.tryParse(DomesticPriceTextCont.text.trim());
              double? InternationalPrice=double.tryParse(InternationalPriceTextCont.text.trim());


              int AddServiceResult=await AddService(
                  User_JwtToken: widget.User_JwtToken,
                  ServiceName: NewServiceNameTextCont.text.trim().toLowerCase(),
                  ServiceDescription:ServiceDescpTextCont.text.trim(),
                  DomesticPrice: DomesticPrice!,
                  DomesticPriceDiscount: DomesticPriceDiscount!,
                  InternationalPrice: InternationalPrice!,
                  InternationalPriceDiscount: InternationalPriceDiscount!
              );

              // ---- New feature: refresh the service list on success ----
              if (AddServiceResult == 200) {
                ServiceCont.refreshTick.value++;
              }

            }catch(obj){
              print(obj.toString());
              return;
            } finally {
              ServiceCont.isAddingService.value = false;
            }
          },
        )),
      ],
    );
  }

  // ---------------------------------------------------------
  // Manage existing service (delete + update price) — logic
  // identical to the original two onPressed bodies.
  // ---------------------------------------------------------
  Widget _buildManageServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextInput(
          controller: ServiceIdTextCont,
          label: "Enter the service id.",
          icon: Icons.design_services,
          focusedRx: ServiceCont.serviceIdFocused,
          onFocusChange: (v) => ServiceCont.serviceIdFocused.value = v,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        Obx(() => _buildPrimaryButton(
          label: "Delete service.",
          icon: Icons.delete_forever_rounded,
          danger: true,
          loading: ServiceCont.isDeletingService.value,
          onTap: () async {
            if (ServiceCont.isDeletingService.value) return;
            ServiceCont.isDeletingService.value = true;
            try{

              if(ServiceIdTextCont.text.trim().isEmptyOrNull){
                Toast.Toastmsg("Service id is required.");
                return;
              }
              int ServiceId=int.tryParse(ServiceIdTextCont.text.trim())!;

              int DeleteServiceResult=await DeleteService(
                  User_JwtToken:widget.User_JwtToken,
                  ServiceId:ServiceId
              );

              // ---- New feature: refresh the service list on success ----
              if (DeleteServiceResult == 200) {
                ServiceCont.refreshTick.value++;
              }

            }catch(obj){
              print(obj.toString());
              return;
            } finally {
              ServiceCont.isDeletingService.value = false;
            }
          },
        )),
        const SizedBox(height: 18),
        _buildDivider(),
        const SizedBox(height: 14),
        const Text(
          "For update price service id and all 4 price field are mandatory.",
          style: TextStyle(color: _Palette.mutedText, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 14),
        Obx(() => _buildPrimaryButton(
          label: "Update service price.",
          icon: Icons.sync_alt_rounded,
          loading: ServiceCont.isUpdatingPrice.value,
          onTap: () async {
            if (ServiceCont.isUpdatingPrice.value) return;
            ServiceCont.isUpdatingPrice.value = true;
            try{

              if(
              ServiceIdTextCont.text.trim().isEmptyOrNull ||
                  DomesticPriceTextCont.text.trim().isEmptyOrNull ||
                  DomesticPriceDiscountTextCont.text.trim().isEmptyOrNull ||
                  InternationalPriceTextCont.text.trim().isEmptyOrNull ||
                  InternationalPriceDiscountTextCont.text.trim().isEmptyOrNull

              ){
                Toast.Toastmsg("Service id and all 4 price is required.");
                return;
              }

              int ServiceId=int.tryParse(ServiceIdTextCont.text.trim())!;

              double? DomesticPriceDiscount=double.tryParse(DomesticPriceDiscountTextCont.text.trim());
              double? InternationalPriceDiscount=double.tryParse(InternationalPriceDiscountTextCont.text.trim());
              double? DomesticPrice=double.tryParse(DomesticPriceTextCont.text.trim());
              double? InternationalPrice=double.tryParse(InternationalPriceTextCont.text.trim());

              int UpdateServiceResult=await UpdateServicePrice(
                  User_JwtToken:widget.User_JwtToken,
                  ServiceId:ServiceId,
                  DomesticPrice: DomesticPrice!,
                  DomesticPriceDiscount: DomesticPriceDiscount!,
                  InternationalPrice: InternationalPrice!,
                  InternationalPriceDiscount: InternationalPriceDiscount!
              );

              // ---- New feature: refresh the service list on success ----
              if (UpdateServiceResult == 200) {
                ServiceCont.refreshTick.value++;
              }

            }catch(obj){
              print(obj.toString());
              return;
            } finally {
              ServiceCont.isUpdatingPrice.value = false;
            }
          },
        )),
        const SizedBox(height: 6),
        Text(
          "Uses the Domestic / International price fields above in \"Add New Service\".",
          style: TextStyle(color: _Palette.mutedText.withOpacity(0.8), fontSize: 11, height: 1.3),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: _Palette.borderColor);
  }

  // ============================================================
  // SHARED UI HELPERS
  // ============================================================

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required RxBool focusedRx,
    required ValueChanged<bool> onFocusChange,
    TextInputType? keyboardType,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: Obx(() {
        final focused = focusedRx.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? _Palette.accentMint : _Palette.borderColor,
              width: focused ? 1.6 : 1,
            ),
            boxShadow: focused
                ? [
              BoxShadow(
                color: _Palette.accentMint.withOpacity(0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ]
                : [],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: _Palette.primaryText, fontSize: 14.5),
            cursorColor: _Palette.accentMint,
            decoration: InputDecoration(
              filled: true,
              fillColor: _Palette.headerFooter,
              labelText: label,
              labelStyle: TextStyle(
                color: focused ? _Palette.accentMint : _Palette.mutedText,
                fontSize: 12.5,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  color: focused ? _Palette.accentMint : _Palette.mutedText,
                  size: 18,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool outlined = false,
    bool danger = false,
    bool loading = false,
  }) {
    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: outlined
                  ? null
                  : LinearGradient(
                colors: danger
                    ? [const Color(0xFFEF4444), const Color(0xFFF87171)]
                    : const [_Palette.accent, _Palette.accentMint],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              color: outlined ? _Palette.surface : null,
              border: outlined ? Border.all(color: _Palette.borderColor) : null,
              boxShadow: outlined
                  ? []
                  : [
                BoxShadow(
                  color: (danger ? const Color(0xFFEF4444) : _Palette.accent)
                      .withOpacity(0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(_Palette.bodyBg),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: outlined ? _Palette.accentMint : _Palette.bodyBg,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: outlined ? _Palette.primaryText : _Palette.bodyBg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaFrame({required Widget child}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _Palette.headerFooter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.borderColor),
      ),
      child: child,
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, color: _Palette.mutedText, size: 24),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _Palette.mutedText, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Ambient organic bubble / blob background painter.
// Soft, low-opacity, heavily blurred shapes with extremely slow
// drift — purely decorative, never intercepts touch input.
// ============================================================
class _BubblePainter extends CustomPainter {
  final double progress; // 0..1 looping

  _BubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final blobs = <_BlobSpec>[
      _BlobSpec(rx: -0.08, ry: 0.05, radius: w * 0.42, color: _Palette.accent, speed: 0.6, opacity: 0.10, blur: 90),
      _BlobSpec(rx: 1.05, ry: 0.10, radius: w * 0.34, color: _Palette.accentMint, speed: -0.5, opacity: 0.08, blur: 80),
      _BlobSpec(rx: 0.92, ry: 0.55, radius: w * 0.30, color: _Palette.accent, speed: 0.4, opacity: 0.07, blur: 70),
      _BlobSpec(rx: 0.06, ry: 0.62, radius: w * 0.28, color: _Palette.accentMint, speed: -0.35, opacity: 0.07, blur: 75),
      _BlobSpec(rx: 0.55, ry: 0.95, radius: w * 0.36, color: _Palette.accent, speed: 0.5, opacity: 0.09, blur: 85),
      _BlobSpec(rx: 0.35, ry: 0.30, radius: w * 0.14, color: _Palette.accentMint, speed: 0.8, opacity: 0.05, blur: 40),
      _BlobSpec(rx: 0.78, ry: 0.78, radius: w * 0.10, color: _Palette.accent, speed: -0.9, opacity: 0.05, blur: 35),
    ];

    for (final b in blobs) {
      final dx = sin(progress * 2 * pi * b.speed) * w * 0.015;
      final dy = cos(progress * 2 * pi * b.speed) * h * 0.012;
      final center = Offset(b.rx * w + dx, b.ry * h + dy);

      final paint = Paint()
        ..color = b.color.withOpacity(b.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.blur);

      canvas.drawCircle(center, b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BlobSpec {
  final double rx;
  final double ry;
  final double radius;
  final Color color;
  final double speed;
  final double opacity;
  final double blur;

  _BlobSpec({
    required this.rx,
    required this.ry,
    required this.radius,
    required this.color,
    required this.speed,
    required this.opacity,
    required this.blur,
  });
}