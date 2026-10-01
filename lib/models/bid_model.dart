import 'user_model.dart';

class BidModel {
  final int bidId;
  final int jobPostId;
  final int workerId;
  final double? proposedPrice;
  final String? message;
  final String? estimatedDuration;
  final String status; // 'pending','accepted','rejected','withdrawn'
  final DateTime? createdAt;
  final UserModel? worker;

  BidModel({
    required this.bidId,
    required this.jobPostId,
    required this.workerId,
    this.proposedPrice,
    this.message,
    this.estimatedDuration,
    this.status = 'pending',
    this.createdAt,
    this.worker,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';

  String get formattedPrice => proposedPrice != null ? '₱${proposedPrice!.toStringAsFixed(2)}' : 'Negotiable';

  factory BidModel.fromMap(Map<String, dynamic> map, {UserModel? worker}) {
    return BidModel(
      bidId: map['bid_id'] is int ? map['bid_id'] : int.tryParse(map['bid_id'].toString()) ?? 0,
      jobPostId: map['job_post_id'] is int ? map['job_post_id'] : int.tryParse(map['job_post_id'].toString()) ?? 0,
      workerId: map['worker_id'] is int ? map['worker_id'] : int.tryParse(map['worker_id'].toString()) ?? 0,
      proposedPrice: map['proposed_price'] != null ? double.tryParse(map['proposed_price'].toString()) : null,
      message: map['message']?.toString(),
      estimatedDuration: map['estimated_duration']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      worker: worker,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bid_id': bidId,
      'job_post_id': jobPostId,
      'worker_id': workerId,
      'proposed_price': proposedPrice,
      'message': message,
      'estimated_duration': estimatedDuration,
      'status': status,
    };
  }
}
