import 'package:app/web/profile/provider_user/send_media.dart';
import 'package:app/web/profile/provider_user/view_media.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectSharedMediaGetx extends GetxController {
  final RxBool isOpening = false.obs;

  String _jwtToken = '';

  void init(String jwtToken) {
    _jwtToken = jwtToken;
  }

  Future<void> openSendMedia(BuildContext context) {
    final String token = _jwtToken;
    return _open(
      context,
          (_) => SendMedia(Current_User_Jwt_Token: token),
    );
  }

  Future<void> openViewMedia(BuildContext context) {
    final String token = _jwtToken;
    return _open(
      context,
          (_) => ViewMedia(Current_User_Jwt_Token: token),
    );
  }

  Future<void> _open(BuildContext context, WidgetBuilder builder) async {
    if (isOpening.value) return;
    try {
      isOpening.value = true;
      await Navigator.push(context, MaterialPageRoute(builder: builder));
    } catch (_) {
    } finally {
      isOpening.value = false;
    }
  }
}