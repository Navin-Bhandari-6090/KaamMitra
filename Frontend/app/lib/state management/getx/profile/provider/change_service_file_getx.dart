
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';


// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.

class ChangeServiceFileGetx extends GetxController {
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
  // Your API call, kept exactly as written — only wrapped with isSubmitting
  // so the button can show a spinner instead of doing nothing while the
  // request is in flight.
  // -----------------------------------------------------------------------
  Future<int> UpdateServiceFile({
    required List<int> FileBytes,
    required String ServiceId,
  }) async {
    isSubmitting.value = true;
    try {
      // =====================================================
      // 1. Validate file
      // =====================================================

      if (FileBytes.isEmpty) {
        Toast.Toastmsg('File data is required');
        print('File data is required');
        return 1;
      }

      // =====================================================
      // 2. Validate service ID
      // =====================================================

      if (ServiceId.trim().isEmpty) {
        Toast.Toastmsg('Service id is required');
        print('Service id is required');
        return 1;
      }

      // =====================================================
      // 3. Validate email
      // =====================================================

      if (_email.trim().isEmpty) {
        Toast.Toastmsg('Email is required');
        print('Email is required');
        return 1;
      }

      // =====================================================
      // 4. API URL
      // =====================================================

      const String url = Backend_Server_Url + "api/Profile/updateservicedocument";

      // =====================================================
      // 5. Create multipart request
      // =====================================================

      final request = http.MultipartRequest('PUT', Uri.parse(url));

      // =====================================================
      // 6. Authorization
      // =====================================================

      request.headers['Authorization'] = 'Bearer $_jwtToken';

      // =====================================================
      // 7. Add normal form fields
      // =====================================================

      request.fields['Email'] = _email.trim();

      request.fields['ProviderServiceId'] = ServiceId.trim();

      // =====================================================
      // 8. Add PDF file
      // =====================================================

      request.files.add(
        http.MultipartFile.fromBytes(
          'ServiceDocument',
          FileBytes,
          filename: 'service_document.pdf',
          contentType: http.MediaType('application', 'pdf'),
        ),
      );

      // =====================================================
      // 9. Debug information
      // =====================================================

      print('==========================================');
      print('UPDATE SERVICE DOCUMENT');
      print('==========================================');
      print('URL: $url');
      print('Email: $_email');
      print('Service ID: ${ServiceId.trim()}');
      print('File bytes: ${FileBytes.length}');
      print('==========================================');

      // =====================================================
      // 10. Send request
      // =====================================================

      final streamedResponse = await request.send();

      // =====================================================
      // 11. Convert streamed response
      // =====================================================

      final response = await http.Response.fromStream(streamedResponse);

      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');

      // =====================================================
      // 12. Success
      // =====================================================

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Service document updated successfully.',
        );

        print('Update service success.');

        return 1;
      }

      // =====================================================
      // 13. Bad data
      // =====================================================

      else if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Data are not in correct format.',
        );

        print('Update service failed - 400: ${response.body}');

        return 3;
      }

      // =====================================================
      // 14. Unauthorized
      // =====================================================

      else if (response.statusCode == 401) {
        Toast.Toastmsg('Unauthorized. Please login again.');

        print('Update service failed - 401: ${response.body}');

        return 4;
      }

      // =====================================================
      // 15. Not found
      // =====================================================

      else if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'User or service not found.',
        );

        print('Update service failed - 404: ${response.body}');

        return 5;
      }

      // =====================================================
      // 16. Server error
      // =====================================================

      else if (response.statusCode == 500) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Server error. Please try again.',
        );

        print('Update service failed - 500: ${response.body}');

        return 6;
      }

      // =====================================================
      // 17. Other status codes
      // =====================================================

      else {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : 'Update service failed.',
        );

        print('Unexpected status code: ${response.statusCode}');

        print('Response: ${response.body}');

        return 2;
      }
    }

    // =======================================================
    // 18. Exception
    // =======================================================

    catch (e) {
      print('UpdateServiceFile exception: $e');

      Toast.Toastmsg('Update service failed.');

      return 0;
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }
}