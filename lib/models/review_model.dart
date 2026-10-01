import 'user_model.dart';

class ReviewModel {
  final int reviewId;
  final int bookingId;
  final int reviewerId;
  final int revieweeId;
  final String reviewerRole; // 'customer','worker'
  final int rating;
  final String? comment;
  final bool isVisible;
  final DateTime? createdAt;
  final UserModel? reviewer;

  ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.reviewerRole,
    required this.rating,
    this.comment,
    this.isVisible = true,
    this.createdAt,
    this.reviewer,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, {UserModel? reviewer}) {
    return ReviewModel(
      reviewId: map['review_id'] is int ? map['review_id'] : int.tryParse(map['review_id'].toString()) ?? 0,
      bookingId: map['booking_id'] is int ? map['booking_id'] : int.tryParse(map['booking_id'].toString()) ?? 0,
      reviewerId: map['reviewer_id'] is int ? map['reviewer_id'] : int.tryParse(map['reviewer_id'].toString()) ?? 0,
      revieweeId: map['reviewee_id'] is int ? map['reviewee_id'] : int.tryParse(map['reviewee_id'].toString()) ?? 0,
      reviewerRole: map['reviewer_role']?.toString() ?? 'customer',
      rating: map['rating'] is int ? map['rating'] : int.tryParse(map['rating']?.toString() ?? '5') ?? 5,
      comment: map['comment']?.toString(),
      isVisible: map['is_visible'] == 1 || map['is_visible'] == true,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      reviewer: reviewer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'review_id': reviewId,
      'booking_id': bookingId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'reviewer_role': reviewerRole,
      'rating': rating,
      'comment': comment,
      'is_visible': isVisible ? 1 : 0,
    };
  }
}
