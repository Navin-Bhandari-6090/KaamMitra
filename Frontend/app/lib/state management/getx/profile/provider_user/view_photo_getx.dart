import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../constant/Server_Database.dart';
import '../../../../models/ServicePhotoModel.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';

// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.

// ==================================================================
// FETCH RESULT — distinguishes "nothing uploaded" (404) from a real
// failure (network / 400 / 401 / 403 / 500 / other), each carrying
// the actual server-provided message instead of a generic one.
// Moved verbatim from the original widget file so the controller can
// expose it too.
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
  // ---------------------------------------------------------------------
  // REACTIVE STATE (replaces _servicePhotoFuture + FutureBuilder + the
  // one setState() that used to live in _refreshPhotos)
  // ---------------------------------------------------------------------
  final RxBool isLoading = true.obs;
  final Rxn<PhotoFetchResult> result = Rxn<PhotoFetchResult>();

  late String _email;
  late String _jwtToken;
  late String _serviceName;

  String get serviceName => _serviceName;

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
    int Result = await UserProviderJwtVerify(Jwt_Token: jwtToken);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      // Context-free navigation via GetX (controllers have no
      // BuildContext) — functionally equivalent to the old
      // Navigator.pushReplacement(...).
      Get.off(() => ErrorPage());
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  // ============================================================
  // GET SERVICE PHOTOS — same logic/status branches as the original
  // GetServicePhotoInfo, only the state writes now go through Rx
  // fields instead of setState().
  // ============================================================
  Future<void> fetchPhotos() async {
    if (!isClosed) isLoading.value = true;

    final PhotoFetchResult fetched = await _getServicePhotoInfo(_email, _jwtToken);

    if (isClosed) return;
    result.value = fetched;
    isLoading.value = false;
  }

  Future<void> refreshPhotos() async {
    await fetchPhotos();
  }

  Future<PhotoFetchResult> _getServicePhotoInfo(
      String Email,
      String JwtToken,
      ) async {
    try {
      print("======================================");
      print("GET SERVICE PHOTO METHOD CALLED");
      print("Email: $Email");
      print("Service Name: $_serviceName");
      print("======================================");

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

      print("Get service photo status: ${response.statusCode}");
      print("Response length: ${response.body.length}");

      // ========================================================
      // SUCCESS
      // ========================================================

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

        print("Number of service photos: ${servicePhotos.length}");

        if (servicePhotos.isEmpty) {
          return const PhotoFetchResult(status: FetchStatus.notFound);
        }

        return PhotoFetchResult(
          status: FetchStatus.success,
          photos: servicePhotos,
        );
      }

      // ========================================================
      // 404 — nothing uploaded yet, NOT an error.
      // ========================================================

      if (response.statusCode == 404) {
        String message = "No service photos found.";
        try {
          final dynamic body = jsonDecode(response.body);
          if (body is String && body.trim().isNotEmpty) {
            message = body;
          }
        } catch (_) {}

        return PhotoFetchResult(status: FetchStatus.notFound, message: message);
      }

      // ========================================================
      // 400
      // ========================================================

      if (response.statusCode == 400) {
        String message = "Invalid request.";
        try {
          final dynamic body = jsonDecode(response.body);
          if (body is String) message = body;
        } catch (_) {}
        // NOTE: the original showed this via a ScaffoldMessenger SnackBar
        // (_showErrorToast), which needs a BuildContext the controller
        // doesn't have. The widget listens to `result` and shows the same
        // SnackBar whenever status == failure — see `ever(...)` in
        // ProviderServicePhoto's initState.
        return PhotoFetchResult(status: FetchStatus.failure, message: message);
      }

      // ========================================================
      // 401
      // ========================================================

      if (response.statusCode == 401) {
        const String message = "Your session has expired. Please login again.";
        return const PhotoFetchResult(status: FetchStatus.failure, message: message);
      }

      // ========================================================
      // 403
      // ========================================================

      if (response.statusCode == 403) {
        const String message = "You do not have permission to view these photos.";
        return const PhotoFetchResult(status: FetchStatus.failure, message: message);
      }

      // ========================================================
      // 500
      // ========================================================

      if (response.statusCode == 500) {
        String message = "Server error. Please try again later.";
        try {
          final dynamic body = jsonDecode(response.body);
          if (body is String && body.trim().isNotEmpty) message = body;
        } catch (_) {}
        return PhotoFetchResult(status: FetchStatus.failure, message: message);
      }

      // ========================================================
      // OTHER STATUS
      // ========================================================

      final String message = "Request failed. Status code: ${response.statusCode}";
      return PhotoFetchResult(status: FetchStatus.failure, message: message);
    } catch (e) {
      print("GetServicePhotoInfo error: $e");
      final String message = "Network error: ${e.toString()}";
      return PhotoFetchResult(status: FetchStatus.failure, message: message);
    }
  }

  // ============================================================
  // URL BUILDER — pure function, no state involved.
  // ============================================================
  String buildImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.trim().isEmpty) {
      return "";
    }
    final String baseUrl = Backend_Server_Url.replaceFirst(RegExp(r'/$'), '');
    final String path = photoPath.startsWith("/") ? photoPath : "/$photoPath";
    return "$baseUrl$path";
  }
}