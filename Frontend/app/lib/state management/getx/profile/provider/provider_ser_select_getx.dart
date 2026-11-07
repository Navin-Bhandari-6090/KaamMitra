import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../models/ProviderRegisterServiceNameModel.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';

class ProviderSerSelectGetx extends GetxController {
  // ============================================================
  // Session state
  // ============================================================

  final RxBool isVerifying = true.obs;
  final RxBool isSessionValid = false.obs;

  // ============================================================
  // Service list state
  // ============================================================

  final RxBool isLoadingServices = true.obs;
  final RxBool hasError = false.obs;
  final RxBool loadFailed = false.obs;
  final RxList<ProviderRegisterServiceNameModel> serviceList =
      <ProviderRegisterServiceNameModel>[].obs;

  // ============================================================
  // UI animation state
  // ============================================================

  final RxList<bool> cardVisible = <bool>[].obs;
  final RxList<bool> cardHover = <bool>[].obs;

  // Request inputs kept so retry() can reuse them.
  String _email = "";
  String _jwtToken = "";
  bool _disposed = false;

  // ============================================================
  // ENTRY POINT — the screen calls only this
  // ============================================================

  /// Verifies the session, then loads the provider's services.
  Future<void> init({
    required String jwtToken,
    required String providerEmail,
  }) async {
    _jwtToken = jwtToken;
    _email = providerEmail;

    await verifyJwt(jwtToken: jwtToken);
    if (!isSessionValid.value) return;

    await fetchServices(email: providerEmail, jwtToken: jwtToken);
  }

  /// Re-runs the service request after a failure.
  Future<void> retry() async {
    if (!isSessionValid.value) return;
    await fetchServices(email: _email, jwtToken: _jwtToken);
  }

  // ============================================================
  // SESSION
  // ============================================================

  Future<void> verifyJwt({required String jwtToken}) async {
    isVerifying.value = true;

    final int result = await UserProviderJwtVerify(Jwt_Token: jwtToken);

    if (_disposed) return;

    if (result == 1) {
      isSessionValid.value = true;
      isVerifying.value = false;
    } else {
      isSessionValid.value = false;
      isVerifying.value = false;

      await Clear_User_Data();
      await Random_token_Clear();

      Toastget().Toastmsg("Session End. Relogin please.");
      Get.offAll(() => ErrorPage());
    }
  }

  // ============================================================
  // SERVICES API
  // ============================================================

  Future<void> fetchServices({
    required String email,
    required String jwtToken,
  }) async {
    isLoadingServices.value = true;
    hasError.value = false;
    loadFailed.value = false;

    try {
      final String url =
          Backend_Server_Url + "api/Profile/getproviderregisterserviceinfo";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode({"Email": email}),
      );

      if (_disposed) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw const FormatException("Expected a list of services.");
        }

        final services = decoded
            .map((data) => ProviderRegisterServiceNameModel.fromJson(data))
            .toList();

        serviceList.assignAll(services);
        cardVisible.assignAll(List<bool>.filled(services.length, false));
        cardHover.assignAll(List<bool>.filled(services.length, false));
        isLoadingServices.value = false;
        _playEntranceAnimation();
      } else {
        serviceList.clear();
        loadFailed.value = true;
        isLoadingServices.value = false;
      }
    } catch (e) {
      if (_disposed) return;
      serviceList.clear();
      hasError.value = true;
      isLoadingServices.value = false;
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  void _playEntranceAnimation() {
    for (int i = 0; i < cardVisible.length; i++) {
      Future.delayed(Duration(milliseconds: 90 * i), () {
        if (_disposed || i >= cardVisible.length) return;
        cardVisible[i] = true;
        cardVisible.refresh();
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
    _disposed = true;
    super.onClose();
  }
}