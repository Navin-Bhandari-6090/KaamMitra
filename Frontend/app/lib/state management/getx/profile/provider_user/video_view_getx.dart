import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../models/ProviderSerResVideoModel.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';

// Adjust the relative import segment counts above if your actual folder
// depth differs.

enum ScreenState { checkingSession, loading, empty, error, loaded }

// =============================================================================
// MAIN SCREEN CONTROLLER
// =============================================================================
class VideoViewGetx extends GetxController {
  final Rx<ScreenState> screenState = ScreenState.checkingSession.obs;
  final RxString screenErrorText = "Something went wrong.".obs;
  final RxList<ProviderSerResVideoModel> ProviderServiceVideoList =
      <ProviderSerResVideoModel>[].obs;

  // ---------------- Search ----------------
  final RxString query = ''.obs;
  final TextEditingController searchCtrl = TextEditingController();

  late String _email;
  late String _jwtToken;
  late String _serviceName;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({
    required String email,
    required String jwtToken,
    required String serviceName,
  }) async {
    _email = email;
    _jwtToken = jwtToken;
    _serviceName = serviceName;
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bool sessionOk = await JwtVerify(Jwt_Token: _jwtToken);
    if (!sessionOk) return;
    await GetProviderServiceResourceVideos(Email: _email, jwttoken: _jwtToken);
  }

  Future<bool> JwtVerify({required String Jwt_Token}) async {
    try {
      final int result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
      if (result == 1) return true;

      await Clear_User_Data();
      await Random_token_Clear();
      Get.offAll(() => ErrorPage());
      Toastget().Toastmsg("Session End.Relogin please.");
      return false;
    } catch (e) {
      debugPrint('JwtVerify error: $e');
      return false;
    }
  }

  Future<int> GetProviderServiceResourceVideos({
    required String Email,
    required String jwttoken,
  }) async {
    if (!isClosed) screenState.value = ScreenState.loading;

    try {
      const String url = Backend_Server_Url + "api/Profile/getservicevideoinfo";

      final Map<String, dynamic> UserDetails = {
        "Email": Email,
        "ServiceName": _serviceName,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode(UserDetails),
      );

      // 404 = nothing uploaded yet, treated as "empty", not "error".
      if (response.statusCode == 404) {
        if (!isClosed) {
          ProviderServiceVideoList.clear();
          screenState.value = ScreenState.empty;
        }
        return 1;
      }

      if (response.statusCode != 200) {
        debugPrint('Video API failed: ${response.statusCode}');
        if (!isClosed) {
          ProviderServiceVideoList.clear();
          screenErrorText.value =
          "Failed to load videos (${response.statusCode}).";
          screenState.value = ScreenState.error;
        }
        return 0;
      }

      final dynamic responseData = jsonDecode(response.body);

      if (responseData is! List) {
        if (!isClosed) {
          screenErrorText.value = "Unexpected response format from server.";
          screenState.value = ScreenState.error;
        }
        return 0;
      }

      final List<ProviderSerResVideoModel> loadedVideos = responseData
          .map((data) => ProviderSerResVideoModel.fromJson(data))
          .toList();

      if (isClosed) return 0;

      ProviderServiceVideoList.value = loadedVideos;
      query.value = '';
      searchCtrl.clear();
      screenState.value =
      loadedVideos.isEmpty ? ScreenState.empty : ScreenState.loaded;

      return 1;
    } catch (e, stackTrace) {
      debugPrint('Video API exception: $e\n$stackTrace');

      if (!isClosed) {
        ProviderServiceVideoList.clear();
        screenErrorText.value = "Network error while loading videos.";
        screenState.value = ScreenState.error;
      }
      return 0;
    }
  }

  // ==================================================================
  // HELPERS (null-safe, never displayed raw)
  // ==================================================================
  String _clean(String? v) {
    final String t = (v ?? '').trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t;
  }

  String displayOr(String? v) {
    final String t = _clean(v);
    return t.isEmpty ? 'No data available' : t;
  }

  String idOf(ProviderSerResVideoModel v) =>
      _clean(v.providerServiceResourcesId?.toString());

  String serviceIdOf(ProviderSerResVideoModel v) =>
      _clean(v.providerServiceId?.toString());

  String titleOf(ProviderSerResVideoModel v) => _clean(v.serviceTitle);

  /// Internal only. Used by the player. Never displayed.
  String videoUrlOf(ProviderSerResVideoModel v) {
    try {
      final String p = _clean(v.serviceVideo);
      if (p.isEmpty) return '';
      if (p.startsWith('http://') || p.startsWith('https://')) return p;
      return resolveUrl(p);
    } catch (_) {
      return '';
    }
  }

  String resolveUrl(String relativePath) {
    String base = Backend_Server_Url;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    final String rel =
    relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$base$rel';
  }

  // ==================================================================
  // SEARCH (resource ID or title)
  // ==================================================================
  List<ProviderSerResVideoModel> get filteredVideos {
    try {
      final String q = query.value.trim().toLowerCase();
      final List<ProviderSerResVideoModel> all =
      ProviderServiceVideoList.toList();
      if (q.isEmpty) return all;
      return all.where((v) {
        return idOf(v).toLowerCase().contains(q) ||
            titleOf(v).toLowerCase().contains(q);
      }).toList();
    } catch (_) {
      return const <ProviderSerResVideoModel>[];
    }
  }

  @override
  void onClose() {
    try {
      searchCtrl.dispose();
    } catch (_) {}
    super.onClose();
  }
}

// =============================================================================
// PER-CARD CONTROLLER — playback error text + retry.
// =============================================================================
class VideoCardController extends GetxController {
  final Rxn<String> errorText = Rxn<String>();

  void setError(String? text) => errorText.value = text;

  void clearError() => errorText.value = null;
}

// =============================================================================
// PER-PLAYER-SURFACE CONTROLLER — controls visibility + auto-hide timer.
// =============================================================================
class PlayerControlsController extends GetxController {
  final RxBool controlsVisible = true.obs;
  Timer? _hideTimer;

  void scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) controlsVisible.value = false;
    });
  }

  void toggle() {
    controlsVisible.value = !controlsVisible.value;
    if (controlsVisible.value) scheduleHide();
  }

  @override
  void onClose() {
    _hideTimer?.cancel();
    super.onClose();
  }
}