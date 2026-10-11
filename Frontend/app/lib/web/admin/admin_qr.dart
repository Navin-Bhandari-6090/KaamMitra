import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust the relative import segment counts / folder names to your project.
import '../../constant/variable.dart';
import '../../state management/getx/admin/admin_qr_getx.dart';
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

class AdminQr extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  final int User_Number;
  const AdminQr({
    super.key,
    required this.User_Role,
    required this.User_JwtToken,
    required this.User_Email,
    required this.User_Number,
  });

  @override
  State<AdminQr> createState() => _AdminQrState();
}

class _AdminQrState extends State<AdminQr> {
  late final AdminQrGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    try {
      Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    } catch (obj) {
      print(obj.toString());
    }
    c = Get.put(AdminQrGetx(), tag: _tag);
    c.init(jwtToken: widget.User_JwtToken);
  }

  @override
  void dispose() {
    try {
      Get.delete<AdminQrGetx>(tag: _tag);
    } catch (obj) {
      print(obj.toString());
    }
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
          "Admin QR",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() => c.isLoading.value
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: _C.accent),
              ),
            ),
          )
              : IconButton(
            tooltip: "Refresh QR info",
            onPressed: c.loadInfo,
            icon: const Icon(Icons.refresh_rounded, color: _C.mint),
          )),
          const SizedBox(width: 6),
        ],
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
                w > 1100 ? (w - 1040) / 2 : (w >= 700 ? 24.0 : 14.0);

                return RefreshIndicator(
                  color: _C.accent,
                  backgroundColor: _C.surface,
                  onRefresh: c.loadInfo,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
                        sliver: SliverToBoxAdapter(child: _Header(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                        sliver: SliverToBoxAdapter(
                          child: LayoutBuilder(builder: (context, b) {
                            final dom = _Entrance(
                                index: 0,
                                child: _QrCard(
                                    c: c,
                                    type: "Domestic",
                                    icon: Icons.home_rounded,
                                    subtitle: "Used for domestic payments."));
                            final intl = _Entrance(
                                index: 1,
                                child: _QrCard(
                                    c: c,
                                    type: "International",
                                    icon: Icons.public_rounded,
                                    subtitle:
                                    "Used for international payments."));
                            if (b.maxWidth >= 760) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: dom),
                                  const SizedBox(width: 16),
                                  Expanded(child: intl),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                dom,
                                const SizedBox(height: 16),
                                intl,
                              ],
                            );
                          }),
                        ),
                      ),
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
// CONFIRM DIALOG (before every upload)
// =============================================================================
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
        content: Text(message,
            style: const TextStyle(color: _C.muted, height: 1.5)),
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
    );
    return r == true;
  } catch (obj) {
    print(obj.toString());
    return false;
  }
}

// =============================================================================
// SHARED SMALL PIECES
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
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
      duration: Duration(milliseconds: 420 + (index * 120).clamp(0, 420)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch),
      ),
      child: child,
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: outlined
                  ? null
                  : const LinearGradient(colors: [_C.accent, _C.mint]),
              color: outlined ? _C.surface : null,
              border: outlined ? Border.all(color: _C.border) : null,
              boxShadow: outlined
                  ? []
                  : [
                BoxShadow(
                    color: _C.accent.withOpacity(.32),
                    blurRadius: 16,
                    offset: const Offset(0, 7)),
              ],
            ),
            child: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(_C.bg)),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: outlined ? _C.mint : _C.bg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: outlined ? _C.text : _C.bg,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
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
// HEADER (reactive summary)
// =============================================================================
class _Header extends StatelessWidget {
  final AdminQrGetx c;
  const _Header({required this.c});

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
            child: const Icon(Icons.qr_code_2_rounded, color: _C.bg, size: 30),
          ),
        ),
        const SizedBox(height: 14),
        const Text("Manage Payment QR",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          "Upload and review the domestic and international QR codes.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (c.isLoading.value) {
            return const _Chip(icon: Icons.sync_rounded, text: "Loading QR info…");
          }
          final int n = c.uploadedCount;
          return _Chip(
            icon: n == 2 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            text: "$n of 2 QR codes uploaded",
            color: n == 2 ? _C.mint : _C.muted,
          );
        }),
      ],
    );
  }
}

// =============================================================================
// QR CARD — current QR, pending selection, pick + upload
// =============================================================================
class _QrCard extends StatelessWidget {
  final AdminQrGetx c;
  final String type;
  final IconData icon;
  final String subtitle;
  const _QrCard({
    required this.c,
    required this.type,
    required this.icon,
    required this.subtitle,
  });

  Future<void> _upload() async {
    try {
      if (c.uploadingType.value.isNotEmpty) return;
      if (!c.hasPending(type)) {
        Toast.Toastmsg("Pick photo first.");
        return;
      }
      final bool ok = await _confirm(
        title: "Upload ${type.toLowerCase()} QR?",
        message:
        "The selected photo will be uploaded as the $type QR and will replace the current one if it exists.",
        confirmLabel: "Upload",
        icon: Icons.cloud_upload_rounded,
      );
      if (!ok) return;
      await c.submitUpload(type);
    } catch (obj) {
      print(obj.toString());
    }
  }

  void _fullscreen(String label, Widget image) {
    try {
      Get.dialog(
        _FullscreenViewer(label: label, child: image),
        barrierColor: Colors.black87,
        useSafeArea: false,
      );
    } catch (obj) {
      print(obj.toString());
    }
  }

  Widget _sectionLabel(String text, Widget trailing) {
    return Row(
      children: [
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.text, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _glassCard(),
      child: LayoutBuilder(builder: (context, box) {
        final Size screen = MediaQuery.of(context).size;
        final double hLimit = (screen.height * 0.4).clamp(200.0, 380.0).toDouble();
        final double side = math.max(0.0, math.min(box.maxWidth, hLimit));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- title ----------------
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _C.mint.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.mint.withOpacity(.35)),
                  ),
                  child: Icon(icon, color: _C.mint, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$type QR",
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
                          style:
                          const TextStyle(color: _C.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------------- current QR (from server) ----------------
            Obx(() {
              final bool loading = c.isLoading.value;
              final String url = c.buildUrl(c.pathFor(type));
              final bool has = !loading && url.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel(
                    "Current QR",
                    loading
                        ? const _Chip(icon: Icons.sync_rounded, text: "Loading", color: _C.muted)
                        : has
                        ? const _Chip(icon: Icons.check_circle_rounded, text: "Uploaded")
                        : const _Chip(icon: Icons.cloud_off_rounded, text: "Not uploaded", color: _C.muted),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: KeyedSubtree(
                          key: ValueKey('cur_${type}_${loading}_$url'),
                          child: loading
                              ? const _SkeletonBox()
                              : has
                              ? _QrFrame(child: _NetworkQr(url: url))
                              : const _PlaceholderBox(
                              icon: Icons.qr_code_2_rounded,
                              text: "No QR uploaded yet"),
                        ),
                      ),
                    ),
                  ),
                  if (has) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _fullscreen(
                            "$type QR", _QrFrame(child: _NetworkQr(url: url))),
                        icon: const Icon(Icons.fullscreen_rounded, size: 20),
                        label: const Text("Full screen"),
                        style: _outlinedStyle(),
                      ),
                    ),
                  ],
                ],
              );
            }),

            // ---------------- pending selection ----------------
            Obx(() {
              final bool pending = c.hasPending(type);
              final bytes = change_photo_cont_getx.imageBytes.value;
              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: (!pending || bytes == null)
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionLabel(
                        "New selection",
                        const _Chip(
                            icon: Icons.fiber_new_rounded,
                            text: "Ready to upload",
                            color: _C.accent),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
                          width: side,
                          height: side,
                          child: _QrFrame(
                              child: _MemoryQr(
                                  bytes: Uint8List.fromList(bytes.toList()))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _fullscreen(
                                "New $type QR",
                                _QrFrame(
                                    child: _MemoryQr(
                                        bytes: Uint8List.fromList(
                                            bytes.toList())))),
                            icon: const Icon(Icons.fullscreen_rounded, size: 20),
                            label: const Text("Full screen"),
                            style: _outlinedStyle(),
                          ),
                          OutlinedButton.icon(
                            onPressed: c.clearPicked,
                            icon: const Icon(Icons.close_rounded, size: 20),
                            label: const Text("Discard"),
                            style: _outlinedStyle(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 18),
            Container(height: 1, color: _C.border),
            const SizedBox(height: 18),

            // ---------------- actions ----------------
            LayoutBuilder(builder: (context, b) {
              final pick = Obx(() => _GradientButton(
                outlined: true,
                label: "Pick ${type.toLowerCase()} QR",
                icon: Icons.add_photo_alternate_rounded,
                onTap: c.uploadingType.value.isNotEmpty
                    ? null
                    : () => c.pickFor(type),
              ));
              final upload = Obx(() => _GradientButton(
                label: "Add ${type.toLowerCase()} QR",
                icon: Icons.cloud_upload_rounded,
                loading: c.uploadingType.value == type,
                onTap: c.uploadingType.value.isNotEmpty ? null : _upload,
              ));
              if (b.maxWidth >= 360) {
                return Row(children: [
                  Expanded(child: pick),
                  const SizedBox(width: 10),
                  Expanded(child: upload),
                ]);
              }
              return Column(children: [
                pick,
                const SizedBox(height: 10),
                upload,
              ]);
            }),
          ],
        );
      }),
    );
  }

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
    foregroundColor: _C.text,
    minimumSize: const Size(0, 42),
    side: const BorderSide(color: _C.border, width: 1.2),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// =============================================================================
// QR IMAGE PIECES (white frame so the QR stays scannable on the dark theme)
// =============================================================================
class _QrFrame extends StatelessWidget {
  final Widget child;
  const _QrFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: _C.accent.withOpacity(.14),
              blurRadius: 22,
              spreadRadius: 1),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _NetworkQr extends StatelessWidget {
  final String url;
  const _NetworkQr({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, p) => p == null
          ? child
          : const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: _C.accent),
        ),
      ),
      errorBuilder: (context, e, st) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.black38, size: 36),
      ),
    );
  }
}

class _MemoryQr extends StatelessWidget {
  final Uint8List bytes;
  const _MemoryQr({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, e, st) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.black38, size: 36),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PlaceholderBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1711),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _C.muted, size: 40),
                const SizedBox(height: 10),
                Text(text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _C.muted, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox();

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .4, end: 1)
          .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.07),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// =============================================================================
// FULLSCREEN VIEWER
// =============================================================================
class _FullscreenViewer extends StatelessWidget {
  final String label;
  final Widget child;
  const _FullscreenViewer({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: _C.bg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: "Close",
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Get.back(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.text, width: 1.2),
                          ),
                          child: const Icon(Icons.close_rounded, color: _C.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: InteractiveViewer(
                    minScale: .8,
                    maxScale: 5,
                    child: Center(child: child),
                  ),
                ),
              ),
            ],
          ),
        ),
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