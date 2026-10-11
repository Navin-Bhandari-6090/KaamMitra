import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../state management/getx/profile/provider/pro_upd_reg_serv_descp.dart';
import '../../authentication/Error_page.dart';
import '../../common method/Commmon_Method.dart';
import '../../common widget/GreenTextfield.dart';


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
  static const Color warn = Color(0xFFFBBF24);
  static const Color frame = Color(0xFF0B1711);
}

// =============================================================================
// SCREEN
// =============================================================================
class UpdateProRegSerDescp extends StatefulWidget {
  final String User_JwtToken;
  const UpdateProRegSerDescp({super.key, required this.User_JwtToken});

  @override
  State<UpdateProRegSerDescp> createState() => _UpdateProRegSerDescpState();
}

class _UpdateProRegSerDescpState extends State<UpdateProRegSerDescp> {
  final TextEditingController ProviderServiceIdController =
      TextEditingController();
  final TextEditingController ProRegServiceDescriptionController =
      TextEditingController();

  final String _tag = UniqueKey().toString();
  late final ProUpdRegServDescp c;

  @override
  void initState() {
    super.initState();
    c = Get.put(ProUpdRegServDescp(), tag: _tag);
    ProRegServiceDescriptionController.addListener(_onDescriptionChanged);
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
  }

  @override
  void dispose() {
    try {
      ProRegServiceDescriptionController.removeListener(_onDescriptionChanged);
    } catch (e) {
      print(e);
    }
    try {
      ProviderServiceIdController.dispose();
    } catch (e) {
      print(e);
    }
    try {
      ProRegServiceDescriptionController.dispose();
    } catch (e)
    {
      print(e);
    }
    try {
      Get.delete<ProUpdRegServDescp>(tag: _tag);
    } catch (e) {
      print(e);
    }
    super.dispose();
  }

  void _onDescriptionChanged() {
    try {
      c.descLength.value = ProRegServiceDescriptionController.text.length;
    } catch (e) {
      print(e);
    }
  }


  // NETWORK (logic unchanged)

  Future<void> UpdateProviderServiceDescription({
    required int ProviderServiceId,
    required String ProRegServiceDescription,
    required String jwttoken,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Profile/updatedescription";

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode({
          "ProviderServiceId": ProviderServiceId,
          "ProRegServiceDescription": ProRegServiceDescription,
        }),
      );
        print(response.statusCode);
        print(response.body);

      if (response.statusCode == 200)
      {
        // UI state only: the "Current details" card updates immediately.
        c.onSaved(ProviderServiceId, ProRegServiceDescription);
        Toast.Toastmsg("Service description updated successfully.");
        return;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg("Invalid provider service information.");
      }
      else if (response.statusCode == 502)
      {
        Toast.Toastmsg("User not found.");
     Logout(context: context);
      }
      else if (response.statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by the system. Please contact the KaamMitra community.",
        );
        Logout(context: context);
      } else if (response.statusCode == 404) {
        Toast.Toastmsg("Provider service not found.");
      } else if (response.statusCode == 500) {
        Toast.Toastmsg("Something went wrong on the server.");
      }
      else
      {
        Toast.Toastmsg("Something went wrong.");
        return;
      }
    } catch (e) {
      print(e);
      Toast.Toastmsg("Something went wrong.");
      return;
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------
  Future<void> _onUpdate() async {
    if (c.busy.value) return;
    try {
      // PROVIDER SERVICE ID CHECK
      final String idText = ProviderServiceIdController.text.trim();
      if (idText.isEmpty) {
        Toast.Toastmsg("Please enter provider service ID.");
        return;
      }

      // PROVIDER SERVICE ID NUMBER CHECK
      final int? providerServiceId = int.tryParse(idText);
      if (providerServiceId == null) {
        Toast.Toastmsg("Provider service ID must be a valid number.");
        return;
      }

      // DESCRIPTION CHECK
      final String description = ProRegServiceDescriptionController.text.trim();
      if (description.isEmpty) {
        Toast.Toastmsg("Please enter service description.");
        return;
      }

      final bool ok = await _confirm(
        title: "Update description?",
        message:
            "The description for service ID #$providerServiceId will be replaced with the text you entered.",
        confirmLabel: "Update",
        icon: Icons.edit_note_rounded,
      );
      if (!ok) return;

      c.busy.value = true;

      await UpdateProviderServiceDescription(
        ProviderServiceId: providerServiceId,
        ProRegServiceDescription: description,
        jwttoken: widget.User_JwtToken,
      );
      return;

    } catch (e)
    {
      print(e);
      Toast.Toastmsg("Something went wrong.");
    } finally {
      c.busy.value = false;
    }
  }

  void _onClear() {
    try {
      ProviderServiceIdController.clear();
      ProRegServiceDescriptionController.clear();
    } catch (e) {
      print(e);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
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
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _C.text,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          "Service Description",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _C.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _AmbientBackground()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final bool wide = box.maxWidth >= 900;
                final double hPad = box.maxWidth >= 600 ? 28 : 16;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: wide ? _buildWideLayout() : _buildNarrowLayout(),
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

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: _spaced([
              _Entrance(index: 0, child: _buildHero()),
              _Entrance(index: 2, child: _buildCurrentCard()),
            ], 18),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(flex: 6, child: _Entrance(index: 1, child: _buildFormCard())),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: _spaced([
        _Entrance(index: 0, child: _buildHero()),
        _Entrance(index: 1, child: _buildFormCard()),
        _Entrance(index: 2, child: _buildCurrentCard()),
      ], 18),
    );
  }

  List<Widget> _spaced(List<Widget> items, double gap) {
    final List<Widget> out = [];
    for (int i = 0; i < items.length; i++) {
      if (i != 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // HERO
  // ---------------------------------------------------------------------------
  Widget _buildHero() {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      child: Column(
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
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: _C.bg,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Update Service Description",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _C.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Write a clear description so customers know exactly what you offer.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final bool saved = c.savedServiceId.value != null;
            return _Chip(
              icon: saved
                  ? Icons.check_circle_rounded
                  : Icons.hourglass_empty_rounded,
              text: saved ? "Saved in this session" : "No changes yet",
              color: saved ? _C.mint : _C.muted,
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM
  // ---------------------------------------------------------------------------
  Widget _buildFormCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            icon: Icons.description_rounded,
            title: "Service details",
            subtitle: "Enter the service ID and the new description.",
          ),
          const SizedBox(height: 18),
          _field(
            controller: ProviderServiceIdController,
            label: "Provider service ID",
            hint: "e.g. 1024",
            icon: Icons.numbers_rounded,
            type: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _field(
            controller: ProRegServiceDescriptionController,
            label: "Service description",
            hint: "Describe what you offer, your experience and your area.",
            icon: Icons.notes_rounded,
            type: TextInputType.multiline,
            maxLines: 6,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(
              () => Text(
                "${c.descLength.value} characters",
                style: const TextStyle(color: _C.muted, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, box) {
              final Widget clear = _GradientButton(
                outlined: true,
                label: "Clear",
                icon: Icons.backspace_outlined,
                onTap: _onClear,
              );
              final Widget update = Obx(
                () => _GradientButton(
                  label: "Update description",
                  icon: Icons.save_rounded,
                  loading: c.busy.value,
                  onTap: c.busy.value ? null : _onUpdate,
                ),
              );

              if (box.maxWidth >= 380) {
                return Row(
                  children: [
                    Expanded(flex: 2, child: clear),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: update),
                  ],
                );
              }
              return Column(
                children: [update, const SizedBox(height: 10), clear],
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CURRENT DETAILS (reactive, shows "No data available" when empty)
  // ---------------------------------------------------------------------------
  Widget _buildCurrentCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            icon: Icons.fact_check_rounded,
            title: "Current details",
            subtitle: "The last description saved from this screen.",
          ),
          const SizedBox(height: 16),
          Obx(
            () => _InfoRow(
              icon: Icons.tag_rounded,
              label: "Service ID",
              value: c.savedServiceId.value?.toString(),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => _InfoRow(
              icon: Icons.notes_rounded,
              label: "Description",
              value: c.savedDescription.value,
              multiline: true,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM FIELD
  // ---------------------------------------------------------------------------
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? type,
    int maxLines = 1,
  }) {
    OutlineInputBorder border(Color color, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: w),
    );
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: _C.text, fontSize: 15, height: 1.4),
      cursorColor: _C.mint,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: _C.muted, fontSize: 13),
        labelStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
        floatingLabelStyle: const TextStyle(
          color: _C.mint,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 80 : 0),
          child: Icon(icon, color: _C.mint, size: 20),
        ),
        filled: true,
        fillColor: _C.bg.withOpacity(.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: border(_C.border, 1),
        focusedBorder: border(_C.mint, 1.5),
        border: border(_C.border, 1),
      ),
    );
  }
}

// =============================================================================
// HELPERS
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
              child: Text(
                title,
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
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
              backgroundColor: _C.accent,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return r == true;
  } catch (e) {
    print(e);
    return false;
  }
}

BoxDecoration _tileDeco() => BoxDecoration(
  color: _C.bg.withOpacity(.55),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: _C.border),
);

// =============================================================================
// SHARED UI PIECES
// =============================================================================
class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + math.min(index * 90, 450)),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch),
      ),
      child: child,
    );
  }
}

/// Frosted glass card: translucent surface, blur behind, soft border.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _C.surface.withOpacity(.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.28),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
              Text(
                title,
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _C.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
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
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool multiline;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool empty = value == null || value!.trim().isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _tileDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _C.mint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _C.muted, fontSize: 11.5),
                ),
                const SizedBox(height: 3),
                Text(
                  empty ? "No data available" : value!,
                  softWrap: true,
                  maxLines: multiline ? 8 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: empty ? _C.muted : _C.text,
                    fontSize: 13.5,
                    height: 1.4,
                    fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                    fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
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
    final bool disabled = onTap == null && !loading;
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: outlined
                  ? null
                  : LinearGradient(
                      colors: [
                        _C.accent.withOpacity(disabled ? .45 : 1),
                        _C.mint.withOpacity(disabled ? .45 : 1),
                      ],
                    ),
              color: outlined ? _C.surface : null,
              border: outlined ? Border.all(color: _C.border) : null,
              boxShadow: outlined || disabled
                  ? []
                  : [
                      BoxShadow(
                        color: _C.accent.withOpacity(.32),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(_C.bg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: outlined
                            ? _C.mint.withOpacity(disabled ? .5 : 1)
                            : _C.bg,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: outlined
                                ? _C.text.withOpacity(disabled ? .5 : 1)
                                : _C.bg,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
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
// AMBIENT BACKGROUND — blurred emerald/mint blobs + glass bubbles.
// Wrapped in IgnorePointer by the caller, so it never blocks taps.
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
          sigmaX: 45,
          sigmaY: 45,
          tileMode: TileMode.decal,
        ),
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
              Colors.white.withOpacity(.01),
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
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.hasBoundedWidth ? box.maxWidth : 800;
          final double h = box.hasBoundedHeight ? box.maxHeight : 800;
          final double base = math.max(w, h);
          final double small = math.min(w, h);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              _blob(
                left: -w * .18,
                top: -h * .12,
                size: base * .70,
                color: _C.accent,
                opacity: .16,
              ),
              _blob(
                right: -w * .22,
                top: h * .28,
                size: base * .60,
                color: _C.mint,
                opacity: .12,
              ),
              _blob(
                left: w * .08,
                bottom: -h * .22,
                size: base * .75,
                color: _C.accent,
                opacity: .12,
              ),
              _bubble(
                right: w * .10,
                top: h * .06,
                size: (small * .16).clamp(40.0, 150.0).toDouble(),
              ),
              _bubble(
                left: w * .06,
                top: h * .42,
                size: (small * .10).clamp(28.0, 100.0).toDouble(),
              ),
              _bubble(
                right: w * .18,
                bottom: h * .10,
                size: (small * .20).clamp(50.0, 190.0).toDouble(),
              ),
            ],
          );
        },
      ),
    );
  }
}
