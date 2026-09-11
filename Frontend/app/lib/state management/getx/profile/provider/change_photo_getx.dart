import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';


// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.

class ChangePhotoGetx extends GetxController {
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
  // mapping) — only wrapped with isSubmitting so the button can show a
  // spinner instead of doing nothing while the request is in flight.
  // -----------------------------------------------------------------------
  Future<int> UpdateServiceResourcesPhoto({
    required List<int> ImageBytes,
    required String ImageExtension,
    required String ServiceResourcesId,
    required String ProviderServiceId,
  }) async {
    isSubmitting.value = true;
    try {
      // =====================================================
      // 1. Validate image bytes
      // =====================================================

      if (ImageBytes.isEmpty) {
        Toast.Toastmsg('Photo data is required.');

        print('Photo data is required.');

        return 1;
      }

      // =====================================================
      // 2. Validate resource ID
      // =====================================================

      if (ServiceResourcesId.trim().isEmpty) {
        Toast.Toastmsg('Service resource ID is required.');

        print('Service resource ID is required.');

        return 1;
      }

      // =====================================================
      // 3. Validate provider service ID
      // =====================================================

      if (ProviderServiceId.trim().isEmpty) {
        Toast.Toastmsg('Provider service ID is required.');

        print('Provider service ID is required.');

        return 1;
      }

      // =====================================================
      // 4. Validate extension
      //
      // You said frontend already validates it.
      // We only use it to create the filename.
      // =====================================================

      if (ImageExtension.trim().isEmpty) {
        Toast.Toastmsg('Image extension is required.');

        print('Image extension is required.');

        return 1;
      }

      // =====================================================
      // 5. Validate Email
      // =====================================================

      if (_email.trim().isEmpty) {
        Toast.Toastmsg('Email is required.');

        print('Email is required.');

        return 1;
      }

      // =====================================================
      // 6. API URL
      // =====================================================

      const String url = Backend_Server_Url + "api/Profile/updateserviceresourcesphoto";

      // =====================================================
      // 7. Create Multipart Request
      // =====================================================

      final request = http.MultipartRequest('PUT', Uri.parse(url));

      // =====================================================
      // 8. Authorization
      // =====================================================

      request.headers['Authorization'] = 'Bearer $_jwtToken';

      // =====================================================
      // 9. Add normal fields
      // =====================================================

      request.fields['ProviderServiceResourcesId'] = ServiceResourcesId.trim();

      request.fields['ProviderServiceId'] = ProviderServiceId.trim();

      request.fields['Email'] = _email.trim();

      // =====================================================
      // 10. Add image file
      // =====================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          'ServicePhoto',
          ImageBytes,
          filename: 'service_photo.${ImageExtension.trim().toLowerCase()}',
        ),
      );

      // =====================================================
      // 11. Debug information
      // =====================================================

      print('==========================================');
      print('UPDATE SERVICE RESOURCE PHOTO');
      print('==========================================');
      print('URL: $url');
      print('Resource ID: ${ServiceResourcesId.trim()}');
      print('Provider Service ID: ${ProviderServiceId.trim()}');
      print('Email: ${_email.trim()}');
      print('Image Extension: ${ImageExtension.trim()}');
      print('Image Bytes: ${ImageBytes.length}');
      print('==========================================');

      // =====================================================
      // 12. Send request
      // =====================================================

      final streamedResponse = await request.send();

      // =====================================================
      // 13. Convert response
      // =====================================================

      final response = await http.Response.fromStream(streamedResponse);

      print('Update resource photo status: ${response.statusCode}');

      print('Update resource photo response: ${response.body}');

      // =====================================================
      // 14. Success
      // =====================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Service resource photo updated successfully.',
        );

        print('Service resource photo updated successfully.');

        return 1;
      }

      // =====================================================
      // 15. Bad data
      // =====================================================

      else if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Data are not in correct format.',
        );

        print('Update resource photo failed - 400: ${response.body}');

        return 3;
      }

      // =====================================================
      // 16. Unauthorized
      // =====================================================

      else if (response.statusCode == 401) {
        Toast.Toastmsg('Unauthorized. Please login again.');

        print('Update resource photo failed - 401: ${response.body}');

        return 4;
      }

      // =====================================================
      // 17. Not found
      // =====================================================

      else if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Service resource not found.',
        );

        print('Update resource photo failed - 404: ${response.body}');

        return 5;
      }

      // =====================================================
      // 18. Server error
      // =====================================================

      else if (response.statusCode == 500) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Server error. Please try again.',
        );

        print('Update resource photo failed - 500: ${response.body}');

        return 6;
      }

      // =====================================================
      // 19. Other status codes
      // =====================================================

      else {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Update service resource photo failed.',
        );

        print('Unexpected status code: ${response.statusCode}');

        print('Response: ${response.body}');

        return 2;
      }
    }

    // =======================================================
    // 20. Exception
    // =======================================================

    catch (e) {
      print('UpdateServiceResources exception: $e');

      Toast.Toastmsg('Update service resource photo failed.');

      return 0;
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }
}