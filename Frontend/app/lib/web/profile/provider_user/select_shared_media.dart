import 'dart:math' as math;
import 'dart:ui' show ImageFilter;


import 'package:app/web/common method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state management/getx/profile/provider_user/select_shared_media_getx.dart';
import '../../common widget/design/bolbs_background.dart';

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

class SelectSharedMedia extends StatefulWidget {
  final String Current_User_Jwt_Token;
  const SelectSharedMedia({super.key, required this.Current_User_Jwt_Token});

  @override
  State<SelectSharedMedia> createState() => _SelectSharedMediaState();
}

class _SelectSharedMediaState extends State<SelectSharedMedia> {
  final String _tag = UniqueKey().toString();
  late final SelectSharedMediaGetx c;

  @override
  void initState() {
    super.initState();
    try {
      Provider_User_Jwt_Verify(
          Jwt_Token: widget.Current_User_Jwt_Token, context: context);
    } catch (_) {}
    c = Get.put(SelectSharedMediaGetx(), tag: _tag)
      ..init(widget.Current_User_Jwt_Token);
  }

  @override
  void dispose() {
    Get.delete<SelectSharedMediaGetx>(tag: _tag);
    super.dispose();
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
          "Shared Media",
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

          const Positioned.fill(child: IgnorePointer(child: AmbientBackground()

          )
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth;
                final bool wide = w >= 760;
                final double hPad = w >= 700 ? 28 : 16;

                final Widget sendTile = _Entrance(
                  index: 0,
                  child: _MediaTile(
                    c: c,
                    icon: Icons.cloud_upload_rounded,
                    title: "Send media",
                    subtitle: "Share photos, videos and documents.",
                    cta: "Open",
                    color: _C.accent,
                    onTap: () => c.openSendMedia(context),
                  ),
                );

                final Widget viewTile = _Entrance(
                  index: 1,
                  child: _MediaTile(
                    c: c,
                    icon: Icons.photo_library_rounded,
                    title: "View media",
                    subtitle: "Browse everything you have shared.",
                    cta: "Open",
                    color: _C.mint,
                    onTap: () => c.openViewMedia(context),
                  ),
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          const SizedBox(height: 24),
                          wide
                              ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: sendTile),
                              const SizedBox(width: 20),
                              Expanded(child: viewTile),
                            ],
                          )
                              : Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              sendTile,
                              const SizedBox(height: 16),
                              viewTile,
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
      duration: Duration(milliseconds: 380 + (index * 110)),
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
          child: const Icon(Icons.perm_media_rounded,
              color: _C.accent, size: 26),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Shared media",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _C.text, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                "Choose whether to send new media or view what you have shared.",
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

class _MediaTile extends StatelessWidget {
  final SelectSharedMediaGetx c;
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final Color color;
  final VoidCallback onTap;
  const _MediaTile({
    required this.c,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool busy = c.isOpening.value;
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: busy ? .55 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: busy ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: _glassCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(.4)),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.border),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: _C.text, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _C.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _C.muted, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      busy ? "Opening..." : cta,
                      style: TextStyle(
                          color: color,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

