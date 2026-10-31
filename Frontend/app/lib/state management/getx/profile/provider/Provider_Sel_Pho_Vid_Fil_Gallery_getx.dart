import 'package:get/get.dart';

import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';

class ProviderSelPhoVidFilGalleryGetx extends GetxController {
  // Session state
  final RxBool isVerifying = true.obs;
  final RxBool isSessionValid = false.obs;

  // UI animation state (replaces setState-driven UI updates).
  // NOT fixed to 3 any more: the screen calls setCardCount(n) with the real
  // number of actions, so you can add / remove actions freely.
  final RxList<bool> cardVisible = <bool>[].obs;
  final RxList<bool> cardHover = <bool>[].obs;

  /// Resize the animation lists to match the number of cards shown.
  void setCardCount(int count) {
    final int n = count < 0 ? 0 : count;
    cardVisible.assignAll(List<bool>.filled(n, false));
    cardHover.assignAll(List<bool>.filled(n, false));
  }

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