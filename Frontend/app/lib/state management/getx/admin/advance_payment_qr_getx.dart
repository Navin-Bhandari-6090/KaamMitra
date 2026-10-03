import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/AdvancePaymentPhotoModel.dart';
import '../../../models/AdvancePaymentQRPhoto.dart';
import '../../../web/common method/Commmon_Method.dart';

// =============================================================================
// CONTROLLER — the four API methods keep their original logic. The only
// changes: state writes go through Rx lists, and the two delete methods now
// return the status code so the UI can react instantly on 200.
// =============================================================================
class AdvancePaymentQrGetx extends GetxController {
  // ---------------- reactive state ----------------
  final RxList<AdvancePaymentPhotoModel> AdvancePaymentInfoList =
      <AdvancePaymentPhotoModel>[].obs;
  final RxList<AdvancePaymentQrPhoto> AdvancePaymentQrInfoList =
      <AdvancePaymentQrPhoto>[].obs;

  final RxBool isLoading = true.obs;

  /// 0 = payment proofs, 1 = provider QR codes.
  final RxInt tab = 0.obs;

  final RxString paymentQuery = ''.obs;
  final RxString qrQuery = ''.obs;

  final RxSet<int> deletingPaymentIds = <int>{}.obs;
  final RxSet<int> deletingQrIds = <int>{}.obs;

  final TextEditingController PaymentIdCont = TextEditingController();
  final TextEditingController QRIdCont = TextEditingController();
  final TextEditingController paymentSearchCont = TextEditingController();
  final TextEditingController qrSearchCont = TextEditingController();

  late String _jwtToken;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({required String jwtToken}) async {
    _jwtToken = jwtToken;
    await loadAll();
  }

  @override
  void onClose() {
    PaymentIdCont.dispose();
    QRIdCont.dispose();
    paymentSearchCont.dispose();
    qrSearchCont.dispose();
    super.onClose();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    await GetAllAdvancePaymentInfos();
    await GetAllAdvancePaymentQrInfos();
    if (!isClosed) isLoading.value = false;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  int paymentIdOf(AdvancePaymentPhotoModel p) => (p.paymentId ?? -1).toInt();
  int bookIdOf(AdvancePaymentPhotoModel p) => (p.bookId ?? -1).toInt();
  int qrIdOf(AdvancePaymentQrPhoto q) => (q.qrId ?? -1).toInt();
  int providerNumberOf(AdvancePaymentQrPhoto q) =>
      (q.providerNumber ?? -1).toInt();

  /// Payment proofs filtered by payment id OR book id.
  List<AdvancePaymentPhotoModel> get filteredPayments {
    final String q = paymentQuery.value.trim();
    if (q.isEmpty) return AdvancePaymentInfoList.toList();
    return AdvancePaymentInfoList
        .where((p) =>
    paymentIdOf(p).toString().contains(q) ||
        bookIdOf(p).toString().contains(q))
        .toList();
  }

  /// QR photos filtered by QR id OR provider number.
  List<AdvancePaymentQrPhoto> get filteredQrs {
    final String q = qrQuery.value.trim();
    if (q.isEmpty) return AdvancePaymentQrInfoList.toList();
    return AdvancePaymentQrInfoList
        .where((x) =>
    qrIdOf(x).toString().contains(q) ||
        providerNumberOf(x).toString().contains(q))
        .toList();
  }

  void clearPaymentSearch() {
    paymentSearchCont.clear();
    paymentQuery.value = '';
  }

  void clearQrSearch() {
    qrSearchCont.clear();
    qrQuery.value = '';
  }

  /// Slash-safe joining of the server base url and the stored photo path.
  String buildUrl(String? photoPath) {
    try {
      if (photoPath == null || photoPath.trim().isEmpty) return "";

      final String baseUrl = Backend_Server_Url.endsWith("/")
          ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
          : Backend_Server_Url;

      final String path = photoPath.trim().startsWith("/")
          ? photoPath.trim()
          : "/${photoPath.trim()}";

      return "$baseUrl$path";
    } catch (obj) {
      print("Exception while creating photo URL.");
      print(obj.toString());
      return "";
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE (UI updates instantly on 200)
  // ---------------------------------------------------------------------------
  Future<void> deletePaymentFromInput() async {
    final int? id = int.tryParse(PaymentIdCont.text.trim());
    if (id == null || id <= 0) {
      Toast.Toastmsg("Check properly data format.Payment id is required.");
      return;
    }
    await deletePaymentById(id);
  }

  Future<void> deleteQrFromInput() async {
    final int? id = int.tryParse(QRIdCont.text.trim());
    if (id == null || id <= 0) {
      Toast.Toastmsg("Check properly data format.QR id is required.");
      return;
    }
    await deleteQrById(id);
  }

  Future<void> deletePaymentById(int id) async {
    if (deletingPaymentIds.contains(id)) return;
    deletingPaymentIds.add(id);

    final int result = await DeleteAdvancePaymentInfo(PaymentId: id);

    deletingPaymentIds.remove(id);

    if (result == 200) {
      AdvancePaymentInfoList.removeWhere((p) => paymentIdOf(p) == id);
      if (PaymentIdCont.text.trim() == id.toString()) PaymentIdCont.clear();
    }
  }

  Future<void> deleteQrById(int id) async {
    if (deletingQrIds.contains(id)) return;
    deletingQrIds.add(id);

    final int result = await DeleteAdvancePaymentQrInfo(QRId: id);

    deletingQrIds.remove(id);

    if (result == 200) {
      AdvancePaymentQrInfoList.removeWhere((q) => qrIdOf(q) == id);
      if (QRIdCont.text.trim() == id.toString()) QRIdCont.clear();
    }
  }

  // ===========================================================================
  // ORIGINAL API METHODS — logic unchanged
  // ===========================================================================

  /// Get All Advance Payment Information
  Future<void> GetAllAdvancePaymentInfos() async {
    try {
      AdvancePaymentInfoList.clear();

      const String url =
          Backend_Server_Url + "api/Admin/getalladvancepaymentinfos";

      print("========== GET ALL ADVANCE PAYMENT INFOS ==========");
      print("URL: $url");
      print("JWT Length: ${_jwtToken.length}");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_jwtToken",
        },
      );



      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);

        AdvancePaymentInfoList.assignAll(responseData
            .map((json) => AdvancePaymentPhotoModel.fromJson(json))
            .toList());

        print("Advance Payment Info Count: ${AdvancePaymentInfoList.length}");
      } else if (response.statusCode == 400) {
        AdvancePaymentInfoList.clear();
        Toast.Toastmsg("Data are not in correct format.");
      } else if (response.statusCode == 401) {
        AdvancePaymentInfoList.clear();
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        AdvancePaymentInfoList.clear();
        Toast.Toastmsg("You are not authorized to access this information.");
      } else if (response.statusCode == 404) {
        AdvancePaymentInfoList.clear();
        Toast.Toastmsg("No advance payment information is present.");
      } else if (response.statusCode == 506) {
        AdvancePaymentInfoList.clear();
        Toast.Toastmsg(
            "You have been blocked by System. Contact KaamMitra community.");
      } else if (response.statusCode == 500) {
        AdvancePaymentInfoList.clear();
        Toast.Toastmsg(
            "Something went wrong while getting advance payment information.");
      } else {
        AdvancePaymentInfoList.clear();
        Toast.Toastmsg("Something went wrong.");
      }
    } catch (e, stackTrace) {
      print("========== GET ALL ADVANCE PAYMENT INFOS ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");

      AdvancePaymentInfoList.clear();

      Toast.Toastmsg("Something went wrong.");
    }
  }

  /// Get All Advance Payment QR Information
  Future<void> GetAllAdvancePaymentQrInfos() async {
    try {
      AdvancePaymentQrInfoList.clear();

      const String url =
          Backend_Server_Url + "api/Admin/getalladvancepaymentqrinfos";

      print("========== GET ALL ADVANCE PAYMENT QR INFOS ==========");
      print("URL: $url");
      print("JWT Length: ${_jwtToken.length}");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_jwtToken",
        },
      );



      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);

        AdvancePaymentQrInfoList.assignAll(responseData
            .map((json) => AdvancePaymentQrPhoto.fromJson(json))
            .toList());

        print(
            "Advance Payment QR Info Count: ${AdvancePaymentQrInfoList.length}");
      } else if (response.statusCode == 400) {
        AdvancePaymentQrInfoList.clear();
        Toast.Toastmsg("Data are not in correct format.");
      } else if (response.statusCode == 401) {
        AdvancePaymentQrInfoList.clear();
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        AdvancePaymentQrInfoList.clear();
        Toast.Toastmsg("You are not authorized to access this information.");
      } else if (response.statusCode == 404) {
        AdvancePaymentQrInfoList.clear();
        Toast.Toastmsg("No advance payment QR information is present.");
      } else if (response.statusCode == 506) {
        AdvancePaymentQrInfoList.clear();
        Toast.Toastmsg(
            "You have been blocked by System. Contact KaamMitra community.");
      } else if (response.statusCode == 500) {
        AdvancePaymentQrInfoList.clear();
        Toast.Toastmsg(
            "Something went wrong while getting advance payment QR information.");
      } else {
        AdvancePaymentQrInfoList.clear();
        Toast.Toastmsg("Something went wrong.");
      }
    } catch (e, stackTrace) {
      print("========== GET ALL ADVANCE PAYMENT QR INFOS ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");

      AdvancePaymentQrInfoList.clear();

      Toast.Toastmsg("Something went wrong.");
    }
  }

  /// Delete Advance Payment Information (returns the status code)
  Future<int> DeleteAdvancePaymentInfo({required int PaymentId}) async {
    try {
      const String url =
          Backend_Server_Url + "api/Admin/deleteadvancepaymentinfo";

      print("========== DELETE ADVANCE PAYMENT INFO ==========");
      print("URL: $url");
      print("PaymentId: $PaymentId");
      print("JWT Length: ${_jwtToken.length}");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $_jwtToken",
        },
        body: jsonEncode({
          "paymentId": PaymentId,
        }),
      );



      if (response.statusCode == 200) {
        Toast.Toastmsg("Advance payment information deleted successfully.");
        print("Advance payment information deleted successfully.");
      } else if (response.statusCode == 400) {
        Toast.Toastmsg("Payment ID is required or data is invalid.");
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        Toast.Toastmsg("You are not authorized to delete this information.");
      } else if (response.statusCode == 404) {
        Toast.Toastmsg("Advance payment information not found.");
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(
            "You have been blocked by System. Contact KaamMitra community.");
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
            "Something went wrong while deleting advance payment information.");
      } else {
        Toast.Toastmsg("Something went wrong.");
      }
      return response.statusCode;
    } catch (e, stackTrace) {
      print("========== DELETE ADVANCE PAYMENT INFO ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");

      Toast.Toastmsg("Something went wrong.");
      return 500;
    }
  }

  /// Delete Advance Payment QR Information (returns the status code)
  Future<int> DeleteAdvancePaymentQrInfo({required int QRId}) async {
    try {
      const String url =
          Backend_Server_Url + "api/Admin/deleteadvancepaymentqrinfo";

      print("========== DELETE ADVANCE PAYMENT QR INFO ==========");
      print("URL: $url");
      print("QRId: $QRId");
      print("JWT Length: ${_jwtToken.length}");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $_jwtToken",
        },
        body: jsonEncode({
          "qrId": QRId,
        }),
      );



      if (response.statusCode == 200) {
        Toast.Toastmsg("Advance payment QR information deleted successfully.");
        print("Advance payment QR information deleted successfully.");
      } else if (response.statusCode == 400) {
        Toast.Toastmsg("QR ID is required or data is invalid.");
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        Toast.Toastmsg("You are not authorized to delete this information.");
      } else if (response.statusCode == 404) {
        Toast.Toastmsg("Advance payment QR information not found.");
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(
            "You have been blocked by System. Contact KaamMitra community.");
      } else if (response.statusCode == 500) {
        Toast.Toastmsg(
            "Something went wrong while deleting advance payment QR information.");
      } else {
        Toast.Toastmsg("Something went wrong.");
      }
      return response.statusCode;
    } catch (e, stackTrace) {
      print("========== DELETE ADVANCE PAYMENT QR INFO ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");

      Toast.Toastmsg("Something went wrong.");
      return 500;
    }
  }
}