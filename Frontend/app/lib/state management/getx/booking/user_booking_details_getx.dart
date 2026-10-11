import 'package:get/get.dart';

// Adjust the relative import to your project structure.
import '../../../models/BookingInfoModel.dart';

class UserBookingDetailsGetx extends GetxController {

  // ORIGINAL (unchanged): toggled to make the advance payment photo reload.

  RxBool UpdateStatePhotoUpload = true.obs;

  ChangeUpdateStatePhotoUpload() {
    if (UpdateStatePhotoUpload.value == true) {
      UpdateStatePhotoUpload.value = false;
    } else {
      UpdateStatePhotoUpload.value = true;
    }
  }

  // NEW (UI state only — replaces setState and makes the screen reactive)


  /// Non-empty while an action runs: 'rate' | 'approve' | 'task' | 'upload'.
  final RxString busyKey = ''.obs;

  /// Rating text field focus (glow effect).
  final RxBool ratingFocused = false.obs;


  final Rxn<num> ratingValue = Rxn<num>();
  final Rxn<bool> userApproval = Rxn<bool>();
  final Rxn<bool> userTaskComplete = Rxn<bool>();

  void seed(BookingInfoModel? b) {
    try {
      ratingValue.value = b?.ratingValueUser;
      userApproval.value = b?.userApprovalStatus;
      userTaskComplete.value = b?.userTaskCompleteStatus;
    } catch (obj) {
      print(obj.toString());
    }
  }
}