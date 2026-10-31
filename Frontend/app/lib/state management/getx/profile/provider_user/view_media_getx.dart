import 'dart:async';
import 'dart:convert';

import 'package:app/constant/Server_Database.dart';
import 'package:app/models/SharedMediaModel.dart';
import 'package:app/web/common method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../constant/variable.dart';
import '../../../../web/common method/date_time.dart';

enum AttachKind { photo, video, file }

class MediaAttachment {
  final AttachKind kind;
  final String path;
  const MediaAttachment(this.kind, this.path);
}

class ViewMediaGetx extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool loadFailed = false.obs;
  final RxString errorText = ''.obs;
  final RxList<SharedMediaModel> sharedList = <SharedMediaModel>[].obs;
  final RxString query = ''.obs;
  final RxSet<int> deletingIds = <int>{}.obs;
  final TextEditingController searchCtrl = TextEditingController();

  String _jwtToken = '';

  void init(String jwtToken) {
    _jwtToken = jwtToken;
  }

  @override
  void onClose() {
    try {
      searchCtrl.dispose();
    } catch (_) {}
    super.onClose();
  }

  Future<void> loadAll(BuildContext context) async {
    try {
      isLoading.value = true;
      loadFailed.value = false;
      final int result =
      await Get_Shared_Media(context: context, JwtToken: _jwtToken);
      if (result != 1) {
        loadFailed.value = true;
        errorText.value = "Unable to load shared media.";
      }
    } catch (_) {
      loadFailed.value = true;
      errorText.value = "Something went wrong while loading media.";
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> deleteMedia(BuildContext context, int id) async {
    if (deletingIds.contains(id)) return;
    try {
      deletingIds.add(id);
      final int result = await Delete_Shared_Media(
        context: context,
        JwtToken: _jwtToken,
        SharedMediaId: id,
      );
      if (result == 1) {
        sharedList.removeWhere((m) => m.sharedMediaId?.toInt() == id);
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong while deleting shared media.");
    } finally {
      deletingIds.remove(id);
    }
  }

  Future<int> Get_Shared_Media({
    required BuildContext context,
    required String JwtToken,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Profile/getsharedmedia";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $JwtToken',
        },
      );

      final int statusCode = response.statusCode;
      final String responseBody = response.body.trim();

      if (statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(responseBody);
        sharedList.assignAll(
          jsonData.map((data) => SharedMediaModel.fromJson(data)).toList(),
        );
        return 1;
      } else if (statusCode == 400) {
        Toast.Toastmsg("Invalid request to retrieve shared media.");
        return 2;
      } else if (statusCode == 401) {
        Toast.Toastmsg("Invalid authentication. Please log in again.");
        await Logout(context: context);
        return 3;
      } else if (statusCode == 500) {
        Toast.Toastmsg("Something went wrong while retrieving shared media.");
        return 6;
      } else if (statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by System. Contact the KaamMitra community.",
        );
        await Logout(context: context);
        return 7;
      } else if (statusCode == 520) {
        Toast.Toastmsg("User account not found.");
        await Logout(context: context);
        return 8;
      } else {
        Toast.Toastmsg("Unable to retrieve shared media. Please try again.");
        return 9;
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong while retrieving shared media.");
      return 10;
    }
  }

  Future<int> Delete_Shared_Media({
    required BuildContext context,
    required String JwtToken,
    required int SharedMediaId,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Profile/deletesharedmedia";

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $JwtToken',
        },
        body: jsonEncode({
          "SharedMediaId": SharedMediaId,
        }),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        Toast.Toastmsg("Shared media deleted successfully.");
        return 1;
      } else if (statusCode == 400) {
        Toast.Toastmsg("Invalid shared media information format.");
        return 2;
      } else if (statusCode == 401) {
        Toast.Toastmsg("Invalid authentication. Please log in again.");
        await Logout(context: context);
        return 3;
      } else if (statusCode == 403) {
        Toast.Toastmsg(
          "You are not authorized to delete this shared media. This media is not sent by you.",
        );
        return 4;
      } else if (statusCode == 404) {
        Toast.Toastmsg("Shared media not found.");
        return 5;
      } else if (statusCode == 500) {
        Toast.Toastmsg("Server error occurred while deleting shared media.");
        return 6;
      } else if (statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by System. Contact the KaamMitra community.",
        );
        await Logout(context: context);
        return 7;
      } else if (statusCode == 520) {
        Toast.Toastmsg("User account not found.");
        await Logout(context: context);
        return 8;
      } else {
        Toast.Toastmsg("Unable to delete shared media. Please try again.");
        return 9;
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong while deleting shared media.");
      return 10;
    }
  }

  // ==================================================================
  // HELPERS (null-safe, empty values show "No data available")
  // ==================================================================
  String _clean(String? v) {
    final String t = (v ?? '').trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t;
  }

  String displayOr(String? v) {
    final String t = _clean(v);
    return t.isEmpty ? 'No data available' : t;
  }

  String numText(num? n) => n == null ? '' : n.toInt().toString();

  String idOf(SharedMediaModel m) => numText(m.sharedMediaId);

  String descOf(SharedMediaModel m) => _clean(m.mediaDescription);

  String formatDate(String? raw) {
    try {
      final String s = _clean(raw);
      if (s.isEmpty) return 'No data available';
      final String formatted = formatDateTime(s);
      return formatted.isEmpty ? 'No data available' : formatted;
    } catch (_) {
      return 'No data available';
    }
  }

  String resolveUrl(String relativePath) {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    final String base = Backend_Server_Url.replaceFirst(RegExp(r'/$'), '');
    final String rel =
    relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$base$rel';
  }

  String urlOf(MediaAttachment a) => resolveUrl(a.path);

  List<MediaAttachment> attachmentsOf(SharedMediaModel m) {
    final List<MediaAttachment> list = [];
    try {
      final String photo = _clean(m.servicePhoto);
      final String video = _clean(m.serviceVideo);
      final String file = _clean(m.serviceFile);
      if (photo.isNotEmpty) list.add(MediaAttachment(AttachKind.photo, photo));
      if (video.isNotEmpty) list.add(MediaAttachment(AttachKind.video, video));
      if (file.isNotEmpty) list.add(MediaAttachment(AttachKind.file, file));
    } catch (_) {}
    return list;
  }

  // ==================================================================
  // SEARCH: media ID, or every typed word found in the full description
  // ==================================================================
  List<SharedMediaModel> get filteredList {
    try {
      final String q = query.value.trim().toLowerCase();
      final List<SharedMediaModel> all = sharedList.toList();
      if (q.isEmpty) return all;

      final List<String> words = q
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      return all.where((m) {
        if (idOf(m).toLowerCase().contains(q)) return true;
        final String desc = descOf(m).toLowerCase();
        return words.isNotEmpty && words.every((w) => desc.contains(w));
      }).toList();
    } catch (_) {
      return const <SharedMediaModel>[];
    }
  }
}

// =============================================================================
// VIEWER CONTROLLER — one instance per open attachment (photo / video / file)
// =============================================================================
class MediaViewerController extends GetxController {
  final RxBool isFullscreen = false.obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;

  final RxBool horizontalPdf = false.obs;
  final RxInt pdfReload = 0.obs;
  final RxInt pdfPage = 1.obs;
  final RxInt pdfPages = 0.obs;
  final RxDouble zoom = 1.0.obs;

  final RxBool playing = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;

  final PdfViewerController pdfCtrl = PdfViewerController();
  final TransformationController photoCtrl = TransformationController();
  Offset viewportCenter = Offset.zero;

  AttachKind kind = AttachKind.photo;
  String url = '';
  String jwt = '';

  Player? _player;
  VideoController? videoCtrl;
  final List<StreamSubscription> _subs = [];
  bool _ready = false;

  bool get isPdf =>
      kind == AttachKind.file &&
          url.toLowerCase().split('?').first.endsWith('.pdf');

  String get fileName {
    try {
      final String clean = url.split('?').first;
      return Uri.decodeComponent(clean.split('/').last);
    } catch (_) {
      return url.split('/').last;
    }
  }

  void init({
    required AttachKind kind,
    required String url,
    required String jwt,
  }) {
    if (_ready) return;
    _ready = true;
    this.kind = kind;
    this.url = url;
    this.jwt = jwt;

    if (url.isEmpty) {
      errorText.value = 'No data available';
      isLoading.value = false;
      return;
    }
    if (kind == AttachKind.video) {
      _openPlayer();
    } else if (!isPdf) {
      isLoading.value = false;
    }
  }

  void _openPlayer() {
    try {
      final Player p = _player ??= Player();
      videoCtrl ??= VideoController(p);
      if (_subs.isEmpty) {
        _subs.add(p.stream.error.listen((e) {
          debugPrint('Playback error: $e');
          errorText.value = 'This video could not be played.';
        }));
        _subs.add(p.stream.playing.listen((v) => playing.value = v));
        _subs.add(p.stream.position.listen((v) => position.value = v));
        _subs.add(p.stream.duration.listen((v) => duration.value = v));
      }
      errorText.value = '';
      p.open(
        Media(url, httpHeaders: {'Authorization': 'Bearer $jwt'}),
        play: false,
      );
    } catch (e) {
      debugPrint('openPlayer error: $e');
      errorText.value = 'This video could not be played.';
    }
  }

  void reopen() {
    try {
      if (kind == AttachKind.video) {
        _openPlayer();
      } else if (isPdf) {
        errorText.value = '';
        isLoading.value = true;
        pdfReload.value++;
      }
    } catch (_) {}
  }

  void playPause() {
    try {
      _player?.playOrPause();
    } catch (_) {}
  }

  void seekTo(double ms) {
    try {
      _player?.seek(Duration(milliseconds: ms.round()));
    } catch (_) {}
  }

  void onPdfLoaded(PdfDocumentLoadedDetails details) {
    pdfPages.value = details.document.pages.count;
    errorText.value = '';
    isLoading.value = false;
  }

  void onPdfFailed(PdfDocumentLoadFailedDetails details) {
    debugPrint('PDF load failed: ${details.description}');
    isLoading.value = false;
    errorText.value = 'This document could not be loaded.';
  }

  void onPdfPageChanged(PdfPageChangedDetails details) {
    pdfPage.value = details.newPageNumber;
  }

  void pdfNext() {
    try {
      pdfCtrl.nextPage();
    } catch (_) {}
  }

  void pdfPrevious() {
    try {
      pdfCtrl.previousPage();
    } catch (_) {}
  }

  void zoomPdf(double delta) {
    try {
      final double z =
      (pdfCtrl.zoomLevel + delta).clamp(1.0, 4.0).toDouble();
      pdfCtrl.zoomLevel = z;
      zoom.value = z;
    } catch (_) {}
  }

  void toggleDirection() => horizontalPdf.toggle();

  void zoomPhoto(double factor) {
    try {
      final Offset c = viewportCenter;
      final Matrix4 z = Matrix4.identity()
        ..translate(c.dx, c.dy)
        ..scale(factor)
        ..translate(-c.dx, -c.dy);
      photoCtrl.value = z * photoCtrl.value;
    } catch (_) {}
  }

  void resetPhoto() {
    photoCtrl.value = Matrix4.identity();
  }

  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
    try {
      SystemChrome.setEnabledSystemUIMode(
        isFullscreen.value
            ? SystemUiMode.immersiveSticky
            : SystemUiMode.edgeToEdge,
      );
    } catch (_) {}
  }

  @override
  void onClose() {
    for (final StreamSubscription s in _subs) {
      s.cancel();
    }
    try {
      _player?.dispose();
    } catch (_) {}
    try {
      pdfCtrl.dispose();
    } catch (_) {}
    try {
      photoCtrl.dispose();
    } catch (_) {}
    if (isFullscreen.value) {
      try {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } catch (_) {}
    }
    super.onClose();
  }
}