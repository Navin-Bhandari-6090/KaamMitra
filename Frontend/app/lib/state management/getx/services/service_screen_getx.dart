import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constant/Server_Database.dart';
import '../../../models/RatingInfoModel.dart';
import '../../../models/ServiceScreenServiceModel.dart';
import '../../../models/ServiceScreenUserInfoModel.dart';
import '../../../web/common method/Commmon_Method.dart';
import '../../../web/common widget/toast.dart';

/// Text shown whenever a database value is null, empty, or "null".
const String kNoData = "No data available";

/// Returns the trimmed value, or [kNoData] when it is null, empty, or "null".
String textOrNoData(String? value) {
  final String t = (value ?? "").trim();
  if (t.isEmpty || t.toLowerCase() == "null") return kNoData;
  return t;
}

enum ServiceSortMode { distance, rating }

class CombinedServiceCard {
  final ServiceScreenServiceModel service;
  final ServiceScreenUserInfoModel? provider;
  final double rating;
  final double distanceKm;
  final bool hasLocation;

  CombinedServiceCard({
    required this.service,
    required this.provider,
    required this.rating,
    required this.distanceKm,
    required this.hasLocation,
  });
}

class ServiceScreenGetx extends GetxController {
  // ============================================================
  // Raw API data
  // ============================================================

  final List<RatingInfoModel> ratingInfoList = [];
  final List<ServiceScreenServiceModel> serviceInfoList = [];
  final List<ServiceScreenUserInfoModel> providerInfoList = [];

  // ============================================================
  // Loading / error state
  // ============================================================

  RxBool isLoading = false.obs;
  RxBool hasLoadError = false.obs;

  void setLoading(bool value) => isLoading.value = value;
  void setLoadError(bool value) => hasLoadError.value = value;

  // ============================================================
  // Cards
  // ============================================================

  final RxList<CombinedServiceCard> allCards = <CombinedServiceCard>[].obs;
  final RxList<CombinedServiceCard> displayedCards =
      <CombinedServiceCard>[].obs;

  // ============================================================
  // Search + sort
  // ============================================================

  RxString searchText = "".obs;
  Rx<ServiceSortMode> sortMode = ServiceSortMode.distance.obs;

  void changeSearchText(String value) {
    try {
      searchText.value = value;
      _applyFilterSort();
    } catch (e) {
      debugPrint("changeSearchText failed: $e");
    }
  }

  void changeSortMode(ServiceSortMode mode) {
    try {
      if (sortMode.value == mode) return;
      sortMode.value = mode;
      _applyFilterSort();
    } catch (e) {
      debugPrint("changeSortMode failed: $e");
    }
  }

  // ============================================================
  // UI interaction state
  // ============================================================

  RxBool isSearchFocused = false.obs;
  RxInt hoveredCardIndex = (-1).obs;
  RxInt pressedCardIndex = (-1).obs;

  void setSearchFocused(bool value) => isSearchFocused.value = value;
  void setHoveredCard(int index) => hoveredCardIndex.value = index;
  void clearHoveredCard() => hoveredCardIndex.value = -1;
  void setPressedCard(int index) => pressedCardIndex.value = index;
  void clearPressedCard() => pressedCardIndex.value = -1;

  // ============================================================
  // LOAD ORCHESTRATION — the screen calls only this
  // ============================================================

  Future<void> loadEverything({
    required String email,
    required String jwtToken,
    required BuildContext context,
  }) async {
    setLoading(true);
    setLoadError(false);

    try {
      final results = await Future.wait([
        getServiceInfo(email: email, jwtToken: jwtToken, context: context),
        getProviderInfo(email: email, jwtToken: jwtToken, context: context),
        getRatingInfo(email: email, jwtToken: jwtToken, context: context),
      ]);

      final bool anyFailed = results.any((r) => r != 1);

      double currentLat = 0.0;
      double currentLong = 0.0;
      bool locationKnown = false;

      for (final p in providerInfoList) {
        if (p.email == email) {
          currentLat = asDouble(p.latitude);
          currentLong = asDouble(p.longitude);
          locationKnown = true;
          break;
        }
      }

      buildCombinedList(
        services: serviceInfoList,
        providers: providerInfoList,
        ratings: ratingInfoList,
        currentUserLat: currentLat,
        currentUserLong: currentLong,
        currentUserLocationKnown: locationKnown,
      );

      setLoadError(anyFailed && serviceInfoList.isEmpty);
    } catch (e) {
      debugPrint("Load services failed: $e");
      setLoadError(true);
    } finally {
      setLoading(false);
    }
  }

  // ============================================================
  // API CALLS (logic unchanged; moved from the screen)
  // ============================================================

  Map<String, String> _headers(String jwtToken) => {
    "Content-Type": "application/json",
    'Authorization': 'Bearer $jwtToken',
  };

  Future<int> getRatingInfo({
    required String email,
    required String jwtToken,
    required BuildContext context,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Service/getratinginfo";
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(jwtToken),
        body: json.encode({"Email": email}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        ratingInfoList
          ..clear()
          ..addAll(responseData.map((d) => RatingInfoModel.fromJson(d)));
        return 1;
      } else if (response.statusCode == 500) {
        ratingInfoList.clear();
        Toastget().Toastmsg("Your register email don't match..");
        if (context.mounted) await Logout(context: context);
        return 3;
      } else if (response.statusCode == 501) {
        ratingInfoList.clear();
        return 4;
      } else {
        ratingInfoList.clear();
        return 2;
      }
    } catch (e) {
      ratingInfoList.clear();
      return 0;
    }
  }

  Future<int> getServiceInfo({
    required String email,
    required String jwtToken,
    required BuildContext context,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Service/getserviceinfo";
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(jwtToken),
        body: json.encode({"Email": email}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        serviceInfoList
          ..clear()
          ..addAll(
              responseData.map((d) => ServiceScreenServiceModel.fromJson(d)));
        return 1;
      } else if (response.statusCode == 404) {
        serviceInfoList.clear();
        if (context.mounted) await Logout(context: context);
        return 3;
      } else if (response.statusCode == 501 || response.statusCode == 502) {
        serviceInfoList.clear();
        return 4;
      } else {
        serviceInfoList.clear();
        return 2;
      }
    } catch (e) {
      serviceInfoList.clear();
      return 0;
    }
  }

  Future<int> getProviderInfo({
    required String email,
    required String jwtToken,
    required BuildContext context,
  }) async {
    try {
      const String url = Backend_Server_Url + "api/Service/getuserinfo";
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(jwtToken),
        body: json.encode({"Email": email}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        providerInfoList
          ..clear()
          ..addAll(responseData
              .map((d) => ServiceScreenUserInfoModel.fromJson(d)));
        return 1;
      } else if (response.statusCode == 404) {
        providerInfoList.clear();
        Toastget().Toastmsg("Your register email don't match..");
        if (context.mounted) await Logout(context: context);
        return 3;
      } else if (response.statusCode == 501 || response.statusCode == 502) {
        providerInfoList.clear();
        return 4;
      } else {
        providerInfoList.clear();
        return 2;
      }
    } catch (e) {
      providerInfoList.clear();
      return 0;
    }
  }

  // ============================================================
  // Current user location
  // ============================================================

  double _currentUserLat = 0.0;
  double _currentUserLong = 0.0;
  bool _currentUserLocationKnown = false;

  void setCurrentUserLocation(double lat, double long, {bool known = true}) {
    _currentUserLat = lat;
    _currentUserLong = long;
    _currentUserLocationKnown = known;
  }

  // ============================================================
  // Build combined list
  // ============================================================

  void buildCombinedList({
    required List<ServiceScreenServiceModel> services,
    required List<ServiceScreenUserInfoModel> providers,
    required List<RatingInfoModel> ratings,
    required double currentUserLat,
    required double currentUserLong,
    bool currentUserLocationKnown = true,
  }) {
    setCurrentUserLocation(
      currentUserLat,
      currentUserLong,
      known: currentUserLocationKnown,
    );

    final List<CombinedServiceCard> combined = [];

    for (final service in services) {
      ServiceScreenUserInfoModel? provider;
      for (final p in providers) {
        if (p.userNumber == service.userNumber) {
          provider = p;
          break;
        }
      }

      double rating = 0.0;
      for (final r in ratings) {
        if (r.ratingReceiverNumber == service.userNumber &&
            r.serviceName == service.serviceName) {
          rating = asDouble(r.averageRating);
          break;
        }
      }

      double distance = 0.0;
      final bool hasLocation = _currentUserLocationKnown && provider != null;

      if (hasLocation) {
        distance = calculateDistanceKm(
          _currentUserLat,
          _currentUserLong,
          asDouble(provider!.latitude),
          asDouble(provider.longitude),
        );
      }

      combined.add(CombinedServiceCard(
        service: service,
        provider: provider,
        rating: rating,
        distanceKm: distance,
        hasLocation: hasLocation,
      ));
    }

    allCards.assignAll(combined);
    _applyFilterSort();
  }

  void clearAll() {
    allCards.clear();
    displayedCards.clear();
    searchText.value = "";
  }

  // ============================================================
  // FILTER (service name OR user number) + SORT
  // ============================================================

  void _applyFilterSort() {
    final String query = searchText.value.trim().toLowerCase();

    List<CombinedServiceCard> filtered;

    if (query.isEmpty) {
      filtered = List<CombinedServiceCard>.from(allCards);
    } else {
      filtered = allCards.where((card) {
        final String name = (card.service.serviceName ?? "").toLowerCase();
        final String userNumber = (card.service.userNumber ?? 0).toString();
        return name.contains(query) || userNumber.contains(query);
      }).toList();
    }

    if (sortMode.value == ServiceSortMode.distance) {
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    displayedCards.assignAll(filtered);
  }
}

// ============================================================
// HAVERSINE DISTANCE (km)
// ============================================================

double calculateDistanceKm(
    double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371;
  final double dLat = _degToRad(lat2 - lat1);
  final double dLon = _degToRad(lon2 - lon1);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * (pi / 180);

// ============================================================
// SAFE NUMERIC CONVERSION
// ============================================================

double asDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}