import 'user_model.dart';
import 'worker_service_model.dart';

class WorkerProfileModel {
  final int workerProfileId;
  final int userId;
  final String? initials;
  final String? avatarColor;
  final String? bio;
  final String? primarySkill;
  final int yearsOfExperience;
  final double? serviceRadiusKm;
  final double? basePrice;
  final String? priceType; // 'hour','day','session','unit','home','negotiable'
  final String availabilityStatus; // 'available','busy','inactive'
  final double avgRating;
  final int totalJobsCompleted;
  final double completionRate;
  final bool isIdVerified;
  final String? idType;
  final String? profilePhotoUrl;
  final UserModel? user;
  final List<WorkerServiceModel> services;

  String? get photoUrl => profilePhotoUrl ?? user?.profilePhotoUrl;

  WorkerProfileModel({
    required this.workerProfileId,
    required this.userId,
    this.initials,
    this.avatarColor,
    this.bio,
    this.primarySkill,
    this.yearsOfExperience = 0,
    this.serviceRadiusKm,
    this.basePrice,
    this.priceType,
    this.availabilityStatus = 'available',
    this.avgRating = 0.0,
    this.totalJobsCompleted = 0,
    this.completionRate = 0.0,
    this.isIdVerified = false,
    this.idType,
    this.profilePhotoUrl,
    this.user,
    this.services = const [],
  });

  String get formattedPrice {
    if (basePrice == null || basePrice == 0) return 'Negotiable';
    String unit = '';
    if (priceType != null && priceType != 'negotiable') {
      String pt = priceType!.toLowerCase();
      if (pt == 'oras' || pt == 'hour' || pt == 'hr') {
        pt = 'hr';
      } else if (pt == 'araw' || pt == 'day') {
        pt = 'day';
      } else if (pt == 'bahay' || pt == 'home' || pt == 'house') {
        pt = 'home';
      }
      unit = '/$pt';
    }
    return '₱${basePrice!.toStringAsFixed(0)}$unit';
  }

  bool get isAvailable => availabilityStatus.toLowerCase() == 'available';

  factory WorkerProfileModel.fromMap(Map<String, dynamic> map, {UserModel? user, List<WorkerServiceModel> services = const []}) {
    return WorkerProfileModel(
      workerProfileId: map['worker_profile_id'] is int ? map['worker_profile_id'] : int.tryParse(map['worker_profile_id'].toString()) ?? 0,
      userId: map['user_id'] is int ? map['user_id'] : int.tryParse(map['user_id'].toString()) ?? 0,
      initials: map['initials']?.toString(),
      avatarColor: map['avatar_color']?.toString(),
      bio: map['bio']?.toString(),
      primarySkill: map['primary_skill']?.toString(),
      yearsOfExperience: map['years_of_experience'] is int ? map['years_of_experience'] : int.tryParse(map['years_of_experience']?.toString() ?? '0') ?? 0,
      serviceRadiusKm: map['service_radius_km'] != null ? double.tryParse(map['service_radius_km'].toString()) : null,
      basePrice: map['base_price'] != null ? double.tryParse(map['base_price'].toString()) : null,
      priceType: map['price_type']?.toString(),
      availabilityStatus: map['availability_status']?.toString() ?? 'available',
      avgRating: map['avg_rating'] != null ? double.tryParse(map['avg_rating'].toString()) ?? 0.0 : 0.0,
      totalJobsCompleted: map['total_jobs_completed'] is int ? map['total_jobs_completed'] : int.tryParse(map['total_jobs_completed']?.toString() ?? '0') ?? 0,
      completionRate: map['completion_rate'] != null ? double.tryParse(map['completion_rate'].toString()) ?? 0.0 : 0.0,
      isIdVerified: map['is_id_verified'] == 1 || map['is_id_verified'] == true,
      idType: map['id_type']?.toString(),
      profilePhotoUrl: map['profile_photo_url']?.toString() ??
          map['profilePhotoUrl']?.toString() ??
          map['photo_url']?.toString() ??
          map['photoUrl']?.toString() ??
          user?.profilePhotoUrl,
      user: user,
      services: services,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'worker_profile_id': workerProfileId,
      'user_id': userId,
      'initials': initials,
      'avatar_color': avatarColor,
      'bio': bio,
      'primary_skill': primarySkill,
      'years_of_experience': yearsOfExperience,
      'service_radius_km': serviceRadiusKm,
      'base_price': basePrice,
      'price_type': priceType,
      'availability_status': availabilityStatus,
      'avg_rating': avgRating,
      'total_jobs_completed': totalJobsCompleted,
      'completion_rate': completionRate,
      'is_id_verified': isIdVerified ? 1 : 0,
      'id_type': idType,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
    };
  }
}
