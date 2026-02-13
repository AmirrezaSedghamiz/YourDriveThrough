import 'package:application/SourceDesign/Models/Order.dart';

class CustomerHomeState {
  final String searchQuery;

  final List<Order> orders;
  final bool ordersLoading;
  final int? workingOrderId;
  final String? ordersError;

  final bool initialized;

  const CustomerHomeState({
    this.searchQuery = "",
    this.orders = const [],
    this.ordersLoading = false,
    this.workingOrderId,
    this.ordersError,
    this.initialized = false,
  });

  bool get showSearchResults => searchQuery.trim().isNotEmpty;

  CustomerHomeState copyWith({
    String? searchQuery,
    List<Order>? orders,
    bool? ordersLoading,
    int? workingOrderId,
    bool clearWorkingOrder = false,
    String? ordersError,
    bool clearOrdersError = false,
    bool? initialized,
    bool? showSearchResults
  }) {
    return CustomerHomeState(
      searchQuery: searchQuery ?? this.searchQuery,
      orders: orders ?? this.orders,
      ordersLoading: ordersLoading ?? this.ordersLoading,
      workingOrderId:
          clearWorkingOrder ? null : (workingOrderId ?? this.workingOrderId),
      ordersError: clearOrdersError ? null : (ordersError ?? this.ordersError),
      initialized: initialized ?? this.initialized,
    );
  }
}