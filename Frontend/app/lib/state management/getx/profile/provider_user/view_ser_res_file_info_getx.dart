import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:app/constant/Server_Database.dart';
import 'package:app/models/ServResourFileInfoModel.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';

import '../../../../constant/variable.dart';

class ViewSerResFileInfoGetx extends GetxController {
  // ---------------- List state ----------------
  final RxList<ServResourFileInfoModel> items = <ServResourFileInfoModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString query = ''.obs;
  final TextEditingController searchCtrl = TextEditingController();

  // ---------------- Selection / layout ----------------
  final Rxn<ServResourFileInfoModel> selected = Rxn<ServResourFileInfoModel>();
  final RxBool isFullscreen = false.obs;
  final RxBool panMode = true.obs; // true = drag, false = text select

  // ---------------- Viewer state ----------------
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 0.obs;
  final RxDouble zoom = 1.0.obs;
  final RxBool viewerReady = false.obs;
  final RxString viewerError = ''.obs;
  final Rx<Key> viewerKey = UniqueKey().obs;
  final PdfViewerController pdfController = PdfViewerController();
  final TransformationController imageTc = TransformationController();

  String _jwt = '';

  void init({required String jwtToken}) {
    try {
      _jwt = jwtToken;
    } catch (e) {
      debugPrint('init error: $e');
    }
  }

  Map<String, String> get authHeaders =>
      _jwt.isEmpty ? <String, String>{} : {'Authorization': 'Bearer $_jwt'};

  // ---------------- Model helpers (null-safe) ----------------
  String _clean(String? v) {
    final String t = (v ?? '').trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t;
  }

  String displayOr(String? v) {
    final String t = _clean(v);
    return t.isEmpty ? 'No data available' : t;
  }

  String idOf(ServResourFileInfoModel f) =>
      _clean(f.providerServiceResourcesId?.toString());

  String providerServiceIdOf(ServResourFileInfoModel f) =>
      _clean(f.providerServiceId?.toString());

  String titleOf(ServResourFileInfoModel f) => _clean(f.serviceTitle);

  /// Internal only. Used to build the request URL. Never displayed.
  String _pathOf(ServResourFileInfoModel f) => _clean(f.resourceFile);

  /// Internal only. Used to build the request URL. Never displayed.
  String urlOf(ServResourFileInfoModel f) {
    try {
      final String p = _pathOf(f);
      if (p.isEmpty) return '';
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      String base = Backend_Server_Url;
      if (base.endsWith('/')) base = base.substring(0, base.length - 1);
      return '$base${p.startsWith('/') ? p : '/$p'}';
    } catch (_) {
      return '';
    }
  }

  /// Internal only. Used to detect file type. Never displayed.
  String _fileNameOf(ServResourFileInfoModel f) {
    final String p = _pathOf(f);
    if (p.isEmpty) return '';
    String last = p.split('?').first.split('/').last;
    try {
      last = Uri.decodeComponent(last);
    } catch (_) {}
    return last;
  }

  String extOf(ServResourFileInfoModel f) {
    final String n = _fileNameOf(f);
    final int d = n.lastIndexOf('.');
    return (d > 0 && d < n.length - 1) ? n.substring(d + 1).toLowerCase() : '';
  }

  bool isPdf(ServResourFileInfoModel f) => extOf(f) == 'pdf';

  bool isImage(ServResourFileInfoModel f) =>
      const ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(extOf(f));

  bool isSameFile(ServResourFileInfoModel a, ServResourFileInfoModel b) =>
      idOf(a) == idOf(b) && _pathOf(a) == _pathOf(b);

  /// Search by providerServiceResourcesId or serviceTitle only.
  List<ServResourFileInfoModel> get filtered {
    final String q = query.value.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((f) {
      return idOf(f).toLowerCase().contains(q) ||
          titleOf(f).toLowerCase().contains(q);
    }).toList();
  }

  // ---------------- Fetch (logic unchanged) ----------------
  Future<int> GetServiceResourcesFileInfo({
    required String Email,
    required String ServiceName,
    required String jwttoken,
  }) async {
    isLoading.value = true;
    try {
      if (Email.trim().isEmpty) {
        items.clear();
        Toast.Toastmsg("Email is required.");
        return 1;
      }

      if (ServiceName.trim().isEmpty) {
        items.clear();
        Toast.Toastmsg("Service name is required.");
        return 2;
      }

      const String url =
          Backend_Server_Url + "api/Profile/getserviceresourcesfileinfo";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode({
          "Email": Email.trim(),
          "ServiceName": ServiceName.trim(),
        }),
      );

      items.clear();

      switch (response.statusCode) {
        case 200:
          final dynamic decodedData = jsonDecode(response.body);

          if (decodedData is! List) {
            Toast.Toastmsg("Invalid service resource data received.");
            return 3;
          }

          final List<ServResourFileInfoModel> parsed = [];
          for (final item in decodedData) {
            if (item is Map) {
              parsed.add(ServResourFileInfoModel.fromJson(
                  Map<String, dynamic>.from(item)));
            }
          }
          items.assignAll(parsed);
          selected.value = null;
          isFullscreen.value = false;

          if (items.isEmpty) {
            Toast.Toastmsg("No service resource files found.");
            return 4;
          }

          Toast.Toastmsg("Service resource files loaded successfully.");
          return 10;

        case 400:
          Toast.Toastmsg("Invalid request. Check the email and service name.");
          return 5;

        case 401:
          Toast.Toastmsg("Your session is invalid. Please log in again.");
          return 6;

        case 403:
          Toast.Toastmsg("You are not authorized to access this information.");
          return 7;

        case 404:
          Toast.Toastmsg(
              "No service resource files found, or the user does not exist.");
          return 8;

        case 500:
          Toast.Toastmsg("Server error while loading service resource files.");
          return 9;

        default:
          Toast.Toastmsg("Unable to load service resource files. Please try again.");
          return 0;
      }
    } catch (e) {
      items.clear();
      debugPrint('GetServiceResourcesFileInfo error: $e');
      Toast.Toastmsg("Something went wrong while loading service resources.");
      return 14;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- Selection ----------------
  void selectFile(ServResourFileInfoModel f, {required bool openFullscreen}) {
    try {
      selected.value = f;
      currentPage.value = 1;
      totalPages.value = 0;
      zoom.value = 1.0;
      viewerReady.value = false;
      viewerError.value = '';
      panMode.value = true;
      imageTc.value = Matrix4.identity();
      viewerKey.value = UniqueKey();
      isFullscreen.value = openFullscreen;
    } catch (e) {
      debugPrint('selectFile error: $e');
    }
  }

  void openFullscreen() => isFullscreen.value = true;
  void exitFullscreen() => isFullscreen.value = false;
  void togglePanMode() => panMode.value = !panMode.value;

  // ---------------- Viewer callbacks ----------------
  void onPdfLoaded(int pages) {
    totalPages.value = pages;
    currentPage.value = 1;
    viewerReady.value = true;
    viewerError.value = '';
  }

  /// The raw Syncfusion message can contain the file URL, so it is logged
  /// for developers only and never shown to the user.
  void onPdfFailed(String msg) {
    debugPrint('PDF load failed: $msg');
    viewerReady.value = false;
    viewerError.value = 'The document could not be displayed.';
  }

  void onPageChanged(int page) => currentPage.value = page;

  void onZoomChanged(double z) => zoom.value = z.clamp(1.0, 3.0).toDouble();

  void retryViewer() {
    viewerError.value = '';
    viewerReady.value = false;
    totalPages.value = 0;
    zoom.value = 1.0;
    viewerKey.value = UniqueKey();
  }

  // ---------------- Viewer controls ----------------
  void setZoom(double z) {
    try {
      final double v = z.clamp(1.0, 3.0).toDouble();
      zoom.value = v;
      final f = selected.value;
      if (f == null) return;
      if (isPdf(f)) {
        pdfController.zoomLevel = v;
      } else {
        imageTc.value = Matrix4.identity()..scale(v);
      }
    } catch (e) {
      debugPrint('setZoom error: $e');
    }
  }

  void zoomIn() => setZoom(zoom.value + 0.25);
  void zoomOut() => setZoom(zoom.value - 0.25);
  void resetZoom() => setZoom(1.0);

  void panBy(double dx) {
    try {
      final Offset o = pdfController.scrollOffset;
      final double x = (o.dx + dx).clamp(0.0, double.maxFinite).toDouble();
      pdfController.jumpTo(xOffset: x, yOffset: o.dy);
    } catch (e) {
      debugPrint('pan error: $e');
    }
  }

  void nextPage() {
    try {
      pdfController.nextPage();
    } catch (_) {}
  }

  void prevPage() {
    try {
      pdfController.previousPage();
    } catch (_) {}
  }

  @override
  void onClose() {
    try {
      pdfController.dispose();
    } catch (_) {}
    try {
      imageTc.dispose();
    } catch (_) {}
    try {
      searchCtrl.dispose();
    } catch (_) {}
    super.onClose();
  }
}