import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust the relative import segment counts if your folder depth differs.
import '../../../models/AdminUserInfosModel.dart';
import '../../../web/common method/Commmon_Method.dart';
import '../../../web/communi_services/services.dart';

// =============================================================================
// CONTROLLER — all state lives here (no setState anywhere).
// =============================================================================
class ChatScreenController extends GetxController {
  final RxList<AdminUserInfosModel> Users = <AdminUserInfosModel>[].obs;
  final RxString SearchText = ''.obs;
  final RxBool IsLoading = false.obs;
  final RxString ErrorMessage = ''.obs;

  // NEW reactive mirrors of the SignalR service values. The service exposes
  // plain values (not observables), which is what made the old header Obx
  // throw "improper use of GetX". These are refreshed by a light timer so
  // every Obx on the screen has a real observable to listen to.
  final RxBool IsConnected = false.obs;
  final RxSet<int> OnlineNumbers = <int>{}.obs;

  // NEW UI-only state.
  final RxInt HoveredIndex = (-1).obs;
  final TextEditingController SearchCont = TextEditingController();

  SignalRService? SignalR;
  late int CurrentUserNumber;
  late String User_JwtToken;

  Timer? _syncTimer;

  @override
  void onInit() {
    super.onInit();

    try {
      SignalR = Get.find<SignalRService>();
    } catch (e) {
      print('ChatScreen: SignalRService not registered: $e');
    }

    try {
      _syncSignalR();
      _syncTimer = Timer.periodic(
        const Duration(seconds: 2),
            (_) => _syncSignalR(),
      );
    } catch (e) {
      print('ChatScreen sync timer error: $e');
    }
  }

  @override
  void onClose() {
    try {
      _syncTimer?.cancel();
      SearchCont.dispose();
    } catch (e) {
      print('ChatScreen onClose error: $e');
    }
    super.onClose();
  }

  // Copies the service's connection + online users into the observables.
  // Only assigns when something actually changed (avoids needless rebuilds).
  void _syncSignalR() {
    try {
      final service = SignalR;
      if (service == null) {
        if (IsConnected.value) IsConnected.value = false;
        if (OnlineNumbers.isNotEmpty) OnlineNumbers.clear();
        return;
      }

      final bool connected = service.IsSignalRConnected == true;
      if (IsConnected.value != connected) IsConnected.value = connected;

      final dynamic raw = service.OnlineUserNumbers;
      final Set<int> next = <int>{};
      if (raw is Iterable) {
        for (final n in raw) {
          if (n is int) next.add(n);
        }
      }

      final bool same = next.length == OnlineNumbers.length &&
          next.every((n) => OnlineNumbers.contains(n));
      if (!same) OnlineNumbers.assignAll(next);
    } catch (e) {
      print('ChatScreen _syncSignalR error: $e');
    }
  }

  void Initialize({
    required String JwtToken,
    required int UserNumber,
  }) {
    try {
      User_JwtToken = JwtToken;
      CurrentUserNumber = UserNumber;
      LoadUsers();
    } catch (e) {
      print('ChatScreen initialization error: $e');
      ErrorMessage.value = 'Unable to initialize the chat screen.';
    }
  }

  Future<void> LoadUsers() async {
    try {
      IsLoading.value = true;
      ErrorMessage.value = '';

      await GetUserInfo(jwttoken: User_JwtToken);

      Users.assignAll(
        UserInfoModelList.where(
              (user) => user.userNumber != CurrentUserNumber,
        ).toList(),
      );

      print('ChatScreen: ${Users.length} users loaded.');
    } catch (e) {
      print('ChatScreen LoadUsers error: $e');
      ErrorMessage.value = 'Unable to load users. Please try again.';
      Users.clear();
    } finally {
      IsLoading.value = false;
      _syncSignalR();
    }
  }

  List<AdminUserInfosModel> GetFilteredUsers() {
    try {
      final query = SearchText.value.trim().toLowerCase();

      if (query.isEmpty) {
        return Users.toList();
      }

      return Users.where((user) {
        final name =
        '${user.firstName ?? ''} ${user.lastName ?? ''}'.toLowerCase();
        final email = (user.email ?? '').toLowerCase();
        final number = '${user.userNumber ?? ''}';

        return name.contains(query) ||
            email.contains(query) ||
            number.contains(query);
      }).toList();
    } catch (e) {
      print('ChatScreen filtering error: $e');
      return [];
    }
  }

  // Reads the observable set, so any Obx calling this reacts to changes.
  bool IsUserOnline(int? UserNumber) {
    try {
      if (UserNumber == null) return false;
      return OnlineNumbers.contains(UserNumber);
    } catch (e) {
      print('Online status lookup error: $e');
      return false;
    }
  }

  int get OnlineCount {
    try {
      int n = 0;
      for (final u in Users) {
        if (u.userNumber != null && OnlineNumbers.contains(u.userNumber)) n++;
      }
      return n;
    } catch (e) {
      return 0;
    }
  }

  void ClearSearch() {
    try {
      SearchCont.clear();
      SearchText.value = '';
    } catch (e) {
      print('ChatScreen clear search error: $e');
    }
  }
}