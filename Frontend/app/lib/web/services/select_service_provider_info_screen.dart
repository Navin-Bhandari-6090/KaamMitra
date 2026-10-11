
import 'dart:convert';

import 'package:app/web/common%20widget/GreenTextfield.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:app/web/services/services_provider_service_select.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../constant/Server_Database.dart';
import '../../models/ServiceScreenServiceModel.dart';
import '../../models/Service_Screen_User_Info_Model.dart';
import '../../state management/getx/services/select_service_provider_info_screen_getx.dart';
import '../authentication/Error_page.dart';
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

  const SelectServiceProviderInfoScreen(
      {super.key,
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
        required this.ServiceId, required this.ProRegServiceDescription
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

  final UserBookingDescriptionTextCont=TextEditingController();

  final Toast=Toastget();

  @override
  void initState()
  {
    super.initState();
    Provider_User_Jwt_Verify(Jwt_Token: widget.Current_User_JwtToken, context: context);
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
  void dispose()
  {
    _entranceController.dispose();
    super.dispose();
  }


  Future<bool> _confirmBooking() async {
    try {
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
                const Icon(Icons.event_available_rounded,
                    color: _Theme.mint),
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
              "You are about to book \"${widget.Provider_Service_Name}\" "
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
    } catch (obj) {
      print(obj.toString());
      return false;
    }
  }



  ServiceScreenUserInfoModel? get _provider
  {

    for (final p in widget.Provider_info_List)
    {
      if (p.userNumber == widget.Providernumber) return p;
    }
    return null;

  }

  List<ServiceScreenServiceModel> get _providerServices
  {

    return widget.Service_info_List
        .where((s) => s.userNumber == widget.Providernumber)
        .toList();

  }

  /// Same pattern as the profile screen's GetPhotoUrl — builds a full
  /// image URL from a stored relative photo path.
  String GetPhotoUrl(String photoPath)
  {
    if (photoPath.isEmpty) {
      return "";
    }

    final baseUrl = Backend_Server_Url.endsWith("/")
        ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
        : Backend_Server_Url;

    final path = photoPath.startsWith("/") ? photoPath : "/$photoPath";

    return "$baseUrl$path";
  }


  Future<int> AddBookingInfo(
      {
    required String Current_User_JwtToken,
    required double Distance,
    required num ProviderNumber,
    required String ServiceName,
    required bool ProviderApprovalStatus,
    required bool  ProviderTaskCompleteStatus,
    required bool  UserTaskCompleteStatus,
    required bool UserApprovalStatus,
    required String UserBookingDescription,
    required num ServiceId,
  }
  ) async {
    try {
      final Map<String, dynamic> userData = {
        "UserBookingDescription": UserBookingDescription,
        "Distance": Distance,
        "ServiceName": ServiceName,
        "ProviderApprovalStatus": ProviderApprovalStatus,
        "ProviderTaskCompleteStatus": ProviderTaskCompleteStatus,
        "UserTaskCompleteStatus":UserTaskCompleteStatus,
        "UserApprovalStatus":UserApprovalStatus,
        "ServiceId":ServiceId,
        "ProviderNumber":ProviderNumber
      };
      const String url = Backend_Server_Url + "api/Service/addbookinginfo";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.Current_User_JwtToken}'
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200)
      {
        print("Add booking info success");
        Toast.Toastmsg("Booking success.");
        return 1;
      }
      else if (response.statusCode == 500)
      {
        Toast.Toastmsg("Booking fail.Try again.Server error.");
        print("Booking fail.Try again.Server error.");
        return 2;
      }
      else if (response.statusCode == 502)
      {
        Toast.Toastmsg("Current user doesn't match.");
        print("Current user doesn't match.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return 3;
      }
      else if (response.statusCode == 503)
      {
        Toast.Toastmsg("Provide doesn't match.Choose different provider.");
        print("Provide doesn't match.Choose different provider.");

        return 4;
      }
      else if (response.statusCode == 501)
      {
        Toast.Toastmsg("Invalid data format.Please provide data in correct format.");
        print("Invalid data format.Please provide data in correct format.");
        return 5;
      }
      else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg("Booking fail.Try again.Server error.");
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while adding booking info.");
      print(Obj.toString());
      Toast.Toastmsg("Booking fail.Try again.Server error.");
      return 7;
    }
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

    final String firstName = provider?.firstName ?? "";
    final String lastName = provider?.lastName ?? "";
    final String fullName = "$firstName $lastName".trim();
    final String phone = provider?.phoneNumber ?? "";
    final String whatsapp = provider?.whatsappPhoneNumber ?? "";
    final String photoUrl = GetPhotoUrl(provider?.photo ?? "");

    return Scaffold(
      backgroundColor: _Theme.bgTop,
      body: Stack(

        children:

        [
          // ====================================================
          // FIXED FULL-HEIGHT BACKGROUND — base gradient + soft
          // ambient bubbles that stay put behind the scrolling
          // content, always covering the full device height.
          // ====================================================
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

          // ====================================================
          // CONTENT
          // ====================================================
          SafeArea(
            child: LayoutBuilder(
              builder: (context, outerConstraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: outerConstraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                        BoxConstraints(maxWidth: contentMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: isMobile ? 20 : 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ========================================
                              // BACK ROW
                              // ========================================
                              _buildBackRow(context, isMobile),

                              SizedBox(height: isMobile ? 20 : 28),

                              if (provider == null)
                                _notFoundCard()
                              else ...[
                                // ====================================
                                // HERO — avatar, name, contact chips
                                // ====================================
                                _animatedSection(
                                  animation: _heroAnim,
                                  child: _buildHero(
                                    isMobile: isMobile,
                                    fullName: fullName,
                                    phone: phone,
                                    whatsapp: whatsapp,
                                    photoUrl: photoUrl,
                                  ),
                                ),

                                SizedBox(height: isMobile ? 18 : 24),

                                // ====================================
                                // STATS — distance, rating, services count
                                // ====================================
                                _animatedSection(
                                  animation: _statsAnim,
                                  child: _buildStatsRow(
                                    isMobile: isMobile,
                                    serviceCount: services.length,
                                  ),
                                ),

                                SizedBox(height: isMobile ? 18 : 24),

                                // ====================================
                                // SERVICES OFFERED
                                // ====================================
                                _animatedSection(
                                  animation: _servicesAnim,
                                  child: _buildServicesCard(
                                      isMobile: isMobile, services: services),
                                ),

                                SizedBox(height: isMobile ? 22 : 28),

                                Text("Please describe all the details of the service you want to book.You cannot update later on.",style: TextStyle(
                                  color: Colors.red
                                ),),

                                SizedBox(height: isMobile ? 22 : 28),

                                  GreenField(controller: UserBookingDescriptionTextCont,
                                      label: "Enter all the details that you need.",
                                      icon: Icons.info,
                                    keyboardType: TextInputType.multiline,
                                    obscure: false,
                                    height: 100,
                                  ),

                                SizedBox(height: isMobile ? 22 : 28),

                                // ====================================
                                // ACTIONS — gallery + book
                                // ====================================
                                _animatedSection(
                                  animation: _actionsAnim,
                                  child: _buildActions(isMobile),
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
        shape: BoxShape.circle,
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
  // NOT FOUND (defensive — provider absent from Provider_info_List)
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
          Text(
            "We couldn't find profile details for this provider.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _Theme.mutedText, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO — avatar + name + contact chips
  // ============================================================

  Widget _buildHero({
    required bool isMobile,
    required String fullName,
    required String phone,
    required String whatsapp,
    required String photoUrl,
  }) {
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
          print("photo url");
          print(photoUrl);
          final avatar = Container(
            height: 96,
            width: 96,
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
              height: 78,
              width: 78,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
              child: ClipOval(
                child: Container(
                  color: _Theme.surface,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person_rounded,
                      color: _Theme.mint, size: 34)
                      : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress)
                    {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: _Theme.emerald,
                          strokeWidth: 2.2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("Provider image loading failed: $error");
                      return const Icon(Icons.person_rounded,
                          color: _Theme.mint, size: 34);
                    },
                  ),
                ),
              ),
            ),
          );

          final info = Column(
            crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _Theme.emerald.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: _Theme.emerald.withOpacity(0.20)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: _Theme.mint, size: 14),
                    SizedBox(width: 7),
                    Text(
                      "Verified provider",
                      style: TextStyle(
                        color: _Theme.mint,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                fullName.isEmpty ? "Service provider" : fullName,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: _Theme.primaryText,
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              // const SizedBox(height: 12),

              //contact info
              // Wrap(
              //   alignment:
              //   compact ? WrapAlignment.center : WrapAlignment.start,
              //   spacing: 10,
              //   runSpacing: 10,
              //   children: [
              //     if (phone.isNotEmpty)
              //       _contactChip(Icons.call_rounded, "Phone Number : ${phone}"),
              //     if (whatsapp.isNotEmpty)
              //       _contactChip(Icons.chat_rounded, "Whatsapp : ${whatsapp}"),
              //   ],
              // ),

              const SizedBox(height: 12),
              Text(
                widget.Provider_Service_Name.isEmpty ? "Service provider name not found" : widget.Provider_Service_Name,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: _Theme.primaryText,
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Provider Description:${widget.ProRegServiceDescription.isEmpty ? "Service description from provider not found" : widget.ProRegServiceDescription}",
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: _Theme.primaryText,
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
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

  Widget _contactChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _Theme.surfaceBar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _Theme.mint, size: 15),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: _Theme.primaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS ROW — distance, rating, service count
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
            value: "${widget.Distance.toStringAsFixed(1)} km",
          ),
          _statCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFBBF24),
            label: "Rating",
            value: widget.Rating > 0
                ? widget.Rating.toStringAsFixed(1)
                : "New",
            trailing: widget.Rating > 0
                ? _starRow(fullStars, hasHalfStar)
                : null,
          ),
          _statCard(
            icon: Icons.design_services_rounded,
            label: "Services",
            value: "$serviceCount",
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
        return Icon(icon, color: const Color(0xFFFBBF24), size: 13);
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
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: _Theme.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
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
  // SERVICES OFFERED
  // ============================================================

  Widget _buildServicesCard({
    required bool isMobile,
    required List<ServiceScreenServiceModel> services,
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
                child: const Icon(Icons.engineering_rounded,
                    color: _Theme.mint, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Services offered",
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
          if (services.isEmpty)
            Text(
              "No services listed yet.",
              style: TextStyle(color: _Theme.mutedText, fontSize: 12.5),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: services.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: _Theme.surfaceBar,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _Theme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: _Theme.mint, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        s.serviceName ?? "Service",
                        style: const TextStyle(
                          color: _Theme.primaryText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS — My gallery + Book
  // ============================================================

  Widget _buildActions(bool isMobile) {
    final galleryButton = _actionButton(
      icon: Icons.photo_library_rounded,
      label: "My gallery",
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
      onTap: () async
      {

        if(widget.Current_User_Role.trim().toLowerCase()=="provider")
        {
          Toast.Toastmsg("Please register as user and book services.");
          return;
        }

        if(UserBookingDescriptionTextCont.text.trim().isEmptyOrNull)
        {
          Toast.Toastmsg("User description is empty.Provide the description.");
          return;
        }

        final bool confirmed = await _confirmBooking();
        if (!confirmed) return;

        final AddBookingResult=await AddBookingInfo(
            Current_User_JwtToken: widget.Current_User_JwtToken,
            Distance: widget.Distance,
            ServiceName: widget.Provider_Service_Name,
            ProviderApprovalStatus: false,
            UserApprovalStatus: true,
          ProviderTaskCompleteStatus: false,
          UserTaskCompleteStatus: false,
          UserBookingDescription: UserBookingDescriptionTextCont.text.trim(),
          ServiceId:widget.ServiceId,
          ProviderNumber: widget.Providernumber,
        );

          final AddNotificationsResult=await AddNotifications(
              ReceiverNumber: widget.Providernumber,
              Message: "You have been booked by ${widget.Current_User_Email} for ${widget.Provider_Service_Name}.",
              Current_User_JwtToken: widget.Current_User_JwtToken,
              context: context
          );

              final AddNewNotificationsResult= await AddNewNotifications(
                  ReceiverNumber: widget.Providernumber,
                  Status: true,
                  Current_User_JwtToken: widget.Current_User_JwtToken,
                  context: context
              );

      },
    );

    if (isMobile)
    {
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
}