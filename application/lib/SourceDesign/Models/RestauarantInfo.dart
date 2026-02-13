import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class RestaurantInfo {
  int? id;
  String name;
  String address;
  num latitude;
  num longitude;
  num? duration;

  String? image;
  bool profileComplete;
  num? rating;
  bool isOpen;

  RestaurantInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.image,
    this.duration,
    required this.profileComplete,
    required this.rating,
    required this.isOpen,
  });

  RestaurantInfo copyWith({
    int? id,
    String? name,
    String? address,
    num? latitude,
    num? rating,
    num? longitude,
    String? image,
    bool? profileComplete,
    bool? isOpen,
  }) {
    return RestaurantInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      image: image ?? this.image,
      profileComplete: profileComplete ?? this.profileComplete,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  factory RestaurantInfo.fromMap(Map<String, dynamic> map) {
    return RestaurantInfo(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      latitude: _parseNum(map['latitude']),
      longitude: _parseNum(map['longitude']),
      image: map['image'] != null ? map['image'] as String : null,
      profileComplete: map['profile_complete'],
      rating: _parseNum(map['average_rating']),
      isOpen: map['is_open'],
      duration: map['duration_seconds'],
      
    );
  }

  factory RestaurantInfo.fromJson(String source) =>
      RestaurantInfo.fromMap(json.decode(source) as Map<String, dynamic>);
}

num _parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}
