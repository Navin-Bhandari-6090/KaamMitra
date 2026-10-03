import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/toast.dart';

// ============================================================
// PALETTE — Dark Green Web App theme
// ============================================================
class _Palette {
  static const bodyBg = Color(0xFF0F1F17);
  static const surface = Color(0xFF162E22);
  static const primaryText = Color(0xFFE6F4EA);
  static const mutedText = Color(0xFF9AA0A6);
  static const headerFooter = Color(0xFF12261C);
  static const accent = Color(0xFF22C55E);
  static const accentMint = Color(0xFF34D399);
  static const borderColor = Color(0xFF234232);
}

// ============================================================
// GETX CONTROLLER — all business logic lives here (unchanged
// behaviour from the original StatefulWidget, only relocated
// and rewritten to use GetX reactive state instead of setState)
// ============================================================
class ChangeAddressGetx extends GetxController {
  late String userEmail;
  late String userJwtToken;
  late String userRole;

  final TextEditingController addressController = TextEditingController();
  final Toast = Toastget();

  final RxBool isVerifying = true.obs;
  final RxBool isSubmitting = false.obs;

  void init({
    required String email,
    required String jwtToken,
    required String role,
  }) {
    userEmail = email;
    userJwtToken = jwtToken;
    userRole = role;
    Pro_User_Jwt_Verify(Jwt_Token: jwtToken);
  }

  Future<void> Pro_User_Jwt_Verify({required String Jwt_Token}) async {
    isVerifying.value = true;
    int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
    isVerifying.value = false;
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Get.offAll(() => ErrorPage());
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  Future<void> ChangeAddress({required String Address}) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      const String url = Backend_Server_Url + "api/Profile/updateaddress";
      Map<String, dynamic> UserDetails = {
        "Address": Address,
        "Email": userEmail,
      };
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $userJwtToken',
        },
        body: json.encode(UserDetails),
      );
      if (response.statusCode == 200) {
        print("Update success.");
        Toast.Toastmsg("Update  success.");
        return;
      } else if (response.statusCode == 500) {
        final data = jsonDecode(response.body);
        print("Exception Message: ${data['error']}");
        print("Exception caught in backend.");
        Toast.Toastmsg("Server erro try again.");
        return;
      } else if (response.statusCode == 501) {
        print("Details are not in correct format.");
        Toast.Toastmsg("Provide deatails in correct format.");
        return;
      } else if (response.statusCode == 502) {
        print("Email does not match");
        Toast.Toastmsg("Your current email doesn't match.");
        await Clear_User_Data();
        await Random_token_Clear();
        Get.offAll(() => ErrorPage());
        Toastget().Toastmsg("Session End.Relogin please.");
        return;
      } else {
        print("Update  failed.");
        Toast.Toastmsg("Server error try again.");
        return;
      }
    } catch (obj) {
      print("Exception in change address: $obj");
      Toast.Toastmsg("Server error try again.");
      return;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    addressController.dispose();
    super.onClose();
  }
}

// ============================================================
// UI — StatefulWidget kept ONLY to own the AnimationController
// for entrance / bubble motion. No setState is ever called for
// data or business state — all of that is Obx/GetX reactive.
// ============================================================
class UpdateAddress extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  const UpdateAddress({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
  });

  @override
  State<UpdateAddress> createState() => _UpdateAddressState();
}

class _UpdateAddressState extends State<UpdateAddress>
    with TickerProviderStateMixin {
  late final ChangeAddressGetx controller;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _bubbleCtrl;

  bool _focused = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChangeAddressGetx());
    controller.init(
      email: widget.User_Email,
      jwtToken: widget.User_JwtToken,
      role: widget.User_Role,
    );

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();

    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _bubbleCtrl.dispose();
    Get.delete<ChangeAddressGetx>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final cardMaxWidth = min(size.width * 0.92, 520.0);
    final horizontalPad = size.width < 420 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: _Palette.bodyBg,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // ---- animated bubble background ----
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bubbleCtrl,
              builder: (context, _) => CustomPaint(
                painter: _BubblePainter(progress: _bubbleCtrl.value, size: size),
              ),
            ),
          ),
          // ---- main scrollable content, fully responsive ----
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: orientation == Orientation.portrait ? 28 : 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          (orientation == Orientation.portrait ? 56 : 32),
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            child: Obx(() {
                              if (controller.isVerifying.value) {
                                return _buildVerifyingState();
                              }
                              return _buildCard(context);
                            }),
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
  // App bar with a clearly-visible bordered back button
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
        "Update Address",
        style: TextStyle(
          color: _Palette.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 19,
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
  // Loading state while JWT is being verified
  // ---------------------------------------------------------
  Widget _buildVerifyingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_Palette.accentMint),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Verifying session...",
            style: TextStyle(color: _Palette.mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Main glassy card with the address form
  // ---------------------------------------------------------
  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 26),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: _Palette.accent.withOpacity(0.05),
            blurRadius: 60,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderIcon(),
          const SizedBox(height: 18),
          const Text(
            "Where should we deliver?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _Palette.primaryText,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Update your saved address below. This helps to reach you corectly.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _Palette.mutedText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _buildAddressField(),
          const SizedBox(height: 26),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: 0.7 + (0.3 * value),
        child: child,
      ),
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_Palette.accent, _Palette.accentMint],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _Palette.accent.withOpacity(0.45),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_city_rounded,
            color: _Palette.bodyBg,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return StatefulBuilder(
      builder: (context, setFieldState) {
        return Focus(
          onFocusChange: (has) => setFieldState(() => _focused = has),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused ? _Palette.accentMint : _Palette.borderColor,
                width: _focused ? 1.6 : 1,
              ),
              boxShadow: _focused
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
              controller: controller.addressController,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: _Palette.primaryText, fontSize: 15),
              cursorColor: _Palette.accentMint,
              decoration: InputDecoration(
                filled: true,
                fillColor: _Palette.headerFooter,
                labelText: "Enter address",
                labelStyle: TextStyle(
                  color: _focused ? _Palette.accentMint : _Palette.mutedText,
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10, top: 2),
                  child: Icon(
                    Icons.location_city,
                    color: _focused ? _Palette.accentMint : _Palette.mutedText,
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Obx(() {
      final loading = controller.isSubmitting.value;
      return SizedBox(
        height: 52,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading
                ? null
                : () async {
              FocusScope.of(context).unfocus();
              try {
                await controller.ChangeAddress(
                  Address: controller.addressController.text.trim(),
                );
              } catch (obj) {
                return;
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: loading
                      ? [_Palette.borderColor, _Palette.borderColor]
                      : [_Palette.accent, _Palette.accentMint],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: loading
                    ? []
                    : [
                  BoxShadow(
                    color: _Palette.accent.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(_Palette.primaryText),
                ),
              )
                  : const Text(
                "Change Address",
                style: TextStyle(
                  color: _Palette.bodyBg,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ============================================================
// Decorative floating "bubble" background painter
// ============================================================
class _BubblePainter extends CustomPainter {
  final double progress; // 0..1 looping
  final Size size;

  _BubblePainter({required this.progress, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;

    final bubbles = <_BubbleSpec>[
      _BubbleSpec(rx: 0.15, ry: 0.18, radius: w * 0.32, color: _Palette.accent, speed: 1.0, opacity: 0.10),
      _BubbleSpec(rx: 0.85, ry: 0.12, radius: w * 0.26, color: _Palette.accentMint, speed: -0.8, opacity: 0.08),
      _BubbleSpec(rx: 0.80, ry: 0.85, radius: w * 0.38, color: _Palette.accent, speed: 0.6, opacity: 0.09),
      _BubbleSpec(rx: 0.10, ry: 0.80, radius: w * 0.22, color: _Palette.accentMint, speed: -1.2, opacity: 0.07),
    ];

    for (final b in bubbles) {
      final dx = sin((progress * 2 * pi * b.speed)) * w * 0.03;
      final dy = cos((progress * 2 * pi * b.speed)) * h * 0.02;
      final center = Offset(b.rx * w + dx, b.ry * h + dy);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withOpacity(b.opacity),
            b.color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: b.radius));
      canvas.drawCircle(center, b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BubbleSpec {
  final double rx;
  final double ry;
  final double radius;
  final Color color;
  final double speed;
  final double opacity;

  _BubbleSpec({
    required this.rx,
    required this.ry,
    required this.radius,
    required this.color,
    required this.speed,
    required this.opacity,
  });
}