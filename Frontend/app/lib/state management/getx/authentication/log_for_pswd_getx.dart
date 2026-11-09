import 'dart:convert';

import 'package:app/constant/Server_Database.dart';
import 'package:app/constant/variable.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// State + API call for LogForPswd (forgot / update password screen).
class LogForPswdGetx extends GetxController {
  // ============================================================
  // UI state
  // ============================================================

  /// True while the update request is running (disables the button).
  final RxBool isLoading = false.obs;

  /// Show / hide password toggles.
  final RxBool hideOldPassword = true.obs;
  final RxBool hideNewPassword = true.obs;

  /// Key of the field that currently has focus (focus glow).
  final RxString focusedField = ''.obs;

  /// Live copy of the new password, used only for the strength meter.
  final RxString newPasswordText = ''.obs;

  void setLoading(bool value) => isLoading.value = value;
  void toggleOldPassword() => hideOldPassword.value = !hideOldPassword.value;
  void toggleNewPassword() => hideNewPassword.value = !hideNewPassword.value;
  void setFocusedField(String key) => focusedField.value = key;
  void clearFocusedField(String key) {
    if (focusedField.value == key) focusedField.value = '';
  }

  void setNewPasswordText(String value) => newPasswordText.value = value;

  /// 0 = empty, 1 = weak, 2 = fair, 3 = good, 4 = strong (UI hint only).
  int get passwordStrength {
    try {
      final String p = newPasswordText.value;
      if (p.isEmpty) return 0;
      int score = 0;
      if (p.length >= 8) score++;
      if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
      if (RegExp(r'\d').hasMatch(p)) score++;
      if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
      return score == 0 ? 1 : score;
    } catch (e) {
      // print("passwordStrength failed: $e");
      return 0;
    }
  }

  // ============================================================
  // SESSION
  // ============================================================

  void verifySession({
    required String jwtToken,
    required BuildContext context,
  }) {
    try {
      Random_Jwt_Verify(Jwt_Token: jwtToken, context: context);
    } catch (e) {
      // print("verifySession failed: $e");
    }
  }

  // ============================================================
  // VALIDATION (same order and messages as before)
  // Returns an error message, or null when everything is filled in.
  // ============================================================

  String? validateInputs({
    required String email,
    required String newPassword,
    required String oldPassword,
    required String phoneNumber,
    required String whatsappNumber,
  }) {
    if (email.trim().isEmpty) return "Please enter your email address.";
    if (newPassword.trim().isEmpty) return "Please enter your new password.";
    if (oldPassword.trim().isEmpty) return "Please enter your old password.";
    if (phoneNumber.trim().isEmpty) return "Please enter your phone number.";
    if (whatsappNumber.trim().isEmpty) {
      return "Please enter your WhatsApp number.";
    }
    return null;
  }

  // ============================================================
  // API — update password (logic unchanged, moved from the screen)
  // Returns: 1 success, 2 blocked, 3 invalid details, 4 session invalid,
  // 0 any other failure.
  // ============================================================

  Future<int> updatePassword({
    required BuildContext context,
    required String jwtToken,
    required String email,
    required String phoneNumber,
    required String whatsappPhoneNumber,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (isLoading.value) return 0;
    setLoading(true);

    try {
      final response = await http.put(
        Uri.parse('${Backend_Server_Url}api/Authentication/updatepassword'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'Email': email,
          'PhoneNumber': phoneNumber,
          'WhatsappPhoneNumber': whatsappPhoneNumber,
          'OldPassword': oldPassword,
          'NewPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg("Password updated successfully.");
        return 1;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("You have been blocked by the system.");
        if (context.mounted) await Logout(context: context);
        return 2;
      } else if (response.statusCode == 501) {
        Toast.Toastmsg("Invalid details or incorrect old password.");
        return 3;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        Toast.Toastmsg("Your session is invalid. Please login again.");
        if (context.mounted) await Logout(context: context);
        return 4;
      } else if (response.statusCode == 550) {
        Toast.Toastmsg("Your session is invalid..");
        if (context.mounted) await Logout(context: context);
        return 4;
      } else {
        Toast.Toastmsg("Unable to update password. Please try again later.");
        return 0;
      }
    } catch (e) {
      // print("updatePassword failed: $e");
      Toast.Toastmsg(
        "Something went wrong. Please check your internet connection.",
      );
      return 0;
    } finally {
      setLoading(false);
    }
  }
}