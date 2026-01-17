// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lawyer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lawyer _$LawyerFromJson(Map<String, dynamic> json) => Lawyer(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  specialization: json['specialization'] as String,
  city: json['city'] as String?,
  experience: json['experience'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
  imageUrl: json['imageUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  bio: json['bio'] as String?,
);

Map<String, dynamic> _$LawyerToJson(Lawyer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'specialization': instance.specialization,
  'city': instance.city,
  'experience': instance.experience,
  'rating': instance.rating,
  'reviewsCount': instance.reviewsCount,
  'imageUrl': instance.imageUrl,
  'isVerified': instance.isVerified,
  'bio': instance.bio,
};
