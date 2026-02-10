// RestaurantSettingsViewModel.dart
import 'dart:io';

import 'package:application/MainProgram/Manager/Menu/MenuState.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/Item.dart';

class RestaurantSettingsViewModel extends Notifier<RestaurantSettingsState> {
  @override
  RestaurantSettingsState build() {
    return RestaurantSettingsState(
      restaurantName: "FastBites Kitchen",
      currentAddress: "123 Main Street, Anytown, CA 90210",
      geofenceRadius: 500,
      categories: [
        Category(
          id: 1,
          name: "Appetizers",
          item: [
            Item(id: 11, name: "Fries", expectedDuration: 5, price: 3.5),
            Item(id: 12, name: "Onion Rings", expectedDuration: 7, price: 4),
          ],
        ),
        Category(
          id: 2,
          name: "Main Courses",
          item: [
            Item(id: 21, name: "Classic Burger", expectedDuration: 12, price: 9.5),
            Item(id: 22, name: "Veggie Wrap", expectedDuration: 10, price: 8),
          ],
        ),
      ],
      expandedCategoryId: 1,
    );
  }

  void setRestaurantName(String v) {
    state = state.copyWith(restaurantName: v);
  }

  void setAddress(String v) {
    state = state.copyWith(currentAddress: v);
  }

  void setGeofenceRadius(double meters) {
    state = state.copyWith(geofenceRadius: meters.clamp(50, 2000));
  }

  /// You handle picking/uploading; we just store the selected file.
  void setRestaurantImageFile(File? file) {
    state = state.copyWith(restaurantImageFile: file);
  }

  void setExpandedCategory(int? id) {
    state = state.copyWith(expandedCategoryId: id);
  }

  Future<void> submitProfileChanges() async {
    if (state.isSavingProfile) return;
    state = state.copyWith(isSavingProfile: true, clearError: true);

    try {
      // TODO: call your API
      await Future.delayed(const Duration(milliseconds: 700));
      state = state.copyWith(isSavingProfile: false, snackBarMessage: "Profile updated");
    } catch (e) {
      state = state.copyWith(isSavingProfile: false, errorMessage: "Profile save failed: $e");
    }
  }

  Future<void> submitMenuChanges() async {
    if (state.isSavingMenu) return;
    state = state.copyWith(isSavingMenu: true, clearError: true);

    try {
      // TODO: call your API with state.categories
      await Future.delayed(const Duration(milliseconds: 900));
      state = state.copyWith(isSavingMenu: false, snackBarMessage: "Menu saved");
    } catch (e) {
      state = state.copyWith(isSavingMenu: false, errorMessage: "Menu save failed: $e");
    }
  }

  void clearSnack() => state = state.copyWith(clearSnack: true);

  // ---------------- Categories ----------------
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

  // ---------------- Items ----------------
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

  int _nextCategoryId() {
    if (state.categories.isEmpty) return 1;
    final ids = state.categories.map((c) => c.id).toList()..sort();
    return ids.last + 1;
  }
}

final restaurantSettingsViewModelProvider =
    NotifierProvider<RestaurantSettingsViewModel, RestaurantSettingsState>(
  () => RestaurantSettingsViewModel(),
);
