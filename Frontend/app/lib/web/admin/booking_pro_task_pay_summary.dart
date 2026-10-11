// =============================================================================
// FilterSummaryBookingTaskCompPayment — analysis & risk review screen.
// Visualization only. Data: FilterSummaryBookingTaskCompPaymentGetx (which wraps
// the OLD BookProTaskCompGetx for server access). No setState anywhere.
// =============================================================================
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust the relative segments to your folder layout (same as the old screen).
import '../../models/AdminTaskCompletePaymentModel.dart';

import '../../models/ProTaskCompPayInfoModel.dart';
import '../../state management/getx/admin/booking_pro_task_pay_summary_getx.dart';
import '../common method/Commmon_Method.dart';

// =============================================================================
// PALETTE — Dark Forest / Emerald Glow
// =============================================================================
class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color bar = Color(0xFF12261C);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF9AA8A0);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color danger = Color(0xFFF87171);
  static const Color warn = Color(0xFFFBBF24);
  static const Color sky = Color(0xFF38BDF8);
  static const Color slate = Color(0xFF64748B);
}

String money(double v) => 'Rs ${compact(v)}';

Color _levelColor(RiskLevel l) {
  switch (l) {
    case RiskLevel.low:
      return _C.mint;
    case RiskLevel.medium:
      return _C.warn;
    case RiskLevel.high:
      return const Color(0xFFFB923C);
    case RiskLevel.critical:
      return _C.danger;
  }
}

String _levelLabel(RiskLevel l) {
  switch (l) {
    case RiskLevel.low:
      return 'Low';
    case RiskLevel.medium:
      return 'Medium';
    case RiskLevel.high:
      return 'High';
    case RiskLevel.critical:
      return 'Critical';
  }
}

String _sortLabel(SortKey k) {
  switch (k) {
    case SortKey.newest:
      return 'Newest';
    case SortKey.oldest:
      return 'Oldest';
    case SortKey.bookIdAsc:
      return 'Book ID ↑';
    case SortKey.bookIdDesc:
      return 'Book ID ↓';
    case SortKey.amountHigh:
      return 'Paid high→low';
    case SortKey.amountLow:
      return 'Paid low→high';
    case SortKey.riskHigh:
      return 'Risk first';
  }
}

String _triLabel(Tri t) {
  switch (t) {
    case Tri.any:
      return 'Any';
    case Tri.yes:
      return 'Yes';
    case Tri.no:
      return 'No';
  }
}

// =============================================================================
// FORMAT HELPERS
// =============================================================================
String compact(double v) {
  final a = v.abs();
  if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
  if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}

String numStr(num? n) {
  if (n == null) return '—';
  return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
}

String txt(String? s) => (s == null || s.trim().isEmpty) ? '—' : s.trim();

String _two(int x) => x.toString().padLeft(2, '0');

String dateStr(DateTime? d) {
  if (d == null) return '—';
  return '${_two(d.day)} ${kMonths[d.month - 1]} ${d.year}, ${_two(d.hour)}:${_two(d.minute)}';
}

String pct(double v) => '${(v * 100).toStringAsFixed(0)}%';

BoxDecoration _glass({double r = 22}) => BoxDecoration(
  color: _C.surface.withOpacity(.9),
  borderRadius: BorderRadius.circular(r),
  border: Border.all(color: _C.border),
  boxShadow: [
    BoxShadow(
        color: Colors.black.withOpacity(.28),
        blurRadius: 22,
        offset: const Offset(0, 9)),
  ],
);

// =============================================================================
// ROOT SCREEN
// =============================================================================
class FilterSummaryBookingTaskCompPayment extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  final int User_Number;

  const FilterSummaryBookingTaskCompPayment({
    super.key,
    required this.User_Role,
    required this.User_JwtToken,
    required this.User_Email,
    required this.User_Number,
  });

  @override
  State<FilterSummaryBookingTaskCompPayment> createState() =>
      _FilterSummaryState();
}

class _FilterSummaryState extends State<FilterSummaryBookingTaskCompPayment> {
  late final FilterSummaryBookingTaskCompPaymentGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    try {
      Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    } catch (obj) {
      print(obj.toString());
    }
    c = Get.put(FilterSummaryBookingTaskCompPaymentGetx(), tag: _tag);
    c.init(jwtToken: widget.User_JwtToken);
  }

  @override
  void dispose() {
    try {
      Get.delete<FilterSummaryBookingTaskCompPaymentGetx>(tag: _tag);
    } catch (obj) {
      print(obj.toString());
    }
    super.dispose();
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bar,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: true,
      leadingWidth: 64,
      leading: Center(
        child: Tooltip(
          message: 'Back',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              try {
                Navigator.of(context).maybePop();
              } catch (obj) {
                print(obj.toString());
              }
            },
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
        'Analysis & Risk Review',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w700),
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
          tooltip: 'Refresh',
          onPressed: c.refreshData,
          icon: const Icon(Icons.refresh_rounded, color: _C.mint),
        )),
        const SizedBox(width: 6),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  Widget _tabBody() {
    switch (c.tab.value) {
      case 1:
        return _BookingsTab(c: c);
      case 2:
        return _IncomeTab(c: c);
      case 3:
        return _RiskTab(c: c);
      default:
        return _OverviewTab(c: c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _appBar(context),
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final double w = box.maxWidth;
              final double hPad = w > 1280 ? (w - 1200) / 2 : (w >= 700 ? 24.0 : 14.0);
              return RefreshIndicator(
                color: _C.accent,
                backgroundColor: _C.surface,
                onRefresh: c.refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Hero(c: c),
                          const SizedBox(height: 18),
                          _TabBar(c: c),
                          const SizedBox(height: 16),
                          Obx(() => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            child: KeyedSubtree(
                              key: ValueKey('tab_${c.tab.value}'),
                              child: _tabBody(),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED PIECES
// =============================================================================
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: _glass(), child: child);
  }
}

class _Title extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Title({required this.icon, required this.text, this.color = _C.mint});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.text, fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color color;
  const _Pill({this.icon, required this.text, this.color = _C.mint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({this.text = 'No data available'});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: _C.muted, size: 44),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.muted, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Skeleton extends StatefulWidget {
  final double height;
  const _Skeleton({this.height = 120});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
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
      opacity: Tween<double>(begin: .35, end: 1)
          .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut)),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
        ),
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
      duration: Duration(milliseconds: 380 + (index * 70).clamp(0, 420)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: ch),
      ),
      child: child,
    );
  }
}

/// Responsive grid: fits as many columns as `minTile` allows.
class _Grid extends StatelessWidget {
  final double minTile;
  final double gap;
  final List<Widget> children;
  const _Grid({required this.minTile, required this.children, this.gap = 12});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, b) {
      final int cols = math.max(1, ((b.maxWidth + gap) / (minTile + gap)).floor());
      final double w = math.max(0.0, (b.maxWidth - gap * (cols - 1)) / cols);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    });
  }
}

class _Warn extends StatelessWidget {
  final String text;
  const _Warn({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.danger.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.danger.withOpacity(.55)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_maybe_rounded, color: _C.danger, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: _C.text, fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _Seg({
    required this.text,
    required this.selected,
    required this.onTap,
    this.color = _C.mint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: selected
              ? LinearGradient(colors: [color, _C.accent.withOpacity(.9)])
              : null,
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: selected ? _C.bg : _C.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? const LinearGradient(colors: [_C.accent, _C.mint])
              : null,
          color: selected ? null : _C.bg.withOpacity(.6),
          border: Border.all(color: selected ? _C.mint : _C.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? _C.bg : _C.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// =============================================================================
// HERO + TABS
// =============================================================================
class _Hero extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  const _Hero({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, v, child) =>
              Transform.scale(scale: .7 + .3 * v, child: child),
          child: Container(
            width: 58,
            height: 58,
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
            child: const Icon(Icons.insights_rounded, color: _C.bg, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Booking & Payment Intelligence',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          'Analyse income, spot fake users and stalled providers, review every booking.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        Obx(() => Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(icon: Icons.event_note_rounded, text: '${c.totalBookings} bookings'),
            _Pill(
                icon: Icons.payments_rounded,
                text: '${c.totalPayments} payments',
                color: _C.accent),
            _Pill(
                icon: Icons.gpp_bad_rounded,
                text:
                '${c.blacklistedUsers + c.blacklistedProviders} flagged',
                color: _C.danger),
          ],
        )),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  const _TabBar({required this.c});

  static const List<(IconData, String)> _items = [
    (Icons.dashboard_rounded, 'Overview'),
    (Icons.manage_search_rounded, 'Bookings'),
    (Icons.account_balance_wallet_rounded, 'Income'),
    (Icons.shield_rounded, 'Risk'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int sel = c.tab.value;
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _C.surface.withOpacity(.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            for (int i = 0; i < _items.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => c.tab.value = i,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      height: 44,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: sel == i
                            ? const LinearGradient(colors: [_C.accent, _C.mint])
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_items[i].$1,
                              size: 18, color: sel == i ? _C.bg : _C.muted),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(_items[i].$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: sel == i ? _C.bg : _C.muted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// =============================================================================
// TAB 0 — OVERVIEW
// =============================================================================
class _OverviewTab extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  const _OverviewTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      try {
        if (c.isLoading.value && c.bookings.isEmpty) {
          return const _Skeleton(height: 260);
        }
        if (c.bookings.isEmpty && c.payments.isEmpty) return const _Empty();

        final flagged = c.blacklistedUsers + c.blacklistedProviders;
        final dom = c.domesticRevenue;
        final intl = c.intlRevenue;
        final oth = c.otherRevenue;
        final total = c.totalRevenue;
        final cats = c.categoryBreakdown().take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (flagged > 0)
              _Warn(
                  text:
                  '${c.blacklistedUsers} user(s) and ${c.blacklistedProviders} provider(s) match blacklist rules. Review them in the Risk tab.'),
            _Grid(minTile: 160, children: [
              _Kpi(Icons.account_balance_wallet_rounded, 'Company revenue',
                  compact(total), _C.mint),
              _Kpi(Icons.event_note_rounded, 'Bookings', '${c.totalBookings}', _C.text),
              _Kpi(Icons.payments_rounded, 'Payments', '${c.totalPayments}', _C.accent),
              _Kpi(Icons.task_alt_rounded, 'Fully completed', pct(c.completionRate), _C.mint),
              _Kpi(Icons.hourglass_bottom_rounded, 'Stalled 7d+', '${c.stalledCount}', _C.warn),
              _Kpi(Icons.money_off_rounded, 'Unpaid bookings', '${c.bookingsWithoutPayment}', _C.sky),
            ]),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (ctx, b) {
              final donut = _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Title(icon: Icons.donut_large_rounded, text: 'Revenue split'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CustomPaint(
                            painter: _DonutPainter(
                                values: [dom, intl, oth],
                                colors: const [_C.mint, _C.sky, _C.slate]),
                            child: Center(
                              child: Text(compact(total),
                                  style: const TextStyle(
                                      color: _C.text,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _LegendRow(color: _C.mint, label: 'Domestic', value: dom, total: total),
                              const SizedBox(height: 10),
                              _LegendRow(color: _C.sky, label: 'International', value: intl, total: total),
                              const SizedBox(height: 10),
                              _LegendRow(color: _C.slate, label: 'Other', value: oth, total: total),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Average payment: ${compact(c.avgPayment)}',
                        style: const TextStyle(color: _C.muted, fontSize: 12.5)),
                  ],
                ),
              );

              final catCard = _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Title(icon: Icons.category_rounded, text: 'Top service categories'),
                    const SizedBox(height: 14),
                    if (cats.isEmpty)
                      const Text('No data available',
                          style: TextStyle(color: _C.muted))
                    else
                      for (final ca in cats) ...[
                        _CatRow(ca: ca, maxTotal: cats.first.total),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              );

              if (b.maxWidth >= 860) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: donut),
                      const SizedBox(width: 16),
                      Expanded(child: catCard),
                    ],
                  ),
                );
              }
              return Column(children: [donut, const SizedBox(height: 16), catCard]);
            }),
          ],
        );
      } catch (obj) {
        print(obj.toString());
        return const _Empty();
      }
    });
  }
}

class _Kpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Kpi(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(14),
      decoration: _glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _C.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  final double total;
  const _LegendRow({required this.color, required this.label, required this.value, required this.total});

  @override
  Widget build(BuildContext context) {
    final double share = total == 0 ? 0 : value / total;
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: _C.muted, fontSize: 12.5)),
        ),
        Text('${compact(value)}  (${pct(share)})',
            style: const TextStyle(
                color: _C.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CatRow extends StatelessWidget {
  final CategoryIncome ca;
  final double maxTotal;
  const _CatRow({required this.ca, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final double frac = maxTotal == 0 ? 0 : ca.total / maxTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(ca.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _C.text, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text(compact(ca.total),
                style: const TextStyle(
                    color: _C.mint, fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: frac),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 8,
              color: _C.mint,
              backgroundColor: _C.bg.withOpacity(.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold<double>(0, (s, v) => s + v);
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = _C.bg;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (total <= 0) return;
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2;
      if (sweep <= 0) continue;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = colors[i];
      canvas.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

// =============================================================================
// TAB 1 — BOOKINGS (search, filter, sort, quick finder, list)
// =============================================================================
class _BookingsTab extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  const _BookingsTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------- search: each field separately ----------------
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Title(icon: Icons.search_rounded, text: 'Search'),
              const SizedBox(height: 12),
              _Grid(minTile: 220, children: [
                _SearchField(hint: 'Book ID', icon: Icons.tag_rounded, ctrl: c.bookIdCont, rx: c.bookIdQ),
                _SearchField(hint: 'User number', icon: Icons.person_rounded, ctrl: c.userCont, rx: c.userQ),
                _SearchField(hint: 'Provider number', icon: Icons.engineering_rounded, ctrl: c.providerCont, rx: c.providerQ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---------------- tri-state filters ----------------
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: _Title(icon: Icons.tune_rounded, text: 'Status filters')),
                  TextButton.icon(
                    onPressed: c.resetFilters,
                    icon: const Icon(Icons.restart_alt_rounded, color: _C.mint, size: 18),
                    label: const Text('Reset', style: TextStyle(color: _C.mint)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Grid(minTile: 230, children: [
                _TriToggle(label: 'User approved', rx: c.userApprovedF),
                _TriToggle(label: 'Provider approved', rx: c.providerApprovedF),
                _TriToggle(label: 'User task complete', rx: c.userDoneF),
                _TriToggle(label: 'Provider task complete', rx: c.providerDoneF),
                _TriToggle(label: 'Payment logged', rx: c.paymentF),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---------------- sorting ----------------
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Title(icon: Icons.sort_rounded, text: 'Sort by'),
              const SizedBox(height: 12),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in SortKey.values)
                    _ChipBtn(
                      label: _sortLabel(k),
                      selected: c.sortKey.value == k,
                      onTap: () => c.sortKey.value = k,
                    ),
                ],
              )),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---------------- quick finder ----------------
        _QuickFinder(c: c),
        const SizedBox(height: 14),

        // ---------------- results ----------------
        Obx(() {
          if (c.isLoading.value && c.bookings.isEmpty) {
            return const _Skeleton(height: 180);
          }
          final list = c.filteredBookings;
          if (c.bookings.isEmpty) return const _Empty();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text('${list.length} result(s)',
                    style: const TextStyle(color: _C.muted, fontSize: 12.5)),
              ),
              if (list.isEmpty)
                const _Empty(text: 'No results match your search or filters.')
              else
                _Grid(
                  minTile: 330,
                  gap: 14,
                  children: [
                    for (int i = 0; i < list.length; i++)
                      _Entrance(
                        key: ValueKey('bk_${list[i].bookId}'),
                        index: i,
                        child: _BookingTile(c: c, r: list[i]),
                      ),
                  ],
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController ctrl;
  final RxString rx;
  const _SearchField({required this.hint, required this.icon, required this.ctrl, required this.rx});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: (v) => rx.value = v.trim(),
      style: const TextStyle(color: _C.text, fontSize: 14.5),
      cursorColor: _C.mint,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
        filled: true,
        fillColor: _C.bg.withOpacity(.6),
        prefixIcon: Icon(icon, color: _C.mint),
        suffixIcon: Obx(() => rx.value.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.close_rounded, color: _C.muted),
          onPressed: () {
            ctrl.clear();
            rx.value = '';
          },
        )),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

class _TriToggle extends StatelessWidget {
  final String label;
  final Rx<Tri> rx;
  const _TriToggle({required this.label, required this.rx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.bg.withOpacity(.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: _C.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Obx(() => Row(
            children: [
              for (final t in Tri.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _Seg(
                      text: _triLabel(t),
                      selected: rx.value == t,
                      onTap: () => rx.value = t,
                      color: t == Tri.no ? _C.warn : _C.mint,
                    ),
                  ),
                ),
            ],
          )),
        ],
      ),
    );
  }
}

class _QuickFinder extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  const _QuickFinder({required this.c});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Title(icon: Icons.bolt_rounded, text: 'Quick finder — last N bookings', color: _C.warn),
          const SizedBox(height: 6),
          const Text(
            'Provider approved and no task-complete payment logged, newest first.',
            style: TextStyle(color: _C.muted, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 8),
          Obx(() => Row(
            children: [
              Text('N = ${c.quickN.value}',
                  style: const TextStyle(
                      color: _C.mint, fontWeight: FontWeight.w800)),
              Expanded(
                child: Slider(
                  value: c.quickN.value.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${c.quickN.value}',
                  activeColor: _C.accent,
                  inactiveColor: _C.border,
                  onChanged: (v) => c.quickN.value = v.round(),
                ),
              ),
            ],
          )),
          Obx(() {
            final list = c.quickFinder;
            if (c.bookings.isEmpty) return const _Empty();
            if (list.isEmpty) {
              return const _Empty(text: 'No bookings match this quick filter.');
            }
            return Column(
              children: [
                for (int i = 0; i < list.length; i++) ...[
                  _BookingTile(c: c, r: list[i], compact: true),
                  const SizedBox(height: 10),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  final BookingRow r;
  final bool compact;
  const _BookingTile({required this.c, required this.r, this.compact = false});

  Widget _status(String label, bool on) => _Pill(
    icon: on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
    text: label,
    color: on ? _C.mint : _C.warn,
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      try {
        final int score = c.userScoreOf(r.userNumber);
        final bool risky = score >= 50;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(r.bookId),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _glass(r: 18).copyWith(
              border: Border.all(
                  color: risky ? _C.danger.withOpacity(.5) : _C.border),
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
                        color: _C.mint.withOpacity(.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_note_rounded, color: _C.mint, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Booking #${numStr(r.bookId)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _C.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          Text(r.serviceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _C.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (r.hasPayment)
                      _Pill(text: money(r.paidTotal), color: _C.accent)
                    else
                      const _Pill(text: 'Unpaid', icon: Icons.money_off_rounded, color: _C.muted),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _status('User approved', r.userApproved),
                    _status('Provider approved', r.providerApproved),
                    _status('User done', r.userDone),
                    _status('Provider done', r.providerDone),
                    if (r.stalled) const _Pill(icon: Icons.hourglass_bottom_rounded, text: 'Stalled 7d+', color: _C.warn),
                    if (r.paidButIncomplete)
                      const _Pill(icon: Icons.report_rounded, text: 'Paid, not closed', color: _C.danger),
                    if (risky)
                      _Pill(icon: Icons.gpp_bad_rounded, text: 'User risk $score', color: _C.danger),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: _C.muted),
                      const SizedBox(width: 4),
                      Text('User ${numStr(r.userNumber)}',
                          style: const TextStyle(color: _C.muted, fontSize: 12)),
                      const SizedBox(width: 14),
                      const Icon(Icons.engineering_rounded, size: 14, color: _C.muted),
                      const SizedBox(width: 4),
                      Text('Provider ${numStr(r.providerNumber)}',
                          style: const TextStyle(color: _C.muted, fontSize: 12)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(dateStr(r.createdAt),
                    style: const TextStyle(color: _C.muted, fontSize: 11.5)),
              ],
            ),
          ),
        );
      } catch (obj) {
        print(obj.toString());
        return const SizedBox.shrink();
      }
    });
  }



  void _openDetail(num id) {
    try {
      Get.bottomSheet(
        _DetailSheet(c: c, bookId: id),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } catch (obj) {
      print(obj.toString());
    }
  }
}

// =============================================================================
// BOOKING DETAIL SHEET (reactive lookup by bookId)
// =============================================================================
class _DetailSheet extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  final num bookId;
  const _DetailSheet({required this.c, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final double maxH = MediaQuery.of(context).size.height * .9;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Obx(() {
        try {
          final r = c.bookingById(bookId);
          if (r == null) {
            return const Padding(
                padding: EdgeInsets.all(24), child: _Empty());
          }
          final score = c.userScoreOf(r.userNumber);
          final info = r.info;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _C.border, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text('Booking #${numStr(r.bookId)}',
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ),
                    Tooltip(
                      message: 'Close',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Get.back(),
                        child: Container(
                          width: 40,
                          height: 40,
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
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Pill(text: 'User approved: ${r.userApproved ? 'yes' : 'no'}', color: r.userApproved ? _C.mint : _C.warn),
                  _Pill(text: 'Provider approved: ${r.providerApproved ? 'yes' : 'no'}', color: r.providerApproved ? _C.mint : _C.warn),
                  _Pill(text: 'User done: ${r.userDone ? 'yes' : 'no'}', color: r.userDone ? _C.mint : _C.warn),
                  _Pill(text: 'Provider done: ${r.providerDone ? 'yes' : 'no'}', color: r.providerDone ? _C.mint : _C.warn),
                  if (score >= 50) _Pill(icon: Icons.gpp_bad_rounded, text: 'User risk $score', color: _C.danger),
                ]),
                const SizedBox(height: 18),
                const _Title(icon: Icons.person_rounded, text: 'User'),
                const SizedBox(height: 10),
                _InfoGrid(items: [
                  _Info(Icons.tag_rounded, 'User number', numStr(info.userNumber)),
                  _Info(Icons.email_rounded, 'Email', txt(info.userEmail)),
                  _Info(Icons.phone_rounded, 'Phone', txt(info.userPhoneNumber)),
                  _Info(Icons.chat_rounded, 'WhatsApp', txt(info.userWhatsappPhoneNumber)),
                  _Info(Icons.location_on_rounded, 'Address', txt(info.userAddress)),
                  _Info(Icons.notes_rounded, 'Description', txt(info.userBookingDescription)),
                ]),
                const SizedBox(height: 18),
                const _Title(icon: Icons.engineering_rounded, text: 'Provider'),
                const SizedBox(height: 10),
                _InfoGrid(items: [
                  _Info(Icons.tag_rounded, 'Provider number', numStr(info.providerNumber)),
                  _Info(Icons.email_rounded, 'Email', txt(info.providerEmail)),
                  _Info(Icons.phone_rounded, 'Phone', txt(info.providerPhoneNumber)),
                  _Info(Icons.chat_rounded, 'WhatsApp', txt(info.providerWhatsappPhoneNumber)),
                  _Info(Icons.location_on_rounded, 'Address', txt(info.providerAddress)),
                  _Info(Icons.notes_rounded, 'Description', txt(info.providerBookingDescription)),
                ]),
                const SizedBox(height: 18),
                const _Title(icon: Icons.sell_rounded, text: 'Service & pricing'),
                const SizedBox(height: 10),
                _InfoGrid(items: [
                  _Info(Icons.handyman_rounded, 'Service', '${txt(info.serviceName)} (ID ${numStr(info.serviceId)})'),
                  _Info(Icons.home_rounded, 'Domestic price', '${numStr(info.domesticPrice)}  •  ${numStr(info.domesticPriceDiscount)}% off'),
                  _Info(Icons.public_rounded, 'International price', '${numStr(info.internationalPrice)}  •  ${numStr(info.internationalPriceDiscount)}% off'),
                  _Info(Icons.account_balance_wallet_rounded, 'Advance', '${numStr(info.advancePaymentAmount)}  (${info.requiredAdvancePayment == true ? 'required' : 'not required'})'),
                  _Info(Icons.straighten_rounded, 'Distance', numStr(info.distance)),
                  _Info(Icons.schedule_rounded, 'Created', dateStr(r.createdAt)),
                ]),
                const SizedBox(height: 18),
                _Title(
                    icon: Icons.receipt_long_rounded,
                    text: 'Payments (${r.payments.length})'),
                const SizedBox(height: 10),
                if (r.payments.isEmpty)
                  const _Empty(text: 'No payment logged for this booking')
                else
                  for (final p in r.payments) ...[
                    _PaymentDetail(c: c, p: p),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        } catch (obj) {
          print(obj.toString());
          return const _Empty();
        }
      }),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  final ProTaskCompPayInfoModel p;
  const _PaymentDetail({required this.c, required this.p});

  @override
  Widget build(BuildContext context) {
    final String url = c.src.buildUrl(p.paymentPhoto);
    final bool domestic = (p.paymentMethod ?? '').toLowerCase() == 'domestic';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.bg.withOpacity(.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Payment #${numStr(p.taskCompletePaymentId)}',
                    style: const TextStyle(
                        color: _C.text, fontWeight: FontWeight.w800)),
              ),
              _Pill(
                icon: domestic ? Icons.home_rounded : Icons.public_rounded,
                text: txt(p.paymentMethod),
                color: domestic ? _C.mint : _C.sky,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(compact(((p.paymentAmount ?? 0)).toDouble()),
              style: const TextStyle(
                  color: _C.mint, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(txt(p.paymentDate),
              style: const TextStyle(color: _C.muted, fontSize: 12)),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, prog) => prog == null
                      ? child
                      : const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: _C.accent),
                    ),
                  ),
                  errorBuilder: (ctx, e, st) => const SizedBox(
                    height: 80,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: _C.muted, size: 34),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
    return _Grid(
      minTile: 220,
      gap: 10,
      children: [
        for (final i in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          style: const TextStyle(color: _C.muted, fontSize: 11.5)),
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
      ],
    );
  }
}

// =============================================================================
// TAB 2 — INCOME (weekly / monthly / yearly, domestic vs international)
// =============================================================================
class _IncomeTab extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  const _IncomeTab({required this.c});

  static const List<(IncomePeriod, String)> _periods = [
    (IncomePeriod.weekly, 'Weekly'),
    (IncomePeriod.monthly, 'Monthly'),
    (IncomePeriod.yearly, 'Yearly'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Title(icon: Icons.calendar_month_rounded, text: 'Income period'),
              const SizedBox(height: 12),
              Obx(() => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _C.bg.withOpacity(.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  children: [
                    for (final p in _periods)
                      Expanded(
                        child: _Seg(
                          text: p.$2,
                          selected: c.period.value == p.$1,
                          onTap: () => c.period.value = p.$1,
                        ),
                      ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          if (c.payments.isEmpty) return const _Empty();
          final dom = c.domesticRevenue;
          final intl = c.intlRevenue;
          final oth = c.otherRevenue;
          return _Grid(minTile: 180, children: [
            _Kpi(Icons.home_rounded, 'Domestic', compact(dom), _C.mint),
            _Kpi(Icons.public_rounded, 'International', compact(intl), _C.sky),
            _Kpi(Icons.more_horiz_rounded, 'Other method', compact(oth), _C.slate),
            _Kpi(Icons.account_balance_rounded, 'Total income', compact(c.totalRevenue), _C.accent),
          ]);
        }),
        const SizedBox(height: 14),
        _GlassCard(
          child: Obx(() {
            if (c.payments.isEmpty) return const _Empty();
            final buckets = c.incomeBuckets();
            final double maxT = buckets.fold<double>(0.0, (m, b) => b.total > m ? b.total : m);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: _Title(icon: Icons.bar_chart_rounded, text: 'Income trend')),
                    _Pill(icon: Icons.home_rounded, text: 'Domestic', color: _C.mint),
                    const SizedBox(width: 6),
                    _Pill(icon: Icons.public_rounded, text: 'Intl', color: _C.sky),
                  ],
                ),
                const SizedBox(height: 16),
                _BarChart(buckets: buckets, maxTotal: maxT, key: ValueKey('chart_${c.period.value}')),
              ],
            );
          }),
        ),
        const SizedBox(height: 14),
        _GlassCard(
          child: Obx(() {
            if (c.payments.isEmpty) return const _Empty();
            final cats = c.categoryBreakdown();
            if (cats.isEmpty) return const _Empty();
            final maxT = cats.first.total;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Title(icon: Icons.category_rounded, text: 'Income by service category'),
                const SizedBox(height: 14),
                for (final ca in cats) ...[
                  _CategoryDetail(ca: ca, maxTotal: maxT),
                  const SizedBox(height: 14),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<IncomeBucket> buckets;
  final double maxTotal;
  const _BarChart({super.key, required this.buckets, required this.maxTotal});

  static const double _barH = 170;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty || maxTotal <= 0) return const _Empty();
    return SizedBox(
      height: _barH + 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: buckets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final b = buckets[i];
          final double hD = b.domestic / maxTotal * _barH;
          final double hI = b.international / maxTotal * _barH;
          final double hO = b.other / maxTotal * _barH;
          return _Entrance(
            index: i,
            child: SizedBox(
              width: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(compact(b.total),
                      maxLines: 1,
                      style: const TextStyle(color: _C.muted, fontSize: 10.5)),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => SizedBox(
                      height: _barH,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _seg(hO * v, _C.slate, top: true),
                          _seg(hI * v, _C.sky, top: hO == 0),
                          _seg(hD * v, _C.mint, top: hO == 0 && hI == 0, bottom: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(b.label,
                      maxLines: 1,
                      style: const TextStyle(color: _C.muted, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _seg(double h, Color c, {bool top = false, bool bottom = false}) {
    if (h <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      height: h,
      decoration: BoxDecoration(
        color: c.withOpacity(.85),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(top ? 8 : 0),
          topRight: Radius.circular(top ? 8 : 0),
          bottomLeft: Radius.circular(bottom ? 8 : 0),
          bottomRight: Radius.circular(bottom ? 8 : 0),
        ),
      ),
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  final CategoryIncome ca;
  final double maxTotal;
  const _CategoryDetail({required this.ca, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final double frac = maxTotal == 0 ? 0 : ca.total / maxTotal;
    final double dShare = ca.total == 0 ? 0 : ca.domestic / ca.total;
    final double iShare = ca.total == 0 ? 0 : ca.international / ca.total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.bg.withOpacity(.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ca.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text, fontWeight: FontWeight.w700)),
              ),
              Text('${ca.count} pay  •  ${compact(ca.total)}',
                  style: const TextStyle(color: _C.mint, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: frac),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      flex: math.max(1, (dShare * v * 1000).round()),
                      child: Container(color: _C.mint),
                    ),
                    Expanded(
                      flex: math.max(1, (iShare * v * 1000).round()),
                      child: Container(color: _C.sky),
                    ),
                    Expanded(
                      flex: math.max(1, ((1 - dShare - iShare) * v * 1000).round()),
                      child: Container(color: _C.slate),
                    ),
                    Expanded(
                      flex: math.max(1, ((1 - v) * 1000).round()),
                      child: Container(color: _C.bg),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              'Domestic ${compact(ca.domestic)}  •  International ${compact(ca.international)}  •  Other ${compact(ca.other)}',
              style: const TextStyle(color: _C.muted, fontSize: 11.5)),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 3 — RISK (fake users / blacklist, providers not finishing)
// =============================================================================
class _RiskTab extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  const _RiskTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Title(icon: Icons.shield_rounded, text: 'Who to review'),
              const SizedBox(height: 12),
              Obx(() => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _C.bg.withOpacity(.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Seg(
                        text: 'Users (fake check)',
                        selected: c.riskKind.value == PartyKind.user,
                        onTap: () => c.riskKind.value = PartyKind.user,
                      ),
                    ),
                    Expanded(
                      child: _Seg(
                        text: 'Providers (not finishing)',
                        selected: c.riskKind.value == PartyKind.provider,
                        onTap: () => c.riskKind.value = PartyKind.provider,
                        color: _C.warn,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              _SearchField(
                  hint: 'Search by number',
                  icon: Icons.search_rounded,
                  ctrl: c.riskCont,
                  rx: c.riskQ),
              const SizedBox(height: 12),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipBtn(
                    label: 'All levels',
                    selected: c.riskLevelF.value == null,
                    onTap: () => c.riskLevelF.value = null,
                  ),
                  for (final l in RiskLevel.values)
                    _ChipBtn(
                      label: _levelLabel(l),
                      selected: c.riskLevelF.value == l,
                      onTap: () => c.riskLevelF.value = l,
                    ),
                ],
              )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          if (c.bookings.isEmpty) return const _Empty();
          final isUser = c.riskKind.value == PartyKind.user;
          final flagged = isUser ? c.blacklistedUsers : c.blacklistedProviders;
          final high = isUser ? c.highRiskUsers : c.highRiskProviders;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (flagged > 0)
                _Warn(
                    text:
                    '$flagged ${isUser ? 'user' : 'provider'}(s) are blacklist candidates. Review each one before taking any action outside this screen.'),
              _Grid(minTile: 180, children: [
                _Kpi(Icons.people_alt_rounded, isUser ? 'Users checked' : 'Providers checked',
                    '${isUser ? c.userRisks.length : c.providerRisks.length}', _C.text),
                _Kpi(Icons.gpp_bad_rounded, 'Blacklist candidates', '$flagged', _C.danger),
                _Kpi(Icons.warning_amber_rounded, 'High / critical', '$high', _C.warn),
              ]),
              const SizedBox(height: 14),
              _RiskList(c: c),
            ],
          );
        }),
      ],
    );
  }

}

class _RiskList extends StatelessWidget {
  final FilterSummaryBookingTaskCompPaymentGetx c;
  const _RiskList({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = c.filteredRisks;
      if (list.isEmpty) return const _Empty(text: 'No data available');
      return _Grid(
        minTile: 340,
        gap: 14,
        children: [
          for (int i = 0; i < list.length; i++)
            _Entrance(
              key: ValueKey('rk_${list[i].kind.name}_${list[i].number}'),
              index: i,
              child: _RiskCard(profile: list[i]),
            ),
        ],
      );
    });
  }
}

class _RiskCard extends StatelessWidget {
  final RiskProfile profile;
  const _RiskCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    try {
      final isUser = profile.kind == PartyKind.user;
      final lc = _levelColor(profile.level);
      final bool bl = profile.blacklisted;
      return _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: lc.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lc.withOpacity(.4)),
                  ),
                  child: Icon(
                      isUser ? Icons.person_rounded : Icons.engineering_rounded,
                      color: lc),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${isUser ? 'User' : 'Provider'} #${numStr(profile.number)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Text(txt(profile.email ?? profile.phone),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _C.muted, fontSize: 12)),
                    ],
                  ),
                ),
                _Pill(text: _levelLabel(profile.level), color: lc),
              ],
            ),
            if (bl) ...[
              const SizedBox(height: 10),
              const _Pill(
                  icon: Icons.block_rounded,
                  text: 'Blacklist candidate',
                  color: _C.danger),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Risk score',
                    style: const TextStyle(color: _C.muted, fontSize: 12)),
                const Spacer(),
                Text('${profile.score}/100',
                    style: TextStyle(
                        color: lc, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: profile.score / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  color: lc,
                  backgroundColor: _C.bg.withOpacity(.7),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(icon: Icons.event_note_rounded, text: '${profile.total} bookings'),
                _Pill(icon: Icons.hourglass_bottom_rounded, text: '${profile.stalledCount} stalled', color: _C.warn),
                _Pill(icon: Icons.payments_rounded, text: compact(profile.paidTotal), color: _C.accent),
              ],
            ),
            const SizedBox(height: 14),
            if (profile.flags.isEmpty)
              const Text('No risk signals found.',
                  style: TextStyle(color: _C.muted, fontSize: 12.5))
            else
              for (final f in profile.flags) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (f.severe ? _C.danger : _C.warn).withOpacity(.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (f.severe ? _C.danger : _C.warn).withOpacity(.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(f.severe ? Icons.report_rounded : Icons.flag_rounded,
                          size: 18, color: f.severe ? _C.danger : _C.warn),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.title,
                                style: const TextStyle(
                                    color: _C.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(f.detail,
                                style: const TextStyle(
                                    color: _C.muted, fontSize: 12, height: 1.35)),
                          ],
                        ),
                      ),
                      Text('+${f.points}',
                          style: TextStyle(
                              color: f.severe ? _C.danger : _C.warn,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      );
    } catch (obj) {
      print(obj.toString());
      return const _Empty();
    }
  }
}

// =============================================================================
// AMBIENT BACKGROUND — blurred emerald blobs, wrapped in IgnorePointer
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
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50, tileMode: TileMode.decal),
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
            colors: [Colors.white.withOpacity(.06), Colors.white.withOpacity(.01)],
          ),
          border: Border.all(color: Colors.white.withOpacity(.06)),
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
            _blob(left: -w * .18, top: -h * .12, size: base * .70, color: _C.accent, opacity: .14),
            _blob(right: -w * .22, top: h * .28, size: base * .60, color: _C.mint, opacity: .10),
            _blob(left: w * .08, bottom: -h * .22, size: base * .75, color: _C.accent, opacity: .10),
            _bubble(right: w * .10, top: h * .06, size: (small * .16).clamp(40.0, 150.0).toDouble()),
            _bubble(left: w * .06, top: h * .42, size: (small * .10).clamp(28.0, 100.0).toDouble()),
            _bubble(right: w * .18, bottom: h * .10, size: (small * .20).clamp(50.0, 190.0).toDouble()),
          ],
        );
      }),
    );
  }
}