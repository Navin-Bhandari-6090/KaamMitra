import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:velocity_x/velocity_x.dart';

import '../../../constant/Server_Database.dart';
import '../../../constant/variable.dart';
import '../../../models/ProRegServResourcesModel.dart';
import '../../../models/ServiceScreenServiceModel.dart';

enum MediaKind { serviceDocument, resourceFile, photo, video }

class ServiceMediaItem {
  final MediaKind kind;
  final String path;
  final String title;
  final int serviceId;
  final int? resourceId;

  const ServiceMediaItem({
    required this.kind,
    required this.path,
    required this.title,
    required this.serviceId,
    this.resourceId,
  });

  String get kindLabel {
    switch (kind) {
      case MediaKind.serviceDocument:
        return 'Service document';
      case MediaKind.resourceFile:
        return 'Resource file';
      case MediaKind.photo:
        return 'Photo';
      case MediaKind.video:
        return 'Video';
    }
  }
}

bool isPdfPath(String path) {
  final String clean = path.split('?').first.toLowerCase();
  final int dot = clean.lastIndexOf('.');
  final int slash = clean.lastIndexOf('/');
  if (dot < 0 || dot < slash) return true;
  return clean.substring(dot) == '.pdf';
}

bool _hasText(String? v) => v != null && v.trim().isNotEmpty;

class ShowServResInfoGetx extends GetxController {
  final RxList<ServiceScreenServiceModel> services =
      <ServiceScreenServiceModel>[].obs;
  final RxList<ProRegServResourcesModel> resources =
      <ProRegServResourcesModel>[].obs;

  final RxBool isLoading = true.obs;
  final RxSet<int> deletingIds = <int>{}.obs;
  final RxString searchQuery = ''.obs;

  final RxMap<int, int> mediaIndex = <int, int>{}.obs;

  final TextEditingController serviceIdTextCont = TextEditingController();
  final TextEditingController searchTextCont = TextEditingController();

  late String _jwtToken;
  late String _email;

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

  Future<void> loadAll() async {
    isLoading.value = true;
    await GetAllProviderServices();
    await GetAllProviderServiceResources();
    if (!isClosed) isLoading.value = false;
  }

  int idOf(ServiceScreenServiceModel s) => (s.providerServiceId ?? -1).toInt();

  int _serviceIdOfResource(ProRegServResourcesModel r) =>
      (r.providerServiceId ?? -2).toInt();

  String _titleOf(ProRegServResourcesModel r) {
    final String? t = r.serviceTitle?.trim();
    return _hasText(t) ? t! : 'Untitled resource';
  }

  ServiceMediaItem _resourceItem(
      MediaKind kind,
      String path,
      ProRegServResourcesModel r,
      int serviceId,
      ) {
    return ServiceMediaItem(
      kind: kind,
      path: path.trim(),
      title: _titleOf(r),
      serviceId: serviceId,
      resourceId: r.providerServiceResourcesId?.toInt(),
    );
  }

  List<ServiceScreenServiceModel> get filteredServices {
    final String q = searchQuery.value.trim();
    if (q.isEmpty) return services.toList();
    return services.where((s) => idOf(s).toString().contains(q)).toList();
  }

  int resourceCountFor(ServiceScreenServiceModel s) {
    final int id = idOf(s);
    return resources.where((r) => _serviceIdOfResource(r) == id).length;
  }

  List<ServiceMediaItem> mediaFor(ServiceScreenServiceModel s) {
    final int id = idOf(s);
    final List<ServiceMediaItem> items = [];
    final List<ProRegServResourcesModel> related =
    resources.where((r) => _serviceIdOfResource(r) == id).toList();

    final String? doc = s.serviceDocument;
    if (_hasText(doc)) {
      items.add(ServiceMediaItem(
        kind: MediaKind.serviceDocument,
        path: doc!.trim(),
        title: 'Service document',
        serviceId: id,
      ));
    }

    for (final r in related) {
      final String? file = r.serviceFile;
      if (_hasText(file)) {
        items.add(_resourceItem(MediaKind.resourceFile, file!, r, id));
      }
    }

    for (final r in related) {
      final String? photo = r.servicePhoto;
      if (_hasText(photo)) {
        items.add(_resourceItem(MediaKind.photo, photo!, r, id));
      }
    }

    for (final r in related) {
      final String? video = r.serviceVideo;
      if (_hasText(video)) {
        items.add(_resourceItem(MediaKind.video, video!, r, id));
      }
    }

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

  String buildUrl(String? photoPath) {
    try {
      if (photoPath == null || photoPath.trim().isEmpty) return "";
      final String p = photoPath.trim();
      if (p.startsWith("http://") || p.startsWith("https://")) return p;

      final String baseUrl = Backend_Server_Url.endsWith("/")
          ? Backend_Server_Url.substring(0, Backend_Server_Url.length - 1)
          : Backend_Server_Url;

      final String path = p.startsWith("/") ? p : "/$p";
      return "$baseUrl$path";
    } catch (_) {
      return "";
    }
  }

  Future<void> deleteFromInput() async {
    try {
      final String raw = serviceIdTextCont.text.trim();
      if (raw.isEmptyOrNull) {
        Toast.Toastmsg("Service id is required.");
        return;
      }
      final int? serviceId = int.tryParse(raw);
      if (serviceId == null) {
        Toast.Toastmsg("Enter a valid service id.");
        return;
      }
      await deleteServiceById(serviceId);
    } catch (_) {
      return;
    }
  }

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
      resources.removeWhere((r) => _serviceIdOfResource(r) == id);
      mediaIndex.remove(id);
      if (serviceIdTextCont.text.trim() == id.toString()) {
        serviceIdTextCont.clear();
      }
    }
  }

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
    } catch (_) {
      Toast.Toastmsg("Something went wrong.");
      return 500;
    }
  }

  Future<void> GetAllProviderServices() async {
    try {
      services.clear();

      const String url = Backend_Server_Url + "api/Admin/getallproviderservices";

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
    } catch (_) {
      services.clear();
      Toast.Toastmsg("Something went wrong.");
    }
  }

  Future<void> GetAllProviderServiceResources() async {
    try {
      resources.clear();

      const String url =
          Backend_Server_Url + "api/Admin/getallproviderserviceresources";

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
    } catch (_) {
      resources.clear();
      Toast.Toastmsg("Something went wrong.");
    }
  }
}