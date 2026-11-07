import 'package:app/models/NewNotificationsModel.dart';
import 'package:app/models/NotificationsInfoModel.dart';
import 'package:app/web/common%20method/notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminHomeGetx extends GetxController {
  final RxList<NotificationsInfoModel> notifications =
      <NotificationsInfoModel>[].obs;
  final RxList<NewNotificationsModel> newStatuses =
      <NewNotificationsModel>[].obs;

  // Bell state. Read by the AppBar bell.
  final RxBool hasNewFlag = false.obs;
  final RxInt newCountFlag = 0.obs;

  final RxBool isLoading = false.obs;
  final RxBool isMarking = false.obs;
  final RxBool loadFailed = false.obs;
  final RxString lastUpdate = ''.obs;

  String _email = '';
  String _jwtToken = '';

  Worker? _bellWorker;

  void init({required String email, required String jwtToken}) {
    _email = email;
    _jwtToken = jwtToken;
  }

  @override
  void onInit() {
    super.onInit();
    _bellWorker = ever<bool>(hasNewFlag, (bool v) {
      debugPrint(
          '[AdminHome] BELL -> ${v ? "RED (new)" : "NORMAL (no new)"}, '
              'newCount=${newCountFlag.value}');
    });
  }

  @override
  void onClose() {
    _bellWorker?.dispose();
    super.onClose();
  }

  bool get hasNew => hasNewFlag.value;

  int get newCount => newCountFlag.value;

  /// Sets the bell from the status rows returned by the server.
  void _applyStatuses(List<NewNotificationsModel> rows) {
    int trueCount = 0;
    for (final NewNotificationsModel r in rows) {
      final bool? s = r.status;
      debugPrint(
          '[AdminHome] status row: newNotId=${r.newNotId}, '
              'receiver=${r.receiverNumber}, status=$s (${s.runtimeType})');
      if (s == true) trueCount++;
    }
    newStatuses.assignAll(rows);
    newCountFlag.value = trueCount;
    hasNewFlag.value = trueCount > 0;
    debugPrint(
        '[AdminHome] status applied: rows=${rows.length}, trueRows=$trueCount');
  }

  /// Loads the messages list. Returns the API code (1 = success).
  Future<int> _loadMessages(BuildContext context) async {
    final int result = await GetNotificationsInfo(
      Email: _email,
      Current_User_JwtToken: _jwtToken,
      context: context,
    );
    notifications.assignAll(NotificationsInfoList);
    debugPrint(
        '[AdminHome] messages loaded: ${NotificationsInfoList.length}, '
            'code=$result (1 = success)');
    return result;
  }

  /// Loads status and messages. Used on first open and by the refresh button.
  /// Refresh never changes the status on the server.
  Future<void> loadAll(BuildContext context) async {
    if (isLoading.value) {
      debugPrint('[AdminHome] load skipped: already loading');
      return;
    }
    try {
      isLoading.value = true;
      loadFailed.value = false;


      final int statusResult = await GetNewNotificationInfo(
        Email: _email,
        Current_User_JwtToken: _jwtToken,
        context: context,
      );
      if (statusResult == 1) {
        _applyStatuses(List<NewNotificationsModel>.from(NewNotificationsList));
      } else {
        // Keep the current bell state if the status request failed.
        debugPrint('[AdminHome] status request failed, code=$statusResult');
      }

      final int notifResult = await _loadMessages(context);

      loadFailed.value = statusResult != 1 || notifResult != 1;
      lastUpdate.value = DateTime.now().toIso8601String();

    } catch (e) {
      loadFailed.value = true;
      debugPrint('[AdminHome] load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Bell click: sets the new-notification status to false on the server.
  /// When the update succeeds the bell turns normal right away, and only the
  /// messages are reloaded.
  Future<void> openNotifications(BuildContext context) async {
    if (isMarking.value) {
      debugPrint('[AdminHome] bell click ignored: update already running');
      return;
    }
    int updateResult = -1;
    try {
      isMarking.value = true;
      debugPrint('[AdminHome] bell click: UpdateNewNotificationInfo');
      updateResult = await UpdateNewNotificationInfo(
        Email: _email,
        Current_User_JwtToken: _jwtToken,
        context: context,
      );
      debugPrint(
          '[AdminHome] UpdateNewNotificationInfo result=$updateResult '
              '(1 = success, 3 = logout, 4 = server, 2 = other, 0 = exception)');
    } catch (e) {
      debugPrint('[AdminHome] update error: $e');
    } finally {
      isMarking.value = false;
    }

    if (updateResult == 1) {
      // Status is now false on the server. Show the normal bell at once.
      newStatuses.assignAll(newStatuses
          .map((r) => NewNotificationsModel(
        newNotId: r.newNotId,
        receiverNumber: r.receiverNumber,
        status: false,
      ))
          .toList());
      newCountFlag.value = 0;
      hasNewFlag.value = false;
      debugPrint('[AdminHome] bell set to NORMAL after update');
      await _loadMessages(context);
    } else {
      // Update failed. Reload from the server so the bell shows the real state.
      await loadAll(context);
    }
  }
}