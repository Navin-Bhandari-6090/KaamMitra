import 'package:app/web/authentication/Error_page.dart';
import 'package:app/web/common%20method/Commmon_Method.dart';
import 'package:app/web/common%20widget/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';

/// Shown whenever a database value is null, empty, or whitespace only.
const String kDataNotAvailable = "Data not available";

/// Returns the trimmed value, or [kDataNotAvailable] if it is null/empty.
String valueOrNA(String? value) {
  if (value == null) return kDataNotAvailable;
  final v = value.trim();
  if (v.isEmpty || v.toLowerCase() == "null") return kDataNotAvailable;
  return v;
}

class SelectServiceProviderInfoScreenGetx extends GetxController {
  // ============================================================
  // UI state
  // ============================================================

  RxBool isGalleryPressed = false.obs;
  RxBool isBookPressed = false.obs;

  /// True while a booking request is in flight. Prevents double submits.
  RxBool isBooking = false.obs;

  void setGalleryPressed(bool value) => isGalleryPressed.value = value;
  void setBookPressed(bool value) => isBookPressed.value = value;

  // ============================================================
  // SESSION
  // ============================================================

  void verifySession({
    required String jwtToken,
    required BuildContext context,
  }) {
    Provider_User_Jwt_Verify(Jwt_Token: jwtToken, context: context);
  }

  // ============================================================
  // VALIDATION (no network call; returns an error message or null)
  // ============================================================

  String? validateBooking({
    required bool? providerStatus,
    required String role,
    required String description,
  }) {
    if (providerStatus == null) {
      return "Provider status is not available. Try again later.";
    }
    if (providerStatus) {
      return "Provider is reserved. You cannot book now.";
    }
    if (role.trim().toLowerCase() == "provider") {
      return "Please register as a user to book services.";
    }
    if (description.trim().isEmpty) {
      return "Please describe the service you need.";
    }
    return null;
  }

  // ============================================================
  // BOOKING FLOW — booking request, then notifications on success
  // ============================================================

  Future<void> bookService({
    required BuildContext context,
    required String jwtToken,
    required String userEmail,
    required String serviceName,
    required num serviceId,
    required num providerNumber,
    required double distance,
    required String description,
  }) async {
    if (isBooking.value) return;
    isBooking.value = true;

    try {
      final int result = await _postBooking(
        jwtToken: jwtToken,
        distance: distance,
        serviceName: serviceName,
        serviceId: serviceId,
        providerNumber: providerNumber,
        description: description,
      );

      // Only notify and clear attachments when the booking really succeeded.
      if (result != 1) return;

      ClearFilesValues();

      await AddNotifications(
        ReceiverNumber: providerNumber,
        Message:
        "You have been booked by $userEmail for ${valueOrNA(serviceName)}.",
        Current_User_JwtToken: jwtToken,
        context: context,
      );

      await AddNewNotifications(
        ReceiverNumber: providerNumber,
        Status: true,
        Current_User_JwtToken: jwtToken,
        context: context,
      );
    } finally {
      isBooking.value = false;
    }
  }

  // ============================================================
  // BOOKING API (multipart POST)
  // Returns: 1 success, 2–10 error codes (same as before).
  // ============================================================

  Future<int> _postBooking({
    required String jwtToken,
    required double distance,
    required num providerNumber,
    required String serviceName,
    required num serviceId,
    required String description,
  }) async {
    try {
      final String url = Backend_Server_Url + "api/Service/addbookinginfo";

      final request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers["Authorization"] = "Bearer $jwtToken";

      request.fields["Distance"] = distance.toString();
      request.fields["ServiceName"] = serviceName;
      request.fields["ProviderApprovalStatus"] = "false";
      request.fields["ProviderTaskCompleteStatus"] = "false";
      request.fields["UserTaskCompleteStatus"] = "false";
      request.fields["UserApprovalStatus"] = "true";
      request.fields["UserBookingDescription"] = description;
      request.fields["ServiceId"] = serviceId.toString();
      request.fields["ProviderNumber"] = providerNumber.toString();
      request.fields["CreatedAt"] = DateTime.now().toUtc().toIso8601String();
      request.fields["RequiredAdvancePayment"] = "false";

      // Optional file
      final List<int>? fileBytes = change_file_cont_getx.fileBytes.value;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final String ext = _cleanExtension(
          change_file_cont_getx.fileExtension.value,
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            "BookingFile",
            fileBytes,
            filename: ext.isNotEmpty ? "booking_file.$ext" : "booking_file",
          ),
        );
      }

      // Optional video
      final List<int>? videoBytes = change_video_cont_getx.videoBytes.value;
      if (videoBytes != null && videoBytes.isNotEmpty) {
        final String ext = _cleanExtension(
          change_video_cont_getx.videoExtension.value,
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            "BookingVideo",
            videoBytes,
            filename: ext.isNotEmpty ? "booking_video.$ext" : "booking_video",
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleBookingStatus(response.statusCode);
    } catch (e) {
      Toast.Toastmsg(
        "Unable to create booking. Please check your connection and try again.",
      );
      return 10;
    }
  }

  int _handleBookingStatus(int statusCode) {
    switch (statusCode) {
      case 200:
        Toast.Toastmsg("Booking success.");
        return 1;

      case 400:
        Toast.Toastmsg("Invalid booking data. Please check your information.");
        return 2;

      case 401:
        Toast.Toastmsg("Unauthorized. Please log in again.");
        return 3;

      case 403:
        Toast.Toastmsg("You are not authorized to create this booking.");
        return 4;

      case 500:
        Toast.Toastmsg("Booking failed. Server error. Please try again.");
        return 5;

      case 502:
        Toast.Toastmsg("Current user doesn't match.");
        _endSession();
        return 6;

      case 503:
        Toast.Toastmsg("Provider not found. Choose a different provider.");
        return 7;

      case 506:
        Toast.Toastmsg(
            "You have been blocked by the system. Contact KaamMitra support.");
        return 8;

      default:
        Toast.Toastmsg("Booking failed. Please try again later.");
        return 9;
    }
  }

  /// Clears the stored session and sends the user back to the login flow.
  Future<void> _endSession() async {
    await Clear_User_Data();
    await Random_token_Clear();
    Get.offAll(() => ErrorPage());
    Toastget().Toastmsg("Session ended. Please log in again.");
  }

  String _cleanExtension(String? raw) {
    String ext = (raw ?? "").trim();
    if (ext.startsWith(".")) ext = ext.substring(1);
    return ext;
  }
}