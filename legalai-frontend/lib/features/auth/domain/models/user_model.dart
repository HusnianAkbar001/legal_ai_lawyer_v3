import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? cnic;
  final bool isEmailVerified;
  final bool? isAdmin;
  final String? avatarPath;
  // Family info
  final String? fatherName;
  final String? fatherCnic;
  final String? motherName;
  final String? motherCnic;
  final String? city;
  final String? gender;
  final int? age;
  final int? totalSiblings;
  final int? brothers;
  final int? sisters;
  final String? timezone;
  final String? language;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.cnic,
    this.isEmailVerified = false,
    this.isAdmin,
    this.avatarPath,
    this.fatherName,
    this.fatherCnic,
    this.motherName,
    this.motherCnic,
    this.city,
    this.gender,
    this.age,
    this.totalSiblings,
    this.brothers,
    this.sisters,
    this.timezone,
    this.language,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
