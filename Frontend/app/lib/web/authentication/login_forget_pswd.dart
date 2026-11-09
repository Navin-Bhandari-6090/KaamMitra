import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../constant/variable.dart';
import '../../state management/getx/authentication/log_for_pswd_getx.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/design/bolbs_background.dart';

// ---------------------------------------------------------------------------
// THEME TOKENS (dark green) — matches Header.dart / ProviderProfile.dart
// ---------------------------------------------------------------------------
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
  static const Color danger = Color(0xFFF87171);

  static const Color border = Color(0xFF234232);
}

class LogForPswd extends StatefulWidget {
  final String User_JwtToken;
  const LogForPswd({super.key, required this.User_JwtToken});

  @override
  State<LogForPswd> createState() => _LogForPswdState();
}

class _LogForPswdState extends State<LogForPswd>
    with SingleTickerProviderStateMixin {
  final LogForPswdGetx pswdCont = Get.put(LogForPswdGetx());

  final TextEditingController EmailCont = TextEditingController();
  final TextEditingController NewPasswordCont = TextEditingController();
  final TextEditingController OldPasswordCont = TextEditingController();
  final TextEditingController PhoneNumberCont = TextEditingController();
  final TextEditingController WhatsappNumberCont = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _whatsappFocus = FocusNode();
  final FocusNode _oldFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();

  // Entrance animation (UI only)
  late final AnimationController _entranceController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _formAnim;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
    );
    _formAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();

    try {
      _bindFocus(_emailFocus, 'email');
      _bindFocus(_phoneFocus, 'phone');
      _bindFocus(_whatsappFocus, 'whatsapp');
      _bindFocus(_oldFocus, 'old');
      _bindFocus(_newFocus, 'new');

      pswdCont.verifySession(
        jwtToken: widget.User_JwtToken,
        context: context,
      );
    } catch (e) {
      // print("initState failed: $e");
    }
  }

  void _bindFocus(FocusNode node, String key) {
    node.addListener(() {
      try {
        if (node.hasFocus) {
          pswdCont.setFocusedField(key);
        } else {
          pswdCont.clearFocusedField(key);
        }
      } catch (e) {
        // print("Focus listener failed: $e");
      }
    });
  }

  @override
  void dispose() {
    try {
      _entranceController.dispose();
      for (final c in [
        EmailCont,
        NewPasswordCont,
        OldPasswordCont,
        PhoneNumberCont,
        WhatsappNumberCont,
      ]) {
        c.dispose();
      }
      for (final f in [
        _emailFocus,
        _phoneFocus,
        _whatsappFocus,
        _oldFocus,
        _newFocus,
      ]) {
        f.dispose();
      }
    } catch (e) {
      // print("dispose failed: $e");
    }
    super.dispose();
  }

  // ============================================================
  // ACTION — validate -> confirm -> controller call
  // ============================================================

  Future<void> _onUpdatePressed() async {
    try {
      if (pswdCont.isLoading.value) return;

      final String? error = pswdCont.validateInputs(
        email: EmailCont.text,
        newPassword: NewPasswordCont.text,
        oldPassword: OldPasswordCont.text,
        phoneNumber: PhoneNumberCont.text,
        whatsappNumber: WhatsappNumberCont.text,
      );
      if (error != null) {
        Toast.Toastmsg(error);
        return;
      }

      final bool confirmed = await _confirmUpdate();
      if (!confirmed || !mounted) return;

      final int result = await pswdCont.updatePassword(
        context: context,
        jwtToken: widget.User_JwtToken,
        email: EmailCont.text.trim(),
        phoneNumber: PhoneNumberCont.text.trim(),
        whatsappPhoneNumber: WhatsappNumberCont.text.trim(),
        oldPassword: OldPasswordCont.text.trim(),
        newPassword: NewPasswordCont.text.trim(),
      );

      // Clear the form only after a successful update.
      if (result == 1) {
        OldPasswordCont.clear();
        NewPasswordCont.clear();
        pswdCont.setNewPasswordText('');
      }
    } catch (e) {
      // print("_onUpdatePressed failed: $e");
    }
  }

  Future<bool> _confirmUpdate() async {
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
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: _Theme.mint),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    "Update password?",
                    style: TextStyle(
                      color: _Theme.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              "Your password will be changed to the new one you entered. "
                  "Use it the next time you log in.",
              style: TextStyle(
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
                child: const Text("Update"),
              ),
            ],
          );
        },
      );
      return result == true;
    } catch (e) {
      // print("_confirmUpdate failed: $e");
      return false;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;
    final double hPad = width < 420 ? 14 : (isMobile ? 20 : 32);

    return Scaffold(
      backgroundColor: _Theme.bgTop,
      appBar: _buildAppBar(context),
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
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: outer.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            hPad,
                            isMobile ? 22 : 36,
                            hPad,
                            32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _animatedSection(
                                animation: _heroAnim,
                                child: _buildHero(isMobile),
                              ),
                              SizedBox(height: isMobile ? 20 : 26),
                              _animatedSection(
                                animation: _formAnim,
                                child: _buildFormCard(isMobile),
                              ),
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
  // APP BAR — bordered back arrow (primary-text-colored), title
  // ============================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _Theme.surfaceBar,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: Navigator.of(context).canPop()
          ? Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: Tooltip(
            message: "Back",
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
                    Navigator.of(context).maybePop();
                  } catch (e) {
                    // print("Back failed: $e");
                  }
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: _Theme.primaryText,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      )
          : null,
      title: const Text(
        "Forgot password",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _Theme.primaryText,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.1,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _Theme.border),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(bool isMobile) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, v, child) =>
              Transform.scale(scale: 0.7 + (0.3 * v), child: child),
          child: Container(
            width: isMobile ? 68 : 78,
            height: isMobile ? 68 : 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_Theme.emerald, _Theme.mint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _Theme.emerald.withOpacity(0.40),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: _Theme.bgTop,
              size: isMobile ? 34 : 40,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Reset your password",
          textAlign: TextAlign.center,
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
          "Confirm your account details, then choose a new password. "
              "You will use it the next time you log in.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _Theme.mutedText,
            fontSize: isMobile ? 13 : 14.5,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF193A29), Color(0xFF12261C), Color(0xFF101F18)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _Theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            icon: Icons.badge_rounded,
            title: "Your account",
          ),
          const SizedBox(height: 14),
          _field(
            keyName: 'email',
            controller: EmailCont,
            focusNode: _emailFocus,
            label: "Email",
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _field(
            keyName: 'phone',
            controller: PhoneNumberCont,
            focusNode: _phoneFocus,
            label: "Phone number",
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _field(
            keyName: 'whatsapp',
            controller: WhatsappNumberCont,
            focusNode: _whatsappFocus,
            label: "WhatsApp number",
            icon: Icons.chat_rounded,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 24),
          _sectionTitle(
            icon: Icons.password_rounded,
            title: "Password",
          ),
          const SizedBox(height: 14),
          _passwordField(
            keyName: 'old',
            controller: OldPasswordCont,
            focusNode: _oldFocus,
            label: "Old password",
            hidden: pswdCont.hideOldPassword,
            onToggle: pswdCont.toggleOldPassword,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _passwordField(
            keyName: 'new',
            controller: NewPasswordCont,
            focusNode: _newFocus,
            label: "New password",
            hidden: pswdCont.hideNewPassword,
            onToggle: pswdCont.toggleNewPassword,
            textInputAction: TextInputAction.done,
            onChanged: pswdCont.setNewPasswordText,
            onSubmitted: (_) => _onUpdatePressed(),
          ),
          const SizedBox(height: 12),
          _strengthMeter(),
          const SizedBox(height: 22),
          _updateButton(),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: _Theme.mutedTextAlt),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  "Your details are sent securely.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _Theme.mutedTextAlt, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _Theme.emerald.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _Theme.emerald.withOpacity(0.25)),
          ),
          child: Icon(icon, color: _Theme.mint, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _Theme.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // Text field (glow on focus, reactive)
  // ------------------------------------------------------------
  Widget _field({
    required String keyName,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Obx(() {
      final bool focused = pswdCont.focusedField.value == keyName;
      return _fieldShell(
        focused: focused,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          cursorColor: _Theme.mint,
          style: const TextStyle(color: _Theme.primaryText, fontSize: 14.5),
          decoration: _decoration(label: label, icon: icon, focused: focused),
        ),
      );
    });
  }

  Widget _passwordField({
    required String keyName,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required RxBool hidden,
    required VoidCallback onToggle,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return Obx(() {
      final bool focused = pswdCont.focusedField.value == keyName;
      final bool hide = hidden.value;
      return _fieldShell(
        focused: focused,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: hide,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: textInputAction,
          cursorColor: _Theme.mint,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(color: _Theme.primaryText, fontSize: 14.5),
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
          decoration: _decoration(
            label: label,
            icon: Icons.lock_rounded,
            focused: focused,
            suffix: IconButton(
              tooltip: hide ? "Show password" : "Hide password",
              onPressed: onToggle,
              icon: Icon(
                hide ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: _Theme.mutedTextAlt,
                size: 20,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _fieldShell({required bool focused, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _Theme.surfaceBar,
        border: Border.all(
          color: focused ? _Theme.emerald.withOpacity(0.60) : _Theme.border,
          width: 1.4,
        ),
        boxShadow: focused
            ? [
          BoxShadow(
            color: _Theme.emerald.withOpacity(0.16),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ]
            : const [],
      ),
      child: child,
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    required bool focused,
    Widget? suffix,
  }) {
    return InputDecoration(
      border: InputBorder.none,
      labelText: label,
      labelStyle: const TextStyle(color: _Theme.mutedTextAlt, fontSize: 13.5),
      floatingLabelStyle: const TextStyle(
        color: _Theme.mint,
        fontWeight: FontWeight.w700,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(
        icon,
        color: focused ? _Theme.mint : _Theme.mutedTextAlt,
        size: 20,
      ),
      suffixIcon: suffix,
    );
  }

  // ------------------------------------------------------------
  // Password strength meter (UI hint only)
  // ------------------------------------------------------------
  Widget _strengthMeter() {
    return Obx(() {
      final int s = pswdCont.passwordStrength;
      final List<Color> colors = [
        _Theme.border,
        _Theme.danger,
        const Color(0xFFFB923C),
        _Theme.mint,
        _Theme.emerald,
      ];
      const labels = ["Enter a new password", "Weak", "Fair", "Good", "Strong"];
      final Color active = colors[s];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final bool on = i < s;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 5,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: on ? active : _Theme.border,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(
                s == 0 ? Icons.info_outline_rounded : Icons.security_rounded,
                size: 13,
                color: s == 0 ? _Theme.mutedTextAlt : active,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  s == 0 ? labels[0] : "Password strength: ${labels[s]}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: s == 0 ? _Theme.mutedTextAlt : active,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  // ------------------------------------------------------------
  // Update button (gradient, loading state)
  // ------------------------------------------------------------
  Widget _updateButton() {
    return Obx(() {
      final bool loading = pswdCont.isLoading.value;
      return Opacity(
        opacity: loading ? 0.85 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : _onUpdatePressed,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [_Theme.emerald, _Theme.mint],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _Theme.emerald.withOpacity(0.32),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(_Theme.bgTop),
                ),
              )
                  : const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_reset_rounded,
                        color: _Theme.bgTop, size: 20),
                    SizedBox(width: 9),
                    Text(
                      "Update password",
                      style: TextStyle(
                        color: _Theme.bgTop,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}