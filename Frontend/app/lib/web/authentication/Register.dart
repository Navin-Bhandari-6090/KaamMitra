import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../constant/Server_Database.dart';
import '../../state management/bloc/common state/common_variable_bloc.dart';
import '../common method/Commmon_Method.dart';
import '../common widget/toast.dart';
import '../common widget/toast_long_period.dart';
import 'Error_page.dart';
import 'Login.dart';

/// ============================================================
/// GREEN REGISTER SCREEN — fully responsive (mobile / tablet /
/// desktop, portrait / landscape) with wave animation + staggered
/// entrance animations. Matches LoginScreen's visual language.
///
/// Fields: First name, Last name, Email, Phone number, WhatsApp
/// number, Role (User / Provider), Password, Retype password.
///
/// Uses your existing logo:
///   assets/images/logo/app_logo.png
/// ============================================================

class AppColors {
  static const bgDeep = Color(0xFF07271B);
  static const bgMid = Color(0xFF0E4430);
  static const bgSoft = Color(0xFF14603F);
  static const accent = Color(0xFF3DDC97);
  static const accentSoft = Color(0xFFB9F3D6);
  static const card = Color(0xFFF6FBF8);
  static const textDark = Color(0xFF0B2A1D);
  static const textMuted = Color(0xFF5E7A6C);
  static const fieldFill = Color(0xFFEFF6F2);
}

class RegisterScreen extends StatefulWidget {
  final String User_JwtToken;
  const RegisterScreen({super.key, required this.User_JwtToken});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {

  late final AnimationController _entrance;
  late final AnimationController _wave;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _retypeCtrl = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _toast = Toastget_Long_Period();

  @override
  void initState() {
    super.initState();
    JwtVerify(Jwt_Token:widget.User_JwtToken);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  Future<void> JwtVerify({required String Jwt_Token})async
  {
    int Result=await RandomJwtVerify(Jwt_Token: Jwt_Token);
    if (Result==1)
    {
      return;
    } else
    {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => ErrorPage()
          )
        ,
            (route) => false,
      );
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _wave.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _passCtrl.dispose();
    _retypeCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }


  Future<int> _handleCreateAccount(BuildContext context) async {
    try {
      // ---------------------------------------------------------
      // Get values from text fields
      // ---------------------------------------------------------
      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final whatsapp = _whatsappCtrl.text.trim();
      final password = _passCtrl.text.trim();
      final retype = _retypeCtrl.text.trim();
      final latitude = _latitude.text.trim();
      final longitude = _longitude.text.trim();

      // Get role from Bloc
      final blocState = context.read<CommonVariableBloc>().state;
      final role = blocState.Role;

      // ---------------------------------------------------------
      // Validation
      // ---------------------------------------------------------

      if (firstName.isEmpty) {
        _toast.Toastmsg('First name is required');
        print('First name is required');
        return 1;
      }

      if (lastName.isEmpty) {
        _toast.Toastmsg('Last name is required');
        print('Last name is required');
        return 2;
      }

      if (email.isEmpty) {
        _toast.Toastmsg('Email is required');
        print('Email is required');
        return 3;
      }

      if (!email.contains('@') || !email.contains('.com')) {
        _toast.Toastmsg('Enter a valid email address');
        print('Enter a valid email address');
        return 4;
      }

      if (phone.isEmpty) {
        _toast.Toastmsg('Phone number is required');
        print('Phone number is required');
        return 5;
      }

      if (!phone.startsWith('+')) {
        _toast.Toastmsg('Phone number must start with +');
        print('Phone number must start with +');
        return 6;
      }

      if (whatsapp.isEmpty) {
        _toast.Toastmsg('WhatsApp number is required');
        print('WhatsApp number is required');
        return 7;
      }

      if (!whatsapp.startsWith('+')) {
        _toast.Toastmsg('WhatsApp number must start with +');
        print('WhatsApp number must start with +');
        return 8;
      }

      if (password.isEmpty) {
        _toast.Toastmsg('Password is required');
        print('Password is required');
        return 9;
      }

      if (retype.isEmpty) {
        _toast.Toastmsg('Please retype your password');
        print('Please retype your password');
        return 10;
      }

      if (role == null || role.isEmpty) {
        _toast.Toastmsg('Role is required.');
        print('Role is required.');
        return 10;
      }

      if (latitude.isEmpty) {
        _toast.Toastmsg('Latitude is required.');
        print('Latitude is required.');
        return 10;
      }

      if (longitude.isEmpty) {
        _toast.Toastmsg('Longitude is required.');
        print('Longitude is required.');
        return 10;
      }

      if (password != retype) {
        _toast.Toastmsg('Passwords do not match');
        print('Passwords do not match');
        return 11;
      }

      // ---------------------------------------------------------
      // Validate latitude and longitude
      // ---------------------------------------------------------

      final latitudeValue = double.tryParse(latitude);
      final longitudeValue = double.tryParse(longitude);

      if (latitudeValue == null) {
        _toast.Toastmsg('Invalid latitude');
        print('Invalid latitude');
        return 10;
      }

      if (longitudeValue == null) {
        _toast.Toastmsg('Invalid longitude');
        print('Invalid longitude');
        return 10;
      }

      // ---------------------------------------------------------
      // API URL
      // ---------------------------------------------------------

      const String url =
          Backend_Server_Url + "api/Authentication/signin";

      print('----------------------------------------');
      print('Creating account...');
      print('URL: $url');
      print('First Name: $firstName');
      print('Last Name: $lastName');
      print('Email: $email');
      print('Phone: $phone');
      print('WhatsApp: $whatsapp');
      print('Latitude: $latitudeValue');
      print('Longitude: $longitudeValue');
      print('Role: $role');
      print('Photo: Not selected');
      print('----------------------------------------');

      // ---------------------------------------------------------
      // Create Multipart Request
      // ---------------------------------------------------------
      //
      // We use multipart/form-data because your backend is now
      // using [FromForm].
      //
      // There is NO photo/file because signup does not have
      // a photo selection option.
      // ---------------------------------------------------------

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      // ---------------------------------------------------------
      // Add Authorization header
      // ---------------------------------------------------------

      request.headers['Authorization'] =
      'Bearer ${widget.User_JwtToken}';

      // ---------------------------------------------------------
      // Add form fields
      // ---------------------------------------------------------

      request.fields['FirstName'] = firstName;
      request.fields['LastName'] = lastName;
      request.fields['Email'] = email;
      request.fields['PhoneNumber'] = phone;
      request.fields['WhatsappPhoneNumber'] = whatsapp;
      request.fields['Password'] = password;
      request.fields['Latitude'] = latitudeValue.toString();
      request.fields['Longitude'] = longitudeValue.toString();
      request.fields['Role'] = role;

      // ---------------------------------------------------------
      // Send request
      // ---------------------------------------------------------

      print('Sending signup request...');

      final response = await request.send();

      print('Signup response status code: ${response.statusCode}');

      // Read backend response body
      final responseBody = await response.stream.bytesToString();

      print('Signup response body: $responseBody');

      // ---------------------------------------------------------
      // Handle response status codes
      // ---------------------------------------------------------

      if (response.statusCode == 200) {
        _toast.Toastmsg('Account created successfully');

        print('Account created successfully');
        print('Data insert in userinfo table success.');

        return 1;
      }

      // ---------------------------------------------------------
      // Email already exists
      // Backend: 502
      // ---------------------------------------------------------

      else if (response.statusCode == 502) {
        _toast.Toastmsg(
          'Account created fail.Email already exists.',
        );

        print('Account created fail.Email already exists.');
        print('Email already exists.');

        return 3;
      }

      // ---------------------------------------------------------
      // Invalid data
      // Backend: 501
      // ---------------------------------------------------------

      else if (response.statusCode == 501) {
        _toast.Toastmsg(
          'Account created fail.Provided data are not in correct format.',
        );

        print(
          'Account created fail.Provided data are not in correct format.',
        );

        return 4;
      }

      // ---------------------------------------------------------
      // Backend exception
      // Backend: 500
      // ---------------------------------------------------------

      else if (response.statusCode == 500) {
        _toast.Toastmsg(
          'Account created fail.Exception caught in backend.',
        );

        print(
          'Account created fail.Exception caught in backend.',
        );

        return 5;
      }

      // ---------------------------------------------------------
      // Other status codes
      // ---------------------------------------------------------

      else {
        print(
          'Unexpected status code = ${response.statusCode}',
        );

        _toast.Toastmsg(
          'Account created fail.Data insert in userinfo table fail.',
        );

        print(
          'Account created fail.Data insert in userinfo table fail.',
        );

        return 2;
      }
    } catch (E) {
      // ---------------------------------------------------------
      // Connection / Flutter / unexpected error
      // ---------------------------------------------------------

      print('Signup exception: $E');

      _toast.Toastmsg(
        'Account created fail.Please try again.Server error.',
      );

      print(
        'Account created fail.Please try again.Server error.',
      );

      return 0;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isWide = width >= 980;
          final isPortraitCompact = width < 620;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: isWide
                  ? _WideLayout(state: this, panelFlex: width > 1300 ? 5 : 4)
                  : _CompactLayout(
                      state: this,
                      isPortraitCompact: isPortraitCompact,
                    ),
            ),
          );
        },
      ),
    );
  }

  // ---- shared pieces -----------------------------------------------

  Widget wavePanel({
    required double height,
    double? width,
    bool showText = true,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _wave,
            builder: (context, _) =>
                CustomPaint(painter: _WavePainter(progress: _wave.value)),
          ),
          if (showText)
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _stagger(0.0, 0.5),
                    child: SlideTransition(
                      position: _stagger(0.0, 0.5).drive(
                        Tween(begin: const Offset(0, 0.15), end: Offset.zero),
                      ),
                      child: Image.asset(
                        'assets/images/logo/app_logo.png',
                        width: 84,
                        height: 84,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeTransition(
                    opacity: _stagger(0.1, 0.6),
                    child: SlideTransition(
                      position: _stagger(0.1, 0.6).drive(
                        Tween(begin: const Offset(0, 0.2), end: Offset.zero),
                      ),
                      child: const Text(
                        'Join\nKaamMitra.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _stagger(0.2, 0.7),
                    child: SizedBox(
                      width: 320,
                      child: Text(
                        'Create your account to book trusted services, or sign up as a provider to start offering yours.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget formCard(BuildContext context, {required bool compact}) {
    return FadeTransition(
      opacity: _stagger(0.15, 0.7),
      child: SlideTransition(
        position: _stagger(
          0.15,
          0.7,
        ).drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 460),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 22 : 40,
            vertical: compact ? 28 : 40,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo/app_logo.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'KaamMitra',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'Create account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fill in your details to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
              ),
              const SizedBox(height: 26),

              // First / last name — side by side on wider screens, stacked on narrow
              Builder(
                builder: (context) {
                  final stack = MediaQuery.of(context).size.width < 420;
                  final firstField = _GreenField(
                    controller: _firstNameCtrl,
                    label: 'First name',
                    icon: Icons.person_outline_rounded,
                  );
                  final lastField = _GreenField(
                    controller: _lastNameCtrl,
                    label: 'Last name',
                    icon: Icons.person_outline_rounded,
                  );
                  if (stack) {
                    return Column(
                      children: [
                        firstField,
                        const SizedBox(height: 16),
                        lastField,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: firstField),
                      const SizedBox(width: 14),
                      Expanded(child: lastField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              _GreenField(
                controller: _emailCtrl,
                label: 'Email address',
                hintText: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _GreenField(
                controller: _phoneCtrl,
                label: 'Phone number',
                hintText: '+91 98765 43210',
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _GreenField(
                controller: _whatsappCtrl,
                label: 'WhatsApp number',
                hintText: '+91 98765 43210',
                icon: Icons.chat_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _GreenField(
                controller: _latitude,
                label: 'Latitude',
                hintText:
                    '23.567(Long press on your current location in google map.First decimal value of google map)',
                icon: Icons.map,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _GreenField(
                controller: _longitude,
                label: 'Longitude',
                hintText:
                    '23.567(Long press on your current location in google map.Second decimal value of google map)',
                icon: Icons.map,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              BlocBuilder<CommonVariableBloc, CommonVariableState>(
                builder: (context, state) {
                  return _GreenDropdown(
                    value: state.Role!,
                    items: const ['User', 'Provider'],
                    label: 'I am signing up as',
                    icon: Icons.badge_outlined,
                    onChanged: (value) {
                      context.read<CommonVariableBloc>().add(
                        SelectUserRole(Role: value),
                      );
                    },
                  );
                },
              ),


              const SizedBox(height: 16),
              //
              // _GreenField(
              //   controller: _passCtrl,
              //   label: 'Password',
              //   icon: Icons.lock_outline_rounded,
              //   obscure: _obscurePass,
              //   suffix: IconButton(
              //     splashRadius: 18,
              //     icon: Icon(
              //       _obscurePass
              //           ? Icons.visibility_off_rounded
              //           : Icons.visibility_rounded,
              //       size: 19,
              //       color: AppColors.textMuted,
              //     ),
              //     onPressed: () =>
              //         setState(() => _obscurePass = !_obscurePass),
              //   ),
              // ),
              // const SizedBox(height: 16),
              //
              // _GreenField(
              //   controller: _retypeCtrl,
              //   label: 'Retype password',
              //   icon: Icons.lock_reset_rounded,
              //   obscure: _obscureRetype,
              //   suffix: IconButton(
              //     splashRadius: 18,
              //     icon: Icon(
              //       _obscureRetype
              //           ? Icons.visibility_off_rounded
              //           : Icons.visibility_rounded,
              //       size: 19,
              //       color: AppColors.textMuted,
              //     ),
              //     onPressed: () =>
              //         setState(() => _obscureRetype = !_obscureRetype),
              //   ),
              // ),
              // const SizedBox(height: 24),

              BlocBuilder<CommonVariableBloc, CommonVariableState>(
                builder: (context, state) {
                  return _GreenField(
                    controller: _passCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: state.ObscureValuePassword!,
                    suffix: IconButton(
                      splashRadius: 18,
                      icon: Icon(
                        state.ObscureValuePassword!
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        context.read<CommonVariableBloc>().add(
                          ChangeObscureValuePassword(),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              BlocBuilder<CommonVariableBloc, CommonVariableState>(
                builder: (context, state) {
                  return _GreenField(
                    controller: _retypeCtrl,
                    label: 'Retype password',
                    icon: Icons.lock_reset_rounded,
                    obscure: state.ObscureValueRetypePassword!,
                    suffix: IconButton(
                      splashRadius: 18,
                      icon: Icon(
                        state.ObscureValueRetypePassword!
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        context.read<CommonVariableBloc>().add(
                          ChangeObscureValueRetypePassword(),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              _GreenButton(
                label: 'Create account',
                onTap: () async {
                  final result = await _handleCreateAccount(context);
                  print(
                    "Handle create account methode executed.Result = ${result}",
                  );
                },
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.bgMid,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(User_JwtToken:widget.User_JwtToken,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop / wide-tablet: split panel layout.
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.state, required this.panelFlex});
  final _RegisterScreenState state;
  final int panelFlex;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: panelFlex,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bgDeep, AppColors.bgMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: state.wavePanel(height: double.infinity, showText: true),
            ),
          ),
          Expanded(
            flex: 10 - panelFlex,
            child: Container(
              color: AppColors.fieldFill,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(32),
              child: state.formCard(context, compact: false),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile / portrait / narrow-tablet: stacked layout.
class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.state, required this.isPortraitCompact});
  final _RegisterScreenState state;
  final bool isPortraitCompact;

  @override
  Widget build(BuildContext context) {
    final bannerHeight = isPortraitCompact ? 200.0 : 300.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgDeep, AppColors.bgMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: state.wavePanel(
            height: bannerHeight,
            showText: !isPortraitCompact,
          ),
        ),
        Container(
          color: AppColors.fieldFill,
          padding: EdgeInsets.symmetric(
            horizontal: isPortraitCompact ? 16 : 28,
            vertical: 24,
          ),
          alignment: Alignment.topCenter,
          child: state.formCard(context, compact: true),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------
/// Signature element: layered sine-wave animation.
/// ---------------------------------------------------------------
class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _layer(
      canvas,
      size,
      phase: progress * 2 * math.pi,
      amp: 22,
      color: AppColors.accent.withOpacity(0.16),
      baseline: 0.62,
    );
    _layer(
      canvas,
      size,
      phase: progress * 2 * math.pi + 2,
      amp: 16,
      color: AppColors.accentSoft.withOpacity(0.10),
      baseline: 0.74,
    );
    _layer(
      canvas,
      size,
      phase: progress * 2 * math.pi + 4,
      amp: 28,
      color: AppColors.bgSoft.withOpacity(0.55),
      baseline: 0.85,
    );
  }

  void _layer(
    Canvas canvas,
    Size size, {
    required double phase,
    required double amp,
    required Color color,
    required double baseline,
  }) {
    final path = Path();
    final base = size.height * baseline;
    path.moveTo(0, base);
    for (double x = 0; x <= size.width; x += 8) {
      final y = base + amp * math.sin((x / size.width * 2 * math.pi) + phase);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// ---------------------------------------------------------------
/// Reusable pieces
/// ---------------------------------------------------------------
class _GreenField extends StatefulWidget {
  const _GreenField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  @override
  State<_GreenField> createState() => _GreenFieldState();
}

class _GreenFieldState extends State<_GreenField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? AppColors.bgMid : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.bgMid.withOpacity(0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldFill,
            labelText: widget.label,
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            labelStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
            ),
            prefixIcon: Icon(widget.icon, size: 19, color: AppColors.textMuted),
            suffixIcon: widget.suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}


/// Styled dropdown matching the green field look — used for the
/// User / Provider role selector.
class _GreenDropdown extends StatefulWidget
{
  const _GreenDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final String label;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  @override
  State<_GreenDropdown> createState() => _GreenDropdownState();
}

class _GreenDropdownState extends State<_GreenDropdown>
{
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? AppColors.bgMid : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: DropdownButtonFormField<String>(
          value: widget.value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldFill,
            labelText: widget.label,
            labelStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
            ),
            prefixIcon: Icon(widget.icon, size: 19, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
          items: widget.items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}


class _GreenButton extends StatefulWidget {
  const _GreenButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  State<_GreenButton> createState() => _GreenButtonState();
}

class _GreenButtonState extends State<_GreenButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap ?? () {},
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.bgMid, AppColors.bgSoft],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.bgMid.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
