import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../state management/getx/footer/footer_getx.dart';



const Color headerGreen = Color(0xFF12261C);
const Color borderGreen = Color(0xFF234232);
const Color mutedText = Color(0xFF8A9A90);

const Color _primaryText = Color(0xFFE6F4EA);
const Color _emerald = Color(0xFF22C55E);
const Color _mint = Color(0xFF34D399);

// =============================================================================
// Footer – same constructor as before
// =============================================================================
class Footer extends StatelessWidget {
  final String User_JwtToken;
  const Footer({super.key, required this.User_JwtToken});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FooterController>(
      init: FooterController(),
      initState: (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final FooterController? c = state.controller;
            if (c != null && context.mounted) {
              c.loadFooter(jwtToken: User_JwtToken, context: context);
            }
          } catch (_) {}
        });
      },
      builder: (_) => const _FooterBody(),
    );
  }
}

class _FooterBody extends StatelessWidget {
  const _FooterBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          final double w = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;

          // Tiny widths: only the copyright, scaled down.
          if (w < 180) {
            return Container(
              width: double.infinity,
              color: headerGreen,
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '© ${DateTime.now().year}',
                  style: const TextStyle(color: mutedText, fontSize: 11),
                ),
              ),
            );
          }

          final double hPad = w < 400 ? 12 : (w < 900 ? 20 : 32);
          final double inner = math.max(w - hPad * 2, 0);

          final Widget content = Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoRow(maxWidth: inner),
                const SizedBox(height: 8),
                Text(
                  '© ${DateTime.now().year} KaamMitra  •  Built for a better experience',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: mutedText, fontSize: 11),
                ),
              ],
            ),
          );

          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: headerGreen,
              border: Border(top: BorderSide(color: borderGreen)),
            ),
            child: constraints.hasBoundedHeight
                ? SingleChildScrollView(child: content)
                : content,
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

// =============================================================================
// Contact + social row (wraps onto new lines on small screens)
// =============================================================================
class _InfoRow extends StatelessWidget {
  final double maxWidth;
  const _InfoRow({required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final FooterController c = Get.put(FooterController());

    return Obx(() {
      try {
        final String phone = c.contactNumber.value;
        final String mail = c.email.value;
        final String addr = c.address.value;
        final String social = c.socialMediaInfo.value;

        if (c.isLoading.value && !c.hasAnyData) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _emerald),
          );
        }

        if (!c.hasAnyData) {
          return const Text(
            'No data available',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedText, fontSize: 12),
          );
        }

        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 22,
          runSpacing: 8,
          children: [
            if (phone.isNotEmpty)
              _Item(
                itemKey: 'phone',
                icon: Icons.call_rounded,
                text: phone,
                maxWidth: maxWidth,
                onTap: () => c.copyText(label: 'Phone number', value: phone),
              ),
            if (mail.isNotEmpty)
              _Item(
                itemKey: 'email',
                icon: Icons.mail_rounded,
                text: mail,
                maxWidth: maxWidth,
                onTap: () => c.copyText(label: 'Email', value: mail),
              ),
            if (addr.isNotEmpty)
              _Item(
                itemKey: 'address',
                icon: Icons.location_on_rounded,
                text: addr,
                maxWidth: maxWidth,
                onTap: () => c.copyText(label: 'Address', value: addr),
              ),
            if (social.isNotEmpty)
              _Item(
                itemKey: 'social',
                icon: Icons.share_rounded,
                text: social,
                maxWidth: math.min(maxWidth, 640),
                maxLines: null,
                onTap: () => c.copyText(label: 'Social media info', value: social),
              ),
          ],
        );
      } catch (_) {
        return const Text(
          'No data available',
          style: TextStyle(color: mutedText, fontSize: 12),
        );
      }
    });
  }
}

class _Item extends StatelessWidget {
  final String itemKey;
  final IconData icon;
  final String text;
  final double maxWidth;
  final VoidCallback onTap;
  final int? maxLines;

  const _Item({
    required this.itemKey,
    required this.icon,
    required this.text,
    required this.maxWidth,
    required this.onTap,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final FooterController c = Get.find<FooterController>();

    return Obx(() {
      final bool hovered = c.hoveredKey.value == itemKey;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => c.setHover(itemKey),
        onExit: (_) => c.clearHover(itemKey),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: math.max(maxWidth, 0)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 14, color: hovered ? _mint : _emerald),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      color: hovered ? _mint : _primaryText,
                      fontSize: 12.5,
                    ),
                    child: Text(
                      text,
                      maxLines: maxLines,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}