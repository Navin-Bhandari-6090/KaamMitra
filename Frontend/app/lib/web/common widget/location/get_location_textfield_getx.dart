import 'package:get/get.dart';

/// UI-only reactive state for UpdateLocation's two text fields — replaces
/// the setState-based focus tracking that used to live in the screen's
/// State class. Put/deleted with the screen's own unique tag, same
/// pattern as ChangeLocationGetx and GetLocationGetx.
class UpdateLocationFieldsGetx extends GetxController {
  RxBool isLatFocused = false.obs;
  RxBool isLngFocused = false.obs;

  void setLatFocused(bool value) => isLatFocused.value = value;
  void setLngFocused(bool value) => isLngFocused.value = value;
}