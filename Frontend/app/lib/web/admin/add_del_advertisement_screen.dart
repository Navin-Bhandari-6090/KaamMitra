import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

// Adjust the relative import segment counts / folder names to your project.
import '../../constant/variable.dart';
import '../../models/AdvertisementInfoModel.dart';
import '../../state management/getx/admin/add_del_ads_getx.dart';
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
  static const Color dangerBtn = Color(0xFFEF4444);
}

// =============================================================================
// SCREEN  (StatefulWidget only for controller lifecycle — zero setState)
// =============================================================================
class AdvertisementScreen extends StatefulWidget {
  final String User_Role;
  final String User_JwtToken;
  final String User_Email;
  const AdvertisementScreen({
    super.key,
    required this.User_Role,
    required this.User_JwtToken,
    required this.User_Email,
  });

  @override
  State<AdvertisementScreen> createState() => _AdvertisementScreenState();
}

class _AdvertisementScreenState extends State<AdvertisementScreen> {
  late final AddDelAdsGetx c;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    try {
      Admin_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    } catch (obj) {
      print(obj.toString());
    }
    c = Get.put(AddDelAdsGetx(), tag: _tag);
    c.init(jwtToken: widget.User_JwtToken);
  }

  @override
  void dispose() {
    try {
      Get.delete<AddDelAdsGetx>(tag: _tag);
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
          "Advertisement Screen",
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
                        sliver: const SliverToBoxAdapter(child: _Header()),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                        sliver: SliverToBoxAdapter(
                          child: LayoutBuilder(builder: (context, b) {
                            final create = _CreatePanel(c: c);
                            final delete = _DeletePanel(c: c);
                            if (b.maxWidth >= 760) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 6, child: create),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 5, child: delete),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                create,
                                const SizedBox(height: 16),
                                delete,
                              ],
                            );
                          }),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverToBoxAdapter(child: _SearchPanel(c: c)),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 8),
                        sliver: SliverToBoxAdapter(child: _ListHeader(c: c)),
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
    try {
      if (c.isLoading.value) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, i) => const _SkeletonCard(),
            childCount: 3,
          ),
        );
      }

      final String q = c.searchQuery.value.trim();
      final List<AdvertisementInfoModel> list = c.filteredAds;

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
            final a = list[i];
            return _Entrance(
              key: ValueKey('ad_${c.idOf(a)}'),
              index: i,
              child: _AdCard(c: c, a: a, jwt: widget.User_JwtToken),
            );
          },
          childCount: list.length,
        ),
      );
    } catch (obj) {
      print(obj.toString());
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }
}

// =============================================================================
// CONFIRM DIALOG (used before add and before every delete)
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
              backgroundColor: danger ? _C.dangerBtn : _C.accent,
              foregroundColor: danger ? Colors.white : Colors.black,
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

ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
  foregroundColor: _C.text,
  disabledForegroundColor: _C.muted.withOpacity(.5),
  minimumSize: const Size(0, 44),
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = _C.mint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
      ],
    );
  }
}

/// Text field with the animated focus glow (focus state lives in GetX).
class _GlowField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final RxBool focusedRx;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _GlowField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.focusedRx,
    this.keyboardType,
    this.formatters,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => focusedRx.value = v,
      child: Obx(() {
        final bool f = focusedRx.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: f ? _C.mint : _C.border, width: f ? 1.6 : 1),
            boxShadow: f
                ? [
              BoxShadow(
                  color: _C.mint.withOpacity(.18),
                  blurRadius: 14,
                  spreadRadius: 1)
            ]
                : [],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: _C.text, fontSize: 15),
            cursorColor: _C.mint,
            decoration: InputDecoration(
              filled: true,
              fillColor: _C.bar,
              isDense: true,
              labelText: label,
              labelStyle: TextStyle(
                  color: f ? _C.mint : _C.muted, fontSize: 13.5),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, color: f ? _C.mint : _C.muted, size: 19),
              ),
              prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            ),
          ),
        );
      }),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;
  final bool loading;
  final bool outlined;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
    this.loading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: outlined
                  ? null
                  : LinearGradient(
                colors: danger
                    ? const [_C.dangerBtn, _C.danger]
                    : const [_C.accent, _C.mint],
              ),
              color: outlined ? _C.surface : null,
              border: outlined ? Border.all(color: _C.border) : null,
              boxShadow: outlined
                  ? []
                  : [
                BoxShadow(
                    color: (danger ? _C.dangerBtn : _C.accent)
                        .withOpacity(.32),
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
                Icon(icon,
                    size: 18,
                    color: outlined ? _C.mint : _C.bg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: outlined ? _C.text : _C.bg,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5)),
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
// HEADER
// =============================================================================
class _Header extends StatelessWidget {
  const _Header();

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
            child: const Icon(Icons.ad_units_rounded, color: _C.bg, size: 28),
          ),
        ),
        const SizedBox(height: 14),
        const Text("Manage Advertisements",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _C.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
          "Publish new promotions or remove ones that have run their course.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.muted, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}

// =============================================================================
// CREATE PANEL
// =============================================================================
class _CreatePanel extends StatelessWidget {
  final AddDelAdsGetx c;
  const _CreatePanel({required this.c});

  Future<void> _pickPhoto() async {
    try {
      final int r = await change_photo_cont_getx.pickImage();
      if (r == 1) {
        Toast.Toastmsg("Pick photo for success.");
      } else if (r == 2) {
        Toast.Toastmsg("Only ${PhotoExtension} format accepted.");
      } else if (r == 5) {
        Toast.Toastmsg(
            "Image is larger then ${PhotoSize}.Please compressed and upload..");
      } else {
        Toast.Toastmsg("Pick photo for fail.");
      }
    } catch (e) {
      Toast.Toastmsg("Pick photo for fail.");
    }
  }

  Future<void> _pickVideo() async {
    try {
      final int r = await change_video_cont_getx.pickVideo();
      if (r == 1) {
        Toast.Toastmsg("Pick video success.");
      } else if (r == 2) {
        Toast.Toastmsg("Only ${VideoExtension} format accepted.");
      } else if (r == 5) {
        Toast.Toastmsg(
            "Video is larger then ${VideoSize}.Please compressed and upload..");
      } else {
        Toast.Toastmsg("Pick video fail.");
      }
    } catch (e) {
      Toast.Toastmsg("Pick video fail.");
    }
  }

  Future<void> _add() async {
    try {
      if (c.isAddingAd.value) return;
      if (c.titleCont.text.trim().isEmpty) {
        Toast.Toastmsg("Advertisement title is required.");
        return;
      }
      final bool ok = await _confirm(
        title: "Add advertisement?",
        message:
        "\"${c.titleCont.text.trim()}\" will be published with the selected media.",
        confirmLabel: "Add",
        icon: Icons.cloud_upload_rounded,
      );
      if (!ok) return;
      await c.submitAdd();
    } catch (obj) {
      print(obj.toString());
    }
  }

  Widget _status(bool selected, String on, String off, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _C.bar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? _C.mint : _C.border, width: selected ? 1.4 : 1),
        boxShadow: selected
            ? [
          BoxShadow(
              color: _C.mint.withOpacity(.16),
              blurRadius: 12,
              spreadRadius: 1)
        ]
            : [],
      ),
      child: Row(
        children: [
          Icon(selected ? Icons.check_circle_rounded : icon,
              color: selected ? _C.mint : _C.muted, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(selected ? on : off,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selected ? _C.text : _C.muted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            icon: Icons.campaign_rounded,
            title: "Create Advertisement",
            subtitle: "Add a title, link and optional media.",
          ),
          const SizedBox(height: 16),
          _GlowField(
            controller: c.titleCont,
            label: "Enter tittle of advertisement",
            icon: Icons.title,
            focusedRx: c.titleFocused,
          ),
          const SizedBox(height: 12),
          _GlowField(
            controller: c.urlCont,
            label: "Enter link of advertisement",
            icon: Icons.link,
            focusedRx: c.urlFocused,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Obx(() => _status(
                    change_photo_cont_getx.imageBytes.value != null,
                    "Photo selected",
                    "No photo",
                    Icons.image_outlined)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() => _status(
                    change_video_cont_getx.videoBytes.value != null,
                    "Video selected",
                    "No video",
                    Icons.videocam_outlined)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, b) {
            final pickPhoto = _GradientButton(
                outlined: true,
                label: "Pick photo",
                icon: Icons.add_photo_alternate_rounded,
                onTap: _pickPhoto);
            final pickVideo = _GradientButton(
                outlined: true,
                label: "Pick video",
                icon: Icons.video_call_rounded,
                onTap: _pickVideo);
            if (b.maxWidth >= 400) {
              return Row(children: [
                Expanded(child: pickPhoto),
                const SizedBox(width: 10),
                Expanded(child: pickVideo),
              ]);
            }
            return Column(children: [
              pickPhoto,
              const SizedBox(height: 10),
              pickVideo,
            ]);
          }),
          const SizedBox(height: 14),
          Obx(() => _GradientButton(
            label: "Add advertisement",
            icon: Icons.cloud_upload_rounded,
            loading: c.isAddingAd.value,
            onTap: _add,
          )),
        ],
      ),
    );
  }
}

// =============================================================================
// DELETE PANEL (by id)
// =============================================================================
class _DeletePanel extends StatelessWidget {
  final AddDelAdsGetx c;
  const _DeletePanel({required this.c});

  Future<void> _submit() async {
    try {
      final int? id = int.tryParse(c.adIdCont.text.trim());
      if (id == null) {
        await c.deleteFromInput(); // shows the validation toast
        return;
      }
      final bool ok = await _confirm(
        title: "Delete advertisement?",
        message:
        "Advertisement ID $id will be permanently deleted. This can't be undone.",
        confirmLabel: "Delete",
        icon: Icons.warning_amber_rounded,
        danger: true,
      );
      if (ok) await c.deleteFromInput();
    } catch (obj) {
      print(obj.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            icon: Icons.delete_sweep_rounded,
            title: "Delete Advertisement",
            subtitle: "Remove an advertisement by its ID.",
            tone: _C.danger,
          ),
          const SizedBox(height: 16),
          _GlowField(
            controller: c.adIdCont,
            label: "Enter the advertisement ID.",
            icon: Icons.ad_units,
            focusedRx: c.adIdFocused,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Obx(() => _GradientButton(
            label: "Delete advertisement.",
            icon: Icons.delete_forever_rounded,
            danger: true,
            loading: c.isDeletingAd.value,
            onTap: _submit,
          )),
        ],
      ),
    );
  }
}

// =============================================================================
// SEARCH + LIST HEADER
// =============================================================================
class _SearchPanel extends StatelessWidget {
  final AddDelAdsGetx c;
  const _SearchPanel({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _glassCard(),
      child: Obx(() {
        final bool has = c.searchQuery.value.isNotEmpty;
        return TextField(
          controller: c.searchCont,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: _C.text, fontSize: 15),
          cursorColor: _C.accent,
          onChanged: (v) => c.searchQuery.value = v,
          decoration: InputDecoration(
            hintText: "Search by advertisement id",
            hintStyle: const TextStyle(color: _C.muted, fontSize: 14),
            prefixIcon:
            const Icon(Icons.search_rounded, color: _C.mint, size: 20),
            suffixIcon: has
                ? IconButton(
              tooltip: "Clear",
              onPressed: c.clearSearch,
              icon: const Icon(Icons.close_rounded,
                  color: _C.muted, size: 20),
            )
                : null,
            filled: true,
            fillColor: _C.bar,
            isDense: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _C.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _C.accent, width: 1.5)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _C.border)),
          ),
        );
      }),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final AddDelAdsGetx c;
  const _ListHeader({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int total = c.ads.length;
      final int shown = c.filteredAds.length;
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text("All Advertisements",
              style: TextStyle(
                  color: _C.text, fontSize: 20, fontWeight: FontWeight.w800)),
          if (!c.isLoading.value) ...[
            _Chip(
              icon: Icons.layers_rounded,
              text: shown == total ? "$total ads" : "$shown of $total",
            ),
            const _Chip(icon: Icons.schedule_rounded, text: "Latest first"),
          ],
        ],
      );
    });
  }
}

// =============================================================================
// AD CARD — info + delete + one-by-one media viewer
// =============================================================================
class _AdCard extends StatelessWidget {
  final AddDelAdsGetx c;
  final AdvertisementInfoModel a;
  final String jwt;
  const _AdCard({required this.c, required this.a, required this.jwt});

  @override
  Widget build(BuildContext context) {
    final int id = c.idOf(a);
    final String link = c.linkOf(a);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: _glassCard(),
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
                  child: const Icon(Icons.campaign_rounded,
                      color: _C.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.titleOf(a),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(
                              icon: Icons.tag_rounded,
                              text: "ID $id",
                              color: _C.accent),
                          _Chip(
                              icon: Icons.schedule_rounded,
                              text: c.dateLabel(a)),
                        ],
                      ),
                      if (link.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            try {
                              await Clipboard.setData(ClipboardData(text: link));
                              Toast.Toastmsg("Link copied.");
                            } catch (obj) {
                              print(obj.toString());
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded,
                                    color: _C.mint, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(link,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: _C.mint,
                                          fontSize: 12.5,
                                          decoration:
                                          TextDecoration.underline,
                                          decorationColor: _C.mint)),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_rounded,
                                    color: _C.muted, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final bool busy = c.deletingIds.contains(id);
                  return Tooltip(
                    message: "Delete this advertisement",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: busy
                          ? null
                          : () async {
                        try {
                          final bool ok = await _confirm(
                            title: "Delete advertisement?",
                            message:
                            "Advertisement ID $id (${c.titleOf(a)}) will be permanently deleted. This can't be undone.",
                            confirmLabel: "Delete",
                            icon: Icons.warning_amber_rounded,
                            danger: true,
                          );
                          if (ok) await c.deleteAdById(id);
                        } catch (obj) {
                          print(obj.toString());
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
            final items = c.mediaFor(a);
            final int idx = c.indexFor(id, items.length);

            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(26),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.perm_media_outlined,
                          color: _C.muted, size: 34),
                      SizedBox(height: 10),
                      Text("No photo or video for this advertisement.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _C.muted, fontSize: 13.5)),
                    ],
                  ),
                ),
              );
            }

            final item = items[idx];
            final String url = c.buildUrl(item.path);

            return LayoutBuilder(builder: (context, box) {
              final Size screen = MediaQuery.of(context).size;
              final double availW = math.max(box.maxWidth - 32, 120);
              final bool isVideo = item.kind == AdMediaKind.video;

              final double w =
              math.min(availW, isVideo ? 760.0 : 560.0).toDouble();
              final double h =
              (screen.height * 0.45).clamp(220.0, 460.0).toDouble();

              final IconData kindIcon = isVideo
                  ? Icons.play_circle_outline_rounded
                  : Icons.photo_outlined;

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
                            scale:
                            Tween<double>(begin: .97, end: 1).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('${id}_$idx'),
                          child: _MediaPane(
                              kind: item.kind,
                              url: url,
                              jwt: jwt,
                              fullscreen: false),
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
                          style: _outlinedStyle(),
                        ),
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
                            textStyle:
                            const TextStyle(fontWeight: FontWeight.w700),
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
                                label:
                                "${c.titleOf(a)} · ${item.label}",
                                url: url,
                                jwt: jwt),
                            barrierColor: Colors.black87,
                            useSafeArea: false,
                          ),
                          icon: const Icon(Icons.fullscreen_rounded, size: 20),
                          label: const Text("Full screen"),
                          style: _outlinedStyle(),
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
}

// =============================================================================
// FULLSCREEN VIEWER
// =============================================================================
class _FullscreenViewer extends StatelessWidget {
  final AdMediaKind kind;
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
                  child: _MediaPane(
                      kind: kind, url: url, jwt: jwt, fullscreen: true),
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
// MEDIA PANE — photo / video
// =============================================================================
class _MediaPane extends StatelessWidget {
  final AdMediaKind kind;
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
    try {
      if (url.isEmpty) {
        inner = const _PaneMessage(
            icon: Icons.link_off_rounded,
            text: "No path returned for this item.");
      } else if (kind == AdMediaKind.photo) {
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
      } else {
        inner = _VideoPane(url: url, jwt: jwt);
      }
    } catch (obj) {
      print(obj.toString());
      inner = const _PaneMessage(
          icon: Icons.error_outline_rounded, text: "Unable to display media.");
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
      child: SingleChildScrollView(
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
                  icon: const Icon(Icons.refresh_rounded,
                      color: _C.accent, size: 18),
                  label: const Text("Retry",
                      style: TextStyle(color: _C.accent)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
    try {
      _player.open(
        Media(widget.url,
            httpHeaders: {"Authorization": "Bearer ${widget.jwt}"}),
        play: false,
      );
    } catch (obj) {
      error.value = "Unable to open this video.";
    }
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
    try {
      _errSub?.cancel();
      _player.dispose();
    } catch (obj) {
      print(obj.toString());
    }
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

        if (degenerate || bw >= _minControlsW) return video;

        // Narrower than the controls need: lay out at a safe width and scale
        // down uniformly (touch still works, FittedBox transforms hit tests).
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
                  searching ? Icons.search_off_rounded : Icons.campaign_outlined,
                  color: _C.accent,
                  size: 40),
            ),
            const SizedBox(height: 18),
            Text(searching ? "No match found" : "No advertisements yet",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.text, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              searching
                  ? "No advertisement has an id containing \"$query\"."
                  : "Advertisements you publish will appear here.",
              textAlign: TextAlign.center,
              style:
              const TextStyle(color: _C.muted, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: searching ? onClear : onRefresh,
              icon: Icon(
                  searching ? Icons.close_rounded : Icons.refresh_rounded,
                  size: 19),
              label: Text(searching ? "Clear search" : "Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.accent,
                foregroundColor: Colors.black,
                elevation: 0,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: _glassCard(),
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