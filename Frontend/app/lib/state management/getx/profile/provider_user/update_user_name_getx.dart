import 'package:get/get.dart';

class UpdateUserNameGetx extends GetxController {
  // ============================================================
  // UI-only reactive state — replaces every place a StatefulWidget
  // would normally reach for setState (submit-button loading state,
  // press feedback, focus glow on each field).
  // ============================================================

  /// True while the update-name network call is in flight.
  RxBool isSubmitting = false.obs;

  /// True while the submit button is being pressed down (for the
  /// scale/press animation).
  RxBool isButtonPressed = false.obs;

  /// True while the First Name field has focus (for the glow border).
  RxBool isFirstNameFocused = false.obs;

  /// True while the Last Name field has focus (for the glow border).
  RxBool isLastNameFocused = false.obs;

  void setSubmitting(bool value) => isSubmitting.value = value;

  void setButtonPressed(bool value) => isButtonPressed.value = value;

  void setFirstNameFocused(bool value) => isFirstNameFocused.value = value;

  void setLastNameFocused(bool value) => isLastNameFocused.value = value;
}