import 'dart:convert';

import 'package:app/web/footer/Footer.dart';
import 'package:flutter/material.dart';
import 'package:app/web/header/Header.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';
import '../../constant/Server_Database.dart';
import '../../constant/variable.dart';
import '../../models/AdvertisementInfoModel.dart';
import '../../models/FooterInfosModel.dart';
import '../authentication/Error_page.dart';
import '../authentication/Login.dart';
import '../common method/Commmon_Method.dart';
import '../communi_services/services.dart';
import '../communication/chat/chat_screen.dart';


class HomeScreenUi extends StatefulWidget
{

  final bool UserLogin;
  final String User_JwtToken;

  const HomeScreenUi({
    super.key,
    required this.UserLogin,
    required this.User_JwtToken,
  });

  @override
  State<HomeScreenUi> createState() => _HomeScreenUiState();
}

class _HomeScreenUiState extends State<HomeScreenUi>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final SignalRService SignalR =
  Get.put(SignalRService(), permanent: true);


  @override
  void initState()
  {
    super.initState();
    widget.UserLogin == true
        ? Provider_User_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context)
        : Random_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);

    if(widget.UserLogin){

      ConnectSignalR();
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> ConnectSignalR() async {
    try {
      final box = Hive.box('User_Data');

      final String User_JwtToken =
      box.get('jwt_token', defaultValue: '').toString();

      if (User_JwtToken.isEmpty) {
        print("SignalR: JWT token is missing.");
        return;
      }

      await SignalR.ConnectSignalR(
        User_JwtToken: User_JwtToken,
      );
    } catch (e) {
      print("HomeScreen SignalR error: $e");
    }
  }

  List<FooterInfosModel> FooterInfosList=[];

  Future<void> GetFooterInfos({
    required String jwttoken,
  }) async {
    try {
      final String url =
          Backend_Server_Url + "api/Home/getfooterinfo";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
      );



      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Clear old data before adding new data
        FooterInfosList.clear();

        // Backend returns a single object because the table has only one row
        FooterInfosList.add(
          FooterInfosModel.fromJson(data),
        );

        // print("Footer information loaded successfully.");
      } else if (response.statusCode == 400) {
        // Toast.Toastmsg("Data are not in correct format.");
        // print("Footer info request returned 400.");
      } else if (response.statusCode == 401) {
        // Toast.Toastmsg("Unauthorized access.");
        // print("Footer info request returned 401.");
     Logout(context: context);
      } else if (response.statusCode == 403) {
        // Toast.Toastmsg("You do not have permission to access footer information.");
        // print("Footer info request returned 403.");
      } else if (response.statusCode == 404) {
        // Toast.Toastmsg("Footer information not found.");
        // print("Footer information not found.");
      } else if (response.statusCode == 502) {
        // Toast.Toastmsg("User not found.");
        // print("User not found.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toast.Toastmsg("Session End.Relogin please.");
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by the system. Please contact the KaamMitra community.",
        );
        print("User has been blocked.");
    Logout(context: context);

      } else if (response.statusCode == 500) {
        // Toast.Toastmsg(
        //   "Something went wrong while getting footer information.",
        // );
        // print("Server error while getting footer information.");
      } else {
        // Toast.Toastmsg("Something went wrong.");
        // print("Unexpected status code: ${response.statusCode}");
      }
    } catch (e) {
      // Toast.Toastmsg("Something went wrong.");
      // print("========== GET FOOTER INFO ERROR ==========");
      // print(e);

      return;
    }
  }

  List<AdvertisementInfoModel> AdvertisementInfosList=[];

  Future<void> GetAllAdvertisementInfos({
    required String jwttoken,
  }) async {
    try {
      const String url =
          Backend_Server_Url + "api/Admin/getalladvertisementinfos";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        AdvertisementInfosList.clear();

        AdvertisementInfosList.addAll(
          data.map(
                (json) => AdvertisementInfoModel.fromJson(json),
          ),
        );

        // print("Advertisement count: ${AdvertisementInfosList.length}");
      } else if (response.statusCode == 400) {
        // Toast.Toastmsg(
        //   "Data are not in correct format.",
        // );
      } else if (response.statusCode == 401) {
        Toast.Toastmsg(
          "Unauthorized access.",
        );
 Logout(context: context);
      } else if (response.statusCode == 403) {
        // Toast.Toastmsg(
        //   "You do not have permission to access advertisements.",
        // );
      } else if (response.statusCode == 404) {
        // Toast.Toastmsg(
        //   "No advertisement information is present.",
        // );
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by the system. Please contact the KaamMitra community.",
        );
      Logout(context: context);

      } else if (response.statusCode == 500) {
        // Toast.Toastmsg(
        //   "Something went wrong while getting advertisement information.",
        // );
      } else {
        // Toast.Toastmsg(
        //   "Something went wrong.",
        // );
      }
    } catch (e) {
      // print("========== GET ADVERTISEMENT ERROR ==========");
      // print(e);

      // Toast.Toastmsg(
      //   "Something went wrong.",
      // );
    }
  }




  // ------------------------------------------------------------
  // COLORS
  // ------------------------------------------------------------

  static const Color deepForest = Color(0xFF0F1F17);
  static const Color headerGreen = Color(0xFF12261C);
  static const Color cardGreen = Color(0xFF162E22);
  static const Color borderGreen = Color(0xFF234232);

  static const Color primaryText = Color(0xFFE6F4EA);
  static const Color mutedText = Color(0xFF8A9A90);

  static const Color emerald = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepForest,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // <-- key change
                  children: [
                    Column(
                      children: [

                        Header(
                          UserLogin: widget.UserLogin,
                          User_JwtToken: widget.User_JwtToken,
                        ),

                        SizedBox(height: 10,),

                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await GetFooterInfos(
                                jwttoken: widget.User_JwtToken,
                              );

                              await GetAllAdvertisementInfos(
                                jwttoken: widget.User_JwtToken,
                              );
                            } catch (e) {
                              print(e.toString());
                            }
                          },
                          child: const Text("Test Get Footer & Advertisement"),
                        ),

                        SizedBox(height: 10,),

                        FadeTransition
                          (
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildHomeBody(),
                          ),
                        ),
                      ],
                    ),

                    Footer(),

                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  // HOME BODY


  Widget _buildHomeBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        final bool isMobile = screenWidth < 600;
        final bool isTablet = screenWidth >= 600 && screenWidth < 1000;

        final double horizontalPadding = isMobile
            ? 18
            : isTablet
            ? 32
            : 60;

        final double contentMaxWidth = screenWidth > 1400
            ? 1280
            : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),

            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 24 : 40,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // LOGIN NOTICE


                  if (!widget.UserLogin) _buildLoginNotice(),

                  if (!widget.UserLogin) const SizedBox(height: 24),


                  // WELCOME / HERO

                  _buildHeroSection(),

                  const SizedBox(height: 32),

                  if (widget.UserLogin) ElevatedButton(onPressed: ()async{

                    final box =
                    await Hive.openBox('User_Data');

                    int? User_Number =
                    box.get('user_number');



                    Navigator.push(
                      context,
                      MaterialPageRoute
                        (
                        builder: (context) =>
                            ChatScreen(User_JwtToken: widget.User_JwtToken, CurrentUserNumber:User_Number!),
                            ),
                      );

                  }, child: Text("Communicate with people.")),

                  const SizedBox(height: 32),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LOGIN NOTICE
  // ============================================================

  Widget _buildLoginNotice() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFF183526),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: emerald.withOpacity(0.25)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Container(
            height: 44,
            width: 44,

            decoration: BoxDecoration(
              color: emerald.withOpacity(0.12),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.lock_outline_rounded,
              color: mint,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: const [
                Text(
                  "Unlock the full experience",
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Login to access all available services and features.",
                  style: TextStyle(color: mutedText, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          FilledButton(
            onPressed: null,
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(emerald),

              foregroundColor: WidgetStatePropertyAll(Colors.white),

              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              ),

              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            child: const Text(
              "Login",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ).onTap(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LoginScreen(User_JwtToken: widget.User_JwtToken),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // HERO SECTION
  // ============================================================

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [Color(0xFF193A29), Color(0xFF12261C), Color(0xFF101F18)],
        ),

        border: Border.all(color: borderGreen),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 650;

          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,

            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,

            children: [
              Expanded(
                flex: compact ? 0 : 7,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),

                      decoration: BoxDecoration(
                        color: emerald.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(50),

                        border: Border.all(color: emerald.withOpacity(0.20)),
                      ),

                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: mint,
                            size: 15,
                          ),

                          SizedBox(width: 7),

                          Text(
                            "A better way to get things done",
                            style: TextStyle(
                              color: mint,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Everything you need,\n"
                      "in one simple place.",
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 38,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      "Explore our services, connect with the right people, "
                      "and make your everyday experience simpler.",
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Wrap(
                      spacing: 12,
                      runSpacing: 10,

                      children: [
                        _buildHeroStat(Icons.flash_on_rounded, "Simple"),

                        _buildHeroStat(Icons.security_rounded, "Secure"),

                        _buildHeroStat(Icons.devices_rounded, "Responsive"),
                      ],
                    ),
                  ],
                ),
              ),

              if (!compact) const SizedBox(width: 40),

              if (compact) const SizedBox(height: 28),

              // Decorative visual
              SizedBox(
                width: compact ? double.infinity : 260,
                height: 210,

                child: _buildHeroVisual(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // HERO VISUAL
  // ============================================================

  Widget _buildHeroVisual() {
    return Stack(
      alignment: Alignment.center,

      children: [
        Container(
          height: 170,
          width: 170,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            gradient: RadialGradient(
              colors: [
                emerald.withOpacity(0.25),
                emerald.withOpacity(0.03),
                Colors.transparent,
              ],
            ),
          ),
        ),

        Container(
          height: 120,
          width: 120,

          decoration: BoxDecoration(
            color: cardGreen,

            borderRadius: BorderRadius.circular(32),

            border: Border.all(color: emerald.withOpacity(0.30), width: 1.5),

            boxShadow: [
              BoxShadow(
                color: emerald.withOpacity(0.10),
                blurRadius: 35,
                spreadRadius: 5,
              ),
            ],
          ),

          child: const Icon(
            Icons.dashboard_customize_rounded,
            color: mint,
            size: 52,
          ),
        ),

        Positioned(
          top: 12,
          right: 20,

          child: _floatingIcon(Icons.check_circle_rounded),
        ),

        Positioned(
          bottom: 18,
          left: 15,

          child: _floatingIcon(Icons.star_rounded),
        ),
      ],
    );
  }

  Widget _floatingIcon(IconData icon) {
    return Container(
      height: 42,
      width: 42,

      decoration: BoxDecoration(
        color: const Color(0xFF1B3829),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: borderGreen),

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 15),
        ],
      ),

      child: Icon(icon, color: mint, size: 20),
    );
  }

  Widget _buildHeroStat(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, color: mint, size: 16),

          const SizedBox(width: 7),

          Text(
            text,
            style: const TextStyle(
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,

      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "Explore our services",
                style: TextStyle(
                  color: primaryText,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 6),

              Text(
                "Discover what you can do from here.",
                style: TextStyle(color: mutedText, fontSize: 13),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),

          decoration: BoxDecoration(
            color: emerald.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),

          child: const Text(
            "SERVICES",
            style: TextStyle(
              color: mint,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SERVICE GRID
  // ============================================================

  Widget _buildServiceGrid() {
    final services = [
      {
        "icon": Icons.people_alt_rounded,
        "title": "Find People",
        "description": "Discover people and providers that match your needs.",
      },
      {
        "icon": Icons.search_rounded,
        "title": "Explore",
        "description": "Browse available services and discover new options.",
      },
      {
        "icon": Icons.favorite_rounded,
        "title": "Personalized",
        "description": "Keep the things you care about close and accessible.",
      },
      {
        "icon": Icons.support_agent_rounded,
        "title": "Get Support",
        "description": "Find help and assistance whenever you need it.",
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width < 550) {
          columns = 1;
        } else if (width < 850) {
          columns = 2;
        } else if (width < 1150) {
          columns = 3;
        } else {
          columns = 4;
        }

        const spacing = 14.0;

        final itemWidth = (width - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,

          children: services.map((service) {
            return SizedBox(
              width: itemWidth,

              child: _buildServiceCard(
                icon: service["icon"] as IconData,
                title: service["title"] as String,
                description: service["description"] as String,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: cardGreen,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: borderGreen),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            height: 48,
            width: 48,

            decoration: BoxDecoration(
              color: emerald.withOpacity(0.10),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(icon, color: mint, size: 23),
          ),

          const SizedBox(height: 18),

          Text(
            title,
            style: TextStyle(
              color: primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: mutedText,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 18),

          const Row(
            children: [
              Text(
                "Explore",
                style: TextStyle(
                  color: mint,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(width: 5),

              Icon(Icons.arrow_forward_rounded, color: mint, size: 15),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHY SECTION
  // ============================================================

  Widget _buildWhySection() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: headerGreen,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: borderGreen),
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,

            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,

            children: [
              Expanded(
                flex: compact ? 0 : 2,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: const [
                    Text(
                      "Designed around you.",
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      "A clean experience that stays comfortable "
                      "whether you're using a phone, tablet or desktop.",
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              if (compact) const SizedBox(height: 24),

              if (!compact) const SizedBox(width: 30),

              Expanded(
                flex: compact ? 0 : 3,

                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,

                  children: [
                    _buildFeatureChip(Icons.devices_rounded, "Any device"),

                    _buildFeatureChip(Icons.dark_mode_rounded, "Dark focused"),

                    _buildFeatureChip(Icons.speed_rounded, "Fast experience"),

                    _buildFeatureChip(
                      Icons.auto_awesome_rounded,
                      "Modern design",
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),

      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: borderGreen),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, color: mint, size: 16),

          const SizedBox(width: 7),

          Text(
            text,
            style: const TextStyle(
              color: primaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM CALLOUT
  // ============================================================

  Widget _buildBottomCallout() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),

        gradient: LinearGradient(
          colors: [emerald.withOpacity(0.14), mint.withOpacity(0.04)],
        ),

        border: Border.all(color: emerald.withOpacity(0.18)),
      ),

      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,

            decoration: BoxDecoration(
              color: emerald.withOpacity(0.12),
              shape: BoxShape.circle,
            ),

            child: const Icon(Icons.lightbulb_outline_rounded, color: mint),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Your journey starts here.",
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Explore the options above and find what works best for you.",
                  style: TextStyle(color: mutedText, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
