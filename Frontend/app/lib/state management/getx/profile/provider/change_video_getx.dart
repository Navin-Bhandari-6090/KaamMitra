import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';

// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.
// Mirrors ChangePhotoGetx one-to-one so both screens share the exact same
// controller shape/behaviour.

class ChangeVideoGetx extends GetxController {
  final Toast = Toastget();

  // ---------------------------------------------------------------------
  // REACTIVE UI STATE (no setState anywhere)
  // ---------------------------------------------------------------------
  final RxBool isSubmitting = false.obs;

  late String _email;
  late String _jwtToken;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({required String email, required String jwtToken}) async {
    _email = email;
    _jwtToken = jwtToken;
    await Provider_Jwt_Verify(Jwt_Token: jwtToken);
  }

  // -----------------------------------------------------------------------
  // Same session-check logic as the original, only the navigation call is
  // now context-free (GetX controllers have no BuildContext).
  // -----------------------------------------------------------------------
  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Get.offAll(() => ErrorPage());
      Toast.Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  // -----------------------------------------------------------------------
  // Your API call, kept exactly as written (including the original field
  // mapping, status handling, and print statements) — only wrapped with
  // isSubmitting so the button can show a spinner instead of doing nothing
  // while the request is in flight.
  // -----------------------------------------------------------------------
  Future<int> UpdateServiceResourcesVideo({
    required List<int> VideoBytes,
    required String ServiceResourcesId,
    required String ProviderServiceId,
    required String VideoExtension,
  }) async {
    isSubmitting.value = true;
    try {
      // =========================================================
      // 1. Validate video
      // =========================================================

      if (VideoBytes.isEmpty) {
        Toast.Toastmsg(
          "Video data is required.",
        );

        print(
          "Video data is required.",
        );

        return 1;
      }

      // =========================================================
      // 2. Validate ServiceResourcesId
      // =========================================================

      if (ServiceResourcesId.trim().isEmpty) {
        Toast.Toastmsg(
          "Service resource ID is required.",
        );

        print(
          "Service resource ID is required.",
        );

        return 2;
      }

      // =========================================================
      // 3. Convert ServiceResourcesId
      // =========================================================

      final int? serviceResourcesId = int.tryParse(
        ServiceResourcesId.trim(),
      );

      if (serviceResourcesId == null || serviceResourcesId <= 0) {
        Toast.Toastmsg(
          "Invalid service resource ID.",
        );

        print(
          "Invalid service resource ID: $ServiceResourcesId",
        );

        return 2;
      }

      // =========================================================
      // 4. Validate ProviderServiceId
      // =========================================================

      if (ProviderServiceId.trim().isEmpty) {
        Toast.Toastmsg(
          "Provider service ID is required.",
        );

        print(
          "Provider service ID is required.",
        );

        return 3;
      }

      // =========================================================
      // 5. Convert ProviderServiceId
      // =========================================================

      final int? providerServiceId = int.tryParse(
        ProviderServiceId.trim(),
      );

      if (providerServiceId == null || providerServiceId <= 0) {
        Toast.Toastmsg(
          "Invalid provider service ID.",
        );

        print(
          "Invalid provider service ID: $ProviderServiceId",
        );

        return 3;
      }

      // =========================================================
      // 6. Validate video extension
      // =========================================================

      final String videoExtension = VideoExtension.trim().toLowerCase().replaceFirst('.', '');

      if (videoExtension.isEmpty) {
        Toast.Toastmsg(
          "Video extension is required.",
        );

        print(
          "Video extension is required.",
        );

        return 4;
      }

      // =========================================================
      // 7. Validate Email
      // =========================================================

      if (_email.trim().isEmpty) {
        Toast.Toastmsg(
          "Email is required.",
        );

        print(
          "Email is required.",
        );

        return 5;
      }

      // =========================================================
      // 8. Print information
      // =========================================================

      print(
        "==========================================",
      );

      print(
        "UPDATE SERVICE RESOURCE VIDEO",
      );

      print(
        "==========================================",
      );

      print(
        "Email: ${_email.trim()}",
      );

      print(
        "ProviderServiceId: $providerServiceId",
      );

      print(
        "ProviderServiceResourcesId: $serviceResourcesId",
      );

      print(
        "Video Size: ${VideoBytes.length} bytes",
      );

      print(
        "Video Extension: $videoExtension",
      );

      // =========================================================
      // 9. API URL
      // =========================================================

      const String url = Backend_Server_Url + "api/Profile/updateserviceresourcesvideo";

      print(
        "API URL: $url",
      );

      // =========================================================
      // 10. Create Multipart Request
      // =========================================================

      final request = http.MultipartRequest(
        "PUT",
        Uri.parse(url),
      );

      // =========================================================
      // 11. Authorization
      // =========================================================

      request.headers["Authorization"] = "Bearer $_jwtToken";

      // =========================================================
      // 12. Add normal form fields
      // =========================================================

      request.fields["ProviderServiceResourcesId"] = serviceResourcesId.toString();

      request.fields["ProviderServiceId"] = providerServiceId.toString();

      request.fields["Email"] = _email.trim();

      // =========================================================
      // 13. Add video file
      // =========================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          "ServiceVideo",
          VideoBytes,
          filename: "service_video.$videoExtension",
        ),
      );

      // =========================================================
      // 14. Print upload information
      // =========================================================

      print(
        "Multipart request created.",
      );

      print(
        "Video filename: service_video.$videoExtension",
      );

      print(
        "Uploading service resource video...",
      );

      // =========================================================
      // 15. Send request
      // =========================================================

      final streamedResponse = await request.send();

      // =========================================================
      // 16. Convert streamed response
      // =========================================================

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      // =========================================================
      // 17. Print response
      // =========================================================

      print(
        "Response status: ${response.statusCode}",
      );

      print(
        "Response body: ${response.body}",
      );

      // =========================================================
      // 18. Success
      // =========================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : "Service resource video updated successfully.",
        );

        print(
          "Service resource video updated successfully.",
        );

        return 1;
      }

      // =========================================================
      // 19. Bad request
      // =========================================================

      if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : "Data are not in correct format.",
        );

        print(
          "Bad request: ${response.body}",
        );

        return 4;
      }

      // =========================================================
      // 20. Unauthorized
      // =========================================================

      if (response.statusCode == 401) {
        Toast.Toastmsg(
          "Unauthorized. Please login again.",
        );

        print(
          "Unauthorized.",
        );

        return 6;
      }

      // =========================================================
      // 21. Forbidden
      // =========================================================

      if (response.statusCode == 403) {
        Toast.Toastmsg(
          "You are not authorized to update this resource.",
        );

        print(
          "Forbidden.",
        );

        return 7;
      }

      // =========================================================
      // 22. Resource not found
      // =========================================================

      if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : "Service resource not found.",
        );

        print(
          "Service resource not found: ${response.body}",
        );

        return 5;
      }

      // =========================================================
      // 23. Server error
      // =========================================================

      if (response.statusCode == 500) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : "Server error while updating service resource video.",
        );

        print(
          "Server error: ${response.body}",
        );

        return 8;
      }

      // =========================================================
      // 24. Unexpected status code
      // =========================================================

      print(
        "Unexpected status code: ${response.statusCode}",
      );

      print(
        "Response: ${response.body}",
      );

      Toast.Toastmsg(
        "Update service resource video failed.",
      );

      return 9;
    } catch (e) {
      // =========================================================
      // 25. Exception
      // =========================================================

      print(
        "Exception caught while updating service resource video.",
      );

      print(
        "Exception: $e",
      );

      Toast.Toastmsg(
        "Update service resource video failed.",
      );

      return 0;
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }
}