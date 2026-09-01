import 'package:flutter/material.dart';

/// Drop-in replacement for your Commonbutton — same call signature,
/// now with a red theme, hover/press animations, and sizing that's
/// clamped so it behaves on mobile, tablet, and wide desktop/web,
/// not just phone-sized "shortestSide" screens.
///
/// Usage (unchanged):
///   Commonbutton("Home", () {}, context, Colors.red)
Widget Commonbutton(
    String title,
    VoidCallback onPressFn,
    BuildContext context,
    Color buttonColor,
    ) {
  return _AnimatedCommonButton(
    title: title,
    onPressed: onPressFn,
    color: buttonColor,
  );
}

class _AnimatedCommonButton extends StatefulWidget {
  const _AnimatedCommonButton({
    required this.title,
    required this.onPressed,
    required this.color,
  });

  final String title;
  final VoidCallback onPressed;
  final Color color;

  @override
  State<_AnimatedCommonButton> createState() => _AnimatedCommonButtonState();
}

class _AnimatedCommonButtonState extends State<_AnimatedCommonButton> {
  bool _hover = false;
  bool _pressed = false;

  // Red palette derived from the passed-in color, with a couple of
  // built-in defaults if the caller passes a neutral color like grey.
  Color get _base =>
      widget.color == Colors.grey ? const Color(0xFFE53935) : widget.color;
  Color get _dark => Color.lerp(_base, Colors.black, 0.25)!;
  Color get _glow => _base.withOpacity(0.45);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;

        // Responsive sizing: scale with screen width but clamp so it
        // never becomes tiny on phones or oversized on desktop/web.
        final horizontalPad = (width * 0.035).clamp(18.0, 36.0);
        final verticalPad = (width * 0.014).clamp(12.0, 18.0);
        final fontSize = (width * 0.014).clamp(13.0, 17.0);
        final radius = (width * 0.01).clamp(10.0, 16.0);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() {
            _hover = false;
            _pressed = false;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onPressed,
            child: AnimatedScale(
              scale: _pressed ? 0.95 : (_hover ? 1.03 : 1.0),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad,
                  vertical: verticalPad,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    colors: _hover ? [_base, _dark] : [_dark, _base],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _glow,
                      blurRadius: _hover ? 20 : 10,
                      spreadRadius: _hover ? 1 : 0,
                      offset: Offset(0, _hover ? 8 : 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}