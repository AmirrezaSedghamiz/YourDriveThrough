import 'package:application/SourceDesign/Models/Item.dart';

class OrderLine {
  final Item item;
  final int qty;

  const OrderLine({required this.item, required this.qty});

  num get lineTotal => item.price * qty;

  OrderLine copyWith({Item? item, int? qty}) =>
      OrderLine(item: item ?? this.item, qty: qty ?? this.qty);
}

class SubmittedOrder {
  final DateTime createdAt;
  final int restaurantId;
  final String restaurantName;
  final List<OrderLine> lines;

  const SubmittedOrder({
    required this.createdAt,
    required this.restaurantId,
    required this.restaurantName,
    required this.lines,
  });

  num get total =>
      lines.fold<num>(0, (sum, l) => sum + l.lineTotal);
}

class OrderState {
  final List<OrderLine> draftLines;          // current “cart”
  final List<SubmittedOrder> submittedOrders; // history
  final bool isSubmitting;
  final String? error;

  const OrderState({
    this.draftLines = const [],
    this.submittedOrders = const [],
    this.isSubmitting = false,
    this.error,
  });

  num get draftTotal =>
      draftLines.fold<num>(0, (sum, l) => sum + l.lineTotal);

  OrderState copyWith({
    List<OrderLine>? draftLines,
    List<SubmittedOrder>? submittedOrders,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return OrderState(
      draftLines: draftLines ?? this.draftLines,
      submittedOrders: submittedOrders ?? this.submittedOrders,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
