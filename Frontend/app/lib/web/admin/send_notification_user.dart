import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../state management/getx/admin/admin_send_not_user_getx.dart';
import '../common method/Commmon_Method.dart';


class _C {
  static const bg = Color(0xFF0F1F17);
  static const surface = Color(0xFF162E22);
  static const header = Color(0xFF12261C);
  static const text = Color(0xFFE6F4EA);
  static const muted = Color(0xFF8A9A90);
  static const emerald = Color(0xFF22C55E);
  static const mint = Color(0xFF34D399);
  static const border = Color(0xFF234232);
}

class SendNotificationUser extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  final int User_Number;
  const SendNotificationUser({
    super.key,
    required this.User_Role,
    required this.User_JwtToken,
    required this.User_Email,
    required this.User_Number,
  });

  @override
  State<SendNotificationUser> createState() => _SendNotificationUserState();
}

class _SendNotificationUserState extends State<SendNotificationUser> {
  late final AdminSendNotUserGetx c;

  @override
  void initState() {
    super.initState();
    Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    c = Get.put(AdminSendNotUserGetx());
    c.jwtToken = widget.User_JwtToken;
  }

  @override
  void dispose() {
    try {
      Get.delete<AdminSendNotUserGetx>();
    } catch (e) {
      debugPrint(e.toString());
    }
    super.dispose();
  }

  Future<void> _onSend() async {
    try {
      FocusScope.of(context).unfocus();
      if (!c.validate()) return;
      final ok = await _confirm();
      if (ok != true) return;
      if (!mounted) return;
      await c.send(context);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<bool?> _confirm() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _C.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: _C.mint),
            SizedBox(width: 10),
            Flexible(
              child: Text('Confirm send',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _C.text, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send this notification to user ID ${c.userNumberCont.text.trim()}?',
                    style: const TextStyle(color: _C.muted, height: 1.4)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.bg.withOpacity(.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: Text(c.messageCont.text.trim(),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _C.text, height: 1.4)),
                ),
              ],
            ),
          ),
        ),
        actionsOverflowButtonSpacing: 8,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.text,
              side: const BorderSide(color: _C.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.emerald,
              foregroundColor: _C.bg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: Material(
            color: _C.surface.withOpacity(.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _C.mint, width: 1.2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: _C.text),
              ),
            ),
          ),
        ),
        title: const Text(
          'Send notification',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _Background(anim: c.bgAnim)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth.isFinite ? box.maxWidth : 360.0;
                final h = box.maxHeight.isFinite ? box.maxHeight : 640.0;
                final pad = (w * 0.04).clamp(8.0, 28.0);
                final compact = h < 520 || w < 340;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      pad, kToolbarHeight * .6, pad, pad),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                      math.max(0, h - pad - kToolbarHeight * .6),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: _Reveal(
                          index: 0,
                          child: _glassCard(compact, pad),
                        ),
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

  Widget _glassCard(bool compact, double pad) {
    final inner = (pad * 0.9).clamp(10.0, 28.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(inner),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _C.surface.withOpacity(.82),
                _C.header.withOpacity(.70),
              ],
            ),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: _C.emerald.withOpacity(.10),
                blurRadius: 40,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Reveal(index: 1, child: _header(compact)),
              SizedBox(height: compact ? 14 : 22),
              _Reveal(
                index: 2,
                child: _GlassField(
                  controller: c.messageCont,
                  enabledRx: c.isSending,
                  label: 'Enter the message',
                  hint: 'Write the notification text...',
                  icon: Icons.message_rounded,
                  maxLines: compact ? 3 : 5,
                  minLines: compact ? 2 : 3,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => Text(
                    '${c.messageLength.value} characters',
                    style:
                    const TextStyle(color: _C.muted, fontSize: 12),
                  )),
                ),
              ),
              const SizedBox(height: 10),
              _Reveal(
                index: 3,
                child: _GlassField(
                  controller: c.userNumberCont,
                  enabledRx: c.isSending,
                  label: 'Enter the user ID.',
                  hint: 'e.g. 1024',
                  icon: Icons.badge_rounded,
                  maxLines: 1,
                  minLines: 1,
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              SizedBox(height: compact ? 16 : 24),
              _Reveal(index: 4, child: _sendButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool compact) {
    final size = compact ? 44.0 : 64.0;
    return Column(
      children: [
        AnimatedBuilder(
          animation: c.bgAnim,
          builder: (_, __) {
            final pulse =
                0.5 + 0.5 * math.sin(c.bgAnim.value * 2 * math.pi * 6);
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_C.emerald, _C.mint],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.emerald.withOpacity(.25 + .25 * pulse),
                    blurRadius: 18 + 14 * pulse,
                    spreadRadius: 1 + 3 * pulse,
                  ),
                ],
              ),
              child: Icon(Icons.notifications_active_rounded,
                  color: _C.bg, size: size * .5),
            );
          },
        ),
        SizedBox(height: compact ? 8 : 14),
        const Text(
          'Send notification to user',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: _C.text, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        if (!compact) ...[
          const SizedBox(height: 6),
          const Text(
            'Write a message and deliver it straight to the user by ID.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.muted, fontSize: 13.5, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _sendButton() {
    return Obx(() {
      final sending = c.isSending.value;
      final ready = c.canSend.value && !sending;
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: c.canSend.value ? 1 : .55,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [_C.emerald, _C.mint]),
            boxShadow: [
              BoxShadow(
                color: _C.emerald.withOpacity(ready ? .35 : .10),
                blurRadius: ready ? 22 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: sending ? null : _onSend,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: sending
                      ? const SizedBox(
                    key: ValueKey('l'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.6, color: _C.bg),
                  )
                      : const Padding(
                    key: ValueKey('t'),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded,
                            color: _C.bg, size: 20),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Send notification to user.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _C.bg,
                                fontWeight: FontWeight.w800,
                                fontSize: 15),
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
      );
    });
  }
}

/// Fade + slide-up entrance, staggered by index.
class _Reveal extends StatelessWidget {
  final int index;
  final Widget child;
  const _Reveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (_, v, ch) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch),
      ),
      child: child,
    );
  }
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final RxBool enabledRx;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final int minLines;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? formatters;

  const _GlassField({
    required this.controller,
    required this.enabledRx,
    required this.label,
    required this.hint,
    required this.icon,
    required this.maxLines,
    required this.minLines,
    required this.keyboardType,
    this.formatters,
  });

  OutlineInputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() => TextField(
      controller: controller,
      enabled: !enabledRx.value,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      cursorColor: _C.mint,
      style: const TextStyle(color: _C.text, fontSize: 15, height: 1.4),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _C.muted),
        floatingLabelStyle: const TextStyle(color: _C.mint),
        hintStyle: TextStyle(color: _C.muted.withOpacity(.6)),
        prefixIcon: Icon(icon, color: _C.mint, size: 20),
        filled: true,
        fillColor: _C.bg.withOpacity(.55),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: _b(_C.border),
        disabledBorder: _b(_C.border.withOpacity(.5)),
        focusedBorder: _b(_C.mint, 1.6),
        border: _b(_C.border),
      ),
    ));
  }
}

/// Dark forest + blurred emerald blobs + translucent glass bubbles.
/// Fully wrapped in IgnorePointer so it never blocks touch/click.
class _Background extends StatelessWidget {
  final Animation<double> anim;
  const _Background({required this.anim});

  Widget _blob(double left, double top, double size, Color color,
      double opacity, Offset drift) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.translate(
        offset: drift,
        child: RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: 50, sigmaY: 50, tileMode: TileMode.decal),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color.withOpacity(opacity),
                  color.withOpacity(0),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(double left, double top, double size, Offset drift) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.translate(
        offset: drift,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(.10),
                    _C.mint.withOpacity(.03),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(.10)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : 360.0;
          final h = box.maxHeight.isFinite ? box.maxHeight : 640.0;
          final base = math.max(math.min(w, h), 220.0);
          return AnimatedBuilder(
            animation: anim,
            builder: (_, __) {
              final t = anim.value * 2 * math.pi;
              Offset d(double ph, double amp) =>
                  Offset(math.sin(t + ph) * amp, math.cos(t * 1.0 + ph) * amp);
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(child: ColoredBox(color: _C.bg)),
                  _blob(-base * .35, -base * .30, base * 1.1, _C.emerald,
                      .30, d(0, base * .05)),
                  _blob(w - base * .60, h * .30, base * 1.0, _C.mint, .20,
                      d(2, base * .06)),
                  _blob(-base * .25, h - base * .65, base * 1.0, _C.emerald,
                      .22, d(4, base * .05)),
                  _blob(w * .55, h - base * .45, base * .8, _C.mint, .16,
                      d(1, base * .04)),
                  _bubble(w * .12, h * .18, base * .14, d(1, 10)),
                  _bubble(w * .82, h * .12, base * .10, d(3, 12)),
                  _bubble(w * .08, h * .72, base * .18, d(5, 14)),
                  _bubble(w * .78, h * .78, base * .12, d(2, 10)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}