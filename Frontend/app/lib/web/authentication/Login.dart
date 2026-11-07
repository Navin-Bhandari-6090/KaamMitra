import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../state management/getx/authentication/login_getx.dart';
import '../common widget/design/bolbs_background.dart';
import 'Register.dart';

import 'login_forget_pswd.dart';

/// ============================================================
/// DARK GREEN LOGIN SCREEN
/// Forest background + AmbientBackground blobs + glass card.
/// Fully responsive (any width / height, portrait / landscape),
/// GetX only (zero setState), staggered entrance animations.
/// ============================================================

class LoginColors {
  static const bg = Color(0xFF0F1F17);
  static const surface = Color(0xFF162E22);
  static const header = Color(0xFF12261C);
  static const text = Color(0xFFE6F4EA);
  static const muted = Color(0xFF8A9A90);
  static const accent = Color(0xFF22C55E);
  static const mint = Color(0xFF34D399);
  static const border = Color(0xFF234232);
}

class LoginScreen extends StatefulWidget {
  final String User_JwtToken;
  const LoginScreen({super.key, required this.User_JwtToken});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final String _tag;
  late final LoginController c;

  @override
  void initState() {
    super.initState();
    _tag = UniqueKey().toString();
    c = Get.put(LoginController(userJwtToken: widget.User_JwtToken), tag: _tag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.jwtVerify(context);
    });
  }

  @override
  void dispose() {
    Get.delete<LoginController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: c.wave,
                builder: (_, __) => CustomPaint(
                  painter: _WavePainter(progress: c.wave.value),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final h = box.maxHeight;
                final wide = w >= 900;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h.isFinite ? h : 0),
                    child: Center(
                      child: wide ? _wideLayout(w) : _compactLayout(w),
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

  // ---- layouts ------------------------------------------------------

  Widget _wideLayout(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w > 1300 ? 72 : 40, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: Center(child: _hero(w))),
          const SizedBox(width: 32),
          Expanded(
            flex: 5,
            child: Center(child: _formCard(compact: false, availableWidth: w * 5 / 11)),
          ),
        ],
      ),
    );
  }

  Widget _compactLayout(double w) {
    final pad = (w * 0.05).clamp(8.0, 28.0);
    final cardWidth = math.max(0.0, math.min(440.0, w - pad * 2));
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _reveal(0.0, 0.5, _logo(w < 380 ? 96 : 124)),
          SizedBox(height: w < 380 ? 12 : 18),
          _reveal(
            0.1,
            0.6,
            _brandTitle(fontSize: w < 380 ? 26 : 32, center: true),
          ),
          const SizedBox(height: 8),
          _reveal(
            0.2,
            0.7,
            SizedBox(
              width: cardWidth,
              child: const Text(
                'Sign in to pick up right where you left off.',
                textAlign: TextAlign.center,
                style: TextStyle(color: LoginColors.muted, fontSize: 14, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: cardWidth,
            child: _formCard(compact: true, availableWidth: cardWidth),
          ),
        ],
      ),
    );
  }

  // ---- hero (wide only) ----------------------------------------------

  Widget _hero(double w) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reveal(0.0, 0.5, _logo(150)),
          const SizedBox(height: 28),
          _reveal(0.1, 0.6, _brandTitle(fontSize: w > 1300 ? 54 : 44, center: false)),
          const SizedBox(height: 16),
          _reveal(
            0.2,
            0.7,
            const Text(
              'Sign in to pick up right where you left off — your bookings and services are waiting for you.',
              style: TextStyle(color: LoginColors.muted, fontSize: 16, height: 1.6),
            ),
          ),
          const SizedBox(height: 28),
          _reveal(
            0.3,
            0.8,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _Chip(icon: Icons.verified_user_rounded, text: 'Trusted providers'),
                _Chip(icon: Icons.bolt_rounded, text: 'Quick booking'),
                _Chip(icon: Icons.lock_rounded, text: 'Secure login'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandTitle({required double fontSize, required bool center}) {
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome back to',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: LoginColors.text.withOpacity(0.85),
            fontSize: fontSize * 0.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [LoginColors.mint, LoginColors.accent],
          ).createShader(r),
          child: Text(
            'KaamMitra',
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _logo(double size) {
    return AnimatedBuilder(
      animation: c.wave,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(c.wave.value * 2 * math.pi) * 5),
        child: child,
      ),
      child: Container(
        width: size + 20,
        height: size + 20,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: LoginColors.surface.withOpacity(0.7),
          border: Border.all(color: LoginColors.border),
          boxShadow: [
            BoxShadow(
              color: LoginColors.accent.withOpacity(0.35),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/logo/app_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.handyman_rounded, color: LoginColors.mint),
        ),
      ),
    );
  }

  // ---- form card ------------------------------------------------------

  Widget _formCard({required bool compact, required double availableWidth}) {
    final hPad = availableWidth < 340 ? 16.0 : (compact ? 22.0 : 36.0);
    final vPad = compact ? 26.0 : 38.0;
    return _reveal(
      0.15,
      0.8,
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    LoginColors.surface.withOpacity(0.80),
                    LoginColors.header.withOpacity(0.70),
                  ],
                ),
                border: Border.all(color: LoginColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 26 : 30,
                      fontWeight: FontWeight.w800,
                      color: LoginColors.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your details to access your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: LoginColors.muted, fontSize: 13.5),
                  ),
                  const SizedBox(height: 26),
                  _DarkField(
                    controller: c.emailCtrl,
                    focusNode: c.emailFocus,
                    focused: c.emailFocused,
                    label: 'Email address',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _DarkField(
                    controller: c.passCtrl,
                    focusNode: c.passFocus,
                    focused: c.passFocused,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    keyboardType: TextInputType.visiblePassword,
                    obscure: c.obscure,
                    onToggleObscure: c.toggleObscure,
                    action: TextInputAction.done,
                    onSubmitted: () => c.submit(context),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: LoginColors.mint,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return LogForPswd(User_JwtToken: widget.User_JwtToken);
                          }),
                        );
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GlowButton(
                    label: 'Login',
                    pressed: c.buttonPressed,
                    loading: c.isLoading,
                    onTap: () => c.submit(context),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: LoginColors.muted, fontSize: 13),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: LoginColors.mint,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RegisterScreen(User_JwtToken: widget.User_JwtToken),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- entrance helper -----------------------------------------------

  Widget _reveal(double start, double end, Widget child) {
    final a = c.stagger(start, end);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: a.drive(Tween(begin: const Offset(0, 0.12), end: Offset.zero)),
        child: child,
      ),
    );
  }
}

// ====================================================================
// Reusable pieces (stateless, GetX/Rx driven)
// ====================================================================

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: LoginColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: LoginColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: LoginColors.mint),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LoginColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure,
    this.onToggleObscure,
    this.action,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final RxBool focused;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final RxBool? obscure;
  final VoidCallback? onToggleObscure;
  final TextInputAction? action;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocused = focused.value;
      final hidden = obscure?.value ?? false;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused ? LoginColors.accent : LoginColors.border,
            width: 1.4,
          ),
          boxShadow: isFocused
              ? [
            BoxShadow(
              color: LoginColors.accent.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
              : const [],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: hidden,
          keyboardType: keyboardType,
          textInputAction: action,
          onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
          cursorColor: LoginColors.mint,
          style: const TextStyle(fontSize: 14.5, color: LoginColors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: LoginColors.bg.withOpacity(0.65),
            labelText: label,
            labelStyle: TextStyle(
              color: isFocused ? LoginColors.mint : LoginColors.muted,
              fontSize: 13.5,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            prefixIcon: Icon(
              icon,
              size: 19,
              color: isFocused ? LoginColors.mint : LoginColors.muted,
            ),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
              splashRadius: 18,
              onPressed: onToggleObscure,
              icon: Icon(
                hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 19,
                color: LoginColors.muted,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          ),
        ),
      );
    });
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.label,
    required this.pressed,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final RxBool pressed;
  final RxBool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = loading.value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => pressed.value = true,
        onTapUp: (_) => pressed.value = false,
        onTapCancel: () => pressed.value = false,
        onTap: isLoading ? null : onTap,
        child: AnimatedScale(
          scale: pressed.value ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: isLoading ? 0.8 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [LoginColors.accent, LoginColors.mint],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LoginColors.accent.withOpacity(0.40),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: LoginColors.bg,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: LoginColors.bg,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: LoginColors.bg),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Soft animated waves along the bottom (very low opacity, never blocks content).
class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _layer(canvas, size, progress * 2 * math.pi, 18, 0.86,
        LoginColors.accent.withOpacity(0.07));
    _layer(canvas, size, progress * 2 * math.pi + 2.2, 24, 0.92,
        LoginColors.mint.withOpacity(0.06));
  }

  void _layer(Canvas canvas, Size size, double phase, double amp,
      double baseline, Color color) {
    final path = Path();
    final base = size.height * baseline;
    path.moveTo(0, base);
    for (double x = 0; x <= size.width; x += 8) {
      path.lineTo(
          x, base + amp * math.sin((x / math.max(size.width, 1) * 2 * math.pi) + phase));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress;
}