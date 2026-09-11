import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

class CommonGetxCont extends GetxController {
  RxString CommonStringValue = "".obs;

  void CommonStringValueMethod(String NewValue) {
    this.CommonStringValue.value = NewValue;
  }

}