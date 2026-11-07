import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:app/constant/Server_Database.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:app/web/common%20widget/toast.dart';

// State + API call of AdminDelServORRes. API logic is unchanged from the original screen.
class AdminDelServResGetx extends GetxController {
  final Toastget _toast = Toastget();

  String _jwt = '';

  // Text controllers live here so the screen needs no setState.
  final ServiceIdController = TextEditingController();
  final ResourceIdController = TextEditingController();

  // Live copies of the typed ids (drive button label, banners and card glow).
  final RxString serviceText = ''.obs;
  final RxString resourceText = ''.obs;

  // True while the delete request runs.
  final RxBool isBusy = false.obs;

  // Last outcome shown in the result card: 0 none, 1 success, 2 partial, 3 failed.
  final RxInt resultCode = 0.obs;
  final RxString resultMessage = ''.obs;

  void init(String jwt) {
    _jwt = jwt;
    isBusy.value = false;
    resultCode.value = 0;
  }

  Future<void> verifyJwt(BuildContext context) async {
    try {
      await Admin_Jwt_Verify(Jwt_Token: _jwt, context: context);
    } catch (_) {}
  }

  // Which ids are typed: 'none' | 'service' | 'resource' | 'both'.
  String get mode {
    final bool s = _has(serviceText.value);
    final bool r = _has(resourceText.value);
    if (s && r) return 'both';
    if (s) return 'service';
    if (r) return 'resource';
    return 'none';
  }

  bool _has(String t) => (int.tryParse(t.trim()) ?? 0) > 0;

  void clearFields() {
    ServiceIdController.clear();
    ResourceIdController.clear();
    serviceText.value = '';
    resourceText.value = '';
  }

  void dismissResult() => resultCode.value = 0;

  // Same validation as the original function; returns an error message or null.
  String? validateIds(int? ProviderServiceId, int? ProviderServiceResourcesId) {
    // Only one ID is allowed.
    if (ProviderServiceId != null &&
        ProviderServiceId > 0 &&
        ProviderServiceResourcesId != null &&
        ProviderServiceResourcesId > 0) {
      return "Please provide only one ID.";
    }
    // At least one valid ID is required.
    if ((ProviderServiceId == null || ProviderServiceId <= 0) &&
        (ProviderServiceResourcesId == null || ProviderServiceResourcesId <= 0)) {
      return "Service or resource ID is required.";
    }
    return null;
  }

  // Toast + remember the outcome for the result card.
  void _report(int code, String message) {
    _toast.Toastmsg(message);
    resultCode.value = code;
    resultMessage.value = message;
  }

  // Original API method. Returns 1 success, 2 success with leftover files, 3 failure.
  Future<int> DeleteServORRes({
    required BuildContext context,
    required int? ProviderServiceId,
    required int? ProviderServiceResourcesId,
  }) async {
    try {
      final String? error =
      validateIds(ProviderServiceId, ProviderServiceResourcesId);
      if (error != null) {
        _report(3, error);
        return 3;
      }

      // Request body carries only one ID.
      final Map<String, dynamic> requestBody = {};
      if (ProviderServiceId != null && ProviderServiceId > 0) {
        requestBody["ProviderServiceId"] = ProviderServiceId;
      } else {
        requestBody["ProviderServiceResourcesId"] = ProviderServiceResourcesId;
      }

      final response = await http.post(
        Uri.parse("$Backend_Server_Url" + "api/Admin/deleteproserviceares"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $_jwt",
        },
        body: jsonEncode(requestBody),
      );

      // Successful deletion.
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData["FileCleanupIncomplete"] == true) {
          _report(2,
              "Deleted successfully, but some media files could not be removed.");
          return 2;
        }

        _report(1, "Deleted successfully.");
        return 1;
      }

      // API errors.
      switch (response.statusCode) {
        case 400:
          _report(3, "Invalid request. Please check the provided ID.");
          break;
        case 401:
          _report(3, "Your session has expired. Please login again.");
          await Logout(context: context);
          break;
        case 403:
          _report(3, "You are not authorized to perform this action.");
          break;
        case 404:
          _report(3, "Service or resource not found.");
          break;
        case 505:
          _report(3, "User account not found.");
          await Logout(context: context);
          break;
        case 506:
          _report(3, "Your account has been blocked. Contact KaamMitra support.");
          await Logout(context: context);
          break;
        case 512:
          _report(3, "Please provide only one ID at a time.");
          break;
        default:
          _report(3, "Unable to delete. Please try again later.");
          break;
      }
      return 3;
    } catch (_) {
      _report(3, "Something went wrong. Please try again.");
      return 3;
    }
  }

  // Runs the delete with a busy flag and clears the fields after a success.
  Future<int> runDelete(
      BuildContext context, {
        required int? serviceId,
        required int? resourceId,
      }) async {
    if (isBusy.value) return 3;
    isBusy.value = true;
    try {
      final int result = await DeleteServORRes(
        context: context,
        ProviderServiceId: serviceId,
        ProviderServiceResourcesId: resourceId,
      );
      if (result == 1 || result == 2) clearFields();
      return result;
    } catch (_) {
      return 3;
    } finally {
      isBusy.value = false;
    }
  }

  @override
  void onClose() {
    try {
      ServiceIdController.dispose();
      ResourceIdController.dispose();
    } catch (_) {}
    super.onClose();
  }
}