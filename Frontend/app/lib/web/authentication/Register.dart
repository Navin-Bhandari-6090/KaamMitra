import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../state management/getx/authentication/register_getx.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/design/bolbs_background.dart';
import 'Login.dart';


/// ============================================================
/// DARK GREEN REGISTER SCREEN
/// Forest background + AmbientBackground blobs + glass form card.
/// Fully responsive (any size, portrait / landscape), GetX only.
/// ============================================================

class RegColors {
  static const bg = Color(0xFF0F1F17);
  static const surface = Color(0xFF162E22);
  static const header = Color(0xFF12261C);
  static const text = Color(0xFFE6F4EA);
  static const muted = Color(0xFF8A9A90);
  static const accent = Color(0xFF22C55E);
  static const mint = Color(0xFF34D399);
  static const border = Color(0xFF234232);
}

class RegisterScreen extends StatefulWidget {
  final String User_JwtToken;
  const RegisterScreen({super.key, required this.User_JwtToken});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final String _tag;
  late final RegisterController c;

  @override
  void initState() {
    super.initState();
    _tag = UniqueKey().toString();
    c = Get.put(RegisterController(userJwtToken: widget.User_JwtToken),
        tag: _tag);
    Random_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
  }

  @override
  void dispose() {
    Get.delete<RegisterController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegColors.bg,
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
                final h = box.maxHeight.isFinite ? box.maxHeight : 0.0;
                return w >= 980 ? _wide(w, h) : _compact(w, h);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- layouts ------------------------------------------------------

  /// Wide: brand panel stays fixed on the left, the long form scrolls on the right.
  Widget _wide(double w, double h)
  {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h),
                  child: Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                      child: _hero(w),
                    ),
                  ),
                ),
              ),
              Positioned(top: 18, left: 24, child: _backButton()),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: Center(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: _formCard(compact: false, availableWidth: w * 6 / 11 - 64),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compact(double w, double h) {
    final pad = (w * 0.05).clamp(8.0, 28.0);
    final cardWidth = math.max(0.0, math.min(520.0, w - pad * 2));
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: h),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
            child: SizedBox(
              width: cardWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(alignment: Alignment.centerLeft, child: _backButton()),
                  const SizedBox(height: 8),
                  _reveal(0.0, 0.5, _logo(w < 380 ? 80 : 104)),
                  const SizedBox(height: 14),
                  _reveal(0.1, 0.6, _brandTitle(fontSize: w < 380 ? 26 : 32, center: true)),
                  const SizedBox(height: 8),
                  _reveal(
                    0.2,
                    0.7,
                    const Text(
                      'Create your account in a minute.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: RegColors.muted, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _formCard(compact: true, availableWidth: cardWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- hero (wide) ----------------------------------------------------

  Widget _hero(double w) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reveal(0.0, 0.5, _logo(140)),
          const SizedBox(height: 28),
          _reveal(0.1, 0.6, _brandTitle(fontSize: w > 1300 ? 52 : 42, center: false)),
          const SizedBox(height: 16),
          _reveal(
            0.2,
            0.7,
            const Text(
              'Create your account to book trusted services, or sign up as a provider to start offering yours.',
              style: TextStyle(color: RegColors.muted, fontSize: 16, height: 1.6),
            ),
          ),
          const SizedBox(height: 26),
          _reveal(
            0.3,
            0.8,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _Chip(icon: Icons.search_rounded, text: 'Find trusted help'),
                _Chip(icon: Icons.work_outline_rounded, text: 'Become a provider'),
                _Chip(icon: Icons.lock_rounded, text: 'Private & secure'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandTitle({required double fontSize, required bool center}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Join',
          style: TextStyle(
            color: RegColors.text.withOpacity(0.85),
            fontSize: fontSize * 0.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [RegColors.mint, RegColors.accent],
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
          color: RegColors.surface.withOpacity(0.7),
          border: Border.all(color: RegColors.border),
          boxShadow: [
            BoxShadow(
              color: RegColors.accent.withOpacity(0.35),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/logo/app_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.handyman_rounded, color: RegColors.mint),
        ),
      ),
    );
  }

  Widget _backButton() {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    return _reveal(
      0.0,
      0.4,
      Tooltip(
        message: 'Back',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: RegColors.surface.withOpacity(0.6),
              border: Border.all(color: RegColors.text.withOpacity(0.45), width: 1.2),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: RegColors.text, size: 20),
          ),
        ),
      ),
    );
  }

  // ---- form card -----------------------------------------------------

  Widget _formCard({required bool compact, required double availableWidth}) {
    final hPad = availableWidth < 340 ? 16.0 : (compact ? 22.0 : 36.0);
    return _reveal(
      0.15,
      0.8,
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: hPad, vertical: compact ? 26 : 36),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    RegColors.surface.withOpacity(0.80),
                    RegColors.header.withOpacity(0.70),
                  ],
                ),
                border: Border.all(color: RegColors.border, width: 1.2),
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
                    'Create account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 25 : 30,
                      fontWeight: FontWeight.w800,
                      color: RegColors.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fill in your details to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RegColors.muted, fontSize: 13.5),
                  ),
                  const SizedBox(height: 24),

                  // ---- Personal ----
                  const _Section(icon: Icons.person_rounded, title: 'Personal'),
                  LayoutBuilder(builder: (context, box) {
                    final first = _DarkField(
                      controller: c.firstNameCtrl,
                      ff: c.firstF,
                      label: 'First name',
                      icon: Icons.person_outline_rounded,
                      action: TextInputAction.next,
                    );
                    final last = _DarkField(
                      controller: c.lastNameCtrl,
                      ff: c.lastF,
                      label: 'Last name',
                      icon: Icons.person_outline_rounded,
                      action: TextInputAction.next,
                    );
                    if (box.maxWidth < 380) {
                      return Column(children: [first, const SizedBox(height: 14), last]);
                    }
                    return Row(children: [
                      Expanded(child: first),
                      const SizedBox(width: 12),
                      Expanded(child: last),
                    ]);
                  }),
                  const SizedBox(height: 14),
                  _DarkField(
                    controller: c.emailCtrl,
                    ff: c.emailF,
                    label: 'Email address',
                    hint: 'you@example.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _RoleField(c: c),

                  // ---- Contact ----
                  const _Section(icon: Icons.call_rounded, title: 'Contact'),
                  _DarkField(
                    controller: c.phoneCtrl,
                    ff: c.phoneF,
                    label: 'Phone number',
                    hint: '+91 98765 43210',
                    icon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _DarkField(
                    controller: c.whatsappCtrl,
                    ff: c.whatsappF,
                    label: 'WhatsApp number',
                    hint: '+91 98765 43210',
                    icon: Icons.chat_outlined,
                    keyboardType: TextInputType.phone,
                    action: TextInputAction.next,
                  ),

                  // ---- Location ----
                  const _Section(icon: Icons.location_on_rounded, title: 'Location'),
                  _DarkField(
                    controller: c.addressCtrl,
                    ff: c.addressF,
                    label: 'Address',
                    hint: 'Street, city',
                    icon: Icons.home_outlined,
                    keyboardType: TextInputType.streetAddress,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _LocationButton(c: c),
                  _DetectedChip(c: c),
                  const SizedBox(height: 14),
                  LayoutBuilder(builder: (context, box) {
                    final lat = _DarkField(
                      controller: c.latitudeCtrl,
                      ff: c.latF,
                      label: 'Latitude',
                      hint: 'e.g. 26.8123',
                      icon: Icons.explore_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      action: TextInputAction.next,
                    );
                    final lng = _DarkField(
                      controller: c.longitudeCtrl,
                      ff: c.lngF,
                      label: 'Longitude',
                      hint: 'e.g. 87.2810',
                      icon: Icons.explore_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      action: TextInputAction.next,
                    );
                    if (box.maxWidth < 380) {
                      return Column(children: [lat, const SizedBox(height: 14), lng]);
                    }
                    return Row(children: [
                      Expanded(child: lat),
                      const SizedBox(width: 12),
                      Expanded(child: lng),
                    ]);
                  }),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: RegColors.muted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tip: long-press your location in Google Maps and copy the two decimal values (latitude first, then longitude).',
                          style: TextStyle(
                              color: RegColors.muted, fontSize: 11.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),

                  // ---- Security ----
                  const _Section(icon: Icons.shield_rounded, title: 'Security'),
                  _DarkField(
                    controller: c.passCtrl,
                    ff: c.passF,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    keyboardType: TextInputType.visiblePassword,
                    obscure: c.obscurePass,
                    onToggleObscure: c.toggleObscurePass,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _DarkField(
                    controller: c.retypeCtrl,
                    ff: c.retypeF,
                    label: 'Retype password',
                    icon: Icons.lock_reset_rounded,
                    keyboardType: TextInputType.visiblePassword,
                    obscure: c.obscureRetype,
                    onToggleObscure: c.toggleObscureRetype,
                    action: TextInputAction.done,
                  ),
                  const SizedBox(height: 26),
                  _GlowButton(
                    label: 'Create account',
                    pressed: c.buttonPressed,
                    loading: c.isLoading,
                    onTap: () async {
                      try {
                        final ok = await _confirmCreate(context);
                        if (ok == true && context.mounted) {
                          await c.createAccountFlow(context);
                        }
                      } catch (e) {
                        print("Exception in create account tap: $e");
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: RegColors.muted, fontSize: 13),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: RegColors.mint,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(
                                  User_JwtToken: widget.User_JwtToken),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign in',
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

/// Confirm / cancel before writing to the database.
Future<bool?> _confirmCreate(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (ctx) => AlertDialog(
      backgroundColor: RegColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: RegColors.border),
      ),
      title: const Text('Create account?',
          style: TextStyle(color: RegColors.text, fontWeight: FontWeight.w800)),
      content: const Text(
        'Please make sure your details are correct before continuing.',
        style: TextStyle(color: RegColors.muted, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel', style: TextStyle(color: RegColors.muted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: RegColors.accent,
            foregroundColor: RegColors.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}

// ====================================================================
// Reusable pieces (stateless, Rx driven)
// ====================================================================

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: RegColors.mint),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: RegColors.mint,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: RegColors.border, height: 1)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: RegColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: RegColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: RegColors.mint),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: RegColors.text, fontSize: 13, fontWeight: FontWeight.w600),
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
    required this.ff,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.obscure,
    this.onToggleObscure,
    this.action,
  });

  final TextEditingController controller;
  final FieldFocus ff;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final RxBool? obscure;
  final VoidCallback? onToggleObscure;
  final TextInputAction? action;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final f = ff.focused.value;
      final hidden = obscure?.value ?? false;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: f ? RegColors.accent : RegColors.border, width: 1.4),
          boxShadow: f
              ? [
            BoxShadow(
              color: RegColors.accent.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
              : const [],
        ),
        child: TextField(
          controller: controller,
          focusNode: ff.node,
          obscureText: hidden,
          keyboardType: keyboardType,
          textInputAction: action,
          cursorColor: RegColors.mint,
          style: const TextStyle(fontSize: 14.5, color: RegColors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: RegColors.bg.withOpacity(0.65),
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
                color: RegColors.muted.withOpacity(0.6), fontSize: 13),
            labelStyle: TextStyle(
                color: f ? RegColors.mint : RegColors.muted, fontSize: 13.5),
            prefixIcon:
            Icon(icon, size: 19, color: f ? RegColors.mint : RegColors.muted),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
              splashRadius: 18,
              onPressed: onToggleObscure,
              icon: Icon(
                hidden
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 19,
                color: RegColors.muted,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          ),
        ),
      );
    });
  }
}

class _RoleField extends StatelessWidget {
  const _RoleField({required this.c});
  final RegisterController c;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => c.roleFocused.value = v,
      child: Obx(() {
        final f = c.roleFocused.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: f ? RegColors.accent : RegColors.border, width: 1.4),
            boxShadow: f
                ? [
              BoxShadow(
                color: RegColors.accent.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
                : const [],
          ),
          child: DropdownButtonFormField<String>(
            value: c.role.value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: RegColors.muted),
            style: const TextStyle(fontSize: 14.5, color: RegColors.text),
            dropdownColor: RegColors.surface,
            borderRadius: BorderRadius.circular(14),
            decoration: InputDecoration(
              filled: true,
              fillColor: RegColors.bg.withOpacity(0.65),
              labelText: 'I am signing up as',
              labelStyle: TextStyle(
                  color: f ? RegColors.mint : RegColors.muted, fontSize: 13.5),
              prefixIcon: Icon(Icons.badge_outlined,
                  size: 19, color: f ? RegColors.mint : RegColors.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
            ),
            items: const ['User', 'Provider']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: c.selectRole,
          ),
        );
      }),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.c});
  final RegisterController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fetching = c.locationCont.isFetchingLocation.value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: fetching ? null : c.handleUseCurrentLocation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            decoration: BoxDecoration(
              color: RegColors.accent.withOpacity(fetching ? 0.06 : 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: RegColors.mint.withOpacity(fetching ? 0.35 : 0.7),
                  width: 1.4),
            ),
            child: Center(
              child: fetching
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: RegColors.mint),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text('Getting your location...',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: RegColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5)),
                  ),
                ],
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.my_location_rounded,
                      color: RegColors.mint, size: 18),
                  SizedBox(width: 9),
                  Flexible(
                    child: Text('Use my current location',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: RegColors.mint,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5)),
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

class _DetectedChip extends StatelessWidget {
  const _DetectedChip({required this.c});
  final RegisterController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lat = c.locationCont.latitude.value;
      final lng = c.locationCont.longitude.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: (lat == null || lng == null)
            ? const SizedBox.shrink(key: ValueKey('no-fix'))
            : Container(
          key: const ValueKey('fix'),
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: RegColors.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RegColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: RegColors.mint, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Detected: $lat, $lng',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: RegColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
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
                  colors: [RegColors.accent, RegColors.mint],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: RegColors.accent.withOpacity(0.40),
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
                    strokeWidth: 2.4, color: RegColors.bg),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: RegColors.bg,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: RegColors.bg),
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
        RegColors.accent.withOpacity(0.07));
    _layer(canvas, size, progress * 2 * math.pi + 2.2, 24, 0.92,
        RegColors.mint.withOpacity(0.06));
  }

  void _layer(Canvas canvas, Size size, double phase, double amp,
      double baseline, Color color) {
    final path = Path();
    final base = size.height * baseline;
    path.moveTo(0, base);
    for (double x = 0; x <= size.width; x += 8) {
      path.lineTo(
          x,
          base +
              amp * math.sin((x / math.max(size.width, 1) * 2 * math.pi) + phase));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress;
}