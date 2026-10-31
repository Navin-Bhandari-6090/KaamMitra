import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:app/constant/variable.dart';

import 'package:app/web/common method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../state management/getx/profile/provider/update_res_file_getx.dart';

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

InputDecoration _input(String hint, IconData icon) {
  OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: col, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _C.muted, fontSize: 14),
    prefixIcon: Icon(icon, color: _C.mint, size: 20),
    filled: true,
    fillColor: _C.bar,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: b(_C.border),
    focusedBorder: b(_C.accent, 1.5),
    border: b(_C.border),
  );
}

ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
  foregroundColor: _C.text,
  minimumSize: const Size(0, 48),
  side: const BorderSide(color: _C.border, width: 1.2),
  textStyle: const TextStyle(fontWeight: FontWeight.w600),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
  backgroundColor: _C.accent,
  disabledBackgroundColor: _C.accent.withOpacity(.3),
  foregroundColor: Colors.black,
  disabledForegroundColor: Colors.black45,
  elevation: 0,
  minimumSize: const Size(0, 52),
  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

class UpdateServResFile extends StatefulWidget {
  final String User_JwtToken;
  const UpdateServResFile({super.key, required this.User_JwtToken});

  @override
  State<UpdateServResFile> createState() => _UpdateServResFileState();
}

class _UpdateServResFileState extends State<UpdateServResFile> {
  final String _tag = UniqueKey().toString();
  late final UpdateResFileGetx c;

  @override
  void initState() {
    super.initState();
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    c = Get.put(UpdateResFileGetx(), tag: _tag)..init(widget.User_JwtToken);
  }

  @override
  void dispose() {
    Get.delete<UpdateResFileGetx>(tag: _tag);
    super.dispose();
  }

  Future<void> _onUpdatePressed() async {
    try {
      if (!c.validate()) return;
      if (await _confirmUpdate(c.resourceIdCont.text.trim())) {
        await c.updateFile();
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    }
  }

  Future<bool> _confirmUpdate(String id) async {
    final bool? r = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _C.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.upload_file_rounded, color: _C.accent),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "Update service file?",
                style: TextStyle(
                    color: _C.text, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          "The file of resource ID $id will be replaced with the selected file. "
              "The current file will be lost.",
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
            style: _primaryStyle().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
    return r == true;
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
          "Update Resource File",
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
          const Positioned.fill(
              child: IgnorePointer(child: _AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth;
                final bool wide = w >= 880;
                final double hPad = w >= 700 ? 28 : 16;

                final Widget left = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Entrance(index: 0, child: _ResourceCard(c: c)),
                    const SizedBox(height: 18),
                    _Entrance(index: 1, child: _FileCard(c: c)),
                  ],
                );

                final Widget right = _Entrance(
                  index: 2,
                  child: _ReviewCard(c: c, onUpdate: _onUpdatePressed),
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          const SizedBox(height: 22),
                          wide
                              ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: left),
                              const SizedBox(width: 20),
                              Expanded(flex: 4, child: right),
                            ],
                          )
                              : Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              left,
                              const SizedBox(height: 18),
                              right,
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
      duration: Duration(milliseconds: 380 + (index * 90)),
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
          child: const Icon(Icons.upload_file_rounded,
              color: _C.accent, size: 26),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update service file",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _C.text, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                "Replace the document of a provider service resource.",
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

class _SectionCard extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.accent.withOpacity(.4)),
                ),
                child: Text(step,
                    style: const TextStyle(
                        color: _C.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
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
                        style:
                        const TextStyle(color: _C.muted, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final UpdateResFileGetx c;
  const _ResourceCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      step: "1",
      title: "Resource",
      subtitle: "Enter the id of the resource you want to update.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: c.resourceIdCont,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: _C.text, fontSize: 15),
            cursorColor: _C.accent,
            onChanged: c.onResourceIdChanged,
            decoration: _input("Resource ID", Icons.numbers_rounded),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final bool ok = c.resourceId.value.isNotEmpty;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Row(
                key: ValueKey(ok),
                children: [
                  Icon(
                    ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size: 15,
                    color: ok ? _C.accent : _C.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ok ? "Resource ID entered" : "Resource ID is required",
                    style: TextStyle(
                        color: ok ? _C.accent : _C.muted, fontSize: 12.5),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final UpdateResFileGetx c;
  const _FileCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      step: "2",
      title: "Document",
      subtitle: "Choose the new file to upload for this resource.",
      child: Obx(() {
        final List<int>? bytes = change_file_cont_getx.fileBytes.value;
        final bool has = bytes != null;
        final String kb =
        bytes == null ? "" : (bytes.length / 1024).toStringAsFixed(1);

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: has ? _C.accent.withOpacity(.08) : _C.bar,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: has ? _C.accent.withOpacity(.45) : _C.border),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      has
                          ? Icons.check_circle_rounded
                          : Icons.insert_drive_file_outlined,
                      key: ValueKey(has),
                      color: has ? _C.accent : _C.muted,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          has ? "File ready" : "No file selected",
                          style: const TextStyle(
                              color: _C.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          has
                              ? "$kb KB · uploads as service_file.pdf"
                              : "Choose a file to continue.",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _C.muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: c.pickFile,
                icon: const Icon(Icons.folder_open_rounded, size: 20),
                label: Text(has ? "Change file" : "Choose file"),
                style: _outlinedStyle(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final UpdateResFileGetx c;
  final Future<void> Function() onUpdate;
  const _ReviewCard({required this.c, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      step: "3",
      title: "Review & update",
      subtitle: "Check the details, then confirm.",
      child: Column(
        children: [
          Obx(() => _SummaryRow(
            icon: Icons.tag_rounded,
            label: "Resource ID",
            value: c.resourceId.value.isEmpty
                ? "Not entered"
                : c.resourceId.value,
            ok: c.resourceId.value.isNotEmpty,
          )),
          const SizedBox(height: 10),
          Obx(() {
            final bool ok = change_file_cont_getx.fileBytes.value != null;
            return _SummaryRow(
              icon: Icons.picture_as_pdf_outlined,
              label: "File",
              value: ok ? "Selected" : "Not selected",
              ok: ok,
            );
          }),
          const SizedBox(height: 18),
          const Text(
            "You will be asked to confirm before the file is sent. "
                "The current file will be replaced.",
            style: TextStyle(color: _C.muted, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 18),
          Obx(() {
            final bool busy = c.isUpdating.value;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onUpdate,
                icon: busy
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(busy ? "Updating..." : "Update file"),
                style: _primaryStyle(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ok;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.bar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ok ? _C.accent.withOpacity(.35) : _C.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ok ? _C.accent : _C.muted),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: _C.muted, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ok ? _C.text : _C.muted,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            children: [
              _blob(
                  left: -w * .18,
                  top: -h * .12,
                  size: base * .70,
                  color: _C.accent,
                  opacity: .16),
              _blob(
                  right: -w * .22,
                  top: h * .28,
                  size: base * .60,
                  color: _C.mint,
                  opacity: .12),
              _blob(
                  left: w * .08,
                  bottom: -h * .22,
                  size: base * .75,
                  color: _C.accent,
                  opacity: .12),
              _bubble(
                  right: w * .10,
                  top: h * .06,
                  size: math.min(math.max(small * .16, 40), 150)),
              _bubble(
                  left: w * .06,
                  top: h * .42,
                  size: math.min(math.max(small * .10, 28), 100)),
              _bubble(
                  right: w * .18,
                  bottom: h * .10,
                  size: math.min(math.max(small * .20, 50), 190)),
            ],
          );
        },
      ),
    );
  }
}