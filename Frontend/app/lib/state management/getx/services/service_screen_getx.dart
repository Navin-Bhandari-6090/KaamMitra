// ---------------------------------------------------------------------------
// service_screen_getx.dart
//
// Adjust the three model import paths below to match your project structure
// (these mirror the "../../../models/XYZ.dart" pattern used by
// add_service_getx.dart — update the number of "../" as needed depending on
// where you place this file, e.g. state management/getx/services/).
// ---------------------------------------------------------------------------

import 'dart:math';

import 'package:get/get.dart';

import '../../../models/RatingInfoModel.dart';
import '../../../models/Service_Screen_Service_Model.dart';
import '../../../models/Service_Screen_User_Info_Model.dart';

/// How the provider list is currently ordered.
enum ServiceSortMode { distance, rating }

/// One row of the Services screen list: a service, joined with its
/// provider's profile info and average rating, plus the computed distance
/// from the current user.
///
/// This is a *view* model only — it does not replace or alter
/// ServiceScreenServiceModel / ServiceScreenUserInfoModel / RatingInfoModel.
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
  // ============================================================
  // LOADING STATE
  // ============================================================

  RxBool isLoading = false.obs;
  RxBool hasLoadError = false.obs;

  void setLoading(bool value) => isLoading.value = value;
  void setLoadError(bool value) => hasLoadError.value = value;

  // ============================================================
  // COMBINED + DERIVED LISTS
  // allCards  = every service joined with provider + rating info.
  // displayedCards = allCards after search filter + sort are applied.
  // ============================================================

  final RxList<CombinedServiceCard> allCards = <CombinedServiceCard>[].obs;
  final RxList<CombinedServiceCard> displayedCards =
      <CombinedServiceCard>[].obs;

  // ============================================================
  // SEARCH + SORT
  // ============================================================

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

  // ============================================================
  // UI-ONLY REACTIVE STATE (replaces setState — press/hover/focus)
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
  // CURRENT USER LOCATION
  // (Set once, before building the combined list — see notes in
  // ServicesScreen on where this currently comes from.)
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
  // BUILD COMBINED LIST
  // Joins service (by email) -> provider profile, and service (by email
  // AND service name) -> rating. Does not mutate or re-request any of the
  // raw source lists.
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

    for (final service in services)
    {
      ServiceScreenUserInfoModel? provider;
      for (final p in providers)
      {
        if (p.email == service.email) {
          provider = p;
          break;
        }
      }

      // ----------------------------------------------------------
      // UPDATED: a rating row now belongs to one specific service
      // (userEmail + serviceName), not just one provider overall.
      // Match on both fields so each card gets the correct average
      // rating for that exact service, instead of whichever rating
      // row for that provider happened to come first.
      // ----------------------------------------------------------
      double rating = 0.0;
      for (final r in ratings) {
        if (r.userEmail == service.email &&
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