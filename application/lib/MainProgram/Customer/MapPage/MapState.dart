// ClosestRestaurantsState.dart
import 'package:latlong2/latlong.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart';

class ClosestRestaurantsState {
  final LatLng? userLatLng;
  final LatLng? destinationLatLng;

  /// when you tap a restaurant card (NOT select) we highlight it on the map
  final RestaurantInfo? highlightedRestaurant;

  final String? error; // non-paging errors only (optional)
  final bool initialized;

  const ClosestRestaurantsState({
    this.userLatLng,
    this.destinationLatLng,
    this.highlightedRestaurant,
    this.error,
    this.initialized = false,
  });

  bool get canFetch => userLatLng != null && destinationLatLng != null;

  ClosestRestaurantsState copyWith({
    LatLng? userLatLng,
    LatLng? destinationLatLng,
    RestaurantInfo? highlightedRestaurant,
    bool clearHighlighted = false,
    String? error,
    bool clearError = false,
    bool? initialized,
  }) {
    return ClosestRestaurantsState(
      userLatLng: userLatLng ?? this.userLatLng,
      destinationLatLng: destinationLatLng ?? this.destinationLatLng,
      highlightedRestaurant:
          clearHighlighted ? null : (highlightedRestaurant ?? this.highlightedRestaurant),
      error: clearError ? null : (error ?? this.error),
      initialized: initialized ?? this.initialized,
    );
  }
}
