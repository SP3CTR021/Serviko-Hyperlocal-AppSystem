import 'user_model.dart';

class BookingModel {
  final int bookingId;
  final int customerId;
  final int workerId;
  final int? workerServiceId;
  final int? categoryId;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String? serviceAddress;
  final String? jobDescription;
  final String status; // 'pending','accepted','in_progress','completed','cancelled'
  final bool isUrgent;
  final String? cancellationReason;
  final String? cancelledBy;
  final double? totalAmount;
  final DateTime? createdAt;
  final UserModel? customer;
  final UserModel? worker;
  final String? serviceName;
  final String? categoryName;

  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime? completedAt;
  final String? completionNotes;
  final int? rating;
  final String? reviewComment;
  final double? commissionRate;
  final double? commissionAmount;
  final double? netAmount;

  BookingModel({
    required this.bookingId,
    required this.customerId,
    required this.workerId,
    this.workerServiceId,
    this.categoryId,
    this.scheduledDate,
    this.scheduledTime,
    this.serviceAddress,
    this.jobDescription,
    this.status = 'pending',
    this.isUrgent = false,
    this.cancellationReason,
    this.cancelledBy,
    this.totalAmount,
    this.createdAt,
    this.customer,
    this.worker,
    this.serviceName,
    this.categoryName,
    this.paymentMethod,
    this.paymentStatus,
    this.completedAt,
    this.completionNotes,
    this.rating,
    this.reviewComment,
    this.commissionRate,
    this.commissionAmount,
    this.netAmount,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get formattedDate {
    if (scheduledDate == null) return 'Flexible date';
    return '${scheduledDate!.year}-${scheduledDate!.month.toString().padLeft(2, '0')}-${scheduledDate!.day.toString().padLeft(2, '0')}';
  }

  String get formattedTotal => totalAmount != null ? '₱${totalAmount!.toStringAsFixed(2)}' : 'TBD';

  factory BookingModel.fromMap(Map<String, dynamic> map, {UserModel? customer, UserModel? worker, String? serviceName, String? categoryName}) {
    return BookingModel(
      bookingId: map['booking_id'] is int ? map['booking_id'] : int.tryParse(map['booking_id'].toString()) ?? 0,
      customerId: map['customer_id'] is int ? map['customer_id'] : int.tryParse(map['customer_id'].toString()) ?? 0,
      workerId: map['worker_id'] is int ? map['worker_id'] : int.tryParse(map['worker_id'].toString()) ?? 0,
      workerServiceId: map['worker_service_id'] != null ? int.tryParse(map['worker_service_id'].toString()) : null,
      categoryId: map['category_id'] != null ? int.tryParse(map['category_id'].toString()) : null,
      scheduledDate: map['scheduled_date'] != null ? DateTime.tryParse(map['scheduled_date'].toString()) : null,
      scheduledTime: map['scheduled_time']?.toString(),
      serviceAddress: map['service_address']?.toString(),
      jobDescription: map['job_description']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      isUrgent: map['is_urgent'] == 1 || map['is_urgent'] == true,
      cancellationReason: map['cancellation_reason']?.toString(),
      cancelledBy: map['cancelled_by']?.toString(),
      totalAmount: map['total_amount'] != null ? double.tryParse(map['total_amount'].toString()) : null,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      customer: customer,
      worker: worker,
      serviceName: serviceName ?? map['service_name']?.toString(),
      categoryName: categoryName ?? map['category_name']?.toString(),
      paymentMethod: map['payment_method']?.toString(),
      paymentStatus: map['payment_status']?.toString(),
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'].toString()) : null,
      completionNotes: map['completion_notes']?.toString(),
      rating: map['rating'] is int ? map['rating'] : int.tryParse(map['rating']?.toString() ?? ''),
      reviewComment: map['review_comment']?.toString(),
      commissionRate: map['commission_rate'] != null ? double.tryParse(map['commission_rate'].toString()) : null,
      commissionAmount: map['commission_amount'] != null ? double.tryParse(map['commission_amount'].toString()) : null,
      netAmount: map['net_amount'] != null ? double.tryParse(map['net_amount'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'customer_id': customerId,
      'worker_id': workerId,
      'worker_service_id': workerServiceId,
      'category_id': categoryId,
      'scheduled_date': scheduledDate != null ? '${scheduledDate!.year}-${scheduledDate!.month.toString().padLeft(2, '0')}-${scheduledDate!.day.toString().padLeft(2, '0')}' : null,
      'scheduled_time': scheduledTime,
      'service_address': serviceAddress,
      'job_description': jobDescription,
      'status': status,
      'is_urgent': isUrgent ? 1 : 0,
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'completed_at': completedAt?.toIso8601String(),
      'completion_notes': completionNotes,
      'rating': rating,
      'review_comment': reviewComment,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'net_amount': netAmount,
    };
  }
}
