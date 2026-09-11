import 'dart:convert';
import 'dart:math' as math;
import 'package:app/state%20management/bloc/common%20state/common_variable_bloc.dart';
import 'package:app/web/authentication/Error_page.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:app/web/home/Admin_Home_Screenn.dart';
import 'package:app/web/home/Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../constant/Server_Database.dart';
import '../common method/Commmon_Method.dart';
import 'Register.dart';

/// ============================================================
/// GREEN LOGIN SCREEN — fully responsive (mobile / tablet / desktop,
/// portrait / landscape) with layered wave animation + staggered
/// entrance animations.
///
/// Drop into any route:
///   MaterialApp(home: const LoginScreen())
///
/// Uses your existing logo:
///   assets/images/logo/app_logo.png
/// Make sure it's registered in pubspec.yaml:
///   flutter:
///     assets:
///       - assets/images/logo/app_logo.png
/// ============================================================

class AppColors {
  static const bgDeep = Color(0xFF07271B); // near-black forest
  static const bgMid = Color(0xFF0E4430); // pine green
  static const bgSoft = Color(0xFF14603F); // mid emerald
  static const accent = Color(0xFF3DDC97); // signature mint-emerald
  static const accentSoft = Color(0xFFB9F3D6);
  static const card = Color(0xFFF6FBF8);
  static const textDark = Color(0xFF0B2A1D);
  static const textMuted = Color(0xFF5E7A6C);
  static const fieldFill = Color(0xFFEFF6F2);
}

class LoginScreen extends StatefulWidget {
  final String User_JwtToken;
  const LoginScreen({super.key, required this.User_JwtToken});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  late final AnimationController _entrance;
  late final AnimationController _wave;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final Toast = Toastget();

  @override
  void initState()
  {
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
          MaterialPageRoute(builder: (context) => ErrorPage())
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }


  Future<int> Login_User({
    required String email,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        "Email": email,
        "Password": password,
      };
      const String url = Backend_Server_Url + "api/Authentication/login";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.User_JwtToken}'
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        print("login success");
        await handleResponse(responseData);
        Toast.Toastmsg("Login success");
        String token = responseData['token']!;
        String email = responseData['email']!;
        String User_Type = responseData['usertype']!;
        if(User_Type=="Admin")
        {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context){
            return AdminHomeScreen(User_Role: User_Type, User_JwtToken: token, User_Email: email,);
          },),
            (route) => false,
          );
        }
        else
        {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context){
            return HomeScreenUi(UserLogin: true, User_JwtToken:token );
          },
          ),
                (route) => false,
          );
        }
        return 1;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg("Invalid password.");
        print("Invalid password.");
        return 3;
      }
     else if (response.statusCode == 504)
     {
    Toast.Toastmsg("You have been blocked by community.Please contact customer service.");
    print("You have been blocked by community.");
    return 7;
    }
    else if (response.statusCode == 501) {
        Toast.Toastmsg("Email don't found.User don't exist.");
        print("Email don't found.User don't exist.");
        return 4;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Incorrect format of provided details.");
        print("Incorrect format of provided details.");
        return 5;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg("Incorrect provided details.");
        print("Incorrect provided details.");
        return 6;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg("Login fail.Try again.");
        return 2;
      }
    } catch (Obj) {
      print("Exception caight in login user method in http method.");
      print(Obj.toString());
      Toast.Toastmsg("Login fail.Try again.Server error.");
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
          final isWide = width >= 980; // desktop / tablet-landscape
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
                mainAxisAlignment: MainAxisAlignment.start,
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
                        'Welcome back\nto KaamMitra.',
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
                        'Sign in to pick up right where you left off — your bookings and services are waiting.',
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
          constraints: const BoxConstraints(maxWidth: 420),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 40,
            vertical: compact ? 32 : 44,
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
                  children: [
                    Image.asset(
                      'assets/images/logo/app_logo.png',
                      width: 40,
                      height: 40,
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
                'Sign in',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your details to access your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
              ),
              const SizedBox(height: 28),
              _GreenField(
                controller: _emailCtrl,
                label: 'Email address',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              BlocBuilder<CommonVariableBloc, CommonVariableState>(
                builder: (context, state) {
                  return _GreenField(
                    controller: _passCtrl,
                    keyboardType: TextInputType.visiblePassword,
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.bgMid,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _GreenButton(
                label: 'Login',
                onTap: () async {
                  final result = await Login_User(
                    email: _emailCtrl.text.trim().toString(),
                    password: _passCtrl.text.trim().toString(),
                  );
                  print("Login result = ${result}");
                },
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.bgMid,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: ()  {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(User_JwtToken:widget.User_JwtToken,
                          ),
                        ),
                        );
                    },
                    child: const Text(
                      'Sign up',
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
  final _LoginScreenState state;
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

/// Mobile / portrait / narrow-tablet: stacked layout with a shorter
/// wave banner up top so the form never gets pushed off-screen.
class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.state, required this.isPortraitCompact});
  final _LoginScreenState state;
  final bool isPortraitCompact;

  @override
  Widget build(BuildContext context) {
    final bannerHeight = isPortraitCompact ? 220.0 : 300.0;
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
            vertical: 28,
          ),
          alignment: Alignment.topCenter,
          child: state.formCard(context, compact: true),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------
/// Signature element: layered sine-wave animation in green tones.
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
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
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
