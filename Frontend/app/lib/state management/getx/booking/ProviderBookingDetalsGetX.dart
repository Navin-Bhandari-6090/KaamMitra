import 'dart:convert';

import 'package:app/web/common%20method/date_time.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:app/constant/Server_Database.dart';
import 'package:app/models/BookingInfoModel.dart';
import 'package:app/web/authentication/Error_page.dart';
import 'package:app/web/common method/Commmon_Method.dart';
import 'package:app/web/common widget/toast.dart';

/// State + every API call used by Providerbookinginfodetailsscreen.
///
/// UPDATE FLOW (same after every change):
///   1. PUT update succeeds (200)
///   2. the matching reactive value is set immediately  -> UI rebuilds NOW
///   3. POST api/Booking/sendfilterbookinginfo {BookId}
///   4. ReactiveBookingInfos.clear() + addAll(new items)
///   5. booking.value = ReactiveBookingInfos[0]          -> UI rebuilds with server data
///
/// Step 2 is why the UI no longer depends on step 3 succeeding.
class Providerbookingdetalsgetx extends GetxController {
  final Toastget _toast = Toastget();

  String _email = '';
  String _jwt = '';

  // ---------------------------------------------------------------- booking
  final Rxn<BookingInfoModel> booking = Rxn<BookingInfoModel>();

  /// '' = idle, otherwise the running action name.
  final RxString busyKey = ''.obs;

  /// True while the booking is being re-fetched (thin progress bar in the app bar).
  final RxBool isRefreshing = false.obs;

  // Reactive copies of the fields the provider can change. They are re-filled
  // from [booking] every time it changes, and set directly after a successful PUT.
  final Rxn<bool> _providerApproval = Rxn<bool>();
  final Rxn<bool> _providerTaskComplete = Rxn<bool>();
  final Rxn<bool> _customerApproval = Rxn<bool>();
  final Rxn<bool> _customerTaskComplete = Rxn<bool>();
  final Rxn<num> _advanceAmount = Rxn<num>();
  final Rxn<Object> _startDate = Rxn<Object>();
  final Rxn<Object> _endDate = Rxn<Object>();
  final Rxn<Object> _providerDescription = Rxn<Object>();

  // Getters read an Rx inside, so they stay reactive inside Obx.
  bool? get providerApproval => _providerApproval.value;
  bool? get providerTaskComplete => _providerTaskComplete.value;
  bool? get customerApproval => _customerApproval.value;
  bool? get customerTaskComplete => _customerTaskComplete.value;
  num? get advanceAmount => _advanceAmount.value;
  Object? get startDate => _startDate.value;
  Object? get endDate => _endDate.value;
  Object? get providerDescription => _providerDescription.value;

  // ----------------------------------------------------------------- photos
  final RxBool UpdateStatePhotoUpload = true.obs;

  final RxBool photoLoading = false.obs;
  final RxBool photoError = false.obs;
  final RxnString photoUrl = RxnString();

  final RxBool qrLoading = false.obs;
  final RxBool qrError = false.obs;
  final RxnString qrUrl = RxnString();

  @override
  void onInit() {
    super.onInit();
    ever(booking, (_) => _syncFromBooking());
  }

  void _syncFromBooking() {
    final b = booking.value;
    _providerApproval.value = b?.providerApprovalStatus;
    _providerTaskComplete.value = b?.providerTaskCompleteStatus;
    _customerApproval.value = b?.userApprovalStatus;
    _customerTaskComplete.value = b?.userTaskCompleteStatus;
    _advanceAmount.value = b?.advancePaymentAmount;
    _startDate.value = b?.startDate;
    _endDate.value = b?.endDate;
    _providerDescription.value = b?.providerBookingDescription;
  }

  // =========================================================================
  // INIT
  // =========================================================================
  void init({
    required List<BookingInfoModel> bookings,
    required String email,
    required String jwt,
  }) {
    _email = email;
    _jwt = jwt;
    busyKey.value = '';
    isRefreshing.value = false;
    photoUrl.value = null;
    qrUrl.value = null;
    photoError.value = false;
    qrError.value = false;
    booking.value = bookings.isEmpty ? null : bookings[0];
    _syncFromBooking();
  }

  // =========================================================================
  // SESSION
  // =========================================================================
  Future<void> forceRelogin() async {
    try {
      await Clear_User_Data();
      await Random_token_Clear();
      Get.offAll(() => ErrorPage());
      _toast.Toastmsg("Session ended. Please log in again.");
    } catch (e) {
      print(e);
    }
  }

  Future<void> verifyJwt() async {
    try {
      final int result = await ProviderJwtVerify(Jwt_Token: _jwt);
      if (result != 1) await forceRelogin();
    } catch (e) {
      print("Unexpected error in verifyJwt: $e");
      _toast.Toastmsg("Something went wrong. Please try again.");
      await forceRelogin();
    }
  }

  // =========================================================================
  // LOW LEVEL PUT
  // Returns: 1 ok, 2 server, 3 session, 4 not found, 5 bad format,
  //          6 failed, 7 exception, 8 already done.
  // =========================================================================
  Future<int> _put(
      String path,
      Map<String, dynamic> body, {
        required String okMsg,
        String? alreadyMsg,
      }) async {
    try {
      final r = await http.put(
        Uri.parse(Backend_Server_Url + path),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $_jwt',
        },
        body: json.encode(body),
      );
      switch (r.statusCode) {
        case 200:
          _toast.Toastmsg(okMsg);
          return 1;
        case 500:
          _toast.Toastmsg("Server error. Please try again.");
          return 2;
        case 502:
          await forceRelogin();
          return 3;
        case 503:
          _toast.Toastmsg("No booking found for this ID.");
          return 4;
        case 501:
          _toast.Toastmsg("Invalid data format.");
          return 5;
        case 504:
          if (alreadyMsg != null) {
            _toast.Toastmsg(alreadyMsg);
            return 8;
          }
          _toast.Toastmsg("Update failed. Try again.");
          return 6;
        default:
          _toast.Toastmsg("Update failed. Try again.");
          return 6;
      }
    } catch (e) {
      print(e);
      _toast.Toastmsg("Update failed. Try again.");
      return 7;
    }
  }

  // =========================================================================
  // API CALLS
  // =========================================================================
  Future<int> UpdateDate({
    required String UserEmail,
    required num BookId,
    required String StartDate,
    required String EndDate,
  }) {
    return _put(
      "api/Booking/updatedate",
      {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "StartDate": StartDate,
        "EndDate": EndDate,
      },
      okMsg: "Schedule updated.",
    );
  }

  Future<int> UpdateAdvanceAmount({
    required String UserEmail,
    required num BookId,
    required double AdvanceAmount,
  }) {
    return _put(
      "api/Booking/updateadvanceamount",
      {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "AdvancePaymentAmount": AdvanceAmount,
      },
      okMsg: "Advance amount updated.",
      alreadyMsg: "Advance amount was already changed.",
    );
  }

  Future<int> UpdateProviderApprovalStatus({
    required String UserEmail,
    required num BookId,
  }) {
    return _put(
      "api/Booking/updateproviderapprovalstatus",
      {"UserEmail": UserEmail, "BookId": BookId},
      okMsg: "Approval updated.",
      alreadyMsg: "You have already approved this booking.",
    );
  }

  Future<int> UpdateDescription({
    required String UserEmail,
    required num BookId,
    required String UserBookingDescription,
  }) {
    return _put(
      "api/Booking/updateproviderdescp",
      {
        "UserEmail": UserEmail,
        "BookId": BookId,
        "UserBookingDescription": UserBookingDescription,
      },
      okMsg: "Description updated.",
    );
  }

  // =========================================================================
  // REFRESH: clear ReactiveBookingInfos -> add new items -> booking.value
  // [silent] = true after an update (no extra toast); false for the manual
  // refresh button, which shows the real status code so failures are visible.
  // =========================================================================
  Future<bool> refreshBooking(BuildContext context, {bool silent = true}) async {
    final b = booking.value;
    if (b == null || b.bookId == null) return false;
    isRefreshing.value = true;
    try {
      final response = await http.post(
        Uri.parse(Backend_Server_Url + "api/Booking/sendfilterbookinginfo"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_jwt",
        },
        body: jsonEncode({"BookId": b.bookId!.toInt()}),
      );

      final int code = response.statusCode;
      if (code == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body.trim());
        final List<BookingInfoModel> fresh = jsonData
            .map((e) => BookingInfoModel.fromJson(e))
            .toList();
        if (fresh.isEmpty) {
          if (!silent) _toast.Toastmsg("No booking data available.");
          return false;
        }
        ReactiveBookingInfos.clear(); // delete old list
        ReactiveBookingInfos.addAll(fresh); // add new items
        booking.value = ReactiveBookingInfos[0]; // UI rebuilds
        booking.refresh();
        return true;
      }

      if (code == 401 || code == 403 || code == 502 || code == 506) {
        _toast.Toastmsg("Please log in again. Your session is invalid.");
        await Logout(context: context);
        return false;
      }

      if (!silent) {
        _toast.Toastmsg("Could not refresh booking (server code $code).");
      }
      return false;
    } catch (e) {

      if (!silent) _toast.Toastmsg("Could not refresh booking.");
      return false;
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> refreshAll(BuildContext context, {bool silent = true}) async {
    await refreshBooking(context, silent: silent);
    await Future.wait([fetchPhoto(context), fetchQr(context)]);
  }

  Future<void> markTaskComplete(BuildContext context) async {
    _providerTaskComplete.value = true;
    await refreshBooking(context);
  }

  // =========================================================================
  // PHOTOS
  // =========================================================================
  Future<void> reloadPhoto(BuildContext context) async {
    UpdateStatePhotoUpload.value = !UpdateStatePhotoUpload.value;
    await fetchPhoto(context);
  }

  Future<void> fetchPhoto(BuildContext context) async {
    final b = booking.value;
    if (b == null || b.bookId == null) {
      photoUrl.value = null;
      return;
    }
    photoLoading.value = true;
    photoError.value = false;
    try {
      await GetAdvancePaymentPhoto(
        BookId: b.bookId!.toString(),
        UserEmail: _email,
        context: context,
        Current_User_JwtToken: _jwt,
        UpdateStatePhotoUpload: UpdateStatePhotoUpload.value,
      );
      if (AdvancePaymentPhotoList.isEmpty) {
        photoUrl.value = null;
      } else {
        final String url = GetPhotoUrl(
          AdvancePaymentPhotoList[0].paymentPhoto ?? "",
        );
        photoUrl.value = url.isEmpty ? null : url;
      }
    } catch (e) {

      photoError.value = true;
      photoUrl.value = null;
    } finally {
      photoLoading.value = false;
    }
  }

  Future<void> fetchQr(BuildContext context) async {
    final b = booking.value;
    if (b == null || b.providerNumber == null) {
      qrUrl.value = null;
      return;
    }
    qrLoading.value = true;
    qrError.value = false;
    try {
      await GetAdvancePaymentQRPhoto(
        UserNumber: b.providerNumber!,
        context: context,
        Current_User_JwtToken: _jwt,
      );
      if (AdvancePaymentQrPhotoList.isEmpty) {
        qrUrl.value = null;
      } else {
        final String url = GetPhotoUrl(
          AdvancePaymentQrPhotoList[0].qrPhoto ?? "",
        );
        qrUrl.value = url.isEmpty ? null : url;
      }
    } catch (e) {

      qrError.value = true;
      qrUrl.value = null;
    } finally {
      qrLoading.value = false;
    }
  }

  // =========================================================================
  // ACTIONS — each returns true when the change was saved.
  // =========================================================================
  Future<bool> saveSchedule(
      BuildContext context, {
        required DateTime start,
        required DateTime end,
      }) async {
    final b = booking.value;
    if (busyKey.value.isNotEmpty || b == null || b.bookId == null) return false;
    busyKey.value = 'date';
    try {
      final r = await UpdateDate(
        UserEmail: _email,
        BookId: b.bookId!,
        StartDate: start.toIso8601String(),
        EndDate: end.toIso8601String(),
      );
      if (r == 1)
      {
        _startDate.value = start.toIso8601String(); // instant UI update
        _endDate.value = end.toIso8601String();
        await refreshBooking(context);
        await _notifyCustomer(
          context,
          b.userNumber! as int,
          "Provider updated the schedule(Date) from $formatDateTime($start) to $formatDateTime($end) for booking ID = ${b.bookId}.",
        );
      }
      return r == 1;
    } catch (e) {

      _toast.Toastmsg("Something went wrong.");
      return false;
    } finally {
      busyKey.value = '';
    }
  }

  Future<bool> saveAdvance(BuildContext context, double amount) async {
    final b = booking.value;
    if (busyKey.value.isNotEmpty ||
        b == null ||
        b.bookId == null ||
        b.userNumber == null) {
      return false;
    }
    busyKey.value = 'advance';
    try {
      final r = await UpdateAdvanceAmount(
        UserEmail: _email,
        BookId: b.bookId!,
        AdvanceAmount: amount,
      );
      if (r == 1) {
        _advanceAmount.value = amount; // instant UI update
        await refreshBooking(context);
        await _notifyCustomer(
          context,
          b.userNumber! as int,
          "Provider updated the advance amount to $amount for booking #${b.bookId}.",
        );
      }
      return r == 1;
    } catch (e) {
      _toast.Toastmsg("Something went wrong.");
      return false;
    } finally {
      busyKey.value = '';
    }
  }

  Future<bool> approve(BuildContext context) async {
    final b = booking.value;
    if (busyKey.value.isNotEmpty ||
        b == null ||
        b.bookId == null ||
        b.userNumber == null) {
      return false;
    }
    busyKey.value = 'approval';
    try {
      final r = await UpdateProviderApprovalStatus(
        UserEmail: _email,
        BookId: b.bookId!,
      );
      // 1 = approved now, 8 = server says already approved. Both mean approved.
      if (r == 1 || r == 8) {
        _providerApproval.value = true; // instant UI update
        await refreshBooking(context);
      }
      if (r == 1) {
        await _notifyCustomer(
          context,
          b.userNumber! as int,
          "Provider changed the approval status for booking #${b.bookId}.",
        );
      }
      return r == 1 || r == 8;
    } catch (e) {


      _toast.Toastmsg("Something went wrong.");
      return false;
    } finally {
      busyKey.value = '';
    }
  }

  Future<bool> saveDescription(BuildContext context, String text) async {
    final b = booking.value;
    if (busyKey.value.isNotEmpty || b == null || b.bookId == null) return false;
    busyKey.value = 'desc';
    try {
      final r = await UpdateDescription(
        UserEmail: _email,
        BookId: b.bookId!,
        UserBookingDescription: text,
      );
      if (r == 1) {
        _providerDescription.value = text; // instant UI update
        await refreshBooking(context);
      }
      return r == 1;
    } catch (e) {


      _toast.Toastmsg("Something went wrong.");
      return false;
    } finally {
      busyKey.value = '';
    }
  }

  Future<void> _notifyCustomer(
      BuildContext context,
      int receiverNumber,
      String message,
      ) async {
    try {
      await AddNotifications(
        ReceiverNumber: receiverNumber,
        Message: message,
        Current_User_JwtToken: _jwt,
        context: context,
      );
      await AddNewNotifications(
        ReceiverNumber: receiverNumber,
        Status: true,
        Current_User_JwtToken: _jwt,
        context: context,
      );
    } catch (e) {
      print(e);
    }
  }
}