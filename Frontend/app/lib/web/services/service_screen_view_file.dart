import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../models/ProviderServiceFileModel.dart';
import '../../../state management/getx/profile/provider_user/view_file_getx.dart';


class ServiceScreenProviderServiceFile extends StatefulWidget {
  final String User_Email;
  final String User_JwtToken;
  final String User_Role;
  final String Service_Name;
  final String Provider_Email;

  const ServiceScreenProviderServiceFile({
    super.key,
    required this.User_Email,
    required this.User_JwtToken,
    required this.User_Role,
    required this.Service_Name, required this.Provider_Email,
  });

  @override
  State<ServiceScreenProviderServiceFile> createState() => _ServiceScreenProviderServiceFileState();
}

class _ServiceScreenProviderServiceFileState extends State<ServiceScreenProviderServiceFile> {
  // ---------------------------------------------------------------------
  // THEME — dark green
  // ---------------------------------------------------------------------
  static const Color _bg = Color(0xFF07110C);
  static const Color _surface = Color(0xFF0F1D15);
  static const Color _card = Color(0xFF13241A);
  static const Color _green = Color(0xFF00E676);
  static const Color _greenDim = Color(0xFF0C6B3B);

  late final ViewFileGetxCont controller;
  final String _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ViewFileGetxCont(), tag: _tag);
    controller.init(
      email: widget.Provider_Email,
      jwtToken: widget.User_JwtToken,
      serviceName: widget.Service_Name,
    );
  }

  @override
  void dispose() {
    Get.delete<ViewFileGetxCont>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          widget.Service_Name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(
              () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (controller.screenState.value) {
      case ScreenState.checkingSession:
      case ScreenState.loading:
        return _StatusView(
          key: const ValueKey('loading'),
          spinner: true,
          title: "Loading documents...",
          message: "Fetching \"${widget.Service_Name}\" files.",
        );

      case ScreenState.empty:
        return _StatusView(
          key: const ValueKey('empty'),
          icon: Icons.folder_off_outlined,
          title: "No documents found",
          message:
          "No files have been uploaded yet for \"${widget.Service_Name}\".",
          actionLabel: "Refresh",
          onAction: () => controller.GetProviderRegisterService(
            Email: widget.Provider_Email,
            jwttoken: widget.User_JwtToken,
          ),
        );

      case ScreenState.error:
        return _StatusView(
          key: const ValueKey('error'),
          icon: Icons.error_outline_rounded,
          title: "Couldn't load documents",
          message: controller.screenErrorText.value,
          actionLabel: "Retry",
          onAction: () => controller.GetProviderRegisterService(
            Email: widget.Provider_Email,
            jwttoken: widget.User_JwtToken,
          ),
        );

      case ScreenState.loaded:
        return _DocumentListView(
          key: const ValueKey('loaded'),
          files: controller.ProviderRegisterFileList,
          resolveUrl: controller.resolveDocumentUrl,
          jwtToken: widget.User_JwtToken,
        );
    }
  }
}

// ===========================================================================
// STATUS VIEW — shared loading / empty / error UI
// ===========================================================================
class _StatusView extends StatelessWidget {
  static const Color _green = Color(0xFF00E676);

  final IconData? icon;
  final bool spinner;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusView({
    super.key,
    this.icon,
    this.spinner = false,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spinner)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(scale: value, child: child),
                  ),
                  child: const SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(_green),
                    ),
                  ),
                )
              else if (icon != null)
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withOpacity(0.08),
                    border: Border.all(color: _green.withOpacity(0.4), width: 1.5),
                  ),
                  child: Icon(icon, color: _green.withOpacity(0.85), size: 38),
                ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13.5),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: Text(actionLabel!, style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// DOCUMENT LIST — one card per file, service name + ID header,
// PDF sized to 80% width / 80% height, staggered entrance animation.
// ===========================================================================
class _DocumentListView extends StatelessWidget {
  final List<ProviderServiceFileModel> files;
  final String Function(String relativePath) resolveUrl;
  final String jwtToken;

  const _DocumentListView({
    super.key,
    required this.files,
    required this.resolveUrl,
    required this.jwtToken,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + (index * 80).clamp(0, 500)),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: child),
              ),
              child: _ServiceDocumentCard(
                index: index,
                file: file,
                resolveUrl: resolveUrl,
                jwtToken: jwtToken,
                // NOTE: constraints.maxHeight from a LayoutBuilder that wraps
                // a ListView can legitimately be reported as very small or
                // even 0 on the very first layout pass (before the real
                // viewport settles, especially on Flutter Web). We floor
                // both dimensions in the card itself so nothing downstream
                // — especially SfPdfViewer's internal scrollbar math — ever
                // sees a degenerate 0-height/width box.
                screenHeight: constraints.maxHeight,
                screenWidth: constraints.maxWidth,
              ),
            );
          },
        );
      },
    );
  }
}

class _ServiceDocumentCard extends StatelessWidget {
  static const Color _surface = Color(0xFF0F1D15);
  static const Color _card = Color(0xFF13241A);
  static const Color _green = Color(0xFF00E676);
  static const Color _greenDim = Color(0xFF0C6B3B);

  // Hard floors so the PDF viewer box is never asked to render at an
  // invalid/degenerate size, which is what triggers the
  // "Invalid argument: 0" clamp() crash inside SfPdfViewer's scrollbar.
  static const double _minViewerWidth = 260;
  static const double _minViewerHeight = 340;

  final int index;
  final ProviderServiceFileModel file;
  final String Function(String relativePath) resolveUrl;
  final String jwtToken;
  final double screenHeight;
  final double screenWidth;

  const _ServiceDocumentCard({
    required this.index,
    required this.file,
    required this.resolveUrl,
    required this.jwtToken,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final String docPath = file.serviceDocument ?? '';
    final String url = docPath.isEmpty ? '' : resolveUrl(docPath);

    // 80% width / 80% height of the available viewport, per spec — but
    // never below the floor, and never NaN/negative if the incoming
    // constraints happen to be 0 or unbounded-turned-0.
    final double safeScreenWidth =
    screenWidth.isFinite && screenWidth > 0 ? screenWidth : _minViewerWidth;
    final double safeScreenHeight =
    screenHeight.isFinite && screenHeight > 0 ? screenHeight : _minViewerHeight;

    final double viewerWidth =
    math.max(safeScreenWidth * 0.8, _minViewerWidth);
    final double viewerHeight =
    math.max(safeScreenHeight * 0.8, _minViewerHeight);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _greenDim.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Header: service name + service ID ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                bottom: BorderSide(color: _greenDim.withOpacity(0.35)),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, headerConstraints) {
                // If the header itself ever gets squeezed narrower than the
                // fixed-size icon + its spacing, drop the icon instead of
                // overflowing (matches the fix applied to the video screen).
                final bool showIcon = headerConstraints.maxWidth >= 140;

                return Row(
                  children: [
                    if (showIcon) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _green.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.picture_as_pdf_outlined,
                            color: _green, size: 20),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.serviceName ?? 'Unknown Service',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Service ID: ${file.providerServiceId ?? '-'}',
                            style: TextStyle(
                              color: _green.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // --- PDF viewer, 80% width x 80% height (floored) ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: viewerWidth,
                height: viewerHeight,
                child: docPath.isEmpty
                    ? const _InlineMessage(text: "No document path returned for this file.")
                    : _PdfDocumentView(
                  cardTag: 'pdf_card_${index}_${file.providerServiceId}',
                  url: url,
                  jwtToken: jwtToken,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String text;
  const _InlineMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
      ),
    );
  }
}

// ===========================================================================
// PDF VIEWER — loads from network URL, zoom in/out, fade-in, error/retry.
//
// The whole widget is wrapped in an inner LayoutBuilder. SfPdfViewer's
// desktop scrollbar computes a clamp() over the viewer's own render box
// size; if that box is ever 0 (or otherwise degenerate) — which can happen
// for a frame or two while a parent's real constraints are still settling,
// especially on Flutter Web — that clamp() throws "Invalid argument: 0".
// We simply refuse to mount SfPdfViewer until the box we've actually been
// given has a valid, positive size, showing a small "Preparing viewer..."
// placeholder in the meantime. LayoutBuilder rebuilds automatically once
// real constraints arrive, so this resolves itself within a frame or two
// with no extra plumbing required.
//
// Ephemeral per-card state (zoom / error / page count / reload key) lives
// in a tagged PdfViewerCardController — this is the only setState() that
// existed in the original file, now converted to GetX like everything else.
// ===========================================================================
class _PdfDocumentView extends StatefulWidget {
  final String cardTag;
  final String url;
  final String jwtToken;
  const _PdfDocumentView({required this.cardTag, required this.url, required this.jwtToken});

  @override
  State<_PdfDocumentView> createState() => _PdfDocumentViewState();
}

class _PdfDocumentViewState extends State<_PdfDocumentView>
    with SingleTickerProviderStateMixin {
  static const Color _surface = Color(0xFF0F1D15);
  static const Color _bg = Color(0xFF07110C);
  static const Color _green = Color(0xFF00E676);

  final PdfViewerController _pdfController = PdfViewerController();
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final PdfViewerCardController _cardController;

  @override
  void initState() {
    super.initState();
    _cardController = Get.put(PdfViewerCardController(), tag: widget.cardTag);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pdfController.dispose();
    Get.delete<PdfViewerCardController>(tag: widget.cardTag);
    super.dispose();
  }

  void _retry() {
    _cardController.retry();
    _fadeController.forward(from: 0);
  }

  void _zoomIn() {
    final next = _cardController.zoomIn();
    _pdfController.zoomLevel = next;
  }

  void _zoomOut() {
    final next = _cardController.zoomOut();
    _pdfController.zoomLevel = next;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Mini toolbar
          Container(
            color: _surface,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Obx(() {
              final totalPages = _cardController.totalPages.value;
              final zoom = _cardController.zoom.value;
              final hasError = _cardController.hasError.value;
              return Row(
                children: [
                  if (totalPages > 0)
                    Text(
                      "$totalPages page${totalPages == 1 ? '' : 's'}",
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                    ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: "Zoom out",
                    icon: const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                    onPressed: hasError ? null : _zoomOut,
                  ),
                  Text(
                    "${(zoom * 100).round()}%",
                    style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: "Zoom in",
                    icon: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    onPressed: hasError ? null : _zoomIn,
                  ),
                ],
              );
            }),
          ),
          // Viewer / error body — guarded against zero/invalid size.
          Expanded(
            child: LayoutBuilder(
              builder: (context, pdfConstraints) {
                final bool hasValidSize = pdfConstraints.maxWidth.isFinite &&
                    pdfConstraints.maxHeight.isFinite &&
                    pdfConstraints.maxWidth > 0 &&
                    pdfConstraints.maxHeight > 0;

                if (!hasValidSize) {
                  // Don't mount SfPdfViewer with a degenerate box — this is
                  // what causes the desktop scrollbar's clamp() to throw
                  // "Invalid argument: 0". Show a lightweight placeholder
                  // until real constraints arrive.
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(_green),
                      ),
                    ),
                  );
                }

                return Obx(() {
                  if (_cardController.hasError.value) {
                    return _buildError();
                  }

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SfPdfViewer.network(
                      widget.url,
                      key: _cardController.viewerKey.value,
                      controller: _pdfController,
                      headers: {"Authorization": "Bearer ${widget.jwtToken}"},
                      canShowScrollHead: true,
                      canShowScrollStatus: true,
                      canShowPaginationDialog: false,
                      enableDoubleTapZooming: true,
                      pageSpacing: 4,
                      onDocumentLoaded: (details) {
                        _cardController.reportLoaded(details.document.pages.count);
                      },
                      onDocumentLoadFailed: (details) {
                        _cardController.reportFailed(details.description);
                      },
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: _green.withOpacity(0.7), size: 30),
            const SizedBox(height: 10),
            Obx(() => Text(
              _cardController.errorText.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5),
            )),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh, color: _green, size: 18),
              label: const Text("Retry", style: TextStyle(color: _green)),
            ),
          ],
        ),
      ),
    );
  }
}