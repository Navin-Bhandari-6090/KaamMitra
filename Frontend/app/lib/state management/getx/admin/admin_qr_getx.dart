import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/AdminQRInfoModel.dart';
import '../../../web/common method/Commmon_Method.dart';

// =============================================================================
// CONTROLLER — all state lives here (no setState anywhere).
// API method bodies are the original logic, moved from the screen.
// =============================================================================
class AdminQrGetx extends GetxController {
  // ---------------- reactive state ----------------
  final RxList<AdminQrInfoModel> adminQrInfoList = <AdminQrInfoModel>[].obs;
  final RxBool isLoading = true.obs;

  /// "Domestic" / "International" while that upload is running, else "".
  final RxString uploadingType = ''.obs;

  /// Which QR slot the currently picked photo was picked for, else "".
  /// (The photo picker is one shared global, so we remember its owner.)
  final RxString pickedFor = ''.obs;

  String _jwt = '';

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({required String jwtToken}) async {
    _jwt = jwtToken;
    await loadInfo();
  }

  @override
  void onClose() {
    clearPicked();
    super.onClose();
  }

  Future<void> loadInfo() async {
    try {
      isLoading.value = true;
      await GetAdminQRInfo();
    } catch (obj) {
      print(obj.toString());
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS (null / empty safe: either QR, both, or none may exist)
  // ---------------------------------------------------------------------------
  String? pathFor(String type) {
    try {
      if (adminQrInfoList.isEmpty) return null;
      final AdminQrInfoModel m = adminQrInfoList.first;
      final String? raw =
      type == "Domestic" ? m.domesticQRPhoto : m.internationalQRPhoto;
      if (raw == null || raw.trim().isEmpty) return null;
      return raw.trim();
    } catch (_) {
      return null;
    }
  }

  int get uploadedCount =>
      (pathFor("Domestic") != null ? 1 : 0) +
          (pathFor("International") != null ? 1 : 0);

  /// Slash-safe URL joining.
  String buildUrl(String? path) {
    try {
      if (path == null || path.trim().isEmpty) return "";
      final String baseUrl = Backend_Server_Url.endsWith("/")
          ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
          : Backend_Server_Url;
      final String p =
      path.trim().startsWith("/") ? path.trim() : "/${path.trim()}";
      return "$baseUrl$p";
    } catch (obj) {
      print(obj.toString());
      return "";
    }
  }

  bool hasPending(String type) =>
      pickedFor.value == type && change_photo_cont_getx.imageBytes.value != null;

  void clearPicked() {
    try {
      change_photo_cont_getx.imageExtension.value = "";
      change_photo_cont_getx.imageBytes.value = null;
      change_photo_cont_getx.imagePath.value = "";
      pickedFor.value = '';
    } catch (obj) {
      print(obj.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIONS used by the screen
  // ---------------------------------------------------------------------------
  Future<void> pickFor(String type) async {
    try {
      final int photoResult = await change_photo_cont_getx.pickImage();
      if (photoResult == 1) {
        pickedFor.value = type;
        Toast.Toastmsg("Pick photo success.");
      } else if (photoResult == 2) {
        Toast.Toastmsg("Only $PhotoExtension format accepted.");
      } else if (photoResult == 5) {
        Toast.Toastmsg(
            "Image is larger then $PhotoSize.Please compressed and upload..");
      } else {
        Toast.Toastmsg("Pick photo  fail.");
      }
    } catch (e) {
      Toast.Toastmsg("Pick photo  fail.");
    }
  }

  Future<void> submitUpload(String type) async {
    if (uploadingType.value.isNotEmpty) return;
    uploadingType.value = type;
    try {
      final bytes = change_photo_cont_getx.imageBytes.value;
      if (bytes == null || pickedFor.value != type) {
        Toast.Toastmsg("Pick photo first.");
        return;
      }

      final int result = await AddAdminQRQr(
        ImageBytes: bytes.toList(),
        PhotoExtension: change_photo_cont_getx.imageExtension.value,
        QRType: type,
      );

      if (result == 1) {
        pickedFor.value = '';
        await GetAdminQRInfo(); // show the freshly uploaded QR
      }
    } catch (obj) {
      print(obj.toString());
    } finally {
      uploadingType.value = '';
    }
  }

  // ===========================================================================
  // ORIGINAL API METHODS — logic unchanged
  // ===========================================================================
  Future<int> AddAdminQRQr({
    required List<int> ImageBytes,
    required String PhotoExtension,
    required String QRType,
  }) async {
    try {
      // 1. Validate QR photo
      if (ImageBytes.isEmpty) {
        Toast.Toastmsg("QR photo is required.");
        print("QR photo data is required.");
        return 1;
      }

      // 2. Validate photo extension
      final String photoExtension =
      PhotoExtension.trim().toLowerCase().replaceFirst('.', '');

      if (photoExtension.isEmpty) {
        Toast.Toastmsg("Photo extension is required.");
        return 4;
      }

      // 3. Validate photo extension
      if (photoExtension != "jpg" &&
          photoExtension != "jpeg" &&
          photoExtension != "png") {
        Toast.Toastmsg("Invalid QR photo format.");
        print("Invalid QR photo extension: $photoExtension");
        return 4;
      }

      // 4. Validate QR type
      if (QRType != "Domestic" && QRType != "International") {
        Toast.Toastmsg("Invalid QR type.");
        print("Invalid QR type: $QRType");
        return 4;
      }

      // 5. API URL
      const String url = Backend_Server_Url + "api/Admin/addadminqr";
      print("========== ADD ADMIN QR ==========");

      // 6. Create multipart request
      final request = http.MultipartRequest("POST", Uri.parse(url));

      // 7. Authorization
      request.headers["Authorization"] = "Bearer $_jwt";

      // 8. Decide DTO field name
      String fieldName;
      if (QRType == "Domestic") {
        fieldName = "DomesticQRPhoto";
      } else {
        fieldName = "InternationalQRPhoto";
      }
      print("Multipart Field Name: $fieldName");

      // 9. Add QR photo
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          ImageBytes,
          filename: "admin_qr.$photoExtension",
        ),
      );

      print("Uploading $QRType QR...");

      // 11. Send request
      final streamedResponse = await request.send();

      // 12. Convert response
      final response = await http.Response.fromStream(streamedResponse);

      // 14. Success
      if (response.statusCode == 200) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Admin QR uploaded successfully.",
        );
        print("Admin $QRType QR uploaded successfully.");

        // Clear selected image
        change_photo_cont_getx.imageExtension.value = "";
        change_photo_cont_getx.imageBytes.value = null;
        change_photo_cont_getx.imagePath.value = "";

        return 1;
      }

      // 15. Bad request
      if (response.statusCode == 400) {
        Toast.Toastmsg(response.body);
        print("Bad request: ${response.body}");
        return 4;
      }

      // 16. Unauthorized
      if (response.statusCode == 401) {
        Toast.Toastmsg("Unauthorized. Please login again.");
        return 6;
      }

      // 17. Forbidden
      if (response.statusCode == 403) {
        Toast.Toastmsg("You are not authorized.");
        return 7;
      }

      // 18. User not found
      if (response.statusCode == 404) {
        Toast.Toastmsg(response.body);
        print("User not found: ${response.body}");
        return 5;
      }

      // 19. Blocked user
      if (response.statusCode == 506) {
        Toast.Toastmsg(response.body);
        print("User blocked: ${response.body}");
        return 10;
      }

      // 20. Server error
      if (response.statusCode == 500) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Server error while saving admin QR.",
        );
        print("Server error: ${response.body}");
        return 8;
      }

      // 21. Other status
      print("Unexpected status code: ${response.statusCode}");
      print("Response body: ${response.body}");
      Toast.Toastmsg("Add Admin QR failed.");
      return 9;
    } catch (e, stackTrace) {
      print("========== ADD ADMIN QR ERROR ==========");
      print("Exception: $e");
      print("StackTrace: $stackTrace");
      Toast.Toastmsg("Add Admin QR failed.");
      return 0;
    }
  }

  Future<void> GetAdminQRInfo() async {
    try {
      adminQrInfoList.clear();

      const String url = Backend_Server_Url + "api/Admin/getadminqr";

      print("========== GET ADMIN QR INFO ==========");
      print("API URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_jwt",
        },
      );



      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        // Backend returns one AdminQRPhotoModel object
        if (responseData is Map<String, dynamic>) {
          adminQrInfoList.add(AdminQrInfoModel.fromJson(responseData));
        }

        print("Admin QR Info Count: ${adminQrInfoList.length}");

        Toast.Toastmsg("Admin QR information loaded successfully.");
      } else if (response.statusCode == 400) {
        adminQrInfoList.clear();
        Toast.Toastmsg("Data are not in correct format.");
      } else if (response.statusCode == 401) {
        adminQrInfoList.clear();
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        adminQrInfoList.clear();
        Toast.Toastmsg("You are not authorized to access admin QR information.");
      } else if (response.statusCode == 404) {
        adminQrInfoList.clear();
        Toast.Toastmsg("Admin QR information is not present.");
      } else if (response.statusCode == 506) {
        adminQrInfoList.clear();
        Toast.Toastmsg(
            "You have been blocked by System. Contact KaamMitra community.");
      } else if (response.statusCode == 500) {
        adminQrInfoList.clear();
        Toast.Toastmsg(
            "Something went wrong while getting admin QR information.");
      } else {
        adminQrInfoList.clear();
        Toast.Toastmsg("Something went wrong.");
      }
    } catch (e, stackTrace) {
      print("========== GET ADMIN QR INFO ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");
      adminQrInfoList.clear();
      Toast.Toastmsg("Something went wrong.");
    }
  }
}