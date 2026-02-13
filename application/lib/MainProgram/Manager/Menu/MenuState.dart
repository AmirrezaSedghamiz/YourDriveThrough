// RestaurantSettingsState.dart
import 'dart:io';
import 'package:application/SourceDesign/Models/Category.dart';

class RestaurantSettingsState {
  // Profile
  final String? restaurantName;
  final String? currentAddress;
  final double geofenceRadius;
  final File? restaurantImageFile;
  final String? restaurantImageUrl;

  // Menu
  final List<Category> categories;
  final int? expandedCategoryId;

  // Loading flags (split)
  final bool isLoadingProfile;
  final bool isLoadingMenu;

  // Saving flags (split)
  final bool isSavingProfile;
  final bool isSavingMenu;

  // UI messages
  final String? snackBarMessage;
  final String? errorMessage;

  const RestaurantSettingsState({
    this.restaurantName,
    this.currentAddress,
    this.geofenceRadius = 500,
    this.restaurantImageFile,
    this.restaurantImageUrl,
    this.categories = const [],
    this.expandedCategoryId,
    this.isLoadingProfile = true,
    this.isLoadingMenu = true,
    this.isSavingProfile = false,
    this.isSavingMenu = false,
    this.snackBarMessage,
    this.errorMessage,
  });

  RestaurantSettingsState copyWith({
    String? restaurantName,
    String? currentAddress,
    double? geofenceRadius,
    File? restaurantImageFile,
    String? restaurantImageUrl,
    List<Category>? categories,
    int? expandedCategoryId,
    bool? isLoadingProfile,
    bool? isLoadingMenu,
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
      restaurantImageFile:
          clearImageFile ? null : (restaurantImageFile ?? this.restaurantImageFile),
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      categories: categories ?? this.categories,
      expandedCategoryId: expandedCategoryId ?? this.expandedCategoryId,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isLoadingMenu: isLoadingMenu ?? this.isLoadingMenu,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isSavingMenu: isSavingMenu ?? this.isSavingMenu,
      snackBarMessage: clearSnack ? null : (snackBarMessage ?? this.snackBarMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
