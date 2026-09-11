import 'package:app/web/bookings/ProviderBookings.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:app/web/profile/user/User_Profile.dart';
import 'package:app/web/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../state management/getx/header/Header_GET_X.dart';
import '../bookings/UserBookings.dart';
import '../home/Home_Screen.dart';
import '../profile/provider/Provider_Profile.dart';



class Header extends StatelessWidget {
  final bool UserLogin;
  final String User_JwtToken;


  final commonGetxCont = Get.put(HeaderGetX());

  Header({
    super.key,
    required this.UserLogin,
    required this.User_JwtToken,
  });

  // ============================================================
  // DARK GREEN PALETTE
  // ============================================================

  static const Color bodyBackground = Color(0xFF0F1F17);
  static const Color headerBackground = Color(0xFF12261C);

  static const Color surface = Color(0xFF162E22);
  static const Color surfaceLight = Color(0xFF1B3829);

  static const Color primaryText = Color(0xFFE6F4EA);
  static const Color secondaryText = Color(0xFF9AA0A6);

  static const Color emerald = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);

  static const Color border = Color(0xFF234232);



  // ============================================================
  // RESPONSIVE FONT
  // ============================================================

  double _responsiveFont(
      double width, {
        required double desktop,
        required double tablet,
        required double mobile,
      }) {
    if (width >= 1200) {
      return desktop;
    }

    if (width >= 700) {
      return tablet;
    }

    return mobile;
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo(
      BuildContext context,
      double width,
      ) {
    final bool small = width < 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: emerald.withOpacity(0.06),
        splashColor: emerald.withOpacity(0.12),
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) {
                return HomeScreenUi(
                  UserLogin: UserLogin,
                  User_JwtToken: User_JwtToken,
                );
              },
            ),
                (route) => false,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ------------------------------------------------
              // LOGO ICON
              // ------------------------------------------------

              Container(
                width: small ? 38 : 44,
                height: small ? 38 : 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      emerald,
                      mint,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    small ? 11 : 13,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: emerald.withOpacity(0.25),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: small ? 21 : 25,
                ),
              ),

              // ------------------------------------------------
              // LOGO TEXT
              // ------------------------------------------------

              if (width >= 520) ...[
                const SizedBox(width: 11),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KammMitra",
                      style: TextStyle(
                        color: primaryText,
                        fontSize: _responsiveFont(
                          width,
                          desktop: 19,
                          tablet: 17,
                          mobile: 15,
                        ),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    if (width >= 850)
                      const Text(
                        "SERVICES • CONNECT • GROW",
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION ITEM
  // ============================================================

  Widget _buildNavigationItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required double width,
  }) {
    final bool compact = width < 900;

    return Obx(
          () {
        final bool isHovered =
            commonGetxCont.HeaderHoveredIndex.value == index;

        return MouseRegion(
          cursor: SystemMouseCursors.click,

          // ----------------------------------------------------
          // GETX HOVER START
          // ----------------------------------------------------

          onEnter: (_) {
            commonGetxCont.HeaderHoveredIndexMethod(index);
          },

          // ----------------------------------------------------
          // GETX HOVER END
          // ----------------------------------------------------

          onExit: (_) {
            commonGetxCont.HeaderHoverClearMethod();
          },

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,

            margin: EdgeInsets.symmetric(
              horizontal: width < 600 ? 2 : 4,
            ),

            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 15,
              vertical: compact ? 8 : 10,
            ),

            decoration: BoxDecoration(
              color: isHovered
                  ? emerald.withOpacity(0.11)
                  : Colors.transparent,

              borderRadius: BorderRadius.circular(14),

              border: Border.all(
                color: isHovered
                    ? emerald.withOpacity(0.22)
                    : Colors.transparent,
                width: 1,
              ),

              boxShadow: isHovered
                  ? [
                BoxShadow(
                  color: emerald.withOpacity(0.06),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
                  : null,
            ),

            child: Material(
              color: Colors.transparent,

              child: InkWell(
                onTap: onTap,

                borderRadius: BorderRadius.circular(14),

                splashColor: emerald.withOpacity(0.15),
                highlightColor: emerald.withOpacity(0.05),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==========================================
                    // ICON
                    // ==========================================

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,

                      padding: const EdgeInsets.all(7),

                      decoration: BoxDecoration(
                        gradient: isHovered
                            ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            emerald,
                            mint,
                          ],
                        )
                            : null,

                        color: isHovered
                            ? null
                            : surface,

                        borderRadius: BorderRadius.circular(9),

                        border: Border.all(
                          color: isHovered
                              ? Colors.transparent
                              : border,
                        ),

                        boxShadow: isHovered
                            ? [
                          BoxShadow(
                            color: emerald.withOpacity(0.20),
                            blurRadius: 10,
                          ),
                        ]
                            : null,
                      ),

                      child: Icon(
                        icon,
                        size: compact ? 17 : 19,
                        color: isHovered
                            ? Colors.white
                            : primaryText,
                      ),
                    ),

                    // ==========================================
                    // TEXT
                    // ==========================================

                    if (width >= 500) ...[
                      const SizedBox(width: 9),

                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,

                        style: TextStyle(
                          color: isHovered
                              ? const Color(0xFF7AFFA8)
                              : primaryText,

                          fontSize: _responsiveFont(
                            width,
                            desktop: 14,
                            tablet: 13,
                            mobile: 12,
                          ),

                          fontWeight: isHovered
                              ? FontWeight.w700
                              : FontWeight.w600,

                          letterSpacing: 0.1,
                        ),

                        child: Text(title),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MOBILE NAVIGATION
  // ============================================================

  Widget _buildMobileNavigation(
      BuildContext context,
      double width,
      ) {
    return PopupMenuButton<int>(
      tooltip: "Menu",

      offset: const Offset(0, 55),

      color: surface,

      elevation: 15,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: border,
        ),
      ),

      icon: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: border,
          ),
        ),
        child: const Icon(
          Icons.menu_rounded,
          color: primaryText,
          size: 22,
        ),
      ),

      onSelected: (value) async {
        // ==========================================
        // HOME
        // ==========================================

        if (value == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) {
                return HomeScreenUi(
                  UserLogin: UserLogin,
                  User_JwtToken: User_JwtToken,
                );
              },
            ),
                (route) => false,
          );
        }

        // ==========================================
        // SERVICES
        // ==========================================

        if (value == 1) {
          try {
            if (UserLogin == true) {
              final box =
              await Hive.openBox('User_Data');

              String? Jwt_Token =
              box.get('jwt_token');

              String? User_Email =
              box.get('user_email');

              String? User_Role =
              box.get('user_role');

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ServicesScreen(
                      User_Email: User_Email!,
                      User_JwtToken: Jwt_Token!,
                      User_Role: User_Role!,
                    );
                  },
                ),
                    (route) => false,
              );
            } else {
              Toastget().Toastmsg(
                "Please login to use all kind of services.",
              );
            }
          } catch (e) {
            Toastget().Toastmsg(
              "Something went wrong.Try again.",
            );
          }
        }

        // ==========================================
        // BOOKINGS
        // ==========================================

        if (value == 2) {
          try {
            if (UserLogin == true) {
              final box =
              await Hive.openBox('User_Data');

              String? Jwt_Token =
              box.get('jwt_token');

              String? User_Email =
              box.get('user_email');

              String? User_Role =
              box.get('user_role');

              if (User_Role == "Provider") {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ProviderBookingsScreen(
                        User_Email: User_Email!,
                        User_JwtToken: Jwt_Token!,
                        User_Role: User_Role!,
                      );
                    },
                  ),
                      (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return MyBookingScreenUser(
                        User_Email: User_Email!,
                        User_JwtToken: Jwt_Token!,
                        User_Role: User_Role!,
                      );
                    },
                  ),
                      (route) => false,
                );
              }
            } else {
              Toastget().Toastmsg(
                "Please login to use all kind of services.",
              );
            }
          } catch (e) {
            Toastget().Toastmsg(
              "Something went wrong.Try again.",
            );
          }
        }

        // ==========================================
        // PROFILE
        // ==========================================

        if (value == 3) {
          try {
            if (UserLogin == true) {
              final box =
              await Hive.openBox('User_Data');

              String? Jwt_Token =
              box.get('jwt_token');

              String? User_Email =
              box.get('user_email');

              String? User_Role =
              box.get('user_role');

              print("header token");
              print(Jwt_Token);

              if (User_Role == "Provider") {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ProviderProfile(
                        User_Email: User_Email!,
                        User_JwtToken: Jwt_Token!,
                        User_Role: User_Role!,
                        UserLogin: UserLogin,
                      );
                    },
                  ),
                      (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return UserProfile(
                        User_Email: User_Email!,
                        User_JwtToken: Jwt_Token!,
                        User_Role: User_Role!,
                        UserLogin: UserLogin,
                      );
                    },
                  ),
                      (route) => false,
                );
              }
            } else {
              Toastget().Toastmsg(
                "Please login to use all kind of services.",
              );
            }
          } catch (e) {
            Toastget().Toastmsg(
              "Something went wrong.Try again.",
            );
          }
        }
      },

      itemBuilder: (context) => [
        _mobileMenuItem(
          0,
          Icons.home_rounded,
          "Home",
        ),

        _mobileMenuItem(
          1,
          Icons.grid_view_rounded,
          "Services",
        ),

        _mobileMenuItem(
          2,
          Icons.calendar_month_rounded,
          "Bookings",
        ),

        _mobileMenuItem(
          3,
          Icons.person_rounded,
          "Profile",
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE MENU ITEM
  // ============================================================

  PopupMenuItem<int> _mobileMenuItem(
      int value,
      IconData icon,
      String title,
      ) {
    return PopupMenuItem<int>(
      value: value,

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: emerald.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: mint,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          Text(
            title,
            style: const TextStyle(
              color: primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final double width = media.size.width;
    final double height = media.size.height;

    // ==========================================================
    // RESPONSIVE HEADER HEIGHT
    // ==========================================================

    final double headerHeight = width < 650 ? 64.0 : 76.0;

    // NOTE: raised from 650 -> 950. The desktop nav (logo + 4 labeled
    // nav items) needs roughly 850-950px to lay out without squeezing.
    // Below 950px we now show the hamburger menu instead of overflowing.
    final bool mobile = width < 950;

    final bool verySmall = width < 420;

    return Container(
      width: double.infinity,
      height: headerHeight,

      decoration: BoxDecoration(
        color: headerBackground,

        border: const Border(
          bottom: BorderSide(
            color: border,
            width: 1,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 25,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),

      child: Stack(
        children: [
          // ====================================================
          // BACKGROUND GLOW
          // ====================================================

          Positioned(
            top: -80,
            left: width * 0.15,

            child: IgnorePointer(
              child: Container(
                width: width * 0.35,
                height: 140,

                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      emerald.withOpacity(0.055),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            right: width * 0.05,

            child: IgnorePointer(
              child: Container(
                width: width * 0.30,
                height: 150,

                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      mint.withOpacity(0.035),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ====================================================
          // HEADER CONTENT
          // ====================================================

          SafeArea(
            bottom: false,

            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: verySmall
                    ? 8
                    : width < 650
                    ? 12
                    : width < 1000
                    ? 18
                    : 28,
              ),

              child: Row(
                children: [
                  // ==================================================
                  // LOGO
                  // ==================================================

                  _buildLogo(
                    context,
                    width,
                  ),

                  const Spacer(),

                  // ==================================================
                  // DESKTOP NAVIGATION
                  // ==================================================

                  if (!mobile) ...[
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            // ------------------------------------------
                            // HOME
                            // ------------------------------------------

                            _buildNavigationItem(
                              context: context,
                              index: 0,
                              icon: Icons.home_rounded,
                              title: "Home",
                              width: width,
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return HomeScreenUi(
                                        UserLogin: UserLogin,
                                        User_JwtToken:
                                        User_JwtToken,
                                      );
                                    },
                                  ),
                                      (route) => false,
                                );
                              },
                            ),

                            // ------------------------------------------
                            // SERVICES
                            // ------------------------------------------

                            _buildNavigationItem(
                              context: context,
                              index: 1,
                              icon: Icons.grid_view_rounded,
                              title: "Services",
                              width: width,
                              onTap: () async {
                                try {
                                  if (UserLogin == true) {
                                    final box =
                                    await Hive.openBox(
                                      'User_Data',
                                    );

                                    String? Jwt_Token =
                                    box.get('jwt_token');

                                    String? User_Email =
                                    box.get('user_email');

                                    String? User_Role =
                                    box.get('user_role');

                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return ServicesScreen(
                                            User_JwtToken:User_JwtToken!,
                                            User_Email: User_Email!,
                                            User_Role: User_Role!,

                                          );
                                        },
                                      ),
                                          (route) => false,
                                    );
                                  } else {
                                    Toastget().Toastmsg(
                                      "Please login to use all kind of services.",
                                    );
                                  }
                                } catch (e) {
                                  Toastget().Toastmsg(
                                    "Something went wrong.Try again.",
                                  );
                                }
                              },
                            ),

                            // ------------------------------------------
                            // BOOKINGS
                            // ------------------------------------------

                            _buildNavigationItem(
                              context: context,
                              index: 2,
                              icon:
                              Icons.calendar_month_rounded,
                              title: "Bookings",
                              width: width,
                              onTap: () async {
                                try {
                                  if (UserLogin == true) {
                                    final box =
                                    await Hive.openBox(
                                      'User_Data',
                                    );

                                    String? Jwt_Token =
                                    box.get('jwt_token');

                                    String? User_Email =
                                    box.get('user_email');

                                    String? User_Role =
                                    box.get('user_role');

                                    if (User_Role ==
                                        "Provider") {
                                      Navigator
                                          .pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return ProviderBookingsScreen(
                                              User_Email:
                                              User_Email!,
                                              User_JwtToken:
                                              Jwt_Token!,
                                              User_Role:
                                              User_Role!,
                                            );
                                          },
                                        ),
                                            (route) => false,
                                      );
                                    } else {
                                      Navigator
                                          .pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return MyBookingScreenUser(
                                              User_Email:
                                              User_Email!,
                                              User_JwtToken:
                                              Jwt_Token!,
                                              User_Role:
                                              User_Role!,
                                            );
                                          },
                                        ),
                                            (route) => false,
                                      );
                                    }
                                  } else {
                                    Toastget().Toastmsg(
                                      "Please login to use all kind of services.",
                                    );
                                  }
                                } catch (e) {
                                  Toastget().Toastmsg(
                                    "Something went wrong.Try again.",
                                  );
                                }
                              },
                            ),

                            // ------------------------------------------
                            // PROFILE
                            // ------------------------------------------

                            _buildNavigationItem(
                              context: context,
                              index: 3,
                              icon: Icons.person_rounded,
                              title: "Profile",
                              width: width,
                              onTap: () async {
                                try {
                                  if (UserLogin == true) {
                                    final box =
                                    await Hive.openBox(
                                      'User_Data',
                                    );

                                    String? Jwt_Token =
                                    box.get('jwt_token');

                                    String? User_Email =
                                    box.get('user_email');

                                    String? User_Role =
                                    box.get('user_role');

                                    print("header token");
                                    print(Jwt_Token);

                                    if (User_Role ==
                                        "Provider") {
                                      Navigator
                                          .pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return ProviderProfile(
                                              User_Email:
                                              User_Email!,
                                              User_JwtToken:
                                              Jwt_Token!,
                                              User_Role:
                                              User_Role!,
                                              UserLogin:
                                              UserLogin,
                                            );
                                          },
                                        ),
                                            (route) => false,
                                      );
                                    } else {
                                      Navigator
                                          .pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return UserProfile(
                                              User_Email:
                                              User_Email!,
                                              User_JwtToken:
                                              Jwt_Token!,
                                              User_Role:
                                              User_Role!,
                                              UserLogin:
                                              UserLogin,
                                            );
                                          },
                                        ),
                                            (route) => false,
                                      );
                                    }
                                  } else {
                                    Toastget().Toastmsg(
                                      "Please login to use all kind of services.",
                                    );
                                  }
                                } catch (e) {
                                  Toastget().Toastmsg(
                                    "Something went wrong.Try again.",
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),


                  ]

                  // ==================================================
                  // MOBILE
                  // ==================================================

                  else ...[


                    _buildMobileNavigation(
                      context,
                      width,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}