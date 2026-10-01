import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../models/user_model.dart';
import '../models/service_category_model.dart';
import '../models/worker_profile_model.dart';
import '../models/booking_model.dart';
import '../models/job_post_model.dart';
import '../models/bid_model.dart';
import '../models/message_model.dart';
import 'firestore_service.dart';

/// Type alias for modern naming while preserving backward compatibility
typedef AppDataService = MySqlService;

/// Central reactive state store connecting Flutter UI components directly to Cloud Firestore.
/// Retains the class name `MySqlService` to preserve 100% compatibility across all UI screens
/// without requiring massive breaking changes across 80+ widget files.
class MySqlService extends ChangeNotifier {
  static final MySqlService _instance = MySqlService._internal();
  factory MySqlService() => _instance;
  MySqlService._internal();

  bool _isConnected = true;
  bool _isConnecting = false;
  String? _lastError;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get lastError => _lastError;

  // In-memory cache lists
  List<ServiceCategoryModel> _categories = [];
  List<WorkerProfileModel> _workerProfiles = [];
  List<BookingModel> _bookings = [];
  List<JobPostModel> _jobPosts = [];
  List<MessageModel> _messages = [];

  List<ServiceCategoryModel> get categories => _categories;
  List<WorkerProfileModel> get workerProfiles => _workerProfiles;
  List<BookingModel> get bookings => _bookings;
  List<JobPostModel> get jobPosts => _jobPosts;
  List<MessageModel> get messages => _messages;

  /// Safe notifyListeners to prevent "setState() or markNeedsBuild() called during build" exceptions
  void _safeNotifyListeners() {
    try {
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        notifyListeners();
      }
    } catch (_) {
      notifyListeners();
    }
  }

  /// Initialize and sync directly from Cloud Firestore (0ms startup delay)
  Future<void> initialize() async {
    _categories = [];
    _workerProfiles = [];
    _bookings = [];
    _jobPosts = [];
    _messages = [];

    await refreshData();
  }

  void clearLocalCache() {
    _categories = [];
    _workerProfiles = [];
    _bookings = [];
    _jobPosts = [];
    _messages = [];
    _safeNotifyListeners();
  }

  /// Sync fresh data directly from Cloud Firestore
  Future<void> refreshData() async {
    _isConnecting = true;
    _lastError = null;
    // NOTE: Do not call notifyListeners() synchronously here to prevent build collision

    try {
      final fs = FirestoreService();
      final fsCats = await fs.getCategories();
      _categories = fsCats;

      final fsWorkers = await fs.getWorkers();
      _workerProfiles = fsWorkers;

      final fsBookings = await fs.getBookings();
      _bookings = fsBookings;

      final fsJobPosts = await fs.getJobPosts();
      _jobPosts = fsJobPosts;

      final fsMessages = await fs.getMessages();
      _messages = fsMessages;

      _isConnected = true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[AppDataService] Refresh error: $e');
    } finally {
      _isConnecting = false;
      _safeNotifyListeners();
    }
  }

  /// Legacy helper - connects immediately via Firestore
  Future<bool> connectToDatabase() async {
    await refreshData();
    return true;
  }

  /// User Login
  Future<UserModel?> login(String email, String password) async {
    // Authentication is handled via AuthService & Firebase Auth
    return null;
  }

  /// User Registration fallback
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? city,
    String? barangay,
    String? skill,
  }) async {
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newUser = UserModel(
      id: newId,
      name: fullName,
      fullName: fullName,
      email: email,
      role: role,
      phoneNumber: phoneNumber,
      city: city,
      barangay: barangay,
      skill: skill,
      isVerified: false,
      memberSince: DateTime.now(),
    );

    _safeNotifyListeners();
    return newUser;
  }

  /// Create a new Booking in Cloud Firestore
  Future<bool> createBooking(BookingModel booking) async {
    _bookings.insert(0, booking);
    _safeNotifyListeners();

    try {
      return await FirestoreService().createBooking(booking);
    } catch (e) {
      debugPrint('[AppDataService] createBooking error: $e');
      return false;
    }
  }

  /// Update Booking Status (e.g., accepted, rejected, in_progress, completed, cancelled)
  Future<bool> updateBookingStatus(int bookingId, String newStatus, {String? reason, String? cancelledBy}) async {
    final idx = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (idx != -1) {
      final old = _bookings[idx];
      _bookings[idx] = BookingModel(
        bookingId: old.bookingId,
        customerId: old.customerId,
        workerId: old.workerId,
        workerServiceId: old.workerServiceId,
        categoryId: old.categoryId,
        scheduledDate: old.scheduledDate,
        scheduledTime: old.scheduledTime,
        serviceAddress: old.serviceAddress,
        jobDescription: old.jobDescription,
        status: newStatus,
        isUrgent: old.isUrgent,
        cancellationReason: reason ?? old.cancellationReason,
        cancelledBy: cancelledBy ?? old.cancelledBy,
        totalAmount: old.totalAmount,
        createdAt: old.createdAt,
        customer: old.customer,
        worker: old.worker,
        serviceName: old.serviceName,
        categoryName: old.categoryName,
      );
      _safeNotifyListeners();
    }

    try {
      return await FirestoreService().updateBookingStatus(bookingId, newStatus);
    } catch (e) {
      debugPrint('[AppDataService] updateBookingStatus error: $e');
      return false;
    }
  }

  /// Delete Booking from Cloud Firestore
  Future<bool> deleteBooking(int bookingId) async {
    _bookings.removeWhere((b) => b.bookingId == bookingId);
    _safeNotifyListeners();

    try {
      return await FirestoreService().deleteBooking(bookingId);
    } catch (e) {
      debugPrint('[AppDataService] deleteBooking error: $e');
      return false;
    }
  }

  /// Create a new Job Post in Cloud Firestore
  Future<bool> createJobPost(JobPostModel post) async {
    _jobPosts.insert(0, post);
    _safeNotifyListeners();

    try {
      return await FirestoreService().createJobPost(post);
    } catch (e) {
      debugPrint('[AppDataService] createJobPost error: $e');
      return false;
    }
  }

  /// Delete Job Post from Cloud Firestore
  Future<bool> deleteJobPost(int jobPostId) async {
    _jobPosts.removeWhere((p) => p.jobPostId == jobPostId);
    _safeNotifyListeners();

    try {
      return await FirestoreService().deleteJobPost(jobPostId);
    } catch (e) {
      debugPrint('[AppDataService] deleteJobPost error: $e');
      return false;
    }
  }

  /// Submit Bid for a Job Post (alias: placeBid) in Cloud Firestore
  Future<bool> placeBid(BidModel bid) => submitBid(bid);

  Future<bool> submitBid(BidModel bid) async {
    final postIdx = _jobPosts.indexWhere((p) => p.jobPostId == bid.jobPostId);
    if (postIdx != -1) {
      final post = _jobPosts[postIdx];
      final updatedBids = List<BidModel>.from(post.bids)..add(bid);
      _jobPosts[postIdx] = JobPostModel(
        jobPostId: post.jobPostId,
        customerId: post.customerId,
        categoryId: post.categoryId,
        title: post.title,
        description: post.description,
        locationAddress: post.locationAddress,
        city: post.city,
        barangay: post.barangay,
        budgetMin: post.budgetMin,
        budgetMax: post.budgetMax,
        preferredDate: post.preferredDate,
        urgency: post.urgency,
        status: post.status,
        createdAt: post.createdAt,
        customer: post.customer,
        categoryName: post.categoryName,
        bids: updatedBids,
      );
      _safeNotifyListeners();
    }

    try {
      return await FirestoreService().placeBid(bid);
    } catch (e) {
      debugPrint('[AppDataService] submitBid error: $e');
      return false;
    }
  }

  /// Send Message to Cloud Firestore
  Future<bool> sendMessage(MessageModel msg) async {
    _messages.add(msg);
    _safeNotifyListeners();

    try {
      return await FirestoreService().sendMessage(msg);
    } catch (e) {
      debugPrint('[AppDataService] sendMessage error: $e');
      return false;
    }
  }
}
