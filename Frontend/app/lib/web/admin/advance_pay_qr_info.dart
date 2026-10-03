import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Adjust the relative import segment counts / folder names to your project.
import '../../constant/variable.dart';
import '../../state management/getx/admin/advance_payment_qr_getx.dart';
import '../authentication/Error_page.dart';
import '../common method/Commmon_Method.dart';

// =============================================================================
// PALETTE
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
// SCREEN
// =============================================================================
class AdvancePayQrInfo extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  final int User_Number;
  const AdvancePayQrInfo({
    super.key,
    required this.User_Role,
    required this.User_JwtToken,
    required this.User_Email,
    required this.User_Number,
  });

  @override
  State<AdvancePayQrInfo> createState() => _AdvancePayQrInfoState();
}

class _AdvancePayQrInfoState extends State<AdvancePayQrInfo> {
  late final AdvancePaymentQrGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken);
    c = Get.put(AdvancePaymentQrGetx(), tag: _tag);
    c.init(jwtToken: widget.User_JwtToken);
  }

  @override
  void dispose() {
    Get.delete<AdvancePaymentQrGetx>(tag: _tag);
    super.dispose();
  }

  // Original session check — logic unchanged.
  Future<void> Admin_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await AdminJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ErrorPage()),
            (route) => false,
      );
      Toast.Toastmsg("Session End.Relogin please.");
      return;
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
                  border: Border.all(color: _C.text.withOpacity(.55), width: 1.2),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _C.text, size: 18),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Advance Pay QR Info",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
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
          const Positioned.fill(child: IgnorePointer(child: _AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth;
                final double hPad =
                w > 1160 ? (w - 1100) / 2 : (w >= 700 ? 24.0 : 14.0);

                return RefreshIndicator(
                  color: _C.accent,
                  backgroundColor: _C.surface,
                  onRefresh: c.loadAll,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 0),
                        sliver: SliverToBoxAdapter(child: _Header(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverToBoxAdapter(child: _TabSwitch(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverToBoxAdapter(child: _ToolsPanel(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 8),
                        sliver: SliverToBoxAdapter(child: _ResultsHeader(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 40),
                        sliver: SliverToBoxAdapter(child: _Results(c: c)),
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
// CONFIRM DIALOG
// =============================================================================
Future<bool> _confirmDelete(String title, String message) async {
  final bool? r = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _C.border),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _C.danger),
          const SizedBox(width: 10),
          Flexible(
            child: Text(title,
                style: const TextStyle(
                    color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
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
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Delete"),
        ),
      ],
    ),
  );
  return r == true;
}

// =============================================================================
// SHARED SMALL PIECES
// =============================================================================
BoxDecoration _glassCard({double radius = 20}) => BoxDecoration(
  color: _C.surface.withOpacity(.86),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _C.border),
  boxShadow: [
    BoxShadow(
        color: Colors.black.withOpacity(.28),
        blurRadius: 18,
        offset: const Offset(0, 8)),
  ],
);

InputDecoration _input(String hint, IconData icon, {Widget? suffix}) {
  OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: col, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _C.muted, fontSize: 14),
    prefixIcon: Icon(icon, color: _C.mint, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: _C.bar,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: b(_C.border),
    focusedBorder: b(_C.accent, 1.5),
    border: b(_C.border),
  );
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
      duration: Duration(milliseconds: 380 + (index * 70).clamp(0, 420)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 22), child: ch),
      ),
      child: child,
    );
  }
}

// =============================================================================
// HEADER — title + live counters
// =============================================================================
class _Header extends StatelessWidget {
  final AdvancePaymentQrGetx c;
  const _Header({required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Advance Payments",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: _C.text, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text("Review payment proofs and provider QR codes.",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _C.muted, fontSize: 13.5, height: 1.4)),
        const SizedBox(height: 12),
        Obx(() {
          if (c.isLoading.value) return const SizedBox.shrink();
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.receipt_long_rounded,
                text:
                "${c.AdvancePaymentInfoList.length} payment proof${c.AdvancePaymentInfoList.length == 1 ? '' : 's'}",
                color: _C.accent,
              ),
              _Chip(
                icon: Icons.qr_code_2_rounded,
                text:
                "${c.AdvancePaymentQrInfoList.length} QR code${c.AdvancePaymentQrInfoList.length == 1 ? '' : 's'}",
              ),
            ],
          );
        }),
      ],
    );
  }
}

// =============================================================================
// TAB SWITCH
// =============================================================================
class _TabSwitch extends StatelessWidget {
  final AdvancePaymentQrGetx c;
  const _TabSwitch({required this.c});

  Widget _btn(int i, IconData icon, String label) {
    final bool on = c.tab.value == i;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => c.tab.value = i,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            color: on ? _C.accent.withOpacity(.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: on ? _C.accent.withOpacity(.6) : Colors.transparent),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: on ? _C.accent : _C.muted),
                const SizedBox(width: 8),
                Text(label,
                    maxLines: 1,
                    style: TextStyle(
                        color: on ? _C.text : _C.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: _glassCard(radius: 18),
      child: Obx(() => Row(
        children: [
          _btn(0, Icons.receipt_long_rounded, "Payment Proofs"),
          const SizedBox(width: 6),
          _btn(1, Icons.qr_code_2_rounded, "Provider QR"),
        ],
      )),
    );
  }
}

// =============================================================================
// TOOLS PANEL — search + delete by id (both follow the active tab)
// =============================================================================
class _ToolsPanel extends StatelessWidget {
  final AdvancePaymentQrGetx c;
  const _ToolsPanel({required this.c});

  Future<void> _submitPayment() async {
    final int? id = int.tryParse(c.PaymentIdCont.text.trim());
    if (id == null) {
      await c.deletePaymentFromInput(); // shows the "required" toast
      return;
    }
    if (await _confirmDelete("Delete payment proof?",
        "Payment ID $id will be permanently deleted. This can't be undone.")) {
      await c.deletePaymentFromInput();
    }
  }

  Future<void> _submitQr() async {
    final int? id = int.tryParse(c.QRIdCont.text.trim());
    if (id == null) {
      await c.deleteQrFromInput();
      return;
    }
    if (await _confirmDelete("Delete QR photo?",
        "QR ID $id will be permanently deleted. This can't be undone.")) {
      await c.deleteQrFromInput();
    }
  }

  Widget _sectionTitle(IconData icon, String title, String sub, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(.35)),
          ),
          child: Icon(icon, color: color, size: 19),
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
                      color: _C.text, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _C.muted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchSection() {
    return Obx(() {
      final bool pay = c.tab.value == 0;
      final bool has = (pay ? c.paymentQuery.value : c.qrQuery.value).isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            Icons.search_rounded,
            "Search",
            pay ? "By payment id or book id" : "By QR id or provider number",
            _C.mint,
          ),
          const SizedBox(height: 14),
          TextField(
            key: ValueKey('search_$pay'),
            controller: pay ? c.paymentSearchCont : c.qrSearchCont,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: _C.text, fontSize: 15),
            cursorColor: _C.accent,
            onChanged: (v) =>
            pay ? c.paymentQuery.value = v : c.qrQuery.value = v,
            decoration: _input(
              pay ? "Payment id or book id" : "QR id or provider number",
              Icons.search_rounded,
              suffix: has
                  ? IconButton(
                tooltip: "Clear",
                onPressed: pay ? c.clearPaymentSearch : c.clearQrSearch,
                icon: const Icon(Icons.close_rounded,
                    color: _C.muted, size: 20),
              )
                  : null,
            ),
          ),
        ],
      );
    });
  }

  Widget _deleteSection() {
    return Obx(() {
      final bool pay = c.tab.value == 0;
      final bool busy =
      pay ? c.deletingPaymentIds.isNotEmpty : c.deletingQrIds.isNotEmpty;

      final field = TextField(
        key: ValueKey('del_$pay'),
        controller: pay ? c.PaymentIdCont : c.QRIdCont,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: _C.text, fontSize: 15),
        cursorColor: _C.accent,
        onSubmitted: (_) => pay ? _submitPayment() : _submitQr(),
        decoration: _input(
          pay ? "Enter the payment id" : "Enter the QR id",
          Icons.numbers_rounded,
        ),
      );

      final button = ElevatedButton.icon(
        onPressed: busy ? null : (pay ? _submitPayment : _submitQr),
        icon: busy
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.delete_outline_rounded, size: 19),
        label: Text(pay ? "Delete payment" : "Delete QR"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          disabledBackgroundColor: const Color(0xFFEF4444).withOpacity(.4),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            Icons.delete_sweep_rounded,
            pay ? "Delete by Payment ID" : "Delete by QR ID",
            "Permanently removes the record.",
            _C.danger,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, box) {
            if (box.maxWidth >= 430) {
              return Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 12),
                  button,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [field, const SizedBox(height: 12), button],
            );
          }),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassCard(),
      child: LayoutBuilder(builder: (context, box) {
        if (box.maxWidth >= 820) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _searchSection()),
              Container(
                width: 1,
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: _C.border,
              ),
              Expanded(child: _deleteSection()),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _searchSection(),
            Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 16),
                color: _C.border),
            _deleteSection(),
          ],
        );
      }),
    );
  }
}

// =============================================================================
// RESULTS HEADER
// =============================================================================
class _ResultsHeader extends StatelessWidget {
  final AdvancePaymentQrGetx c;
  const _ResultsHeader({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool pay = c.tab.value == 0;
      final int total =
      pay ? c.AdvancePaymentInfoList.length : c.AdvancePaymentQrInfoList.length;
      final int shown = pay ? c.filteredPayments.length : c.filteredQrs.length;
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(pay ? "Payment Proofs" : "Provider QR Codes",
              style: const TextStyle(
                  color: _C.text, fontSize: 20, fontWeight: FontWeight.w800)),
          if (!c.isLoading.value)
            _Chip(
              icon: Icons.layers_rounded,
              text: shown == total ? "$total total" : "$shown of $total",
            ),
        ],
      );
    });
  }
}

// =============================================================================
// RESULTS — responsive card grid (Wrap, so card height is always natural)
// =============================================================================
class _Results extends StatelessWidget {
  final AdvancePaymentQrGetx c;
  const _Results({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool pay = c.tab.value == 0;

      Widget body;
      if (c.isLoading.value) {
        body = _CardGrid(
          key: const ValueKey('loading'),
          children: List.generate(3, (_) => const _SkeletonCard()),
        );
      } else if (pay) {
        final list = c.filteredPayments;
        final String q = c.paymentQuery.value.trim();
        if (list.isEmpty) {
          body = _EmptyState(
            key: const ValueKey('empty_pay'),
            searching: q.isNotEmpty,
            query: q,
            noun: "payment proofs",
            hint: "No payment has a payment id or book id containing",
            onClear: c.clearPaymentSearch,
            onRefresh: c.loadAll,
          );
        } else {
          body = _CardGrid(
            key: const ValueKey('grid_pay'),
            children: [
              for (int i = 0; i < list.length; i++)
                _Entrance(
                  key: ValueKey('pay_${c.paymentIdOf(list[i])}'),
                  index: i,
                  child: _MediaCard(
                    icon: Icons.receipt_long_rounded,
                    title: "Payment ID #${c.paymentIdOf(list[i])}",
                    url: c.buildUrl(list[i].paymentPhoto),
                    aspect: 4 / 3,
                    chips: [
                      _Chip(
                          icon: Icons.tag_rounded,
                          text: "ID ${c.paymentIdOf(list[i])}",
                          color: _C.accent),
                      _Chip(
                          icon: Icons.book_online_rounded,
                          text: "Book ID ${c.bookIdOf(list[i])}"),
                    ],
                    isBusy: () =>
                        c.deletingPaymentIds.contains(c.paymentIdOf(list[i])),
                    onDelete: () async {
                      final int id = c.paymentIdOf(list[i]);
                      if (await _confirmDelete("Delete payment proof?",
                          "Payment ID $id will be permanently deleted. This can't be undone.")) {
                        await c.deletePaymentById(id);
                      }
                    },
                  ),
                ),
            ],
          );
        }
      } else {
        final list = c.filteredQrs;
        final String q = c.qrQuery.value.trim();
        if (list.isEmpty) {
          body = _EmptyState(
            key: const ValueKey('empty_qr'),
            searching: q.isNotEmpty,
            query: q,
            noun: "QR codes",
            hint: "No QR has a QR id or provider number containing",
            onClear: c.clearQrSearch,
            onRefresh: c.loadAll,
          );
        } else {
          body = _CardGrid(
            key: const ValueKey('grid_qr'),
            children: [
              for (int i = 0; i < list.length; i++)
                _Entrance(
                  key: ValueKey('qr_${c.qrIdOf(list[i])}'),
                  index: i,
                  child: _MediaCard(
                    icon: Icons.qr_code_2_rounded,
                    title: "QR ID #${c.qrIdOf(list[i])}",
                    url: c.buildUrl(list[i].qrPhoto),
                    aspect: 1,
                    chips: [
                      _Chip(
                          icon: Icons.tag_rounded,
                          text: "ID ${c.qrIdOf(list[i])}",
                          color: _C.accent),
                      _Chip(
                          icon: Icons.phone_rounded,
                          text: "Provider ID ${c.providerNumberOf(list[i])}"),
                      if ((list[i].providerEmail ?? '').toString().isNotEmpty)
                        _Chip(
                            icon: Icons.mail_outline_rounded,
                            text: list[i].providerEmail.toString()),
                    ],
                    isBusy: () =>
                        c.deletingQrIds.contains(c.qrIdOf(list[i])),
                    onDelete: () async {
                      final int id = c.qrIdOf(list[i]);
                      if (await _confirmDelete("Delete QR photo?",
                          "QR ID $id will be permanently deleted. This can't be undone.")) {
                        await c.deleteQrById(id);
                      }
                    },
                  ),
                ),
            ],
          );
        }
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: body,
      );
    });
  }
}

class _CardGrid extends StatelessWidget {
  final List<Widget> children;
  const _CardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final double w = box.maxWidth;
      if (!w.isFinite || w <= 0) return const SizedBox.shrink();

      const double gap = 16;
      final int cols = w >= 1000 ? 3 : (w >= 620 ? 2 : 1);
      final double cardW = math.max((w - gap * (cols - 1)) / cols, 1);

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final ch in children) SizedBox(width: cardW, child: ch),
        ],
      );
    });
  }
}

// =============================================================================
// MEDIA CARD
// =============================================================================
class _MediaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;
  final double aspect;
  final List<Widget> chips;
  final bool Function() isBusy;
  final VoidCallback onDelete;
  const _MediaCard({
    required this.icon,
    required this.title,
    required this.url,
    required this.aspect,
    required this.chips,
    required this.isBusy,
    required this.onDelete,
  });

  void _openFullscreen() {
    if (url.isEmpty) return;
    Get.dialog(
      _FullscreenViewer(label: title, url: url),
      barrierColor: Colors.black87,
      useSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _glassCard(radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            color: _C.bar,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.accent.withOpacity(.35)),
                  ),
                  child: Icon(icon, color: _C.accent, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _C.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final bool busy = isBusy();
                  return Tooltip(
                    message: "Delete",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: busy ? null : onDelete,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _C.danger.withOpacity(.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.danger.withOpacity(.4)),
                        ),
                        child: busy
                            ? const Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _C.danger),
                        )
                            : const Icon(Icons.delete_outline_rounded,
                            color: _C.danger, size: 20),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Container(height: 1, color: _C.border),

          // image
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onTap: _openFullscreen,
              child: AspectRatio(
                aspectRatio: aspect,
                child: _ImageBox(url: url, fullscreen: false),
              ),
            ),
          ),

          // chips + view button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: chips),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: url.isEmpty ? null : _openFullscreen,
                  icon: const Icon(Icons.fullscreen_rounded, size: 20),
                  label: const Text("View full screen"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.text,
                    disabledForegroundColor: _C.muted.withOpacity(.5),
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: _C.border, width: 1.2),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

class _ImageBox extends StatelessWidget {
  final String url;
  final bool fullscreen;
  const _ImageBox({required this.url, required this.fullscreen});

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (url.isEmpty) {
      inner = const _PaneMessage(
          icon: Icons.link_off_rounded, text: "No photo path returned.");
    } else {
      final img = Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, p) => p == null
            ? child
            : const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.accent),
          ),
        ),
        errorBuilder: (context, e, st) => const _PaneMessage(
            icon: Icons.broken_image_outlined, text: "Image unavailable"),
      );
      inner = fullscreen
          ? InteractiveViewer(minScale: .8, maxScale: 5, child: Center(child: img))
          : Center(child: img);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1711),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );
  }
}

class _PaneMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PaneMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _C.muted, size: 32),
              const SizedBox(height: 10),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _C.muted, fontSize: 12.5)),
            ],
          ),
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
                            border: Border.all(color: _C.text.withOpacity(.55)),
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
                  child: _ImageBox(url: url, fullscreen: true),
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
// EMPTY + SKELETON
// =============================================================================
class _EmptyState extends StatelessWidget {
  final bool searching;
  final String query;
  final String noun;
  final String hint;
  final VoidCallback onClear;
  final Future<void> Function() onRefresh;
  const _EmptyState({
    super.key,
    required this.searching,
    required this.query,
    required this.noun,
    required this.hint,
    required this.onClear,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.accent.withOpacity(.08),
                border: Border.all(color: _C.accent.withOpacity(.25)),
              ),
              child: Icon(
                  searching ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                  color: _C.accent,
                  size: 40),
            ),
            const SizedBox(height: 18),
            Text(searching ? "No match found" : "No $noun yet",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.text, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              searching
                  ? "$hint \"$query\"."
                  : "Uploaded $noun will appear here.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.muted, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: searching ? onClear : onRefresh,
              icon: Icon(searching ? Icons.close_rounded : Icons.refresh_rounded,
                  size: 19),
              label: Text(searching ? "Clear search" : "Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.accent,
                foregroundColor: Colors.black,
                elevation: 0,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Widget _bar(double h) => Container(
    height: h,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.07),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .45, end: 1)
          .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _glassCard(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.07),
                    borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(width: 12),
              Expanded(child: _bar(16)),
            ]),
            const SizedBox(height: 16),
            AspectRatio(aspectRatio: 4 / 3, child: _bar(double.infinity)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// AMBIENT BACKGROUND — blurred emerald/mint blobs slowly drifting + glass
// bubbles. Wrapped in IgnorePointer by the caller, so it can never block taps.
// The blurred blobs sit in RepaintBoundaries, so the drift only moves cached
// layers and stays cheap.
// =============================================================================
class _AmbientBackground extends StatefulWidget {
  const _AmbientBackground();

  @override
  State<_AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<_AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
  AnimationController(vsync: this, duration: const Duration(seconds: 18))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Widget _blob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
    required double driftX,
    required double driftY,
  }) {
    final Widget blob = RepaintBoundary(
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

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _ac,
        child: blob,
        builder: (context, ch) {
          final double t = Curves.easeInOut.transform(_ac.value) - .5;
          return Transform.translate(
              offset: Offset(driftX * t, driftY * t), child: ch);
        },
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
            colors: [Colors.white.withOpacity(.07), Colors.white.withOpacity(.01)],
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
          children: [
            _blob(left: -w * .18, top: -h * .12, size: base * .70, color: _C.accent, opacity: .16, driftX: 60, driftY: 40),
            _blob(right: -w * .22, top: h * .28, size: base * .60, color: _C.mint, opacity: .12, driftX: -50, driftY: 60),
            _blob(left: w * .08, bottom: -h * .22, size: base * .75, color: _C.accent, opacity: .12, driftX: 40, driftY: -50),
            _bubble(right: w * .10, top: h * .06, size: (small * .16).clamp(40.0, 150.0)),
            _bubble(left: w * .06, top: h * .42, size: (small * .10).clamp(28.0, 100.0)),
            _bubble(right: w * .18, bottom: h * .10, size: (small * .20).clamp(50.0, 190.0)),
            _bubble(left: w * .40, bottom: h * .04, size: (small * .07).clamp(20.0, 70.0)),
          ],
        );
      }),
    );
  }
}