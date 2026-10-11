import 'package:get/get.dart';

class Providerbookingdetalsgetx extends GetxController {
  // Toggles to force a reload of the advance payment photo / QR.
  final RxBool UpdateStatePhotoUpload = true.obs;

  // '' = idle, otherwise the name of the running action (drives loaders & disables buttons).
  final RxString busyKey = ''.obs;

  // Reactive booking status values.
  final Rxn<bool> providerApproval = Rxn<bool>();      // this provider approved
  final Rxn<bool> providerTaskComplete = Rxn<bool>();  // this provider finished the task
  final Rxn<bool> customerApproval = Rxn<bool>();      // customer approved
  final Rxn<bool> customerTaskComplete = Rxn<bool>();  // customer finished the task
  final Rxn<num> advanceAmount = Rxn<num>();

  /// Loads the values from the booking model. Call once when the screen opens.
  void seed({
    bool? providerApproval,
    bool? providerTaskComplete,
    bool? customerApproval,
    bool? customerTaskComplete,
    num? advanceAmount,
  }) {
    busyKey.value = '';
    this.providerApproval.value = providerApproval;
    this.providerTaskComplete.value = providerTaskComplete;
    this.customerApproval.value = customerApproval;
    this.customerTaskComplete.value = customerTaskComplete;
    this.advanceAmount.value = advanceAmount;
  }

  void ChangeUpdateStatePhotoUpload() {
    UpdateStatePhotoUpload.value = !UpdateStatePhotoUpload.value;
  }
}