import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust the relative import segment counts / folder names to your project.
import '../../constant/variable.dart';
import '../../models/AdminTaskCompletePaymentModel.dart';
import '../../state management/getx/admin/book_pro_task_comp_getx.dart';
import '../bookings/view_book_file.dart';
import '../bookings/view_book_video.dart';
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
  static const Color warn = Color(0xFFFBBF24);
}

// =============================================================================
// SCREEN (StatefulWidget only for controller lifecycle — zero setState)
// =============================================================================
class BookingProTaskCompletePay extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  final int User_Number;
  const BookingProTaskCompletePay({
    super.key,
    required this.User_Role,
    required this.User_JwtToken,
    required this.User_Email,
    required this.User_Number,
  });

  @override
  State<BookingProTaskCompletePay> createState() =>
      _BookingProTaskCompletePayState();
}

class _BookingProTaskCompletePayState extends State<BookingProTaskCompletePay> {
  late final BookProTaskCompGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    try {
      Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    } catch (obj) {
      print(obj.toString());
    }
    c = Get.put(BookProTaskCompGetx(), tag: _tag);
    c.init(jwtToken: widget.User_JwtToken);
  }

  @override
  void dispose() {
    try {
      Get.delete<BookProTaskCompGetx>(tag: _tag);
    } catch (obj) {
      print(obj.toString());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {

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
          "Bookings & Payments",
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
            tooltip: "Refresh",
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
                w > 1360 ? (w - 1280) / 2 : (w >= 700 ? 24.0 : 14.0);

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
                        padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 0),
                        sliver: SliverToBoxAdapter(child: _Toolbar(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 40),
                        sliver: SliverToBoxAdapter(child: _Content(c: c, Current_User_JwtToken: widget.User_JwtToken,)),
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
// HELPERS
// =============================================================================
String _txt(String? s) => (s == null || s.trim().isEmpty) ? '—' : s.trim();

String _numStr(num? n) {
  if (n == null) return '—';
  return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
}

String _fmtDate(dynamic v) {
  try {
    if (v == null) return '—';
    final String raw = v.toString();
    final DateTime? d = DateTime.tryParse(raw);
    if (d == null) return raw.isEmpty ? '—' : raw;
    final DateTime l = d.toLocal();
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(l.day)} ${m[l.month - 1]} ${l.year}, ${two(l.hour)}:${two(l.minute)}';
  } catch (_) {
    return '—';
  }
}

String _coords(num? lat, num? lon) {
  if (lat == null || lon == null) return '—';
  return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
}

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
// CONFIRM DIALOG (Cancel / Confirm before every action)
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

// =============================================================================
// SMALL SHARED PIECES
// =============================================================================
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
      duration: Duration(milliseconds: 420 + (index * 90).clamp(0, 450)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool danger;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null && !loading;
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: danger
                  ? null
                  : LinearGradient(colors: [
                _C.accent.withOpacity(disabled ? .45 : 1),
                _C.mint.withOpacity(disabled ? .45 : 1)
              ]),
              color: danger ? _C.danger.withOpacity(disabled ? .06 : .12) : null,
              border: danger
                  ? Border.all(color: _C.danger.withOpacity(.6), width: 1.2)
                  : null,
              boxShadow: danger || disabled
                  ? []
                  : [
                BoxShadow(
                    color: _C.accent.withOpacity(.30),
                    blurRadius: 16,
                    offset: const Offset(0, 7)),
              ],
            ),
            child: loading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      danger ? _C.danger : _C.bg)),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: danger ? _C.danger : _C.bg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: danger ? _C.danger : _C.bg,
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _SectionTitle(
      {required this.icon, required this.text, this.color = _C.mint});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.text, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _Info {
  final IconData icon;
  final String label;
  final String value;
  const _Info(this.icon, this.label, this.value);
}

class _InfoGrid extends StatelessWidget {
  final List<_Info> items;
  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, b) {
      final int cols = b.maxWidth >= 460 ? 2 : 1;
      final double w = math.max(0.0, (b.maxWidth - (cols - 1) * 10) / cols);
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final i in items)
            SizedBox(
              width: w,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _C.bg.withOpacity(.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(i.icon, size: 16, color: _C.mint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _C.muted, fontSize: 11.5)),
                          const SizedBox(height: 2),
                          Text(i.value,
                              style: const TextStyle(
                                  color: _C.text,
                                  fontSize: 13.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// Read-only, input-looking field showing the value the action will use.
class _ReadField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadField(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.bg.withOpacity(.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _C.muted),
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
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  final String title;
  final String hint;
  final List<Widget> fields; // shown ABOVE the button
  final Widget button;
  final bool danger;
  const _ActionGroup({
    required this.title,
    required this.hint,
    required this.fields,
    required this.button,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color tone = danger ? _C.danger : _C.mint;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withOpacity(.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withOpacity(.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: TextStyle(
                  color: tone, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(hint,
              style:
              const TextStyle(color: _C.muted, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, b) {
            final int cols = (fields.length > 1 && b.maxWidth >= 360) ? 2 : 1;
            final double w =
            math.max(0.0, (b.maxWidth - (cols - 1) * 10) / cols);
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final f in fields) SizedBox(width: w, child: f)],
            );
          }),
          const SizedBox(height: 12),
          button,
        ],
      ),
    );
  }
}

// =============================================================================
// HEADER (reactive summary)
// =============================================================================
class _Header extends StatelessWidget {
  final BookProTaskCompGetx c;
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
            child: const Icon(Icons.receipt_long_rounded, color: _C.bg, size: 30),
          ),
        ),
        const SizedBox(height: 14),
        const Text("Bookings & Task Payments",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          "Review booking details, provider payments and manage them safely.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (c.isLoading.value) {
            return const

            _Chip(
                icon: Icons.sync_rounded, text: "Loading…", color: _C.muted);
          }
          // Distinct bookings (a booking with many payments counts once).
          final int total = c.bookingCount;
          final int paid = c.paymentCount;
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(icon: Icons.event_note_rounded, text: "$total bookings"),
              _Chip(
                  icon: Icons.payments_rounded,
                  text: "$paid payments",
                  color: _C.accent),
            ],
          );
        }),
      ],
    );
  }
}

// =============================================================================
// TOOLBAR — tab switcher + search
// =============================================================================
class _Toolbar extends StatelessWidget {
  final BookProTaskCompGetx c;
  const _Toolbar({required this.c});

  Widget _tabBtn(int index, IconData icon, String label) {
    return Expanded(
      child: Obx(() {
        final bool sel = c.tab.value == index;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => c.tab.value = index,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: sel
                  ? const LinearGradient(colors: [_C.accent, _C.mint])
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: sel ? _C.bg : _C.muted),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: sel ? _C.bg : _C.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _search({
    required TextEditingController ctrl,
    required String hint,
    required RxString query,
  }) {
    return TextField(
      controller: ctrl,
      onChanged: (v) => query.value = v,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: _C.text, fontSize: 14.5),
      cursorColor: _C.mint,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
        filled: true,
        fillColor: _C.surface.withOpacity(.9),
        prefixIcon: const Icon(Icons.search_rounded, color: _C.mint),
        suffixIcon: Obx(() => query.value.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
          tooltip: "Clear",
          icon: const Icon(Icons.close_rounded, color: _C.muted),
          onPressed: () {
            ctrl.clear();
            query.value = '';
          },
        )),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _C.surface.withOpacity(.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              _tabBtn(0, Icons.event_note_rounded, "Booking details"),
              const SizedBox(width: 4),
              _tabBtn(1, Icons.payments_rounded, "Task payment"),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey('search_${c.tab.value}'),
            child: c.tab.value == 0
                ? _search(
                ctrl: c.bookingSearchCont,
                hint: "Search by Book ID or User number",
                query: c.bookingQuery)
                : _search(
                ctrl: c.paymentSearchCont,
                hint: "Search by Payment ID or Book ID",
                query: c.paymentQuery),
          ),
        )),
      ],
    );
  }
}

// =============================================================================
// CONTENT — responsive grid of cards (reactive)
// =============================================================================
class _Content extends StatelessWidget {
  final String Current_User_JwtToken;
  final BookProTaskCompGetx c;
  const _Content({required this.c, required this.Current_User_JwtToken});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, b) {
      final double w = b.maxWidth;
      final int cols = w >= 1000 ? 3 : (w >= 680 ? 2 : 1);
      const double gap = 16;
      final double cardW = math.max(0.0, (w - gap * (cols - 1)) / cols);

      return Obx(() {
        final bool loading = c.isLoading.value;
        final int tab = c.tab.value;
        // Reading these registers the reactive dependencies.
        final bool searching =
            (tab == 0 ? c.bookingQuery.value : c.paymentQuery.value)
                .trim()
                .isNotEmpty;
        final List<AdminTaskCompletePaymentModel> items =
        tab == 0 ? c.filteredBookings : c.filteredPayments;

        if (loading) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (int i = 0; i < cols; i++)
                SizedBox(
                    width: cardW,
                    height: 260,
                    child: const _SkeletonBox()),
            ],
          );
        }

        if (items.isEmpty) {
          return _EmptyState(
            text: searching
                ? "No results match your search."
                : (tab == 0
                ? "No booking information available."
                : "No task payment information available."),
          );
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int i = 0; i < items.length; i++)
              SizedBox(
                width: cardW,
                child: _Entrance(
                  key: ValueKey(tab == 0
                      ? 'b_${items[i].bookingInfo?.bookId}_$i'
                      : 'p_${items[i].paymentInfo?.taskCompletePaymentId}_$i'),
                  index: i,
                  child: tab == 0
                      ? _BookingCard(c: c, m: items[i], Current_User_JwtToken: Current_User_JwtToken,)
                      : _PaymentCard(c: c, m: items[i]),
                ),
              ),
          ],
        );
      });
    });
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: _glassCard(),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: _C.muted, size: 46),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.muted, fontSize: 14)),
        ],
      ),
    );
  }
}

// =============================================================================
// BOOKING CARD
// =============================================================================
class _BookingCard extends StatelessWidget {
  final String Current_User_JwtToken;
  final BookProTaskCompGetx c;
  final AdminTaskCompletePaymentModel m;
  const _BookingCard({required this.c, required this.m, required this.Current_User_JwtToken});

  Widget _status(String label, bool? v) {
    final bool on = v == true;
    return _Chip(
      icon: on ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
      text: label,
      color: on ? _C.mint : _C.warn,
    );
  }

  @override
  Widget build(BuildContext context)
  {

    final b = m.bookingInfo;
    final p = m.paymentInfo;
    final num? bookId = b?.bookId;
    final num? providerNumber = b?.providerNumber;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------- title ----------------
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _C.mint.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.mint.withOpacity(.35)),
                ),
                child: const Icon(Icons.event_note_rounded,
                    color: _C.mint, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Booking #${_numStr(bookId)}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(_txt(b?.serviceName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        const TextStyle(color: _C.muted, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              p != null
                  ? const _Chip(icon: Icons.paid_rounded, text: "Paid")
                  : const _Chip(
                  icon: Icons.money_off_rounded,
                  text: "No payment",
                  color: _C.muted),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _status("Provider approved", b?.providerApprovalStatus),
              _status("User approved", b?.userApprovalStatus),
              _status("Provider completed", b?.providerTaskCompleteStatus),
              _status("User completed", b?.userTaskCompleteStatus),
            ],
          ),

          // ---------------- user ----------------
          const SizedBox(height: 18),
          const _SectionTitle(icon: Icons.person_rounded, text: "User"),
          const SizedBox(height: 10),
          _InfoGrid(items: [
            _Info(Icons.tag_rounded, "User number", _numStr(b?.userNumber)),
            _Info(Icons.email_rounded, "Email", _txt(b?.userEmail)),
            _Info(Icons.phone_rounded, "Phone", _txt(b?.userPhoneNumber)),
            _Info(Icons.chat_rounded, "WhatsApp",
                _txt(b?.userWhatsappPhoneNumber)),
            _Info(Icons.location_on_rounded, "Address", _txt(b?.userAddress)),
            _Info(Icons.my_location_rounded, "Coordinates",
                _coords(b?.userLatitude, b?.userLongitude)),
            _Info(Icons.notes_rounded, "Description",
                _txt(b?.userBookingDescription)),
          ]),

          // ---------------- provider ----------------
          const SizedBox(height: 18),
          const _SectionTitle(
              icon: Icons.engineering_rounded, text: "Provider"),
          const SizedBox(height: 10),
          _InfoGrid(items: [
            _Info(Icons.tag_rounded, "Provider number",
                _numStr(b?.providerNumber)),
            _Info(Icons.email_rounded, "Email", _txt(b?.providerEmail)),
            _Info(Icons.phone_rounded, "Phone", _txt(b?.providerPhoneNumber)),
            _Info(Icons.chat_rounded, "WhatsApp",
                _txt(b?.providerWhatsappPhoneNumber)),
            _Info(Icons.location_on_rounded, "Address",
                _txt(b?.providerAddress)),
            _Info(Icons.my_location_rounded, "Coordinates",
                _coords(b?.providerLatitude, b?.providerLongitude)),
            _Info(Icons.notes_rounded, "Description",
                _txt(b?.providerBookingDescription)),
          ]),

          // ---------------- service & price ----------------
          const SizedBox(height: 18),
          const _SectionTitle(
              icon: Icons.sell_rounded, text: "Service & pricing"),
          const SizedBox(height: 10),
          _InfoGrid(items: [
            _Info(Icons.handyman_rounded, "Service",
                "${_txt(b?.serviceName)} (ID ${_numStr(b?.serviceId)})"),
            _Info(Icons.badge_rounded, "Provider service ID",
                _numStr(b?.providerServiceId)),
            _Info(Icons.home_rounded, "Domestic price",
                "${_numStr(b?.domesticPrice)}  •  ${_numStr(b?.domesticPriceDiscount)}% off"),
            _Info(Icons.public_rounded, "International price",
                "${_numStr(b?.internationalPrice)}  •  ${_numStr(b?.internationalPriceDiscount)}% off"),
            _Info(Icons.account_balance_wallet_rounded, "Advance payment",
                "${_numStr(b?.advancePaymentAmount)}  (${b?.requiredAdvancePayment == true ? 'required' : 'not required'})"),
            _Info(Icons.star_rounded, "User rating",
                _numStr(b?.ratingValueUser)),
            _Info(Icons.straighten_rounded, "Distance", _numStr(b?.distance)),
            _Info(Icons.schedule_rounded, "Created", _fmtDate(b?.createdAt)),
            _Info(Icons.play_arrow_rounded, "Start date", _fmtDate(b?.startDate)),
            _Info(Icons.stop_rounded, "End date", _fmtDate(b?.endDate)),
          ]),

          // ---------------- actions ----------------
          const SizedBox(height: 20),
          Container(height: 1, color: _C.border),
          const SizedBox(height: 18),
          const _SectionTitle(icon: Icons.bolt_rounded, text: "Actions"),
          const SizedBox(height: 12),

          SizedBox(height: 10,),

          ElevatedButton(onPressed: (){
            try{
              if(b!.bookingFile==null || b!.bookingFile!.isEmpty)
              {
                Toast.Toastmsg("No file available.");
                return;
              }

              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return ViewBookFile(Current_User_JwtToken:Current_User_JwtToken, FilePath: b.bookingFile!,);
              },
              )
              );

            }catch(obj){
              return;
            }

          }, child: Text("View file.")),

          SizedBox(height: 10,),
          ElevatedButton(onPressed: (){
            try{
              if(b!.bookingVideo==null || b!.bookingVideo!.isEmpty){
                Toast.Toastmsg("No video available.");
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return ViewBookVideo(Current_User_JwtToken:Current_User_JwtToken, VideoPath: b.bookingVideo!,);
              },
              )
              );

            }catch(obj){
              return;
            }
          }, child: Text("View video.")),
          SizedBox(height: 10,),
          // -- change provider task complete (inputs ABOVE button) --
          _ActionGroup(
            title: "Change provider task complete",
            hint:
            "Uses the provider number and book ID below to change the provider task complete status.",
            fields: [
              _ReadField(
                  label: "Provider number",
                  value: _numStr(providerNumber),
                  icon: Icons.numbers_rounded),
              _ReadField(
                  label: "Book ID",
                  value: _numStr(bookId),
                  icon: Icons.numbers_rounded),
            ],
            button: Obx(() {
              final String key = 'pro_${bookId?.toInt()}';
              final bool busy = c.busyKey.value.isNotEmpty;
              return _ActionButton(
                label: "Change pro task complete",
                icon: Icons.published_with_changes_rounded,
                loading: c.busyKey.value == key,
                onTap: (busy || bookId == null || providerNumber == null)
                    ? null
                    : () async {
                  try {

                    final bool ok = await _confirm(
                      title: "Change task complete?",
                      message:
                      "Provider #${_numStr(providerNumber)} task complete status for booking #${_numStr(bookId)} will be changed and the provider will be notified.",
                      confirmLabel: "Confirm",
                      icon: Icons.published_with_changes_rounded,
                    );
                    if (!ok) return;

                    await c.changeProTaskComplete(
                      context: context,
                      providerNumber: providerNumber,
                      bookId: bookId,
                    );

                  } catch (obj) {
                    print(obj.toString());
                  }
                },
              );
            }),
          ),

          // -- delete booking (LAST) --
          const SizedBox(height: 14),
          _ActionGroup(
            danger: true,
            title: "Delete booking",
            hint:
            "Permanently removes this booking information. This cannot be undone.",
            fields: [
              _ReadField(
                  label: "Book ID",
                  value: _numStr(bookId),
                  icon: Icons.numbers_rounded),
            ],
            button: Obx(() {
              final String key = 'delb_${bookId?.toInt()}';
              final bool busy = c.busyKey.value.isNotEmpty;
              return _ActionButton(
                danger: true,
                label: "Delete booking data",
                icon: Icons.delete_forever_rounded,
                loading: c.busyKey.value == key,
                onTap: (busy || bookId == null)
                    ? null
                    : () async {
                  try {
                    final bool ok = await _confirm(
                      title: "Delete booking?",
                      message:
                      "Booking #${_numStr(bookId)} will be permanently deleted.",
                      confirmLabel: "Delete",
                      icon: Icons.delete_forever_rounded,
                      danger: true,
                    );
                    if (!ok) return;
                    await c.deleteBookingAction(bookId);
                  } catch (obj) {
                    print(obj.toString());
                  }
                },
              );
            }),
          ),
        ],
      ),
    );


  }
}

// =============================================================================
// PAYMENT CARD — details + photo (normal & full screen) + delete
// Works for orphan payments too (bookingInfo == null).
// =============================================================================
class _PaymentCard extends StatelessWidget {
  final BookProTaskCompGetx c;
  final AdminTaskCompletePaymentModel m;
  const _PaymentCard({required this.c, required this.m});

  @override
  Widget build(BuildContext context) {
    final p = m.paymentInfo;
    final num? payId = p?.taskCompletePaymentId;
    final num? bookId = p?.bookId ?? m.bookingInfo?.bookId;
    final bool bookingMissing = m.bookingInfo == null;
    final String method = _txt(p?.paymentMethod);
    final bool domestic = method.toLowerCase() == 'domestic';
    final String url = c.buildUrl(p?.paymentPhoto);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _glassCard(),
      child: LayoutBuilder(builder: (context, box) {
        final Size screen = MediaQuery.of(context).size;
        final double hLimit =
        (screen.height * 0.4).clamp(200.0, 380.0).toDouble();
        final double side = math.max(0.0, math.min(box.maxWidth, hLimit));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- title ----------------
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _C.mint.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.mint.withOpacity(.35)),
                  ),
                  child: const Icon(Icons.payments_rounded,
                      color: _C.mint, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Payment #${_numStr(payId)}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text("Booking #${_numStr(bookId)}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                          const TextStyle(color: _C.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: domestic ? Icons.home_rounded : Icons.public_rounded,
                  text: method,
                ),
              ],
            ),
            if (bookingMissing) ...[
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: _Chip(
                    icon: Icons.link_off_rounded,
                    text: "Booking no longer exists",
                    color: _C.warn),
              ),
            ],
            const SizedBox(height: 16),

            // ---------------- amount ----------------
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [
                  _C.accent.withOpacity(.18),
                  _C.mint.withOpacity(.06)
                ]),
                border: Border.all(color: _C.mint.withOpacity(.3)),
              ),
              child: Column(
                children: [
                  const Text("Payment amount",
                      style: TextStyle(color: _C.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_numStr(p?.paymentAmount),
                        style: const TextStyle(
                            color: _C.mint,
                            fontSize: 30,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InfoGrid(items: [
              _Info(Icons.tag_rounded, "Payment ID", _numStr(payId)),
              _Info(Icons.numbers_rounded, "Book ID", _numStr(bookId)),
              _Info(Icons.credit_card_rounded, "Method", method),
              _Info(Icons.schedule_rounded, "Paid on", _fmtDate(p?.paymentDate)),
            ]),

            // ---------------- photo ----------------
            const SizedBox(height: 18),
            const _SectionTitle(
                icon: Icons.image_rounded, text: "Payment photo"),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: side,
                height: side,
                child: url.isEmpty
                    ? const _PlaceholderBox(
                    icon: Icons.image_not_supported_rounded,
                    text: "No payment photo")
                    : _PhotoFrame(
                  url: url,
                  onFullscreen: () => _openFullscreen(
                      "Payment #${_numStr(payId)}", url),
                ),
              ),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openFullscreen("Payment #${_numStr(payId)}", url),
                  icon: const Icon(Icons.fullscreen_rounded, size: 20),
                  label: const Text("Full screen"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.text,
                    minimumSize: const Size(0, 42),
                    side: const BorderSide(color: _C.border, width: 1.2),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // ---------------- actions ----------------
            const SizedBox(height: 20),
            Container(height: 1, color: _C.border),
            const SizedBox(height: 18),
            const _SectionTitle(icon: Icons.bolt_rounded, text: "Actions"),
            const SizedBox(height: 12),
            _ActionGroup(
              danger: true,
              title: "Delete task complete payment",
              hint:
              "Permanently removes this provider task complete payment. This cannot be undone.",
              fields: [
                _ReadField(
                    label: "Payment ID",
                    value: _numStr(payId),
                    icon: Icons.numbers_rounded),
              ],
              button: Obx(() {
                final String key = 'delp_${payId?.toInt()}';
                final bool busy = c.busyKey.value.isNotEmpty;
                return _ActionButton(
                  danger: true,
                  label: "Delete payment info",
                  icon: Icons.delete_forever_rounded,
                  loading: c.busyKey.value == key,
                  onTap: (busy || payId == null)
                      ? null
                      : () async {
                    try {
                      final bool ok = await _confirm(
                        title: "Delete payment?",
                        message:
                        "Payment #${_numStr(payId)} will be permanently deleted.",
                        confirmLabel: "Delete",
                        icon: Icons.delete_forever_rounded,
                        danger: true,
                      );
                      if (!ok) return;
                      await c.deletePaymentAction(payId);
                    } catch (obj) {
                      print(obj.toString());
                    }
                  },
                );
              }),
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
void _openFullscreen(String label, String url) {
  try {
    Get.dialog(
      _FullscreenViewer(label: label, url: url),
      barrierColor: Colors.black87,
      useSafeArea: false,
    );
  } catch (obj) {
    print(obj.toString());
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  const _NetImage({required this.url});

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
        child: Icon(Icons.broken_image_outlined, color: _C.muted, size: 36),
      ),
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  final String url;
  final VoidCallback onFullscreen;
  const _PhotoFrame({required this.url, required this.onFullscreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1711),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: _NetImage(url: url),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onFullscreen),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _C.bar.withOpacity(.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border),
                ),
                child: const Icon(Icons.zoom_out_map_rounded,
                    color: _C.mint, size: 16),
              ),
            ),
          ),
        ],
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _C.border),
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
  final String url;
  const _FullscreenViewer({required this.label, required this.url});

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
                          child:
                          const Icon(Icons.close_rounded, color: _C.text),
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
                    child: Center(child: _NetImage(url: url)),
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