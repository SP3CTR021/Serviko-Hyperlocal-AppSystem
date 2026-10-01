import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'sample_data.dart';

/// DatabaseSeeder handles seeding sample users, workers, categories,
/// job posts, bookings, and messages to Cloud Firestore.
///
/// All seeders are commented out by default to provide a completely clean slate
/// for testing real database CRUD operations.
class DatabaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _usersCol => _firestore.collection('users');
  static CollectionReference get _categoriesCol => _firestore.collection('categories');
  static CollectionReference get _workersCol => _firestore.collection('workers');
  static CollectionReference get _bookingsCol => _firestore.collection('bookings');
  static CollectionReference get _jobPostsCol => _firestore.collection('job_posts');
  static CollectionReference get _messagesCol => _firestore.collection('messages');
  static CollectionReference get _bidsCol => _firestore.collection('bids');

  // ===========================================================================
  // 1. SEED SAMPLE ACCOUNTS / USERS
  // ===========================================================================
  /// Seeds sample customer (Ana Ramos) and workers (Juan, Elena, Mark)
  static Future<void> seedAccounts() async {
    try {
      debugPrint('[DatabaseSeeder] Seeding sample user accounts...');
      final users = [
        SampleData.demoCustomer,
        SampleData.demoWorker1,
        SampleData.demoWorker2,
        SampleData.demoWorker3,
      ];
      final batch = _firestore.batch();
      for (var user in users) {
        final docRef = _usersCol.doc(user.id.toString());
        batch.set(docRef, user.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[DatabaseSeeder] User accounts seeded successfully.');
    } catch (e) {
      debugPrint('[DatabaseSeeder] seedAccounts error: $e');
    }
  }

  // ===========================================================================
  // 2. SEED SERVICE CATEGORIES
  // ===========================================================================
  /// Seeds standard service categories (Plumbing, Electrical, Cleaning, etc.)
  static Future<void> seedCategories() async {
    try {
      debugPrint('[DatabaseSeeder] Seeding service categories...');
      final batch = _firestore.batch();
      for (var cat in SampleData.categories) {
        final docRef = _categoriesCol.doc(cat.categoryId.toString());
        batch.set(docRef, cat.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[DatabaseSeeder] Categories seeded successfully.');
    } catch (e) {
      debugPrint('[DatabaseSeeder] seedCategories error: $e');
    }
  }

  // ===========================================================================
  // 3. SEED SAMPLE WORKER PROFILES (SAMPLE PEOPLE)
  // ===========================================================================
  /// Seeds full worker profiles including skills, pricing, and services
  static Future<void> seedWorkers() async {
    try {
      debugPrint('[DatabaseSeeder] Seeding worker profiles...');
      final batch = _firestore.batch();
      for (var wp in SampleData.workerProfiles) {
        final docRef = _workersCol.doc(wp.workerProfileId.toString());
        final map = wp.toMap();
        if (wp.user != null) {
          map['user'] = wp.user!.toMap();
        }
        batch.set(docRef, map, SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[DatabaseSeeder] Worker profiles seeded successfully.');
    } catch (e) {
      debugPrint('[DatabaseSeeder] seedWorkers error: $e');
    }
  }

  // ===========================================================================
  // 4. SEED SAMPLE JOB POSTINGS & BIDS
  // ===========================================================================
  /// Seeds sample community job posts and contractor bids
  static Future<void> seedJobPosts() async {
    try {
      debugPrint('[DatabaseSeeder] Seeding job posts and bids...');
      final batch = _firestore.batch();
      for (var jp in SampleData.jobPosts) {
        final docRef = _jobPostsCol.doc(jp.jobPostId.toString());
        final map = jp.toMap();
        if (jp.customer != null) {
          map['customer'] = jp.customer!.toMap();
        }
        batch.set(docRef, map, SetOptions(merge: true));

        // Seed attached bids if any
        if (jp.bids != null) {
          for (var bid in jp.bids!) {
            final bidRef = _bidsCol.doc(bid.bidId.toString());
            final bidMap = bid.toMap();
            if (bid.worker != null) {
              bidMap['worker'] = bid.worker!.toMap();
            }
            batch.set(bidRef, bidMap, SetOptions(merge: true));
          }
        }
      }
      await batch.commit();
      debugPrint('[DatabaseSeeder] Job posts seeded successfully.');
    } catch (e) {
      debugPrint('[DatabaseSeeder] seedJobPosts error: $e');
    }
  }

  // ===========================================================================
  // 5. SEED SAMPLE BOOKINGS
  // ===========================================================================
  /// Seeds sample service bookings
  static Future<void> seedBookings() async {
    try {
      debugPrint('[DatabaseSeeder] Seeding bookings...');
      final batch = _firestore.batch();
      for (var b in SampleData.bookings) {
        final docRef = _bookingsCol.doc(b.bookingId.toString());
        final map = b.toMap();
        if (b.customer != null) map['customer'] = b.customer!.toMap();
        if (b.worker != null) map['worker'] = b.worker!.toMap();
        map['service_name'] = b.serviceName;
        map['category_name'] = b.categoryName;
        batch.set(docRef, map, SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[DatabaseSeeder] Bookings seeded successfully.');
    } catch (e) {
      debugPrint('[DatabaseSeeder] seedBookings error: $e');
    }
  }

  // ===========================================================================
  // 6. SEED SAMPLE MESSAGES
  // ===========================================================================
  /// Seeds sample chat conversation messages
  static Future<void> seedMessages() async {
    try {
      debugPrint('[DatabaseSeeder] Seeding chat messages...');
      final batch = _firestore.batch();
      for (var m in SampleData.messages) {
        final docRef = _messagesCol.doc(m.messageId.toString());
        batch.set(docRef, m.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[DatabaseSeeder] Messages seeded successfully.');
    } catch (e) {
      debugPrint('[DatabaseSeeder] seedMessages error: $e');
    }
  }

  static CollectionReference get _reviewsCol => _firestore.collection('reviews');

  // ===========================================================================
  // MASTER SEED ALL
  // ===========================================================================
  /// Runs all seeders sequentially
  static Future<void> seedAll() async {
    await seedAccounts();
    await seedCategories();
    await seedWorkers();
    await seedJobPosts();
    await seedBookings();
    await seedMessages();
    debugPrint('[DatabaseSeeder] All sample data successfully seeded into Firestore.');
  }

  // ===========================================================================
  // CLEAN SLATE PURGE HELPER
  // ===========================================================================
  /// Helper to wipe all test collections in Firestore back to an empty clean slate
  static Future<void> clearAll() async {
    try {
      debugPrint('[DatabaseSeeder] Purging collections for clean slate...');
      final cols = [
        _usersCol,
        _categoriesCol,
        _workersCol,
        _bookingsCol,
        _jobPostsCol,
        _messagesCol,
        _bidsCol,
        _reviewsCol,
      ];
      for (var col in cols) {
        final snap = await col.get();
        final batch = _firestore.batch();
        for (var doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      debugPrint('[DatabaseSeeder] All collections purged. Clean slate ready.');
    } catch (e) {
      debugPrint('[DatabaseSeeder] clearAll note: $e');
    }
  }
}
