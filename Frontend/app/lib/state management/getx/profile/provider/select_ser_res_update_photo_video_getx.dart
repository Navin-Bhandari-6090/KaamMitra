import 'package:get/get.dart';


import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';

// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.

class SelectSerResUpdatePhotoVideoGetx extends GetxController {
  final Toast = Toastget();

  // ---------------------------------------------------------------------
  // REACTIVE UI STATE (no setState anywhere)
  // ---------------------------------------------------------------------
  final RxBool photoCardHovered = false.obs;
  final RxBool videoCardHovered = false.obs;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({required String jwtToken}) async {
    await Provider_Jwt_Verify(Jwt_Token: jwtToken);
  }

  void setPhotoHover(bool value) => photoCardHovered.value = value;
  void setVideoHover(bool value) => videoCardHovered.value = value;

  // -----------------------------------------------------------------------
  // Same session-check logic as the original, only the navigation call is
  // now context-free (GetX controllers have no BuildContext).
  // -----------------------------------------------------------------------
  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      Get.offAll(() => ErrorPage());
      Toast.Toastmsg("Session End.Relogin please.");
      return;
    }
  }
}