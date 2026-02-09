import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class ItemOrder {
  int id;
  String itemName;
  int quantity;
  String special;
  ItemOrder({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.special,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'itemName': itemName,
      'quantity': quantity,
      'special': special,
    };
  }

  factory ItemOrder.fromMap(Map<String, dynamic> map) {
    return ItemOrder(
      id: map['id'] as int,
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as int,
      special: map['special'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemOrder.fromJson(String source) => ItemOrder.fromMap(json.decode(source) as Map<String, dynamic>);
}
