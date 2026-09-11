import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../constant/Server_Database.dart';
import '../../../../models/ProviderServiceFileModel.dart';
import '../../../../web/authentication/Error_page.dart';
import '../../../../web/common method/Commmon_Method.dart';
import '../../../../web/common widget/toast.dart';


// Adjust the relative import segment counts above if your actual folder
// depth differs — nothing else in this file depends on where it sits.

enum ScreenState { checkingSession, loading, empty, error, loaded }

class ViewFileGetxCont extends GetxController {
  // ---------------------------------------------------------------------
  // REACTIVE STATE (replaces the old setState()-driven fields 1:1)
  // ---------------------------------------------------------------------
  final Rx<ScreenState> screenState = ScreenState.checkingSession.obs;
  final RxString screenErrorText = "Something went wrong.".obs;
  final RxList<ProviderServiceFileModel> ProviderRegisterFileList =
      <ProviderServiceFileModel>[].obs;

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
    // Checkpoint 1 — session must be valid before anything else runs.
    final bool sessionOk = await JwtVerify(Jwt_Token: _jwtToken);
    if (!sessionOk) return; // JwtVerify already redirected to ErrorPage.

    // Checkpoint 2 — fetch the service's documents.
    await GetProviderRegisterService(Email: _email, jwttoken: _jwtToken);
  }

  Future<bool> JwtVerify({required String Jwt_Token}) async {
    int Result = await UserProviderJwtVerify(Jwt_Token: Jwt_Token);
    if (Result == 1) {
      return true;
    } else {
      await Clear_User_Data();
      await Random_token_Clear();
      // Context-free navigation via GetX (controllers don't have a
      // BuildContext), functionally equivalent to the old
      // Navigator.pushAndRemoveUntil(..., (route) => false).
      Get.offAll(() => ErrorPage());
      Toastget().Toastmsg("Session End.Relogin please.");
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // Your API call, kept exactly as tested — only the state writes now go
  // through Rx fields instead of setState().
  // -----------------------------------------------------------------------
  Future<int> GetProviderRegisterService({
    required String Email,
    required String jwttoken,
  }) async {
    if (!isClosed) screenState.value = ScreenState.loading;

    try {
      print('');
      print('================================================');
      print('GET SERVICE FILE METHOD CALLED');
      print('================================================');

      print('Email   : $Email');
      print('Service : $_serviceName');

      const String url = Backend_Server_Url + "api/Profile/getservicefileinfo";

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

      if (response.statusCode != 200) {
        print('API FAILED');
        print('Response: ${response.body}');

        if (!isClosed) {
          ProviderRegisterFileList.clear();
          screenErrorText.value =
          "Failed to load documents for \"$_serviceName\" (${response.statusCode}).";
          screenState.value = ScreenState.error;
        }
        return 0;
      }

      print('API RESPONSE SUCCESS');
      print('Response length: ${response.body.length}');

      final dynamic responseData = jsonDecode(response.body);

      if (responseData is! List) {
        print('ERROR: Response is not a List.');
        if (!isClosed) {
          screenErrorText.value = "Unexpected response format from server.";
          screenState.value = ScreenState.error;
        }
        return 0;
      }

      print('Number of files: ${responseData.length}');

      final List<ProviderServiceFileModel> loadedFiles = responseData
          .map((data) => ProviderServiceFileModel.fromJson(data))
          .toList();

      for (int i = 0; i < loadedFiles.length; i++) {
        final service = loadedFiles[i];
        print('');
        print('--------------- FILE $i ---------------');
        print('Service Name: ${service.serviceName}');
        print('Service ID: ${service.providerServiceId}');
        print('Document Path: ${service.serviceDocument}');
        print('Document length: ${service.serviceDocument?.length ?? 0}');
      }

      if (isClosed) return 0;

      ProviderRegisterFileList.value = loadedFiles;
      screenState.value =
      loadedFiles.isEmpty ? ScreenState.empty : ScreenState.loaded;

      print('');
      print('SERVICE FILE API PROCESS SUCCESS');
      print('================================================');

      return 1;
    } catch (e, stackTrace) {
      print('');
      print('================================================');
      print('SERVICE FILE API EXCEPTION');
      print('================================================');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('================================================');

      if (!isClosed) {
        ProviderRegisterFileList.clear();
        screenErrorText.value = "Network error while loading documents.";
        screenState.value = ScreenState.error;
      }
      return 0;
    }
  }

  /// The backend stores a relative path like
  /// "/uploads/service-documents/xxxx.pdf". This joins it with
  /// Backend_Server_Url safely regardless of trailing/leading slashes.
  String resolveDocumentUrl(String relativePath) {
    String base = Backend_Server_Url;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    String rel = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$base$rel';
  }
}

// ===========================================================================
// Per-card PDF viewer state (zoom / error / page count / reload key).
// The original screen kept this as local setState() inside
// _PdfDocumentViewState — moved here 1:1, one instance per visible card
// (Get.put/Get.delete with a unique tag), so multiple PDFs never share state.
// ===========================================================================
class PdfViewerCardController extends GetxController {
  final RxBool hasError = false.obs;
  final RxString errorText = "Failed to load this document.".obs;
  final RxInt totalPages = 0.obs;
  final RxDouble zoom = 1.0.obs;
  final Rx<Key> viewerKey = UniqueKey().obs;

  void retry() {
    hasError.value = false;
    viewerKey.value = UniqueKey(); // forces SfPdfViewer to reload the network URL
  }

  void reportLoaded(int pages) {
    totalPages.value = pages;
  }

  void reportFailed(String description) {
    hasError.value = true;
    errorText.value = description.isNotEmpty ? description : "Failed to load this document.";
  }

  double zoomIn() {
    zoom.value = (zoom.value + 0.25).clamp(1.0, 3.0);
    return zoom.value;
  }

  double zoomOut() {
    zoom.value = (zoom.value - 0.25).clamp(1.0, 3.0);
    return zoom.value;
  }
}