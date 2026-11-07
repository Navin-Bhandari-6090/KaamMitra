import 'dart:convert';

import 'package:app/web/admin/Admin_Home_Screenn.dart';
import 'package:app/web/authentication/Error_page.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:app/web/home/Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../web/common method/Commmon_Method.dart';


/// GetX controller for the Login screen.
/// Holds ALL state (animations, focus, obscure, loading) and ALL api calls,
/// so the screen itself never needs setState.
class LoginController extends GetxController
    with GetTickerProviderStateMixin {
  LoginController({required this.userJwtToken});

  final String userJwtToken;

  // ---- animations ---------------------------------------------------
  late final AnimationController entrance;
  late final AnimationController wave;

  // ---- inputs -------------------------------------------------------
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  // ---- reactive UI state -------------------------------------------
  final obscure = true.obs;
  final emailFocused = false.obs;
  final passFocused = false.obs;
  final buttonPressed = false.obs;
  final isLoading = false.obs;



  @override
  void onInit() {
    super.onInit();
    entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    emailFocus.addListener(() => emailFocused.value = emailFocus.hasFocus);
    passFocus.addListener(() => passFocused.value = passFocus.hasFocus);
  }

  @override
  void onClose() {
    entrance.dispose();
    wave.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    super.onClose();
  }

  /// Staggered interval animation helper used for entrance effects.
  Animation<double> stagger(double start, double end) {
    return CurvedAnimation(
      parent: entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  void toggleObscure() => obscure.value = !obscure.value;

  // ---- api / logic (unchanged) -------------------------------------

  Future<void> jwtVerify(BuildContext context) async
  {
    try {
      Random_Jwt_Verify(Jwt_Token: userJwtToken, context: context);
      return;
    } catch (e) {
      print("Exception in jwtVerify: $e");
      return;
    }
  }

  /// Called by the Login button / keyboard submit.
  Future<void> submit(BuildContext context) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await loginUser(
        context,
        email: emailCtrl.text.trim().toString(),
        password: passCtrl.text.trim().toString(),
      );
      print("Login result = $result");
    } catch (e) {
      print("Exception in submit: $e");
      Toast.Toastmsg("Login fail.Try again.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<int> loginUser(
      BuildContext context, {
        required String email,
        required String password,
      }) async {
    try {
      final Map<String, dynamic> userData = {
        "Email": email,
        "Password": password,
      };
      const String url = Backend_Server_Url + "api/Authentication/login";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $userJwtToken'
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        print("login success");
        await handleResponse(responseData);
        Toast.Toastmsg("Login success");
        String token = responseData['token']!;
        String email = responseData['email']!;
        String userType = responseData['usertype']!;
        int userNumber = responseData['usernumber']!;
        if (!context.mounted) return 1;
        if (userType == "admin") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) {
              return AdminHomeScreen(
                User_Role: userType,
                User_JwtToken: token,
                User_Email: email,
                User_Number: userNumber,
              );
            }),
                (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) {
              return HomeScreenUi(UserLogin: true, User_JwtToken: token);
            }),
                (route) => false,
          );
        }
        return 1;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg("Invalid password.");
        print("Invalid password.");
        return 3;
      } else if (response.statusCode == 504) {
        Toast.Toastmsg(
            "You have been blocked by community.Please contact customer service.");
        print("You have been blocked by community.");
        return 7;
      } else if (response.statusCode == 501) {
        Toast.Toastmsg("Email don't found.User don't exist.");
        print("Email don't found.User don't exist.");
        return 4;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Incorrect format of provided details.");
        print("Incorrect format of provided details.");
        return 5;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg("Incorrect provided details.");
        print("Incorrect provided details.");
        return 6;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg("Login fail.Try again.");
        return 2;
      }
    } catch (Obj) {
      print("Exception caight in login user method in http method.");
      print(Obj.toString());
      Toast.Toastmsg("Login fail.Try again.Server error.");
      return 0;
    }
  }
}