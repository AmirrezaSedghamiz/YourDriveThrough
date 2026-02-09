import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class RestaurantInfo {
  int id;
  String name;
  String address;
  num latitiude;
  num longitude;
  String? image;
  bool profileComplete;
  num rating;

  RestaurantInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitiude,
    required this.longitude,
    this.image,
    required this.profileComplete,
    required this.rating,
  });

  RestaurantInfo copyWith({
    int? id,
    String? name,
    String? address,
    num? latitiude,
    num? rating,
    num? logitude,
    String? image,
    bool? profileComplete,
  }) {
    return RestaurantInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitiude: latitiude ?? this.latitiude,
      longitude: logitude ?? this.longitude,
      image: image ?? this.image,
      profileComplete: profileComplete ?? this.profileComplete,
      rating: rating ?? this.rating,
    );
  }

  factory RestaurantInfo.fromMap(Map<String, dynamic> map) {
    return RestaurantInfo(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      latitiude: map['latitiude'],
      longitude: map['logitude'],
      image: map['image'] != null ? map['image'] as String : null,
      profileComplete: map['profile_complete'],
      rating: map['rating'],
    );
  }

  factory RestaurantInfo.fromJson(String source) =>
      RestaurantInfo.fromMap(json.decode(source) as Map<String, dynamic>);
}
