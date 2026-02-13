import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Item {
  int id;
  String name;
  String? image;
  num expectedDuration;
  num price;
  String? description;
  Item({
    required this.id,
    required this.name,
    this.image,
    required this.expectedDuration,
    required this.price,
    this.description,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'image': image,
      'expectedDuration': expectedDuration,
      'price': price,
      'description': description,
    };
  }

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

  static String? _str(dynamic v) => v?.toString();


  /// ✅ parses API map
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: _int(map['id']),
      name: _str(map['name']) ?? '',
      image: _str(map['image']),
      expectedDuration: _num(map['expected_duration']),
      price: _num(map['price']),
      description: _str(map['description']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) => Item.fromMap(json.decode(source) as Map<String, dynamic>);

  Item copyWith({
    int? id,
    String? name,
    String? image,
    num? expectedDuration,
    num? price,
    String? description,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      expectedDuration: expectedDuration ?? this.expectedDuration,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }
}
