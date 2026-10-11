import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';


import '../../models/ServiceScreenServiceModel.dart';
import '../../state management/getx/admin/show_serv_res_info_getx.dart';
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
class DelProRegServiceRes extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  const DelProRegServiceRes({
    super.key,
    required this.User_Role,
    required this.User_JwtToken,
    required this.User_Email,
  });

  @override
  State<DelProRegServiceRes> createState() => _DelProRegServiceResState();
}

class _DelProRegServiceResState extends State<DelProRegServiceRes> {
  late final ShowServResInfoGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    c = Get.put(ShowServResInfoGetx(), tag: _tag);
    c.init(jwtToken: widget.User_JwtToken, email: widget.User_Email);
  }

  @override
  void dispose() {
    Get.delete<ShowServResInfoGetx>(tag: _tag);
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
          "Manage Provider Services",
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
                        sliver: SliverToBoxAdapter(child: _DeletePanel(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverToBoxAdapter(child: _SearchPanel(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 8),
                        sliver: SliverToBoxAdapter(child: _DetailsHeader(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 40),
                        sliver: Obx(() => _buildList()),
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

  Widget _buildList() {
    if (c.isLoading.value) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) => const _SkeletonCard(),
          childCount: 3,
        ),
      );
    }

    final String q = c.searchQuery.value.trim();
    final List<ServiceScreenServiceModel> list = c.filteredServices;

    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptyState(
          searching: q.isNotEmpty,
          query: q,
          onClear: c.clearSearch,
          onRefresh: c.loadAll,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, i) {
          final s = list[i];
          final int id = c.idOf(s);
          return _Entrance(
            key: ValueKey('svc_$id'),
            index: i,
            child: _ServiceCard(c: c, s: s, jwt: widget.User_JwtToken),
          );
        },
        childCount: list.length,
      ),
    );
  }
}

// =============================================================================
// CONFIRM DIALOG
// =============================================================================
Future<bool> _confirmDelete(int id, String? name) async {
  final bool? r = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _C.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _C.danger),
          SizedBox(width: 10),
          Flexible(
            child: Text("Delete service?",
                style: TextStyle(
                    color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: Text(
        "Service ID $id${name != null && name.isNotEmpty ? ' ($name)' : ''} and all of its "
            "files, photos and videos will be permanently deleted. This can't be undone.",
        style: const TextStyle(color: _C.muted, height: 1.5),
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
// DELETE PANEL (top) — delete by service id
// =============================================================================
class _DeletePanel extends StatelessWidget {
  final ShowServResInfoGetx c;
  const _DeletePanel({required this.c});

  Future<void> _submit() async {
    final int? id = int.tryParse(c.serviceIdTextCont.text.trim());
    if (id == null) {
      // Lets the controller show the original "Service id is required." toast.
      await c.deleteFromInput();
      return;
    }
    final String? name = c.services
        .firstWhereOrNull((s) => c.idOf(s) == id)
        ?.serviceName;
    if (await _confirmDelete(id, name)) {
      await c.deleteFromInput();
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: c.serviceIdTextCont,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: _C.text, fontSize: 15),
      cursorColor: _C.accent,
      onSubmitted: (_) => _submit(),
      decoration: _input("Enter the service id", Icons.numbers_rounded),
    );

    final button = Obx(() {
      final busy = c.deletingIds.isNotEmpty;
      return ElevatedButton.icon(
        onPressed: busy ? null : _submit,
        icon: busy
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.delete_outline_rounded, size: 19),
        label: const Text("Delete service"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          disabledBackgroundColor: const Color(0xFFEF4444).withOpacity(.4),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.danger.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.danger.withOpacity(.35)),
                ),
                child: const Icon(Icons.delete_sweep_rounded,
                    color: _C.danger, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Delete by Service ID",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _C.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text("Removes the service and all its resources.",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _C.muted, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, box) {
            if (box.maxWidth >= 560) {
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
      ),
    );
  }
}

// =============================================================================
// SEARCH PANEL — filter by service id
// =============================================================================
class _SearchPanel extends StatelessWidget {
  final ShowServResInfoGetx c;
  const _SearchPanel({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _glassCard(),
      child: Obx(() {
        final bool has = c.searchQuery.value.isNotEmpty;
        return TextField(
          controller: c.searchTextCont,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: _C.text, fontSize: 15),
          cursorColor: _C.accent,
          onChanged: (v) => c.searchQuery.value = v,
          decoration: _input(
            "Search by service id",
            Icons.search_rounded,
            suffix: has
                ? IconButton(
              tooltip: "Clear",
              onPressed: c.clearSearch,
              icon: const Icon(Icons.close_rounded, color: _C.muted, size: 20),
            )
                : null,
          ),
        );
      }),
    );
  }
}

// =============================================================================
// DETAILS HEADER
// =============================================================================
class _DetailsHeader extends StatelessWidget {
  final ShowServResInfoGetx c;
  const _DetailsHeader({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int total = c.services.length;
      final int shown = c.filteredServices.length;
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text("Service Details",
              style: TextStyle(
                  color: _C.text, fontSize: 20, fontWeight: FontWeight.w800)),
          if (!c.isLoading.value)
            _Chip(
              icon: Icons.layers_rounded,
              text: shown == total ? "$total services" : "$shown of $total",
            ),
        ],
      );
    });
  }
}

// =============================================================================
// SERVICE CARD — header + delete + one-by-one media viewer
// =============================================================================
class _ServiceCard extends StatelessWidget {
  final ShowServResInfoGetx c;
  final ServiceScreenServiceModel s;
  final String jwt;
  const _ServiceCard({required this.c, required this.s, required this.jwt});

  @override
  Widget build(BuildContext context) {
    final int id = c.idOf(s);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: _glassCard(radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------- header ----------------
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            color: _C.bar,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.accent.withOpacity(.35)),
                  ),
                  child: const Icon(Icons.home_repair_service_rounded,
                      color: _C.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.serviceName ?? 'Unknown Service',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        final items = c.mediaFor(s);
                        final files =
                            items.where((e) => e.kind == MediaKind.file).length;
                        final photos =
                            items.where((e) => e.kind == MediaKind.photo).length;
                        final videos =
                            items.where((e) => e.kind == MediaKind.video).length;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(icon: Icons.tag_rounded, text: "ID $id", color: _C.accent),
                            _Chip(icon: Icons.picture_as_pdf_outlined, text: "$files file"),
                            _Chip(icon: Icons.photo_outlined, text: "$photos photo${photos == 1 ? '' : 's'}"),
                            _Chip(icon: Icons.videocam_outlined, text: "$videos video${videos == 1 ? '' : 's'}"),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final bool busy = c.deletingIds.contains(id);
                  return Tooltip(
                    message: "Delete this service",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: busy
                          ? null
                          : () async {
                        if (await _confirmDelete(id, s.serviceName)) {
                          await c.deleteServiceById(id);
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _C.danger.withOpacity(.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.danger.withOpacity(.4)),
                        ),
                        child: busy
                            ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _C.danger),
                        )
                            : const Icon(Icons.delete_outline_rounded,
                            color: _C.danger, size: 21),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Container(height: 1, color: _C.border),

          // ---------------- media viewer ----------------
          Obx(() {
            final items = c.mediaFor(s);
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_off_outlined, color: _C.muted, size: 34),
                      SizedBox(height: 10),
                      Text("Nothing uploaded for this service yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _C.muted, fontSize: 13.5)),
                    ],
                  ),
                ),
              );
            }

            final int idx = c.indexFor(id, items.length);
            final item = items[idx];
            final String url = c.buildUrl(item.path);

            return LayoutBuilder(builder: (context, box) {
              final Size screen = MediaQuery.of(context).size;
              final double availW = math.max(box.maxWidth - 32, 120);
              final bool isVideo = item.kind == MediaKind.video;

              // Photos / PDFs: 50% of screen width, floored so it never
              // collapses. Video: full available width so the player controls
              // are scaled down as little as possible on small screens.
              final double w = isVideo
                  ? availW
                  : (screen.width * 0.5)
                  .clamp(math.min(280.0, availW), availW)
                  .toDouble();
              final double h = math.max(screen.height * 0.5, 240.0);

              final IconData kindIcon = item.kind == MediaKind.file
                  ? Icons.picture_as_pdf_outlined
                  : item.kind == MediaKind.photo
                  ? Icons.photo_outlined
                  : Icons.play_circle_outline_rounded;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Chip(icon: kindIcon, text: item.label, color: _C.accent),
                        _Chip(
                            icon: Icons.filter_none_rounded,
                            text: "${idx + 1} / ${items.length}"),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: w,
                      height: h,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOut,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: .97, end: 1).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('${id}_$idx'),
                          child: _MediaPane(
                              kind: item.kind, url: url, jwt: jwt, fullscreen: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: items.length > 1
                              ? () => c.previous(id, items.length)
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded, size: 20),
                          label: const Text("Previous"),
                          style: _outlined(),
                        ),
                        if (items.length <= 8)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(items.length, (i) {
                              final bool on = i == idx;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: on ? 20 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: on ? _C.accent : _C.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }),
                          ),
                        ElevatedButton.icon(
                          onPressed: items.length > 1
                              ? () => c.next(id, items.length)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded, size: 20),
                          label: const Text("Next"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.accent,
                            disabledBackgroundColor: _C.accent.withOpacity(.25),
                            foregroundColor: Colors.black,
                            disabledForegroundColor: Colors.black38,
                            elevation: 0,
                            minimumSize: const Size(0, 44),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: url.isEmpty
                              ? null
                              : () => Get.dialog(
                            _FullscreenViewer(
                                kind: item.kind,
                                label: item.label,
                                url: url,
                                jwt: jwt),
                            barrierColor: Colors.black87,
                            useSafeArea: false,
                          ),
                          icon: const Icon(Icons.fullscreen_rounded, size: 20),
                          label: const Text("Full screen"),
                          style: _outlined(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  ButtonStyle _outlined() => OutlinedButton.styleFrom(
    foregroundColor: _C.text,
    disabledForegroundColor: _C.muted.withOpacity(.5),
    minimumSize: const Size(0, 44),
    side: const BorderSide(color: _C.border, width: 1.2),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// =============================================================================
// FULLSCREEN VIEWER
// =============================================================================
class _FullscreenViewer extends StatelessWidget {
  final MediaKind kind;
  final String label;
  final String url;
  final String jwt;
  const _FullscreenViewer({
    required this.kind,
    required this.label,
    required this.url,
    required this.jwt,
  });

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
                  child: _MediaPane(kind: kind, url: url, jwt: jwt, fullscreen: true),
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
// MEDIA PANE — picks photo / pdf / video
// =============================================================================
class _MediaPane extends StatelessWidget {
  final MediaKind kind;
  final String url;
  final String jwt;
  final bool fullscreen;
  const _MediaPane({
    required this.kind,
    required this.url,
    required this.jwt,
    required this.fullscreen,
  });

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (url.isEmpty) {
      inner = const _PaneMessage(
          icon: Icons.link_off_rounded, text: "No path returned for this item.");
    } else {
      switch (kind) {
        case MediaKind.photo:
          final img = Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, p) => p == null
                ? child
                : const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: _C.accent),
              ),
            ),
            errorBuilder: (context, e, st) => const _PaneMessage(
                icon: Icons.broken_image_outlined, text: "Image unavailable"),
          );
          inner = fullscreen
              ? InteractiveViewer(
              minScale: .8, maxScale: 5, child: Center(child: img))
              : Center(child: img);
          break;
        case MediaKind.file:
          inner = _PdfPane(url: url, jwt: jwt);
          break;
        case MediaKind.video:
          inner = _VideoPane(url: url, jwt: jwt);
          break;
      }
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
  final VoidCallback? onRetry;
  const _PaneMessage({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _C.muted, size: 32),
            const SizedBox(height: 10),
            Text(text,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _C.muted, fontSize: 12.5)),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, color: _C.accent, size: 18),
                label: const Text("Retry", style: TextStyle(color: _C.accent)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- PDF pane ---
class _PdfPane extends StatefulWidget {
  final String url;
  final String jwt;
  const _PdfPane({required this.url, required this.jwt});

  @override
  State<_PdfPane> createState() => _PdfPaneState();
}

class _PdfPaneState extends State<_PdfPane> {
  final RxnString error = RxnString();
  final RxInt attempt = 0.obs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      // Never mount SfPdfViewer in a degenerate box (avoids its clamp crash).
      final bool ok = box.maxWidth.isFinite &&
          box.maxHeight.isFinite &&
          box.maxWidth > 0 &&
          box.maxHeight > 0;
      if (!ok) {
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: _C.accent),
          ),
        );
      }

      return Obx(() {
        if (error.value != null) {
          return _PaneMessage(
            icon: Icons.picture_as_pdf_outlined,
            text: error.value!,
            onRetry: () {
              error.value = null;
              attempt.value++;
            },
          );
        }
        return SfPdfViewer.network(
          widget.url,
          key: ValueKey('pdf_${attempt.value}'),
          headers: {"Authorization": "Bearer ${widget.jwt}"},
          canShowScrollHead: true,
          canShowScrollStatus: true,
          canShowPaginationDialog: false,
          enableDoubleTapZooming: true,
          pageSpacing: 4,
          onDocumentLoadFailed: (d) {
            error.value = d.description.isNotEmpty
                ? d.description
                : "Failed to load this document.";
          },
        );
      });
    });
  }
}

// -------------------------------------------------------------- Video pane ---
class _VideoPane extends StatefulWidget {
  final String url;
  final String jwt;
  const _VideoPane({required this.url, required this.jwt});

  @override
  State<_VideoPane> createState() => _VideoPaneState();
}

class _VideoPaneState extends State<_VideoPane> {
  late final Player _player;
  late final VideoController _vc;
  final RxnString error = RxnString();
  dynamic _errSub;

  /// Width the media_kit controls need to lay out without overflowing.
  static const double _minControlsW = 360;

  void _open() {
    _player.open(
      Media(widget.url, httpHeaders: {"Authorization": "Bearer ${widget.jwt}"}),
      play: false,
    );
  }

  @override
  void initState() {
    super.initState();
    _player = Player();
    _vc = VideoController(_player);
    _errSub = _player.stream.error.listen((e) {
      error.value = e.isNotEmpty ? e : "Playback error.";
    });
    _open();
  }

  @override
  void dispose() {
    _errSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (error.value != null) {
        return _PaneMessage(
          icon: Icons.error_outline_rounded,
          text: error.value!,
          onRetry: () {
            error.value = null;
            _open();
          },
        );
      }

      return LayoutBuilder(builder: (context, box) {
        final double bw = box.maxWidth;
        final double bh = box.maxHeight;
        final Widget video = Video(controller: _vc, fit: BoxFit.contain);

        final bool degenerate =
            !bw.isFinite || !bh.isFinite || bw <= 0 || bh <= 0;

        // Wide enough (or unmeasurable): render normally.
        if (degenerate || bw >= _minControlsW) return video;

        // Narrower than the controls need: lay out at a safe width with the
        // same aspect ratio as the pane, then scale everything down uniformly.
        // Touch input still works because FittedBox transforms hit testing.
        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _minControlsW,
            height: _minControlsW * bh / bw,
            child: video,
          ),
        );
      });
    });
  }
}

// =============================================================================
// EMPTY + SKELETON
// =============================================================================
class _EmptyState extends StatelessWidget {
  final bool searching;
  final String query;
  final VoidCallback onClear;
  final Future<void> Function() onRefresh;
  const _EmptyState({
    required this.searching,
    required this.query,
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
            Text(searching ? "No match found" : "No services yet",
                style: const TextStyle(
                    color: _C.text, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              searching
                  ? "No service has an id containing \"$query\"."
                  : "Registered provider services will appear here.",
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

  Widget _bar(double h, {double? w}) => Container(
    height: h,
    width: w,
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
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: _glassCard(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.07),
                    borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(width: 12),
              Expanded(child: _bar(16)),
            ]),
            const SizedBox(height: 16),
            _bar(180),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// AMBIENT BACKGROUND — blurred emerald/mint blobs + glass bubbles.
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
        imageFilter: ImageFilter.blur(
            sigmaX: 45, sigmaY: 45, tileMode: TileMode.decal),
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
            _blob(left: -w * .18, top: -h * .12, size: base * .70, color: _C.accent, opacity: .16),
            _blob(right: -w * .22, top: h * .28, size: base * .60, color: _C.mint, opacity: .12),
            _blob(left: w * .08, bottom: -h * .22, size: base * .75, color: _C.accent, opacity: .12),
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