import 'package:get/get.dart';

import '../../../models/BookingInfoModel.dart';
import '../../../models/NotificationsInfoModel.dart';

// Adjust the two model import paths above to match wherever you place this
// file relative to your models folder.

/// UI-only reactive state for ProviderBookingsScreen — replaces setState.
/// Put once with Get.put in initState, deleted in dispose.
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
  // hasNewNotification mirrors NewNotificationsModel.status for the
  // current user — true = unread notification exists (red ring bell),
  // false = nothing new (normal bell).
  // ============================================================

  RxBool hasNewNotification = false.obs;

  void setHasNewNotification(bool value) => hasNewNotification.value = value;

  // ============================================================
  // DATA LISTS
  // bookingInfoList  = every booking exactly as received from the API.
  // displayedBookings = bookingInfoList after the booking-ID search filter.
  // notificationsInfoList = untouched notification history for the drawer.
  // ============================================================

  final RxList<BookingInfoModel> bookingInfoList = <BookingInfoModel>[].obs;
  final RxList<BookingInfoModel> displayedBookings = <BookingInfoModel>[].obs;
  final RxList<NotificationsInfoModel> notificationsInfoList =
      <NotificationsInfoModel>[].obs;

  void setBookingInfoList(List<BookingInfoModel> list) {
    try {
      bookingInfoList.assignAll(list);
      _applyBookingIdFilter();
    } catch (e) {
      // Defensive fallback only — never let a bad list crash the screen.
      bookingInfoList.clear();
      displayedBookings.clear();
    }
  }

  void setNotificationsInfoList(List<NotificationsInfoModel> list) {
    try {
      notificationsInfoList.assignAll(list);
    } catch (e) {
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
      // no-op — clearing is already the fallback state
    }
  }

  // ============================================================
  // SEARCH — filter bookings by booking ID as the person types.
  // ============================================================

  RxString searchText = "".obs;
  RxBool isSearchFocused = false.obs;

  void setSearchFocused(bool value) => isSearchFocused.value = value;

  void changeSearchText(String value) {
    try {
      searchText.value = value;
      _applyBookingIdFilter();
    } catch (e) {
      // Defensive fallback — keep whatever was already displayed rather
      // than crash on an unexpected filter failure.
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
        final String idStr =
        b.bookId != null ? b.bookId.toString().toLowerCase() : "";
        return idStr.contains(query);
      }).toList();

      displayedBookings.assignAll(filtered);
    } catch (e) {
      displayedBookings.assignAll(bookingInfoList);
    }
  }

  // ============================================================
  // CARD HOVER / PRESS STATE (web + touch feedback, no setState)
  // ============================================================

  RxInt hoveredCardIndex = (-1).obs;
  RxInt pressedCardIndex = (-1).obs;

  void setHoveredCard(int index) => hoveredCardIndex.value = index;
  void clearHoveredCard() => hoveredCardIndex.value = -1;
  void setPressedCard(int index) => pressedCardIndex.value = index;
  void clearPressedCard() => pressedCardIndex.value = -1;
}