// RestaurantSettingsViewModel.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/Item.dart';
import 'RestaurantSettingsState.dart';

// You implement these API calls however you want.
abstract class RestaurantRepo {
  Future<RestaurantProfileDto> fetchProfile(int restaurantId);
  Future<List<Category>> fetchMenu(int restaurantId);
}

class RestaurantProfileDto {
  final String name;
  final String address;
  final double radius;
  final String? imageUrl;

  RestaurantProfileDto({
    required this.name,
    required this.address,
    required this.radius,
    this.imageUrl,
  });
}

// Provide your real repo implementation.
final restaurantRepoProvider = Provider<RestaurantRepo>((ref) {
  throw UnimplementedError("Provide RestaurantRepo");
});

class RestaurantSettingsViewModel extends FamilyNotifier<RestaurantSettingsState, int> {
  late final int restaurantId;

  @override
  RestaurantSettingsState build(int arg) {
    restaurantId = arg;

    // start with loading
    state = const RestaurantSettingsState(
      isLoadingProfile: true,
      isLoadingMenu: true,
    );

    // fire initial fetch (no await in build)
    _loadInitial();

    return state;
  }

  Future<void> _loadInitial() async {
    // Load them independently so Profile shimmer can stop before Menu, etc.
    await Future.wait([
      _loadProfile(),
      _loadMenu(),
    ]);
  }

  Future<void> _loadProfile() async {
    state = state.copyWith(isLoadingProfile: true, clearError: true);
    try {
      final repo = ref.read(restaurantRepoProvider);
      final p = await repo.fetchProfile(restaurantId);

      state = state.copyWith(
        restaurantName: p.name,
        currentAddress: p.address,
        geofenceRadius: p.radius,
        restaurantImageUrl: p.imageUrl,
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
    state = state.copyWith(isLoadingMenu: true, clearError: true);
    try {
      final repo = ref.read(restaurantRepoProvider);
      final cats = await repo.fetchMenu(restaurantId);

      state = state.copyWith(
        categories: cats,
        isLoadingMenu: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMenu: false,
        errorMessage: "Menu load failed: $e",
      );
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([_loadProfile(), _loadMenu()]);
  }

  // ------- Profile edits -------
  void setRestaurantName(String v) => state = state.copyWith(restaurantName: v);
  void setAddress(String v) => state = state.copyWith(currentAddress: v);

  void setGeofenceRadius(double meters) {
    state = state.copyWith(geofenceRadius: meters.clamp(50, 2000));
  }

  void setRestaurantImageFile(File? file) {
    state = state.copyWith(restaurantImageFile: file);
  }

  Future<void> submitProfileChanges() async {
    if (state.isSavingProfile) return;
    state = state.copyWith(isSavingProfile: true, clearError: true);

    try {
      // TODO: call your API with restaurantId + profile fields
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(
        isSavingProfile: false,
        snackBarMessage: "Profile updated",
      );
    } catch (e) {
      state = state.copyWith(
        isSavingProfile: false,
        errorMessage: "Profile save failed: $e",
      );
    }
  }

  // ------- Menu edits -------
  void setExpandedCategory(int? id) => state = state.copyWith(expandedCategoryId: id);

  void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final nextId = _nextCategoryId();
    final updated = List<Category>.from(state.categories)
      ..add(Category(id: nextId, name: trimmed, item: []));

    state = state.copyWith(categories: updated, expandedCategoryId: nextId);
  }

  void renameCategory(int categoryId, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = state.categories.map((c) {
      if (c.id != categoryId) return c;
      return Category(id: c.id, name: trimmed, item: c.item);
    }).toList();

    state = state.copyWith(categories: updated);
  }

  void deleteCategory(int categoryId) {
    final updated = List<Category>.from(state.categories)
      ..removeWhere((c) => c.id == categoryId);

    final expanded = state.expandedCategoryId == categoryId ? null : state.expandedCategoryId;
    state = state.copyWith(categories: updated, expandedCategoryId: expanded);
  }

  void addItem(int categoryId, Item item) {
    final updated = state.categories.map((c) {
      if (c.id != categoryId) return c;
      final items = List<Item>.from(c.item)..add(item);
      return Category(id: c.id, name: c.name, item: items);
    }).toList();

    state = state.copyWith(categories: updated, expandedCategoryId: categoryId);
  }

  void updateItem(int categoryId, Item updatedItem) {
    final updated = state.categories.map((c) {
      if (c.id != categoryId) return c;
      final items = c.item.map((it) => it.id == updatedItem.id ? updatedItem : it).toList();
      return Category(id: c.id, name: c.name, item: items);
    }).toList();

    state = state.copyWith(categories: updated);
  }

  void deleteItem(int categoryId, int itemId) {
    final updated = state.categories.map((c) {
      if (c.id != categoryId) return c;
      final items = List<Item>.from(c.item)..removeWhere((it) => it.id == itemId);
      return Category(id: c.id, name: c.name, item: items);
    }).toList();

    state = state.copyWith(categories: updated);
  }

  Future<void> submitMenuChanges() async {
    if (state.isSavingMenu) return;
    state = state.copyWith(isSavingMenu: true, clearError: true);

    try {
      // TODO: call your API with restaurantId + state.categories
      await Future.delayed(const Duration(milliseconds: 700));
      state = state.copyWith(
        isSavingMenu: false,
        snackBarMessage: "Menu saved",
      );
    } catch (e) {
      state = state.copyWith(
        isSavingMenu: false,
        errorMessage: "Menu save failed: $e",
      );
    }
  }

  void clearSnack() => state = state.copyWith(clearSnack: true);

  int _nextCategoryId() {
    if (state.categories.isEmpty) return 1;
    final ids = state.categories.map((c) => c.id).toList()..sort();
    return ids.last + 1;
  }
}

final restaurantSettingsViewModelProvider =
    NotifierProvider.family<RestaurantSettingsViewModel, RestaurantSettingsState, int>(
  RestaurantSettingsViewModel.new,
);
