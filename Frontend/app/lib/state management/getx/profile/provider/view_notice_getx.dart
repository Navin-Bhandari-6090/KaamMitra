import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../constant/variable.dart';
import '../../../../models/NoticeProviderModel.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common method/ui_kit.dart';


class ViewNoticeGetx extends GetxController {
  ViewNoticeGetx({required this.jwtToken});

  final String jwtToken;

  final TextEditingController searchController = TextEditingController();

  final RxList<NoticeProviderModel> notices = <NoticeProviderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool sortNewestFirst = true.obs;
  final RxString searchQuery = ''.obs;
  final RxnString errorMessage = RxnString();
  final RxnInt deletingId = RxnInt();

  BuildContext get _context {
    final BuildContext? ctx = Get.context;
    if (ctx == null) throw StateError('No active context');
    return ctx;
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void onReady() {
    super.onReady();
    initialise();
  }

  /// Verifies the JWT (same call as before), then loads the notices.
  Future<void> initialise() async {
    try {
      await Provider_Jwt_Verify(Jwt_Token: jwtToken, context: _context);
    } catch (e, s) {
      debugPrint('ViewNotice verify error: $e\n$s');
    }
    await fetchNotices();
  }

  Future<void> fetchNotices() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final int result =
      await getNoticePro(context: _context, jwtToken: jwtToken);

      if (result != 1) {
        errorMessage.value = 'Could not load notices. Please try again.';
      }
    } catch (e, s) {
      debugPrint('ViewNotice fetchNotices error: $e\n$s');
      errorMessage.value = 'Could not load notices. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Notices after applying the notice ID search and the date sort.
  /// Reads notices, searchQuery and sortNewestFirst, so Obx rebuilds on change.
  List<NoticeProviderModel> get visibleNotices {
    try {
      final String query = searchQuery.value.trim();

      final List<NoticeProviderModel> list = notices.where((n) {
        if (query.isEmpty) return true;
        final String id = n.noticeId?.toInt().toString() ?? '';
        return id.contains(query);
      }).toList();

      list.sort((a, b) {
        final DateTime? da = DateTime.tryParse(a.createdAt ?? '');
        final DateTime? db = DateTime.tryParse(b.createdAt ?? '');
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return sortNewestFirst.value ? db.compareTo(da) : da.compareTo(db);
      });

      return list;
    } catch (e, s) {
      debugPrint('ViewNotice visibleNotices error: $e\n$s');
      return <NoticeProviderModel>[];
    }
  }

  void setSortNewestFirst(bool value) => sortNewestFirst.value = value;

  void clearSearch() => searchController.clear();

  /// Builds a full image URL from the photo path stored in the database.
  /// Returns null when the photo is empty or null, so the initials avatar shows.
  String? photoUrl(String? photo) {
    try {
      final String raw = (photo ?? '').trim();
      if (raw.isEmpty) return null;
      if (raw.startsWith('http')) return raw;

      final String base = Backend_Server_Url.endsWith('/')
          ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
          : Backend_Server_Url;
      final String path = raw.startsWith('/') ? raw : '/$raw';
      return '$base$path';
    } catch (e) {
      return null;
    }
  }

  /// Asks for confirmation (Cancel / Delete), then deletes and updates the list.
  Future<void> confirmAndDelete(NoticeProviderModel item) async {
    try {
      final int? id = item.noticeId?.toInt();
      if (id == null) {
        showAppSnack('Error', 'This notice has no ID and cannot be deleted.',
            error: true);
        return;
      }
      if (deletingId.value != null) return;

      final bool confirmed = await confirmAction(
        title: 'Delete this notice?',
        message: 'Notice #$id will be permanently deleted. This cannot be undone.',
        confirmText: 'Delete',
        destructive: true,
      );
      if (!confirmed) return;

      deletingId.value = id;
      await deleteNotice(context: _context, jwtToken: jwtToken, NoticeId: id);
    } catch (e, s) {
      debugPrint('ViewNotice confirmAndDelete error: $e\n$s');
      showAppSnack('Error', 'Something went wrong. Please try again.',
          error: true);
    } finally {
      deletingId.value = null;
    }
  }

  /// API call moved from the screen. Endpoint and status handling are unchanged.
  Future<int> getNoticePro({
    required BuildContext context,
    required String jwtToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${Backend_Server_Url}api/Service/getnoticepro'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200)
      {
        final dynamic data = jsonDecode(response.body);

        if (data is! List) {
          notices.clear();
          return 0;
        }

        final List<NoticeProviderModel> parsed = data
            .map((item) => NoticeProviderModel.fromJson(item))
            .toList();
        notices.assignAll(parsed);

        return 1;
      } else if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 506) {
        Toast.Toastmsg('Unauthorized. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 510) {
        Toast.Toastmsg('Provider account not found.');
        return 4;
      } else if (response.statusCode == 511) {
        Toast.Toastmsg('Your account has been blocked.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Server error. Please try again later.');
        return 5;
      } else {
        Toast.Toastmsg('Something went wrong. Please try again.');
        return 0;
      }
    } catch (e, s) {
      debugPrint('ViewNotice getNoticePro error: $e\n$s');
      Toast.Toastmsg('Unable to connect to the server.');
      return 0;
    }
  }

  /// API call moved from the screen. Endpoint and status handling are unchanged.
  Future<int> deleteNotice({
    required BuildContext context,
    required String jwtToken,
    required int NoticeId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${Backend_Server_Url}api/Service/deletenotice'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'NoticeId': NoticeId,
        }),
      );

      if (response.statusCode == 200) {
        notices.removeWhere((item) => item.noticeId?.toInt() == NoticeId);
        Toast.Toastmsg('Notice deleted successfully.');
        return 1;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg('Invalid notice information.');
        return 2;
      } else if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 506) {
        Toast.Toastmsg('Unauthorized. Please log in again.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 507) {
        Toast.Toastmsg('Invalid notice ID.');
        return 4;
      } else if (response.statusCode == 510) {
        Toast.Toastmsg('Provider account not found.');
        return 5;
      } else if (response.statusCode == 511) {
        Toast.Toastmsg('Your account has been blocked.');
        await Logout(context: context);
        return 3;
      } else if (response.statusCode == 512) {
        Toast.Toastmsg(
            'Notice not found or you are not authorized to delete it.');
        return 6;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg('Server error. Please try again later.');
        return 7;
      } else {
        Toast.Toastmsg('Something went wrong. Please try again.');
        return 0;
      }
    } catch (e, s) {
      debugPrint('ViewNotice deleteNotice error: $e\n$s');
      Toast.Toastmsg('Unable to connect to the server.');
      return 0;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}