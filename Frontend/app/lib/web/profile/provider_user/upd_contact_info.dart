import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:app/web/common method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../constant/variable.dart';
import '../../../state management/getx/profile/provider_user/upd_contact_info_getx.dart';

class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color bar = Color(0xFF12261C);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
}

const TextStyle _fieldText = TextStyle(color: _C.text, fontSize: 15);
const TextStyle _mutedSmall = TextStyle(color: _C.muted, fontSize: 12.5);

final TextInputFormatter _phoneFormatter =
FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'));

BoxDecoration _glassCard({double radius = 22}) => BoxDecoration(
  color: _C.surface.withOpacity(.86),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _C.border),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(.28),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ],
);

InputDecoration _input(String label, IconData icon, {String? helper}) {
  OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: col, width: w),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _C.muted, fontSize: 14),
    floatingLabelStyle: const TextStyle(color: _C.accent, fontSize: 13),
    helperText: helper,
    helperStyle: const TextStyle(color: _C.muted, fontSize: 12),
    helperMaxLines: 2,
    prefixIcon: Icon(icon, color: _C.mint, size: 20),
    filled: true,
    fillColor: _C.bar,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: b(_C.border),
    focusedBorder: b(_C.accent, 1.5),
    border: b(_C.border),
  );
}

ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
  foregroundColor: _C.text,
  minimumSize: const Size(0, 48),
  side: const BorderSide(color: _C.border, width: 1.2),
  textStyle: const TextStyle(fontWeight: FontWeight.w600),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
  backgroundColor: _C.accent,
  disabledBackgroundColor: _C.accent.withOpacity(.25),
  foregroundColor: Colors.black,
  disabledForegroundColor: Colors.black45,
  elevation: 0,
  minimumSize: const Size(0, 52),
  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

class UpdContactInfo extends StatefulWidget {
  final String Current_User_Jwt_Token;
  const UpdContactInfo({super.key, required this.Current_User_Jwt_Token});

  @override
  State<UpdContactInfo> createState() => _UpdContactInfoState();
}

class _UpdContactInfoState extends State<UpdContactInfo> {
  final String _tag = UniqueKey().toString();
  late final UpdContactInfoGetx c;

  @override
  void initState() {
    super.initState();
    try {
      Provider_User_Jwt_Verify(
          Jwt_Token: widget.Current_User_Jwt_Token, context: context);
    } catch (_) {}
    c = Get.put(UpdContactInfoGetx(), tag: _tag)
      ..init(widget.Current_User_Jwt_Token);
  }

  @override
  void dispose() {
    Get.delete<UpdContactInfoGetx>(tag: _tag);
    super.dispose();
  }

  Future<void> _onUpdatePressed() async {
    try {
      if (!c.validate()) return;
      final bool ok = await _confirmUpdate(
        c.phoneCont.text.trim(),
        c.whatsappCont.text.trim(),
      );
      if (ok) await c.submit(context);
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    }
  }

  Future<bool> _confirmUpdate(String phone, String whatsapp) async {
    try {
      final List<Widget> lines = [
        if (phone.isNotEmpty) _dialogLine("Phone", phone),
        if (whatsapp.isNotEmpty) _dialogLine("WhatsApp", whatsapp),
      ];

      final bool? r = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _C.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.contact_phone_rounded, color: _C.accent),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  "Update contact info?",
                  style: TextStyle(
                      color: _C.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "These numbers will be saved to your account:",
                style: TextStyle(color: _C.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              ...lines,
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text("Cancel", style: TextStyle(color: _C.muted)),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.accent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Update",
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return r == true;
    } catch (_) {
      return false;
    }
  }

  Widget _dialogLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label,
                style: const TextStyle(color: _C.muted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _C.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.text, width: 1.2),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _C.text, size: 18),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Update Contact Info",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
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
                final bool wide = w >= 900;
                final double hPad = w >= 700 ? 28 : 16;

                final Widget details =
                _Entrance(index: 0, child: _DetailsCard(c: c));
                final Widget preview = _Entrance(
                  index: 1,
                  child: _PreviewCard(c: c, onUpdate: _onUpdatePressed),
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          const SizedBox(height: 22),
                          wide
                              ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: details),
                              const SizedBox(width: 20),
                              Expanded(flex: 4, child: preview),
                            ],
                          )
                              : Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              details,
                              const SizedBox(height: 18),
                              preview,
                            ],
                          ),
                        ],
                      ),
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
}

class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 22), child: ch),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.accent.withOpacity(.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.accent.withOpacity(.35)),
          ),
          child: const Icon(Icons.contact_phone_rounded,
              color: _C.accent, size: 26),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update contact info",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _C.text, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                "Keep your phone and WhatsApp numbers up to date.",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _C.muted, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.accent.withOpacity(.4)),
                ),
                child: Icon(icon, color: _C.accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _mutedSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final UpdContactInfoGetx c;
  const _DetailsCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.contact_phone_rounded,
      title: "Numbers",
      subtitle: "Fill in one or both. Empty fields are not changed.",
      child: Column(
        children: [
          TextField(
            controller: c.phoneCont,
            keyboardType: TextInputType.phone,
            inputFormatters: [_phoneFormatter],
            style: _fieldText,
            cursorColor: _C.accent,
            onChanged: c.onPhoneChanged,
            decoration: _input(
              "Phone number",
              Icons.phone_outlined,
              helper: "Start with + and country code, e.g. +9779800000000",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: c.whatsappCont,
            keyboardType: TextInputType.phone,
            inputFormatters: [_phoneFormatter],
            style: _fieldText,
            cursorColor: _C.accent,
            onChanged: c.onWhatsappChanged,
            decoration: _input(
              "WhatsApp number",
              Icons.chat_outlined,
              helper: "Start with + and country code, e.g. +9779800000000",
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final UpdContactInfoGetx c;
  final Future<void> Function() onUpdate;
  const _PreviewCard({required this.c, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.visibility_outlined,
      title: "Review & update",
      subtitle: "Check the numbers, then update.",
      child: Column(
        children: [
          Obx(() {
            final bool ok = c.phone.value.isNotEmpty;
            return _SummaryRow(
              icon: Icons.phone_outlined,
              label: "Phone",
              value: ok ? c.phone.value : "Not entered",
              ok: ok,
            );
          }),
          const SizedBox(height: 10),
          Obx(() {
            final bool ok = c.whatsapp.value.isNotEmpty;
            return _SummaryRow(
              icon: Icons.chat_outlined,
              label: "WhatsApp",
              value: ok ? c.whatsapp.value : "Not entered",
              ok: ok,
            );
          }),
          const SizedBox(height: 18),
          Obx(() {
            final bool busy = c.isUpdating.value;
            final bool ready = c.phone.value.isNotEmpty ||
                c.whatsapp.value.isNotEmpty;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (busy || !ready) ? null : onUpdate,
                style: _primaryStyle(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Row(
                    key: ValueKey(busy),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      busy
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                          : const Icon(Icons.cloud_upload_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(busy ? "Updating..." : "Update contact info"),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: c.clearForm,
              icon: const Icon(Icons.restart_alt_rounded, size: 19),
              label: const Text("Clear"),
              style: _outlinedStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ok;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.bar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ok ? _C.accent.withOpacity(.35) : _C.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ok ? _C.accent : _C.muted),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: _C.muted, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ok ? _C.text : _C.muted,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              Colors.white.withOpacity(.01),
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
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.hasBoundedWidth ? box.maxWidth : 800;
          final double h = box.hasBoundedHeight ? box.maxHeight : 800;
          final double base = math.max(w, h);
          final double small = math.min(w, h);

          return Stack(
            children: [
              _blob(
                  left: -w * .18,
                  top: -h * .12,
                  size: base * .70,
                  color: _C.accent,
                  opacity: .16),
              _blob(
                  right: -w * .22,
                  top: h * .28,
                  size: base * .60,
                  color: _C.mint,
                  opacity: .12),
              _blob(
                  left: w * .08,
                  bottom: -h * .22,
                  size: base * .75,
                  color: _C.accent,
                  opacity: .12),
              _bubble(
                  right: w * .10,
                  top: h * .06,
                  size: math.min(math.max(small * .16, 40), 150)),
              _bubble(
                  left: w * .06,
                  top: h * .42,
                  size: math.min(math.max(small * .10, 28), 100)),
              _bubble(
                  right: w * .18,
                  bottom: h * .10,
                  size: math.min(math.max(small * .20, 50), 190)),
            ],
          );
        },
      ),
    );
  }
}