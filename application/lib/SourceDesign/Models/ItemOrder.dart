import 'dart:convert';

class ItemOrder {
  int id;
  int? itemId;
  String itemName;
  int quantity;
  String special;
  num? price;

  ItemOrder({
    required this.id,
    this.itemId,
    required this.itemName,
    required this.quantity,
    required this.special,
    this.price,
  });

  // ---------- Normalizers ----------
  static int _int(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  static String _str(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  factory ItemOrder.fromMap(Map<String, dynamic> map) {
    return ItemOrder(
      id: _int(map['id']),
      itemId: _int(map['item'], fallback: 0),
      itemName: _str(map['item_name']),
      quantity: _int(map['quantity']),
      special: _str(map['special']),
      price: _num(map['price']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'special': special,
      'price': price,
    };
  }

  String toJson() => json.encode(toMap());
  factory ItemOrder.fromJson(String source) =>
      ItemOrder.fromMap(json.decode(source));
}
