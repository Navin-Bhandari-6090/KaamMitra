import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

// Adjust the relative import segment counts if your folder depth differs.
import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/ProRegServResourcesModel.dart';
import '../../../models/Service_Screen_Service_Model.dart';
import '../../../web/common method/Commmon_Method.dart';

// =============================================================================
// One displayable thing (document / photo / video) belonging to a service.
// =============================================================================
enum MediaKind { file, photo, video }

class ServiceMediaItem {
  final MediaKind kind;
  final String path;
  final String label;
  const ServiceMediaItem({
    required this.kind,
    required this.path,
    required this.label,
  });
}

// =============================================================================
// CONTROLLER — same three API methods as the original screen (logic kept),
// only the state writes now go through Rx fields instead of plain lists.
// =============================================================================
class ShowServResInfoGetx extends GetxController {
  // ---------------- reactive state ----------------
  final RxList<ServiceScreenServiceModel> services =
      <ServiceScreenServiceModel>[].obs;
  final RxList<ProRegServResourcesModel> resources =
      <ProRegServResourcesModel>[].obs;

  final RxBool isLoading = true.obs;
  final RxSet<int> deletingIds = <int>{}.obs;
  final RxString searchQuery = ''.obs;

  /// serviceId -> index of the item currently shown (Next / Previous).
  final RxMap<int, int> mediaIndex = <int, int>{}.obs;

  final TextEditingController serviceIdTextCont = TextEditingController();
  final TextEditingController searchTextCont = TextEditingController();

  late String _jwtToken;
  late String _email;

  /// Call once from the screen's initState, right after Get.put(...).
  Future<void> init({required String jwtToken, required String email}) async {
    _jwtToken = jwtToken;
    _email = email;
    await loadAll();
  }

  @override
  void onClose() {
    serviceIdTextCont.dispose();
    searchTextCont.dispose();
    super.onClose();
  }

  /// Services first, then resources (the services call clears the resource
  /// list on success, exactly like the original, so order matters).
  Future<void> loadAll() async {
    isLoading.value = true;
    await GetAllProviderServices();
    await GetAllProviderServiceResources();
    if (!isClosed) isLoading.value = false;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  int idOf(ServiceScreenServiceModel s) => (s.providerServiceId ?? -1).toInt();

  List<ServiceScreenServiceModel> get filteredServices {
    final String q = searchQuery.value.trim();
    if (q.isEmpty) return services.toList();
    return services.where((s) => idOf(s).toString().contains(q)).toList();
  }

  /// Order shown one by one: document first, then each resource's photo/video.

  List<ServiceMediaItem> mediaFor(ServiceScreenServiceModel s) {
    final int id = idOf(s);
    final List<ServiceMediaItem> items = [];

    // =========================================================
    // 1. SERVICE DOCUMENT
    // =========================================================

    final String? doc = s.serviceDocument;

    if (doc != null && doc.trim().isNotEmpty) {
      items.add(
        ServiceMediaItem(
          kind: MediaKind.file,
          path: doc,
          label: 'Document',
        ),
      );
    }

    // =========================================================
    // 2. ALL PHOTOS
    // =========================================================

    for (final r in resources) {
      if ((r.providerServiceId ?? -2).toInt() != id) {
        continue;
      }

      final String rid =
          '${r.providerServiceResourcesId ?? '-'}';

      final String? photo = r.servicePhoto;

      if (photo != null && photo.trim().isNotEmpty) {
        items.add(
          ServiceMediaItem(
            kind: MediaKind.photo,
            path: photo,
            label: 'Photo · Resource $rid',
          ),
        );
      }
    }

    // =========================================================
    // 3. ALL VIDEOS
    // =========================================================

    for (final r in resources) {
      if ((r.providerServiceId ?? -2).toInt() != id) {
        continue;
      }

      final String rid =
          '${r.providerServiceResourcesId ?? '-'}';

      final String? video = r.serviceVideo;

      if (video != null && video.trim().isNotEmpty) {
        items.add(
          ServiceMediaItem(
            kind: MediaKind.video,
            path: video,
            label: 'Video · Resource $rid',
          ),
        );
      }
    }

    // =========================================================
    // DEBUG
    // =========================================================

    // print("========== MEDIA FOR SERVICE $id ==========");
    //
    // for (int i = 0; i < items.length; i++) {
    //   print(
    //     "Media $i | "
    //         "Kind: ${items[i].kind} | "
    //         "Path: ${items[i].path} | "
    //         "Label: ${items[i].label}",
    //   );
    // }
    //
    // print("Total Media: ${items.length}");

    return items;
  }

  int indexFor(int id, int total) {
    if (total <= 0) return 0;
    final int i = mediaIndex[id] ?? 0;
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
    searchTextCont.clear();
    searchQuery.value = '';
  }

  /// Same slash-safe joining as GetPhotoUrl.
  String buildUrl(String? photoPath) {
    try {
      if (photoPath == null || photoPath.trim().isEmpty) return "";

      final String baseUrl = Backend_Server_Url.endsWith("/")
          ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
          : Backend_Server_Url;

      final String path = photoPath.trim().startsWith("/")
          ? photoPath.trim()
          : "/${photoPath.trim()}";

      return "$baseUrl$path";
    } catch (obj) {
      print("Exception while creating photo URL.");
      print(obj.toString());
      return "";
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  /// From the "Delete by Service ID" panel (original button logic).
  Future<void> deleteFromInput() async {
    try {
      if (serviceIdTextCont.text.trim().isEmptyOrNull) {
        Toast.Toastmsg("Service id is required.");
        return;
      }
      int serviceId = int.tryParse(serviceIdTextCont.text.trim())!;
      await deleteServiceById(serviceId);
    } catch (obj) {
      print(obj.toString());
      return;
    }
  }

  /// Used by both the top panel and every service card.
  /// On 200 the service and its resources vanish from the UI instantly.
  Future<void> deleteServiceById(int id) async {
    if (deletingIds.contains(id)) return;
    deletingIds.add(id);

    final int result = await DelProService(
      User_JwtToken: _jwtToken,
      ProviderServiceId: id,
      Email: _email,
    );

    deletingIds.remove(id);

    if (result == 200) {
      services.removeWhere((s) => idOf(s) == id);
      resources.removeWhere((r) => (r.providerServiceId ?? -2).toInt() == id);
      mediaIndex.remove(id);
      if (serviceIdTextCont.text.trim() == id.toString()) {
        serviceIdTextCont.clear();
      }
    }
  }

  // ===========================================================================
  // ORIGINAL API METHODS — logic unchanged
  // ===========================================================================
  Future<int> DelProService({
    required String User_JwtToken,
    required String Email,
    required int ProviderServiceId,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Admin/deleteservice";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "*/*",
          "Authorization": "Bearer $User_JwtToken",
        },
        body: jsonEncode({
          "ProviderServiceId": ProviderServiceId,
          "Email": Email,
        }),
      );

      if (response.statusCode == 200) {
        Toast.Toastmsg("Service deleted successfully.");
        return 200;
      } else if (response.statusCode == 400) {
        Toast.Toastmsg(response.body.isNotEmpty
            ? response.body
            : "Invalid service information.");
        return 400;
      } else if (response.statusCode == 404) {
        Toast.Toastmsg(
            response.body.isNotEmpty ? response.body : "Service not found.");
        return 404;
      } else if (response.statusCode == 401) {
        Toast.Toastmsg("Unauthorized. Please login again.");
        return 401;
      } else if (response.statusCode == 403) {
        Toast.Toastmsg("You are not authorized to delete this service.");
        return 403;
      } else {
        Toast.Toastmsg("Something went wrong. Status: ${response.statusCode}");
        return response.statusCode;
      }
    } catch (obj) {
      print("Delete Service Error: $obj");
      Toast.Toastmsg("Something went wrong.");
      return 500;
    }
  }

  /// Get all provider services
  Future<void> GetAllProviderServices() async {
    try {
      services.clear();

      const String url = Backend_Server_Url + "api/Admin/getallproviderservices";
      print("========== GET ALL PROVIDER SERVICES ==========");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_jwtToken",
        },
      );


      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        resources.clear();

        services.assignAll(responseData
            .map((json) => ServiceScreenServiceModel.fromJson(json))
            .toList());

        print("Provider Services Count: ${services.length}");
      } else if (response.statusCode == 400) {
        services.clear();
        Toast.Toastmsg("Invalid request data.");
      } else if (response.statusCode == 401) {
        services.clear();
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        services.clear();
        Toast.Toastmsg("You are not authorized to access provider services.");
      } else if (response.statusCode == 404) {
        services.clear();
        Toast.Toastmsg("No registered provider services are available.");
      } else if (response.statusCode == 500) {
        services.clear();
        Toast.Toastmsg("Something went wrong while getting provider services.");
      } else {
        services.clear();
        Toast.Toastmsg("Something went wrong.");
      }
    } catch (e, stackTrace) {
      print("========== GET ALL PROVIDER SERVICES ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");
      services.clear();
      Toast.Toastmsg("Something went wrong.");
    }
  }

  /// Get all provider service resources
  Future<void> GetAllProviderServiceResources() async {
    try {
      resources.clear();

      const String url =
          Backend_Server_Url + "api/Admin/getallproviderserviceresources";
      print("========== GET ALL PROVIDER SERVICE RESOURCES ==========");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_jwtToken",
        },
      );



      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        resources.assignAll(responseData
            .map((json) => ProRegServResourcesModel.fromJson(json))
            .toList());

        print("Provider Service Resources Count: ${resources.length}");
      } else if (response.statusCode == 400) {
        resources.clear();
        Toast.Toastmsg("Invalid request data.");
      } else if (response.statusCode == 401) {
        resources.clear();
        Toast.Toastmsg("Your session has expired. Please login again.");
      } else if (response.statusCode == 403) {
        resources.clear();
        Toast.Toastmsg("You are not authorized to access provider resources.");
      } else if (response.statusCode == 404) {
        resources.clear();
        Toast.Toastmsg("No provider service resources are available.");
      } else if (response.statusCode == 500) {
        resources.clear();
        Toast.Toastmsg("Something went wrong while getting provider resources.");
      } else {
        resources.clear();
        Toast.Toastmsg("Something went wrong.");
      }
    } catch (e, stackTrace) {
      print("========== GET ALL PROVIDER SERVICE RESOURCES ERROR ==========");
      print("Error: $e");
      print("StackTrace: $stackTrace");
      resources.clear();
      Toast.Toastmsg("Something went wrong.");
    }
  }
}