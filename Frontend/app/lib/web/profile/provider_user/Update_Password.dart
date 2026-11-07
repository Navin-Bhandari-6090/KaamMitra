import 'package:app/constant/variable.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state management/getx/profile/provider_user/update_password_getx.dart';
import '../../common method/forget_pswd_credentials_download.dart';



/// =============================================================================
/// DARK GREEN PALETTE (kept identical across the app for brand consistency)
/// =============================================================================
class _Palette {
  static const Color bodyBg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color textPrimary = Color(0xFFE6F4EA);
  static const Color textMuted = Color(0xFF8A9A90);
  static const Color headerFooter = Color(0xFF12261C);
  static const Color accent = Color(0xFF22C55E);
  static const Color accentMint = Color(0xFF34D399);
  static const Color borderColor = Color(0xFF234232);
}

class UpdatePasswordScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String PhoneNumber;
  final String WhatsappNumber;


  const UpdatePasswordScreen({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.PhoneNumber,
    required this.WhatsappNumber,
  });

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen>
    with SingleTickerProviderStateMixin {
  late final UpdatePasswordGetx controller;
  final String _tag = UniqueKey().toString();

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(UpdatePasswordGetx(), tag: _tag);
    controller.init(email: widget.User_Email, jwtToken: widget.User_JwtToken);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    Get.delete<UpdatePasswordGetx>(tag: _tag);
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Responsive helpers
  // ---------------------------------------------------------------------
  double _horizontalPadding(double width) {
    if (width < 420) return 18;
    if (width < 700) return 32;
    if (width < 1100) return 60;
    return (width - 1100) / 2 + 80;
  }

  double _cardMaxWidth(double width, Orientation orientation) {
    if (width < 500) return double.infinity;
    if (orientation == Orientation.landscape && width < 900) return 460;
    return 480;
  }

  Widget _glowBlob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: 130, spreadRadius: 46)],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF16301F),
                _Palette.bodyBg,
                Color(0xFF0B1712),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(top: -70, right: -60, child: _glowBlob(_Palette.accent.withOpacity(0.15), 250)),
        Positioned(top: 260, left: -100, child: _glowBlob(_Palette.accentMint.withOpacity(0.09), 220)),
        Positioned(bottom: -100, right: -70, child: _glowBlob(_Palette.accent.withOpacity(0.11), 250)),
        Positioned(bottom: 120, left: -70, child: _glowBlob(_Palette.accentMint.withOpacity(0.09), 220)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _Palette.headerFooter,
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
                color: _Palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _Palette.accent.withOpacity(0.55), width: 1.4),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    // Bordered container + primary-text-colored arrow so the
                    // back action stays clearly visible on the dark surface.
                    child: Icon(Icons.arrow_back_rounded, color: _Palette.textPrimary, size: 20),
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
              gradient: const LinearGradient(colors: [_Palette.accent, _Palette.accentMint]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: _Palette.accent.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.lock_reset_rounded, color: _Palette.bodyBg, size: 19),
          ),
          const SizedBox(width: 12),
          const Text(
            'Update Password',
            style: TextStyle(
              color: _Palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async
  {
    try {
      final String newPassword = _newPasswordController.text;
      final String confirmPassword = _confirmPasswordController.text;

      final String? validationError = controller.validate(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (validationError != null) {
        controller.errorText.value = validationError;
        return;
      }

      controller.errorText.value = '';
      FocusScope.of(context).unfocus();

      final bool success = await controller.UpdatePassword(
          NewPassword: newPassword);

      if (!mounted) return;

      if (success)
      {

        await downloadCredentialsPdf(
          email: widget.User_Email,
          phone:widget.PhoneNumber,
          whatsapp:widget.WhatsappNumber,
          password: _confirmPasswordController.text.trim(),
        );

        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSnack("Password updated successfully.", isError: false);
      } else {
        _showSnack(
            "Failed to update password. Please try again.", isError: true);
      }
    }catch(e){
      Toast.Toastmsg("Update password failed. Please try again later.");
      return ;
    }


  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? Colors.white : _Palette.bodyBg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isError ? Colors.white : _Palette.bodyBg, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? Colors.red.shade700 : _Palette.accentMint,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bodyBg,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, outer) {
          final Orientation orientation = MediaQuery.of(context).orientation;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double horizontalPadding = _horizontalPadding(width);
                final double cardMaxWidth = _cardMaxWidth(width, orientation);

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: outer.maxHeight),
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildBackground()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 28,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: cardMaxWidth),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildCard(width),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(double width) {
    return Container(
      padding: EdgeInsets.all(width < 420 ? 20 : 30),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Icon badge ---
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_Palette.accent.withOpacity(0.22), _Palette.accentMint.withOpacity(0.12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _Palette.accent.withOpacity(0.4)),
            ),
            child: const Icon(Icons.shield_moon_outlined, color: _Palette.accentMint, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            'Set a new password',
            style: TextStyle(
              color: _Palette.textPrimary,
              fontSize: width < 420 ? 20 : 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a strong password you haven\'t used before to keep your account secure.',
            style: TextStyle(color: _Palette.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 26),

          // --- New password field ---
          _PasswordField(
            controller: _newPasswordController,
            focusNode: _newPasswordFocus,
            label: 'New Password',
            hint: 'Enter new password',
            obscureListenable: this.controller.obscureNewPassword,
            onToggleObscure: this.controller.toggleNewPasswordVisibility,
            onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // --- Confirm password field ---
          _PasswordField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            label: 'Confirm Password',
            hint: 'Re-enter new password',
            obscureListenable: this.controller.obscureConfirmPassword,
            onToggleObscure: this.controller.toggleConfirmPasswordVisibility,
            onSubmitted: (_) => _handleSubmit(),
            textInputAction: TextInputAction.done,
          ),

          // --- Inline validation error ---
          Obx(() {
            final error = this.controller.errorText.value;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: error.isEmpty
                  ? const SizedBox(height: 0, key: ValueKey('no-error'))
                  : Padding(
                key: const ValueKey('has-error'),
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // --- Password requirement hints ---
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _RequirementChip(text: 'At least 6 characters'),
              _RequirementChip(text: 'Both fields match'),
            ],
          ),

          const SizedBox(height: 26),

          // --- Submit button ---
          Obx(() {
            final bool submitting = this.controller.isSubmitting.value;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: submitting ? null : _handleSubmit,
                child: Ink(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: submitting
                          ? [_Palette.accent.withOpacity(0.5), _Palette.accentMint.withOpacity(0.5)]
                          : [_Palette.accent, _Palette.accentMint],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: submitting
                        ? []
                        : [
                      BoxShadow(
                        color: _Palette.accent.withOpacity(0.32),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: submitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(_Palette.bodyBg),
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, color: _Palette.bodyBg, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Update Password',
                          style: TextStyle(
                            color: _Palette.bodyBg,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 18),

          // --- Footer note ---
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _Palette.textMuted.withOpacity(0.8), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "You'll stay signed in on this device after updating.",
                  style: TextStyle(color: _Palette.textMuted, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// PASSWORD FIELD — bordered, focus-aware, with a show/hide toggle driven by
// GetX (RxBool passed in), no setState for app state (only a tiny local
// focus-highlight flag, which is Flutter focus plumbing, not app state).
// ===========================================================================
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final RxBool obscureListenable;
  final VoidCallback onToggleObscure;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.obscureListenable,
    required this.onToggleObscure,
    required this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _hasFocus = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: _Palette.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _Palette.bodyBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasFocus ? _Palette.accent.withOpacity(0.75) : _Palette.borderColor,
              width: _hasFocus ? 1.6 : 1.2,
            ),
            boxShadow: _hasFocus
                ? [BoxShadow(color: _Palette.accent.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4))]
                : [],
          ),
          child: Obx(() {
            final bool obscure = widget.obscureListenable.value;
            return TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              obscureText: obscure,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(color: _Palette.textPrimary, fontSize: 14.5),
              cursorColor: _Palette.accentMint,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: _Palette.textMuted.withOpacity(0.6), fontSize: 14),
                prefixIcon: Icon(Icons.lock_outline_rounded, color: _Palette.textMuted, size: 19),
                suffixIcon: IconButton(
                  onPressed: widget.onToggleObscure,
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _Palette.textMuted,
                    size: 19,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ===========================================================================
// REQUIREMENT CHIP — small pill hint under the fields.
// ===========================================================================
class _RequirementChip extends StatelessWidget {
  final String text;
  const _RequirementChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Palette.bodyBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, color: _Palette.accentMint, size: 12),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: _Palette.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}