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

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int,
      name: map['name'] as String,
      image: map['image'] != null ? map['image'] as String : null,
      expectedDuration: map['expectedDuration'] as num,
      price: map['price'] as num,
      description: map['description'] != null ? map['description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) => Item.fromMap(json.decode(source) as Map<String, dynamic>);
}
