import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/AdminQRInfoModel.dart';
import '../../../models/BookingInfoModel.dart';
import '../../../models/ProTaskCompPayInfoModel.dart';
import '../../../web/common method/Commmon_Method.dart';

// =============================================================================
// CONTROLLER — all state lives here (no setState anywhere).
// API method bodies are the original logic, moved from the screen.
// Navigation to ErrorPage needs a BuildContext, so the screen hands in
// [onSessionEnd] and the controller calls it exactly where the original
// called Navigator.pushAndRemoveUntil.
// =============================================================================
class ProTaskCompleteGetx extends GetxController {
  // ---------------- reactive state ----------------
  final RxList<AdminQrInfoModel> adminQrInfoList = <AdminQrInfoModel>[].obs;
  final RxList<ProTaskCompPayInfoModel> providerPayments =
      <ProTaskCompPayInfoModel>[].obs;

  final RxBool isLoadingQr = true.obs;
  final RxBool isLoadingPayments = true.obs;

  /// "Domestic" / "International" while that upload is running, else "".
  final RxString uploadingMethod = ''.obs;

  // ---------------- example payment photos (assets) ----------------
  static const String nepalExampleAsset = 'assets/images/payment/nepal.jpg';
  static const String paypalExampleAsset = 'assets/images/payment/paypal.jpg';

  /// asset path -> true (exists) / false (missing). Absent key = still checking.
  final RxMap<String, bool> exampleOk = <String, bool>{}.obs;

  // ---------------- booking + amounts (immutable after init) ----------------
  BookingInfoModel? booking;

  double domesticOriginalPrice = 0;
  double domesticDiscountPercent = 0;
  double domesticDiscountAmount = 0;
  double domesticPaymentAmount = 0;

  double internationalOriginalPrice = 0;
  double internationalDiscountPercent = 0;
  double internationalDiscountAmount = 0;
  double internationalPaymentAmount = 0;

  String _jwt = '';
  void Function()? _onSessionEnd;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({
    required String jwtToken,
    required List<BookingInfoModel> bookings,
    required void Function() onSessionEnd,
  }) async {
    _jwt = jwtToken;
    _onSessionEnd = onSessionEnd;

    try {
      print("Booking info list length = ${bookings.length}");
      booking = bookings.isEmpty ? null : bookings.first;
      _calculateAmounts();
    } catch (obj) {
      print(obj.toString());
    }

    _checkExamples(); // not awaited, shows skeleton until checked
    Provider_Jwt_Verify(Jwt_Token: jwtToken); // not awaited, like the original
    await loadAll();
  }

  @override
  void onClose() {
    clearPicked();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // EXAMPLE PHOTO ASSETS (missing / unreadable asset => "not available")
  // ---------------------------------------------------------------------------
  Future<void> _checkExamples() async {
    for (final String asset in [nepalExampleAsset, paypalExampleAsset]) {
      try {
        final data = await rootBundle.load(asset);
        exampleOk[asset] = data.lengthInBytes > 0;
      } catch (_) {
        exampleOk[asset] = false;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // AMOUNTS (same formula as the original)
  // ---------------------------------------------------------------------------
  void _calculateAmounts() {
    final BookingInfoModel? b = booking;
    if (b == null) return;

    domesticOriginalPrice = (b.domesticPrice ?? 0).toDouble();
    domesticDiscountPercent = (b.domesticPriceDiscount ?? 0).toDouble();
    domesticDiscountAmount =
        domesticOriginalPrice * domesticDiscountPercent / 100;
    domesticPaymentAmount = domesticOriginalPrice - domesticDiscountAmount;

    internationalOriginalPrice = (b.internationalPrice ?? 0).toDouble();
    internationalDiscountPercent =
        (b.internationalPriceDiscount ?? 0).toDouble();
    internationalDiscountAmount =
        internationalOriginalPrice * internationalDiscountPercent / 100;
    internationalPaymentAmount =
        internationalOriginalPrice - internationalDiscountAmount;
  }

  // ---------------------------------------------------------------------------
  // LOADING
  // ---------------------------------------------------------------------------
  Future<void> loadAll() async {
    try {
      isLoadingQr.value = true;
      isLoadingPayments.value = true;
      await GetAdminQRInfo();
      if (!isClosed) isLoadingQr.value = false;
      await GetProviderTaskCompletePayments(JwtToken: _jwt);
    } catch (obj) {
      print(obj.toString());
    } finally {
      if (!isClosed) {
        isLoadingQr.value = false;
        isLoadingPayments.value = false;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS (null / empty safe)
  // ---------------------------------------------------------------------------
  String? qrPathFor(String type) {
    try {
      if (adminQrInfoList.isEmpty) return null;
      final AdminQrInfoModel m = adminQrInfoList.first;
      final String? raw =
      type == "Domestic" ? m.domesticQRPhoto : m.internationalQRPhoto;
      if (raw == null || raw.trim().isEmpty) return null;
      return raw.trim();
    } catch (_) {
      return null;
    }
  }

  /// Slash-safe URL joining.
  String buildUrl(String? path) {
    try {
      if (path == null || path.trim().isEmpty) return "";
      final String baseUrl = Backend_Server_Url.endsWith("/")
          ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
          : Backend_Server_Url;
      final String p =
      path.trim().startsWith("/") ? path.trim() : "/${path.trim()}";
      return "$baseUrl$p";
    } catch (obj) {
      print(obj.toString());
      return "";
    }
  }

  // Payment model fields are read defensively (a missing getter or a null
  // value just yields null instead of crashing the screen).
  String? paymentPhotoOf(ProTaskCompPayInfoModel m) {
    try {
      final v = (m as dynamic).paymentPhoto;
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    } catch (_) {
      return null;
    }
  }

  String? paymentMethodOf(ProTaskCompPayInfoModel m) {
    try {
      final s = (m as dynamic).paymentMethod?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    } catch (_) {
      return null;
    }
  }

  double? paymentAmountOf(ProTaskCompPayInfoModel m) {
    try {
      return double.tryParse(((m as dynamic).paymentAmount ?? '').toString());
    } catch (_) {
      return null;
    }
  }

  int? paymentBookIdOf(ProTaskCompPayInfoModel m) {
    try {
      return num.tryParse(((m as dynamic).bookId ?? '').toString())?.toInt();
    } catch (_) {
      return null;
    }
  }

  DateTime? paymentDateOf(ProTaskCompPayInfoModel m) {
    try {
      final s = ((m as dynamic).paymentDate ?? '').toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  String dateLabel(DateTime? d0) {
    try {
      final DateTime? d = d0?.toLocal();
      if (d == null) return 'Date unavailable';
      const m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final int h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final String mm = d.minute.toString().padLeft(2, '0');
      final String ap = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day} ${m[d.month - 1]} ${d.year}, $h12:$mm $ap';
    } catch (_) {
      return 'Date unavailable';
    }
  }

  /// Payments for this booking when the model exposes a book id, otherwise all
  /// of the provider's payments. Newest first when dates are available.
  List<ProTaskCompPayInfoModel> get visiblePayments {
    final List<ProTaskCompPayInfoModel> all = providerPayments.toList();
    List<ProTaskCompPayInfoModel> out = all;

    try {
      final num? id = booking?.bookId;
      if (id != null && all.any((p) => paymentBookIdOf(p) != null)) {
        out = all.where((p) => paymentBookIdOf(p) == id.toInt()).toList();
      }
      out.sort((a, b) {
        final DateTime? da = paymentDateOf(a);
        final DateTime? db = paymentDateOf(b);
        if (da != null && db != null) return db.compareTo(da);
        if (da != null) return -1;
        if (db != null) return 1;
        return 0;
      });
    } catch (obj) {
      print(obj.toString());
    }
    return out;
  }

  void clearPicked() {
    try {
      change_photo_cont_getx.imageExtension.value = "";
      change_photo_cont_getx.imageBytes.value = null;
      change_photo_cont_getx.imagePath.value = "";
    } catch (obj) {
      print(obj.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIONS used by the screen
  // ---------------------------------------------------------------------------
  Future<void> pickPhoto() async {
    try {
      final int photoResult = await change_photo_cont_getx.pickImage();
      if (photoResult == 1) {
        Toast.Toastmsg("Pick photo success.");
      } else if (photoResult == 2) {
        Toast.Toastmsg("Only $PhotoExtension format accepted.");
      } else if (photoResult == 5) {
        Toast.Toastmsg(
            "Image is larger than $PhotoSize.Please compressed and upload..");
      } else {
        Toast.Toastmsg("Pick photo fail.");
      }
    } catch (obj) {
      print(obj.toString());
    }
  }

  Future<void> submitPayment(String method) async {
    if (uploadingMethod.value.isNotEmpty) return;
    uploadingMethod.value = method;
    try {
      final bytes = change_photo_cont_getx.imageBytes.value;
      if (bytes == null) {
        Toast.Toastmsg("Please pick photo first.");
        return;
      }

      final BookingInfoModel? b = booking;
      if (b == null || b.bookId == null) {
        Toast.Toastmsg("Booking information is not available.");
        return;
      }

      final double amount = method == "Domestic"
          ? domesticPaymentAmount
          : internationalPaymentAmount;

      final int result = await AddTaskCompletePayment(
        PaymentAmount: amount,
        BookId: b.bookId!,
        PaymentMethod: method,
        PaymentPhotoBytes: bytes.toList(),
        PhotoExtension: change_photo_cont_getx.imageExtension.value,
      );

      if (result == 1) {
        clearPicked();

        // Payment photo is saved -> notify KaamMitra automatically.
        // Own try/catch so a notification failure never breaks the flow
        // (the payment is already saved at this point).
        try {
          await AdminAddNotification(
            Message:
            "Provider uploaded a ${method == "Domestic" ? "Nepal (Domestic)" : "International"} payment photo of ${amount.toStringAsFixed(2)} for Book ID ${b.bookId}.",
            jwttoken: _jwt,
          );
        } catch (obj) {
          print(obj.toString());
        }

        await GetProviderTaskCompletePayments(JwtToken: _jwt);
      }
    } catch (obj) {
      print(obj.toString());
    } finally {
      uploadingMethod.value = '';
    }
  }

  // ===========================================================================
  // ORIGINAL API METHODS — logic unchanged
  // ===========================================================================
  Future<void> _endSession() async {
    await Clear_User_Data();
    await Random_token_Clear();
    _onSessionEnd?.call();
    Toast.Toastmsg("Session End.Relogin please.");
  }

  Future<void> Provider_Jwt_Verify({required String Jwt_Token}) async {
    try {
      int Result = await ProviderJwtVerify(Jwt_Token: Jwt_Token);
      if (Result == 1) {
        return;
      } else {
        await _endSession();
        return;
      }
    } catch (e) {
      print("Unexpected error in Provider_Jwt_Verify: $e");
      Toast.Toastmsg("Something went wrong. Please try again.");
      await _endSession();
      return;
    }
  }

  // POST api/Admin/adminaddnot
  /// Notifies KaamMitra (all active admins on the backend). Called
  /// automatically after a payment photo upload succeeds.
  /// Toasts say "KaamMitra" instead of "admin".
  Future<void> AdminAddNotification({
    required String Message,
    required String jwttoken,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Booking/adminaddnot";

      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode({
          "message": Message.trim(),
        }),
      )
          .timeout(const Duration(seconds: 30));

      // print("========== ADMIN ADD NOTIFICATION ==========");
      // print("URL: $url");
      // print("JWT Length: ${jwttoken.length}");
      // print("Message: ${Message.trim()}");
      // print("Status Code: ${response.statusCode}");
      // print("Response Body: ${response.body}");

      // Server message (used only for 400, where it explains what is wrong).
      String ResponseMessage = "";

      if (response.body.isNotEmpty) {
        try {
          final responseData = jsonDecode(response.body);

          if (responseData is Map && responseData["message"] != null) {
            ResponseMessage = responseData["message"].toString();
          }
        } catch (e) {
          // print("Response JSON decode error: $e");
        }
      }

      // Never show the word "admin" to the provider.
      ResponseMessage = ResponseMessage.replaceAll(
        RegExp(r'\b(all\s+)?(active\s+)?admins?\b', caseSensitive: false),
        'KaamMitra',
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg("KaamMitra has been notified about your payment photo.");
      } else if (response.statusCode == 400) {
        Toast.Toastmsg(ResponseMessage.isNotEmpty
            ? ResponseMessage
            : "Could not notify KaamMitra. Invalid notification data.");
      } else if (response.statusCode == 401) {
        Toast.Toastmsg(
            "Payment saved, but KaamMitra could not be notified. Please login again.");
      } else if (response.statusCode == 403) {
        Toast.Toastmsg(
            "Payment saved, but you are not allowed to notify KaamMitra.");
      } else if (response.statusCode == 404) {
        Toast.Toastmsg(
            "Payment saved, but no KaamMitra team member is available right now.");
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
            "Payment saved, but KaamMitra notification failed. Server error.");
      } else {
        Toast.Toastmsg("Payment saved, but KaamMitra could not be notified.");
      }
    } catch (e) {
      // print("========== ADMIN ADD NOTIFICATION EXCEPTION ==========");
      // print(e);

      Toast.Toastmsg(
          "Payment saved, but KaamMitra could not be notified. Check your connection.");
    }
  }

  Future<void> GetAdminQRInfo() async {
    try {
      adminQrInfoList.clear();

      const String url = Backend_Server_Url + "api/Admin/getadminqr";

      print("========== GET ADMIN QR INFO ==========");


      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_jwt",
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        // Backend returns one AdminQRPhotoModel object
        if (responseData is Map<String, dynamic>) {
          adminQrInfoList.add(AdminQrInfoModel.fromJson(responseData));
        }
      } else if (response.statusCode == 400) {
        adminQrInfoList.clear();
      } else if (response.statusCode == 401) {
        adminQrInfoList.clear();
      } else if (response.statusCode == 403) {
        adminQrInfoList.clear();
      } else if (response.statusCode == 404) {
        adminQrInfoList.clear();
      } else if (response.statusCode == 506) {
        adminQrInfoList.clear();
        Toast.Toastmsg(
            "You have been blocked by System. Contact KaamMitra community.");
      } else if (response.statusCode == 500) {
        adminQrInfoList.clear();
        Toast.Toastmsg(
            "Something went wrong while getting admin QR information.");
      } else {
        adminQrInfoList.clear();
        Toast.Toastmsg("Something went wrong.");
      }
    } catch (e, stackTrace) {
      print("========== GET ADMIN QR INFO ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");
      adminQrInfoList.clear();
      Toast.Toastmsg("Something went wrong.");
    }
  }

  Future<int> AddTaskCompletePayment({
    required double PaymentAmount,
    required num BookId,
    required String PaymentMethod,
    required List<int> PaymentPhotoBytes,
    required String PhotoExtension,
  }) async {
    try {
      print("========== ADD TASK COMPLETE PAYMENT ==========");

      const String url =
          Backend_Server_Url + "api/Booking/addtaskcompletepayment";

      // Validate payment method
      if (PaymentMethod.trim().isEmpty) {
        Toast.Toastmsg("Payment method is required.");
        return 4;
      }

      if (PaymentMethod != "Domestic" && PaymentMethod != "International") {
        Toast.Toastmsg("Payment method must be Domestic or International.");
        return 4;
      }

      // Validate payment photo
      if (PaymentPhotoBytes.isEmpty) {
        Toast.Toastmsg("Payment photo is required.");
        return 4;
      }

      // Validate photo extension
      String extension =
      PhotoExtension.trim().toLowerCase().replaceAll(".", "");

      if (extension != "jpg" && extension != "jpeg" && extension != "png") {
        print("Invalid photo extension: $extension");
        Toast.Toastmsg("Only JPG, JPEG and PNG photos are allowed.");
        return 4;
      }

      // Create multipart request
      var request = http.MultipartRequest("POST", Uri.parse(url));

      // Authorization
      request.headers.addAll({
        "Authorization": "Bearer $_jwt",
        "Accept": "application/json",
      });

      // Form fields (PaymentDate is NOT sent; backend uses DateTime.UtcNow)
      request.fields["PaymentAmount"] = PaymentAmount.toString();
      request.fields["BookId"] = BookId.toString();
      request.fields["PaymentMethod"] = PaymentMethod;

      // Payment photo
      request.files.add(
        http.MultipartFile.fromBytes(
          "PaymentPhoto",
          PaymentPhotoBytes,
          filename: "payment.$extension",
        ),
      );

      // print("BookId: $BookId");
      // print("PaymentAmount: $PaymentAmount");
      // print("PaymentMethod: $PaymentMethod");
      // print("Photo Size: ${PaymentPhotoBytes.length} bytes");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);



      if (response.statusCode == 200) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Task-complete payment added successfully.",
        );

        // (original had `imageBytes.value==null;` here, a no-op comparison;
        // it is assigned properly now so the preview disappears after upload)
        change_photo_cont_getx.imageBytes.value = null;
        change_photo_cont_getx.imageExtension.value = "";
        change_photo_cont_getx.imagePath.value = "";



        return 1;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Data are not in correct format.",
        );
        return 4;
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Your session is invalid. Please login again.");
        return 6;
      } else if (response.statusCode == 403) {
        Toast.Toastmsg("You are not authorized to perform this action.");
        return 7;
      } else if (response.statusCode == 404) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Booking or provider information not found.",
        );
        return 2;
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "You have been blocked by System. Contact KaamMitra community.",
        );
        return 10;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
          response.body.isNotEmpty ? response.body : "Server error occurred.",
        );
        return 8;
      } else {
        print("Task-complete payment failed. Status code: ${response.statusCode}");
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "Task-complete payment failed.",
        );
        return 2;
      }
    } catch (e, stackTrace) {
      print("========== TASK COMPLETE PAYMENT FLUTTER ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");
      Toast.Toastmsg("An error occurred while saving task-complete payment.");
      return 0;
    }
  }

  Future<void> GetProviderTaskCompletePayments({
    required String JwtToken,
  }) async {
    try {
      print("========== GET PROVIDER TASK COMPLETE PAYMENTS ==========");

      providerPayments.clear();

      const String url =
          Backend_Server_Url + "api/Booking/getprovidertaskcompletepayments";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $JwtToken",
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData is List) {
          final List<ProTaskCompPayInfoModel> parsed = [];
          for (var item in responseData) {
            if (item is Map<String, dynamic>) {
              parsed.add(ProTaskCompPayInfoModel.fromJson(item));
            }
          }
          providerPayments.assignAll(parsed);
        }

        if (providerPayments.isEmpty) {
          print("Payment list is empty.");
          return;
        }
      } else if (response.statusCode == 400) {
        print("Data are not in correct format.");
      } else if (response.statusCode == 401) {
        print("Invalid or expired JWT token.");
        await _endSession();
        return;
      } else if (response.statusCode == 403) {
        // not authorized — nothing to show
      } else if (response.statusCode == 404) {
        print("No task complete payment information is present for this provider.");
      } else if (response.statusCode == 506) {
        print("Provider login access is blocked.");
        Toast.Toastmsg(
          response.body.isNotEmpty
              ? response.body
              : "You have been blocked by System. Contact KaamMitra community.",
        );
        await _endSession();
        return;
      } else if (response.statusCode == 500) {
        print("Backend server error.");
      } else {
        print("Unexpected status code: ${response.statusCode}");
        return;
      }
    } catch (e, stackTrace) {
      print("========== GET PROVIDER TASK COMPLETE PAYMENTS ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");
    }
  }
}