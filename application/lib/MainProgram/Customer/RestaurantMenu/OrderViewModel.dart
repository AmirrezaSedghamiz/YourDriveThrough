import 'package:application/MainProgram/Customer/RestaurantMenu/OrderState.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:application/SourceDesign/Models/Item.dart';

class OrderViewModel extends Notifier<OrderState> {
  @override
  OrderState build() => const OrderState();

  void addItem(Item item, int qty) {
    final lines = [...state.draftLines];
    final idx = lines.indexWhere((l) => l.item.id == item.id);
    if (idx >= 0) {
      lines[idx] = lines[idx].copyWith(qty: lines[idx].qty + qty);
    } else {
      lines.add(OrderLine(item: item, qty: qty));
    }
    state = state.copyWith(draftLines: lines, clearError: true);
  }

  void removeItem(int itemId) {
    state = state.copyWith(
      draftLines: state.draftLines.where((l) => l.item.id != itemId).toList(),
    );
  }

  void clearDraft() {
    state = state.copyWith(draftLines: const []);
  }

  /// “Submit” the draft into the list of submitted orders (but not final “checkout”)
  Future<void> submitDraft({
    required int restaurantId,
    required String restaurantName,
  }) async {
    if (state.draftLines.isEmpty) return;

    try {
      state = state.copyWith(isSubmitting: true, clearError: true);

      // If you have an API call, do it here (optional).
      // await OrderRepo().submitDraft(...);

      final order = SubmittedOrder(
        createdAt: DateTime.now(),
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        lines: state.draftLines,
      );

      state = state.copyWith(
        isSubmitting: false,
        submittedOrders: [order, ...state.submittedOrders],
        draftLines: const [], // clear cart after submit
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: '$e');
    }
  }

  /// Final “checkout”/finalize action (you can decide what it means).
  Future<void> finalizeOrder() async {
    try {
      state = state.copyWith(isSubmitting: true, clearError: true);

      // TODO: call your API to finalize all submitted orders or the latest one
      // await OrderRepo().finalize(...);

      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: '$e');
    }
  }
}

final orderViewModelProvider =
    NotifierProvider<OrderViewModel, OrderState>(() => OrderViewModel());
