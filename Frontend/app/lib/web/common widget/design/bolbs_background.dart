import 'dart:math' as math;

import 'package:flutter/material.dart';

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _AmbientPainter(),
      ),
    );
  }
}

class _Blob {
  final Offset center;
  final double radius;
  final Color color;
  final double opacity;
  const _Blob(this.center, this.radius, this.color, this.opacity);
}

class _Bubble {
  final Offset center;
  final double radius;
  const _Bubble(this.center, this.radius);
}

class _AmbientPainter extends CustomPainter {
  static const Color _accent = Color(0xFF22C55E);
  static const Color _mint = Color(0xFF34D399);

  static const List<_Blob> _blobs = [
    _Blob(Offset(-0.05, 0.05), 0.42, _accent, 0.16),
    _Blob(Offset(1.05, 0.28), 0.38, _mint, 0.12),
    _Blob(Offset(0.02, 0.50), 0.34, _accent, 0.10),
    _Blob(Offset(0.98, 0.72), 0.40, _accent, 0.14),
    _Blob(Offset(0.30, 1.04), 0.40, _mint, 0.13),
    _Blob(Offset(0.60, 0.42), 0.26, _mint, 0.07),
  ];

  static const List<_Bubble> _bubbles = [
    _Bubble(Offset(0.88, 0.12), 0.08),
    _Bubble(Offset(0.10, 0.36), 0.05),
    _Bubble(Offset(0.80, 0.60), 0.11),
    _Bubble(Offset(0.18, 0.86), 0.07),
    _Bubble(Offset(0.55, 0.97), 0.04),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double avg = (size.width + size.height) / 2;
    final double shortest = math.min(size.width, size.height);

    for (final _Blob b in _blobs) {
      final Offset center =
      Offset(b.center.dx * size.width, b.center.dy * size.height);
      final double radius = b.radius * avg;
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withOpacity(b.opacity),
            b.color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(center, radius, paint);
    }

    for (final _Bubble b in _bubbles) {
      final Offset center =
      Offset(b.center.dx * size.width, b.center.dy * size.height);
      final double radius = b.radius * shortest;
      final Rect rect = Rect.fromCircle(center: center, radius: radius);

      final Paint fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(.07),
            Colors.white.withOpacity(.01),
          ],
        ).createShader(rect);
      canvas.drawCircle(center, radius, fill);

      final Paint stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(.07);
      canvas.drawCircle(center, radius, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}