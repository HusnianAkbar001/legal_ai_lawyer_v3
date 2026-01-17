import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/media_url.dart';

part 'lawyer_model.g.dart';

@JsonSerializable()
class Lawyer {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String specialization;
  final String? city;
  final String? experience;
  final double rating;
  final int reviewsCount;
  final String? imageUrl;
  final bool isVerified;
  final String? bio;

  Lawyer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.specialization,
    this.city,
    this.experience,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.imageUrl,
    this.isVerified = false,
    this.bio,
  });

  factory Lawyer.fromJson(Map<String, dynamic> json) => _$LawyerFromJson(json);
  Map<String, dynamic> toJson() => _$LawyerToJson(this);

  factory Lawyer.fromApi(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['fullName'] ?? '').toString();
    final category = (json['category'] ?? json['specialization'] ?? '').toString();
    final rawImage = json['profilePicturePath'] ?? json['imageUrl'];
    final imageUrl = rawImage is String ? resolveMediaUrl(rawImage) : null;
    return Lawyer(
      id: json['id'] as int,
      name: name,
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] as String?) ?? '',
      specialization: category.isEmpty ? 'General' : category,
      city: (json['city'] as String?) ?? '',
      experience: (json['experience'] as String?),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (json['reviewsCount'] as int?) ?? 0,
      imageUrl: imageUrl,
      isVerified: (json['isVerified'] as bool?) ?? (json['isActive'] as bool?) ?? true,
      bio: (json['bio'] as String?),
    );
  }
}
