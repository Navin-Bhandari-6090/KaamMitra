import 'dart:math' as math;
import 'package:flutter/material.dart';

// TODO: Update this import to point to your actual login screen file.
import 'Login.dart';

/// A fully responsive, animated Error Page for Flutter apps.
/// Theme: Black background with Green accents.
///
/// Usage:
///   Navigator.pushReplacement(
///     context,
///     MaterialPageRoute(builder: (_) => const ErrorPage()),
///   );
///
/// Optional custom message:
///   ErrorPage(message: "Something went wrong. Please try again.")
class ErrorPage extends StatefulWidget {
  final String title;
  final String message;

  const ErrorPage({
    super.key,
    this.title = "Session end.Close tab.Revisit again.",
    this.message =
    "Please close tab and relogin.",
  });

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> with TickerProviderStateMixin {
  // Controls the entrance animation (fade + scale + slide) for the whole page.
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  // Controls the continuous floating animation for the illustration.
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  // Controls the pulsing glow behind the illustration / button.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Controls the subtle rotating gradient / glow ring behind the image.
  late final AnimationController _rotateController;

  bool _buttonPressed = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00E676); // Vibrant green accent
    const darkGreen = Color(0xFF00C853);
    const black = Color(0xFF000000);
    const nearBlack = Color(0xFF0A0F0A);

    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    // Responsive breakpoints
    final isMobile = shortestSide < 600;
    final isTablet = shortestSide >= 600 && shortestSide < 1024;
    final isDesktop = shortestSide >= 1024;

    final imageSize = isDesktop
        ? 260.0
        : isTablet
        ? 220.0
        : math.min(size.width * 0.55, 200.0);

    final titleFontSize = isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0);
    final messageFontSize = isDesktop ? 17.0 : (isTablet ? 16.0 : 14.5);
    final horizontalPadding = isDesktop
        ? size.width * 0.25
        : isTablet
        ? size.width * 0.15
        : 24.0;
    final maxContentWidth = isDesktop ? 480.0 : double.infinity;

    return Scaffold(
      backgroundColor: black,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      0.3 * math.cos(_rotateController.value * 2 * math.pi),
                      0.3 * math.sin(_rotateController.value * 2 * math.pi),
                    ),
                    radius: 1.4,
                    colors: const [
                      Color(0xFF072A12),
                      nearBlack,
                      black,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Subtle grid / dotted overlay for texture (optional decorative layer)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.03,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Illustration with glow + float animation
                            AnimatedBuilder(
                              animation: Listenable.merge(
                                  [_floatAnimation, _pulseAnimation]),
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Pulsing glow behind image
                                      Container(
                                        width: imageSize * _pulseAnimation.value,
                                        height: imageSize * _pulseAnimation.value,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              green.withOpacity(0.35),
                                              green.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Rotating dashed ring
                                      Transform.rotate(
                                        angle: _rotateController.value * 2 * math.pi,
                                        child: CustomPaint(
                                          size: Size(
                                            imageSize + 30,
                                            imageSize + 30,
                                          ),
                                          painter: _DashedRingPainter(color: green),
                                        ),
                                      ),
                                      // Error image
                                      ClipOval(
                                        child: Container(
                                          width: imageSize,
                                          height: imageSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: green.withOpacity(0.6),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: green.withOpacity(0.4),
                                                blurRadius: 24,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Image.asset(
                                            'assets/images/error/error01.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stack) {
                                              return Container(
                                                color: nearBlack,
                                                child: Icon(
                                                  Icons.error_outline_rounded,
                                                  color: green,
                                                  size: imageSize * 0.4,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: isDesktop ? 40 : 32),

                            // Title
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    color: green.withOpacity(0.5),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isDesktop ? 16 : 12),

                            // Message
                            Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: messageFontSize,
                                height: 1.5,
                              ),
                            ),






                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a faint dot-grid pattern used as a subtle background texture.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 1;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints a rotating dashed ring around the error illustration.
class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashCount = 28;
    const dashSweep = 0.06; // radians of each dash
    const gapSweep = (2 * math.pi / dashCount) - dashSweep;

    double angle = 0;
    for (int i = 0; i < dashCount; i++) {
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          angle,
          dashSweep,
        );
      canvas.drawPath(path, paint);
      angle += dashSweep + gapSweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}