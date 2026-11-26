import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Adjust these paths to where your files live.
import 'package:app/models/UserLinkedResoModel.dart';
import 'package:app/state%20management/getx/admin/user_link_res_getx.dart';
import 'package:app/web/common%20widget/design/bolbs_background.dart';
import 'package:app/web/common%20widget/toast.dart';

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
  static const Color frame = Color(0xFF0B1711);
}

// One card per linked-resource group returned by the API ("11&13&14" style lists).
class _Cat {
  final String key;
  final String title;
  final IconData icon;
  final String? Function(UserLinkedResoModel m) pick;
  const _Cat(this.key, this.title, this.icon, this.pick);
}

final List<_Cat> _cats =
[
  _Cat("service", "Provider services", Icons.home_repair_service_rounded,
          (m) => m.providerServiceInfo),
  _Cat("resources", "Service resources", Icons.perm_media_rounded,
          (m) => m.providerServiceResourcesInfo),
  _Cat("booking", "Bookings", Icons.event_note_rounded, (m) => m.bookingInfos),
  _Cat("notif", "Notifications", Icons.notifications_rounded,
          (m) => m.notificationInfos),
  _Cat("newnotif", "New notifications", Icons.notifications_active_rounded,
          (m) => m.newNotificationInfos),
  _Cat("advance", "Advance payments", Icons.payments_rounded,
          (m) => m.advancePaymentInfos),
  _Cat("qr", "Payment QR codes", Icons.qr_code_2_rounded,
          (m) => m.advancePaymentQrInfos),
  _Cat("chat", "Chats", Icons.forum_rounded, (m) => m.chatInfos),
  _Cat("notices", "Notices", Icons.mark_chat_unread_rounded,
          (m) => m.noticeInfos),
  _Cat("notices", "Notices", Icons.mark_chat_unread_rounded,
          (m) => m.noticeInfos),
  _Cat("media", "Shared media", Icons.photo_library_rounded,
          (m) => m.sharedMediaInfos),
  _Cat("rating", "Ratings", Icons.star_rounded, (m) => m.ratingInfos),
  _Cat("Limit resource no per user", "Limit resource no per user", Icons.star_rounded, (m) => m.resourcesNoPerUserInfo),
];

// "1&2&3" -> ["1","2","3"]; null / empty -> [] (UI shows "No data available").
List<String> _ids(String? raw) {
  try {
    if (raw == null) return const [];
    return raw
        .split('&')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != "null")
        .toList();
  } catch (_) {
    return const [];
  }
}

const int _previewLimit = 24;

class UserLinkedResources extends StatefulWidget {
  final String User_JwtToken;
  const UserLinkedResources({super.key, required this.User_JwtToken});

  @override
  State<UserLinkedResources> createState() => _UserLinkedResourcesState();
}

class _UserLinkedResourcesState extends State<UserLinkedResources> {
  final Toast = Toastget();

  late final UserLinkResGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    c = Get.put(UserLinkResGetx(), tag: _tag);
    c.init(widget.User_JwtToken);
    c.verifyJwt(context);
  }

  @override
  void dispose() {
    try {
      Get.delete<UserLinkResGetx>(tag: _tag);
    } catch (_) {}
    super.dispose();
  }

  // Same validation as the original button handler.
  Future<void> _onSearch() async {
    if (c.isLoading.value) return;
    try {
      final String t = c.UserIdController.text.trim();
      final int? id = int.tryParse(t);
      if (t.isEmpty || id == null || id <= 0) {
        Toast.Toastmsg("Please enter a valid user ID.");
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await c.runSearch(context, id);
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    }
  }

  Future<void> _copy(String title, List<String> ids) async {
    try {
      await Clipboard.setData(ClipboardData(text: ids.join(', ')));
      Toast.Toastmsg("$title IDs copied.");
    } catch (_) {}
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
        shape: const Border(bottom: BorderSide(color: _C.border, width: 1)),
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
          "User Linked Resources",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 18, fontWeight: FontWeight.w700),
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

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad + 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _buildContent(math.max(0.0, w - hPad * 2)),
                    ),
                  ),
                );
              },
            ),
          ),
          // Thin progress bar kept out of the AppBar so tiny heights never overflow.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Obx(() => c.isLoading.value
                  ? const SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                      color: _C.mint, backgroundColor: _C.border))
                  : const SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Entrance(index: 0, child: _buildHeader(width)),
        const SizedBox(height: 18),
        _Entrance(index: 1, child: _buildSearchCard(width)),
        const SizedBox(height: 18),
        // Everything below reacts to the controller.
        Obx(() {
          if (c.isLoading.value) return _buildSkeleton(width);

          final List<UserLinkedResoModel> list =
          c.UserLinkedResoModelList.toList();

          if (list.isNotEmpty) return _buildResults(list[0], width);

          if (c.hasSearched.value) {
            return _EmptyState(
              icon: Icons.inbox_rounded,
              title: "No data available",
              text: c.errorMessage.value.isEmpty
                  ? "No linked resources were returned for this user."
                  : c.errorMessage.value,
              color: c.errorMessage.value.isEmpty ? _C.muted : _C.danger,
            );
          }

          return const _EmptyState(
            icon: Icons.manage_search_rounded,
            title: "Search a user",
            text:
            "Enter a user ID above to see every record linked to that user.",
            color: _C.mint,
          );
        }),
      ],
    );
  }

  Widget _buildHeader(double width) {
    final double titleSize = (width * 0.06).clamp(20.0, 28.0).toDouble();
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
            child: const Icon(Icons.hub_rounded, color: _C.bg, size: 32),
          ),
        ),
        const SizedBox(height: 14),
        Text("User Linked Resources",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text,
                fontSize: titleSize,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          "See every service, booking, chat, notification and payment record connected to a user.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildSearchCard(double width) {
    final bool row = width >= 560;

    final Widget field = Obx(() {
      final bool has = c.userIdText.value.trim().isNotEmpty;
      OutlineInputBorder border(Color color, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: w),
      );
      return TextField(
        controller: c.UserIdController,
        onChanged: (v) => c.userIdText.value = v,
        onSubmitted: (_) => _onSearch(),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.search,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        style: const TextStyle(color: _C.text, fontSize: 15),
        cursorColor: _C.mint,
        decoration: InputDecoration(
          labelText: "Enter the user ID",
          hintText: "e.g. 12",
          hintStyle: const TextStyle(color: _C.muted, fontSize: 13),
          labelStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
          floatingLabelStyle:
          const TextStyle(color: _C.mint, fontWeight: FontWeight.w600),
          prefixIcon: const Icon(Icons.numbers_rounded, color: _C.mint, size: 20),
          suffixIcon: has
              ? Tooltip(
            message: "Clear",
            child: IconButton(
              onPressed: c.clearInput,
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
          focusedBorder: border(_C.mint, 1.5),
          border: border(_C.border, 1),
        ),
      );
    });

    final Widget button = Obx(() => _GradientButton(
      label: "Get user linked resources",
      icon: Icons.search_rounded,
      loading: c.isLoading.value,
      onTap: c.isLoading.value ? null : _onSearch,
    ));

    return _GlassCard(
      child: row
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: field),
          const SizedBox(width: 14),
          Flexible(child: SizedBox(width: 280, child: button)),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [field, const SizedBox(height: 14), button],
      ),
    );
  }

  Widget _buildResults(UserLinkedResoModel m, double width) {
    int total = 0;
    int filled = 0;
    for (final _Cat cat in _cats) {
      final int n = _ids(cat.pick(m)).length;
      total += n;
      if (n > 0) filled++;
    }

    final int cols = width >= 900 ? 3 : (width >= 560 ? 2 : 1);
    const double gap = 14;
    final double cardW = math.max(0.0, (width - gap * (cols - 1)) / cols);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Entrance(
          index: 0,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                  icon: Icons.person_rounded,
                  text: "User #${c.searchedUser.value}"),
              _Chip(icon: Icons.layers_rounded, text: "$total linked records"),
              _Chip(
                  icon: Icons.category_rounded,
                  text: "$filled of ${_cats.length} groups have data",
                  color: filled == 0 ? _C.warn : _C.mint),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int i = 0; i < _cats.length; i++)
              SizedBox(
                width: cardW,
                child: _Entrance(
                  index: i + 1,
                  child: _buildCategoryCard(_cats[i], _ids(_cats[i].pick(m))),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(_Cat cat, List<String> ids) {
    final bool empty = ids.isEmpty;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (empty ? _C.muted : _C.mint).withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: (empty ? _C.muted : _C.mint).withOpacity(.35)),
                ),
                child: Icon(cat.icon, color: empty ? _C.muted : _C.mint, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(cat.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              _Chip(
                icon: empty ? Icons.remove_rounded : Icons.tag_rounded,
                text: "${ids.length}",
                color: empty ? _C.muted : _C.mint,
              ),
              if (!empty)
                Tooltip(
                  message: "Copy IDs",
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copy(cat.title, ids),
                    icon: const Icon(Icons.copy_rounded,
                        color: _C.muted, size: 17),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (empty)
            const Text("No data available",
                style: TextStyle(
                    color: _C.muted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic))
          else
            Obx(() {
              final bool open = c.expanded.contains(cat.key);
              final bool more = ids.length > _previewLimit;
              final List<String> shown =
              (open || !more) ? ids : ids.sublist(0, _previewLimit);
              return AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final id in shown) _IdPill(id)],
                    ),
                    if (more) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => c.toggleExpanded(cat.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  open
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: _C.mint,
                                  size: 18),
                              const SizedBox(width: 4),
                              Text(
                                  open
                                      ? "Show less"
                                      : "Show all ${ids.length}",
                                  style: const TextStyle(
                                      color: _C.mint,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSkeleton(double width) {
    final int cols = width >= 900 ? 3 : (width >= 560 ? 2 : 1);
    const double gap = 14;
    final double cardW = math.max(0.0, (width - gap * (cols - 1)) / cols);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (int i = 0; i < math.min(cols * 2, 6); i++)
          SizedBox(width: cardW, child: const _SkeletonBox(height: 120)),
      ],
    );
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
      duration: Duration(milliseconds: 420 + math.min(index * 70, 450)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 22), child: ch),
      ),
      child: child,
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.26),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
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

class _IdPill extends StatelessWidget {
  final String id;
  const _IdPill(this.id);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _C.bg.withOpacity(.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Text("#$id",
          style: const TextStyle(
              color: _C.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
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
    return SizedBox(
      height: 52,
      width: double.infinity,
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
              gradient: LinearGradient(colors: [
                _C.accent.withOpacity(disabled ? .45 : 1),
                _C.mint.withOpacity(disabled ? .45 : 1),
              ]),
              boxShadow: disabled
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
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(_C.bg)),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: _C.bg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _C.bg,
                          fontWeight: FontWeight.w800,
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Entrance(
      index: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: _C.surface.withOpacity(.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 46),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.text, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.muted, fontSize: 13.5, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  const _SkeletonBox({this.height = 120});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose()
  {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FadeTransition(
        opacity: Tween<double>(begin: .4, end: 1)
            .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.border),
          ),
        ),
      ),
    );
  }
}