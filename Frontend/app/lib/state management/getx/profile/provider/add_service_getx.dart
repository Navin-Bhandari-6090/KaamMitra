import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class AddServiceGetx extends GetxController {
  // ============================================================
  // ORIGINAL — search text (UNCHANGED)
  // ============================================================

  RxString SearchText = "".obs;

  void ChangeSearchText(String NewValue) {
    this.SearchText.value = NewValue;
  }

  // ============================================================
  // NEW — UI-only reactive state for the redesigned screen.
  // Replaces every place a StatefulWidget would normally reach
  // for setState (submit-button loading state, press/hover
  // feedback, list-item hover highlight).
  // ============================================================

  /// True while the Add Service network call is in flight.
  RxBool isSubmitting = false.obs;

  /// True while the submit button is being pressed down (for the
  /// scale/press animation).
  RxBool isButtonPressed = false.obs;

  /// True while the search field has focus (for the glow border).
  RxBool isSearchFocused = false.obs;

  /// Index of the service list item currently hovered (desktop/web),
  /// -1 when nothing is hovered.
  RxInt hoveredServiceIndex = (-1).obs;

  void setSubmitting(bool value) {
    isSubmitting.value = value;
  }

  void setButtonPressed(bool value) {
    isButtonPressed.value = value;
  }

  void setSearchFocused(bool value) {
    isSearchFocused.value = value;
  }

  void setHoveredService(int index) {
    hoveredServiceIndex.value = index;
  }

  void clearHoveredService() {
    hoveredServiceIndex.value = -1;
  }
}