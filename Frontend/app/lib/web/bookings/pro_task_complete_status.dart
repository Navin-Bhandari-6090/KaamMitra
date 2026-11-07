import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

// Adjust the relative import segment counts / folder names to your project.
import '../../constant/variable.dart';
import '../../models/BookingInfoModel.dart';
import '../../models/ProTaskCompPayInfoModel.dart';

import '../../state management/getx/booking/pro_task_complete_getx.dart';
import '../authentication/Error_page.dart';
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

String _money(double v) => v.isFinite ? v.toStringAsFixed(2) : "0.00";

String _methodLabel(String? m) {
  if (m == "Domestic") return "Nepal (Domestic)";
  if (m == "International") return "International";
  return (m == null || m.isEmpty) ? "Unknown method" : m;
}

// =============================================================================
// SCREEN  (StatefulWidget only for controller lifecycle — zero setState)
// =============================================================================
class ProTaskCompleteStatus extends StatefulWidget {
  final String Current_User_Email;
  final String Current_User_JwtToken;
  final String Current_User_Role;
  final int Current_User_Number;
  final List<BookingInfoModel> BookingInfoListInfo;

  const ProTaskCompleteStatus({
    super.key,
    required this.Current_User_Email,
    required this.Current_User_JwtToken,
    required this.Current_User_Role,
    required this.Current_User_Number,
    required this.BookingInfoListInfo,
  });

  @override
  State<ProTaskCompleteStatus> createState() => _ProTaskCompleteStatusState();
}

class _ProTaskCompleteStatusState extends State<ProTaskCompleteStatus> {
  late final ProTaskCompleteGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    c = Get.put(ProTaskCompleteGetx(), tag: _tag);
    c.init(
      jwtToken: widget.Current_User_JwtToken,
      bookings: widget.BookingInfoListInfo,
      onSessionEnd: () {
        try {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context as BuildContext,
            MaterialPageRoute(builder: (context) => ErrorPage()),
                (route) => false,
          );
        } catch (obj) {
          print(obj.toString());
        }
      },
    );
  }

  @override
  void dispose() {
    try {
      Get.delete<ProTaskCompleteGetx>(tag: _tag);
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
          "Provider Task Complete Status",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() => (c.isLoadingQr.value || c.isLoadingPayments.value)
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
            tooltip: "Refresh",
            onPressed: c.loadAll,
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
                  onRefresh: c.loadAll,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 0),
                        sliver: SliverToBoxAdapter(child: _Header(c: c)),
                      ),
                      if (c.booking == null)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                          sliver: const SliverToBoxAdapter(
                            child: _Section(
                              icon: Icons.error_outline_rounded,
                              title: "Booking unavailable",
                              subtitle: "No booking information was provided.",
                              tone: _C.danger,
                              child: _PlaceholderBox(
                                  icon: Icons.event_busy_rounded,
                                  text: "Booking information is not available."),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _Entrance(index: 0, child: _AmountsSection(c: c)),
                              const SizedBox(height: 16),
                              _Entrance(index: 1, child: _AdminQrSection(c: c)),
                              const SizedBox(height: 16),
                              _Entrance(index: 2, child: _ExampleSection(c: c)),
                              const SizedBox(height: 16),
                              _Entrance(index: 3, child: _ProofsSection(c: c)),
                              const SizedBox(height: 16),
                              _Entrance(index: 4, child: _UploadSection(c: c, context: context,)),
                            ]),
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
// CONFIRM DIALOG (before every upload / update / send)
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

ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
  foregroundColor: _C.text,
  minimumSize: const Size(0, 42),
  side: const BorderSide(color: _C.border, width: 1.2),
  textStyle: const TextStyle(fontWeight: FontWeight.w600),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  const _Entrance({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 100).clamp(0, 400)),
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
                  : LinearGradient(
                  colors: onTap == null && !loading
                      ? [_C.accent.withOpacity(.35), _C.mint.withOpacity(.35)]
                      : const [_C.accent, _C.mint]),
              color: outlined ? _C.surface : null,
              border: outlined ? Border.all(color: _C.border) : null,
              boxShadow: (outlined || onTap == null)
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

/// Glass card with an icon title, used for every section.
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final Color tone;
  const _Section({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.tone = _C.mint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _glassCard(),
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
                        style: const TextStyle(color: _C.muted, fontSize: 12.5)),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Two children side by side on wide layouts, stacked on narrow ones.
class _TwoUp extends StatelessWidget {
  final Widget a;
  final Widget b;
  final double breakpoint;
  const _TwoUp({required this.a, required this.b, this.breakpoint = 560});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth >= breakpoint) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 14),
            Expanded(child: b),
          ],
        );
      }
      return Column(children: [a, const SizedBox(height: 14), b]);
    });
  }
}

// =============================================================================
// HEADER
// =============================================================================
class _Header extends StatelessWidget {
  final ProTaskCompleteGetx c;
  const _Header({required this.c});

  @override
  Widget build(BuildContext context) {
    final BookingInfoModel? b = c.booking;
    final String email = (b?.providerEmail ?? '').trim();
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
            child:
            const Icon(Icons.task_alt_rounded, color: _C.bg, size: 30),
          ),
        ),
        const SizedBox(height: 14),
        const Text("Task Complete & Payments",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          "Review payment amounts, admin QR codes and payment proofs.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
        if (b != null) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                  icon: Icons.tag_rounded,
                  text: "Book ID ${b.bookId ?? '-'}",
                  color: _C.accent),
              if (email.isNotEmpty)
                _Chip(icon: Icons.alternate_email_rounded, text: email),
            ],
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// 1) PAYMENT AMOUNTS
// =============================================================================
class _AmountsSection extends StatelessWidget {
  final ProTaskCompleteGetx c;
  const _AmountsSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.payments_rounded,
      title: "Payment amounts",
      subtitle: "Final amounts after discount.",
      child: _TwoUp(
        a: _AmountCard(
          label: "Nepal payment amount",
          icon: Icons.home_rounded,
          original: c.domesticOriginalPrice,
          percent: c.domesticDiscountPercent,
          saved: c.domesticDiscountAmount,
          payable: c.domesticPaymentAmount,
        ),
        b: _AmountCard(
          label: "International payment amount",
          icon: Icons.public_rounded,
          original: c.internationalOriginalPrice,
          percent: c.internationalDiscountPercent,
          saved: c.internationalDiscountAmount,
          payable: c.internationalPaymentAmount,
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final double original;
  final double percent;
  final double saved;
  final double payable;
  const _AmountCard({
    required this.label,
    required this.icon,
    required this.original,
    required this.percent,
    required this.saved,
    required this.payable,
  });

  Widget _row(String k, String v, {Color color = _C.muted}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              child: Text(k,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _C.muted, fontSize: 12.5))),
          const SizedBox(width: 8),
          Text(v,
              style: TextStyle(
                  color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.bar,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _C.mint, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [_C.accent, _C.mint],
                ).createShader(r),
                child: Text(_money(payable),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: _C.border),
          const SizedBox(height: 6),
          _row("Original price", _money(original)),
          _row("Discount", "${percent.isFinite ? percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2) : '0'}%"),
          _row("Discount amount", "- ${_money(saved)}", color: _C.mint),
        ],
      ),
    );
  }
}

// =============================================================================
// 2) ADMIN QR
// =============================================================================
class _AdminQrSection extends StatelessWidget {
  final ProTaskCompleteGetx c;
  const _AdminQrSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.qr_code_2_rounded,
      title: "KaamMitra QR codes",
      subtitle:
      "Scan the Nepal QR, or pay with PayPal for international payments, then upload the payment proof below.",
      child: _TwoUp(
        a: _QrTile(
            c: c,
            type: "Domestic",
            label: "Nepal (Domestic) QR",
            icon: Icons.home_rounded),
        b: _QrTile(
            c: c,
            type: "International",
            label: "International QR (PayPal)",
            icon: Icons.public_rounded),
      ),
    );
  }
}

class _QrTile extends StatelessWidget {
  final ProTaskCompleteGetx c;
  final String type;
  final String label;
  final IconData icon;
  const _QrTile({
    required this.c,
    required this.type,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final Size screen = MediaQuery.of(context).size;
      final double hLimit = (screen.height * 0.38).clamp(200.0, 340.0).toDouble();
      final double side = math.max(0.0, math.min(box.maxWidth, hLimit));

      return Obx(() {
        final bool loading = c.isLoadingQr.value;
        final String url = c.buildUrl(c.qrPathFor(type));
        final bool has = !loading && url.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: _C.mint, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _C.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                loading
                    ? const _Chip(icon: Icons.sync_rounded, text: "Loading", color: _C.muted)
                    : has
                    ? const _Chip(icon: Icons.check_circle_rounded, text: "Available")
                    : const _Chip(icon: Icons.cloud_off_rounded, text: "Not available", color: _C.muted),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: side,
                height: side,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: KeyedSubtree(
                    key: ValueKey('qr_${type}_${loading}_$url'),
                    child: loading
                        ? const _SkeletonBox()
                        : has
                        ? _Frame(child: _NetworkPhoto(url: url))
                        : _PlaceholderBox(
                        icon: Icons.qr_code_2_rounded,
                        text: type == "International"
                            ? "PayPal QR not uploaded yet"
                            : "QR not uploaded yet"),
                  ),
                ),
              ),
            ),
            if (has) ...[
              const SizedBox(height: 10),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _fullscreen(label, _Frame(child: _NetworkPhoto(url: url))),
                  icon: const Icon(Icons.fullscreen_rounded, size: 20),
                  label: const Text("Full screen"),
                  style: _outlinedStyle(),
                ),
              ),
            ],
          ],
        );
      });
    });
  }
}

// =============================================================================
// 2b) EXAMPLE PAYMENT PHOTOS (assets/images/payment/nepal.jpg + paypal.jpg)
// =============================================================================
class _ExampleSection extends StatelessWidget {
  final ProTaskCompleteGetx c;
  const _ExampleSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.fact_check_rounded,
      title: "Example payment photos",
      subtitle:
      "Your payment photo must show all transaction details like these examples, otherwise it is not valid.",
      child: _TwoUp(
        a: _ExampleTile(
          c: c,
          asset: ProTaskCompleteGetx.nepalExampleAsset,
          label: "Nepal payment example",
          icon: Icons.home_rounded,
        ),
        b: _ExampleTile(
          c: c,
          asset: ProTaskCompleteGetx.paypalExampleAsset,
          label: "PayPal (International) example",
          icon: Icons.public_rounded,
        ),
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  final ProTaskCompleteGetx c;
  final String asset;
  final String label;
  final IconData icon;
  const _ExampleTile({
    required this.c,
    required this.asset,
    required this.label,
    required this.icon,
  });

  Widget _photo() => _Frame(
    dark: true,
    child: Image.asset(
      asset,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, e, st) => const Center(
        child: Icon(Icons.broken_image_outlined, color: _C.muted, size: 36),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final Size screen = MediaQuery.of(context).size;
      final double hLimit = (screen.height * 0.42).clamp(220.0, 400.0).toDouble();
      final double side = math.max(0.0, math.min(box.maxWidth, hLimit));

      return Obx(() {
        final bool? ok = c.exampleOk[asset]; // null = still checking
        final bool checking = ok == null;
        final bool has = ok == true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: _C.mint, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _C.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                checking
                    ? const _Chip(icon: Icons.sync_rounded, text: "Loading", color: _C.muted)
                    : has
                    ? const _Chip(icon: Icons.check_circle_rounded, text: "Example")
                    : const _Chip(icon: Icons.cloud_off_rounded, text: "Not available", color: _C.muted),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: side,
                height: side,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: KeyedSubtree(
                    key: ValueKey('ex_${asset}_${ok ?? 'x'}'),
                    child: checking
                        ? const _SkeletonBox()
                        : has
                        ? _photo()
                        : const _PlaceholderBox(
                        icon: Icons.image_not_supported_outlined,
                        text: "Example payment photo not available"),
                  ),
                ),
              ),
            ),
            if (has) ...[
              const SizedBox(height: 10),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _fullscreen(label, _photo()),
                  icon: const Icon(Icons.fullscreen_rounded, size: 20),
                  label: const Text("Full screen"),
                  style: _outlinedStyle(),
                ),
              ),
            ],
          ],
        );
      });
    });
  }
}

// =============================================================================
// 3) PROVIDER PAYMENT PROOFS
// =============================================================================
class _ProofsSection extends StatelessWidget {
  final ProTaskCompleteGetx c;
  const _ProofsSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool loading = c.isLoadingPayments.value;
      final List<ProTaskCompPayInfoModel> list = c.visiblePayments;

      Widget body;
      if (loading) {
        body = const SizedBox(height: 200, child: _SkeletonBox());
      } else if (list.isEmpty) {
        body = const SizedBox(
          height: 200,
          child: _PlaceholderBox(
              icon: Icons.receipt_long_outlined,
              text: "No payment photo has been uploaded yet."),
        );
      } else {
        body = Column(
          children: [
            for (int i = 0; i < list.length; i++) ...[
              _Entrance(
                  key: ValueKey('pay_$i'),
                  index: i,
                  child: _PaymentCard(c: c, p: list[i], number: i + 1)),
              if (i != list.length - 1) const SizedBox(height: 14),
            ],
          ],
        );
      }

      return _Section(
        icon: Icons.receipt_long_rounded,
        title: "Provider payment photos",
        subtitle: "Proofs uploaded for this booking.",
        trailing: loading ? null : _Chip(icon: Icons.layers_rounded, text: "${list.length}"),
        child: body,
      );
    });
  }
}

class _PaymentCard extends StatelessWidget {
  final ProTaskCompleteGetx c;
  final ProTaskCompPayInfoModel p;
  final int number;
  const _PaymentCard({required this.c, required this.p, required this.number});

  @override
  Widget build(BuildContext context) {
    final String url = c.buildUrl(c.paymentPhotoOf(p));
    final String? method = c.paymentMethodOf(p);
    final double? amount = c.paymentAmountOf(p);
    final String date = c.dateLabel(c.paymentDateOf(p));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.bar,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final Size screen = MediaQuery.of(context).size;
        final double h = (screen.height * 0.42).clamp(220.0, 420.0).toDouble();
        final double w = math.max(0.0, math.min(box.maxWidth, 560.0));

        return Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(icon: Icons.numbers_rounded, text: "#$number", color: _C.accent),
                _Chip(icon: Icons.account_balance_wallet_outlined, text: _methodLabel(method)),
                if (amount != null)
                  _Chip(icon: Icons.payments_outlined, text: _money(amount)),
                _Chip(icon: Icons.schedule_rounded, text: date, color: _C.muted),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: w,
              height: h,
              child: url.isEmpty
                  ? const _PlaceholderBox(
                  icon: Icons.image_not_supported_outlined,
                  text: "No photo for this payment.")
                  : _Frame(dark: true, child: _NetworkPhoto(url: url, dark: true)),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _fullscreen(
                    "Payment #$number · ${_methodLabel(method)}",
                    _Frame(dark: true, child: _NetworkPhoto(url: url, dark: true))),
                icon: const Icon(Icons.fullscreen_rounded, size: 20),
                label: const Text("Full screen"),
                style: _outlinedStyle(),
              ),
            ],
          ],
        );
      }),
    );
  }
}

// =============================================================================
// 4) UPLOAD PAYMENT PHOTO  (every action asks Confirm / Cancel)
// =============================================================================
class _UploadSection extends StatelessWidget {
  final ProTaskCompleteGetx c;
  final BuildContext context;
  const _UploadSection({required this.c, required this.context});

  Future<void> _pick() async {
    try {
      if (c.uploadingMethod.value.isNotEmpty) return;
      if (change_photo_cont_getx.imageBytes.value != null) {
        final bool ok = await _confirm(
          title: "Replace selected photo?",
          message:
          "A photo is already selected. Picking a new one will replace it.",
          confirmLabel: "Replace",
          icon: Icons.swap_horiz_rounded,
        );
        if (!ok) return;
      }
      await c.pickPhoto();
    } catch (obj) {
      print(obj.toString());
    }
  }

  Future<void> _discard() async {
    try {
      if (c.uploadingMethod.value.isNotEmpty) return;
      final bool ok = await _confirm(
        title: "Discard photo?",
        message: "The selected photo will be removed. You can pick it again.",
        confirmLabel: "Discard",
        icon: Icons.delete_outline_rounded,
      );
      if (!ok) return;
      c.clearPicked();
    } catch (obj) {
      print(obj.toString());
    }
  }

  Future<void> _upload(String method) async 
  {
    try {
      if (c.uploadingMethod.value.isNotEmpty) return;
      if (change_photo_cont_getx.imageBytes.value == null) {
        Toast.Toastmsg("Please pick photo first.");
        return;
      }
      final bool domestic = method == "Domestic";
      final double amount =
      domestic ? c.domesticPaymentAmount : c.internationalPaymentAmount;
      final bool ok = await _confirm(
        title: "Upload ${domestic ? 'Nepal' : 'international'} payment?",
        message:
        "The selected photo will be uploaded as the ${_methodLabel(method)} payment of ${_money(amount)} for Book ID ${c.booking?.bookId ?? '-'}.",
        confirmLabel: "Upload",
        icon: Icons.cloud_upload_rounded,
      );
      if (!ok) return;
      await c.submitPayment(method, context: context);
    } catch (obj) {
      print(obj.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.cloud_upload_rounded,
      title: "Upload payment photo",
      subtitle: "Pick one photo, then upload it as Nepal or international.",
      child: LayoutBuilder(builder: (context, box) {
        final Size screen = MediaQuery.of(context).size;
        final double hLimit = (screen.height * 0.4).clamp(200.0, 360.0).toDouble();
        final double side = math.max(0.0, math.min(box.maxWidth, hLimit));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              final bytes = change_photo_cont_getx.imageBytes.value;
              final bool has = bytes != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text("Selected photo",
                            style: TextStyle(
                                color: _C.text,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                      ),
                      has
                          ? const _Chip(icon: Icons.check_circle_rounded, text: "Ready to upload")
                          : const _Chip(icon: Icons.image_outlined, text: "No photo", color: _C.muted),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: KeyedSubtree(
                          key: ValueKey('pending_${has}_${bytes?.length ?? 0}'),
                          child: has
                              ? _Frame(
                              dark: true,
                              child: _MemoryPhoto(
                                  bytes: Uint8List.fromList(bytes.toList())))
                              : const _PlaceholderBox(
                              icon: Icons.add_photo_alternate_outlined,
                              text: "Pick a payment photo to preview it here"),
                        ),
                      ),
                    ),
                  ),
                  if (has) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _fullscreen(
                              "Selected payment photo",
                              _Frame(
                                  dark: true,
                                  child: _MemoryPhoto(
                                      bytes: Uint8List.fromList(bytes.toList())))),
                          icon: const Icon(Icons.fullscreen_rounded, size: 20),
                          label: const Text("Full screen"),
                          style: _outlinedStyle(),
                        ),
                        OutlinedButton.icon(
                          onPressed: _discard,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: const Text("Discard"),
                          style: _outlinedStyle(),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 16),
            Container(height: 1, color: _C.border),
            const SizedBox(height: 16),
            Obx(() => _GradientButton(
              outlined: true,
              label: "Pick payment photo.",
              icon: Icons.add_photo_alternate_rounded,
              onTap: c.uploadingMethod.value.isNotEmpty ? null : _pick,
            )),
            const SizedBox(height: 12),
            _TwoUp(
              breakpoint: 520,
              a: Obx(() => _GradientButton(
                label: "Upload nepal payment photo.",
                icon: Icons.home_rounded,
                loading: c.uploadingMethod.value == "Domestic",
                onTap: c.uploadingMethod.value.isNotEmpty
                    ? null
                    : () => _upload("Domestic"),
              )),
              b: Obx(() => _GradientButton(
                label: "Upload international payment photo.",
                icon: Icons.public_rounded,
                loading: c.uploadingMethod.value == "International",
                onTap: c.uploadingMethod.value.isNotEmpty
                    ? null
                    : () => _upload("International"),
              )),
            ),
          ],
        );
      }),
    );
  }
}

// =============================================================================
// PHOTO PIECES
// =============================================================================
/// Frame around a photo. White for QR codes (scannable), dark for proofs.
class _Frame extends StatelessWidget {
  final Widget child;
  final bool dark;
  const _Frame({required this.child, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0B1711) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: _C.accent.withOpacity(.12),
              blurRadius: 22,
              spreadRadius: 1),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  final String url;
  final bool dark;
  const _NetworkPhoto({required this.url, this.dark = false});

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
      errorBuilder: (context, e, st) => Center(
        child: Icon(Icons.broken_image_outlined,
            color: dark ? _C.muted : Colors.black38, size: 36),
      ),
    );
  }
}

class _MemoryPhoto extends StatelessWidget {
  final Uint8List bytes;
  const _MemoryPhoto({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, e, st) => const Center(
        child: Icon(Icons.broken_image_outlined, color: _C.muted, size: 36),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1711),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _C.muted, size: 38),
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