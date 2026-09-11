import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';


// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.

class UpdatePasswordGetx extends GetxController {
  // ---------------------------------------------------------------------
  // REACTIVE UI STATE (no setState anywhere)
  // ---------------------------------------------------------------------
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxString errorText = ''.obs;

  late String _email;
  late String _jwtToken;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({required String email, required String jwtToken}) async {
    _email = email;
    _jwtToken = jwtToken;
    await Provider_Jwt_Verify(Jwt_Token: jwtToken);
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  // -----------------------------------------------------------------------
  // Same session-check logic as the original, only the navigation call is
  // now context-free (GetX controllers have no BuildContext).
  // -----------------------------------------------------------------------
  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Get.offAll(() => ErrorPage());
      Toastget().Toastmsg("Session End.Relogin please.");
      return;
    }
  }

  // -----------------------------------------------------------------------
  // Your API call, kept exactly as written — only wrapped with isSubmitting
  // so the button can show a spinner instead of doing nothing while the
  // request is in flight.
  // -----------------------------------------------------------------------
  Future<bool> UpdatePassword({required String NewPassword}) async {
    isSubmitting.value = true;
    try {
      const String url = Backend_Server_Url + "api/Profile/updatepassword";
      Map<String, dynamic> new_data = {
        "Email": _email,
        "Password": NewPassword,
      };
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $_jwtToken',
        },
        body: json.encode(new_data),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        print("Update password success");
        return true;
      } else {
        print("Update password fail.");
        return false;
      }
    } catch (obj) {
      print("Update password fail.");
      print(obj.toString());
      return false;
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }

  /// Client-side validation only — does not touch the API call itself.
  /// Returns null when valid, or an error message to show inline.
  String? validate({required String newPassword, required String confirmPassword}) {
    if (newPassword.isEmpty) return "Please enter a new password.";
    if (newPassword.length < 6) return "Password must be at least 6 characters.";
    if (newPassword != confirmPassword) return "Passwords do not match.";
    return null;
  }
}