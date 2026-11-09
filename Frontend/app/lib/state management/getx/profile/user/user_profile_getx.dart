import 'dart:convert';

import 'package:app/constant/Server_Database.dart';
import 'package:app/constant/variable.dart';
import 'package:app/models/UserInfo.dart';
import 'package:app/web/authentication/Error_page.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Shown whenever a database value is null, empty, or "null".
const String kNoDataAvailable = "No data available";

/// Returns the trimmed value, or [kNoDataAvailable] when it is null/empty.
String valueOrNoData(Object? value) {
  if (value == null) return kNoDataAvailable;
  final String v = value.toString().trim();
  if (v.isEmpty || v.toLowerCase() == "null") return kNoDataAvailable;
  return v;
}

/// State + every API call used by the user profile screen
/// (separate from the provider profile controller).
class UserProfileGetx extends GetxController {
  // ============================================================
  // DATA / LOADING STATE
  // ============================================================

  /// The loaded profile (null until loaded or when loading failed).
  final Rxn<UserInfo> userInfo = Rxn<UserInfo>();

  final RxBool isLoading = true.obs;
  final RxBool hasLoadError = false.obs;

  /// True while a new profile photo is being uploaded.
  final RxBool isUploadingPhoto = false.obs;

  /// Bumped after every successful photo update so the image reloads even if
  /// the server keeps the same file path.
  final RxInt photoVersion = 0.obs;

  // ============================================================
  // UI INTERACTION STATE (per action tile, no shared pressed flag)
  // ============================================================

  final RxInt hoveredActionIndex = (-1).obs;
  final RxInt pressedActionIndex = (-1).obs;

  void setHoveredAction(int index) => hoveredActionIndex.value = index;
  void clearHoveredAction() => hoveredActionIndex.value = -1;
  void setPressedAction(int index) => pressedActionIndex.value = index;
  void clearPressedAction() => pressedActionIndex.value = -1;

  // ============================================================
  // SESSION
  // ============================================================

  Future<void> verifySession({
    required String jwtToken,
    required BuildContext context,
  }) async {
    try {
      final int result = await UserJwtVerify(Jwt_Token: jwtToken);
      if (result == 1) return;

      await Clear_User_Data();
      await Random_token_Clear();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
      }
      Toastget().Toastmsg("Session End.Relogin please.");
    } catch (e) {
      // print("verifySession failed: $e");
    }
  }

  Future<void> logout({required BuildContext context}) async {
    try {
      await Clear_User_Data();
      await Random_token_Clear();
      Toast.Toastmsg("Logout Success");
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ErrorPage()),
        );
      }
      Toastget().Toastmsg("Session End.Relogin please.");
    } catch (e) {
      // print("logout failed: $e");
    }
  }

  // ============================================================
  // LOAD PROFILE (logic unchanged; moved from the screen)
  // [showLoader] = false keeps the current profile visible while refreshing.
  // ============================================================

  Future<bool> loadUserInfo({
    required String email,
    required String jwtToken,
    bool showLoader = true,
  }) async {
    if (showLoader) isLoading.value = true;
    hasLoadError.value = false;

    try {
      const String url = Backend_Server_Url + "api/Profile/getuserinfo";
      final Map<String, dynamic> userDetails = {"Email": email};
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(userDetails),
      );

      if (response.statusCode == 200) {
        // print("profile user info");
        final Map<dynamic, dynamic> responseData = jsonDecode(response.body);
        userInfo.value = UserInfo.fromJson(responseData);
        return true;
      } else {
        // print("Data insert in userinfo list failed.");
        userInfo.value = null;
        hasLoadError.value = true;
        return false;
      }
    } catch (e) {
      // print("Exception caught while fetching user data for profile screen: $e");
      userInfo.value = null;
      hasLoadError.value = true;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // UPDATE PHOTO (multipart PUT, logic unchanged)
  // ============================================================

  Future<bool> updatePhoto({
    required String email,
    required String jwtToken,
    required String photoExtension,
    required List<int> photoBytes,
  }) async {
    try {
      // 1. Validate photo
      if (photoBytes.isEmpty) {
        // print("ERROR: Photo bytes are empty.");
        return false;
      }

      // 2. Validate extension
      String extension = photoExtension.toLowerCase().trim();
      if (extension.startsWith(".")) {
        extension = extension.substring(1);
      }
      if (extension != "jpg" && extension != "jpeg" && extension != "png") {
        // print("ERROR: Invalid photo extension.");
        return false;
      }

      // 3-8. Build the multipart request
      const String url = Backend_Server_Url + "api/Profile/updateprofilephoto";
      final request = http.MultipartRequest("PUT", Uri.parse(url));
      request.headers["Authorization"] = "Bearer $jwtToken";
      request.fields["Email"] = email;
      request.fields["PhotoExtension"] = extension;
      request.files.add(
        http.MultipartFile.fromBytes(
          "Photo",
          photoBytes,
          filename: "profile.$extension",
        ),
      );

      // 9-10. Send and read the response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // print("Profile photo updated successfully.");
        return true;
      }
      // print("Photo update failed. Status code = ${response.statusCode}");
      return false;
    } catch (e) {
      // print("Exception caught while updating profile photo: $e");
      return false;
    }
  }

  /// Uploads the picked photo, tells the user, then reloads the profile so the
  /// new photo shows immediately.
  Future<bool> changePhoto({
    required String email,
    required String jwtToken,
    required String photoExtension,
    required List<int> photoBytes,
  }) async {
    if (isUploadingPhoto.value) return false;
    isUploadingPhoto.value = true;

    try {
      final bool result = await updatePhoto(
        email: email,
        jwtToken: jwtToken,
        photoExtension: photoExtension,
        photoBytes: photoBytes,
      );

      if (result == true) {
        Toast.Toastmsg("Image update success");
        photoVersion.value++;
        await loadUserInfo(email: email, jwtToken: jwtToken, showLoader: false);
        return true;
      } else {
        Toast.Toastmsg("Fail to change photo.Try again.");
        return false;
      }
    } catch (e) {
      // print("changePhoto failed: $e");
      Toast.Toastmsg("Fail to change photo.Try again.");
      return false;
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Full image URL from a stored relative photo path ("" when none).
  String getPhotoUrl(String? photoPath) {
    try {
      final String p = (photoPath ?? "").trim();
      if (p.isEmpty || p.toLowerCase() == "null") return "";

      final String baseUrl = Backend_Server_Url.endsWith("/")
          ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
          : Backend_Server_Url;
      final String path = p.startsWith("/") ? p : "/$p";
      final String url = "$baseUrl$path";
      return photoVersion.value > 0 ? "$url?v=${photoVersion.value}" : url;
    } catch (e) {
      return "";
    }
  }
}