
import 'package:app/web/common method/Commmon_Method.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../constant/variable.dart';
import '../../../state management/getx/profile/provider_user/send_media_getx.dart';
import '../../common widget/design/bolbs_background.dart';

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

const TextStyle _fieldText = TextStyle(color: _C.text, fontSize: 15);
const TextStyle _mutedSmall = TextStyle(color: _C.muted, fontSize: 12.5);

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

InputDecoration _input(String label, IconData icon, {String? helper}) {
  OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: col, width: w),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _C.muted, fontSize: 14),
    floatingLabelStyle: const TextStyle(color: _C.accent, fontSize: 13),
    helperText: helper,
    helperStyle: const TextStyle(color: _C.muted, fontSize: 12),
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
  minimumSize: const Size(0, 44),
  side: const BorderSide(color: _C.border, width: 1.2),
  textStyle: const TextStyle(fontWeight: FontWeight.w600),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
  backgroundColor: _C.accent,
  disabledBackgroundColor: _C.accent.withOpacity(.25),
  foregroundColor: Colors.black,
  disabledForegroundColor: Colors.black45,
  elevation: 0,
  minimumSize: const Size(0, 52),
  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

class SendMedia extends StatefulWidget {
  final String Current_User_Jwt_Token;
  const SendMedia({super.key, required this.Current_User_Jwt_Token});

  @override
  State<SendMedia> createState() => _SendMediaState();
}

class _SendMediaState extends State<SendMedia> {
  final String _tag = UniqueKey().toString();
  late final SendMediaGetx c;

  @override
  void initState() {
    super.initState();
    try {
      Provider_User_Jwt_Verify(
          Jwt_Token: widget.Current_User_Jwt_Token, context: context);
    } catch (_) {}
    c = Get.put(SendMediaGetx(), tag: _tag)
      ..init(widget.Current_User_Jwt_Token);
  }

  @override
  void dispose() {
    try {
      ClearFilesValues();
    } catch (_) {}
    Get.delete<SendMediaGetx>(tag: _tag);
    super.dispose();
  }

  Future<void> _onSendPressed() async {
    try {
      if (!c.validate()) return;
      final bool ok = await _confirmSend();
      if (ok && mounted) await c.submit(context);
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    }
  }

  List<String> _selectedMediaNames() {
    final List<String> names = [];
    if (change_photo_cont_getx.imageBytes.value != null) names.add("Photo");
    if (change_video_cont_getx.videoBytes.value != null) names.add("Video");
    if (change_file_cont_getx.fileBytes.value != null) names.add("File");
    return names;
  }

  Future<bool> _confirmSend() async {
    try {
      final String receiver = c.receiverCont.text.trim();
      final String description = c.descriptionCont.text.trim();
      final String media = _selectedMediaNames().join(", ");

      final bool? r = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _C.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.send_rounded, color: _C.accent),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  "Send media?",
                  style: TextStyle(
                      color: _C.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "This media will be sent to the user below.",
                style: TextStyle(color: _C.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              _dialogLine("User ID", receiver),
              _dialogLine("Media", media.isEmpty ? "None" : media),
              _dialogLine("Description", description),
            ],
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
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Send",
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return r == true;
    } catch (_) {
      return false;
    }
  }

  Widget _dialogLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(color: _C.muted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _C.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
          "Send Media",
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
              child: IgnorePointer(child: AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth;
                final bool wide = w >= 900;
                final double hPad = w >= 700 ? 28 : 16;

                final Widget details =
                _Entrance(index: 0, child: _DetailsCard(c: c));
                final Widget media =
                _Entrance(index: 1, child: _MediaCard(c: c));
                final Widget send = _Entrance(
                  index: 2,
                  child: _SendCard(c: c, onSend: _onSendPressed),
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          const SizedBox(height: 22),
                          wide
                              ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    details,
                                    const SizedBox(height: 18),
                                    media,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(flex: 4, child: send),
                            ],
                          )
                              : Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              details,
                              const SizedBox(height: 18),
                              media,
                              const SizedBox(height: 18),
                              send,
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
          child: const Icon(Icons.send_rounded, color: _C.accent, size: 26),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Send media",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _C.text, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                "Share a photo, video or file with another user.",
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
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.icon,
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
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.accent.withOpacity(.4)),
                ),
                child: Icon(icon, color: _C.accent, size: 19),
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
                        style: _mutedSmall),
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

class _DetailsCard extends StatelessWidget {
  final SendMediaGetx c;
  const _DetailsCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.edit_note_rounded,
      title: "Message",
      subtitle: "Who receives it and what it is about.",
      child: Column(
        children: [
          TextField(
            controller: c.receiverCont,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: _fieldText,
            cursorColor: _C.accent,
            onChanged: c.onReceiverChanged,
            decoration: _input("User ID", Icons.numbers_rounded),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: c.descriptionCont,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: _fieldText,
            cursorColor: _C.accent,
            onChanged: c.onDescriptionChanged,
            decoration: _input("Description", Icons.text_fields_rounded),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() => Text(
              "${c.description.value.length} characters",
              style: _mutedSmall,
            )),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final SendMediaGetx c;
  const _MediaCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.perm_media_rounded,
      title: "Media",
      subtitle: "Pick at least one photo, video or file.",
      child: Column(
        children: [
          _MediaRow(
            icon: Icons.photo_outlined,
            title: "Photo",
            selected: () => change_photo_cont_getx.imageBytes.value != null,
            detail: () {
              final bytes = change_photo_cont_getx.imageBytes.value;
              if (bytes == null) return "No photo selected";
              return "${(bytes.length / 1024).toStringAsFixed(1)} KB · ${change_photo_cont_getx.imageExtension.value}";
            },
            onPick: c.pickPhoto,
          ),
          const SizedBox(height: 12),
          _MediaRow(
            icon: Icons.videocam_outlined,
            title: "Video",
            selected: () => change_video_cont_getx.videoBytes.value != null,
            detail: () {
              final bytes = change_video_cont_getx.videoBytes.value;
              if (bytes == null) return "No video selected";
              return "${(bytes.length / 1024).toStringAsFixed(1)} KB · ${change_video_cont_getx.videoExtension.value}";
            },
            onPick: c.pickVideo,
          ),
          const SizedBox(height: 12),
          _MediaRow(
            icon: Icons.insert_drive_file_outlined,
            title: "File",
            selected: () => change_file_cont_getx.fileBytes.value != null,
            detail: () {
              final bytes = change_file_cont_getx.fileBytes.value;
              if (bytes == null) return "No file selected";
              return "${(bytes.length / 1024).toStringAsFixed(1)} KB · ${change_file_cont_getx.fileExtension.value}";
            },
            onPick: c.pickFile,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Supported extensions: Photo (${PhotoExtension}) · Video (${VideoExtension}) · File (${FileExtension})",
              style: _mutedSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool Function() selected;
  final String Function() detail;
  final VoidCallback onPick;
  const _MediaRow({
    required this.icon,
    required this.title,
    required this.selected,
    required this.detail,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool ok = selected();
      final String info = detail();
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ok ? _C.accent.withOpacity(.08) : _C.bar,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ok ? _C.accent.withOpacity(.45) : _C.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (ok ? _C.accent : _C.mint).withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ok ? _C.accent : _C.mint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _C.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: ok ? _C.text : _C.muted, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onPick,
              style: _outlinedStyle(),
              child: Text(ok ? "Change" : "Pick"),
            ),
          ],
        ),
      );
    });
  }
}

class _SendCard extends StatelessWidget {
  final SendMediaGetx c;
  final Future<void> Function() onSend;
  const _SendCard({required this.c, required this.onSend});

  int _mediaCount() {
    int n = 0;
    if (change_photo_cont_getx.imageBytes.value != null) n++;
    if (change_video_cont_getx.videoBytes.value != null) n++;
    if (change_file_cont_getx.fileBytes.value != null) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.checklist_rounded,
      title: "Review & send",
      subtitle: "Check the details, then send.",
      child: Column(
        children: [
          Obx(() {
            final bool ok = c.receiverId.value.isNotEmpty;
            return _SummaryRow(
              icon: Icons.person_outline_rounded,
              label: "User ID",
              value: ok ? c.receiverId.value : "Not entered",
              ok: ok,
            );
          }),
          const SizedBox(height: 10),
          Obx(() {
            final bool ok = c.description.value.isNotEmpty;
            return _SummaryRow(
              icon: Icons.text_fields_rounded,
              label: "Description",
              value: ok ? "Entered" : "Not entered",
              ok: ok,
            );
          }),
          const SizedBox(height: 10),
          Obx(() {
            final int n = _mediaCount();
            return _SummaryRow(
              icon: Icons.perm_media_outlined,
              label: "Media",
              value: n == 0 ? "None selected" : "$n selected",
              ok: n > 0,
            );
          }),
          const SizedBox(height: 18),
          Obx(() {
            final bool busy = c.isSending.value;
            final bool ready = c.receiverId.value.isNotEmpty &&
                c.description.value.isNotEmpty &&
                _mediaCount() > 0;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (busy || !ready) ? null : onSend,
                style: _primaryStyle(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Row(
                    key: ValueKey(busy),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      busy
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                          : const Icon(Icons.send_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(busy ? "Sending..." : "Send media"),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: c.clearAll,
              icon: const Icon(Icons.restart_alt_rounded, size: 19),
              label: const Text("Clear all"),
              style: _outlinedStyle(),
            ),
          ),
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
          Text(label, style: const TextStyle(color: _C.muted, fontSize: 13)),
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