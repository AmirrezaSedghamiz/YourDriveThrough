import 'dart:async';
import 'dart:math';

import 'package:application/MainProgram/Customer/MainPage/MainPageState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:application/SourceDesign/Enums/OrderStatus.dart';
import 'package:application/SourceDesign/Models/Order.dart';
import 'package:application/SourceDesign/Models/ItemOrder.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart';

class CustomerHomeViewModel extends Notifier<CustomerHomeState> {
  static const _firstPageKey = 1;
  static const _pageSize = 8;

  Timer? _debounce;

  /// Recommended paging controller (horizontal list)
  final PagingController<int, RestaurantInfo> recommendedPagingController =
      PagingController(firstPageKey: _firstPageKey);

  /// Search paging controller (horizontal list)
  final PagingController<int, RestaurantInfo> searchPagingController =
      PagingController(firstPageKey: _firstPageKey);

  @override
  CustomerHomeState build() {
    // Hook page request listeners ONCE
    recommendedPagingController.addPageRequestListener(_fetchRecommendedPage);
    searchPagingController.addPageRequestListener(_fetchSearchPage);

    ref.onDispose(() {
      _debounce?.cancel();
      recommendedPagingController.dispose();
      searchPagingController.dispose();
    });

    return const CustomerHomeState();
  }

  Future<void> initIfNeeded() async {
    if (state.initialized) return;
    state = state.copyWith(initialized: true);

    // initial loads
    refreshRecommended();
    await refreshOrders();
  }

  // ------------------------
  // Refresh actions
  // ------------------------

  Future<void> refreshAll() async {
    refreshRecommended();
    await refreshOrders();
    if (state.showSearchResults) {
      refreshSearch();
    }
  }

  void refreshRecommended() {
    recommendedPagingController.refresh();
  }

  void refreshSearch() {
    if (!state.showSearchResults) return;
    searchPagingController.refresh();
  }

  // ------------------------
  // Search query handling
  // ------------------------

  void setSearchQuery(String v) {
    state = state.copyWith(searchQuery: v);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = state.searchQuery.trim();
      if (q.isEmpty) {
        // requirement: show nothing if empty
        searchPagingController.itemList = [];
        searchPagingController.error = null;
        return;
      }
      searchPagingController.refresh();
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    state = state.copyWith(searchQuery: "");
    searchPagingController.itemList = [];
    searchPagingController.error = null;
  }

  // ------------------------
  // Orders + receive
  // ------------------------

  Future<void> refreshOrders() async {
    state = state.copyWith(ordersLoading: true, clearOrdersError: true);

    try {
      await Future.delayed(const Duration(milliseconds: 450));
      state = state.copyWith(ordersLoading: false, orders: _mockOrders());
    } catch (e) {
      state = state.copyWith(ordersLoading: false, ordersError: "$e");
    }
  }

  Future<void> markReceived(int orderId) async {
    state = state.copyWith(workingOrderId: orderId, clearOrdersError: true);

    try {
      await Future.delayed(const Duration(milliseconds: 350));
      final updated = state.orders.map((o) {
        if (o.id != orderId) return o;
        if (o.status != OrderStatus.done) return o;

        // rebuild (no copyWith assumptions)
        return Order(
          id: o.id,
          customerId: o.customerId,
          restaurantId: o.restaurantId,
          customerPhone: o.customerPhone,
          restaurantName: o.restaurantName,
          status: OrderStatus.recieved,
          createdAt: o.createdAt,
          expectedDuration: o.expectedDuration,
          total: o.total,
          items: o.items,
        );
      }).toList(growable: false);

      state = state.copyWith(orders: updated, clearWorkingOrder: true);
    } catch (e) {
      state = state.copyWith(clearWorkingOrder: true, ordersError: "$e");
    }
  }

  // ------------------------
  // Paging fetchers (mock now)
  // Replace these with your backend later
  // ------------------------

  Future<void> _fetchRecommendedPage(int pageKey) async {
    try {
      await Future.delayed(const Duration(milliseconds: 450));
      final newItems = _mockRestaurants(page: pageKey);

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        recommendedPagingController.appendLastPage(newItems);
      } else {
        recommendedPagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (e) {
      recommendedPagingController.error = e;
    }
  }

  Future<void> _fetchSearchPage(int pageKey) async {
    final q = state.searchQuery.trim();
    if (q.isEmpty) {
      // do nothing; UI shouldn't request pages when hidden
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final newItems = _mockRestaurants(page: pageKey, filter: q);

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        searchPagingController.appendLastPage(newItems);
      } else {
        searchPagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (e) {
      searchPagingController.error = e;
    }
  }

  // ------------------------
  // Mock data
  // ------------------------

  List<RestaurantInfo> _mockRestaurants({
    required int page,
    String? filter,
  }) {
    final rnd = Random(page * 999);
    final base = List.generate(_pageSize, (i) {
      final id = page * 100 + i;
      final name = page.isEven ? "Burger Haven $id" : "The Beef Joint $id";
      return RestaurantInfo(
        id: id,
        name: name,
        address: "Main Street",
        latitude: 0,
        longitude: 0,
        image: null,
        profileComplete: true,
        rating: num.parse((4 + rnd.nextDouble()).toStringAsFixed(1)),
        isOpen: rnd.nextBool(),
      );
    });

    if (filter == null || filter.trim().isEmpty) return base;

    return base
        .where((r) => r.name.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  List<Order> _mockOrders() {
    return [
      Order(
        id: 101,
        restaurantName: "Burger Haven",
        status: OrderStatus.done,
        createdAt: DateTime.now(),
        expectedDuration: 20,
        total: 25,
        items: [
          ItemOrder(
            id: 1,
            itemName: "Classic Burger",
            quantity: 2,
            special: "",
          ),
        ],
      ),
      Order(
        id: 102,
        restaurantName: "The Beef Joint",
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        expectedDuration: 30,
        total: 18,
        items: [
          ItemOrder(
            id: 2,
            itemName: "Fries",
            quantity: 1,
            special: "",
          ),
        ],
      ),
    ];
  }
}

final customerHomeProvider =
    NotifierProvider<CustomerHomeViewModel, CustomerHomeState>(
  () => CustomerHomeViewModel(),
);