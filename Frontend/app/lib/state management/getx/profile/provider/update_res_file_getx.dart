import 'package:app/constant/Server_Database.dart';
import 'package:app/constant/variable.dart';
import 'package:app/web/common method/Commmon_Method.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

class UpdateResFileGetx extends GetxController {
  final TextEditingController resourceIdCont = TextEditingController();
  final RxString resourceId = ''.obs;
  final RxBool isUpdating = false.obs;

  late String _jwtToken;

  void init(String jwtToken) {
    _jwtToken = jwtToken;
  }

  @override
  void onClose() {
    resourceIdCont.dispose();
    super.onClose();
  }

  void onResourceIdChanged(String value) {
    resourceId.value = value.trim();
  }

  Future<void> pickFile() async {
    try {
      await PickFile();
    } catch (_) {
      Toast.Toastmsg("Could not open the file picker. Please try again.");
    }
  }

  bool validate() {
    try {
      final String raw = resourceIdCont.text.trim();
      if (raw.isEmptyOrNull) {
        Toast.Toastmsg("Resource Id is required.");
        return false;
      }
      if (int.tryParse(raw) == null) {
        Toast.Toastmsg("Enter a valid resource id.");
        return false;
      }
      if (change_file_cont_getx.fileBytes.value == null) {
        Toast.Toastmsg("Service file is required.");
        return false;
      }
      return true;
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
      return false;
    }
  }

  Future<void> updateFile() async {
    if (isUpdating.value) return;
    try {
      isUpdating.value = true;
      await UpdateFile(
        Jwt_Token: _jwtToken,
        ProviderServiceResourcesId: int.parse(resourceIdCont.text.trim()),
        FileBytes: change_file_cont_getx.fileBytes.value!,
      );
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    } finally {
      isUpdating.value = false;
    }
  }

  Future<int> UpdateFile({
    required String Jwt_Token,
    required int ProviderServiceResourcesId,
    required List<int> FileBytes,
  }) async {
    try {
      if (FileBytes.isEmpty) {
        Toast.Toastmsg("Please select a valid file to upload.");
        return 400;
      }

      final String url =
          Backend_Server_Url + "api/Profile/updateserviceresourcefile";

      final request = http.MultipartRequest("PUT", Uri.parse(url));

      request.headers["Authorization"] = "Bearer $Jwt_Token";

      request.fields["ProviderServiceResourcesId"] =
          ProviderServiceResourcesId.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          "ServiceFile",
          FileBytes,
          filename: "service_file.pdf",
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Service file updated successfully.",
        );
        return 200;
      }

      final Map<int, String> statusMessages = {
        400: "The provided data is not in the correct format.",
        401: "Invalid provider authentication.",
        404: "Service resource not found or does not belong to the current provider.",
        506: "You have been blocked by System. Contact the KaamMitra community.",
        500: "An error occurred while updating the service resource file.",
      };

      final String backendMessage = response.body.trim();

      Toast.Toastmsg(
        backendMessage.isNotEmpty
            ? backendMessage
            : statusMessages[response.statusCode] ??
            "Failed to update service file. Status code: ${response.statusCode}",
      );

      return response.statusCode;
    } catch (_) {
      Toast.Toastmsg(
        "Something went wrong while updating the service file. Please try again.",
      );
      return 500;
    }
  }
}