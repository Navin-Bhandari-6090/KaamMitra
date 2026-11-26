import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../constant/variable.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common method/ui_kit.dart';


class AddNoticeGetx extends GetxController {
  AddNoticeGetx({required this.jwtToken});

  final String jwtToken;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController serviceIdController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final RxBool isVerifying = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxInt serviceId = 0.obs;
  final RxString message = ''.obs;

  BuildContext get _context {
    final BuildContext? ctx = Get.context;
    if (ctx == null) throw StateError('No active context');
    return ctx;
  }

  @override
  void onInit() {
    super.onInit();
    serviceIdController.addListener(() {
      serviceId.value = int.tryParse(serviceIdController.text.trim()) ?? 0;
    });
    messageController.addListener(() {
      message.value = messageController.text;
    });
  }

  @override
  void onReady() {
    super.onReady();
    verifySession();
  }

  /// Same call that was previously in initState.
  Future<void> verifySession() async {
    try {
      isVerifying.value = true;
      await Provider_Jwt_Verify(Jwt_Token: jwtToken, context: _context);
    } catch (e, s) {
      debugPrint('AddNotice verifySession error: $e\n$s');
    } finally {
      isVerifying.value = false;
    }
  }

  String? validateServiceId(String? value) {
    final int? id = int.tryParse((value ?? '').trim());
    if (id == null || id <= 0) return 'Enter a valid service ID';
    return null;
  }

  String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Notice message is required';
    }
    return null;
  }

  /// Validates, asks for confirmation, then calls the API.
  Future<void> submitNotice() async {
    try {
      if (isSubmitting.value) return;

      final bool valid = formKey.currentState?.validate() ?? false;
      if (!valid) return;

      final bool confirmed = await confirmAction(
        title: 'Add this notice?',
        message: 'A new notice will be added to service #${serviceId.value}.',
        confirmText: 'Add notice',
      );
      if (!confirmed) return;

      isSubmitting.value = true;

      final int result = await addNotice(
        context: _context,
        jwtToken: jwtToken,
        ProviderServiceId: serviceId.value,
        Message: messageController.text,
      );

      if (result == 1) {
        clearForm();
      }
    } catch (e, s) {
      debugPrint('AddNotice submitNotice error: $e\n$s');
      showAppSnack('Error', 'Something went wrong. Please try again.',
          error: true);
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearForm() {
    serviceIdController.clear();
    messageController.clear();
    formKey.currentState?.reset();
  }

  /// API call moved from the screen. The body matches NoticeInfoDTO:
  /// the provider comes from the JWT and CreatedAt is set on the server.
  Future<int> addNotice({
    required BuildContext context,
    required String jwtToken,
    required int ProviderServiceId,
    required String Message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Backend_Server_Url}api/Service/addnotice'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'ProviderServiceId': ProviderServiceId,
          'Message': Message,
        }),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg('Notice added successfully.');
        return 1;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg('Invalid notice information.');
        return 2;
      } else if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 506) {
        Toast.Toastmsg('Unauthorized. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 507) {
        Toast.Toastmsg('Invalid service ID.');
        return 4;
      } else if (response.statusCode == 508) {
        Toast.Toastmsg('Notice message is required.');
        return 5;
      } else if (response.statusCode == 510) {
        Toast.Toastmsg('Provider account not found.');
        return 6;
      } else if (response.statusCode == 511) {
        Toast.Toastmsg('Your account has been blocked.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 512) {
        Toast.Toastmsg('Service not found or does not belong to you.');
        return 7;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Server error. Please try again later.');
        return 8;
      } else {
        Toast.Toastmsg('Something went wrong. Please try again.');
        return 0;
      }
    } catch (e, s) {
      debugPrint('AddNotice API error: $e\n$s');
      Toast.Toastmsg('Unable to connect to the server.');
      return 0;
    }
  }

  @override
  void onClose() {
    serviceIdController.dispose();
    messageController.dispose();
    super.onClose();
  }
}