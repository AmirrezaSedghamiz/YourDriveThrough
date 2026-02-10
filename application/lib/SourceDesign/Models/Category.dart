// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:application/SourceDesign/Models/Item.dart';

class Category {
  int id;
  String name;
  List<Item> item;
  Category({
    required this.id,
    required this.name,
    required this.item,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'item': item.map((x) => x.toMap()).toList(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
      item: List<Item>.from((map['item'] as List<int>).map<Item>((x) => Item.fromMap(x as Map<String,dynamic>),),),
    );
  }

  String toJson() => json.encode(toMap());

  factory Category.fromJson(String source) => Category.fromMap(json.decode(source) as Map<String, dynamic>);
}
