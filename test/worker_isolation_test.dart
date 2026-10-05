import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/booking_model.dart';
import 'package:flutter_application_1/models/job_post_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/screens/customer/customer_job_posts_screen.dart';
import 'package:flutter_application_1/screens/worker/worker_dashboard_screen.dart';
import 'package:flutter_application_1/screens/worker/worker_bookings_screen.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/mysql_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Worker and Customer Account Data Isolation Tests', () {
    setUp(() {
      // Clear local cache
      MySqlService().clearLocalCache();
    });

    testWidgets('Newly created worker account displays 0 completed jobs, ₱0 earnings, and New rating', (tester) async {
      final newWorker = UserModel(
        id: 9991,
        uid: 'uid_new_worker_9991',
        name: 'Carlos',
        fullName: 'Carlos Mendoza',
        email: 'carlos.mendoza@serviko.com',
        role: 'worker',
        skill: 'Carpenter',
        isVerified: true,
      );

      final auth = AuthService();
      auth.setCurrentUserForTesting(newWorker);

      final otherWorkerBooking = BookingModel(
        bookingId: 501,
        customerId: 1,
        workerId: 8888, // Different worker
        status: 'completed',
        totalAmount: 1500.0,
        createdAt: DateTime.now(),
        serviceName: 'Plumbing Repair',
      );
      await MySqlService().createBooking(otherWorkerBooking);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₱0'), findsWidgets);
      expect(find.text('₱1500'), findsNothing);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('No booking requests yet'), findsOneWidget);
    });

    testWidgets('Worker only sees their own bookings in WorkerBookingsScreen', (tester) async {
      final workerA = UserModel(
        id: 7001,
        uid: 'uid_worker_7001',
        name: 'Worker A',
        fullName: 'Worker A Full',
        email: 'workera@serviko.com',
        role: 'worker',
      );

      final auth = AuthService();
      auth.setCurrentUserForTesting(workerA);

      final bookingForA = BookingModel(
        bookingId: 601,
        customerId: 1,
        workerId: 7001,
        status: 'pending',
        totalAmount: 600.0,
        createdAt: DateTime.now(),
        serviceName: 'Carpentry Repair',
      );

      final bookingForB = BookingModel(
        bookingId: 602,
        customerId: 1,
        workerId: 7002, // Other worker
        status: 'pending',
        totalAmount: 1200.0,
        createdAt: DateTime.now(),
        serviceName: 'Electrical Fix',
      );

      await MySqlService().createBooking(bookingForA);
      await MySqlService().createBooking(bookingForB);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkerBookingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Carpentry Repair'), findsOneWidget);
      expect(find.textContaining('Electrical Fix'), findsNothing);
    });

    testWidgets('Newly created customer sees empty job posts and other users posts are isolated', (tester) async {
      final newCustomer = UserModel(
        id: 5501,
        uid: 'uid_customer_5501',
        name: 'Sara',
        fullName: 'Sara Lopez',
        email: 'sara@serviko.com',
        role: 'customer',
      );

      final auth = AuthService();
      auth.setCurrentUserForTesting(newCustomer);

      final otherUserJob = JobPostModel(
        jobPostId: 301,
        customerId: 9999, // Created by another user
        title: 'Fix kitchen cabinets',
        description: 'Cabinets broken',
        budgetMin: 500,
        budgetMax: 1000,
        status: 'open',
        categoryName: 'Carpentry',
      );
      await MySqlService().createJobPost(otherUserJob);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerJobPostsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sara should NOT see the other user's job post; it should show empty state
      expect(find.text('No open job posts'), findsOneWidget);
      expect(find.text('Fix kitchen cabinets'), findsNothing);
    });
  });
}
