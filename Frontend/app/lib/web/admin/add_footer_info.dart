import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constant/variable.dart';
import '../../state management/getx/admin/add_footer_info.dart';
import '../common method/Commmon_Method.dart';

// =============================================================================
// PALETTE — Dark Forest / Emerald Glow
// =============================================================================
class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color bar = Color(0xFF12261C);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color danger = Color(0xFFF87171);
}

// =============================================================================
// SCREEN (StatefulWidget only for controller lifecycle — zero setState)
// =============================================================================
class AddFooterInfo extends StatefulWidget {
  final String User_JwtToken;
  const AddFooterInfo({
    super.key,
    required this.User_JwtToken,
  });

  @override
  State<AddFooterInfo> createState() => _AddFooterInfoState();
}

class _AddFooterInfoState extends State<AddFooterInfo> {
  late final AddFooterInfoGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    try {
      Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    } catch (obj) {
      print(obj.toString());
    }
    c = Get.put(AddFooterInfoGetx(), tag: _tag);
  }

  @override
  void dispose() {
    try {
      Get.delete<AddFooterInfoGetx>(tag: _tag);
    } catch (obj) {
      print(obj.toString());
    }
    super.dispose();
  }

  // Validate -> confirm -> save. Every step is guarded.
  Future<void> _onSave() async {
    try {
      if (c.isSaving.value) return;
      FocusManager.instance.primaryFocus?.unfocus();

      final String? error = c.validate();
      if (error != null) {
        Toast.Toastmsg(error);
        return;
      }

      final bool ok = await _confirm(
        title: "Save footer info?",
        message:
        "The footer contact number, address, email and social media information will be saved.",
        confirmLabel: "Save",
        icon: Icons.save_rounded,
      );
      if (!ok) return;

      await c.submit(jwtToken: widget.User_JwtToken);
    } catch (obj) {
      print(obj.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leadingWidth: 64,
        leading: Center(
          child: Tooltip(
            message: "Back",
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.text, width: 1.4),
                ),
                child: const Icon(Icons.arrow_back, color: _C.text, size: 20),
              ),
            ),
          ),
        ),
        title: const Text(
          "Add Footer Info",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
              child: IgnorePointer(child: _AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth;
                final double hPad =
                w > 1360 ? (w - 1280) / 2 : (w >= 700 ? 24.0 : 14.0);
                final bool wide = w >= 900;

                final Widget form = _Entrance(
                    index: 0, child: _FormCard(c: c, onSave: _onSave));
                final Widget preview =
                _Entrance(index: 2, child: _PreviewCard(c: c));

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 40),
                  child: Column(
                    children: [
                      const _Header(),
                      const SizedBox(height: 22),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: form),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: preview),
                          ],
                        )
                      else ...[
                        form,
                        const SizedBox(height: 18),
                        preview,
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================
BoxDecoration _glassCard({double radius = 22}) => BoxDecoration(
  color: _C.surface.withOpacity(.88),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _C.border),
  boxShadow: [
    BoxShadow(
        color: Colors.black.withOpacity(.28),
        blurRadius: 22,
        offset: const Offset(0, 9)),
  ],
);

// =============================================================================
// CONFIRM DIALOG (Cancel / Confirm before saving)
// =============================================================================
Future<bool> _confirm({
  required String title,
  required String message,
  required String confirmLabel,
  required IconData icon,
  bool danger = false,
}) async {
  try {
    final Color tone = danger ? _C.danger : _C.mint;
    final bool? r = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: _C.surface,
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _C.border),
        ),
        title: Row(
          children: [
            Icon(icon, color: tone),
            const SizedBox(width: 10),
            Flexible(
              child: Text(title,
                  style: const TextStyle(
                      color: _C.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content:
        Text(message, style: const TextStyle(color: _C.muted, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel", style: TextStyle(color: _C.muted)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? _C.danger : _C.accent,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return r == true;
  } catch (obj) {
    print(obj.toString());
    return false;
  }
}

class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 120).clamp(0, 450)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch),
      ),
      child: child,
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, v, child) =>
              Transform.scale(scale: 0.7 + (0.3 * v), child: child),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_C.accent, _C.mint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: _C.accent.withOpacity(.4),
                    blurRadius: 20,
                    spreadRadius: 1),
              ],
            ),
            child: const Icon(Icons.web_asset_rounded, color: _C.bg, size: 30),
          ),
        ),
        const SizedBox(height: 14),
        const Text("Website Footer",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          "Set the contact details shown at the bottom of your website.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}

// =============================================================================
// FORM CARD
// =============================================================================
class _FormCard extends StatelessWidget {
  final AddFooterInfoGetx c;
  final VoidCallback onSave;
  const _FormCard({required this.c, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _glassCard(),
      child: LayoutBuilder(builder: (context, b) {
        final int cols = b.maxWidth >= 520 ? 2 : 1;
        final double w = math.max(0.0, (b.maxWidth - (cols - 1) * 14) / cols);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(
                icon: Icons.edit_note_rounded, text: "Footer details"),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: w,
                  child: _Field(
                    controller: c.ContactNumberController,
                    label: "Contact Number",
                    hint: "+9779800000000",
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _Field(
                    controller: c.EmailController,
                    label: "Email Address",
                    hint: "support@example.com",
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Field(
              controller: c.AddressController,
              label: "Address",
              hint: "Street, city, country",
              icon: Icons.location_on_rounded,
              keyboardType: TextInputType.streetAddress,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: c.SocialMediaInfoController,
              label: "Social Media Information",
              hint: "facebook.com/yourpage  instagram.com/yourpage",
              icon: Icons.share_rounded,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Obx(() => _SaveButton(
              loading: c.isSaving.value,
              onTap: c.isSaving.value ? null : onSave,
            )),
          ],
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _C.mint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.text, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: 1,
      maxLines: maxLines,
      style: const TextStyle(color: _C.text, fontSize: 14.5),
      cursorColor: _C.mint,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
        floatingLabelStyle:
        const TextStyle(color: _C.mint, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: _C.muted.withOpacity(.6), fontSize: 13),
        filled: true,
        fillColor: _C.bg.withOpacity(.6),
        prefixIcon: Icon(icon, color: _C.mint, size: 20),
        // Clear button rebuilds via the text controller itself (no setState).
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, v, _) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
            tooltip: "Clear",
            icon: const Icon(Icons.close_rounded,
                color: _C.muted, size: 18),
            onPressed: () => controller.clear(),
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.mint, width: 1.5),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _SaveButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [
                _C.accent.withOpacity(loading ? .6 : 1),
                _C.mint.withOpacity(loading ? .6 : 1)
              ]),
              boxShadow: [
                BoxShadow(
                    color: _C.accent.withOpacity(.30),
                    blurRadius: 16,
                    offset: const Offset(0, 7)),
              ],
            ),
            child: loading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(_C.bg)),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, size: 20, color: _C.bg),
                SizedBox(width: 8),
                Flexible(
                  child: Text("Add footer info",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: _C.bg,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// LIVE PREVIEW — shows what is being typed, like the real footer
// =============================================================================
class _PreviewCard extends StatelessWidget {
  final AddFooterInfoGetx c;
  const _PreviewCard({required this.c});

  Widget _row(IconData icon, String label, String value) {
    final bool empty = value.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.bg.withOpacity(.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _C.mint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _C.muted, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(empty ? '—' : value.trim(),
                    style: TextStyle(
                        color: empty ? _C.muted : _C.text,
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
              icon: Icons.visibility_rounded, text: "Live footer preview"),
          const SizedBox(height: 4),
          const Text("Updates as you type.",
              style: TextStyle(color: _C.muted, fontSize: 12.5)),
          const SizedBox(height: 14),
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _row(Icons.phone_rounded, "Contact number",
                  c.contactText.value),
              const SizedBox(height: 10),
              _row(Icons.email_rounded, "Email", c.emailText.value),
              const SizedBox(height: 10),
              _row(Icons.location_on_rounded, "Address",
                  c.addressText.value),
              const SizedBox(height: 10),
              _row(Icons.share_rounded, "Social media",
                  c.socialText.value),
            ],
          )),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.mint.withOpacity(.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.mint.withOpacity(.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: _C.mint),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Contact number must start with + and have 7 to 15 digits.",
                    style:
                    TextStyle(color: _C.muted, fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AMBIENT BACKGROUND — heavily blurred emerald/mint blobs + glass bubbles.
// Wrapped in IgnorePointer by the caller, so it can never block taps.
// =============================================================================
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  Widget _blob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter:
        ImageFilter.blur(sigmaX: 45, sigmaY: 45, tileMode: TileMode.decal),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(opacity), color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(.07),
              Colors.white.withOpacity(.01)
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(.07)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(builder: (context, box) {
        final double w = box.hasBoundedWidth ? box.maxWidth : 800;
        final double h = box.hasBoundedHeight ? box.maxHeight : 800;
        final double base = math.max(w, h);
        final double small = math.min(w, h);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            _blob(left: -w * .18, top: -h * .12, size: base * .70, color: _C.accent, opacity: .16),
            _blob(right: -w * .22, top: h * .28, size: base * .60, color: _C.mint, opacity: .12),
            _blob(left: w * .08, bottom: -h * .22, size: base * .75, color: _C.accent, opacity: .12),
            _bubble(right: w * .10, top: h * .06, size: (small * .16).clamp(40.0, 150.0).toDouble()),
            _bubble(left: w * .06, top: h * .42, size: (small * .10).clamp(28.0, 100.0).toDouble()),
            _bubble(right: w * .18, bottom: h * .10, size: (small * .20).clamp(50.0, 190.0).toDouble()),
            _bubble(left: w * .40, bottom: h * .04, size: (small * .07).clamp(20.0, 70.0).toDouble()),
          ],
        );
      }),
    );
  }
}