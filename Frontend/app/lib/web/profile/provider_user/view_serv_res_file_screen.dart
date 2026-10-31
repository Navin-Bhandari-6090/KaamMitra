import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../models/ServResourFileInfoModel.dart';
import '../../../state management/getx/profile/provider_user/view_ser_res_file_info_getx.dart';
import '../../../web/common method/Commmon_Method.dart';
import '../../bookings/view_book_file.dart';

// TODO: import ForestBackground from your booking viewer file, e.g.
// import 'package:app/.../view_book_file.dart' show ForestBackground;


// PALETTE

class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color borderStrong = Color(0xFF2F5A43);
}

// ===========================================================================
// SCREEN
// ===========================================================================
class ViewServResFileScreen extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String Service_Name;

  const ViewServResFileScreen({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.Service_Name,
  });

  @override
  State<ViewServResFileScreen> createState() => _ViewServResFileScreenState();
}

class _ViewServResFileScreenState extends State<ViewServResFileScreen> {
  late final ViewSerResFileInfoGetx ctrl;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    Provider_Jwt_Verify(Jwt_Token: widget.User_JwtToken, context: context);
    super.initState();
    ctrl = Get.put(ViewSerResFileInfoGetx(), tag: _tag);
    ctrl.init(jwtToken: widget.User_JwtToken);

    // Load the files as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFiles();
    });
  }

  @override
  void dispose() {
    Get.delete<ViewSerResFileInfoGetx>(tag: _tag);
    super.dispose();
  }

  Future<void> _loadFiles() async {
    try {
      await ctrl.GetServiceResourcesFileInfo(
        Email: widget.User_Email,
        ServiceName: widget.Service_Name,
        jwttoken: widget.User_JwtToken,
      );
    } catch (e) {
      debugPrint('load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _BorderIconButton(
            tooltip: 'Back',
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const Text(
          'Service Resources',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ForestBackground(
        child: SafeArea(
          top: false,
          child: Obx(() {
            final bool full =
                ctrl.isFullscreen.value && ctrl.selected.value != null;

            // Fullscreen replaces the layout, so only one PDF viewer mounts.
            if (full) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: _ViewerPane(c: ctrl, fullscreen: true),
              );
            }

            return LayoutBuilder(builder: (context, box) {
              final double w = box.maxWidth.isFinite ? box.maxWidth : 900;
              final double h = box.maxHeight.isFinite ? box.maxHeight : 700;
              final bool wide = w >= 900;
              final double pad = w < 600 ? 12 : 20;

              if (wide) {
                return Padding(
                  padding: EdgeInsets.all(pad),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 360,
                        child: _ListPanel(
                          c: ctrl,
                          serviceName: widget.Service_Name,
                          onLoad: _loadFiles,
                          fixedListHeight: null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _ViewerPane(c: ctrl)),
                    ],
                  ),
                );
              }

              // Phone / narrow: whole panel scrolls, list has fixed height.
              final double listH = math.max(300.0, h * 0.72);
              return SingleChildScrollView(
                padding: EdgeInsets.all(pad),
                physics: const BouncingScrollPhysics(),
                child: _ListPanel(
                  c: ctrl,
                  serviceName: widget.Service_Name,
                  onLoad: _loadFiles,
                  fixedListHeight: listH,
                ),
              );
            });
          }),
        ),
      ),
    );
  }
}

// ===========================================================================
// LIST PANEL
// ===========================================================================
class _ListPanel extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  final String serviceName;
  final Future<void> Function() onLoad;

  /// null = fill available height (wide). value = fixed height (narrow).
  final double? fixedListHeight;

  const _ListPanel({
    required this.c,
    required this.serviceName,
    required this.onLoad,
    required this.fixedListHeight,
  });

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.height < 520;

    final Widget header = _Reveal(
      child: _HeaderCard(
        c: c,
        serviceName: serviceName,
        onLoad: onLoad,
        compact: compact,
      ),
    );
    const Widget gap = SizedBox(height: 12);
    final Widget search = _Reveal(delayMs: 80, child: _SearchField(c: c));

    if (fixedListHeight == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          gap,
          search,
          gap,
          Expanded(child: _FileList(c: c)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        gap,
        search,
        gap,
        SizedBox(height: fixedListHeight, child: _FileList(c: c)),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  final String serviceName;
  final Future<void> Function() onLoad;
  final bool compact;

  const _HeaderCard({
    required this.c,
    required this.serviceName,
    required this.onLoad,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 8 : 12),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _C.accent.withOpacity(0.28),
                _C.mint.withOpacity(0.10),
              ]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.accent.withOpacity(0.45)),
            ),
            child: Icon(Icons.folder_copy_outlined,
                color: _C.mint, size: compact ? 18 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Resource Files',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _C.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(c.displayOr(serviceName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _C.mint.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.accent.withOpacity(0.35)),
            ),
            child: Text('${c.items.length}',
                style: const TextStyle(
                    color: _C.mint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          )),
          const SizedBox(width: 8),
          Obx(() => _BorderIconButton(
            tooltip: 'Load files',
            icon: Icons.refresh_rounded,
            onTap: c.isLoading.value ? null : () => onLoad(),
          )),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  const _SearchField({required this.c});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: TextField(
        controller: c.searchCtrl,
        onChanged: (v) => c.query.value = v,
        cursorColor: _C.accent,
        style: const TextStyle(color: _C.text, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search by resource ID or title',
          hintStyle: const TextStyle(color: _C.muted, fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.mint),
          suffixIcon: Obx(() => c.query.value.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.close_rounded, color: _C.muted),
            onPressed: () {
              c.searchCtrl.clear();
              c.query.value = '';
            },
          )),
        ),
      ),
    );
  }
}

class _FileList extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  const _FileList({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoading.value) return const _Loader();

      final list = c.filtered;
      if (list.isEmpty) {
        return _Placeholder(
          icon: Icons.folder_off_outlined,
          title: 'No data available',
          message: c.items.isEmpty
              ? 'Tap refresh to load this service\'s resource files.'
              : 'No file matches your search.',
        );
      }

      return ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _Reveal(
          delayMs: math.min(i, 6) * 60,
          child: _FileCard(c: c, f: list[i]),
        ),
      );
    });
  }
}

class _FileCard extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  final ServResourFileInfoModel f;

  const _FileCard({required this.c, required this.f});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sel = c.selected.value;
      final bool isSel = sel != null && c.isSameFile(sel, f);
      final bool hasFile = c.urlOf(f).isNotEmpty;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: isSel
              ? _C.accent.withOpacity(0.10)
              : _C.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? _C.accent.withOpacity(0.7) : _C.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: hasFile
                ? () => c.selectFile(f, openFullscreen: _isNarrow(context))
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _FileBadge(ext: c.extOf(f)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.displayOr(c.titleOf(f)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _C.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Chip(
                              icon: Icons.tag_rounded,
                              label:
                              'Resource ID: ${c.displayOr(c.idOf(f))}',
                            ),
                            _Chip(
                              icon: Icons.link_rounded,
                              label:
                              'Service ID: ${c.displayOr(c.providerServiceIdOf(f))}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isSel
                        ? Icons.visibility_rounded
                        : Icons.chevron_right_rounded,
                    color: isSel ? _C.accent : _C.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Phones open the viewer fullscreen. Wide screens use the split view.
  bool _isNarrow(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _C.accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.accent.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _C.mint),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _C.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileBadge extends StatelessWidget {
  final String ext;
  const _FileBadge({required this.ext});

  @override
  Widget build(BuildContext context) {
    final bool pdf = ext == 'pdf';
    final bool img = const ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _C.accent.withOpacity(0.28),
          _C.mint.withOpacity(0.10),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.accent.withOpacity(0.45)),
      ),
      child: Icon(
        pdf
            ? Icons.picture_as_pdf_outlined
            : img
            ? Icons.image_outlined
            : Icons.insert_drive_file_outlined,
        color: _C.mint,
        size: 22,
      ),
    );
  }
}

// ===========================================================================
// VIEWER PANE (split view + fullscreen)
// ===========================================================================
class _ViewerPane extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  final bool fullscreen;
  const _ViewerPane({required this.c, this.fullscreen = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: fullscreen
          ? BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      )
          : BoxDecoration(
        color: _C.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ViewerHeader(c: c, fullscreen: fullscreen),
          _Toolbar(c: c),
          Expanded(child: _ViewerBody(c: c)),
        ],
      ),
    );
  }
}

class _ViewerHeader extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  final bool fullscreen;
  const _ViewerHeader({required this.c, required this.fullscreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(fullscreen ? 12 : 14, 10, 10, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Obx(() {
        final f = c.selected.value;
        final String ext = f == null ? '' : c.extOf(f);
        final int pages = c.totalPages.value;

        final String sub = f == null
            ? 'Preview'
            : (c.isPdf(f) && c.viewerReady.value)
            ? '${ext.toUpperCase()}  •  $pages page${pages == 1 ? '' : 's'}'
            : c.displayOr(ext.isEmpty ? '' : ext.toUpperCase());

        return Row(
          children: [
            if (fullscreen) ...[
              _BorderIconButton(
                tooltip: 'Close',
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: c.exitFullscreen,
              ),
              const SizedBox(width: 12),
            ] else ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility_outlined,
                    size: 18, color: _C.mint),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f == null ? 'Preview' : c.displayOr(c.titleOf(f)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _C.mint.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (!fullscreen)
              _BorderIconButton(
                tooltip: 'Full screen',
                icon: Icons.open_in_full_rounded,
                onTap: c.openFullscreen,
              ),
          ],
        );
      }),
    );
  }
}

/// Toolbar scrolls sideways instead of wrapping, so it never grows taller.
class _Toolbar extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  const _Toolbar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final f = c.selected.value;
      if (f == null) return const SizedBox.shrink();

      final bool pdf = c.isPdf(f);
      final bool img = c.isImage(f);
      final bool ready = pdf ? c.viewerReady.value : true;
      final bool canZoom = (pdf || img) && ready;
      final double z = c.zoom.value;
      final int page = c.currentPage.value;
      final int total = c.totalPages.value;

      if (!canZoom) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        color: Colors.black.withOpacity(0.22),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (pdf)
                _Pill(children: [
                  _MiniBtn(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Previous page',
                    onTap: (ready && page > 1) ? c.prevPage : null,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 52),
                    child: Text(
                      ready ? '$page / $total' : '- / -',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: _C.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  _MiniBtn(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Next page',
                    onTap: (ready && page < total) ? c.nextPage : null,
                  ),
                ]),
              const SizedBox(width: 8),
              _Pill(children: [
                _MiniBtn(
                  icon: Icons.zoom_out_rounded,
                  tooltip: 'Zoom out',
                  onTap: z > 1.0 ? c.zoomOut : null,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 46),
                  child: Text(
                    '${(z * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _C.mint,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                _MiniBtn(
                  icon: Icons.zoom_in_rounded,
                  tooltip: 'Zoom in',
                  onTap: z < 3.0 ? c.zoomIn : null,
                ),
                _MiniBtn(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'Reset zoom',
                  onTap: z != 1.0 ? c.resetZoom : null,
                ),
              ]),
              if (pdf) ...[
                const SizedBox(width: 8),
                _Pill(children: [
                  _MiniBtn(
                    icon: Icons.keyboard_arrow_left_rounded,
                    tooltip: 'Move left',
                    onTap: z > 1.0 ? () => c.panBy(-160) : null,
                  ),
                  _MiniBtn(
                    icon: Icons.keyboard_arrow_right_rounded,
                    tooltip: 'Move right',
                    onTap: z > 1.0 ? () => c.panBy(160) : null,
                  ),
                  _MiniBtn(
                    icon: c.panMode.value
                        ? Icons.pan_tool_alt_rounded
                        : Icons.text_fields_rounded,
                    tooltip: c.panMode.value
                        ? 'Drag to move (tap for text select)'
                        : 'Text select (tap for drag)',
                    onTap: ready ? c.togglePanMode : null,
                  ),
                ]),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _ViewerBody extends StatelessWidget {
  final ViewSerResFileInfoGetx c;
  const _ViewerBody({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final f = c.selected.value;

      if (f == null) {
        return _Placeholder(
          icon: Icons.touch_app_outlined,
          title: c.items.isEmpty ? 'No data available' : 'Select a file',
          message: c.items.isEmpty
              ? 'Load the resource files to preview them here.'
              : 'Tap any file from the list to preview it here.',
        );
      }

      final String url = c.urlOf(f);
      if (url.isEmpty) {
        return const _Placeholder(
          icon: Icons.folder_off_outlined,
          title: 'No data available',
          message: 'This resource has no file attached.',
        );
      }

      if (c.isPdf(f)) {
        if (c.viewerError.value.isNotEmpty) {
          return _ErrorView(
            title: "Couldn't load the document",
            message: c.viewerError.value,
            onRetry: c.retryViewer,
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: SfPdfViewer.network(
                url,
                key: c.viewerKey.value,
                controller: c.pdfController,
                headers: c.authHeaders,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                canShowPaginationDialog: false,
                enableDoubleTapZooming: true,
                pageSpacing: 6,
                interactionMode: c.panMode.value
                    ? PdfInteractionMode.pan
                    : PdfInteractionMode.selection,
                onDocumentLoaded: (d) => c.onPdfLoaded(d.document.pages.count),
                onDocumentLoadFailed: (d) => c.onPdfFailed(d.description),
                onPageChanged: (d) => c.onPageChanged(d.newPageNumber),
                onZoomLevelChanged: (d) => c.onZoomChanged(d.newZoomLevel),
              ),
            ),
            if (!c.viewerReady.value)
              const Positioned.fill(child: IgnorePointer(child: _Loading())),
          ],
        );
      }

      if (c.isImage(f)) {
        return InteractiveViewer(
          transformationController: c.imageTc,
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(
              url,
              headers: c.authHeaders,
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : const _Loading(),
              errorBuilder: (ctx, e, st) => const _ErrorView(
                title: "Couldn't load the image",
                message: 'The image could not be displayed.',
              ),
            ),
          ),
        );
      }

      return const _Placeholder(
        icon: Icons.insert_drive_file_outlined,
        title: 'Preview not available',
        message: 'This file type cannot be previewed here.',
      );
    });
  }
}

class _ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _Placeholder(
      icon: Icons.wifi_off_rounded,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.accent,
          foregroundColor: _C.bg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ===========================================================================
// REUSABLE PIECES
// ===========================================================================

/// Fade + slide-up entrance.
class _Reveal extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _Reveal({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    final int total = 480 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Frosted-glass container.
class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bordered square icon button (back arrow uses primary text color).
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
        color: Colors.white.withOpacity(0.05),
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
                color: enabled ? _C.borderStrong : _C.border,
                width: 1.3,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? _C.text : _C.text.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _MiniBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? _C.text : _C.text.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final List<Widget> children;
  const _Pill({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Empty / null / error state. Used for "No data available" everywhere.
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
            child: _Glass(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.accent.withOpacity(0.09),
                      border: Border.all(color: _C.accent.withOpacity(0.4)),
                    ),
                    child: Icon(icon,
                        size: 32, color: _C.accent.withOpacity(0.9)),
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
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 26,
      height: 26,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(_C.accent),
      ),
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1812),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_C.accent),
            ),
          ),
          SizedBox(height: 16),
          Text('Loading document...',
              style: TextStyle(
                  color: _C.text, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}