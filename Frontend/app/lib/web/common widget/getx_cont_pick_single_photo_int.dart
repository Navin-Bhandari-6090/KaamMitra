
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../constant/variable.dart';

class pick_single_photo_getx_int extends GetxController {
  RxString imagePath = "".obs;
  RxString imageExtension = "".obs;
  Rx<Uint8List?> imageBytes = Rx<Uint8List?>(null);

  Future<int> pickImage() async {
    try {
      final ImagePicker imagePicker = ImagePicker();

      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        // Get file extension
        String fileExtension =
        image.name.split('.').last.toLowerCase();

        print("Photo Extension type = $fileExtension");

        // Validate extension
        if (fileExtension != 'jpg' &&
            fileExtension != 'jpeg' &&
            fileExtension != 'png') {
          print("Invalid photo format.");
          return 2;
        }

        // Read image bytes
        final Uint8List bytes = await image.readAsBytes();

        // 100 MB
        const int maxSize = 100 * 1024 * 1024;

        print("Photo size = ${bytes.length} bytes");
        print("Photo size = ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB");

        // Validate file size
        if (bytes.length > maxSize)
        {
          print("Photo is larger then ${PhotoSize}.");
          // Clear previous image if necessary
          imagePath.value = "";
          imageExtension.value = "";
          imageBytes.value = null;
          return 5;
        }

        // Store data
        imageExtension.value = fileExtension;
        imagePath.value = image.path;
        imageBytes.value = bytes;

        print("Image select success.");

        return 1;
      } else {
        print("Image not selected. Image picker.");
        return 3;
      }
    } catch (obj) {
      print("Exception caught while selecting image");
      print("Exception = ${obj.toString()}");

      return 4;
    }
  }
}