import 'package:get/get.dart';

class AddServiceResourcesGetx extends GetxController {
  // ============================================================
  // UI-only reactive state for the redesigned screen. Replaces
  // every place a StatefulWidget would normally reach for
  // setState (submit-button loading state, press feedback on the
  // photo/video pick buttons and the submit button).
  // ============================================================

  /// True while the Add Service Resources network call is in flight.
  RxBool isSubmitting = false.obs;

  /// Press-down feedback for each button (scale animation).
  RxBool isSubmitButtonPressed = false.obs;
  RxBool isPhotoButtonPressed = false.obs;
  RxBool isVideoButtonPressed = false.obs;

  void setSubmitting(bool value) {
    isSubmitting.value = value;
  }

  void setSubmitButtonPressed(bool value) {
    isSubmitButtonPressed.value = value;
  }

  void setPhotoButtonPressed(bool value) {
    isPhotoButtonPressed.value = value;
  }

  void setVideoButtonPressed(bool value) {
    isVideoButtonPressed.value = value;
  }
}