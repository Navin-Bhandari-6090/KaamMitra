import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../models/BookingInfoModel.dart';
import '../../../models/NotificationsInfoModel.dart';
import '../../../web/authentication/Error_page.dart';
import '../../../web/common method/Commmon_Method.dart';
import '../../../web/common method/notification.dart';
import '../../../web/common widget/toast.dart';

/// UI + data state for ProviderBookingsScreen — replaces setState and now also
/// owns every API call of the booking screen.
class ProviderBookingsGetx extends GetxController {
  // ============================================================
  // LOADING / ERROR STATE
  // ============================================================

  RxBool isLoading = false.obs;
  RxBool hasLoadError = false.obs;

  void setLoading(bool value) => isLoading.value = value;
  void setLoadError(bool value) => hasLoadError.value = value;

  // ============================================================
  // NOTIFICATION BELL STATE
  // hasNewNotification = true -> unread notification exists (red bell)
  // ============================================================

  RxBool hasNewNotification = false.obs;

  void setHasNewNotification(bool value) => hasNewNotification.value = value;

  // ============================================================
  // DATA LISTS
  // ============================================================

  /// Raw booking list filled by [getBookingInfo].
  final List<BookingInfoModel> _rawBookingInfoList = [];

  final RxList<BookingInfoModel> bookingInfoList = <BookingInfoModel>[].obs;
  final RxList<BookingInfoModel> displayedBookings = <BookingInfoModel>[].obs;
  final RxList<NotificationsInfoModel> notificationsInfoList =
      <NotificationsInfoModel>[].obs;

  void setBookingInfoList(List<BookingInfoModel> list) {
    try {
      bookingInfoList.assignAll(list);
      _applyBookingIdFilter();
    } catch (e) {
      // print("setBookingInfoList failed: $e");
      bookingInfoList.clear();
      displayedBookings.clear();
    }
  }

  void setNotificationsInfoList(List<NotificationsInfoModel> list) {
    try {
      notificationsInfoList.assignAll(list);
    } catch (e) {
      // print("setNotificationsInfoList failed: $e");
      notificationsInfoList.clear();
    }
  }

  void clearAll() {
    try {
      bookingInfoList.clear();
      displayedBookings.clear();
      notificationsInfoList.clear();
      searchText.value = "";
    } catch (e) {
      // print("clearAll failed: $e");
    }
  }

  // ============================================================
  // LOAD ORCHESTRATION — the screen calls only this
  // ============================================================

  Future<void> loadEverything({
    required String email,
    required String jwtToken,
    required BuildContext context,
  }) async {
    try {
      setLoading(true);
      setLoadError(false);

      final results = await Future.wait([
        getBookingInfo(email: email, jwtToken: jwtToken, context: context),
        GetNotificationsInfo(
          Email: email,
          Current_User_JwtToken: jwtToken,
          context: context,
        ),
        GetNewNotificationInfo(
          Email: email,
          Current_User_JwtToken: jwtToken,
          context: context,
        ),
      ]);

      final bool anyFailed = results.any((r) => r != 1);

      setBookingInfoList(_rawBookingInfoList);
      setNotificationsInfoList(NotificationsInfoList);

      bool hasNew = false;
      for (final n in NewNotificationsList) {
        if ((n.status ?? false) == true) {
          hasNew = true;
          break;
        }
      }
      setHasNewNotification(hasNew);

      setLoadError(anyFailed && _rawBookingInfoList.isEmpty);
    } catch (e) {
      // print("Unexpected error in loadEverything: $e");
      setLoadError(true);
      Toastget().Toastmsg("Couldn't load your bookings. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  // ============================================================
  // BOOKING API (logic unchanged; moved from the screen)
  // Returns: 1 success, 2 other status, 3 session end, 4 backend error,
  // 0 exception.
  // ============================================================

  Future<int> getBookingInfo({
    required String email,
    required String jwtToken,
    required BuildContext context,
  }) async {
    try {
      final Map<String, dynamic> userData = {"Email": email};
      const String url = Backend_Server_Url + "api/Booking/sendbookinginfopro";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        _rawBookingInfoList
          ..clear()
          ..addAll(
            responseData.map((data) => BookingInfoModel.fromJson(data)),
          );
        // print("Booking info get success.");
        return 1;
      } else if (response.statusCode == 502) {
        _rawBookingInfoList.clear();
        // print("Invalid email.");
        await Clear_User_Data();
        await Random_token_Clear();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ErrorPage()),
                (route) => false,
          );
        }
        Toastget().Toastmsg("Your register email don't match..");
        return 3;
      } else if (response.statusCode == 500) {
        _rawBookingInfoList.clear();
        // print("Exception caught in backend.");
        return 4;
      } else if (response.statusCode == 501) {
        _rawBookingInfoList.clear();
        // print("Invalid data format.");
        return 4;
      } else {
        _rawBookingInfoList.clear();
        // print("Booking info get fail. Status code = ${response.statusCode}");
        return 2;
      }
    } catch (e) {
      _rawBookingInfoList.clear();
      // print("Exception caught while getting booking info: $e");
      return 0;
    }
  }

  // ============================================================
  // BELL — mark notifications as seen (optimistic UI, then API)
  // ============================================================

  Future<void> markNotificationsSeen({
    required String email,
    required String jwtToken,
    required BuildContext context,
  }) async {
    try {
      if (!hasNewNotification.value) return;
      setHasNewNotification(false);
      await UpdateNewNotificationInfo(
        Email: email,
        Current_User_JwtToken: jwtToken,
        context: context,
      );
    } catch (e) {
      // print("Unexpected error updating new-notification status: $e");
    }
  }

  // ============================================================
  // SEARCH — filter bookings by booking ID OR user ID as the person types.
  // ============================================================

  RxString searchText = "".obs;
  RxBool isSearchFocused = false.obs;

  void setSearchFocused(bool value) => isSearchFocused.value = value;

  void changeSearchText(String value) {
    try {
      searchText.value = value;
      _applyBookingIdFilter();
    } catch (e) {
      // print("changeSearchText failed: $e");
    }
  }

  void _applyBookingIdFilter() {
    try {
      final String query = searchText.value.trim().toLowerCase();

      if (query.isEmpty) {
        displayedBookings.assignAll(bookingInfoList);
        return;
      }

      final List<BookingInfoModel> filtered = bookingInfoList.where((b) {
        final String bookIdStr =
        b.bookId != null ? b.bookId.toString().toLowerCase() : "";
        final String userIdStr =
        b.userNumber != null ? b.userNumber.toString().toLowerCase() : "";
        return bookIdStr.contains(query) || userIdStr.contains(query);
      }).toList();

      displayedBookings.assignAll(filtered);
    } catch (e) {
      // print("_applyBookingIdFilter failed: $e");
      displayedBookings.assignAll(bookingInfoList);
    }
  }

  // ============================================================
  // CARD HOVER / PRESS STATE
  // ============================================================

  RxInt hoveredCardIndex = (-1).obs;
  RxInt pressedCardIndex = (-1).obs;

  void setHoveredCard(int index) => hoveredCardIndex.value = index;
  void clearHoveredCard() => hoveredCardIndex.value = -1;
  void setPressedCard(int index) => pressedCardIndex.value = index;
  void clearPressedCard() => pressedCardIndex.value = -1;
}