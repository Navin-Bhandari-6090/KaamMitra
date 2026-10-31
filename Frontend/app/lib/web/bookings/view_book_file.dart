import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../state management/getx/booking/view_file_getx.dart';


// Palette

class _C {
  static const Color bg = Color(0xFF0F1F17);
  static const Color surface = Color(0xFF162E22);
  static const Color text = Color(0xFFE6F4EA);
  static const Color muted = Color(0xFF8A9A90);
  static const Color accent = Color(0xFF22C55E);
  static const Color mint = Color(0xFF34D399);
  static const Color border = Color(0xFF234232);
  static const Color borderStrong = Color(0xFF2F5A43);
  static const Color danger = Color(0xFFF87171);
}

// ===========================================================================
// SCREEN
// ===========================================================================
class ViewBookFile extends StatefulWidget {
  final String Current_User_JwtToken;
  final String FilePath;
  const ViewBookFile(
      {super.key, required this.Current_User_JwtToken, required this.FilePath});

  @override
  State<ViewBookFile> createState() => _ViewBookFileState();
}

class _ViewBookFileState extends State<ViewBookFile> {
  late final ViewFileGetx controller;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    All_User_Jwt_Verify(
        Jwt_Token: widget.Current_User_JwtToken, context: context);
    super.initState();
    controller = Get.put(ViewFileGetx(), tag: _tag);
    controller.init(
      jwtToken: widget.Current_User_JwtToken,
      filePath: widget.FilePath,
    );
  }

  @override
  void dispose() {
    Get.delete<ViewFileGetx>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
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
          'View Booking File',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: Obx(() => _BorderIconButton(
              tooltip: 'Download',
              icon: Icons.download_rounded,
              onTap: (controller.hasValidPath.value && !controller.isBusy)
                  ? controller.requestDownload
                  : null,
            )),
          ),
        ],
      ),
      body: ForestBackground(
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SafeArea(
            top: false,
            child: _Body(controller: controller),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// BODY - responsive shell (never overflows, even at tiny sizes)
// ===========================================================================
class _Body extends StatelessWidget {
  final ViewFileGetx controller;
  const _Body({required this.controller});

  static const double _minW = 280;
  static const double _minH = 460;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth.isFinite ? c.maxWidth : 360;
      final double h = c.maxHeight.isFinite ? c.maxHeight : 640;
      final double contentW = math.max(w, _minW);
      final double contentH = math.max(h, _minH);
      final double pad = w < 600 ? 12 : 24;
      final bool compact = h < 560;

      final Widget content = SizedBox(
        width: contentW,
        height: contentH,
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 12),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Obx(() {
                if (!controller.hasValidPath.value) {
                  return const _EmptyState();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Reveal(
                        child:
                        _FileHeader(c: controller, compact: compact)),
                    _DownloadBanner(c: controller),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _Reveal(
                          delayMs: 120, child: _ViewerCard(c: controller)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      );

      // Normal screens: NO outer scroll views at all, so the PDF viewer
      // receives every horizontal / vertical scroll and drag by itself.
      // Outer scrolling is only added when the window is smaller than the
      // minimum layout size.
      if (w >= _minW && h >= _minH) return content;

      Widget scrollable = content;
      if (h < _minH) {
        scrollable = SingleChildScrollView(child: scrollable);
      }
      if (w < _minW) {
        scrollable = SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: scrollable);
      }
      return scrollable;
    });
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
    final int total = 500 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
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
    this.padding = const EdgeInsets.all(12),
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

/// Bordered square icon button (used for the AppBar back arrow too).
class _BorderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _BorderIconButton(
      {required this.icon, required this.tooltip, required this.onTap});

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
                  color: enabled ? _C.borderStrong : _C.border, width: 1.3),
            ),
            child: Icon(icon,
                size: 18,
                color: enabled ? _C.text : _C.text.withOpacity(0.35)),
          ),
        ),
      ),
    );
  }
}

/// Small tool button used inside the toolbar pills.
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
          child: Icon(icon,
              size: 20,
              color: enabled ? _C.text : _C.text.withOpacity(0.3)),
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

// ===========================================================================
// EMPTY STATE
// ===========================================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: _Reveal(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _Glass(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.accent.withOpacity(0.09),
                      border: Border.all(color: _C.accent.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.folder_off_outlined,
                        size: 38, color: _C.accent.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 18),
                  const Text('No data available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _C.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'No file is attached to this booking, so there is nothing to show or download.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _C.muted, fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Go back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.text,
                      side: const BorderSide(color: _C.borderStrong, width: 1.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// FILE HEADER
// ===========================================================================
class _FileHeader extends StatelessWidget {
  final ViewFileGetx c;
  final bool compact;
  const _FileHeader({required this.c, required this.compact});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 8 : 12),
      child: LayoutBuilder(builder: (context, hc) {
        final bool showIcon = hc.maxWidth >= 170;
        return Row(
          children: [
            if (showIcon) ...[
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
                child: Icon(
                  c.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.insert_drive_file_outlined,
                  color: _C.mint,
                  size: compact ? 18 : 22,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => Text(
                    c.fileName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _C.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  )),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Obx(() {
                      final String ext = c.extension.toUpperCase();
                      final String sub = c.viewerLoaded.value
                          ? '$ext  •  ${c.totalPages.value} page${c.totalPages.value == 1 ? '' : 's'}'
                          : '$ext document';
                      return Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _C.mint.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500));
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ===========================================================================
// DOWNLOAD BANNER - progress / success / error / cancelled (all reactive)
// ===========================================================================
class _DownloadBanner extends StatelessWidget {
  final ViewFileGetx c;
  const _DownloadBanner({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final DownloadStatus s = c.status.value;
      Widget body;

      switch (s) {
        case DownloadStatus.downloading:
        case DownloadStatus.saving:
          body = Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s == DownloadStatus.saving
                          ? 'Saving file...'
                          : c.progressKnown.value
                          ? 'Downloading...  ${c.percent}%'
                          : 'Downloading...',
                      style: const TextStyle(
                          color: _C.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: c.progressKnown.value ? c.progress.value : null,
                        color: _C.accent,
                        backgroundColor: _C.border,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: s == DownloadStatus.downloading ? c.requestCancel : null,
                style: TextButton.styleFrom(foregroundColor: _C.danger),
                child: const Text('Cancel'),
              ),
            ],
          );
          break;

        case DownloadStatus.success:
          body = _msgRow(Icons.check_circle_rounded, _C.accent,
              'Downloaded successfully', c);
          break;

        case DownloadStatus.error:
          body = _msgRow(
              Icons.error_outline_rounded,
              _C.danger,
              c.errorText.value.isEmpty
                  ? 'Download failed.'
                  : c.errorText.value,
              c,
              retry: true);
          break;

        case DownloadStatus.cancelled:
          body = _msgRow(
              Icons.cancel_outlined, _C.muted, 'Download cancelled', c);
          break;

        case DownloadStatus.idle:
          body = const SizedBox.shrink();
          break;
      }

      return AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: s == DownloadStatus.idle
              ? const SizedBox(key: ValueKey('idle'), width: double.infinity)
              : Padding(
            key: ValueKey(s),
            padding: const EdgeInsets.only(top: 10),
            child: _Glass(
              radius: 14,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: body,
            ),
          ),
        ),
      );
    });
  }

  Widget _msgRow(IconData icon, Color color, String text, ViewFileGetx c,
      {bool retry = false}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: color == _C.muted ? _C.muted : _C.text, fontSize: 13)),
        ),
        if (retry)
          TextButton(
            onPressed: c.requestDownload,
            style: TextButton.styleFrom(foregroundColor: _C.accent),
            child: const Text('Retry'),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Dismiss',
          onPressed: c.resetStatus,
          icon: const Icon(Icons.close_rounded, size: 18, color: _C.muted),
        ),
      ],
    );
  }
}

// ===========================================================================
// VIEWER CARD  (toolbar + PDF, same proven mechanism as ProviderServiceFile)
// ===========================================================================
class _ViewerCard extends StatelessWidget {
  final ViewFileGetx c;
  const _ViewerCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
      child: c.isPdf ? _PdfDocumentView(c: c) : _NoPreview(c: c),
    );
  }
}

class _PdfDocumentView extends StatefulWidget {
  final ViewFileGetx c;
  const _PdfDocumentView({required this.c});

  @override
  State<_PdfDocumentView> createState() => _PdfDocumentViewState();
}

class _PdfDocumentViewState extends State<_PdfDocumentView>
    with SingleTickerProviderStateMixin {
  final PdfViewerController _pdfController = PdfViewerController();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final PdfViewerCardController _card;
  final String _cardTag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    _card = Get.put(PdfViewerCardController(), tag: _cardTag);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    try {
      _pdfController.dispose();
    } catch (_) {}
    Get.delete<PdfViewerCardController>(tag: _cardTag);
    super.dispose();
  }

  void _retry() {
    _card.retry();
    widget.c.viewerLoaded.value = false;
    widget.c.totalPages.value = 0;
    _fadeController.forward(from: 0);
  }

  void _zoomIn() {
    try {
      _pdfController.zoomLevel = _card.zoomIn();
    } catch (e) {
      debugPrint('zoomIn error: $e');
    }
  }

  void _zoomOut() {
    try {
      _pdfController.zoomLevel = _card.zoomOut();
    } catch (e) {
      debugPrint('zoomOut error: $e');
    }
  }

  void _resetZoom() {
    try {
      _pdfController.zoomLevel = _card.resetZoom();
    } catch (e) {
      debugPrint('resetZoom error: $e');
    }
  }

  /// Move the zoomed page left/right (works even without mouse drag).
  void _panBy(double dx) {
    try {
      final Offset o = _pdfController.scrollOffset;
      final double x = (o.dx + dx).clamp(0.0, double.maxFinite);
      _pdfController.jumpTo(xOffset: x, yOffset: o.dy);
    } catch (e) {
      debugPrint('pan error: $e');
    }
  }

  void _nextPage() {
    try {
      _pdfController.nextPage();
    } catch (_) {}
  }

  void _prevPage() {
    try {
      _pdfController.previousPage();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ViewFileGetx c = widget.c;

    return Column(
      children: [
        _buildToolbar(c),
        Expanded(
          child: LayoutBuilder(
            builder: (context, pdfConstraints) {
              // Never mount SfPdfViewer in a 0 / invalid box.
              final bool hasValidSize = pdfConstraints.maxWidth.isFinite &&
                  pdfConstraints.maxHeight.isFinite &&
                  pdfConstraints.maxWidth > 0 &&
                  pdfConstraints.maxHeight > 0;

              if (!hasValidSize) return const _Spinner();

              return Obx(() {
                if (_card.hasError.value) return _buildError(c);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SfPdfViewer.network(
                          c.fileUrl.value,
                          key: _card.viewerKey.value,
                          controller: _pdfController,
                          headers: c.authHeaders,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                          canShowPaginationDialog: false,
                          enableDoubleTapZooming: true,
                          interactionMode: _card.panMode.value
                              ? PdfInteractionMode.pan
                              : PdfInteractionMode.selection,
                          pageSpacing: 4,
                          onDocumentLoaded: (details) {
                            final int pages = details.document.pages.count;
                            _card.reportLoaded(pages);
                            c.totalPages.value = pages;
                            c.viewerLoaded.value = true;
                          },
                          onDocumentLoadFailed: (details) {
                            _card.reportFailed(details.description);
                            c.viewerLoaded.value = false;
                          },
                          onPageChanged: (d) => _card.reportPage(d.newPageNumber),
                          onZoomLevelChanged: (d) =>
                              _card.reportZoom(d.newZoomLevel),
                        ),
                      ),
                    ),
                    if (!_card.loaded.value)
                      const Positioned.fill(child: _ViewerLoading()),
                  ],
                );
              });
            },
          ),
        ),
      ],
    );
  }

  // ----- toolbar: pages / zoom / download (wraps on small widths) -----
  Widget _buildToolbar(ViewFileGetx c) {
    return Container(
      width: double.infinity,
      color: Colors.black.withOpacity(0.22),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: LayoutBuilder(builder: (context, bc) {
        final bool wide = bc.maxWidth >= 430;

        return Obx(() {
          final bool busy = c.isBusy;
          final bool ready = _card.loaded.value && !_card.hasError.value;
          final double zoom = _card.zoom.value;
          final int page = _card.currentPage.value;
          final int total = _card.totalPages.value;

          final ButtonStyle dlStyle = ElevatedButton.styleFrom(
            backgroundColor: _C.accent,
            foregroundColor: _C.bg,
            disabledBackgroundColor: _C.accent.withOpacity(0.45),
            disabledForegroundColor: _C.bg.withOpacity(0.7),
            minimumSize: const Size(46, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            textStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          );

          final Widget spinner = const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _C.bg));

          final Widget downloadBtn = wide
              ? ElevatedButton.icon(
            onPressed: busy ? null : c.requestDownload,
            icon: busy ? spinner : const Icon(Icons.download_rounded, size: 20),
            label: Text(busy ? 'Downloading...' : 'Download'),
            style: dlStyle,
          )
              : Tooltip(
            message: 'Download',
            child: ElevatedButton(
              onPressed: busy ? null : c.requestDownload,
              style: dlStyle,
              child: busy
                  ? spinner
                  : const Icon(Icons.download_rounded, size: 20),
            ),
          );

          return Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _Pill(children: [
                _MiniBtn(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous page',
                  onTap: (ready && page > 1) ? _prevPage : null,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 56),
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
                  onTap: (ready && page < total) ? _nextPage : null,
                ),
              ]),
              _Pill(children: [
                _MiniBtn(
                  icon: Icons.zoom_out_rounded,
                  tooltip: 'Zoom out',
                  onTap: (ready && zoom > 1.0) ? _zoomOut : null,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48),
                  child: Text(
                    '${(zoom * 100).round()}%',
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
                  onTap: (ready && zoom < 3.0) ? _zoomIn : null,
                ),
                _MiniBtn(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'Reset zoom',
                  onTap: (ready && zoom != 1.0) ? _resetZoom : null,
                ),
              ]),
              _Pill(children: [
                _MiniBtn(
                  icon: Icons.keyboard_arrow_left_rounded,
                  tooltip: 'Move left',
                  onTap: (ready && zoom > 1.0) ? () => _panBy(-160) : null,
                ),
                _MiniBtn(
                  icon: Icons.keyboard_arrow_right_rounded,
                  tooltip: 'Move right',
                  onTap: (ready && zoom > 1.0) ? () => _panBy(160) : null,
                ),
                _MiniBtn(
                  icon: _card.panMode.value
                      ? Icons.pan_tool_alt_rounded
                      : Icons.text_fields_rounded,
                  tooltip: _card.panMode.value
                      ? 'Drag to move (tap for text select)'
                      : 'Text select (tap for drag to move)',
                  onTap: ready ? _card.toggleMode : null,
                ),
              ]),
              downloadBtn,
            ],
          );
        });
      }),
    );
  }

  Widget _buildError(ViewFileGetx c) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 38, color: _C.accent.withOpacity(0.8)),
            const SizedBox(height: 12),
            const Text("Couldn't load the document",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _C.text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Obx(() => Text(_card.errorText.value,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _C.muted, fontSize: 12.5))),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.accent,
                    foregroundColor: _C.bg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: c.requestDownload,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download instead'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.text,
                    side: const BorderSide(color: _C.borderStrong, width: 1.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(_C.accent)),
    ),
  );
}

class _ViewerLoading extends StatelessWidget {
  const _ViewerLoading();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: const Color(0xFF0B1812),
        alignment: Alignment.center,
        child: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_C.accent)),
              ),
              SizedBox(height: 16),
              Text('Loading document...',
                  style: TextStyle(
                      color: _C.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Non-PDF files: no preview, download still works.
class _NoPreview extends StatelessWidget {
  final ViewFileGetx c;
  const _NoPreview({required this.c});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 46, color: _C.accent.withOpacity(0.8)),
            const SizedBox(height: 12),
            const Text('Preview not available',
                style: TextStyle(
                    color: _C.text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('You can still download this file.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _C.muted, fontSize: 13)),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
              onPressed: c.isBusy ? null : c.requestDownload,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.accent,
                foregroundColor: _C.bg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// BACKGROUND
// ===========================================================================

/// Dark forest base + soft emerald/mint ambient blobs + blurred glass bubbles.
/// - Purely decorative: wrapped in IgnorePointer, never blocks taps/text.
/// - Animation is driven by an AnimationController (no setState).
/// - Painted inside a RepaintBoundary so only the background repaints.
class ForestBackground extends StatefulWidget {
  final Widget child;
  const ForestBackground({super.key, required this.child});

  @override
  State<ForestBackground> createState() => _ForestBackgroundState();
}

class _ForestBackgroundState extends State<ForestBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 26))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0F1F17)),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _ForestPainter(_ctrl), size: Size.infinite),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ForestPainter extends CustomPainter {
  final Animation<double> t;
  _ForestPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;

    final double v = Curves.easeInOut.transform(t.value);
    final double rb = math.max(size.shortestSide, 360);

    // ---- Ambient blobs (radial gradients = cheap, very soft, no hard edge) ----
    void blob(double fx, double fy, double radius, Color c, double alpha,
        double dx, double dy) {
      final Offset center = Offset(
        size.width * fx + dx * v * rb * 0.08,
        size.height * fy + dy * v * rb * 0.08,
      );
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      final Paint p = Paint()
        ..shader = RadialGradient(
          colors: [
            c.withOpacity(alpha),
            c.withOpacity(alpha * 0.45),
            c.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, radius, p);
    }

    blob(-0.04, 0.04, rb * 0.80, const Color(0xFF22C55E), 0.22, 1.0, 0.7);
    blob(1.06, 0.32, rb * 0.70, const Color(0xFF34D399), 0.15, -1.0, 0.9);
    blob(0.08, 1.02, rb * 0.85, const Color(0xFF0F766E), 0.26, 0.8, -1.0);
    blob(0.96, 0.96, rb * 0.65, const Color(0xFF22C55E), 0.17, -0.9, -0.6);
    blob(0.50, 0.52, rb * 0.55, const Color(0xFF34D399), 0.05, 0.5, -0.5);

    // ---- Frosted glass bubbles ----
    void bubble(double fx, double fy, double r, double dy, double phase) {
      final double wave = math.sin((v + phase) * math.pi);
      final Offset c = Offset(
        size.width * fx,
        size.height * fy + wave * dy,
      );
      final Rect rect = Rect.fromCircle(center: c, radius: r);

      final Paint fill = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Colors.white.withOpacity(0.12),
            const Color(0xFF34D399).withOpacity(0.05),
            Colors.white.withOpacity(0.015),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
      canvas.drawCircle(c, r, fill);

      final Paint ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withOpacity(0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(c, r, ring);

      final Paint glint = Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(c.translate(-r * 0.35, -r * 0.38), r * 0.14, glint);
    }

    final double u = math.max(size.shortestSide, 320) / 400;
    bubble(0.12, 0.30, 46 * u, 18 * u, 0.0);
    bubble(0.86, 0.14, 30 * u, 14 * u, 0.3);
    bubble(0.92, 0.66, 64 * u, 22 * u, 0.55);
    bubble(0.20, 0.82, 36 * u, 16 * u, 0.8);
    bubble(0.62, 0.92, 22 * u, 10 * u, 0.15);
    bubble(0.05, 0.58, 18 * u, 10 * u, 0.65);
  }

  @override
  bool shouldRepaint(covariant _ForestPainter old) => false; // driven by `repaint`
}