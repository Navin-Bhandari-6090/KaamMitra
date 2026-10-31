import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../models/ServicePhotoModel.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';

// ==================================================================
// FETCH RESULT
// ==================================================================
enum FetchStatus { success, notFound, failure }

class PhotoFetchResult {
  final FetchStatus status;
  final List<ServicePhotoModel> photos;
  final String message;

  const PhotoFetchResult({
    required this.status,
    this.photos = const [],
    this.message = '',
  });
}

class ViewPhotoGetx extends GetxController {
  // ---------------- Reactive state ----------------
  final RxBool isLoading = true.obs;
  final Rxn<PhotoFetchResult> result = Rxn<PhotoFetchResult>();
  final RxString query = ''.obs;
  final TextEditingController searchCtrl = TextEditingController();

  late String _email;
  late String _jwtToken;
  late String _serviceName;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({
    required String email,
    required String jwtToken,
    required String serviceName,
  }) async {
    _email = email;
    _jwtToken = jwtToken;
    _serviceName = serviceName;

    await jwtVerify(jwtToken: _jwtToken);
    await fetchPhotos();
  }

  Future<void> jwtVerify({required String jwtToken}) async {
    try {
      final int result = await UserProviderJwtVerify(Jwt_Token: jwtToken);
      if (result == 1) return;

      await Clear_User_Data();
      await Random_token_Clear();
      Get.off(() => ErrorPage());
      Toastget().Toastmsg("Session End.Relogin please.");
    } catch (e) {
      debugPrint('jwtVerify error: $e');
    }
  }

  Future<void> fetchPhotos() async {
    try {
      if (!isClosed) isLoading.value = true;
      final PhotoFetchResult fetched =
      await _getServicePhotoInfo(_email, _jwtToken);
      if (isClosed) return;
      result.value = fetched;
    } catch (e) {
      debugPrint('fetchPhotos error: $e');
      if (!isClosed) {
        result.value = PhotoFetchResult(
          status: FetchStatus.failure,
          message: 'Something went wrong while loading service photos.',
        );
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> refreshPhotos() async {
    await fetchPhotos();
  }

  Future<PhotoFetchResult> _getServicePhotoInfo(
      String Email,
      String JwtToken,
      ) async {
    try {
      const String url = Backend_Server_Url + "api/Profile/getservicephotoinfo";

      final Map<String, dynamic> UserDetails = {
        "Email": Email,
        "ServiceName": _serviceName,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $JwtToken",
        },
        body: jsonEncode(UserDetails),
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        if (decodedData is! List) {
          return const PhotoFetchResult(
            status: FetchStatus.failure,
            message: "Invalid server response format.",
          );
        }

        final List<ServicePhotoModel> servicePhotos = decodedData
            .map((item) => ServicePhotoModel.fromJson(item))
            .toList();

        if (servicePhotos.isEmpty) {
          return const PhotoFetchResult(status: FetchStatus.notFound);
        }

        return PhotoFetchResult(
          status: FetchStatus.success,
          photos: servicePhotos,
        );
      }

      if (response.statusCode == 404) {
        String message = "No service photos found.";
        try {
          final dynamic body = jsonDecode(response.body);
          if (body is String && body.trim().isNotEmpty) message = body;
        } catch (_) {}
        return PhotoFetchResult(status: FetchStatus.notFound, message: message);
      }

      if (response.statusCode == 400) {
        String message = "Invalid request.";
        try {
          final dynamic body = jsonDecode(response.body);
          if (body is String) message = body;
        } catch (_) {}
        return PhotoFetchResult(status: FetchStatus.failure, message: message);
      }

      if (response.statusCode == 401) {
        return const PhotoFetchResult(
          status: FetchStatus.failure,
          message: "Your session has expired. Please login again.",
        );
      }

      if (response.statusCode == 403) {
        return const PhotoFetchResult(
          status: FetchStatus.failure,
          message: "You do not have permission to view these photos.",
        );
      }

      if (response.statusCode == 500) {
        String message = "Server error. Please try again later.";
        try {
          final dynamic body = jsonDecode(response.body);
          if (body is String && body.trim().isNotEmpty) message = body;
        } catch (_) {}
        return PhotoFetchResult(status: FetchStatus.failure, message: message);
      }

      return PhotoFetchResult(
        status: FetchStatus.failure,
        message: "Request failed. Status code: ${response.statusCode}",
      );
    } catch (e) {
      debugPrint("GetServicePhotoInfo error: $e");
      return PhotoFetchResult(
        status: FetchStatus.failure,
        message: "Network error. Please check your connection.",
      );
    }
  }

  // ==================================================================
  // HELPERS (null-safe, never displayed raw)
  // ==================================================================
  String _clean(String? v) {
    final String t = (v ?? '').trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t;
  }

  String displayOr(String? v) {
    final String t = _clean(v);
    return t.isEmpty ? 'No data available' : t;
  }

  String idOf(ServicePhotoModel p) =>
      _clean(p.providerServiceResourcesId?.toString());

  String serviceIdOf(ServicePhotoModel p) =>
      _clean(p.providerServiceId?.toString());

  String titleOf(ServicePhotoModel p) => _clean(p.serviceTitle?.toString());

  /// Internal only. Used for Image.network. Never displayed.
  String imageUrlOf(ServicePhotoModel p) {
    try {
      return buildImageUrl(p.servicePhoto?.toString());
    } catch (_) {
      return '';
    }
  }

  /// URL builder, pure function.
  String buildImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.trim().isEmpty) return "";
    final String baseUrl = Backend_Server_Url.replaceFirst(RegExp(r'/$'), '');
    final String path = photoPath.startsWith("/") ? photoPath : "/$photoPath";
    return "$baseUrl$path";
  }

  // ==================================================================
  // SEARCH (resource ID or title)
  // ==================================================================
  List<ServicePhotoModel> get allPhotos {
    try {
      return result.value?.photos ?? const <ServicePhotoModel>[];
    } catch (_) {
      return const <ServicePhotoModel>[];
    }
  }

  List<ServicePhotoModel> get filteredPhotos {
    try {
      final String q = query.value.trim().toLowerCase();
      final List<ServicePhotoModel> all = allPhotos;
      if (q.isEmpty) return all;
      return all.where((p) {
        return idOf(p).toLowerCase().contains(q) ||
            titleOf(p).toLowerCase().contains(q);
      }).toList();
    } catch (_) {
      return const <ServicePhotoModel>[];
    }
  }

  @override
  void onClose() {
    try {
      searchCtrl.dispose();
    } catch (_) {}
    super.onClose();
  }
}