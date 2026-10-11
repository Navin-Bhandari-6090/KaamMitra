
import 'package:get/get.dart';

class GreenTextfieldGetx extends GetxController {
  final RxBool isFocused = false.obs;

  void ChangeFocus(bool focused) {
    isFocused.value = focused;
  }
}