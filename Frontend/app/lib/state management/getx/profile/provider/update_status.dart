import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:app/constant/Server_Database.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:app/web/home/Home_Screen.dart';

// State + API call of UpdateStatus. API logic is unchanged from the original screen.
// Named UpdateStatusGetx because the screen widget is already called UpdateStatus.
class UpdateStatusGetx extends GetxController {
  final Toastget _toast = Toastget();

  String _jwt = '';

  // True while the request runs (loader + disabled button).
  final RxBool isBusy = false.obs;

  // Last failed outcome shown in the result card: 0 none, 2 blocked, 3 failed.
  final RxInt resultCode = 0.obs;
  final RxString resultMessage = ''.obs;

  void init(String jwt) {
    _jwt = jwt;
    isBusy.value = false;
    resultCode.value = 0;
  }

  Future<void> verifyJwt(BuildContext context) async {
    try {
      await Provider_Jwt_Verify(Jwt_Token: _jwt, context: context);
    } catch (_) {}
  }

  void dismissResult() => resultCode.value = 0;

  // Toast + remember the outcome for the result card.
  void _report(int code, String message) {
    _toast.Toastmsg(message);
    resultCode.value = code;
    resultMessage.value = message;
  }

  // Original API method. Returns 1 success, 2 blocked, 3 failure.
  Future<int> ChangeStatus({
    required BuildContext context,
    required String User_JwtToken,
  }) async {
    try {
      // Send the status toggle request.
      final response = await http.put(
        Uri.parse("${Backend_Server_Url}" + "api/Profile/changestatus"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $User_JwtToken",
        },
      );

      // Successful status update: go back to Home.
      if (response.statusCode == 200) {
        resultCode.value = 0;
        _toast.Toastmsg("Your status has been updated successfully.");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeScreenUi(UserLogin: true, User_JwtToken: _jwt),
          ),
              (route) => false,
        );
        return 1;
      }

      // API errors.
      switch (response.statusCode) {
        case 401:
          _report(3, "Your session has expired. Please login again.");
          await Logout(context: context);
          break;
        case 403:
          _report(3, "You are not authorized to perform this action.");
          break;
        case 505:
          _report(3, "User account not found.");
          await Logout(context: context);
          break;
        case 506:
          _report(2, "Your account has been blocked. Contact KaamMitra support.");
          await Logout(context: context);
          return 2;
        default:
          _report(3, "Unable to update your status. Please try again.");
          break;
      }

      return 3;
    } catch (_) {
      _report(3, "Something went wrong. Please try again.");
      return 3;
    }
  }

  // Runs the update with a busy flag so it cannot be tapped twice.
  Future<int> runChange(BuildContext context) async {
    if (isBusy.value) return 3;
    isBusy.value = true;
    try {
      return await ChangeStatus(context: context, User_JwtToken: _jwt);
    } catch (_) {
      return 3;
    } finally {
      isBusy.value = false;
    }
  }
}