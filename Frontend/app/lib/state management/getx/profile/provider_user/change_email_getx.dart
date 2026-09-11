import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/authentication/Login.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';

// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.
// Mirrors ChangePhotoGetx / ChangeVideoGetx one-to-one so all three screens
// share the exact same controller shape/behaviour.

class ChangeEmailGetx extends GetxController {
  final Toast = Toastget();

  // ---------------------------------------------------------------------
  // REACTIVE UI STATE (no setState anywhere)
  // ---------------------------------------------------------------------
  final RxBool isSubmitting = false.obs;

  late String _jwtToken;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({required String jwtToken}) async {
    _jwtToken = jwtToken;
    await Provider_User_Jwt_Verify(Jwt_Token: jwtToken);
  }

  // -----------------------------------------------------------------------
  // Same session-check logic as the original, only the navigation call is
  // now context-free (GetX controllers have no BuildContext).
  // -----------------------------------------------------------------------
  Future<void> Provider_User_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
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
  // Your API call, kept exactly as written (including the original
  // status-code handling and print statements) — only wrapped with
  // isSubmitting so the button can show a spinner instead of doing nothing
  // while the request is in flight.
  // -----------------------------------------------------------------------
  Future<void> ChangeEmail({required String NewEmail, required String OldEmail}) async {
    isSubmitting.value = true;
    try {
      const String url = Backend_Server_Url + "api/Profile/updateemail";
      Map<String, dynamic> UserDetails = {
        "NewEmail": NewEmail,
        "OldEmail": OldEmail,
      };
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $_jwtToken',
        },
        body: json.encode(UserDetails),
      );
      if (response.statusCode == 200) {
        print("Update email success.");
        Toast.Toastmsg("Update email success.");
        await Clear_User_Data();
        await Random_token_Clear();
        Get.offAll(() => LoginScreen(User_JwtToken: _jwtToken));
        Toast.Toastmsg("Please login again.");
        return;
      } else if (response.statusCode == 500) {
        final data = jsonDecode(response.body);
        print("Exception Message: ${data['error']}");
        print("Exception caught in backend.");
        Toast.Toastmsg("Server erro try again.");
        return;
      } else if (response.statusCode == 501) {
        print("Details are not in correct format.");
        Toast.Toastmsg("Provide deatails in correct format.");
        return;
      } else if (response.statusCode == 502) {
        print("Old email does not match");
        Toast.Toastmsg("Yout current email doesn't match.");
        await Clear_User_Data();
        await Random_token_Clear();
        Get.offAll(() => LoginScreen(User_JwtToken: _jwtToken));
        return;
      } else {
        print("Update email failed.");
        Toast.Toastmsg("Server error try again.");
        return;
      }
    } catch (obj) {
      print("Exception in ChangeEmail: $obj");
      Toast.Toastmsg("Server error try again.");
      return;
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }
}