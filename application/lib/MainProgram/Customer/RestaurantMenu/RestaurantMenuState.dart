import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/Item.dart';

class RestaurantMenuState {
  bool isLoading;
  String? error;
  
  int? restaurantId; // <-- set from page

  String restaurantName;
  num rating;
  String waitRangeText;

  List<Category> categories;
  int selectedCategoryIndex;

  Item? selectedItem;
  int selectedQty;

  RestaurantMenuState({
    this.restaurantId,
    this.isLoading = false,
    this.error,
    this.restaurantName = "",
    this.rating = 0,
    this.waitRangeText = "",
    List<Category>? categories,
    this.selectedCategoryIndex = 0,
    this.selectedItem,
    this.selectedQty = 1,
  }) : categories = categories ?? [];

  Category? get selectedCategory =>
      (selectedCategoryIndex >= 0 && selectedCategoryIndex < categories.length)
          ? categories[selectedCategoryIndex]
          : null;

  RestaurantMenuState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? restaurantId,
    String? restaurantName,
    num? rating,
    String? waitRangeText,
    List<Category>? categories,
    int? selectedCategoryIndex,
    Item? selectedItem,
    bool clearSelectedItem = false,
    int? selectedQty,
  }) {
    return RestaurantMenuState(
      restaurantId: restaurantId ?? this.restaurantId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      restaurantName: restaurantName ?? this.restaurantName,
      rating: rating ?? this.rating,
      waitRangeText: waitRangeText ?? this.waitRangeText,
      categories: categories ?? this.categories,
      selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
      selectedItem: clearSelectedItem ? null : (selectedItem ?? this.selectedItem),
      selectedQty: selectedQty ?? this.selectedQty,
    );
  }
}
