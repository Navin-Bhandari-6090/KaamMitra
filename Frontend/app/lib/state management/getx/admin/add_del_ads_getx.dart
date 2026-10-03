import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/AdvertisementInfoModel.dart';
import '../../../web/common method/Commmon_Method.dart';

// =============================================================================
// One displayable thing (photo / video) belonging to an advertisement.
// =============================================================================
enum AdMediaKind { photo, video }

class AdMediaItem {
  final AdMediaKind kind;
  final String path;
  final String label;
  const AdMediaItem({
    required this.kind,
    required this.path,
    required this.label,
  });
}

// =============================================================================
// CONTROLLER — all state lives here (no setState anywhere).
// API method bodies are the original logic, moved from the screen.
// =============================================================================
class AddDelAdsGetx extends GetxController {
  // ---------------- text controllers ----------------
  final TextEditingController titleCont = TextEditingController();
  final TextEditingController urlCont = TextEditingController();
  final TextEditingController adIdCont = TextEditingController();
  final TextEditingController searchCont = TextEditingController();

  // ---------------- reactive UI state ----------------
  final RxBool titleFocused = false.obs;
  final RxBool urlFocused = false.obs;
  final RxBool adIdFocused = false.obs;

  final RxBool isAddingAd = false.obs;
  final RxBool isDeletingAd = false.obs;
  final RxBool isLoading = true.obs;

  final RxList<AdvertisementInfoModel> ads = <AdvertisementInfoModel>[].obs;
  final RxSet<int> deletingIds = <int>{}.obs;
  final RxString searchQuery = ''.obs;

  /// advertisementId -> index of the media currently shown (Next / Previous).
  final RxMap<int, int> mediaIndex = <int, int>{}.obs;

  String _jwt = '';

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({required String jwtToken}) async {
    _jwt = jwtToken;
    await loadAll();
  }

  @override
  void onClose() {
    titleCont.dispose();
    urlCont.dispose();
    adIdCont.dispose();
    searchCont.dispose();
    clearPicked();
    super.onClose();
  }

  Future<void> loadAll() async
  {
    try {
      isLoading.value = true;
      await GetAllAdvertisementInfos();
    } catch (obj) {
      print(obj.toString());
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void clearPicked() {
    try {
      change_video_cont_getx.videoExtension.value = "";
      change_video_cont_getx.videoBytes.value = null;
      change_video_cont_getx.videoPath.value = "";
      change_photo_cont_getx.imageExtension.value = "";
      change_photo_cont_getx.imageBytes.value = null;
      change_photo_cont_getx.imagePath.value = "";
    } catch (obj) {
      print(obj.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS (null-safe: only id + title are guaranteed, the rest may be empty)
  // ---------------------------------------------------------------------------
  int idOf(AdvertisementInfoModel a) => (a.advertisementId ?? -1).toInt();

  String titleOf(AdvertisementInfoModel a) {
    final String t = (a.tittle ?? '').trim();
    return t.isEmpty ? 'Untitled advertisement' : t;
  }

  String linkOf(AdvertisementInfoModel a) => (a.urlLink ?? '').trim();

  DateTime? dateOf(AdvertisementInfoModel a) {
    try {
      final String s = (a.uploadedAt ?? '').trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  String dateLabel(AdvertisementInfoModel a) {
    try {
      final DateTime? d = dateOf(a)?.toLocal();
      if (d == null) {
        final String raw = (a.uploadedAt ?? '').trim();
        return raw.isEmpty ? 'Date unavailable' : raw;
      }
      const m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final int h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final String mm = d.minute.toString().padLeft(2, '0');
      final String ap = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day} ${m[d.month - 1]} ${d.year}, $h12:$mm $ap';
    } catch (_) {
      return 'Date unavailable';
    }
  }

  /// Search by advertisement id + newest first (falls back to id when a date
  /// is missing, since ids grow over time).
  List<AdvertisementInfoModel> get filteredAds {
    final String q = searchQuery.value.trim();
    final List<AdvertisementInfoModel> list = q.isEmpty
        ? ads.toList()
        : ads.where((a) => idOf(a).toString().contains(q)).toList();

    list.sort((a, b) {
      final DateTime? da = dateOf(a);
      final DateTime? db = dateOf(b);
      if (da != null && db != null) {
        final int c = db.compareTo(da);
        if (c != 0) return c;
      } else if (da != null) {
        return -1;
      } else if (db != null) {
        return 1;
      }
      return idOf(b).compareTo(idOf(a));
    });
    return list;
  }

  List<AdMediaItem> mediaFor(AdvertisementInfoModel a) {
    final List<AdMediaItem> items = [];
    final String? photo = a.photo;
    final String? video = a.video;
    if (photo != null && photo.trim().isNotEmpty) {
      items.add(AdMediaItem(
          kind: AdMediaKind.photo, path: photo, label: 'Photo'));
    }
    if (video != null && video.trim().isNotEmpty) {
      items.add(AdMediaItem(
          kind: AdMediaKind.video, path: video, label: 'Video'));
    }
    return items;
  }

  int indexFor(int id, int total) {
    final int i = mediaIndex[id] ?? 0; // read first so Obx always subscribes
    if (total <= 0) return 0;
    return i.clamp(0, total - 1);
  }

  void next(int id, int total) {
    if (total <= 1) return;
    mediaIndex[id] = (indexFor(id, total) + 1) % total;
  }

  void previous(int id, int total) {
    if (total <= 1) return;
    mediaIndex[id] = (indexFor(id, total) - 1 + total) % total;
  }

  void clearSearch() {
    searchCont.clear();
    searchQuery.value = '';
  }

  /// Slash-safe URL joining.
  String buildUrl(String? path) {
    try {
      if (path == null || path.trim().isEmpty) return "";
      final String baseUrl = Backend_Server_Url.endsWith("/")
          ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
          : Backend_Server_Url;
      final String p = path.trim().startsWith("/") ? path.trim() : "/${path.trim()}";
      return "$baseUrl$p";
    } catch (obj) {
      print(obj.toString());
      return "";
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIONS used by the screen
  // ---------------------------------------------------------------------------
  Future<void> submitAdd() async {
    if (isAddingAd.value) return;
    isAddingAd.value = true;
    try {
      final int result = await AddAdvertisement(
        Photo: change_photo_cont_getx.imageBytes.value,
        Video: change_video_cont_getx.videoBytes.value,
        Tittle: titleCont.text.trim(),
        UrlLink: urlCont.text.trim(),
        PhotoExtension: change_photo_cont_getx.imageExtension.value,
        VideoExtension: change_video_cont_getx.videoExtension.value,
      );
      if (result == 1) {
        titleCont.clear();
        urlCont.clear();
        clearPicked();
        await GetAllAdvertisementInfos();
      }
    } catch (obj) {
      print(obj.toString());
    } finally {
      isAddingAd.value = false;
    }
  }

  /// From the "Delete by ID" panel.
  Future<void> deleteFromInput() async {
    try {
      if (adIdCont.text.trim().isEmpty) {
        Toast.Toastmsg("Advertisement id is mandatory.");
        return;
      }
      final int? id = int.tryParse(adIdCont.text.trim());
      if (id == null) {
        Toast.Toastmsg("Advertisement id must be a number.");
        return;
      }
      await deleteAdById(id);
    } catch (obj) {
      print(obj.toString());
    }
  }

  /// Used by the panel and every card. On 200 the ad vanishes instantly.
  Future<void> deleteAdById(int id) async {
    if (deletingIds.contains(id)) return;
    deletingIds.add(id);
    isDeletingAd.value = true;
    try {
      final int result = await DeleteAdvertisement(
        User_JwtToken: _jwt,
        AdvertisementId: id.toString(),
      );
      if (result == 200) {
        ads.removeWhere((a) => idOf(a) == id);
        mediaIndex.remove(id);
        if (adIdCont.text.trim() == id.toString()) adIdCont.clear();
      }
    } catch (obj) {
      print(obj.toString());
    } finally {
      deletingIds.remove(id);
      isDeletingAd.value = deletingIds.isNotEmpty;
    }
  }

  // ===========================================================================
  // ORIGINAL API METHODS — logic unchanged
  // ===========================================================================
  Future<int> DeleteAdvertisement({
    required String User_JwtToken,
    required String AdvertisementId,
  }) async {
    try {
      print("========== DELETE ADVERTISEMENT ==========");
      print("AdvertisementId: $AdvertisementId");

      final Map<String, dynamic> data = {
        "AdvertisementId": int.parse(AdvertisementId),
      };

      final response = await http.delete(
        Uri.parse("${Backend_Server_Url}api/Admin/deleteadvertisement"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $User_JwtToken",
        },
        body: jsonEncode(data),
      );

      print("Delete Advertisement Status Code: ${response.statusCode}");
      print("Delete Advertisement Response: ${response.body}");

      if (response.statusCode == 200) {
        Toast.Toastmsg("Advertisement deleted successfully.");
        return 200;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg("Invalid advertisement data.");
        return 400;
      } else if (response.statusCode == 404) {
        Toast.Toastmsg("Advertisement not found.");
        return 404;
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Unauthorized.");
        return 401;
      } else if (response.statusCode == 403) {
        Toast.Toastmsg("Admin permission required.");
        return 403;
      } else {
        Toast.Toastmsg("Failed to delete advertisement.");
        return response.statusCode;
      }
    } catch (obj) {
      print("========== DELETE ADVERTISEMENT ERROR ==========");
      print("Exception: $obj");
      Toast.Toastmsg("Something went wrong.");
      return 500;
    }
  }

  Future<int> AddAdvertisement({
    required List<int>? Photo,
    required List<int>? Video,
    required String Tittle,
    required String? UrlLink,
    required String? PhotoExtension,
    required String? VideoExtension,
  }) async {
    try {
      print("========== ADD ADVERTISEMENT ==========");

      // 1. Validate Tittle
      if (Tittle.trim().isEmpty) {
        Toast.Toastmsg("Advertisement title is required.");
        return 1;
      }

      const String url = Backend_Server_Url + "api/Admin/addadvertisement";
      print("Advertisement API URL: $url");

      final request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers["Authorization"] = "Bearer $_jwt";
      request.fields["Tittle"] = Tittle.trim();

      // Optional URL
      if (UrlLink != null && UrlLink.trim().isNotEmpty) {
        request.fields["UrlLink"] = UrlLink.trim();
      }

      // Optional Photo
      if (Photo != null && Photo.isNotEmpty) {
        final String extension =
        (PhotoExtension ?? "").trim().toLowerCase().replaceFirst(".", "");
        if (extension.isEmpty) {
          Toast.Toastmsg("Photo extension is required when photo is selected.");
          return 2;
        }
        request.files.add(http.MultipartFile.fromBytes(
          "Photo",
          Photo,
          filename: "advertisement_photo.$extension",
        ));
        print("Photo size: ${(Photo.length / (1024 * 1024)).toStringAsFixed(2)} MB");
      }

      // Optional Video
      if (Video != null && Video.isNotEmpty) {
        final String extension =
        (VideoExtension ?? "").trim().toLowerCase().replaceFirst(".", "");
        if (extension.isEmpty) {
          Toast.Toastmsg("Video extension is required when video is selected.");
          return 3;
        }
        request.files.add(http.MultipartFile.fromBytes(
          "Video",
          Video,
          filename: "advertisement_video.$extension",
        ));
        print("Video size: ${(Video.length / (1024 * 1024)).toStringAsFixed(2)} MB");
      }

      print("Uploading advertisement...");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        Toast.Toastmsg("Advertisement added successfully.");
        return 1;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg(response.body);
        return 4;
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Unauthorized. Please login again.");
        return 5;
      } else if (response.statusCode == 403) {
        Toast.Toastmsg("You are not authorized.");
        return 6;
      } else if (response.statusCode == 404) {
        Toast.Toastmsg(response.body);
        return 7;
      } else if (response.statusCode == 500) {
        Toast.Toastmsg("Server error while adding advertisement.");
        return 8;
      } else {
        Toast.Toastmsg("Add advertisement failed.");
        return 9;
      }
    } catch (E) {
      print("Exception while adding advertisement: ${E.toString()}");
      Toast.Toastmsg("Server error try again");
      return 0;
    }
  }

  /// Get all advertisement infos (same status handling as before).
  Future<void> GetAllAdvertisementInfos() async {
    try {
      ads.clear();

      const String url = Backend_Server_Url + "api/Admin/getalladvertisementinfos";
      print("========== GET ALL ADVERTISEMENT INFOS ==========");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_jwt",
        },
      );

      print("Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        ads.assignAll(responseData
            .map((json) => AdvertisementInfoModel.fromJson(json))
            .toList());
        print("Advertisement Info Count: ${ads.length}");
      } else if (response.statusCode == 400) {
        ads.clear();
        Toast.Toastmsg("Data are not in correct format.");
      } else if (response.statusCode == 401) {
        ads.clear();
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        ads.clear();
        Toast.Toastmsg("You are not authorized to access advertisement information.");
      } else if (response.statusCode == 404) {
        ads.clear();
        Toast.Toastmsg("No advertisement information is present.");
      } else if (response.statusCode == 506) {
        ads.clear();
        Toast.Toastmsg("You have been blocked by System. Contact KaamMitra community.");
      } else if (response.statusCode == 500) {
        ads.clear();
        Toast.Toastmsg("Something went wrong while getting advertisement information.");
      } else {
        ads.clear();
        Toast.Toastmsg("Something went wrong.");
      }
    } catch (e, stackTrace) {
      print("========== GET ALL ADVERTISEMENT INFOS ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");
      ads.clear();
      Toast.Toastmsg("Something went wrong.");
    }
  }
}