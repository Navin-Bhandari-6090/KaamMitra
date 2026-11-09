import 'dart:ui' show ImageFilter;

import 'package:app/models/SharedMediaModel.dart';
import 'package:app/state management/getx/profile/provider_user/view_media_getx.dart';
import 'package:app/web/common method/Commmon_Method.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../constant/variable.dart';
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
  static const Color danger = Color(0xFFF87171);
  static const Color viewerBg = Color(0xFF050B08);
}

const TextStyle _fieldText = TextStyle(color: _C.text, fontSize: 15);
const TextStyle _mutedSmall = TextStyle(color: _C.muted, fontSize: 12.5);

BoxDecoration _glassCard({double radius = 20}) => BoxDecoration(
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

class ViewMedia extends StatefulWidget {
  final String Current_User_Jwt_Token;
  const ViewMedia({super.key, required this.Current_User_Jwt_Token});

  @override
  State<ViewMedia> createState() => _ViewMediaState();
}

class _ViewMediaState extends State<ViewMedia> {
  final String _tag = UniqueKey().toString();
  late final ViewMediaGetx c;

  @override
  void initState() {
    super.initState();
    try {
      Provider_User_Jwt_Verify(
          Jwt_Token: widget.Current_User_Jwt_Token, context: context);
    } catch (_) {}
    c = Get.put(ViewMediaGetx(), tag: _tag)
      ..init(widget.Current_User_Jwt_Token);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.loadAll(context);
    });
  }

  @override
  void dispose() {
    Get.delete<ViewMediaGetx>(tag: _tag);
    super.dispose();
  }

  Future<bool> _confirmDelete(int id) async {
    try {
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
                child: Text(
                  "Delete media?",
                  style: TextStyle(
                      color: _C.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            "Media ID $id and its photo, video and file will be permanently deleted. This can't be undone.",
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Delete"),
            ),
          ],
        ),
      );
      return r == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onDelete(SharedMediaModel m) async {
    try {
      final int? id = m.sharedMediaId?.toInt();
      if (id == null) {
        Toast.Toastmsg("This media has no ID and cannot be deleted.");
        return;
      }
      if (await _confirmDelete(id) && mounted) {
        await c.deleteMedia(context, id);
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    }
  }

  void _openViewer(MediaAttachment a, SharedMediaModel m) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MediaViewerPage(
            attachment: a,
            url: c.urlOf(a),
            title: "Media ${c.displayOr(c.idOf(m))} · ${_kindLabel(a.kind)}",
            jwt: widget.Current_User_Jwt_Token,
          ),
        ),
      );
    } catch (_) {
      Toast.Toastmsg("Unable to open this media.");
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
          "Shared Media",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() => IconButton(
            tooltip: "Refresh",
            onPressed:
            c.isLoading.value ? null : () => c.loadAll(context),
            icon: Icon(Icons.refresh_rounded,
                color: c.isLoading.value ? _C.muted : _C.mint),
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
              child: IgnorePointer(child: AmbientBackground())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final double w = box.maxWidth.isFinite ? box.maxWidth : 900;
                final double pad = w >= 700 ? 28 : 14;

                return RefreshIndicator(
                  color: _C.accent,
                  backgroundColor: _C.surface,
                  onRefresh: () => c.loadAll(context),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(pad, 20, pad, 14),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                                children: [
                                  _Reveal(child: _Header(c: c)),
                                  const SizedBox(height: 14),
                                  _Reveal(
                                      delayMs: 80,
                                      child: _SearchField(c: c)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Obx(() => _buildList(pad)),
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

  Widget _buildList(double pad) {
    if (c.isLoading.value && c.sharedList.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, i) => _centered(const _SkeletonCard()),
            childCount: 3,
          ),
        ),
      );
    }

    if (c.loadFailed.value && c.sharedList.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _Placeholder(
          icon: Icons.cloud_off_rounded,
          title: "Unable to Load Media",
          message: c.errorText.value.isEmpty
              ? "Something went wrong while loading shared media."
              : c.errorText.value,
          action: ElevatedButton.icon(
            onPressed: () => c.loadAll(context),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Try Again"),
            style: _primaryStyle(),
          ),
        ),
      );
    }

    if (c.sharedList.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _Placeholder(
          icon: Icons.perm_media_outlined,
          title: "No Media Yet",
          message: "No shared media is available for your account.",
        ),
      );
    }

    final list = c.filteredList;
    if (list.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _Placeholder(
          icon: Icons.search_off_rounded,
          title: "No Match Found",
          message: "No media matches your search.",
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) {
            final SharedMediaModel m = list[i];
            return _Reveal(
              delayMs: (i.clamp(0, 6)) * 60,
              child: _centered(
                _MediaCard(
                  c: c,
                  m: m,
                  onDelete: () => _onDelete(m),
                  onOpen: (a) => _openViewer(a, m),
                ),
              ),
            );
          },
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _centered(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: child,
        ),
      ),
    );
  }
}

String _kindLabel(AttachKind k) {
  switch (k) {
    case AttachKind.photo:
      return "Photo";
    case AttachKind.video:
      return "Video";
    case AttachKind.file:
      return "File";
  }
}

IconData _kindIcon(AttachKind k) {
  switch (k) {
    case AttachKind.photo:
      return Icons.photo_outlined;
    case AttachKind.video:
      return Icons.videocam_outlined;
    case AttachKind.file:
      return Icons.picture_as_pdf_outlined;
  }
}

ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
  backgroundColor: _C.accent,
  foregroundColor: Colors.black,
  elevation: 0,
  minimumSize: const Size(0, 46),
  textStyle: const TextStyle(fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

// =============================================================================
// HEADER + SEARCH
// =============================================================================
class _Header extends StatelessWidget {
  final ViewMediaGetx c;
  const _Header({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassCard(radius: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.accent.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.accent.withOpacity(.35)),
            ),
            child: const Icon(Icons.perm_media_rounded,
                color: _C.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Shared media",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _C.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Obx(() {
                  if (c.isLoading.value && c.sharedList.isEmpty) {
                    return const Text("Loading media...",
                        style: TextStyle(color: _C.mint, fontSize: 12.5));
                  }
                  return Text(
                    "Showing ${c.filteredList.length} of ${c.sharedList.length}",
                    style: const TextStyle(color: _C.mint, fontSize: 12.5),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget
{
  final ViewMediaGetx c;
  const _SearchField({required this.c});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: c.searchCtrl,
      onChanged: (v) => c.query.value = v,
      style: _fieldText,
      cursorColor: _C.accent,
      decoration: InputDecoration(
        hintText: "Search by media ID, sender ID, receiver ID or description",
        hintMaxLines: 1,
        hintStyle: const TextStyle(
          color: _C.muted,
          fontSize: 13.5,
          overflow: TextOverflow.ellipsis,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: _C.mint),
        suffixIcon: Obx(() => c.query.value.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
          tooltip: "Clear",
          icon: const Icon(Icons.close_rounded, color: _C.muted),
          onPressed: () {
            c.searchCtrl.clear();
            c.query.value = '';
          },
        )),
        filled: true,
        fillColor: _C.bar,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.accent, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.border),
        ),
      ),
    );
  }
}

// =============================================================================
// MEDIA CARD — header with delete, description, people, attachments
// =============================================================================
class _MediaCard extends StatelessWidget {
  final ViewMediaGetx c;
  final SharedMediaModel m;
  final Future<void> Function() onDelete;
  final void Function(MediaAttachment a) onOpen;

  const _MediaCard({
    required this.c,
    required this.m,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final int? id = m.sharedMediaId?.toInt();
    final List<MediaAttachment> atts = c.attachmentsOf(m);

    return Container(
      decoration: _glassCard(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: const BoxDecoration(
              color: _C.bar,
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.accent.withOpacity(.35)),
                  ),
                  child: const Icon(Icons.perm_media_outlined,
                      color: _C.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Media ID: ${c.displayOr(c.idOf(m))}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.formatDate(m.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _mutedSmall,
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final bool busy = id != null && c.deletingIds.contains(id);
                  return _DeleteButton(
                    busy: busy,
                    onTap: (busy || id == null) ? null : onDelete,
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label("Description"),
                const SizedBox(height: 6),
                Text(
                  c.displayOr(m.mediaDescription),
                  style: TextStyle(
                    color: c.descOf(m).isEmpty ? _C.muted : _C.text,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Person(
                        label: "From",
                        name: c.displayOr(m.senderName),
                        number: c.displayOr(c.numText(m.senderNumber)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Person(
                        label: "To",
                        name: c.displayOr(m.receiverName),
                        number: c.displayOr(c.numText(m.receiverNumber)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _Label("Attachments"),
                const SizedBox(height: 8),
                if (atts.isEmpty)
                  Text("No data available", style: _mutedSmall)
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: atts
                        .map((a) => _AttachTile(
                      attachment: a,
                      url: c.urlOf(a),
                      onTap: () => onOpen(a),
                    ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          color: _C.muted,
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700),
    );
  }
}

class _Person extends StatelessWidget {
  final String label;
  final String name;
  final String number;
  const _Person({required this.label, required this.name, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.bar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _C.mint, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.text, fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _mutedSmall),
        ],
      ),
    );
  }
}

class _AttachTile extends StatelessWidget {
  final MediaAttachment attachment;
  final String url;
  final VoidCallback onTap;
  const _AttachTile({
    required this.attachment,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPhoto = attachment.kind == AttachKind.photo;

    Widget preview;
    if (isPhoto && url.isNotEmpty) {
      preview = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, p) => p == null
            ? child
            : const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _C.accent),
          ),
        ),
        errorBuilder: (ctx, e, st) => Icon(_kindIcon(attachment.kind),
            color: _C.muted, size: 30),
      );
    } else {
      preview = Center(
        child: Icon(
          attachment.kind == AttachKind.video
              ? Icons.play_circle_outline_rounded
              : _kindIcon(attachment.kind),
          color: _C.accent,
          size: 36,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 150,
          height: 112,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              preview,
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _kindLabel(attachment.kind),
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
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

class _DeleteButton extends StatelessWidget {
  final bool busy;
  final Future<void> Function()? onTap;
  const _DeleteButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Delete media",
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap == null ? null : () => onTap!(),
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
              : Icon(Icons.delete_outline_rounded,
              color: onTap == null ? _C.danger.withOpacity(.4) : _C.danger,
              size: 21),
        ),
      ),
    );
  }
}

// =============================================================================
// VIEWER PAGE — photo, video, PDF, with normal and fullscreen modes
// =============================================================================
class MediaViewerPage extends StatefulWidget {
  final MediaAttachment attachment;
  final String url;
  final String title;
  final String jwt;

  const MediaViewerPage({
    super.key,
    required this.attachment,
    required this.url,
    required this.title,
    required this.jwt,
  });

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  final String _tag = UniqueKey().toString();
  late final MediaViewerController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(MediaViewerController(), tag: _tag)
      ..init(
        kind: widget.attachment.kind,
        url: widget.url,
        jwt: widget.jwt,
      );
  }

  @override
  void dispose() {
    Get.delete<MediaViewerController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.viewerBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              final bool fs = c.isFullscreen.value;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                    fs ? 0 : 8, fs ? 0 : 72, fs ? 0 : 8, fs ? 0 : 84),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: _content(),
                ),
              );
            }),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Obx(() => c.isFullscreen.value
                ? const SizedBox.shrink()
                : SafeArea(bottom: false, child: _topBar(context))),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Obx(() => c.isFullscreen.value
                ? SafeArea(
              child: _BorderIconButton(
                icon: Icons.fullscreen_exit_rounded,
                tooltip: "Exit full screen",
                onTap: c.toggleFullscreen,
              ),
            )
                : const SizedBox.shrink()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(top: false, child: _bottomBar()),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(.75),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          _BorderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: "Back",
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _C.text, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          _BorderIconButton(
            icon: Icons.fullscreen_rounded,
            tooltip: "Full screen",
            onTap: c.toggleFullscreen,
          ),
        ],
      ),
    );
  }

  Widget _content() {
    switch (widget.attachment.kind) {
      case AttachKind.photo:
        return _photoView();
      case AttachKind.video:
        return _videoView();
      case AttachKind.file:
        return c.isPdf ? _pdfView() : _fileInfo();
    }
  }

  Widget _photoView() {
    return LayoutBuilder(builder: (context, box) {
      c.viewportCenter = Offset(box.maxWidth / 2, box.maxHeight / 2);
      return InteractiveViewer(
        transformationController: c.photoCtrl,
        minScale: 1,
        maxScale: 5,
        child: SizedBox(
          width: box.maxWidth,
          height: box.maxHeight,
          child: Image.network(
            c.url,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, p) => p == null
                ? child
                : const Center(
                child: CircularProgressIndicator(color: _C.accent)),
            errorBuilder: (ctx, e, st) => const _ViewerMessage(
              icon: Icons.broken_image_outlined,
              text: "Image unavailable",
            ),
          ),
        ),
      );
    });
  }

  Widget _videoView() {
    return Obx(() {
      if (c.errorText.value.isNotEmpty) {
        return _ViewerMessage(
          icon: Icons.error_outline_rounded,
          text: c.errorText.value,
          onRetry: c.reopen,
        );
      }
      final vc = c.videoCtrl;
      if (vc == null) {
        return const Center(
          child: CircularProgressIndicator(color: _C.accent),
        );
      }
      return Center(
        child: Video(
          controller: vc,
          controls: NoVideoControls,
          fit: BoxFit.contain,
        ),
      );
    });
  }

  Widget _pdfView() {
    return Obx(() {
      if (c.errorText.value.isNotEmpty) {
        return _ViewerMessage(
          icon: Icons.picture_as_pdf_outlined,
          text: c.errorText.value,
          onRetry: c.reopen,
        );
      }
      final bool horizontal = c.horizontalPdf.value;
      final int reload = c.pdfReload.value;
      return Stack(
        children: [
          LayoutBuilder(builder: (context, box) {
            final bool ok = box.maxWidth.isFinite &&
                box.maxHeight.isFinite &&
                box.maxWidth > 0 &&
                box.maxHeight > 0;
            if (!ok) {
              return const Center(
                child: CircularProgressIndicator(color: _C.accent),
              );
            }
            return SfPdfViewer.network(
              c.url,
              key: ValueKey('pdf_$reload'),
              controller: c.pdfCtrl,
              headers: {"Authorization": "Bearer ${c.jwt}"},
              scrollDirection: horizontal
                  ? PdfScrollDirection.horizontal
                  : PdfScrollDirection.vertical,
              pageLayoutMode: PdfPageLayoutMode.continuous,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              canShowPaginationDialog: false,
              enableDoubleTapZooming: true,
              pageSpacing: 6,
              onDocumentLoaded: c.onPdfLoaded,
              onDocumentLoadFailed: c.onPdfFailed,
              onPageChanged: c.onPdfPageChanged,
            );
          }),
          Obx(() => c.isLoading.value
              ? const Center(
            child: CircularProgressIndicator(color: _C.accent),
          )
              : const SizedBox.shrink()),
        ],
      );
    });
  }

  Widget _fileInfo() {
    return _ViewerMessage(
      icon: Icons.insert_drive_file_outlined,
      text: "${c.fileName.isEmpty ? 'File' : c.fileName}\n"
          "Preview is available for PDF files only.",
      action: OutlinedButton.icon(
        onPressed: () {
          try {
            Clipboard.setData(ClipboardData(text: c.url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File link copied.")),
            );
          } catch (_) {}
        },
        icon: const Icon(Icons.copy_rounded, size: 18),
        label: const Text("Copy file link"),
        style: OutlinedButton.styleFrom(
          foregroundColor: _C.text,
          side: const BorderSide(color: _C.border, width: 1.2),
          minimumSize: const Size(0, 44),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final AttachKind kind = widget.attachment.kind;
    Widget bar;

    if (kind == AttachKind.photo) {
      bar = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BorderIconButton(
            icon: Icons.zoom_out_rounded,
            tooltip: "Zoom out",
            onTap: () => c.zoomPhoto(1 / 1.25),
          ),
          const SizedBox(width: 10),
          _BorderIconButton(
            icon: Icons.zoom_in_rounded,
            tooltip: "Zoom in",
            onTap: () => c.zoomPhoto(1.25),
          ),
          const SizedBox(width: 10),
          _BorderIconButton(
            icon: Icons.center_focus_strong_rounded,
            tooltip: "Reset",
            onTap: c.resetPhoto,
          ),
        ],
      );
    } else if (kind == AttachKind.video) {
      bar = Obx(() {
        final Duration pos = c.position.value;
        final Duration dur = c.duration.value;
        final double maxMs = dur.inMilliseconds <= 0
            ? 1
            : dur.inMilliseconds.toDouble();
        final double curMs =
        pos.inMilliseconds.toDouble().clamp(0, maxMs).toDouble();
        return Row(
          children: [
            _BorderIconButton(
              icon: c.playing.value
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              tooltip: c.playing.value ? "Pause" : "Play",
              onTap: c.playPause,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: _C.accent,
                  inactiveTrackColor: Colors.white.withOpacity(.25),
                  thumbColor: _C.accent,
                ),
                child: Slider(
                  min: 0,
                  max: maxMs,
                  value: curMs,
                  onChanged: c.seekTo,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "${_fmt(pos)} / ${_fmt(dur)}",
              style: const TextStyle(color: _C.muted, fontSize: 12),
            ),
          ],
        );
      });
    } else if (c.isPdf) {
      bar = Obx(() {
        final int pages = c.pdfPages.value;
        return Row(
          children: [
            _BorderIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: "Previous page",
              onTap: c.pdfPrevious,
            ),
            const SizedBox(width: 6),
            Text(
              pages > 0 ? "${c.pdfPage.value} / $pages" : "--",
              style: const TextStyle(
                  color: _C.text, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            _BorderIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: "Next page",
              onTap: c.pdfNext,
            ),
            const Spacer(),
            _BorderIconButton(
              icon: Icons.zoom_out_rounded,
              tooltip: "Zoom out",
              onTap: () => c.zoomPdf(-0.25),
            ),
            const SizedBox(width: 6),
            Text(
              "${(c.zoom.value * 100).round()}%",
              style: const TextStyle(
                  color: _C.mint, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            _BorderIconButton(
              icon: Icons.zoom_in_rounded,
              tooltip: "Zoom in",
              onTap: () => c.zoomPdf(0.25),
            ),
            const SizedBox(width: 6),
            _BorderIconButton(
              icon: c.horizontalPdf.value
                  ? Icons.swap_horiz_rounded
                  : Icons.swap_vert_rounded,
              tooltip: c.horizontalPdf.value
                  ? "Switch to up / down"
                  : "Switch to left / right",
              onTap: c.toggleDirection,
            ),
          ],
        );
      });
    } else {
      bar = const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: bar,
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

class _ViewerMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  final Widget? action;
  const _ViewerMessage({
    required this.icon,
    required this.text,
    this.onRetry,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _C.accent.withOpacity(.8), size: 40),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.muted, fontSize: 13.5, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, color: _C.accent),
                label: const Text("Retry", style: TextStyle(color: _C.accent)),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED PIECES
// =============================================================================
class _Reveal extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _Reveal({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    final int total = 420 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, v, ch) => Opacity(
        opacity: v.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: ch),
      ),
      child: child,
    );
  }
}

class _BorderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _BorderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled ? _C.text : _C.border,
                width: 1.2,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? _C.text : _C.text.withOpacity(.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double h, {double? w}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.06),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: bar(14)),
          ]),
          const SizedBox(height: 16),
          bar(12, w: 220),
          const SizedBox(height: 10),
          bar(12),
          const SizedBox(height: 10),
          bar(12, w: 160),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _Placeholder({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _Reveal(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: _glassCard(radius: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _C.accent.withOpacity(.09),
                          border:
                          Border.all(color: _C.accent.withOpacity(.4)),
                        ),
                        child: Icon(icon,
                            size: 32, color: _C.accent.withOpacity(.9)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _C.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _C.muted, fontSize: 13.5, height: 1.4),
                      ),
                      if (action != null) ...[
                        const SizedBox(height: 16),
                        action!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}