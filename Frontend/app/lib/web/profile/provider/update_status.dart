import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust these two paths to where your files live.
import 'package:app/web/common%20widget/design/bolbs_background.dart';

import 'package:app/web/common%20widget/toast.dart';

import '../../../state management/getx/profile/provider/update_status.dart';

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
}

class UpdateStatus extends StatefulWidget {
  final String User_JwtToken;
  const UpdateStatus({super.key, required this.User_JwtToken});

  @override
  State<UpdateStatus> createState() => _UpdateStatusState();
}

class _UpdateStatusState extends State<UpdateStatus> {
  final Toast = Toastget();

  late final UpdateStatusGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    c = Get.put(UpdateStatusGetx(), tag: _tag);
    c.init(widget.User_JwtToken);
    c.verifyJwt(context);
  }

  @override
  void dispose() {
    try {
      Get.delete<UpdateStatusGetx>(tag: _tag);
    } catch (_) {}
    super.dispose();
  }

  // Action: confirm -> controller call -> UI reacts.
  Future<void> _onUpdate() async {
    if (c.isBusy.value) return;
    try {
      final bool ok = await _confirm(
        title: "Update your status?",
        message:
        "Your status will be switched now. After it is saved you will be taken back to the Home screen.",
        confirmLabel: "Update",
        icon: Icons.toggle_on_rounded,
      );
      if (!ok || !mounted) return;

      await c.runChange(context);
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
          "Update Status",
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
                  padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minH),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
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
    final double titleSize = (width * 0.07).clamp(20.0, 28.0).toDouble();
    final bool row = width >= 520;

    final steps = const [
      _StepTile(
          number: "1",
          icon: Icons.touch_app_rounded,
          title: "Confirm",
          text: "Review the cancel and confirm."),
      _StepTile(
          number: "2",
          icon: Icons.sync_alt_rounded,
          title: "Switch",
          text: "Your status is update."),
      _StepTile(
          number: "3",
          icon: Icons.home_rounded,
          title: "Home",
          text: "You return to the Home screen."),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Entrance(
          index: 0,
          child: Column(
            children: [
              const _PulseIcon(),
              const SizedBox(height: 18),
              Text("Update Your Status",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _C.text,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                "Switch your status with a single tap. You will be asked to confirm before anything changes.",
                textAlign: TextAlign.center,
                style: TextStyle(color: _C.muted, fontSize: 13.5, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Entrance(
          index: 1,
          child: row
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                if (i != 0) const SizedBox(width: 12),
                Expanded(child: steps[i]),
              ],
            ],
          )
              : Column(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                steps[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Entrance(
          index: 2,
          child: Obx(() => _GradientButton(
            label: "Update Status",
            icon: Icons.toggle_on_rounded,
            loading: c.isBusy.value,
            onTap: c.isBusy.value ? null : _onUpdate,
          )),
        ),
        // Failure / blocked message with a retry hint.
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
            Icon(icon, color: _C.mint),
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
              backgroundColor: _C.accent,
              foregroundColor: Colors.black,
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

// Hero icon with a soft pulsing glow ring (animation only, no setState).
class _PulseIcon extends StatefulWidget {
  const _PulseIcon();

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, v, child) =>
          Transform.scale(scale: 0.7 + (0.3 * v), child: child),
      child: SizedBox(
        width: 120,
        height: 120,
        child: AnimatedBuilder(
          animation: _ac,
          builder: (context, _) {
            final double t = _ac.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 76 + 44 * t,
                  height: 76 + 44 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _C.mint.withOpacity((1 - t) * .45), width: 1.6),
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_C.accent, _C.mint],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: _C.accent.withOpacity(.42),
                          blurRadius: 26,
                          spreadRadius: 1),
                    ],
                  ),
                  child: const Icon(Icons.toggle_on_rounded,
                      color: _C.bg, size: 44),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;
  const _StepTile({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.mint.withOpacity(.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _C.mint.withOpacity(.35)),
            ),
            child: Icon(icon, color: _C.mint, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$number. $title",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        color: _C.muted, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null && !loading;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: loading ? null : onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [
                    _C.accent.withOpacity(disabled ? .45 : 1),
                    _C.mint.withOpacity(disabled ? .45 : 1),
                  ]),
                  boxShadow: disabled
                      ? []
                      : [
                    BoxShadow(
                        color: _C.accent.withOpacity(.34),
                        blurRadius: 18,
                        offset: const Offset(0, 8)),
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
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22, color: _C.bg),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _C.bg,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
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
    final Color color = code == 2 ? _C.warn : _C.danger;
    final IconData icon =
    code == 2 ? Icons.block_rounded : Icons.error_outline_rounded;
    final String title = code == 2 ? "Account blocked" : "Status not updated";

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