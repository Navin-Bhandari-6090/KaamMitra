import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/FooterInfosModel.dart';
import '../../../web/common method/Commmon_Method.dart';


/// UI state for the footer. It only reads footer data and exposes it
/// reactively, so the footer never needs setState.
class FooterController extends GetxController {
  final RxBool isLoading = true.obs;

  final RxString contactNumber = ''.obs;
  final RxString address = ''.obs;
  final RxString email = ''.obs;

  /// Plain text (account names etc.), shown as-is in the footer.
  final RxString socialMediaInfo = ''.obs;

  /// Key of the item currently hovered (web hover effect).
  final RxString hoveredKey = ''.obs;

  bool get hasAnyData =>
      contactNumber.value.isNotEmpty ||
          address.value.isNotEmpty ||
          email.value.isNotEmpty ||
          socialMediaInfo.value.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------
  Future<void> loadFooter({
    required String jwtToken,
    required BuildContext context,
  }) async {
    try {
      if (!hasAnyData) isLoading.value = true;

      final String url = Backend_Server_Url + "api/Home/getfooterinfo";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Backend returns a single object because the table has only one row
        final FooterInfosModel model = FooterInfosModel.fromJson(data);

        contactNumber.value = _clean(model.contactNumber);
        address.value = _clean(model.address);
        email.value = _clean(model.email);
        socialMediaInfo.value = _clean(model.socialMediaInfo);
      } else if (response.statusCode == 401) {
        if (context.mounted) await Logout(context: context);
      } else if (response.statusCode == 502) {
        if (context.mounted) await Logout(context: context);
        Toast.Toastmsg("Session End.Relogin please.");
      } else if (response.statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by the system. Please contact the KaamMitra community.",
        );
        if (context.mounted) Logout(context: context);
      }
      // 400 / 403 / 404 / 500 / others: show nothing, footer shows "No data available"
    } catch (e) {
      debugPrint('FooterController.loadFooter error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Hover
  // ---------------------------------------------------------------------------
  void setHover(String key) {
    hoveredKey.value = key;
  }

  void clearHover(String key) {
    if (hoveredKey.value == key) hoveredKey.value = '';
  }

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------
  Future<void> copyText({required String label, required String value}) async {
    try {
      if (value.trim().isEmpty) return;
      await Clipboard.setData(ClipboardData(text: value.trim()));
      Toast.Toastmsg('$label copied');
    } catch (e) {
      debugPrint('FooterController.copyText error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _clean(String? v) {
    try {
      final String s = (v ?? '').trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return '';
      return s;
    } catch (_) {
      return '';
    }
  }
}