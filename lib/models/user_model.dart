enum UserRole { customer, worker, admin }

class UserModel {
  final int id;
  final String? uid;
  final String name;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phoneNumber;
  final String role; // 'customer', 'worker', 'admin'
  final String? skill;
  final String? profilePhotoUrl;
  final String? city;
  final String? barangay;
  final String? idType;
  final String? idNumber;
  final String? idPhotoUrl;
  final bool isVerified;
  final bool isActive;
  final DateTime? memberSince;
  final DateTime? verifiedAt;

  UserModel({
    required this.id,
    this.uid,
    required this.name,
    required this.fullName,
    this.firstName,
    this.lastName,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.skill,
    this.profilePhotoUrl,
    this.city,
    this.barangay,
    this.idType,
    this.idNumber,
    this.idPhotoUrl,
    this.isVerified = false,
    this.isActive = true,
    this.memberSince,
    this.verifiedAt,
  });

  bool get isWorker => role.toLowerCase() == 'worker';
  bool get isCustomer => role.toLowerCase() == 'customer';
  bool get isAdmin => role.toLowerCase() == 'admin';

  String get displayName => fullName.isNotEmpty ? fullName : name;

  int get profileCompletionPercentage {
    if (isVerified) return 100;
    int progress = 30; // Base: Name + Email
    if (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty) progress += 15;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) progress += 15;
    if ((city != null && city!.isNotEmpty) || (barangay != null && barangay!.isNotEmpty)) progress += 15;
    if (idPhotoUrl != null || (idNumber != null && idNumber!.isNotEmpty)) progress += 25;
    return progress.clamp(0, 100);
  }

  bool get isProfileComplete => isVerified || profileCompletionPercentage >= 100;

  String get locationString {
    if (barangay != null && city != null) return '$barangay, $city';
    if (city != null) return city!;
    if (barangay != null) return barangay!;
    return 'Location not set';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      uid: map['uid']?.toString(),
      name: map['name']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? map['name']?.toString() ?? '',
      firstName: map['first_name']?.toString(),
      lastName: map['last_name']?.toString(),
      email: map['email']?.toString() ?? '',
      phoneNumber: map['phone_number']?.toString(),
      role: map['role']?.toString() ?? 'customer',
      skill: map['skill']?.toString(),
      profilePhotoUrl: map['profile_photo_url']?.toString() ??
          map['profilePhotoUrl']?.toString() ??
          map['photo_url']?.toString() ??
          map['photoUrl']?.toString(),
      city: map['city']?.toString(),
      barangay: map['barangay']?.toString(),
      idType: map['id_type']?.toString(),
      idNumber: map['id_number']?.toString(),
      idPhotoUrl: map['id_photo_url']?.toString(),
      isVerified: map['is_verified'] == 1 || map['is_verified'] == true,
      isActive: map['is_active'] == 1 || map['is_active'] == true || map['is_active'] == null,
      memberSince: map['member_since'] != null ? DateTime.tryParse(map['member_since'].toString()) : null,
      verifiedAt: map['verified_at'] != null ? DateTime.tryParse(map['verified_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (uid != null) 'uid': uid,
      'name': name,
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'skill': skill,
      'profile_photo_url': profilePhotoUrl,
      'city': city,
      'barangay': barangay,
      if (idType != null) 'id_type': idType,
      if (idNumber != null) 'id_number': idNumber,
      if (idPhotoUrl != null) 'id_photo_url': idPhotoUrl,
      'is_verified': isVerified ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'member_since': memberSince?.toIso8601String(),
      if (verifiedAt != null) 'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? uid,
    String? name,
    String? fullName,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? role,
    String? skill,
    String? profilePhotoUrl,
    String? city,
    String? barangay,
    String? idType,
    String? idNumber,
    String? idPhotoUrl,
    bool? isVerified,
    bool? isActive,
    DateTime? memberSince,
    DateTime? verifiedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      skill: skill ?? this.skill,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      city: city ?? this.city,
      barangay: barangay ?? this.barangay,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      idPhotoUrl: idPhotoUrl ?? this.idPhotoUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      memberSince: memberSince ?? this.memberSince,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
