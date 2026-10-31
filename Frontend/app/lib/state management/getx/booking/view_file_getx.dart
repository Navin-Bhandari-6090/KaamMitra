import 'dart:async';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// TODO: adjust the relative path to where your constant folder is.
import '../../../constant/Server_Database.dart'; // Backend_Server_Url

/// idle -> downloading -> saving -> success | error | cancelled
enum DownloadStatus { idle, downloading, saving, success, error, cancelled }

class ViewFileGetx extends GetxController {
  // ---------------- Reactive state (zero setState) ----------------
  final Rx<DownloadStatus> status = DownloadStatus.idle.obs;
  final RxDouble progress = 0.0.obs; // 0..1
  final RxBool progressKnown = false.obs; // false => indeterminate bar
  final RxInt receivedBytes = 0.obs;
  final RxInt totalBytes = 0.obs;
  final RxString errorText = ''.obs;
  final RxBool hasValidPath = false.obs;
  final RxString fileUrl = ''.obs;
  final RxString fileName = ''.obs; // with extension, for display

  String _jwtToken = '';
  String _baseName = 'file';
  String _extension = 'pdf';

  http.Client? _client;
  bool _cancelRequested = false;

  static const Duration _timeout = Duration(seconds: 30);

  // ---------------- Info used by the view ----------------
  // Mirrored from the PDF viewer so the header can show the page count.
  final RxBool viewerLoaded = false.obs;
  final RxInt totalPages = 0.obs;
  String get extension => _extension;
  bool get isPdf => _extension == 'pdf';
  Map<String, String> get authHeaders => _jwtToken.isEmpty
      ? <String, String>{}
      : {'Authorization': 'Bearer $_jwtToken'};

  // ---------------- Computed ----------------
  bool get isBusy =>
      status.value == DownloadStatus.downloading ||
          status.value == DownloadStatus.saving;

  int get percent => (progress.value * 100).clamp(0, 100).round();

  // ---------------- Init ----------------
  /// Call once from the screen right after Get.put(...).
  void init({required String jwtToken, required String? filePath}) {
    try {
      _jwtToken = jwtToken;
      final String path = (filePath ?? '').trim();

      if (path.isEmpty || path.toLowerCase() == 'null') {
        hasValidPath.value = false;
        fileUrl.value = '';
        fileName.value = '';
        return;
      }

      fileUrl.value = _resolveUrl(path);
      _parseFileName(path);
      hasValidPath.value = true;
    } catch (e) {
      debugPrint('ViewFileGetx.init error: $e');
      hasValidPath.value = false;
      fileUrl.value = '';
    }
  }

  /// "/uploads/booking/file/x.pdf" + Backend_Server_Url => full url.
  /// Safe for leading/trailing slashes and already-absolute urls.
  String _resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    String base = Backend_Server_Url;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    final String rel = path.startsWith('/') ? path : '/$path';
    return '$base$rel';
  }

  void _parseFileName(String path) {
    String last = path.split('?').first.split('/').last;
    try {
      last = Uri.decodeComponent(last);
    } catch (_) {}
    if (last.isEmpty) last = 'file.pdf';

    final int dot = last.lastIndexOf('.');
    if (dot > 0 && dot < last.length - 1) {
      _baseName = last.substring(0, dot);
      _extension = last.substring(dot + 1).toLowerCase();
    } else {
      _baseName = last;
      _extension = 'pdf';
    }
    fileName.value = '$_baseName.$_extension';
  }

  MimeType _mimeFor(String ext) {
    switch (ext) {
      case 'pdf':
        return MimeType.pdf;
      case 'png':
        return MimeType.png;
      case 'jpg':
      case 'jpeg':
        return MimeType.jpeg;
      default:
        return MimeType.other;
    }
  }

  // ---------------- Public actions (called by UI) ----------------

  /// Step A: ask the user to confirm. Step B: run the download.
  Future<void> requestDownload() async {
    try {
      if (isBusy) return;

      if (!hasValidPath.value) {
        _toast('No file available', 'There is no file to download.');
        return;
      }

      final bool? confirmed = await _confirmDialog(
        title: 'Download file?',
        message: 'Do you want to download "${fileName.value}"?',
        confirmLabel: 'Download',
        cancelLabel: 'Cancel',
        icon: Icons.download_rounded,
      );

      if (confirmed == true) {
        await _startDownload();
      }
    } catch (e) {
      debugPrint('requestDownload error: $e');
      _fail('Something went wrong. Please try again.');
    }
  }

  /// Ask before cancelling a running download.
  Future<void> requestCancel() async {
    try {
      if (!isBusy) return;
      final bool? confirmed = await _confirmDialog(
        title: 'Cancel download?',
        message: 'The download is in progress. Stop it now?',
        confirmLabel: 'Stop download',
        cancelLabel: 'Keep downloading',
        icon: Icons.cancel_outlined,
      );
      if (confirmed == true) _cancelNow();
    } catch (e) {
      debugPrint('requestCancel error: $e');
    }
  }

  /// Reset after success/error/cancel so the button is usable again.
  void resetStatus() {
    if (isBusy) return;
    status.value = DownloadStatus.idle;
    progress.value = 0;
    receivedBytes.value = 0;
    totalBytes.value = 0;
    errorText.value = '';
  }

  // ---------------- Core download logic ----------------
  Future<void> _startDownload() async {
    if (isBusy) return;

    _cancelRequested = false;
    receivedBytes.value = 0;
    totalBytes.value = 0;
    progress.value = 0;
    progressKnown.value = false;
    errorText.value = '';
    status.value = DownloadStatus.downloading;

    final http.Client client = http.Client();
    _client = client;

    try {
      final request = http.Request('GET', Uri.parse(fileUrl.value));
      if (_jwtToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_jwtToken';
      }

      final http.StreamedResponse response =
      await client.send(request).timeout(_timeout);

      if (response.statusCode != 200) {
        _fail(_messageForStatus(response.statusCode));
        return;
      }

      final int total = response.contentLength ?? 0;
      totalBytes.value = total;
      progressKnown.value = total > 0;

      final BytesBuilder builder = BytesBuilder(copy: false);

      await for (final List<int> chunk in response.stream) {
        if (_cancelRequested) break;
        builder.add(chunk);
        receivedBytes.value += chunk.length;
        if (total > 0) {
          progress.value = (receivedBytes.value / total).clamp(0.0, 1.0);
        }
      }

      if (_cancelRequested) {
        status.value = DownloadStatus.cancelled;
        return;
      }

      final Uint8List bytes = builder.takeBytes();
      if (bytes.isEmpty) {
        _fail('The file is empty.');
        return;
      }

      progress.value = 1.0;
      progressKnown.value = true;
      status.value = DownloadStatus.saving;

      await FileSaver.instance.saveFile(
        name: _baseName,
        bytes: bytes,
        fileExtension: _extension,
        mimeType: _mimeFor(_extension),
      );

      if (isClosed) return;
      status.value = DownloadStatus.success;
      _toast('Download complete', '"${fileName.value}" was saved.');
    } on TimeoutException {
      _fail('The server took too long to respond.');
    } on http.ClientException catch (e) {
      // client.close() during a cancel also lands here.
      if (_cancelRequested) {
        status.value = DownloadStatus.cancelled;
      } else {
        debugPrint('Download ClientException: $e');
        _fail('Network error. Check your connection (or server CORS).');
      }
    } catch (e, st) {
      debugPrint('Download error: $e\n$st');
      if (_cancelRequested) {
        status.value = DownloadStatus.cancelled;
      } else {
        _fail('Download failed. Please try again.');
      }
    } finally {
      try {
        client.close();
      } catch (_) {}
      _client = null;
    }
  }

  void _cancelNow() {
    _cancelRequested = true;
    try {
      _client?.close(); // aborts the in-flight request
    } catch (_) {}
    if (status.value == DownloadStatus.downloading) {
      status.value = DownloadStatus.cancelled;
    }
  }

  // ---------------- Helpers ----------------
  void _fail(String message) {
    if (isClosed) return;
    errorText.value = message;
    status.value = DownloadStatus.error;
    _toast('Download failed', message);
  }

  String _messageForStatus(int code) {
    switch (code) {
      case 401:
      case 403:
        return 'Session expired or access denied ($code).';
      case 404:
        return 'File not found on the server (404).';
      case 500:
        return 'Server error (500). Try again later.';
      default:
        return 'Download failed (HTTP $code).';
    }
  }

  void _toast(String title, String message) {
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF162E22),
        colorText: const Color(0xFFE6F4EA),
        borderColor: const Color(0xFF234232),
        borderWidth: 1,
        margin: const EdgeInsets.all(16),
        maxWidth: 420,
        duration: const Duration(seconds: 3),
      );
    } catch (_) {}
  }

  /// Themed confirm/cancel dialog (visual polish comes in later steps).
  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required IconData icon,
  }) {
    const Color surface = Color(0xFF162E22);
    const Color border = Color(0xFF234232);
    const Color text = Color(0xFFE6F4EA);
    const Color muted = Color(0xFF8A9A90);
    const Color accent = Color(0xFF22C55E);

    return Get.dialog<bool>(
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accent, size: 38),
                    const SizedBox(height: 12),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: muted, fontSize: 14)),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: () => Get.back(result: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: text,
                            side: const BorderSide(color: border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(cancelLabel),
                        ),
                        ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: const Color(0xFF0F1F17),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(confirmLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    _cancelRequested = true;
    try {
      _client?.close();
    } catch (_) {}
    super.onClose();
  }
}


// ===========================================================================
// Per-viewer PDF state (zoom / pages / error / reload key).
// Same pattern as your working ProviderServiceFile screen
// (PdfViewerCardController), plus page + loaded tracking.
// ===========================================================================
class PdfViewerCardController extends GetxController {
  final RxBool hasError = false.obs;
  final RxString errorText = "Failed to load this document.".obs;
  final RxBool loaded = false.obs;
  final RxInt totalPages = 0.obs;
  final RxInt currentPage = 1.obs;
  final RxDouble zoom = 1.0.obs;
  final Rx<Key> viewerKey = UniqueKey().obs;
  final RxBool panMode = true.obs; // true = drag to move, false = select text

  void toggleMode() => panMode.value = !panMode.value;

  void retry() {
    hasError.value = false;
    loaded.value = false;
    totalPages.value = 0;
    currentPage.value = 1;
    zoom.value = 1.0;
    viewerKey.value = UniqueKey(); // forces SfPdfViewer to reload the network URL
  }

  void reportLoaded(int pages) {
    totalPages.value = pages;
    currentPage.value = 1;
    loaded.value = true;
    hasError.value = false;
  }

  void reportFailed(String description) {
    loaded.value = false;
    hasError.value = true;
    errorText.value =
    description.isNotEmpty ? description : "Failed to load this document.";
  }

  void reportPage(int page) => currentPage.value = page;

  /// Keeps the % label in sync with pinch / double-tap zoom.
  void reportZoom(double z) => zoom.value = z.clamp(1.0, 3.0);

  double zoomIn() {
    zoom.value = (zoom.value + 0.25).clamp(1.0, 3.0);
    return zoom.value;
  }

  double zoomOut() {
    zoom.value = (zoom.value - 0.25).clamp(1.0, 3.0);
    return zoom.value;
  }

  double resetZoom() {
    zoom.value = 1.0;
    return zoom.value;
  }
}