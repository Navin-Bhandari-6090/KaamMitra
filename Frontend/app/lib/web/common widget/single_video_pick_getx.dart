import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../constant/variable.dart';

class PickSingleVideoController extends GetxController {
  RxString videoPath = "".obs;
  RxString videoExtension = "".obs;
  Rx<Uint8List?> videoBytes = Rx<Uint8List?>(null);

  Future<int> pickVideo() async {
    try {
      final ImagePicker videoPicker = ImagePicker();

      final XFile? video = await videoPicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video == null) {
        // print("No video selected.");
        return 4;
      }

      // Use video.name instead of video.path on Flutter Web
      final String fileExtension =
      video.name.split('.').last.toLowerCase();

      // print("Video name: ${video.name}");
      // print("Video extension: $fileExtension");

      if (fileExtension != 'mp4') {
        // print("Invalid video format. Supported format: MP4");
        return 3;
      }
      //
      // print("Video format is valid.");

// Read video into memory
      final Uint8List bytes = await video.readAsBytes();

// Calculate size from bytes
      final int fileSize = bytes.length;

      // print(
      //   "Video size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB",
      // );

// 1 GB limit
      const int maxSize = 1 * 1024 * 1024 * 1024;

      if (fileSize > maxSize) {
        // print("Video file larger then ${PhotoSize}..");
        return 2;
      }

      // print("Video size is valid.");

      // Save information
      videoPath.value = video.path;
      videoExtension.value = fileExtension;
      videoBytes.value = bytes;

      // print("Video selected successfully.");

      return 1;
    } catch (e) {
      // print("Exception caught while selecting video: $e");
      return 5;
    }
  }
}




