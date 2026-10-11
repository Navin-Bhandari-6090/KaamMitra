import 'package:get/get.dart';

class ProUpdRegServDescp extends GetxController {
  // true while an update request is running (drives loader and disables buttons)
  final RxBool busy = false.obs;

  // live character count of the description field
  final RxInt descLength = 0.obs;

  // last successfully saved values (shown in the "Current details" card)
  final Rxn<int> savedServiceId = Rxn<int>();
  final RxnString savedDescription = RxnString();

  /// Called by the screen after the server confirms a successful update.
  void onSaved(int serviceId, String description) {
    savedServiceId.value = serviceId;
    savedDescription.value = description;
  }
}