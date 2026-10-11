import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/AdminTaskCompletePaymentModel.dart';
import '../../../web/authentication/Error_page.dart';
import '../../../web/common method/Commmon_Method.dart';

// =============================================================================
// CONTROLLER — all state lives here (no setState anywhere).
// =============================================================================
class BookProTaskCompGetx extends GetxController {
  // ---------------- reactive state ----------------
  final RxList<AdminTaskCompletePaymentModel> adminTaskCompletePaymentList =
      <AdminTaskCompletePaymentModel>[].obs;
  final RxBool isLoading = true.obs;

  /// Non-empty while an action runs, e.g. "delb_15". Used to disable buttons.
  final RxString busyKey = ''.obs;

  /// 0 = Booking details, 1 = Task payment
  final RxInt tab = 0.obs;
  final RxString bookingQuery = ''.obs;
  final RxString paymentQuery = ''.obs;

  final TextEditingController bookingSearchCont = TextEditingController();
  final TextEditingController paymentSearchCont = TextEditingController();

  String _jwt = '';

  Future<void> init({required String jwtToken}) async {
    _jwt = jwtToken;
    await loadInfo();
  }

  @override
  void onClose() {
    try {
      bookingSearchCont.dispose();
      paymentSearchCont.dispose();
    } catch (obj) {
      print(obj.toString());
    }
    super.onClose();
  }

  Future<void> loadInfo() async {
    try {
      isLoading.value = true;
      await GetAllTaskCompletePayments(JwtToken: _jwt);
    } catch (obj) {
      print(obj.toString());
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH / FILTER
  // ---------------------------------------------------------------------------
  String _s(num? n) {
    if (n == null) return '';
    return n % 1 == 0 ? n.toInt().toString() : n.toString();
  }

  /// Every booking exactly once. The server sends one item per payment, so a
  /// booking with several payments appears several times in the raw list.
  List<AdminTaskCompletePaymentModel> get _uniqueBookings {
    final Set<num> seen = <num>{};
    return adminTaskCompletePaymentList.where((m) {
      final num? id = m.bookingInfo?.bookId;
      return id != null && seen.add(id);
    }).toList();
  }

  /// Total distinct bookings (not affected by search). Used by the header.
  int get bookingCount {
    try {
      return _uniqueBookings.length;
    } catch (obj) {
      print(obj.toString());
      return 0;
    }
  }

  /// Booking search: Book ID or User number.
  List<AdminTaskCompletePaymentModel> get filteredBookings {
    try {
      final String q = bookingQuery.value.trim().toLowerCase();
      final list = _uniqueBookings;
      if (q.isEmpty) return list;
      return list.where((m) {
        final b = m.bookingInfo;
        return _s(b?.bookId).contains(q) || _s(b?.userNumber).contains(q);
      }).toList();
    } catch (obj) {
      print(obj.toString());
      return <AdminTaskCompletePaymentModel>[];
    }
  }

  /// Payment search: TaskCompletePaymentId or Book ID.
  /// Includes orphan payments (booking deleted -> bookingInfo == null).
  List<AdminTaskCompletePaymentModel> get filteredPayments {
    try {
      final String q = paymentQuery.value.trim().toLowerCase();
      final list = adminTaskCompletePaymentList
          .where((m) => m.paymentInfo != null)
          .toList();
      if (q.isEmpty) return list;
      return list.where((m) {
        final p = m.paymentInfo;
        final String bid = _s(p?.bookId ?? m.bookingInfo?.bookId);
        return _s(p?.taskCompletePaymentId).contains(q) || bid.contains(q);
      }).toList();
    } catch (obj) {
      print(obj.toString());
      return <AdminTaskCompletePaymentModel>[];
    }
  }

  int get paymentCount =>
      adminTaskCompletePaymentList.where((m) => m.paymentInfo != null).length;

  /// Slash-safe URL joining for payment photos.
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

  // ---------------------------------------------------------------------------
  // ACTIONS used by the screen (each guarded by busyKey + try/catch)
  // ---------------------------------------------------------------------------
  Future<void> deleteBookingAction(num bookId) async {
    if (busyKey.value.isNotEmpty) return;
    busyKey.value = 'delb_${bookId.toInt()}';
    try {
      final int r = await DeleteBooking(BookId: bookId, JwtToken: _jwt);
      if (r == 1) await GetAllTaskCompletePayments(JwtToken: _jwt);
    } catch (obj) {
      print(obj.toString());
    } finally {
      busyKey.value = '';
    }
  }

  Future<void> deletePaymentAction(num paymentId) async {
    if (busyKey.value.isNotEmpty) return;
    busyKey.value = 'delp_${paymentId.toInt()}';
    try {
      final int r = await DeleteTaskCompletePayment(
          TaskCompletePaymentId: paymentId, JwtToken: _jwt);
      if (r == 1) await GetAllTaskCompletePayments(JwtToken: _jwt);
    } catch (obj) {
      print(obj.toString());
    } finally {
      busyKey.value = '';
    }
  }

  Future<void> changeProTaskComplete(
      {
    required BuildContext context,
    required num providerNumber,
    required num bookId,
  }) async {
    if (busyKey.value.isNotEmpty) return;
    busyKey.value = 'pro_${bookId.toInt()}';
    try {

      final int ProviderNumberValue = providerNumber.toInt();
      final int BookIdValue = bookId.toInt();

      final RequestTaskResult = await ProRequestTaskComplete(
        BookId: BookIdValue,
      );

      print("Request for task complete result = ${RequestTaskResult}");

      await AddNotifications(
        ReceiverNumber: ProviderNumberValue,
        Message:
        "KaamMitra have change provider task complete status for the booking id = ${BookIdValue}.",
        Current_User_JwtToken: _jwt,
        context: context,
      );

      await AddNewNotifications(
        ReceiverNumber: ProviderNumberValue,
        Status: true,
        Current_User_JwtToken: _jwt,
        context: context,
      );

      print("notification add success");

      await GetAllTaskCompletePayments(JwtToken: _jwt);
    } catch (e) {
      print(e.toString());
    } finally {
      busyKey.value = '';
    }
  }

  // ---------------------------------------------------------------------------
  // SESSION END (same steps as the original screen)
  // ---------------------------------------------------------------------------
  Future<void> _forceLogout() async {
    try {
      await Clear_User_Data();
      await Random_token_Clear();
      final BuildContext? ctx = Get.context;
      if (ctx != null) {
        Navigator.pushAndRemoveUntil(
          ctx,
          MaterialPageRoute(builder: (context) => ErrorPage()),
              (route) => false,
        );
      }
    } catch (obj) {
      print(obj.toString());
    }
  }

  // ===========================================================================
  // API METHODS
  // ===========================================================================
  Future<int> DeleteBooking({
    required num BookId,
    required String JwtToken,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Admin/deletebooking";
      print("Delete Booking URL: $url");

      final Map<String, dynamic> requestBody = {"BookId": BookId};

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $JwtToken",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print("========== DELETE BOOKING SUCCESS ==========");
        Toast.Toastmsg("Booking information deleted successfully.");
        return 1;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg(response.body.isNotEmpty
            ? response.body
            : "Invalid booking information.");
        return 0;
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Your session has expired. Please login again.");
        await _forceLogout();
        Toast.Toastmsg("Session End.Relogin please.");
        return 0;
      } else if (response.statusCode == 403) {
        Toast.Toastmsg("You do not have permission to delete booking.");
        return 0;
      } else if (response.statusCode == 404) {
        Toast.Toastmsg(response.body.isNotEmpty
            ? response.body
            : "Booking information not found.");
        return 0;
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(response.body.isNotEmpty
            ? response.body
            : "You have been blocked by System.");
        await _forceLogout();
        return 0;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg("Server error occurred while deleting booking.");
        return 0;
      } else {
        print("Delete Booking Unexpected Status: ${response.statusCode}");
        Toast.Toastmsg(
            "Unable to delete booking. Status: ${response.statusCode}");
        return 0;
      }
    } catch (e, stackTrace) {
      print("========== DELETE BOOKING EXCEPTION ==========");
      Toast.Toastmsg("An error occurred while deleting booking information.");
      return 0;
    }
  }

  Future<int> DeleteTaskCompletePayment({
    required num TaskCompletePaymentId,
    required String JwtToken,
  }) async {
    try {
      const String url =
          Backend_Server_Url + "api/Admin/deletetaskcompletepayment";

      final Map<String, dynamic> requestBody = {
        "TaskCompletePaymentId": TaskCompletePaymentId,
      };

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $JwtToken",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print("========== DELETE TASK COMPLETE PAYMENT SUCCESS ==========");
        Toast.Toastmsg("Task complete payment deleted successfully.");
        return 1;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg(response.body.isNotEmpty
            ? response.body
            : "Invalid task complete payment information.");
        return 0;
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Your session has expired. Please login again.");
        await _forceLogout();
        return 0;
      } else if (response.statusCode == 403) {
        Toast.Toastmsg(
            "You do not have permission to delete task complete payment.");
        return 0;
      } else if (response.statusCode == 404) {
        Toast.Toastmsg(response.body.isNotEmpty
            ? response.body
            : "Task complete payment information not found.");
        return 0;
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(response.body.isNotEmpty
            ? response.body
            : "You have been blocked by System.");
        await _forceLogout();
        Toast.Toastmsg("Session End.Relogin please.");
        return 0;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg("Server error occurred while deleting payment.");
        return 0;
      } else {
        Toast.Toastmsg(
            "Unable to delete payment. Status: ${response.statusCode}");
        return 0;
      }
    } catch (e, stackTrace) {
      Toast.Toastmsg(
          "An error occurred while deleting task complete payment.");
      return 0;
    }
  }

  Future<void> GetAllTaskCompletePayments({
    required String JwtToken,
  }) async {
    try {
      const String url =
          Backend_Server_Url + "api/Admin/getalltaskcompletepayments";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $JwtToken",
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          adminTaskCompletePaymentList.clear();
          Toast.Toastmsg(
              "No task complete payment information is available.");
          return;
        }

        final dynamic responseData = jsonDecode(response.body);

        if (responseData is List) {
          final List<AdminTaskCompletePaymentModel> fresh = [];
          int failed = 0;
          for (var item in responseData) {
            try {
              if (item is Map<String, dynamic>) {
                fresh.add(AdminTaskCompletePaymentModel.fromJson(item));
              } else {
                failed++;
                print("Skipped non-map item: $item");
              }
            } catch (e) {
              // Do NOT hide parse problems: this tells you exactly which
              // row/field breaks fromJson.
              failed++;
              print("PARSE FAILED for item: $e\n$item");
              continue;
            }
          }

          print("Received ${responseData.length} items, parsed ${fresh.length}, failed $failed");

          adminTaskCompletePaymentList.assignAll(fresh);

          if (adminTaskCompletePaymentList.isEmpty) {
            print("No booking information is available.");
            Toast.Toastmsg("No booking or payment information is available.");
            return;
          }

          if (failed > 0) {
            Toast.Toastmsg(
                "$failed record(s) could not be read. Check the console log.");
          } else {
            Toast.Toastmsg(
                "Task complete payment information loaded successfully.");
          }
          return;
        } else {
          adminTaskCompletePaymentList.clear();
          Toast.Toastmsg("Invalid data received from server.");
          return;
        }
      } else if (response.statusCode == 400) {
        adminTaskCompletePaymentList.clear();
        Toast.Toastmsg(
            response.body.isNotEmpty ? response.body : "Invalid request data.");
      } else if (response.statusCode == 401) {
        adminTaskCompletePaymentList.clear();
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        adminTaskCompletePaymentList.clear();
        Toast.Toastmsg("You are not authorized to access this information.");
      } else if (response.statusCode == 404) {
        adminTaskCompletePaymentList.clear();
        Toast.Toastmsg(
            response.body.isNotEmpty ? response.body : "Admin user not found.");
      } else if (response.statusCode == 506) {
        adminTaskCompletePaymentList.clear();
        Toast.Toastmsg(response.body.isNotEmpty
            ? response.body
            : "You have been blocked by System. Contact KaamMitra community.");
      } else if (response.statusCode == 500) {
        adminTaskCompletePaymentList.clear();
        Toast.Toastmsg(
            response.body.isNotEmpty ? response.body : "Server error occurred.");
      } else {
        adminTaskCompletePaymentList.clear();
        Toast.Toastmsg(
            response.body.isNotEmpty ? response.body : "Something went wrong.");
      }
    } catch (e, stackTrace) {
      print("GetAllTaskCompletePayments exception: $e\n$stackTrace");
      adminTaskCompletePaymentList.clear();
      Toast.Toastmsg(
          "An error occurred while getting task complete payment information.");
    }
  }

  Future<int> ProRequestTaskComplete({
    required num BookId,
  }) async {
    try {
      final Map<String, dynamic> userData = {"BookId": BookId};
      const String url =
          Backend_Server_Url + "api/Admin/proupdatetaskcompletestatus";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $_jwt',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        print("Update provider task complete status info success");
        Toast.Toastmsg("Update provider task complete status success.");
        return 1;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
            "Update provider task complete status   fail.Try again.Server error.");
        print("SERVER ERROR: ${response.body}");
        return 2;
      } else if (response.statusCode == 502) {
        Toast.Toastmsg("Current user doesn't match.");
        await _forceLogout();
        Toast.Toastmsg("Session End.Relogin please.");
        return 3;
      } else if (response.statusCode == 503) {
        Toast.Toastmsg("No booking data  available of that book id.");
        return 4;
      } else if (response.statusCode == 504) {
        Toast.Toastmsg(
            "You have already change.You cannot update task complete status.");
        return 8;
      } else if (response.statusCode == 501) {
        Toast.Toastmsg(
            "Invalid provider task complete data format.Please provide data in correct format.");
        return 5;
      } else {
        print("Other status code.Error.");
        print("Status code = ${response.statusCode}");
        Toast.Toastmsg(
            "Update provider task complete status  fail.Try again.Server error.");
        return 6;
      }
    } catch (Obj) {
      print("Exception caught while Updating provider task completestatus .");
      print(Obj.toString());
      Toast.Toastmsg(
          "Update provider task complete status  fail.Try again.Server error.");
      return 7;
    }
  }
}