import 'package:get/get.dart';

import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';



class ProviderSelPhoVidFilGalleryGetx extends GetxController {
  // Session state
  final RxBool isVerifying = true.obs;
  final RxBool isSessionValid = false.obs;

  // UI animation state (replaces setState-driven UI updates)
  final RxList<bool> cardVisible = <bool>[false, false, false].obs;
  final RxList<bool> cardHover = <bool>[false, false, false].obs;

  Future<void> verifyJwt({required String jwtToken}) async {
    isVerifying.value = true;

    final int result = await UserProviderJwtVerify(Jwt_Token: jwtToken);

    if (result == 1) {
      isSessionValid.value = true;
      isVerifying.value = false;
      _playEntranceAnimation();
    } else {
      isSessionValid.value = false;
      isVerifying.value = false;
      Toastget().Toastmsg("Session End.Relogin please.");
    }
  }

  void _playEntranceAnimation() {
    for (int i = 0; i < cardVisible.length; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
        if (i < cardVisible.length) {
          cardVisible[i] = true;
          cardVisible.refresh();
        }
      });
    }
  }

  void setHover(int index, bool value) {
    if (index < cardHover.length && cardHover[index] != value) {
      cardHover[index] = value;
      cardHover.refresh();
    }
  }

  @override
  void onClose() {
    cardVisible.close();
    cardHover.close();
    super.onClose();
  }
}