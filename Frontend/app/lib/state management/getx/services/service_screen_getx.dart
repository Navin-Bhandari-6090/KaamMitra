import 'dart:math';
import 'package:get/get.dart';
import '../../../models/RatingInfoModel.dart';
import '../../../models/ServiceScreenServiceModel.dart';
import '../../../models/ServiceScreenUserInfoModel.dart';

enum ServiceSortMode { distance, rating }
class CombinedServiceCard
{
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

  RxBool isLoading = false.obs;
  RxBool hasLoadError = false.obs;

  void setLoading(bool value) => isLoading.value = value;
  void setLoadError(bool value) => hasLoadError.value = value;



  final RxList<CombinedServiceCard> allCards = <CombinedServiceCard>[].obs;
  final RxList<CombinedServiceCard> displayedCards =
      <CombinedServiceCard>[].obs;



  RxString searchText = "".obs;
  Rx<ServiceSortMode> sortMode = ServiceSortMode.distance.obs;

  void changeSearchText(String value) {
    searchText.value = value;
    _applyFilterSort();
  }

  void changeSortMode(ServiceSortMode mode) {
    if (sortMode.value == mode) return;
    sortMode.value = mode;
    _applyFilterSort();
  }



  RxBool isSearchFocused = false.obs;
  RxInt hoveredCardIndex = (-1).obs;
  RxInt pressedCardIndex = (-1).obs;

  void setSearchFocused(bool value) => isSearchFocused.value = value;
  void setHoveredCard(int index) => hoveredCardIndex.value = index;
  void clearHoveredCard() => hoveredCardIndex.value = -1;
  void setPressedCard(int index) => pressedCardIndex.value = index;
  void clearPressedCard() => pressedCardIndex.value = -1;



  double _currentUserLat = 0.0;
  double _currentUserLong = 0.0;
  bool _currentUserLocationKnown = false;

  void setCurrentUserLocation(double lat, double long, {bool known = true}) {
    _currentUserLat = lat;
    _currentUserLong = long;
    _currentUserLocationKnown = known;
  }



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

    for (final service in services)
    {

      ServiceScreenUserInfoModel? provider;
      for (final p in providers)
      {
        if (p.userNumber == service.userNumber) {
          provider = p;
          break;
        }
      }

      double rating = 0.0;
      for (final r in ratings)
      {
        if (r.ratingReceiverNumber == service.userNumber &&
            r.serviceName == service.serviceName) {
          rating = asDouble(r.averageRating);
          break;
        }
      }

      double distance = 0.0;
      final bool hasLocation =
          _currentUserLocationKnown && provider != null;

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
        final String userNumber =
        (card.service.userNumber ?? 0).toString();
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
// HAVERSINE DISTANCE (km) — straight-line distance between two
// lat/long points on Earth's surface.
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
// Model fields coming from JSON aren't always a clean `double?` —
// they can arrive as int, num, String, or dynamic depending on how
// fromJson was written. This accepts any of those and always
// returns a non-null double, so call sites never fight the type
// checker again.
// ============================================================

double asDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}