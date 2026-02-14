// RestaurantSettingsViewModel.dart
import 'dart:io';

import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/Services/Map.dart';
import 'package:application/Handlers/Repository/ManagerRepo.dart';
import 'package:application/MainProgram/Manager/Menu/MenuState.dart';
import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/Item.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart'; // RestaurantInfo
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------------------------------------------------------------------------
/// Contracts (keep these so you can swap implementations later)
/// ---------------------------------------------------------------------------
abstract class RestaurantRepo {
  Future<RestaurantInfo> fetchProfile(int restaurantId);
  Future<List<Category>> fetchMenu(int restaurantId);

  Future<void> updateProfile({
    required int restaurantId,
    required String name,
    required String address,
    required double radiusMeters,
    File? imageFile,
    num? longitude,
    num? latitude,
  });

  Future<void> updateMenu({
    required int restaurantId,
    required List<Category> categories,
  });
}

/// ---------------------------------------------------------------------------
/// ManagerRepo-backed implementation
///   - fetchProfile() uses ManagerRepo.getRestaurantProfile()
///   - fetchMenu() uses ManagerRepo.getMenu(restaurantId)
///   - updateProfile/updateMenu left as prototypes you replace later
/// ---------------------------------------------------------------------------
class ManagerRestaurantRepo implements RestaurantRepo {
  ManagerRestaurantRepo(this._repo);
  final ManagerRepo _repo;

  @override
  Future<RestaurantInfo> fetchProfile(int restaurantId) async {
    // NOTE: your ManagerRepo.getRestaurantProfile() doesn’t take id; it uses /me/
    final res = await _repo.getRestaurantProfile();

    if (res is RestaurantInfo) {
      // ⚠️ Adjust these field names to match your RestaurantInfo model exactly.
      // I used common ones based on your UI usage.
      final name = (res.name ?? "").toString();
      final address = (res.address ?? "").toString();

      // If you don't have radius/image on RestaurantInfo, keep defaults.
      // final radius = (res.radius ?? 500).toDouble();
      final imageUrl = res.image; // handle either field name

      return res;
    }

    // ManagerRepo returns ConnectionStates on errors
    throw Exception(_connToMessage(res));
  }

  @override
  Future<List<Category>> fetchMenu(int restaurantId) async {
    final res = await _repo.getMenu(restaurantId: restaurantId);

    if (res is List<Category>) return res;

    throw Exception(_connToMessage(res));
  }

  @override
  Future<void> updateProfile({
    required int restaurantId,
    required String name,
    required String address,
    required double radiusMeters,
    File? imageFile,
    num? longitude,
    num? latitude,
  }) async {
    // Your existing API: fillRestaurantProfile({ username, longitude, latitude, image, address })
    // You can wire this now IF you have longitude/latitude ready in the state.
    if (longitude == null || latitude == null) {
      throw Exception(
        "Missing longitude/latitude. Provide them before calling updateProfile.",
      );
    }

    final res = await _repo.fillRestaurantProfile(
      username: name,
      longitude: longitude,
      latitude: latitude,
      image: imageFile,
      address: address,
    );

    if (res == ConnectionStates.Success) return;

    throw Exception(_connToMessage(res));
  }

  @override
  Future<void> updateMenu({
    required int restaurantId,
    required List<Category> categories,
  }) async {
    // You don't show an endpoint for saving menu in ManagerRepo.
    // Keep as prototype.
    throw UnimplementedError(
      "Implement menu save API in ManagerRepo then call it here.",
    );
  }

  String _connToMessage(dynamic state) {
    switch (state) {
      case ConnectionStates.BadRequest:
        return "Bad request (400)";
      case ConnectionStates.Unauthorized:
        return "Unauthorized (401)";
      case ConnectionStates.TokenFailure:
        return "Token failure (404)";
      case ConnectionStates.DataBase:
        return "Database error (500)";
      case ConnectionStates.BadGateWay:
        return "Bad gateway (502)";
      case ConnectionStates.GateWayTimeOut:
        return "Gateway timeout (504)";
      case ConnectionStates.Unexpected:
        return "Unexpected server error";
      case ConnectionStates.Success:
        return "Success";
      default:
        return "Unknown error: $state";
    }
  }
}

/// ---------------------------------------------------------------------------
/// Providers
/// ---------------------------------------------------------------------------
final managerRepoProvider = Provider<ManagerRepo>((ref) {
  return ManagerRepo();
});

final restaurantRepoProvider = Provider<RestaurantRepo>((ref) {
  final mgr = ref.read(managerRepoProvider);
  return ManagerRestaurantRepo(mgr);
});

/// ---------------------------------------------------------------------------
/// ViewModel
/// ---------------------------------------------------------------------------
class RestaurantSettingsViewModel extends Notifier<RestaurantSettingsState> {
  bool _initialized = false;

  @override
  RestaurantSettingsState build() {
    return const RestaurantSettingsState(
      restaurantId: null,
      isLoadingProfile: false,
      isLoadingMenu: false,
      isSavingProfile: false,
      isSavingMenu: false,
    );
  }

  /// Call once from the page (initState/postFrame)
  Future<void> init(int restaurantId) async {
    if (_initialized && state.restaurantId == restaurantId) return;
    _initialized = true;

    state = state.copyWith(
      restaurantId: restaurantId,
      isLoadingProfile: true,
      isLoadingMenu: true,
      clearError: true,
      clearSnack: true,
    );

    await Future.wait([_loadProfile(), _loadMenu()]);
  }

  Future<void> refreshAll() async {
    await Future.wait([_loadProfile(), _loadMenu()]);
  }

  // ---------------- Fetchers ----------------

  Future<void> _loadProfile() async {
    final id = state.restaurantId;
    if (id == null) return;

    state = state.copyWith(isLoadingProfile: true, clearError: true);

    try {
      final repo = ref.read(restaurantRepoProvider);
      final p = await repo.fetchProfile(id);

      state = state.copyWith(
        restaurantName: p.name,
        currentAddress: p.address,
        geofenceRadius: 0,
        restaurantImageUrl: p.image,
        longitude: p.latitude,
        latitude: p.latitude,
        // if user already picked a file, keep it
        isLoadingProfile: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingProfile: false,
        errorMessage: "Profile load failed: $e",
      );
    }
  }

  Future<void> _loadMenu() async {
    final id = state.restaurantId;
    if (id == null) return;

    state = state.copyWith(isLoadingMenu: true, clearError: true);

    try {
      final repo = ref.read(restaurantRepoProvider);
      final cats = await repo.fetchMenu(id);

      // Ensure list is a fresh instance to avoid sliver issues
      state = state.copyWith(
        categories: List<Category>.from(cats),
        isLoadingMenu: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMenu: false,
        errorMessage: "Menu load failed: $e",
      );
    }
  }

  // ---------------- Profile edits ----------------

  void setRestaurantName(String v) => state = state.copyWith(restaurantName: v);

  void setAddress(String v) => state = state.copyWith(currentAddress: v);

  void setGeofenceRadius(double meters) {
    state = state.copyWith(geofenceRadius: meters.clamp(50, 2000));
  }

  void setRestaurantImageFile(File? file) {
    // if local file exists, prefer it over remote url in UI
    state = state.copyWith(
      restaurantImageFile: file,
      restaurantImageUrl: file != null ? null : state.restaurantImageUrl,
    );
  }

  /// Optional: if you later store lng/lat in state
  void setLocationCoords({num? longitude, num? latitude}) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  Future<void> submitProfileChanges({num? longitude, num? latitude}) async {
    final id = state.restaurantId;
    if (id == null) {
      state = state.copyWith(errorMessage: "Restaurant ID missing.");
      return;
    }
    if (state.isSavingProfile) return;

    final name = (state.restaurantName ?? "").trim();
    final address = (state.currentAddress ?? "").trim();

    if (name.isEmpty) {
      state = state.copyWith(errorMessage: "Restaurant name cannot be empty.");
      return;
    }
    if (address.isEmpty) {
      state = state.copyWith(
        errorMessage: "Restaurant address cannot be empty.",
      );
      return;
    }

    state = state.copyWith(isSavingProfile: true, clearError: true);

    try {
      final repo = ref.read(restaurantRepoProvider);

      await repo.updateProfile(
        restaurantId: id,
        name: name,
        address: address,
        radiusMeters: state.geofenceRadius,
        imageFile: state.restaurantImageFile,
        longitude: state.longitude,
        latitude: state.latitude,
      );
      await ManagerRepo().fillRestaurantProfile(
        username: state.restaurantName ?? "",
        longitude: formatCoordinate(state.longitude!.toDouble()),
        latitude: formatCoordinate(state.latitude!.toDouble()),
        image: state.restaurantImageFile,
        address: state.currentAddress ?? "",
      );

      state = state.copyWith(
        isSavingProfile: false,
        snackBarMessage: "Profile updated",
      );
      await _loadProfile();
    } catch (e) {
      state = state.copyWith(
        isSavingProfile: false,
        errorMessage: "Profile save failed: $e",
      );
    }
  }

  // ---------------- Menu edits ----------------

  void setExpandedCategory(int? id) =>
      state = state.copyWith(expandedCategoryId: id);

  void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final nextId = _nextCategoryId();

    final updated = List<Category>.from(state.categories)
      ..add(Category(id: nextId, name: trimmed, item: const []));

    state = state.copyWith(categories: updated, expandedCategoryId: nextId);
  }

  void renameCategory(int categoryId, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = state.categories
        .map((c) {
          if (c.id != categoryId) return c;
          return Category(id: c.id, name: trimmed, item: c.item);
        })
        .toList(growable: false);

    state = state.copyWith(categories: updated);
  }

  void deleteCategory(int categoryId) {
    final updated = List<Category>.from(state.categories)
      ..removeWhere((c) => c.id == categoryId);

    final expanded = state.expandedCategoryId == categoryId
        ? null
        : state.expandedCategoryId;

    state = state.copyWith(categories: updated, expandedCategoryId: expanded);
  }

  void addItem(int categoryId, Item item) {
    final updated = state.categories
        .map((c) {
          if (c.id != categoryId) return c;

          final items = List<Item>.from(c.item)
            ..add(
              item.id == 0
                  ? item.copyWith(id: DateTime.now().microsecondsSinceEpoch)
                  : item,
            );

          return Category(id: c.id, name: c.name, item: items);
        })
        .toList(growable: false);

    state = state.copyWith(categories: updated, expandedCategoryId: categoryId);
  }

  void updateItem(int categoryId, Item updatedItem) {
    final updated = state.categories
        .map((c) {
          if (c.id != categoryId) return c;

          final items = c.item
              .map((it) => it.id == updatedItem.id ? updatedItem : it)
              .toList(growable: false);

          return Category(id: c.id, name: c.name, item: items);
        })
        .toList(growable: false);

    state = state.copyWith(categories: updated);
  }

  void deleteItem(int categoryId, int itemId) {
    final updated = state.categories
        .map((c) {
          if (c.id != categoryId) return c;

          final items = List<Item>.from(c.item)
            ..removeWhere((it) => it.id == itemId);

          return Category(id: c.id, name: c.name, item: items);
        })
        .toList(growable: false);

    state = state.copyWith(categories: updated);
  }

  Future<void> submitMenuChanges() async {
    final id = state.restaurantId;
    if (id == null) {
      state = state.copyWith(errorMessage: "Restaurant ID missing.");
      return;
    }
    if (state.isSavingMenu) return;

    state = state.copyWith(isSavingMenu: true, clearError: true);

    try {
      final repo = ref.read(restaurantRepoProvider);

      await repo.updateMenu(restaurantId: id, categories: state.categories);

      state = state.copyWith(
        isSavingMenu: false,
        snackBarMessage: "Menu saved",
      );

      // Optional: reload authoritative data
      await _loadMenu();
    } catch (e) {
      state = state.copyWith(
        isSavingMenu: false,
        errorMessage: "Menu save failed: $e",
      );
    }
  }

  // ---------------- UI helpers ----------------

  void clearSnack() => state = state.copyWith(clearSnack: true);

  int _nextCategoryId() {
    if (state.categories.isEmpty) return 1;
    final ids = state.categories.map((c) => c.id).toList()..sort();
    return ids.last + 1;
  }
}

/// Provider
final restaurantSettingsViewModelProvider =
    NotifierProvider<RestaurantSettingsViewModel, RestaurantSettingsState>(
      () => RestaurantSettingsViewModel(),
    );
