import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../models/ProviderSerResVideoModel.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';


// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.

enum ScreenState { checkingSession, loading, empty, error, loaded }

// =============================================================================
// MAIN SCREEN CONTROLLER — same fields/logic as the original
// _ProviderSerResVideoScreenState, just reactive instead of setState.
// =============================================================================
class VideoViewGetx extends GetxController {
  final Rx<ScreenState> screenState = ScreenState.checkingSession.obs;
  final RxString screenErrorText = "Something went wrong.".obs;
  final RxList<ProviderSerResVideoModel> ProviderServiceVideoList =
      <ProviderSerResVideoModel>[].obs;

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
    int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return true;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      // Context-free navigation via GetX (controllers have no
      // BuildContext) — functionally equivalent to the old
      // Navigator.pushAndRemoveUntil(..., (route) => false).
      Get.offAll(() => ErrorPage());
      Toastget().Toastmsg("Session End.Relogin please.");
      return false;
    }
  }

  Future<int> GetProviderServiceResourceVideos({
    required String Email,
    required String jwttoken,
  }) async {
    if (!isClosed) screenState.value = ScreenState.loading;

    try {
      print('');
      print('================================================');
      print('GET SERVICE RESOURCE VIDEO METHOD CALLED');
      print('================================================');
      print('Email   : $Email');
      print('Service : $_serviceName');

      const String url = Backend_Server_Url + "api/Profile/getservicevideoinfo";

      print('API URL: $url');

      final Map<String, dynamic> UserDetails = {
        "Email": Email,
        "ServiceName": _serviceName,
      };

      print('Request body: ${jsonEncode(UserDetails)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwttoken",
        },
        body: jsonEncode(UserDetails),
      );

      print('Status code: ${response.statusCode}');

      // Backend returns 404 (not 200 + []) when there's no service or no
      // videos uploaded yet — treat that as "empty", not "error".
      if (response.statusCode == 404) {
        print('No videos found for this service (404).');
        if (!isClosed) {
          ProviderServiceVideoList.clear();
          screenState.value = ScreenState.empty;
        }
        return 1;
      }

      if (response.statusCode != 200) {
        print('API FAILED');
        print('Response: ${response.body}');
        if (!isClosed) {
          ProviderServiceVideoList.clear();
          screenErrorText.value =
          "Failed to load videos for \"$_serviceName\" (${response.statusCode}).";
          screenState.value = ScreenState.error;
        }
        return 0;
      }

      final dynamic responseData = jsonDecode(response.body);

      if (responseData is! List) {
        print('ERROR: Response is not a List.');
        if (!isClosed) {
          screenErrorText.value = "Unexpected response format from server.";
          screenState.value = ScreenState.error;
        }
        return 0;
      }

      print('Number of videos: ${responseData.length}');

      final List<ProviderSerResVideoModel> loadedVideos = responseData
          .map((data) => ProviderSerResVideoModel.fromJson(data))
          .toList();

      for (int i = 0; i < loadedVideos.length; i++) {
        final v = loadedVideos[i];
        print('');
        print('--------------- VIDEO $i ---------------');
        print('Service Name: ${v.serviceName}');
        print('Service ID: ${v.providerServiceId}');
        print('Resource ID: ${v.providerServiceResourcesId}');
        print('Video Path: ${v.serviceVideo}');
      }

      if (isClosed) return 0;

      ProviderServiceVideoList.value = loadedVideos;
      screenState.value =
      loadedVideos.isEmpty ? ScreenState.empty : ScreenState.loaded;

      print('');
      print('SERVICE VIDEO API PROCESS SUCCESS');
      print('================================================');

      return 1;
    } catch (e, stackTrace) {
      print('');
      print('================================================');
      print('SERVICE VIDEO API EXCEPTION');
      print('================================================');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('================================================');

      if (!isClosed) {
        ProviderServiceVideoList.clear();
        screenErrorText.value = "Network error while loading videos.";
        screenState.value = ScreenState.error;
      }
      return 0;
    }
  }

  String resolveUrl(String relativePath) {
    String base = Backend_Server_Url;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    String rel = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$base$rel';
  }
}

// =============================================================================
// PER-CARD CONTROLLER — replaces the single setState() that lived in
// _VideoResourceCardState (playback error text + retry). One instance per
// visible card via a unique Get.put tag.
// =============================================================================
class VideoCardController extends GetxController {
  final Rxn<String> errorText = Rxn<String>();

  void setError(String? text) {
    errorText.value = text;
  }

  void clearError() {
    errorText.value = null;
  }
}

// =============================================================================
// PER-PLAYER-SURFACE CONTROLLER — replaces the setState() that lived in
// _PlayerSurfaceState (controls visibility + auto-hide timer). One instance
// per _PlayerSurface widget (inline card and fullscreen page each get their
// own, exactly like the original independent State objects did).
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