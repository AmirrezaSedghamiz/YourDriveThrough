import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserInfo {
  String? image;
  String? username;
  UserInfo({
    this.image,
    this.username,
  });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'image': image,
      'username': username,
    };
  }

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      image: map['image'] != null ? map['image'] as String : null,
      username: map['phone'] != null ? map['phone'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserInfo.fromJson(String source) => UserInfo.fromMap(json.decode(source) as Map<String, dynamic>);
}
