import 'dart:async';
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

  /// Prevents several overlapping requests (e.g. quick rebuilds).
  bool _isFetching = false;

  bool get hasAnyData {
    try {
      return contactNumber.value.isNotEmpty ||
          address.value.isNotEmpty ||
          email.value.isNotEmpty ||
          socialMediaInfo.value.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------
  Future<void> loadFooter({
    required String jwtToken,
    required BuildContext context,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      if (!hasAnyData) isLoading.value = true;

      final String url = Backend_Server_Url + "api/Home/getfooterinfo";

      final http.Response response = await http
          .get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        _applyResponse(response.body);
      } else if (response.statusCode == 401) {
        await _safeLogout(context);
      } else if (response.statusCode == 502) {
        await _safeLogout(context);
        _safeToast("Session End.Relogin please.");
      } else if (response.statusCode == 506) {
        _safeToast(
          "You have been blocked by the system. Please contact the KaamMitra community.",
        );
        await _safeLogout(context);
      }
      // 400 / 403 / 404 / 500 / others: show nothing, footer shows "No data available"
    } on TimeoutException catch (_) {
      // debugPrint('FooterController.loadFooter timeout');
    } catch (_) {
      // debugPrint('FooterController.loadFooter error: $e');
    } finally {
      _isFetching = false;
      try {
        isLoading.value = false;
      } catch (_) {}
    }
  }

  /// Parses the response safely. A bad body never crashes the footer.
  void _applyResponse(String body) {
    try {
      dynamic data = jsonDecode(body);

      // Backend returns a single object because the table has only one row,
      // but tolerate a list too.
      if (data is List) {
        if (data.isEmpty) return;
        data = data.first;
      }
      if (data is! Map<String, dynamic>) return;

      final FooterInfosModel model = FooterInfosModel.fromJson(data);

      contactNumber.value = _clean(model.contactNumber);
      address.value = _clean(model.address);
      email.value = _clean(model.email);
      socialMediaInfo.value = _clean(model.socialMediaInfo);
    } catch (_) {
      // debugPrint('FooterController._applyResponse error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Hover
  // ---------------------------------------------------------------------------
  void setHover(String key) {
    try {
      hoveredKey.value = key;
    } catch (_) {}
  }

  void clearHover(String key) {
    try {
      if (hoveredKey.value == key) hoveredKey.value = '';
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------
  Future<void> copyText({required String label, required String value}) async {
    try {
      if (value.trim().isEmpty) return;
      await Clipboard.setData(ClipboardData(text: value.trim()));
      _safeToast('$label copied');
    } catch (_) {
      // debugPrint('FooterController.copyText error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Future<void> _safeLogout(BuildContext context) async {
    try {
      if (context.mounted) await Logout(context: context);
    } catch (_) {
      // debugPrint('FooterController logout error: $e');
    }
  }

  void _safeToast(String message) {
    try {
      Toast.Toastmsg(message);
    } catch (_) {}
  }

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