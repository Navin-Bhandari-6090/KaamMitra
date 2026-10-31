import 'package:get/get.dart';

class SelectServiceProviderInfoScreenGetx extends GetxController {
  // ============================================================
  // UI-only reactive state — replaces setState for button press
  // feedback (gallery / book actions).
  // ============================================================

  RxBool isGalleryPressed = false.obs;
  RxBool isBookPressed = false.obs;

  void setGalleryPressed(bool value) => isGalleryPressed.value = value;
  void setBookPressed(bool value) => isBookPressed.value = value;

}