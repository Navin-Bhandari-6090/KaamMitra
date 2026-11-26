import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/web/common%20method/Commmon_Method.dart';

import '../../../../constant/variable.dart';
import '../../../../web/profile/provider/add_notice.dart';
import '../../../../web/profile/provider/view_notice.dart';




class NoticeActionSelectGetx extends GetxController {
  NoticeActionSelectGetx({required this.jwtToken});

  final String jwtToken;

  final RxBool isVerifying = false.obs;
  final RxInt hoveredIndex = (-1).obs;
  final RxnString errorMessage = RxnString();

  @override
  void onReady() {
    super.onReady();
    verifySession();
  }

  /// Same call that was previously in initState, now owned by the controller.
  Future<void> verifySession() async {
    try {
      final BuildContext? ctx = Get.context;
      if (ctx == null) return;

      isVerifying.value = true;
      errorMessage.value = null;

      await Provider_Jwt_Verify(Jwt_Token: jwtToken, context: ctx);
    } catch (e, s) {
      debugPrint('NoticeActionSelect verifySession error: $e\n$s');
      errorMessage.value = 'Unable to verify your session. Please try again.';
    } finally {
      isVerifying.value = false;
    }
  }

  void setHover(int index) => hoveredIndex.value = index;

  void openAddNotice() {
    _safeNavigate(
          () => Get.to(() => AddNotice(Current_User_JwtToken: jwtToken)),
    );
  }

  void openViewNotice() {
    _safeNavigate(
          () => Get.to(() => ViewNotice(Current_User_JwtToken: jwtToken)),
    );
  }

  void _safeNavigate(VoidCallback action) {
    try {
      action();
    } catch (e, s) {

      Toast.Toastmsg("Could not open this screen. Please try again.");
    }
  }
}