// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:application/SourceDesign/Enums/OrderStatus.dart';
import 'package:application/SourceDesign/Models/Item.dart';

class Order {
  int id;
  int customerId;
  int restaurantId;
  OrderStatus status;
  DateTime createdAt;
  int expectedDuration;
  num total;
  List<ItemOrder> items;
  
  Order({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.createdAt,
    required this.expectedDuration,
    required this.total,
    required this.items,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expectedDuration': expectedDuration,
      'total': total,
      'items': items.map((x) => x.toMap()).toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      restaurantId: map['restaurant_id'] as int,
      createdAt: map['created_at'],
      expectedDuration: map['expected_duration'] as int,
      total: map['total'] as num,
      items: List<ItemOrder>.from((map['items']).map<ItemOrder>((x) => ItemOrder.fromMap(x as Map<String,dynamic>),),),
      status: OrderStatusParsing.fromString(map['status'])
    );
  }

  String toJson() => json.encode(toMap());

  factory Order.fromJson(String source) => Order.fromMap(json.decode(source) as Map<String, dynamic>);
}
