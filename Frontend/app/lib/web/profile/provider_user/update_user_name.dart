// ---------------------------------------------------------------------------
// Adjust the two path notes below if your project structure differs:
//   1. GreenField is assumed to live at '../../common widget/GreenTextfield.dart'
//      (same depth as the other imports already in this file).
//   2. UpdateUserNameGetx import path is a guess at where you'll place the
//      controller — update the folder segments to match your project.
// ---------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../state management/getx/profile/provider_user/update_user_name_getx.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/GreenTextfield.dart';
import '../../common widget/toast.dart';

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

class UpdateUserName extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;

  const UpdateUserName(
      {super.key,
        required this.User_Email,
        required this.User_JwtToken,
        required this.User_Role});

  @override
  State<UpdateUserName> createState() => _UpdateUserNameState();
}

class _UpdateUserNameState extends State<UpdateUserName>
    with SingleTickerProviderStateMixin {
  final Toast = Toastget();
  final updateNameCont = Get.put(UpdateUserNameGetx());

  final FirstNameCont = TextEditingController();
  final LastNameCont = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();

  // ============================================================
  // ENTRANCE ANIMATION (UI-only addition, no business logic)
  // ============================================================

  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _formAnim;
  late final Animation<double> _submitAnim;

  @override
  void initState() {
    super.initState();

    // NOTE: this was defined in the original file but never invoked from
    // initState (only a "// TODO: implement initState" placeholder was
    // there). Every sibling screen calls its JWT-verify method on load, so
    // it's wired up here to match that pattern — remove this call if that
    // was intentionally left out.
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _heroAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _formAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );
    _submitAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();

    _firstNameFocusNode.addListener(() {
      updateNameCont.setFirstNameFocused(_firstNameFocusNode.hasFocus);
    });
    _lastNameFocusNode.addListener(() {
      updateNameCont.setLastNameFocused(_lastNameFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    FirstNameCont.dispose();
    LastNameCont.dispose();
    super.dispose();
  }

  // ============================================================
  // ORIGINAL LOGIC — UNCHANGED (same URL, same status-code branches,
  // same error handling as before)
  // ============================================================

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
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
  }

  Future<void> ChangeUserName(
      {required String FirstName, required String LastName}) async {
    try {
      const String url = Backend_Server_Url + "api/Profile/updateusername";
      Map<String, dynamic> UserDetails = {
        "FirstName": FirstName,
        "LastName": LastName,
        "Email": widget.User_Email
      };
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}',
        },
        body: json.encode(UserDetails),
      );
      if (response.statusCode == 200) {
        print("Update username success.");
        Toast.Toastmsg("Update username success.");
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
        Toast.Toastmsg("Yout current email doesn't match.");
        await Clear_User_Data();
        await Random_token_Clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
        Toastget().Toastmsg("Session End.Relogin please.");
        return;
      } else {
        print("Update username failed.");
        Toast.Toastmsg("Server error try again.");
        return;
      }
    } catch (obj) {
      print("Exception in change username: $obj");
      Toast.Toastmsg("Server error try again.");
      return;
    }
  }

  // ============================================================
  // SUBMIT HANDLER — same call/logic as before, wrapped with a
  // GetX-driven loading state instead of setState.
  // ============================================================

  Future<void> _onSubmitPressed() async {
    if (updateNameCont.isSubmitting.value) return;

    updateNameCont.setSubmitting(true);
    try {
      await ChangeUserName(
        FirstName: FirstNameCont.text.toString().trim(),
        LastName: LastNameCont.text.toString().trim(),
      );
    } finally {
      updateNameCont.setSubmitting(false);
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
    final double contentMaxWidth = widthval > 900 ? 640 : double.infinity;

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
                            // ============================================
                            // BACK ROW (bordered arrow, primary text color
                            // for visibility — no header/footer on this
                            // screen)
                            // ============================================
                            _buildBackRow(context, isMobile),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ============================================
                            // HERO
                            // ============================================
                            _animatedSection(
                              animation: _heroAnim,
                              child: _buildHero(isMobile),
                            ),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ============================================
                            // FORM
                            // ============================================
                            _animatedSection(
                              animation: _formAnim,
                              child: _buildFormCard(isMobile),
                            ),

                            SizedBox(height: isMobile ? 22 : 30),

                            // ============================================
                            // SUBMIT
                            // ============================================
                            _animatedSection(
                              animation: _submitAnim,
                              child: _buildSubmitButton(isMobile),
                            ),

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
            "Update Name",
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
          final bool compact = constraints.maxWidth < 480;

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
                          Icon(Icons.badge_rounded, color: _Theme.mint, size: 14),
                          SizedBox(width: 7),
                          Text(
                            "Your profile",
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
                      "Update your name",
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontSize: isMobile ? 24 : 28,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "This is how you'll appear across the app — "
                          "to other users, providers, and on your profile.",
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
                  height: 84,
                  width: 84,
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
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: _Theme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _Theme.emerald.withOpacity(0.30), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _Theme.emerald.withOpacity(0.12),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _Theme.mint,
                      size: 28,
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
  // FORM CARD
  // ============================================================

  Widget _buildFormCard(bool isMobile) {
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
                  "Name details",
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
            "Enter your first and last name exactly as you'd like others "
                "to see them.",
            style: TextStyle(
              color: _Theme.mutedTextAlt,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // ---------------- First name ----------------
          _glowField(
            controller: FirstNameCont,
            focusNode: _firstNameFocusNode,
            focused: updateNameCont.isFirstNameFocused,
            label: "First name",
            icon: Icons.person_outline_rounded,
          ),

          SizedBox(height: isMobile ? 14 : 16),

          // ---------------- Last name ----------------
          _glowField(
            controller: LastNameCont,
            focusNode: _lastNameFocusNode,
            focused: updateNameCont.isLastNameFocused,
            label: "Last name",
            icon: Icons.person_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _glowField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required RxBool focused,
    required String label,
    required IconData icon,
  }) {
    return Obx(
          () => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: focused.value
                ? _Theme.emerald.withOpacity(0.55)
                : Colors.transparent,
            width: 1.4,
          ),
          boxShadow: focused.value
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
          controller: controller,
          label: label,
          icon: icon,
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton(bool isMobile) {
    return Obx(() {
      final bool submitting = updateNameCont.isSubmitting.value;
      final bool pressed = updateNameCont.isButtonPressed.value;

      return AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: submitting ? null : _onSubmitPressed,
            onTapDown: (_) => updateNameCont.setButtonPressed(true),
            onTapCancel: () => updateNameCont.setButtonPressed(false),
            onTapUp: (_) => updateNameCont.setButtonPressed(false),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 15 : 17),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: submitting
                    ? null
                    : const LinearGradient(
                  colors: [_Theme.emerald, _Theme.mint],
                ),
                color: submitting ? _Theme.surface : null,
                borderRadius: BorderRadius.circular(16),
                border: submitting ? Border.all(color: _Theme.border) : null,
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
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: _Theme.mint,
                        strokeWidth: 2.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Saving...",
                      style: TextStyle(
                        color: _Theme.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 19),
                    const SizedBox(width: 9),
                    const Text(
                      "Save changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
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