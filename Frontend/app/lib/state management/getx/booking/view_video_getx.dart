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

class ViewVideoGetx extends GetxController {
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
  String _baseName = 'video';
  String _extension = 'mp4';

  http.Client? _client;
  bool _cancelRequested = false;

  static const Duration _timeout = Duration(seconds: 30);

  // ---------------- Info used by the view ----------------
  String get extension => _extension;
  Map<String, String> get authHeaders => _jwtToken.isEmpty
      ? <String, String>{}
      : {'Authorization': 'Bearer $_jwtToken'};

  /// Filled by the player once the video's duration is known (header shows it).
  final Rx<Duration> duration = Duration.zero.obs;

  // ---------------- Computed ----------------
  bool get isBusy =>
      status.value == DownloadStatus.downloading ||
          status.value == DownloadStatus.saving;

  int get percent => (progress.value * 100).clamp(0, 100).round();

  // ---------------- Init ----------------
  /// Call once from the screen right after Get.put(...).
  void init({required String jwtToken, required String? videoPath}) {
    try {
      _jwtToken = jwtToken;
      final String path = (videoPath ?? '').trim();

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
    if (last.isEmpty) last = 'video.mp4';

    final int dot = last.lastIndexOf('.');
    if (dot > 0 && dot < last.length - 1) {
      _baseName = last.substring(0, dot);
      _extension = last.substring(dot + 1).toLowerCase();
    } else {
      _baseName = last;
      _extension = 'mp4';
    }
    fileName.value = '$_baseName.$_extension';
  }

  MimeType _mimeFor(String ext) {
    switch (ext) {
      case 'mp4':
        return MimeType.mp4Video;
      case 'webm':
        return MimeType.webm;
      default:
        return MimeType.custom;
    }
  }

  /// Only used when _mimeFor() returns MimeType.custom.
  String? _customMimeFor(String ext) {
    switch (ext) {
      case 'mp4':
      case 'webm':
        return null;
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'm4v':
        return 'video/x-m4v';
      case 'ogv':
      case 'ogg':
        return 'video/ogg';
      case '3gp':
        return 'video/3gpp';
      default:
        return 'application/octet-stream';
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
        title: 'Download video?',
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
        customMimeType: _customMimeFor(_extension),
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
// Per-player state (same pattern as VideoCardController in your
// ProviderSerResVideoScreen): playback error + "loaded" flag.
// ===========================================================================
class VideoCardController extends GetxController {
  final Rxn<String> errorText = Rxn<String>();
  final RxBool loaded = false.obs;

  void setError(String? text) {
    errorText.value = text;
    if (text != null) loaded.value = false;
  }

  void clearError() => errorText.value = null;
}

// ===========================================================================
// Player surface controls visibility + auto-hide timer (same as your
// PlayerControlsController). One per surface (inline + fullscreen).
// ===========================================================================
class PlayerControlsController extends GetxController {
  final RxBool controlsVisible = true.obs;
  Timer? _hideTimer;

  void scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) controlsVisible.value = false;
    });
  }

  void toggle() {
    controlsVisible.value = !controlsVisible.value;
    if (controlsVisible.value) scheduleHide();
  }

  @override
  void onClose() {
    _hideTimer?.cancel();
    super.onClose();
  }
}