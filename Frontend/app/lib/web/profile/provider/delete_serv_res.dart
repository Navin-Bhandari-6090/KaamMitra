import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';


import 'package:app/web/common%20widget/toast.dart';

import '../../../state management/getx/profile/provider/del_serv_res_getx.dart';
import '../../common widget/design/bolbs_background.dart';

// Palette: Dark Forest / Emerald Glow
class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color bar = Color(0xFF12261C);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color warn = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDeep = Color(0xFFB91C1C);
}

class DeleteServRes extends StatefulWidget {
  final String Current_User_JwtToken;
  const DeleteServRes({super.key, required this.Current_User_JwtToken});

  @override
  State<DeleteServRes> createState() => _DeleteServResState();
}

class _DeleteServResState extends State<DeleteServRes> {
  final Toast = Toastget();

  late final DelServResGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    c = Get.put(DelServResGetx(), tag: _tag);
    c.init(widget.Current_User_JwtToken);
    c.verifyJwt(context);
  }

  @override
  void dispose() {
    try {
      Get.delete<DelServResGetx>(tag: _tag);
    } catch (_) {}
    super.dispose();
  }

  // Empty -> 0 (same as the original), not a number -> null.
  int? _parseId(String t) {
    final String s = t.trim();
    if (s.isEmpty) return 0;
    return int.tryParse(s);
  }

  // Action: validate -> confirm -> controller call -> UI reacts.
  Future<void> _onDelete() async {
    if (c.isBusy.value) return;
    try {
      final int? sid = _parseId(c.ServiceIdController.text);
      final int? rid = _parseId(c.ResourceIdController.text);

      if (sid == null || rid == null) {
        Toast.Toastmsg("Enter numbers only.");
        return;
      }

      final String? error = c.validateIds(sid, rid);
      if (error != null) {
        Toast.Toastmsg(error);
        return;
      }

      final bool isService = sid > 0;
      final bool ok = await _confirm(
        title: isService ? "Delete service?" : "Delete resource?",
        message: isService
            ? "Service #$sid and ALL of its resources and files will be permanently deleted. This cannot be undone."
            : "Resource #$rid and its files will be permanently deleted. This cannot be undone.",
        confirmLabel: "Delete",
        icon: Icons.delete_forever_rounded,
      );
      if (!ok || !mounted) return;

      await c.runDelete(context, serviceId: sid, resourceId: rid);
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
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
                child: const Icon(Icons.arrow_back_rounded,
                    color: _C.text, size: 20),
              ),
            ),
          ),
        ),
        title: const Text(
          "Delete Service & Resources",
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
          // Ambient glow blobs + glass bubbles, never blocks taps.
          const Positioned.fill(child: IgnorePointer(child: AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth;
                final double h = box.maxHeight;
                final double hPad = (w * 0.04).clamp(10.0, 32.0).toDouble();
                final double vPad = (h * 0.03).clamp(10.0, 28.0).toDouble();
                final double minH = math.max(0.0, h - vPad * 2);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minH),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: _buildContent(math.max(0.0, w - hPad * 2)),
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

  Widget _buildContent(double width) {
    final bool twoCols = width >= 700;

    final Widget serviceCard = _Entrance(
      index: 1,
      child: Obx(() => _IdCard(
        icon: Icons.home_repair_service_rounded,
        title: "Delete a service",
        description:
        "Removes the registered service together with all of its resources and files.",
        label: "Enter the service ID",
        hint: "e.g. 12",
        controller: c.ServiceIdController,
        active: c.serviceText.value.trim().isNotEmpty,
        onChanged: (v) => c.serviceText.value = v,
        onClear: () {
          c.ServiceIdController.clear();
          c.serviceText.value = '';
        },
        danger: true,
      )),
    );

    final Widget resourceCard = _Entrance(
      index: 2,
      child: Obx(() => _IdCard(
        icon: Icons.perm_media_rounded,
        title: "Delete a resource",
        description:
        "Removes only one resource (photo, video or file). The service stays.",
        label: "Enter the service resource ID",
        hint: "e.g. 45",
        controller: c.ResourceIdController,
        active: c.resourceText.value.trim().isNotEmpty,
        onChanged: (v) => c.resourceText.value = v,
        onClear: () {
          c.ResourceIdController.clear();
          c.resourceText.value = '';
        },
        danger: false,
      )),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Entrance(index: 0, child: _buildHeader(width)),
        const SizedBox(height: 18),
        _Entrance(
          index: 1,
          child: const _Banner(
            icon: Icons.info_outline_rounded,
            color: _C.mint,
            text:
            "Only pass one ID at a time. You cannot delete both at once.",
          ),
        ),
        const SizedBox(height: 16),
        if (twoCols)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: serviceCard),
              const SizedBox(width: 16),
              Expanded(child: resourceCard),
            ],
          )
        else ...[
          serviceCard,
          const SizedBox(height: 14),
          resourceCard,
        ],
        // Warns live when both ids are typed.
        Obx(() => AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: c.mode == 'both'
              ? const Padding(
            padding: EdgeInsets.only(top: 14),
            child: _Banner(
              icon: Icons.warning_amber_rounded,
              color: _C.warn,
              text:
              "Both IDs are filled. Clear one of them to continue.",
            ),
          )
              : const SizedBox(width: double.infinity),
        )),
        const SizedBox(height: 18),
        _Entrance(
          index: 3,
          child: Obx(() {
            final String m = c.mode;
            final String label = m == 'service'
                ? "Delete service & resources"
                : m == 'resource'
                ? "Delete resource"
                : m == 'both'
                ? "Only one ID allowed"
                : "Enter one ID to delete";
            final IconData icon = m == 'service'
                ? Icons.delete_forever_rounded
                : m == 'resource'
                ? Icons.delete_outline_rounded
                : Icons.block_rounded;
            return _DangerButton(
              label: label,
              icon: icon,
              loading: c.isBusy.value,
              ready: m == 'service' || m == 'resource',
              onTap: c.isBusy.value ? null : _onDelete,
            );
          }),
        ),
        // Last outcome (success / partial / failed).
        Obx(() => AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: c.resultCode.value == 0
              ? const SizedBox(width: double.infinity)
              : Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _ResultCard(
              code: c.resultCode.value,
              message: c.resultMessage.value,
              onClose: c.dismissResult,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildHeader(double width) {
    final double titleSize = (width * 0.06).clamp(18.0, 26.0).toDouble();
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, v, child) =>
              Transform.scale(scale: 0.7 + (0.3 * v), child: child),
          child: Container(
            width: 64,
            height: 64,
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
                    blurRadius: 22,
                    spreadRadius: 1),
              ],
            ),
            child:
            const Icon(Icons.delete_sweep_rounded, color: _C.bg, size: 32),
          ),
        ),
        const SizedBox(height: 14),
        Text("Clean Up Your Services",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text,
                fontSize: titleSize,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          "Remove a whole service or just one resource. Every delete asks you to confirm first.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(icon: Icons.filter_1_rounded, text: "One ID at a time"),
            _Chip(
                icon: Icons.warning_amber_rounded,
                text: "Permanent action",
                color: _C.warn),
          ],
        ),
      ],
    );
  }
}

// Confirm dialog
Future<bool> _confirm({
  required String title,
  required String message,
  required String confirmLabel,
  required IconData icon,
}) async {
  try {
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
            Icon(icon, color: _C.danger),
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
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return r == true;
  } catch (_) {
    return false;
  }
}

// Shared UI pieces
class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + math.min(index * 90, 450)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Chip({required this.icon, required this.text, this.color = _C.mint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Banner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: _C.text, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool active;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool danger;
  const _IdCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.label,
    required this.hint,
    required this.controller,
    required this.active,
    required this.onChanged,
    required this.onClear,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: w),
    );
    final Color tone = danger ? _C.danger : _C.mint;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: active ? tone.withOpacity(.7) : _C.border,
            width: active ? 1.4 : 1),
        boxShadow: [
          BoxShadow(
            color: active
                ? tone.withOpacity(.18)
                : Colors.black.withOpacity(.28),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tone.withOpacity(.35)),
                ),
                child: Icon(icon, color: tone, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description,
              style:
              const TextStyle(color: _C.muted, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            style: const TextStyle(color: _C.text, fontSize: 15),
            cursorColor: _C.mint,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              hintStyle: const TextStyle(color: _C.muted, fontSize: 13),
              labelStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
              floatingLabelStyle:
              TextStyle(color: tone, fontWeight: FontWeight.w600),
              prefixIcon: Icon(Icons.numbers_rounded, color: tone, size: 20),
              suffixIcon: active
                  ? Tooltip(
                message: "Clear",
                child: IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded,
                      color: _C.muted, size: 18),
                ),
              )
                  : null,
              filled: true,
              fillColor: _C.bg.withOpacity(.6),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              enabledBorder: border(_C.border, 1),
              focusedBorder: border(tone, 1.5),
              border: border(_C.border, 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final bool ready;
  final VoidCallback? onTap;
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.ready,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double o = ready || loading ? 1 : .55;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: loading ? null : onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [
                    _C.danger.withOpacity(o),
                    _C.dangerDeep.withOpacity(o),
                  ]),
                  boxShadow: ready
                      ? [
                    BoxShadow(
                        color: _C.danger.withOpacity(.34),
                        blurRadius: 16,
                        offset: const Offset(0, 7)),
                  ]
                      : [],
                ),
                child: loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white)),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 19, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int code;
  final String message;
  final VoidCallback onClose;
  const _ResultCard(
      {required this.code, required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final Color color = code == 1
        ? _C.mint
        : code == 2
        ? _C.warn
        : _C.danger;
    final IconData icon = code == 1
        ? Icons.check_circle_rounded
        : code == 2
        ? Icons.warning_amber_rounded
        : Icons.error_outline_rounded;
    final String title = code == 1
        ? "Deleted"
        : code == 2
        ? "Deleted with a warning"
        : "Not deleted";

    return TweenAnimationBuilder<double>(
      key: ValueKey("$code$message"),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: ch),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: _C.bar,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.6), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(.14), blurRadius: 14, spreadRadius: 1),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(message,
                      style: const TextStyle(
                          color: _C.text, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            Tooltip(
              message: "Dismiss",
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: _C.muted, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}