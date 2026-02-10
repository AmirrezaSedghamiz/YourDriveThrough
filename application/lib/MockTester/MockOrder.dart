import 'dart:math';

import 'package:application/GlobalWidgets/ReusableComponents/PaginatedListContract.dart';
import 'package:application/MainProgram/Manager/PendingOrders/PendingOrders.dart';
import 'package:application/SourceDesign/Models/ItemOrder.dart';
import 'package:flutter/material.dart';
import 'package:application/SourceDesign/Models/Order.dart';
import 'package:application/SourceDesign/Enums/OrderStatus.dart';

// Import the widget you pasted earlier:
// import 'package:application/wherever/orders_paged_list.dart';

/// ---------- MOCK API ----------
/// Simulates pagination + network delay.
/// - 4 pages total
/// - 20 items per page by default
class MockOrdersApi {
  MockOrdersApi({
    this.totalPages = 4,
    this.pageSize = 20,
    this.minDelayMs = 450,
    this.maxDelayMs = 1200,
    int? seed,
  }) : _rand = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  final int totalPages;
  final int pageSize;
  final int minDelayMs;
  final int maxDelayMs;

  final Random _rand;

  Future<PageResult<Order>> fetchPage(int pageKey) async {
    // Simulate delay
    final delay = minDelayMs + _rand.nextInt(max(1, maxDelayMs - minDelayMs));
    await Future<void>.delayed(Duration(milliseconds: delay));

    // Optional: randomly throw an error for testing
    // if (_rand.nextInt(12) == 0) throw Exception("Mock network error");

    final isLast = pageKey >= totalPages;

    final items = List.generate(pageSize, (i) {
      final orderId = (pageKey - 1) * pageSize + i + 1001;
      final restaurantId = 50 + (orderId % 7);
      final customerId = 100 + (orderId % 23);

      final createdAt = DateTime.now().subtract(
        Duration(minutes: _rand.nextInt(90) + 1),
      );

      final expected = 10 + _rand.nextInt(30);
      final total = 5 + _rand.nextInt(40);

      final orderItems = _mockItems(orderId);

      return Order(
        id: orderId,
        customerId: customerId,
        restaurantId: restaurantId,
        createdAt: createdAt,
        expectedDuration: expected,
        total: total,
        items: orderItems,
        status: OrderStatus.pending,
      );
    });

    return PageResult<Order>(items: items, isLastPage: isLast);
  }

  List<ItemOrder> _mockItems(int orderId) {
    final menu = <String>[
      "Classic Burger",
      "Large Fries",
      "Cola",
      "Pizza Slice",
      "Chicken Wrap",
      "Salad",
      "Ice Cream",
      "Coffee",
    ];

    final count = 2 + _rand.nextInt(4); // 2..5 items
    final picked = <ItemOrder>[];

    for (var i = 0; i < count; i++) {
      final name = menu[_rand.nextInt(menu.length)];
      final qty = 1 + _rand.nextInt(3);

      // Some items have special notes, some don't
      final hasNote = _rand.nextBool();
      final note = hasNote
          ? _randNoteFor(name)
          : "";

      picked.add(
        ItemOrder(
          id: orderId * 10 + i,
          itemName: name,
          quantity: qty,
          special: note,
        ),
      );
    }
    return picked;
  }

  String _randNoteFor(String itemName) {
    final notes = <String>[
      "extra crispy",
      "no ice",
      "no salt",
      "extra sauce",
      "well done",
      "no onions",
      "less spicy",
    ];
    // Create something like: "fries : extra crispy"
    // Your widget formats it per-item anyway; special is just the message.
    return notes[_rand.nextInt(notes.length)];
  }

  Future<void> accept(int orderId) async {
    await Future<void>.delayed(Duration(milliseconds: 250 + _rand.nextInt(500)));
    // Uncomment to simulate occasional failure:
    // if (_rand.nextInt(10) == 0) throw Exception("Mock accept failed");
  }

  Future<void> decline(int orderId) async {
    await Future<void>.delayed(Duration(milliseconds: 250 + _rand.nextInt(500)));
    // Uncomment to simulate occasional failure:
    // if (_rand.nextInt(10) == 0) throw Exception("Mock decline failed");
  }
}