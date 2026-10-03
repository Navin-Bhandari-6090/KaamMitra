import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class UpdateUserLoginAccessGetx extends GetxController
{
  // ---- Live search: substring match on user number ----
  final RxString searchQuery = "".obs;

  // ---- Bump after a successful update to refetch the user list ----
  final RxInt refreshTick = 0.obs;

  // ---- UI-only reactive state ----
  final RxBool numberFocused = false.obs;
  final RxBool isUpdating = false.obs;
}