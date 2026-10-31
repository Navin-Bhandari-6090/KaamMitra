import 'package:app/constant/Server_Database.dart';
import 'package:app/constant/variable.dart';
import 'package:app/web/common method/Commmon_Method.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

class SendMediaGetx extends GetxController {
  final TextEditingController descriptionCont = TextEditingController();
  final TextEditingController receiverCont = TextEditingController();

  final RxString description = ''.obs;
  final RxString receiverId = ''.obs;
  final RxBool isSending = false.obs;

  String _jwtToken = '';

  void init(String jwtToken) {
    _jwtToken = jwtToken;
  }

  @override
  void onClose() {
    descriptionCont.dispose();
    receiverCont.dispose();
    super.onClose();
  }

  void onDescriptionChanged(String value) {
    try {
      description.value = value.trim();
    } catch (_) {}
  }

  void onReceiverChanged(String value) {
    try {
      receiverId.value = value.trim();
    } catch (_) {}
  }

  Future<void> pickPhoto() async {
    try {
      await PickPhoto();
    } catch (_) {
      Toast.Toastmsg("Could not open the photo picker. Please try again.");
    }
  }

  Future<void> pickVideo() async {
    try {
      await PickVideo();
    } catch (_) {
      Toast.Toastmsg("Could not open the video picker. Please try again.");
    }
  }

  Future<void> pickFile() async {
    try {
      await PickFile();
    } catch (_) {
      Toast.Toastmsg("Could not open the file picker. Please try again.");
    }
  }

  void clearMedia() {
    try {
      ClearFilesValues();
    } catch (_) {}
  }

  void clearAll() {
    try {
      descriptionCont.clear();
      receiverCont.clear();
      description.value = '';
      receiverId.value = '';
      ClearFilesValues();
    } catch (_) {}
  }

  bool hasAnyMedia() {
    return change_photo_cont_getx.imageBytes.value != null ||
        change_video_cont_getx.videoBytes.value != null ||
        change_file_cont_getx.fileBytes.value != null;
  }

  bool validate() {
    try {
      if (descriptionCont.text.trim().isEmptyOrNull ||
          receiverCont.text.trim().isEmptyOrNull) {
        Toast.Toastmsg("User ID and Description are mandatory.");
        return false;
      }
      if (int.tryParse(receiverCont.text.trim()) == null) {
        Toast.Toastmsg("Enter a valid user ID.");
        return false;
      }
      if (!hasAnyMedia()) {
        Toast.Toastmsg(
            "Among photo,video and files at least one media is required.");
        return false;
      }
      return true;
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
      return false;
    }
  }

  Future<void> submit(BuildContext context) async {
    if (isSending.value) return;
    isSending.value = true;
    try {
      await Add_Media(
        context: context,
        JwtToken: _jwtToken,
        MediaDescription: descriptionCont.text.trim(),
        ReceiverNumber: int.parse(receiverCont.text.trim()),
        ServicePhoto: change_photo_cont_getx.imageBytes.value,
        ServiceVideo: change_video_cont_getx.videoBytes.value,
        ServiceFile: change_file_cont_getx.fileBytes.value,
        PhotoExtension: change_photo_cont_getx.imageExtension.value,
        VideoExtension: change_video_cont_getx.videoExtension.value,
        FileExtension: change_file_cont_getx.fileExtension.value,
      );
    } catch (_) {
      Toast.Toastmsg("Something went wrong. Please try again.");
    } finally {
      isSending.value = false;
    }
  }

  Future<int> Add_Media({
    required BuildContext context,
    required String JwtToken,
    required String MediaDescription,
    required int ReceiverNumber,
    required List<int>? ServicePhoto,
    required List<int>? ServiceVideo,
    required List<int>? ServiceFile,
    required String? PhotoExtension,
    required String? VideoExtension,
    required String? FileExtension,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Profile/addmedia";

      final bool hasPhoto = ServicePhoto != null && ServicePhoto.isNotEmpty;
      final bool hasVideo = ServiceVideo != null && ServiceVideo.isNotEmpty;
      final bool hasFile = ServiceFile != null && ServiceFile.isNotEmpty;

      if (!hasPhoto && !hasVideo && !hasFile) {
        Toast.Toastmsg(
          "At least one media among photo, video, or file is required.",
        );
        return 12;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      request.headers['Authorization'] = 'Bearer $JwtToken';

      request.fields['MediaDescription'] = MediaDescription.trim();
      request.fields['ReceiverNumber'] = ReceiverNumber.toString();

      if (hasPhoto) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ServicePhoto',
            ServicePhoto!,
            filename: 'ServicePhoto.$PhotoExtension',
          ),
        );
      }

      if (hasVideo) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ServiceVideo',
            ServiceVideo!,
            filename: 'ServiceVideo.$VideoExtension',
          ),
        );
      }

      if (hasFile) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ServiceFile',
            ServiceFile!,
            filename: 'ServiceFile.$FileExtension',
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final int statusCode = response.statusCode;

      if (statusCode == 201) {
        Toast.Toastmsg("Media shared successfully.");
        return 1;
      } else if (statusCode == 400) {
        Toast.Toastmsg("The provided media information is invalid.");
        return 2;
      } else if (statusCode == 401) {
        Toast.Toastmsg("Invalid sender authentication. Please log in again.");
        await Logout(context: context);
        return 3;
      } else if (statusCode == 500) {
        Toast.Toastmsg("An error occurred while sharing media. Please try again.");
        return 7;
      } else if (statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by System. Contact the KaamMitra community.",
        );
        await Logout(context: context);
        return 8;
      } else if (statusCode == 520) {
        Toast.Toastmsg("Sender account not found.");
        await Logout(context: context);
        return 9;
      } else if (statusCode == 521) {
        Toast.Toastmsg("Receiver account not found.");
        return 10;
      } else if (statusCode == 525) {
        Toast.Toastmsg("Sender and receiver account same.Fail.");
        return 10;
      } else if (statusCode == 522) {
        Toast.Toastmsg("The receiver account is blocked.");
        return 11;
      } else if (statusCode == 523) {
        Toast.Toastmsg(
          "At least one media among photo, video, or file is required.",
        );
        return 12;
      } else {
        Toast.Toastmsg("Unable to share media. Please try again.");
        return 13;
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong while sharing media.");
      return 14;
    }
  }
}