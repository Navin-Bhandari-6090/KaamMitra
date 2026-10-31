import 'dart:convert';

import 'package:app/constant/Server_Database.dart';
import 'package:app/web/common method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../../../constant/variable.dart';

class UpdServResTitleGetx extends GetxController {
  final TextEditingController resourceIdCont = TextEditingController();
  final TextEditingController titleCont = TextEditingController();

  final RxString resourceId = ''.obs;
  final RxString title = ''.obs;
  final RxBool isUpdating = false.obs;

  late String _jwtToken;

  void init(String jwtToken) {
    _jwtToken = jwtToken;
  }

  @override
  void onClose() {
    resourceIdCont.dispose();
    titleCont.dispose();
    super.onClose();
  }

  void onResourceIdChanged(String value) {
    try {
      resourceId.value = value.trim();
    } catch (_) {}
  }

  void onTitleChanged(String value) {
    try {
      title.value = value;
    } catch (_) {}
  }

  void clearForm() {
    try {
      resourceIdCont.clear();
      titleCont.clear();
      resourceId.value = '';
      title.value = '';
    } catch (_) {}
  }

  bool validate() {
    try {
      final String rawId = resourceIdCont.text.trim();
      final String rawTitle = titleCont.text.trim();

      if (rawId.isEmptyOrNull || rawTitle.isEmptyOrNull) {
        Toast.Toastmsg("Title and resource id is required.");
        return false;
      }
      if (int.tryParse(rawId) == null) {
        Toast.Toastmsg("Enter a valid resource id.");
        return false;
      }
      return true;
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
      return false;
    }
  }

  Future<void> submit({required BuildContext context}) async {
    if (isUpdating.value) return;
    isUpdating.value = true;
    try {
      await UpdateTitle(
        Jwt_Token: _jwtToken,
        ServiceTitle: titleCont.text.trim(),
        ProviderServiceResourcesId: int.parse(resourceIdCont.text.trim()),
        context: context,
      );
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    } finally {
      isUpdating.value = false;
    }
  }

  Future<int> UpdateTitle({
    required String ServiceTitle,
    required String Jwt_Token,
    required int ProviderServiceResourcesId,
    required BuildContext context,
  }) async {
    try {
      final String url =
          Backend_Server_Url + "api/Profile/updateserviceresourcetitle";

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $Jwt_Token",
        },
        body: jsonEncode({
          "ServiceTitle": ServiceTitle,
          "ProviderServiceResourcesId": ProviderServiceResourcesId,
        }),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg("Title updated successfully.",
        );
        return 200;
      }

      final Map<int, String> statusMessages = {
        400: "Invalid title information.",
        401: "Invalid authentication.",
        403: "You are not authorized to perform this action.",
        404: "The requested information was not found.",
        500: "An error occurred while updating the title.",
        506: "You have been blocked by System. Contact the KaamMitra community.",
      };

      Toast.Toastmsg(
      "${statusMessages[response.statusCode]}"
      );

      if(response.statusCode==401 || response.statusCode==403 || response.statusCode==506)
      {
        await Logout(context: context);
      }

      return response.statusCode;
    } catch (_) {
      Toast.Toastmsg(
        "Something went wrong while updating the title. Please try again.",
      );
      return 500;
    }
  }
}