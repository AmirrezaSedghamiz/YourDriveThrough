// RestaurantSettingsState.dart
import 'dart:io';
import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/Item.dart';

class RestaurantSettingsState {
  // Profile
  String restaurantName;
  String currentAddress;
  double geofenceRadius; // meters
  File? restaurantImageFile; // you’ll handle upload; we only store selection
  String? restaurantImageUrl; // if you already have one from backend

  // Menu
  List<Category> categories;
  int? expandedCategoryId; // for UI expand/collapse

  // Async / UI flags
  bool isSavingProfile;
  bool isSavingMenu;
  String? snackBarMessage;
  String? errorMessage;

  RestaurantSettingsState({
    this.restaurantName = "FastBites Kitchen",
    this.currentAddress = "123 Main Street, Anytown, CA 90210",
    this.geofenceRadius = 500,
    this.restaurantImageFile,
    this.restaurantImageUrl,
    List<Category>? categories,
    this.expandedCategoryId,
    this.isSavingProfile = false,
    this.isSavingMenu = false,
    this.snackBarMessage,
    this.errorMessage,
  }) : categories = categories ?? [];

  RestaurantSettingsState copyWith({
    String? restaurantName,
    String? currentAddress,
    double? geofenceRadius,
    File? restaurantImageFile,
    String? restaurantImageUrl,
    List<Category>? categories,
    int? expandedCategoryId,
    bool? isSavingProfile,
    bool? isSavingMenu,
    String? snackBarMessage,
    String? errorMessage,
    bool clearSnack = false,
    bool clearError = false,
    bool clearImageFile = false,
  }) {
    return RestaurantSettingsState(
      restaurantName: restaurantName ?? this.restaurantName,
      currentAddress: currentAddress ?? this.currentAddress,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      restaurantImageFile: clearImageFile ? null : (restaurantImageFile ?? this.restaurantImageFile),
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      categories: categories ?? this.categories,
      expandedCategoryId: expandedCategoryId ?? this.expandedCategoryId,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isSavingMenu: isSavingMenu ?? this.isSavingMenu,
      snackBarMessage: clearSnack ? null : (snackBarMessage ?? this.snackBarMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
