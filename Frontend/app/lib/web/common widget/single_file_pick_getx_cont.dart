import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

class FilePickerController extends GetxController {
  RxString filePath = "".obs;
  RxString fileExtension = "".obs;
  Rx<Uint8List?> fileBytes = Rx<Uint8List?>(null);

  Future<int> pickFile() async {
    try {
      // 1. Modern v12 single file selection method
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file != null) {
        // 2. Load the bytes safely using the new v12 instance method
        Uint8List bytes = await file.readAsBytes();

        // 3. Fallback path if web environment turns it null
        String path = file.path ?? file.name;

        // 4. FIX: Safely parse out the extension using the modern v12 style
        String extension = file.name.split('.').last.toLowerCase();

        // Check file size (e.g., 2GB limit)
        int fileSize = bytes.length;
        if (fileSize <= 2 * 1024 * 1024 * 1024) {
          filePath.value = path;
          fileBytes.value = bytes;
          fileExtension.value = extension;

          // print("File Path/Name: $path");
          // print("File Extension: $extension");
          // print("File Size: ${fileSize / (1024 * 1024)} MB");

          return 1; // Success
        } else {
          // print("File exceeds size limit.");
          return 2; // File too large
        }
      } else {
        // print("No file selected.");
        return 3; // Cancelled
      }
    } catch (e) {
      // print("Error picking file: $e");
      return 4; // Error occurred
    }
  }
}
