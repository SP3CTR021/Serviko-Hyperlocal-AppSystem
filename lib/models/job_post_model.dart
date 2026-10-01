import 'bid_model.dart';
import 'user_model.dart';

class JobPostModel {
  final int jobPostId;
  final int customerId;
  final int? categoryId;
  final String? title;
  final String? description;
  final String? locationAddress;
  final String? city;
  final String? barangay;
  final double? budgetMin;
  final double? budgetMax;
  final DateTime? preferredDate;
  final String urgency; // 'flexible','this_week','urgent'
  final String status; // 'open','in_review','hired','closed'
  final DateTime? createdAt;
  final UserModel? customer;
  final String? categoryName;
  final List<BidModel> bids;

  JobPostModel({
    required this.jobPostId,
    required this.customerId,
    this.categoryId,
    this.title,
    this.description,
    this.locationAddress,
    this.city,
    this.barangay,
    this.budgetMin,
    this.budgetMax,
    this.preferredDate,
    this.urgency = 'flexible',
    this.status = 'open',
    this.createdAt,
    this.customer,
    this.categoryName,
    this.bids = const [],
  });

  bool get isOpen => status.toLowerCase() == 'open';

  String get budgetDisplay {
    if (budgetMin != null && budgetMax != null) {
      return '₱${budgetMin!.toStringAsFixed(0)} - ₱${budgetMax!.toStringAsFixed(0)}';
    } else if (budgetMin != null) {
      return 'From ₱${budgetMin!.toStringAsFixed(0)}';
    } else if (budgetMax != null) {
      return 'Up to ₱${budgetMax!.toStringAsFixed(0)}';
    }
    return 'Negotiable';
  }

  factory JobPostModel.fromMap(Map<String, dynamic> map, {UserModel? customer, String? categoryName, List<BidModel> bids = const []}) {
    return JobPostModel(
      jobPostId: map['job_post_id'] is int ? map['job_post_id'] : int.tryParse(map['job_post_id'].toString()) ?? 0,
      customerId: map['customer_id'] is int ? map['customer_id'] : int.tryParse(map['customer_id'].toString()) ?? 0,
      categoryId: map['category_id'] != null ? int.tryParse(map['category_id'].toString()) : null,
      title: map['title']?.toString(),
      description: map['description']?.toString(),
      locationAddress: map['location_address']?.toString(),
      city: map['city']?.toString(),
      barangay: map['barangay']?.toString(),
      budgetMin: map['budget_min'] != null ? double.tryParse(map['budget_min'].toString()) : null,
      budgetMax: map['budget_max'] != null ? double.tryParse(map['budget_max'].toString()) : null,
      preferredDate: map['preferred_date'] != null ? DateTime.tryParse(map['preferred_date'].toString()) : null,
      urgency: map['urgency']?.toString() ?? 'flexible',
      status: map['status']?.toString() ?? 'open',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      customer: customer,
      categoryName: categoryName ?? map['category_name']?.toString(),
      bids: bids,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'job_post_id': jobPostId,
      'customer_id': customerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'location_address': locationAddress,
      'city': city,
      'barangay': barangay,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'preferred_date': preferredDate != null ? '${preferredDate!.year}-${preferredDate!.month.toString().padLeft(2, '0')}-${preferredDate!.day.toString().padLeft(2, '0')}' : null,
      'urgency': urgency,
      'status': status,
    };
  }
}
