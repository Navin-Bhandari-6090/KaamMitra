import 'dart:convert';

import 'package:app/constant/Server_Database.dart';
import 'package:app/models/SharedMediaModel.dart';
import 'package:app/state management/getx/profile/provider_user/view_media_getx.dart'
    show AttachKind, MediaAttachment;
import 'package:app/web/common method/Commmon_Method.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/variable.dart';
import '../../../web/common method/date_time.dart';

class ManageMediaGetx extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool loadFailed = false.obs;
  final RxString errorText = ''.obs;
  final RxList<SharedMediaModel> sharedList = <SharedMediaModel>[].obs;
  final RxString query = ''.obs;
  final RxSet<int> deletingIds = <int>{}.obs;
  final TextEditingController searchCtrl = TextEditingController();

  String _jwtToken = '';

  void init(String jwtToken) {
    _jwtToken = jwtToken;
  }

  @override
  void onClose() {
    try {
      searchCtrl.dispose();
    } catch (_) {}
    super.onClose();
  }

  Future<void> loadAll(BuildContext context) async {
    try {
      isLoading.value = true;
      loadFailed.value = false;
      final int result =
      await Get_Shared_Media(context: context, JwtToken: _jwtToken);
      if (result != 1) {
        loadFailed.value = true;
        errorText.value = "Unable to load shared media.";
      }
    } catch (_) {
      loadFailed.value = true;
      errorText.value = "Something went wrong while loading media.";
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> deleteMedia(BuildContext context, int id) async {
    if (deletingIds.contains(id)) return;
    try {
      deletingIds.add(id);
      final int result = await Delete_Shared_Media(
        context: context,
        JwtToken: _jwtToken,
        SharedMediaId: id,
      );
      if (result == 1) {
        sharedList.removeWhere((m) => m.sharedMediaId?.toInt() == id);
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong while deleting shared media.");
    } finally {
      deletingIds.remove(id);
    }
  }

  Future<int> Get_Shared_Media({
    required BuildContext context,
    required String JwtToken,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Admin/getsharedmedia";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $JwtToken',
        },
      );

      final int statusCode = response.statusCode;
      final String responseBody = response.body.trim();

      if (statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(responseBody);
        sharedList.assignAll(
          jsonData.map((data) => SharedMediaModel.fromJson(data)).toList(),
        );
        return 1;
      } else if (statusCode == 400) {
        Toast.Toastmsg("Invalid request to retrieve shared media.");
        return 2;
      } else if (statusCode == 401) {
        Toast.Toastmsg("Invalid authentication. Please log in again.");
        await Logout(context: context);
        return 3;
      } else if (statusCode == 500) {
        Toast.Toastmsg("Something went wrong while retrieving shared media.");
        return 6;
      } else if (statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by System. Contact the KaamMitra community.",
        );
        await Logout(context: context);
        return 7;
      } else if (statusCode == 520) {
        Toast.Toastmsg("User account not found.");
        await Logout(context: context);
        return 8;
      } else {
        Toast.Toastmsg("Unable to retrieve shared media. Please try again.");
        return 9;
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong while retrieving shared media.");
      return 10;
    }
  }

  Future<int> Delete_Shared_Media({
    required BuildContext context,
    required String JwtToken,
    required int SharedMediaId,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Admin/deletesharedmedia";

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $JwtToken',
        },
        body: jsonEncode({
          "SharedMediaId": SharedMediaId,
        }),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        Toast.Toastmsg("Shared media deleted successfully.");
        return 1;
      } else if (statusCode == 400) {
        Toast.Toastmsg("Invalid shared media information format.");
        return 2;
      } else if (statusCode == 401) {
        Toast.Toastmsg("Invalid authentication. Please log in again.");
        await Logout(context: context);
        return 3;
      } else if (statusCode == 403) {
        Toast.Toastmsg("You are not authorized to delete this shared media.");
        return 4;
      } else if (statusCode == 404) {
        Toast.Toastmsg("Shared media not found.");
        return 5;
      } else if (statusCode == 500) {
        Toast.Toastmsg("Server error occurred while deleting shared media.");
        return 6;
      } else if (statusCode == 506) {
        Toast.Toastmsg(
          "You have been blocked by System. Contact the KaamMitra community.",
        );
        await Logout(context: context);
        return 7;
      } else if (statusCode == 520) {
        Toast.Toastmsg("User account not found.");
        await Logout(context: context);
        return 8;
      } else {
        Toast.Toastmsg("Unable to delete shared media. Please try again.");
        return 9;
      }
    } catch (_) {
      Toast.Toastmsg("Something went wrong while deleting shared media.");
      return 10;
    }
  }

  // ==================================================================
  // HELPERS (null-safe, empty values show "No data available")
  // ==================================================================
  String _clean(String? v) {
    final String t = (v ?? '').trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t;
  }

  String displayOr(String? v) {
    final String t = _clean(v);
    return t.isEmpty ? 'No data available' : t;
  }

  String numText(num? n) => n == null ? '' : n.toInt().toString();

  String idOf(SharedMediaModel m) => numText(m.sharedMediaId);

  String descOf(SharedMediaModel m) => _clean(m.mediaDescription);

  String formatDate(String? raw) {
    try {
      final String s = _clean(raw);
      if (s.isEmpty) return 'No data available';
      final String formatted = formatDateTime(s);
      return formatted.isEmpty ? 'No data available' : formatted;
    } catch (_) {
      return 'No data available';
    }
  }

  String resolveUrl(String relativePath) {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    final String base = Backend_Server_Url.replaceFirst(RegExp(r'/$'), '');
    final String rel =
    relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$base$rel';
  }

  String urlOf(MediaAttachment a) => resolveUrl(a.path);

  List<MediaAttachment> attachmentsOf(SharedMediaModel m) {
    final List<MediaAttachment> list = [];
    try {
      final String photo = _clean(m.servicePhoto);
      final String video = _clean(m.serviceVideo);
      final String file = _clean(m.serviceFile);
      if (photo.isNotEmpty) list.add(MediaAttachment(AttachKind.photo, photo));
      if (video.isNotEmpty) list.add(MediaAttachment(AttachKind.video, video));
      if (file.isNotEmpty) list.add(MediaAttachment(AttachKind.file, file));
    } catch (_) {}
    return list;
  }

  int countOf(AttachKind kind) {
    try {
      return sharedList
          .where((m) => attachmentsOf(m).any((a) => a.kind == kind))
          .length;
    } catch (_) {
      return 0;
    }
  }

  // ==================================================================
  // SEARCH: media ID, or every typed word found in the full description
  // ==================================================================
  List<SharedMediaModel> get filteredList {
    try {
      final String q = query.value.trim().toLowerCase();
      final List<SharedMediaModel> all = sharedList.toList();
      if (q.isEmpty) return all;

      final List<String> words =
      q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

      return all.where((m) {
        if (idOf(m).toLowerCase().contains(q)) return true;
        final String desc = descOf(m).toLowerCase();
        return words.isNotEmpty && words.every((w) => desc.contains(w));
      }).toList();
    } catch (_) {
      return const <SharedMediaModel>[];
    }
  }
}