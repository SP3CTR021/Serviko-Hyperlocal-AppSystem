import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/database_seeder.dart';
import '../data/sample_data.dart';
import '../models/service_category_model.dart';
import '../models/worker_profile_model.dart';
import '../models/booking_model.dart';
import '../models/job_post_model.dart';
import '../models/bid_model.dart';
import '../models/message_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

class FirestoreService extends ChangeNotifier {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCol => _firestore.collection('users');
  CollectionReference get _categoriesCol => _firestore.collection('categories');
  CollectionReference get _workersCol => _firestore.collection('workers');
  CollectionReference get _bookingsCol => _firestore.collection('bookings');
  CollectionReference get _jobPostsCol => _firestore.collection('job_posts');
  CollectionReference get _messagesCol => _firestore.collection('messages');
  CollectionReference get _bidsCol => _firestore.collection('bids');
  CollectionReference get _reviewsCol => _firestore.collection('reviews');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Firestore service.
  /// Seeding is commented out for clean slate testing.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // -------------------------------------------------------------
      // SEEDER: COMMENTED OUT TO MAINTAIN A CLEAN SLATE FOR TESTING.
      // To seed sample data into Firestore, uncomment the line below:
      // -------------------------------------------------------------
      // await DatabaseSeeder.seedAll();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[FirestoreService] initialize note: $e');
    }
  }

  /// Automatically seeds initial categories, workers, and sample data to Firestore
  /// (Kept available for manual execution or future use)
  Future<void> seedInitialDataIfEmpty() async {
    await DatabaseSeeder.seedAll();
  }

  // -------------------------------------------------------------
  // CATEGORIES CRUD
  // -------------------------------------------------------------
  Stream<List<ServiceCategoryModel>> getCategoriesStream() {
    return _categoriesCol
        .orderBy('display_order', descending: false)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return [];
      return snap.docs
          .map((d) => ServiceCategoryModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<ServiceCategoryModel>> getCategories() async {
    try {
      final snap = await _categoriesCol.orderBy('display_order').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((d) => ServiceCategoryModel.fromMap(d.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getCategories note: $e');
    }
    return [];
  }

  // -------------------------------------------------------------
  // WORKERS CRUD
  // -------------------------------------------------------------
  Stream<List<WorkerProfileModel>> getWorkersStream() {
    return _workersCol.snapshots().map((snap) {
      if (snap.docs.isEmpty) return [];
      return snap.docs.map((d) {
        final map = d.data() as Map<String, dynamic>;
        UserModel? user;
        if (map['user'] != null && map['user'] is Map<String, dynamic>) {
          user = UserModel.fromMap(map['user'] as Map<String, dynamic>);
        }
        return WorkerProfileModel.fromMap(map, user: user);
      }).toList();
    });
  }

  Future<List<WorkerProfileModel>> getWorkers() async {
    try {
      final snap = await _workersCol.get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) {
          final map = d.data() as Map<String, dynamic>;
          UserModel? user;
          if (map['user'] != null && map['user'] is Map<String, dynamic>) {
            user = UserModel.fromMap(map['user'] as Map<String, dynamic>);
          }
          return WorkerProfileModel.fromMap(map, user: user);
        }).toList();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getWorkers note: $e');
    }
    return [];
  }

  // -------------------------------------------------------------
  // BOOKINGS CRUD
  // -------------------------------------------------------------
  Stream<List<BookingModel>> getBookingsStream({int? customerId, int? workerId}) {
    Query query = _bookingsCol;
    if (customerId != null) {
      query = query.where('customer_id', isEqualTo: customerId);
    } else if (workerId != null) {
      query = query.where('worker_id', isEqualTo: workerId);
    }

    return query.snapshots().map((snap) {
      if (snap.docs.isEmpty) return [];

      return snap.docs.map((d) {
        final map = d.data() as Map<String, dynamic>;
        UserModel? customer;
        if (map['customer'] != null && map['customer'] is Map<String, dynamic>) {
          customer = UserModel.fromMap(map['customer'] as Map<String, dynamic>);
        }
        UserModel? worker;
        if (map['worker'] != null && map['worker'] is Map<String, dynamic>) {
          worker = UserModel.fromMap(map['worker'] as Map<String, dynamic>);
        }
        return BookingModel.fromMap(
          map,
          customer: customer,
          worker: worker,
          serviceName: map['service_name']?.toString(),
          categoryName: map['category_name']?.toString(),
        );
      }).toList();
    });
  }

  Future<List<BookingModel>> getBookings({int? customerId, int? workerId}) async {
    try {
      Query query = _bookingsCol;
      if (customerId != null) {
        query = query.where('customer_id', isEqualTo: customerId);
      } else if (workerId != null) {
        query = query.where('worker_id', isEqualTo: workerId);
      }
      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) {
          final map = d.data() as Map<String, dynamic>;
          UserModel? customer;
          if (map['customer'] != null && map['customer'] is Map<String, dynamic>) {
            customer = UserModel.fromMap(map['customer'] as Map<String, dynamic>);
          }
          UserModel? worker;
          if (map['worker'] != null && map['worker'] is Map<String, dynamic>) {
            worker = UserModel.fromMap(map['worker'] as Map<String, dynamic>);
          }
          return BookingModel.fromMap(
            map,
            customer: customer,
            worker: worker,
            serviceName: map['service_name']?.toString(),
            categoryName: map['category_name']?.toString(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getBookings error: $e');
    }
    return [];
  }

  Future<bool> createBooking(BookingModel booking) async {
    try {
      final docId = booking.bookingId != 0
          ? booking.bookingId.toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      final map = booking.toMap();
      map['booking_id'] = int.tryParse(docId) ?? booking.bookingId;
      map['created_at'] = DateTime.now().toIso8601String();
      if (booking.customer != null) {
        map['customer'] = booking.customer!.toMap();
      }
      if (booking.worker != null) {
        map['worker'] = booking.worker!.toMap();
      }
      map['service_name'] = booking.serviceName;
      map['category_name'] = booking.categoryName;

      await _bookingsCol.doc(docId).set(map);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] createBooking error: $e');
      return false;
    }
  }

  Future<bool> updateBookingStatus(int bookingId, String newStatus) async {
    try {
      await _bookingsCol.doc(bookingId.toString()).update({'status': newStatus});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] updateBookingStatus error: $e');
      return false;
    }
  }

  Future<bool> completeBooking({
    required int bookingId,
    String? paymentMethod,
    String? paymentStatus,
    double? totalAmount,
    double? commissionRate,
    double? commissionAmount,
    double? netAmount,
    String? completionNotes,
    int? rating,
    String? reviewComment,
  }) async {
    try {
      final now = DateTime.now();
      final updates = <String, dynamic>{
        'status': 'completed',
        'completed_at': now.toIso8601String(),
      };
      if (paymentMethod != null) updates['payment_method'] = paymentMethod;
      if (paymentStatus != null) updates['payment_status'] = paymentStatus;
      if (totalAmount != null) updates['total_amount'] = totalAmount;
      if (commissionRate != null) updates['commission_rate'] = commissionRate;
      if (commissionAmount != null) updates['commission_amount'] = commissionAmount;
      if (netAmount != null) updates['net_amount'] = netAmount;
      if (completionNotes != null && completionNotes.isNotEmpty) updates['completion_notes'] = completionNotes;
      if (rating != null) updates['rating'] = rating;
      if (reviewComment != null && reviewComment.isNotEmpty) updates['review_comment'] = reviewComment;

      await _bookingsCol.doc(bookingId.toString()).update(updates);

      // If rating was provided, save review & update worker stats
      if (rating != null && rating > 0) {
        final bSnap = await _bookingsCol.doc(bookingId.toString()).get();
        if (bSnap.exists) {
          final bMap = bSnap.data() as Map<String, dynamic>;
          final cId = bMap['customer_id'] is int
              ? bMap['customer_id']
              : int.tryParse(bMap['customer_id']?.toString() ?? '0') ?? 0;
          final wId = bMap['worker_id'] is int
              ? bMap['worker_id']
              : int.tryParse(bMap['worker_id']?.toString() ?? '0') ?? 0;

          UserModel? customer;
          if (bMap['customer'] is Map<String, dynamic>) {
            customer = UserModel.fromMap(bMap['customer'] as Map<String, dynamic>);
          }

          final newReview = ReviewModel(
            reviewId: DateTime.now().millisecondsSinceEpoch % 100000,
            bookingId: bookingId,
            reviewerId: cId,
            revieweeId: wId,
            reviewerRole: 'customer',
            rating: rating,
            comment: reviewComment,
            createdAt: now,
            reviewer: customer,
          );
          await createReview(newReview);

          try {
            final wDoc = await _workersCol.doc(wId.toString()).get();
            if (wDoc.exists) {
              final wData = wDoc.data() as Map<String, dynamic>;
              final currentJobs = (wData['total_jobs_completed'] as int?) ?? 0;
              final currentRating = ((wData['avg_rating'] ?? 5.0) as num).toDouble();
              final newJobs = currentJobs + 1;
              final newAvg = ((currentRating * currentJobs) + rating) / newJobs;
              await _workersCol.doc(wId.toString()).update({
                'total_jobs_completed': newJobs,
                'avg_rating': double.parse(newAvg.toStringAsFixed(1)),
              });
            }
          } catch (e) {
            debugPrint('[FirestoreService] update worker rating note: $e');
          }
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] completeBooking error: $e');
      return false;
    }
  }

  Future<bool> deleteBooking(int bookingId) async {
    try {
      await _bookingsCol.doc(bookingId.toString()).delete();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] deleteBooking error: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // JOB POSTS & BIDS CRUD
  // -------------------------------------------------------------
  Stream<List<JobPostModel>> getJobPostsStream() {
    return _jobPostsCol.snapshots().map((snap) {
      if (snap.docs.isEmpty) return [];
      return snap.docs.map((d) {
        final map = d.data() as Map<String, dynamic>;
        UserModel? customer;
        if (map['customer'] != null && map['customer'] is Map<String, dynamic>) {
          customer = UserModel.fromMap(map['customer'] as Map<String, dynamic>);
        }
        return JobPostModel.fromMap(map, customer: customer);
      }).toList();
    });
  }

  Future<List<JobPostModel>> getJobPosts() async {
    try {
      final snap = await _jobPostsCol.get();
      if (snap.docs.isNotEmpty) {
        List<JobPostModel> posts = [];
        for (var d in snap.docs) {
          final map = d.data() as Map<String, dynamic>;
          UserModel? customer;
          if (map['customer'] != null && map['customer'] is Map<String, dynamic>) {
            customer = UserModel.fromMap(map['customer'] as Map<String, dynamic>);
          }
          final rawJobId = map['job_post_id'] ?? d.id;
          final intJobId = rawJobId is int ? rawJobId : int.tryParse(rawJobId.toString());
          List<BidModel> bids = [];
          if (intJobId != null) {
            var bidsSnap = await _bidsCol.where('job_post_id', isEqualTo: intJobId).get();
            var bidDocs = bidsSnap.docs;
            if (bidDocs.isEmpty) {
              final strSnap = await _bidsCol.where('job_post_id', isEqualTo: intJobId.toString()).get();
              bidDocs = strSnap.docs;
            }
            bids = bidDocs.map((bDoc) {
              final bMap = bDoc.data() as Map<String, dynamic>;
              UserModel? worker;
              if (bMap['worker'] != null && bMap['worker'] is Map<String, dynamic>) {
                worker = UserModel.fromMap(bMap['worker'] as Map<String, dynamic>);
              }
              return BidModel.fromMap(bMap, worker: worker);
            }).toList();
          }
          posts.add(JobPostModel.fromMap(map, customer: customer, bids: bids));
        }
        return posts;
      }
    } catch (e) {
      debugPrint('[FirestoreService] getJobPosts error: $e');
    }
    return [];
  }

  Future<bool> updateJobPostStatus(int jobPostId, String newStatus) async {
    try {
      await _jobPostsCol.doc(jobPostId.toString()).update({'status': newStatus});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] updateJobPostStatus error: $e');
      return false;
    }
  }

  Future<bool> updateBidStatus(int bidId, String newStatus) async {
    try {
      await _bidsCol.doc(bidId.toString()).update({'status': newStatus});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] updateBidStatus error: $e');
      return false;
    }
  }

  Future<bool> createJobPost(JobPostModel jobPost) async {
    try {
      final docId = jobPost.jobPostId != 0
          ? jobPost.jobPostId.toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      final map = jobPost.toMap();
      map['job_post_id'] = int.tryParse(docId) ?? jobPost.jobPostId;
      map['created_at'] = DateTime.now().toIso8601String();
      if (jobPost.customer != null) {
        map['customer'] = jobPost.customer!.toMap();
      }

      await _jobPostsCol.doc(docId).set(map);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] createJobPost error: $e');
      return false;
    }
  }

  Future<bool> deleteJobPost(int jobPostId) async {
    try {
      await _jobPostsCol.doc(jobPostId.toString()).delete();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] deleteJobPost error: $e');
      return false;
    }
  }

  Future<bool> placeBid(BidModel bid) async {
    try {
      final docId = bid.bidId != 0
          ? bid.bidId.toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      final map = bid.toMap();
      map['bid_id'] = int.tryParse(docId) ?? bid.bidId;
      map['created_at'] = DateTime.now().toIso8601String();
      if (bid.worker != null) {
        map['worker'] = bid.worker!.toMap();
      }

      await _firestore.collection('bids').doc(docId).set(map);

      // Increment bids count on job post
      final jobRef = _jobPostsCol.doc(bid.jobPostId.toString());
      await jobRef.update({'bids_count': FieldValue.increment(1)}).catchError((_) {});

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] placeBid error: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // CHAT / MESSAGES CRUD
  // -------------------------------------------------------------
  Stream<List<MessageModel>> getMessagesStream(int bookingId) {
    return _messagesCol
        .where('booking_id', isEqualTo: bookingId)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return [];
      final list = snap.docs
          .map((d) => MessageModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => (a.sentAt ?? DateTime(2000)).compareTo(b.sentAt ?? DateTime(2000)));
      return list;
    });
  }

  Stream<List<MessageModel>> getAllMessagesStream() {
    return _messagesCol.snapshots().map((snap) {
      if (snap.docs.isEmpty) return [];
      final list = snap.docs
          .map((d) => MessageModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => (a.sentAt ?? DateTime(2000)).compareTo(b.sentAt ?? DateTime(2000)));
      return list;
    });
  }

  Stream<List<MessageModel>> getConversationStream({
    int? bookingId,
    int? currentUserId,
    int? otherUserId,
  }) {
    return _messagesCol.snapshots().map((snap) {
      if (snap.docs.isEmpty) return [];
      final all = snap.docs
          .map((d) => MessageModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();

      final filtered = all.where((m) {
        if (bookingId != null && m.bookingId == bookingId) return true;
        if (currentUserId != null && otherUserId != null) {
          final isMatch = (m.senderId == currentUserId && m.receiverId == otherUserId) ||
                          (m.senderId == otherUserId && m.receiverId == currentUserId);
          if (isMatch) return true;
        }
        return false;
      }).toList();

      filtered.sort((a, b) {
        final aTime = a.sentAt ?? DateTime(2000);
        final bTime = b.sentAt ?? DateTime(2000);
        return aTime.compareTo(bTime);
      });

      return filtered;
    });
  }

  Future<List<MessageModel>> getMessages({int? bookingId}) async {
    try {
      Query query = _messagesCol;
      if (bookingId != null) {
        query = query.where('booking_id', isEqualTo: bookingId);
      }
      final snap = await query.get();
      return snap.docs
          .map((d) => MessageModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] getMessages error: $e');
      return [];
    }
  }

  Future<bool> sendMessage(MessageModel message) async {
    try {
      final docId = message.messageId != 0
          ? message.messageId.toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      final map = message.toMap();
      map['message_id'] = int.tryParse(docId) ?? message.messageId;
      map['created_at'] = DateTime.now().toIso8601String();
      if (message.sender != null) {
        map['sender'] = message.sender!.toMap();
      }
      if (message.receiver != null) {
        map['receiver'] = message.receiver!.toMap();
      }

      await _messagesCol.doc(docId).set(map);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] sendMessage error: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // REVIEWS CRUD
  // -------------------------------------------------------------
  Stream<List<ReviewModel>> getReviewsStream(int revieweeId) {
    return _reviewsCol
        .where('reviewee_id', isEqualTo: revieweeId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return [];
      return snap.docs
          .map((d) => ReviewModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<bool> createReview(ReviewModel review) async {
    try {
      final docId = review.reviewId != 0
          ? review.reviewId.toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      final map = review.toMap();
      map['review_id'] = int.tryParse(docId) ?? review.reviewId;
      map['created_at'] = DateTime.now().toIso8601String();
      if (review.reviewer != null) {
        map['reviewer'] = review.reviewer!.toMap();
      }

      await _reviewsCol.doc(docId).set(map);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] createReview error: $e');
      return false;
    }
  }
}
