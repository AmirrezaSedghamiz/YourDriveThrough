import 'dart:convert';
import 'package:application/SourceDesign/Models/Item.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Category {
  int id;
  String name;
  List<Item> item;

  Category({required this.id, required this.name, required this.item});

  static int _int(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static String _str(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'category': name,
      'items': item.map((x) => x.toMap()).toList(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List? ?? const []);
    return Category(
      id: _int(map['id']),
      // backend may send "category" or "name"
      name: _str(map['category'] ?? map['name']),
      // YOUR MODEL FIELD NAME IS `item`
      item: rawItems
          .map((e) => Item.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());
  factory Category.fromJson(String source) =>
      Category.fromMap(json.decode(source) as Map<String, dynamic>);
}

List<Category> categoriesFromResponse(dynamic data) {
  final decoded = (data is String) ? json.decode(data) : data;

  if (decoded is! List) return [];

  return decoded
      .map((e) => Category.fromMap(e as Map<String, dynamic>))
      .toList();
}

List<Category> categoriesFromJson(String source) {
  final decoded = json.decode(source);
  if (decoded is! List) return [];

  return decoded
      .map((e) => Category.fromMap(e as Map<String, dynamic>))
      .toList();
}
