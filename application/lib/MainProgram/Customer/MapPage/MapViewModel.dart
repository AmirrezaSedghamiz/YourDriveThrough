// ClosestRestaurantsViewModel.dart
import 'dart:async';

import 'package:application/GlobalWidgets/PermissionHandlers/Location/Location.dart';
import 'package:application/GlobalWidgets/Services/Map.dart';
import 'package:application/Handlers/Repository/CustomerRepo.dart';
import 'package:application/MainProgram/Customer/MapPage/MapState.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:latlong2/latlong.dart';


class ClosestRestaurantsViewModel extends Notifier<ClosestRestaurantsState> {
  static const _firstPageKey = 1;
  static const _pageSize = 10;

  final PagingController<int, RestaurantInfo> pagingController =
      PagingController(firstPageKey: _firstPageKey);

  bool _wired = false;

  @override
  ClosestRestaurantsState build() {
    // IMPORTANT:
    // PagingController will request the first page during widget build.
    // So inside _fetchPage you MUST NOT write to `state`.
    if (!_wired) {
      _wired = true;
      pagingController.addPageRequestListener(_fetchPage);
      ref.onDispose(() {
        pagingController.dispose();
      });
    }
    return const ClosestRestaurantsState();
  }

  Future<void> init() async {
    if (state.initialized) return;
    state = state.copyWith(initialized: true, clearError: true);

    // get user location once at start
    await refreshUserLocation();
  }

  Future<void> refreshUserLocation() async {
    // uses YOUR LocationController/provider
    await ref.read(locationControllerProvider.notifier).requestLocation();
    final locState = ref.read(locationControllerProvider);

    // LocationState.success has data != null in your impl
    final data = locState.data;
    if (data == null) {
      // keep it silent; your UI can show the fail-safe dialog if you want
      state = state.copyWith(error: "Location not available.");
      return;
    }

    final user = LatLng(data.latitude!, data.longitude!);
    state = state.copyWith(userLatLng: user, clearError: true);

    // if destination already selected, refresh list
    if (state.destinationLatLng != null) {
      // schedule refresh AFTER current frame to avoid "modify during build" edge cases
      Future<void>.delayed(Duration.zero, () => pagingController.refresh());
    }
  }

  void setDestination(LatLng dest) {
    state = state.copyWith(destinationLatLng: dest, clearError: true);
    // refresh list after destination changes (defer)
    Future<void>.delayed(Duration.zero, () => pagingController.refresh());
  }

  void highlightRestaurant(RestaurantInfo r) {
    // SAFE: this is from user tap, not from paging callback
    state = state.copyWith(highlightedRestaurant: r);
  }

  Future<void> refreshAll() async {
    await refreshUserLocation();
    if (state.canFetch) {
      Future<void>.delayed(Duration.zero, () => pagingController.refresh());
    } else {
      pagingController.itemList = [];
      pagingController.error = null;
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    // DO NOT TOUCH `state` INSIDE THIS FUNCTION.
    // paging requests can happen during widget build.
    if (!state.canFetch) {
      pagingController.appendLastPage(<RestaurantInfo>[]);
      return;
    }

    try {
      final u = state.userLatLng!;
      final d = state.destinationLatLng!;

      final result = await CustomerRepo().getRestaurantListWithTwoCooR(
        pageSize: _pageSize,
        pageKey: pageKey,
        longitude1:formatCoordinate(u.longitude),
        latitude1: formatCoordinate(u.latitude),
        longitude2: formatCoordinate(d.longitude),
        latitude2: formatCoordinate(d.latitude),
      );

      if (result is List<RestaurantInfo>) {
        final newItems = result;
        final isLastPage = newItems.length < _pageSize;

        if (isLastPage) {
          pagingController.appendLastPage(newItems);
        } else {
          pagingController.appendPage(newItems, pageKey + 1);
        }
      } else {
        // ConnectionStates or other failures -> treat as error
        pagingController.error = result;
      }
    } catch (e) {
      pagingController.error = e;
    }
  }
}

final closestRestaurantsProvider =
    NotifierProvider<ClosestRestaurantsViewModel, ClosestRestaurantsState>(
  () => ClosestRestaurantsViewModel(),
);
