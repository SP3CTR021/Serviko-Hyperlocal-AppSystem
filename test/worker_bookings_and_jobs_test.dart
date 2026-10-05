import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/booking_model.dart';
import 'package:flutter_application_1/models/job_post_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/worker_profile_model.dart';
import 'package:flutter_application_1/screens/worker/job_marketplace_screen.dart';
import 'package:flutter_application_1/screens/worker/worker_bookings_screen.dart';
import 'package:flutter_application_1/screens/worker/worker_dashboard_screen.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/mysql_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Worker Bookings Visibility & Customer Photo in Job Posts Tests', () {
    setUp(() {
      MySqlService().clearLocalCache();
    });

    test('BookingModel correctly serializes and deserializes workerUid and customerUid', () {
      final booking = BookingModel(
        bookingId: 8801,
        customerId: 101,
        workerId: 202,
        customerUid: 'cust_uid_101',
        workerUid: 'worker_uid_202',
        serviceName: 'AC Cleaning',
        status: 'pending',
        totalAmount: 750.0,
      );

      final map = booking.toMap();
      expect(map['customer_uid'], 'cust_uid_101');
      expect(map['worker_uid'], 'worker_uid_202');

      final deserialized = BookingModel.fromMap(map);
      expect(deserialized.customerUid, 'cust_uid_101');
      expect(deserialized.workerUid, 'worker_uid_202');
    });

    testWidgets('Worker can see incoming booking on both Pending and Active tabs in WorkerBookingsScreen', (tester) async {
      final worker = UserModel(
        id: 4001,
        uid: 'uid_specialist_4001',
        name: 'Danilo',
        fullName: 'Danilo Ramos',
        email: 'danilo@serviko.com',
        role: 'worker',
      );
      AuthService().setCurrentUserForTesting(worker);

      final customer = UserModel(
        id: 5001,
        uid: 'uid_client_5001',
        name: 'Elena',
        fullName: 'Elena Cruz',
        email: 'elena@serviko.com',
        role: 'customer',
        profilePhotoUrl: 'https://example.com/elena.jpg',
      );

      final incomingBooking = BookingModel(
        bookingId: 9001,
        customerId: 5001,
        customerUid: 'uid_client_5001',
        workerId: 4001,
        workerUid: 'uid_specialist_4001',
        status: 'pending',
        serviceName: 'Full House Cleaning',
        totalAmount: 1200.0,
        createdAt: DateTime.now(),
        customer: customer,
        worker: worker,
      );
      await MySqlService().createBooking(incomingBooking);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkerBookingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. In "Pending" tab (default), incoming booking is visible
      expect(find.text('Elena Cruz'), findsOneWidget);
      expect(find.text('Full House Cleaning'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);

      // 2. Switch to "Active" tab
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      // In Active tab, incoming booking request is also prominently visible with action banner
      expect(find.text('Elena Cruz'), findsOneWidget);
      expect(find.text('Full House Cleaning'), findsOneWidget);
      expect(find.textContaining('Incoming Booking Request'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('JobMarketplaceScreen displays customer profile initials and name on job cards', (tester) async {
      final worker = UserModel(
        id: 4002,
        uid: 'uid_worker_4002',
        name: 'Ben',
        fullName: 'Ben Santos',
        email: 'ben@serviko.com',
        role: 'worker',
      );
      AuthService().setCurrentUserForTesting(worker);

      final postingCustomer = UserModel(
        id: 6001,
        name: 'Maria',
        fullName: 'Maria Clara',
        email: 'maria@serviko.com',
        role: 'customer',
      );

      final jobPost = JobPostModel(
        jobPostId: 7001,
        customerId: 6001,
        title: 'Emergency Electrical Short Circuit Fix',
        description: 'Need certified electrician to inspect panel',
        categoryName: 'Electrical',
        urgency: 'urgent',
        budgetMin: 800,
        budgetMax: 1500,
        status: 'open',
        customer: postingCustomer,
      );
      await MySqlService().createJobPost(jobPost);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JobMarketplaceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Customer name and title should be visible
      expect(find.text('Maria Clara'), findsOneWidget);
      expect(find.text('Emergency Electrical Short Circuit Fix'), findsOneWidget);
      // Customer avatar fallback initials "M"
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('WorkerDashboardScreen displays customer avatar initials and quick job cards', (tester) async {
      final worker = UserModel(
        id: 4003,
        uid: 'uid_worker_4003',
        name: 'Jose',
        fullName: 'Jose Rizal',
        email: 'jose@serviko.com',
        role: 'worker',
      );
      AuthService().setCurrentUserForTesting(worker);

      final postingCustomer = UserModel(
        id: 7001,
        name: 'Grace',
        fullName: 'Grace Poe',
        email: 'grace@serviko.com',
        role: 'customer',
      );

      final jobPost = JobPostModel(
        jobPostId: 8001,
        customerId: 7001,
        title: 'General Deep Home Cleaning',
        description: 'Kitchen and living room deep cleaning',
        categoryName: 'Cleaning',
        urgency: 'flexible',
        budgetMin: 500,
        budgetMax: 900,
        status: 'open',
        customer: postingCustomer,
      );
      await MySqlService().createJobPost(jobPost);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Customer name should be shown in Jobs Near You quick card
      expect(find.text('Grace Poe'), findsOneWidget);
      expect(find.text('General Deep Home Cleaning'), findsOneWidget);
      expect(find.text('G'), findsWidgets);
    });
  });
}
