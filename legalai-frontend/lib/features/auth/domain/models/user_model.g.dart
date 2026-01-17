// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  cnic: json['cnic'] as String?,
  isEmailVerified: json['isEmailVerified'] as bool? ?? false,
  isAdmin: json['isAdmin'] as bool?,
  avatarPath: json['avatarPath'] as String?,
  fatherName: json['fatherName'] as String?,
  fatherCnic: json['fatherCnic'] as String?,
  motherName: json['motherName'] as String?,
  motherCnic: json['motherCnic'] as String?,
  city: json['city'] as String?,
  gender: json['gender'] as String?,
  age: (json['age'] as num?)?.toInt(),
  totalSiblings: (json['totalSiblings'] as num?)?.toInt(),
  brothers: (json['brothers'] as num?)?.toInt(),
  sisters: (json['sisters'] as num?)?.toInt(),
  timezone: json['timezone'] as String?,
  language: json['language'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'cnic': instance.cnic,
  'isEmailVerified': instance.isEmailVerified,
  'isAdmin': instance.isAdmin,
  'avatarPath': instance.avatarPath,
  'fatherName': instance.fatherName,
  'fatherCnic': instance.fatherCnic,
  'motherName': instance.motherName,
  'motherCnic': instance.motherCnic,
  'city': instance.city,
  'gender': instance.gender,
  'age': instance.age,
  'totalSiblings': instance.totalSiblings,
  'brothers': instance.brothers,
  'sisters': instance.sisters,
  'timezone': instance.timezone,
  'language': instance.language,
};
