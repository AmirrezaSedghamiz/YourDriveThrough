import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/Item.dart';

import 'RestaurantMenuState.dart';

class RestaurantMenuViewModel extends Notifier<RestaurantMenuState> {
  bool _initialized = false;

  @override
  RestaurantMenuState build() {
    return RestaurantMenuState(); // empty until init(restaurantId)
  }

  /// Call this ONCE from the page's initState/postFrame
  Future<void> init(int restaurantId) async {
    if (_initialized && state.restaurantId == restaurantId) return;
    _initialized = true;

    state = state.copyWith(restaurantId: restaurantId);
    await _load();
  }

  Future<void> _load() async {
    final id = state.restaurantId;
    if (id == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // TODO: replace with your repo call:
      // final res = await RestaurantRepo().getMenu(id);

      await Future.delayed(const Duration(milliseconds: 700));
      final mock = _mockMenu(id);

      state = state.copyWith(
        isLoading: false,
        restaurantName: mock.$1,
        rating: mock.$2,
        waitRangeText: mock.$3,
        categories: mock.$4,
        selectedCategoryIndex: 0,
        clearSelectedItem: true,
        selectedQty: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "$e");
    }
  }

  Future<void> refresh() async => _load();

  void selectCategory(int index) {
    if (index < 0 || index >= state.categories.length) return;
    state = state.copyWith(
      selectedCategoryIndex: index,
      clearSelectedItem: true,
      selectedQty: 1,
    );
  }

  void openItem(Item item) {
    state = state.copyWith(selectedItem: item, selectedQty: 1);
  }

  void closeItem() {
    state = state.copyWith(clearSelectedItem: true, selectedQty: 1);
  }

  void incQty() => state = state.copyWith(selectedQty: state.selectedQty + 1);

  void decQty() {
    if (state.selectedQty <= 1) return;
    state = state.copyWith(selectedQty: state.selectedQty - 1);
  }

}

final restaurantMenuViewModelProvider =
    NotifierProvider<RestaurantMenuViewModel, RestaurantMenuState>(
  () => RestaurantMenuViewModel(),
);

/// -------------------- MOCK DATA --------------------
(String, num, String, List<Category>) _mockMenu(int restaurantId) {
  final rnd = Random(restaurantId);
  final name = restaurantId % 2 == 0 ? "Burger Haven" : "The Beef Joint";
  final rating = 4 + rnd.nextDouble() * 0.9;
  final wait = "${15 + rnd.nextInt(6)}-${20 + rnd.nextInt(6)} min wait";

  Item it(int id, String n, num price, num dur, {String? desc, String? img}) {
    return Item(
      id: id,
      name: n,
      price: price,
      expectedDuration: dur,
      description: desc,
      image: img,
    );
  }

  final cats = <Category>[
    Category(
      id: 1,
      name: "Burgers",
      item: [
        it(11, "Classic Beef Beef", 12.99, 18,
            desc: "A juicy beef patty with lettuce, tomato, onion and pickles."),
        it(12, "Spicy Chicken Beef", 13.49, 20,
            desc: "Crispy fried chicken, sriracha mayo, jalapeños and coleslaw."),
      ],
    ),
    Category(
      id: 2,
      name: "Sides",
      item: [
        it(21, "Fries", 3.99, 6, desc: "Golden crispy fries."),
        it(22, "Onion Rings", 4.49, 8, desc: "Crunchy rings with dip."),
      ],
    ),
  ];

  return (name, num.parse(rating.toStringAsFixed(1)), wait, cats);
}
