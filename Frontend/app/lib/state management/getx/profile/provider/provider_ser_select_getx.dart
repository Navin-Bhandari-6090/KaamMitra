import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../models/ProviderRegisterServiceNameModel.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';



class ProviderSerSelectGetx extends GetxController {
  // Session state
  final RxBool isVerifying = true.obs;
  final RxBool isSessionValid = false.obs;

  // Service list state
  final RxBool isLoadingServices = true.obs;
  final RxBool hasError = false.obs;
  final RxBool loadFailed = false.obs;
  final RxList<ProviderRegisterServiceNameModel> serviceList = <ProviderRegisterServiceNameModel>[].obs;

  // UI animation state (replaces setState-driven UI updates)
  final RxList<bool> cardVisible = <bool>[].obs;
  final RxList<bool> cardHover = <bool>[].obs;

  Future<void> verifyJwt({required String jwtToken}) async {
    isVerifying.value = true;

    final int result = await ProviderJwtVerify(Jwt_Token: jwtToken);

    if (result == 1) {
      isSessionValid.value = true;
      isVerifying.value = false;
    } else {
      isSessionValid.value = false;
      isVerifying.value = false;

      await Clear_User_Data();
      await Random_token_Clear();

      Toastget().Toastmsg("Session End.Relogin please.");
      Get.offAll(() => ErrorPage());
    }
  }

  Future<void> fetchServices({required String email, required String jwtToken}) async {
    isLoadingServices.value = true;
    hasError.value = false;
    loadFailed.value = false;

    try {
      print("Profile service photo method called");

      const String url = Backend_Server_Url + "api/Profile/getproviderregisterserviceinfo";

      Map<String, dynamic> userDetails = {"Email": email};

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode(userDetails),
      );

      if (response.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(response.body);
        serviceList.assignAll(
          responseData.map((data) => ProviderRegisterServiceNameModel.fromJson(data)).toList(),
        );
        cardVisible.assignAll(List<bool>.filled(serviceList.length, false));
        cardHover.assignAll(List<bool>.filled(serviceList.length, false));
        isLoadingServices.value = false;
        _playEntranceAnimation();
      } else {
        serviceList.clear();
        print("Failed to fetch provider register service data. Status code: ${response.statusCode}");
        loadFailed.value = true;
        isLoadingServices.value = false;
      }
    } catch (e) {
      serviceList.clear();
      print("Error occurred while fetching provider register service data: $e");
      hasError.value = true;
      isLoadingServices.value = false;
    }
  }

  void _playEntranceAnimation() {
    for (int i = 0; i < cardVisible.length; i++) {
      Future.delayed(Duration(milliseconds: 90 * i), () {
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
    serviceList.close();
    cardVisible.close();
    cardHover.close();
    super.onClose();
  }
}