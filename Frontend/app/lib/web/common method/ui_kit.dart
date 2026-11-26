import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dark green palette (matches Header.dart / ProviderProfile.dart).
class AppColors {
  AppColors._();
  static const Color body = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color header = Color(0xFF12261C);
  static const Color border = Color(0xFF234232);
  static const Color primaryText = Color(0xFFE6F4EA);
  static const Color mutedText = Color(0xFF9AA0A6);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color danger = Color(0xFFF87171);
}

/// Responsive helpers: phone, tablet, desktop, portrait and landscape.
class AppResponsive {
  AppResponsive._();

  static double horizontalPadding(double width) {
    if (width < 600) return 16;
    if (width < 1100) return 28;
    return 40;
  }

  static double contentMaxWidth(double width) {
    if (width >= 1100) return 900;
    if (width >= 700) return 640;
    return double.infinity;
  }

  static bool isWide(double width) => width >= 800;
}

/// Returns a safe string for UI. Null or empty values show "Data not available".
String safeText(String? value) {
  if (value == null || value.trim().isEmpty) return 'Data not available';
  return value;
}

/// Frosted, translucent card with optional hover/highlight border and tap ripple.
class GlassCard extends StatelessWidget {
  final Widget child;
  final bool highlighted;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(24);

    final Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.7),
            borderRadius: radius,
            border: Border.all(
              color: highlighted
                  ? AppColors.accent.withOpacity(0.6)
                  : AppColors.border,
            ),
            boxShadow: highlighted
                ? [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ]
                : const [],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Back button with a visible border and primary-text-colored arrow.
class BorderedBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const BorderedBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryText.withOpacity(0.55),
                width: 1.4,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primaryText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Smooth fade + slide-up entrance animation (stateless, no setState).
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// Shown whenever a model or database value is null or empty.
class DataNotAvailable extends StatelessWidget {
  final String message;
  final IconData icon;

  const DataNotAvailable({
    super.key,
    this.message = 'Data not available',
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog for add, update and delete. Returns true only on confirm.
Future<bool> confirmAction({
  required String title,
  required String message,
  required String confirmText,
  bool destructive = false,
}) async {
  final bool? result = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.mutedText, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.danger : AppColors.accent,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Get.back(result: true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Themed snackbar for success and error messages.
void showAppSnack(String title, String message, {bool error = false}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.surface,
    colorText: AppColors.primaryText,
    borderColor: error ? AppColors.danger : AppColors.accent,
    borderWidth: 1,
    margin: const EdgeInsets.all(16),
    borderRadius: 14,
    maxWidth: 520,
    duration: const Duration(seconds: 3),
  );
}