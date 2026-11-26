import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:app/constant/Server_Database.dart';
import 'package:app/models/UserLinkedResoModel.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:app/web/common%20widget/toast.dart';

// State + API call of UserLinkedResources. API logic is unchanged from the original screen.
class UserLinkResGetx extends GetxController {
  final Toastget _toast = Toastget();

  String _jwt = '';

  // Text controller lives here so the screen needs no setState.
  final UserIdController = TextEditingController();

  // Live copy of the typed id (drives the clear button and search button state).
  final RxString userIdText = ''.obs;

  // Original result list (cleared on every request, filled on success).
  final RxList<UserLinkedResoModel> UserLinkedResoModelList =
      <UserLinkedResoModel>[].obs;

  // True while the request runs.
  final RxBool isLoading = false.obs;

  // True after the first search, so the screen can tell "nothing yet" from "no data".
  final RxBool hasSearched = false.obs;

  // The user number of the last search and the last failure message.
  final RxInt searchedUser = 0.obs;
  final RxString errorMessage = ''.obs;

  // Category keys whose id list is expanded ("show all").
  final RxSet<String> expanded = <String>{}.obs;

  void init(String jwt) {
    _jwt = jwt;
    isLoading.value = false;
  }

  Future<void> verifyJwt(BuildContext context) async {
    try {
      await Admin_Jwt_Verify(Jwt_Token: _jwt, context: context);
    } catch (_) {}
  }

  void toggleExpanded(String key) {
    if (expanded.contains(key)) {
      expanded.remove(key);
    } else {
      expanded.add(key);
    }
  }

  void clearInput() {
    UserIdController.clear();
    userIdText.value = '';
  }

  // Toast + remember the failure for the screen.
  void _fail(String message) {
    _toast.Toastmsg(message);
    errorMessage.value = message;
  }

  // Original API method. Returns 1 success, 3 failure.
  Future<int> GetUserLinkedReso({
    required BuildContext context,
    required String Jwt_Token,
    required int UserNumber,
  }) async {
    try {
      // Clear previous user linked resources.
      UserLinkedResoModelList.clear();
      errorMessage.value = '';

      // Send the request to retrieve linked resources.
      final response = await http.post(
        Uri.parse("${Backend_Server_Url}" + "api/Admin/getuserlinkedresources"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $Jwt_Token",
        },
        body: jsonEncode({"UserNumber": UserNumber}),
      );

      print(response.body);
      // Successful response.
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        UserLinkedResoModelList.add(UserLinkedResoModel.fromJson(responseData));

        _toast.Toastmsg("User linked resources retrieved successfully.");
        return 1;
      }

      // Suitable messages for every failure.
      switch (response.statusCode) {
        case 400:
          _fail("Invalid user information.");
          break;
        case 401:
          _fail("Your session has expired. Please login again.");
          await Logout(context: context);
          break;
        case 403:
          _fail("You are not authorized to perform this action.");
          break;
        case 404:
          _fail("User not found.");
          await Logout(context: context);
          break;
        case 505:
          _fail("Admin account not found.");
          await Logout(context: context);
          break;
        case 506:
          _fail("Your account has been blocked. Contact KaamMitra support.");
          await Logout(context: context);
          break;
        default:
          _fail("Unable to retrieve user linked resources.");
          break;
      }

      return 3;
    } catch (_) {
      // Unexpected errors.
      UserLinkedResoModelList.clear();
      _fail("Something went wrong. Please try again.");
      return 3;
    }
  }

  // Runs the search with a loading flag so it cannot be fired twice.
  Future<int> runSearch(BuildContext context, int userNumber) async {
    if (isLoading.value) return 3;
    isLoading.value = true;
    hasSearched.value = true;
    searchedUser.value = userNumber;
    expanded.clear();
    try {
      return await GetUserLinkedReso(
        context: context,
        Jwt_Token: _jwt,
        UserNumber: userNumber,
      );
    } catch (_) {
      return 3;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    try {
      UserIdController.dispose();
    } catch (_) {}
    super.onClose();
  }
}