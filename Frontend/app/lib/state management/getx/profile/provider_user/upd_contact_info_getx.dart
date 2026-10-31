import 'dart:convert';

import 'package:app/constant/Server_Database.dart';
import 'package:app/web/common method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../../constant/variable.dart';

class UpdContactInfoGetx extends GetxController {
  final TextEditingController phoneCont = TextEditingController();
  final TextEditingController whatsappCont = TextEditingController();

  final RxString phone = ''.obs;
  final RxString whatsapp = ''.obs;
  final RxBool isUpdating = false.obs;

  late String _jwtToken;

  void init(String jwtToken) {
    _jwtToken = jwtToken;
  }

  @override
  void onClose() {
    phoneCont.dispose();
    whatsappCont.dispose();
    super.onClose();
  }

  void onPhoneChanged(String value) {
    try {
      phone.value = value.trim();
    } catch (_) {}
  }

  void onWhatsappChanged(String value) {
    try {
      whatsapp.value = value.trim();
    } catch (_) {}
  }

  void clearForm() {
    try {
      phoneCont.clear();
      whatsappCont.clear();
      phone.value = '';
      whatsapp.value = '';
    } catch (_) {}
  }

  bool validate() {
    try {
      if (phoneCont.text.trim().isEmptyOrNull &&
          whatsappCont.text.trim().isEmptyOrNull) {
        Toast.Toastmsg("Anyone contact data is required.");
        return false;
      }
      return true;
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
      return false;
    }
  }

  Future<void> submit(BuildContext context) async {
    if (isUpdating.value) return;
    isUpdating.value = true;
    try {
      await UpdatContactInfo(
        PhoneNumber: phoneCont.text.trim(),
        WhatsappNumber: whatsappCont.text.trim(),
        Jwt_Token: _jwtToken,
        context: context,
      );
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    } finally {
      isUpdating.value = false;
    }
  }

  Future<int> UpdatContactInfo({
    required String? PhoneNumber,
    required String? WhatsappNumber,
    required String Jwt_Token,
    required BuildContext context,
  }) async {
    try {
      final bool updatePhone = PhoneNumber?.trim().isNotEmpty ?? false;
      final bool updateWhatsapp = WhatsappNumber?.trim().isNotEmpty ?? false;

      if (!updatePhone && !updateWhatsapp) {
        Toast.Toastmsg(
          "Please provide a phone number, WhatsApp number, or both.",
        );
        return 400;
      }

      final String url =
          Backend_Server_Url + "api/Profile/updatephonenumbers";

      final Map<String, dynamic> body = {};

      if (updatePhone) {
        body["phoneNumber"] = PhoneNumber!.trim();
      }

      if (updateWhatsapp) {
        body["whatsappPhoneNumber"] = WhatsappNumber!.trim();
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Jwt_Token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg("Contact information updated successfully.");
        phoneCont.clear();
        whatsappCont.clear();
        phone.value = '';
        whatsapp.value = '';
        return 200;
      }

      final Map<int, String> statusMessages = {
        400: "Please provide valid phone number format.Start with +.(+9779800000000).",
        401: "Invalid user authentication.",
        403: "You are not authorized to perform this action.",
        404: "User account not found.",
        500: "An error occurred while updating phone numbers.",
        506: "You have been blocked by System. Contact the KaamMitra community.",
      };

      Toast.Toastmsg("Failed to update = ${statusMessages[response.statusCode]}",
      );

      if(response.statusCode==400 || response.statusCode==404 || response.statusCode==506)
      {
          await Logout(context: context);
      }

      return response.statusCode;
    } catch (_) {
      Toast.Toastmsg(
        "Something went wrong while updating contact information. Please try again.",
      );
      return 500;
    }
  }
}