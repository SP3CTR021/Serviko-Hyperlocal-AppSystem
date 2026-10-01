import 'user_model.dart';

class CustomerProfileModel {
  final int customerProfileId;
  final int userId;
  final String? initials;
  final String? avatarColor;
  final int totalBookings;
  final double totalSpent;
  final int activeBookingsCount;
  final double avgRatingAsCustomer;
  final int reviewCount;
  final String? defaultAddress;
  final UserModel? user;

  CustomerProfileModel({
    required this.customerProfileId,
    required this.userId,
    this.initials,
    this.avatarColor,
    this.totalBookings = 0,
    this.totalSpent = 0.0,
    this.activeBookingsCount = 0,
    this.avgRatingAsCustomer = 0.0,
    this.reviewCount = 0,
    this.defaultAddress,
    this.user,
  });

  factory CustomerProfileModel.fromMap(Map<String, dynamic> map, {UserModel? user}) {
    return CustomerProfileModel(
      customerProfileId: map['customer_profile_id'] is int ? map['customer_profile_id'] : int.tryParse(map['customer_profile_id'].toString()) ?? 0,
      userId: map['user_id'] is int ? map['user_id'] : int.tryParse(map['user_id'].toString()) ?? 0,
      initials: map['initials']?.toString(),
      avatarColor: map['avatar_color']?.toString(),
      totalBookings: map['total_bookings'] is int ? map['total_bookings'] : int.tryParse(map['total_bookings']?.toString() ?? '0') ?? 0,
      totalSpent: map['total_spent'] != null ? double.tryParse(map['total_spent'].toString()) ?? 0.0 : 0.0,
      activeBookingsCount: map['active_bookings_count'] is int ? map['active_bookings_count'] : int.tryParse(map['active_bookings_count']?.toString() ?? '0') ?? 0,
      avgRatingAsCustomer: map['avg_rating_as_customer'] != null ? double.tryParse(map['avg_rating_as_customer'].toString()) ?? 0.0 : 0.0,
      reviewCount: map['review_count'] is int ? map['review_count'] : int.tryParse(map['review_count']?.toString() ?? '0') ?? 0,
      defaultAddress: map['default_address']?.toString(),
      user: user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_profile_id': customerProfileId,
      'user_id': userId,
      'initials': initials,
      'avatar_color': avatarColor,
      'total_bookings': totalBookings,
      'total_spent': totalSpent,
      'active_bookings_count': activeBookingsCount,
      'avg_rating_as_customer': avgRatingAsCustomer,
      'review_count': reviewCount,
      'default_address': defaultAddress,
    };
  }
}
