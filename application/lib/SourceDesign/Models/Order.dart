import 'dart:convert';

import 'package:application/SourceDesign/Enums/OrderStatus.dart';
import 'package:application/SourceDesign/Models/ItemOrder.dart';

class Order {
  int id;

  int? customerId;
  int? restaurantId;

  String? customerPhone;
  String? restaurantName;

  OrderStatus status;
  DateTime createdAt;
  int expectedDuration;
  num total;
  List<ItemOrder> items;

  Order({
    required this.id,
    this.customerId,
    this.restaurantId,
    this.customerPhone,
    this.restaurantName,
    required this.status,
    required this.createdAt,
    required this.expectedDuration,
    required this.total,
    required this.items,
  });

  // ---------- Normalizers ----------
  static int _int(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static num _num(dynamic v, {num fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? fallback;
    return fallback;
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    return v.toString();
  }

  static DateTime _date(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    print("${map['id']} : ${map['status']}");
    return Order(
      id: _int(map['id']),
      customerId: _int(map['customer_id'], fallback: 0),
      restaurantId: _int(map['restaurant_id'], fallback: 0),
      customerPhone: _str(map['customer_phone']),
      restaurantName: _str(map['restaurant_name']),
      status: OrderStatusParsing.from(
        map['status']?.toString() ?? 'failed',
      ),
      createdAt: _date(map['start'] ?? map['created_at']),
      expectedDuration: _int(map['expected_duration']),
      total: _num(map['total']),
      items: (map['items'] as List? ?? [])
          .map((e) => ItemOrder.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'restaurant_id': restaurantId,
      'customer_phone': customerPhone,
      'restaurant_name': restaurantName,
      'status': status.name,
      'start': createdAt.toIso8601String(),
      'expected_duration': expectedDuration,
      'total': total,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());
  factory Order.fromJson(String source) =>
      Order.fromMap(json.decode(source));
}
