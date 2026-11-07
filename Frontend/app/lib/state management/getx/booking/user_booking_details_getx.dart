import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:app/constant/Server_Database.dart';
import 'package:app/models/BookingInfoModel.dart';
import 'package:app/web/common method/Commmon_Method.dart';
import 'package:app/web/common widget/toast.dart';

// State + every API call of Userbookinginfodetailsscreen.
// Update flow: API call ok -> instant Rx update -> fetch booking by BookId ->
// ReactiveBookingInfos cleared and refilled -> booking.value replaced -> Obx rebuilds.
class UserBookingDetailsGetx extends GetxController {
  final Toastget _toast = Toastget();

  String _email = '';
  String _jwt = '';

  // Single source of truth for the screen.
  final Rxn<BookingInfoModel> booking = Rxn<BookingInfoModel>();

  // Non-empty while an action runs: 'rate' | 'approve' | 'task' | 'upload'.
  final RxString busyKey = ''.obs;

  // True while the booking is re-fetched (thin progress bar in the app bar).
  final RxBool isRefreshing = false.obs;

  // Rating text field focus (glow effect).
  final RxBool ratingFocused = false.obs;

  // Fields the user changes; set instantly after a successful update, re-synced from booking.
  final Rxn<num> ratingValue = Rxn<num>();
  final Rxn<bool> userApproval = Rxn<bool>();
  final Rxn<bool> userTaskComplete = Rxn<bool>();

  // Photo reload flag (kept from the original controller) + photo / QR state.
  RxBool UpdateStatePhotoUpload = true.obs;
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
    ratingValue.value = b?.ratingValueUser;
    userApproval.value = b?.userApprovalStatus;
    userTaskComplete.value = b?.userTaskCompleteStatus;
  }

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

  void ChangeUpdateStatePhotoUpload() {
    UpdateStatePhotoUpload.value = !UpdateStatePhotoUpload.value;
  }

  // ---------------------------------------------------------------- session
  Future<void> verifyJwt(BuildContext context) async {
    try {
      await User_Jwt_Verify(Jwt_Token: _jwt, context: context);
    } catch (_) {}
  }

  // ------------------------------------------------------------ refresh API
  // silent = true after updates (no extra toast); false for the manual refresh button.
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
        final List<BookingInfoModel> fresh =
        jsonData.map((e) => BookingInfoModel.fromJson(e)).toList();
        if (fresh.isEmpty) {
          if (!silent) _toast.Toastmsg("No booking data available.");
          return false;
        }
        // Delete old list, add new items, then publish to the UI.
        ReactiveBookingInfos.clear();
        ReactiveBookingInfos.addAll(fresh);
        booking.value = ReactiveBookingInfos[0];
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
    } catch (_) {
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

  // ----------------------------------------------------------------- photos
  Future<void> reloadPhoto(BuildContext context) async {
    ChangeUpdateStatePhotoUpload();
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
        final String url =
        GetPhotoUrl(AdvancePaymentPhotoList[0].paymentPhoto ?? "");
        photoUrl.value = url.isEmpty ? null : url;
      }
    } catch (_) {
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
        final String url =
        GetPhotoUrl(AdvancePaymentQrPhotoList[0].qrPhoto ?? "");
        qrUrl.value = url.isEmpty ? null : url;
      }
    } catch (_) {
      qrError.value = true;
      qrUrl.value = null;
    } finally {
      qrLoading.value = false;
    }
  }

  // ------------------------------------------------------------ low level PUT
  // Returns: 1 ok, 2 server, 3 session, 4 not found, 5 bad format / rating done,
  //          6 failed, 7 exception, 8 already done.
  Future<int> _put(
      BuildContext context,
      String path,
      Map<String, dynamic> body, {
        required String okMsg,
        required String failMsg,
        required String notFoundMsg,
        required String invalidMsg,
        String? alreadyMsg,
        String? duplicateMsg,
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
          _toast.Toastmsg(failMsg);
          return 2;
        case 502:
          _toast.Toastmsg("Current user doesn't match.");
          await Logout(context: context);
          return 3;
        case 503:
          _toast.Toastmsg(notFoundMsg);
          return 4;
        case 504:
          if (alreadyMsg != null) {
            _toast.Toastmsg(alreadyMsg);
            return 8;
          }
          _toast.Toastmsg(failMsg);
          return 6;
        case 501:
          _toast.Toastmsg(invalidMsg);
          return 5;
        case 507:
          if (duplicateMsg != null) {
            _toast.Toastmsg(duplicateMsg);
            return 5;
          }
          _toast.Toastmsg(failMsg);
          return 6;
        default:
          _toast.Toastmsg(failMsg);
          return 6;
      }
    } catch (_) {
      _toast.Toastmsg(failMsg);
      return 7;
    }
  }

  // --------------------------------------------------------------- API calls
  Future<int> UpdateRating(
      BuildContext context, {
        required String RatingGiver,
        required num BookId,
        required String RatingReceiver,
        required int RatingValue,
        required String ServiceName,
      }) {
    return _put(
      context,
      "api/Booking/updateuserrating",
      {
        "RatingGiver": RatingGiver,
        "BookId": BookId,
        "RatingReceiver": RatingReceiver,
        "RatingValue": RatingValue,
        "ServiceName": ServiceName,
      },
      okMsg: "Update success.",
      failMsg: "Update fail.Try again.Server error.",
      notFoundMsg: "No booking available of that book id.",
      invalidMsg: "Invalid data format.Please provide data in correct format.",
      duplicateMsg: "Rating value already updated.",
    );
  }

  Future<int> UpdateUserApprovalStatus(
      BuildContext context, {
        required String UserEmail,
        required num BookId,
      }) {
    return _put(
      context,
      "api/Booking/updateuserapprovalstatus",
      {"UserEmail": UserEmail, "BookId": BookId},
      okMsg: "Update success.",
      failMsg: "Update fail.Try again.Server error.",
      notFoundMsg: "No booking available of that book id.",
      invalidMsg:
      "Invalid  approval status data format.Please provide data in correct format.",
      alreadyMsg:
      "You have already accept it.You cannot update approval status.",
    );
  }

  Future<int> UserRequestTaskComplete(
      BuildContext context, {
        required String UserEmail,
        required num BookId,
      }) {
    return _put(
      context,
      "api/Booking/userupdatetaskcompletestatus",
      {"UserEmail": UserEmail, "BookId": BookId},
      okMsg: "Update  task complete status success.",
      failMsg: "Update  task complete status  fail.Try again.Server error.",
      notFoundMsg: "No booking data  available of that book id.",
      invalidMsg:
      "Invalid  task complete data format.Please provide data in correct format.",
      alreadyMsg:
      "You have already change.You cannot update task complete status.",
    );
  }

  // Returns 0 on success (kept from the original), other codes are failures.
  Future<int> UploadAdvancePaymentPhoto({
    required num BookId,
    required List<int> ImageBytes,
    required String PhotoExtension,
  }) async {
    try {
      if (BookId <= 0) {
        _toast.Toastmsg("Invalid BookId.");
        return 1;
      }
      if (ImageBytes.isEmpty) {
        _toast.Toastmsg("Payment photo is required.");
        return 2;
      }
      final String ext =
      PhotoExtension.trim().toLowerCase().replaceFirst('.', '');
      if (ext.isEmpty) {
        _toast.Toastmsg("Photo extension is required.");
        return 3;
      }
      if (ext != "jpg" && ext != "jpeg" && ext != "png") {
        _toast.Toastmsg(
            "Invalid photo format. Only JPG, JPEG and PNG are allowed.");
        return 3;
      }

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(Backend_Server_Url + "api/Booking/uploadadvancepaymentphoto"),
      );
      request.headers["Authorization"] = "Bearer $_jwt";
      request.fields["BookId"] = BookId.toInt().toString();
      request.files.add(http.MultipartFile.fromBytes(
        "PaymentPhoto",
        ImageBytes,
        filename: "payment_photo.$ext",
      ));

      final response = await http.Response.fromStream(await request.send());

      switch (response.statusCode) {
        case 200:
          _toast.Toastmsg("Advance payment photo uploaded successfully.");
          return 0;
        case 400:
          _toast.Toastmsg(response.body);
          return 4;
        case 404:
          _toast.Toastmsg(response.body);
          return 5;
        case 401:
          _toast.Toastmsg("Unauthorized. Please login again.");
          return 6;
        case 403:
          _toast.Toastmsg("You are not authorized.");
          return 7;
        case 500:
          _toast.Toastmsg("Server error while uploading payment photo.");
          return 8;
        default:
          _toast.Toastmsg("Upload failed. Try again.");
          return 9;
      }
    } catch (_) {
      _toast.Toastmsg("Upload failed. Try again.");
      return 10;
    }
  }

  // ----------------------------------------------------------------- actions
  // Each returns true when the change was saved.
  Future<bool> submitRating(BuildContext context, int value) async {
    final b = booking.value;
    if (busyKey.value.isNotEmpty ||
        b == null ||
        b.bookId == null ||
        b.providerEmail == null ||
        b.serviceName == null) {
      return false;
    }
    busyKey.value = 'rate';
    try {
      final r = await UpdateRating(
        context,
        RatingGiver: _email,
        BookId: b.bookId!,
        RatingReceiver: b.providerEmail!,
        RatingValue: value,
        ServiceName: b.serviceName!,
      );
      if (r == 1) {
        ratingValue.value = value; // instant UI update
        await refreshBooking(context);
      }
      return r == 1;
    } catch (_) {
      return false;
    } finally {
      busyKey.value = '';
    }
  }

  // Approval can be changed any number of times (yes <-> no).
  Future<bool> toggleApproval(BuildContext context) async {
    final b = booking.value;
    if (busyKey.value.isNotEmpty ||
        b == null ||
        b.bookId == null ||
        b.providerNumber == null) {
      return false;
    }
    busyKey.value = 'approve';
    try {
      final r = await UpdateUserApprovalStatus(
        context,
        UserEmail: _email,
        BookId: b.bookId!,
      );
      if (r == 1) {
        userApproval.value = !(userApproval.value == true); // instant UI update
        await refreshBooking(context);
        await _notifyProvider(context, b.providerNumber! as int,
            "User have change approval status for the booking id = ${b.bookId}.");
      } else if (r == 8) {
        await refreshBooking(context);
      }
      return r == 1;
    } catch (_) {
      return false;
    } finally {
      busyKey.value = '';
    }
  }

  Future<bool> completeTask(BuildContext context) async {
    final b = booking.value;
    if (busyKey.value.isNotEmpty ||
        b == null ||
        b.bookId == null ||
        b.providerNumber == null) {
      return false;
    }
    busyKey.value = 'task';
    try {
      final r = await UserRequestTaskComplete(
        context,
        UserEmail: _email,
        BookId: b.bookId!,
      );
      if (r == 1) {
        userTaskComplete.value = true; // instant UI update
        await refreshBooking(context);
        await _notifyProvider(context, b.providerNumber! as int,
            "User have change task complete status make sure task is finish for the booking id = ${b.bookId}.");
      } else if (r == 8) {
        await refreshBooking(context);
      }
      return r == 1;
    } catch (_) {
      return false;
    } finally {
      busyKey.value = '';
    }
  }

  Future<bool> uploadPhoto(
      BuildContext context, {
        required List<int> bytes,
        required String extension,
      }) async {
    final b = booking.value;
    if (busyKey.value.isNotEmpty ||
        b == null ||
        b.bookId == null ||
        b.providerNumber == null) {
      return false;
    }
    busyKey.value = 'upload';
    try {
      final r = await UploadAdvancePaymentPhoto(
        BookId: b.bookId!,
        ImageBytes: bytes,
        PhotoExtension: extension,
      );
      if (r == 0) {
        await _notifyProvider(context, b.providerNumber! as int,
            "User have upload the advance amount payment photo for the booking id = ${b.bookId}.");
        await reloadPhoto(context);
        await refreshBooking(context);
      }
      return r == 0;
    } catch (_) {
      return false;
    } finally {
      busyKey.value = '';
    }
  }

  Future<void> _notifyProvider(
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
    } catch (_) {}
  }
}