import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../web/common method/Commmon_Method.dart';



class DeleteUserGetx extends GetxController
    with GetSingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // State (all reactive – the screen never needs setState)
  // ---------------------------------------------------------------------------
  final TextEditingController UserNumberController = TextEditingController();

  /// True while the delete request is running.
  final RxBool isDeleting = false.obs;

  /// Result banner shown under the button after a request.
  final RxString statusMessage = ''.obs;
  final RxBool statusIsSuccess = false.obs;

  /// Hover state of the delete button (web).
  final RxBool deleteHovered = false.obs;

  /// Drives the soft pulsing glow on the header icon.
  late final AnimationController pulse;

  @override
  void onInit() {
    super.onInit();
    pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void onClose() {
    try {
      pulse.dispose();
      UserNumberController.dispose();
    } catch (_) {}
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Admin check (same call that used to be in initState)
  // ---------------------------------------------------------------------------
  void verifyAdmin({
    required String jwtToken,
    required BuildContext context,
  }) {
    try {
      Admin_Jwt_Verify(Jwt_Token: jwtToken, context: context);
    } catch (e) {
      debugPrint('DeleteUserGetx.verifyAdmin error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Validation (same messages as before). Returns the id or null.
  // ---------------------------------------------------------------------------
  int? validateUserId() {
    try {
      final String text = UserNumberController.text.trim();

      if (text.isEmpty) {
        Toast.Toastmsg("User id is required.");
        return null;
      }

      final int? value = int.tryParse(text);
      if (value == null) {
        Toast.Toastmsg("Enter a valid numeric user id.");
        return null;
      }
      return value;
    } catch (e) {
      debugPrint('DeleteUserGetx.validateUserId error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete request (same endpoint, headers, body and status handling)
  // ---------------------------------------------------------------------------
  Future<void> DeleteUserInfo({
    required int UserNumber,
    required String Current_User_JwtToken,
    required BuildContext context,
  }) async {
    try {
      isDeleting.value = true;
      statusMessage.value = '';

      final String url = "${Backend_Server_Url}api/Admin/deleteuserinfo";

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Current_User_JwtToken",
        },
        body: jsonEncode({
          "UserNumber": UserNumber,
        }),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg("User deleted successfully.");
        UserNumberController.clear();
        _setStatus(
          true,
          "User ID $UserNumber and all linked data were deleted.",
        );
        return;
      }

      String errorMessage = response.body.trim();

      if (errorMessage.isEmpty) {
        errorMessage = "Something went wrong. Please try again.";
      }

      String shown = errorMessage;

      switch (response.statusCode) {
        case 400:
          Toast.Toastmsg(errorMessage);
          break;

        case 401:
          shown = "Unauthorized. Please login again.";
          Toast.Toastmsg(shown);
          if (context.mounted) Logout(context: context);
          break;

        case 403:
          shown = "Admin access required.";
          Toast.Toastmsg(shown);
          if (context.mounted) Logout(context: context);
          break;

        case 404:
          Toast.Toastmsg(errorMessage);
          break;

        case 500:
          Toast.Toastmsg(errorMessage);
          break;

        default:
          Toast.Toastmsg(errorMessage);
          break;
      }

      _setStatus(false, shown);
    } catch (e) {
      debugPrint('DeleteUserGetx.DeleteUserInfo error: $e');
      Toast.Toastmsg("Something went wrong. Please try again.");
      _setStatus(false, "Something went wrong. Please try again.");
    } finally {
      isDeleting.value = false;
    }
  }

  void _setStatus(bool success, String message) {
    statusIsSuccess.value = success;
    statusMessage.value = message;
  }
}