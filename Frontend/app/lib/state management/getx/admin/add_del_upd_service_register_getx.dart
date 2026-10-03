import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class AddDelUpdServiceRegister extends GetxController
{
  // ---- New feature: live substring search by service name ----
  final RxString searchQuery = "".obs;

  // ---- New feature: bump this after Add/Delete/Update succeeds
  // to trigger a fresh GetRegisterServiceInfo() call. ----
  final RxInt refreshTick = 0.obs;

  // ---- UI-only reactive state: focus glow + loading indicators ----
  final RxBool searchFocused = false.obs;
  final RxBool newServiceNameFocused = false.obs;
  final RxBool serviceDescFocused = false.obs;
  final RxBool domesticPriceFocused = false.obs;
  final RxBool domesticDiscountFocused = false.obs;
  final RxBool internationalPriceFocused = false.obs;
  final RxBool internationalDiscountFocused = false.obs;
  final RxBool serviceIdFocused = false.obs;

  final RxBool isAddingService = false.obs;
  final RxBool isDeletingService = false.obs;
  final RxBool isUpdatingPrice = false.obs;
}