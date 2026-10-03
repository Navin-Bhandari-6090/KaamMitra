import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constant/variable.dart';
import '../../../web/common method/Commmon_Method.dart';

class AdminSendNotUserGetx extends GetxController
    with GetSingleTickerProviderStateMixin {
  final messageCont = TextEditingController();
  final userNumberCont = TextEditingController();

  final isSending = false.obs;
  final messageLength = 0.obs;
  final canSend = false.obs;

  String jwtToken = '';

  /// Drives the ambient blobs and glass bubbles (no setState needed).
  late final AnimationController bgAnim;

  @override
  void onInit() {
    super.onInit();
    bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    messageCont.addListener(_sync);
    userNumberCont.addListener(_sync);
  }

  void _sync() {
    try {
      messageLength.value = messageCont.text.trim().length;
      canSend.value = messageCont.text.trim().isNotEmpty &&
          userNumberCont.text.trim().isNotEmpty;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Returns true when inputs are valid.
  bool validate() {
    try {
      if (messageCont.text.trim().isEmpty ||
          userNumberCont.text.trim().isEmpty) {
        Toast.Toastmsg("Message and user Id cannot be empty.");
        return false;
      }
      if (int.tryParse(userNumberCont.text.trim()) == null) {
        Toast.Toastmsg("Please enter a valid user ID.");
        return false;
      }
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<void> send(BuildContext context) async {
    if (isSending.value) return;
    try {
      isSending.value = true;

      num ProviderNumberValue = int.parse(userNumberCont.text.trim());

      final AddNotificationsResult = await AddNotifications(
        ReceiverNumber: ProviderNumberValue,
        Message: messageCont.text.trim(),
        Current_User_JwtToken: jwtToken,
        context: context,
      );

      final AddNewNotificationsResult = await AddNewNotifications(
        ReceiverNumber: ProviderNumberValue,
        Status: true,
        Current_User_JwtToken: jwtToken,
        context: context,
      );

      if (_isSuccess(AddNotificationsResult) && _isSuccess(AddNewNotificationsResult)) {
        Toast.Toastmsg("Notification sent successfully.");
        messageCont.clear();
        userNumberCont.clear();
      } else {
        Toast.Toastmsg("Failed to send notification. Please try again.");
      }


    } catch (obj) {
      debugPrint(obj.toString());
      return;
    } finally {
      isSending.value = false;
    }
  }

  bool _isSuccess(dynamic r) {
    try {
      if (r == null) return false;
      if (r is bool) return r;
      final code = r.statusCode; // http.Response style
      if (code is int) return code >= 200 && code < 300;
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  void onClose() {
    try {
      messageCont.dispose();
      userNumberCont.dispose();
      bgAnim.dispose();
    } catch (e) {
      debugPrint(e.toString());
    }
    super.onClose();
  }
}