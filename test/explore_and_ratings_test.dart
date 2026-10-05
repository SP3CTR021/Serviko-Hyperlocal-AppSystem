import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/worker_profile_model.dart';
import 'package:flutter_application_1/screens/customer/explore_services_screen.dart';
import 'package:flutter_application_1/screens/worker/worker_dashboard_screen.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/mysql_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/widgets/booking_completion_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Explore Services & Rating Star Theme Tests', () {
    setUp(() {
      MySqlService().clearLocalCache();
    });

    test('WorkerProfileModel photoUrl getter and serialization work properly', () {
      final user = UserModel(
        id: 701,
        name: 'Roberto',
        fullName: 'Roberto Cruz',
        email: 'roberto@serviko.com',
        role: 'worker',
        profilePhotoUrl: 'https://example.com/roberto.jpg',
      );

      final profileWithUser = WorkerProfileModel(
        workerProfileId: 101,
        userId: 701,
        user: user,
      );

      expect(profileWithUser.photoUrl, 'https://example.com/roberto.jpg');

      final map = profileWithUser.toMap();
      final fromMap = WorkerProfileModel.fromMap(map, user: user);
      expect(fromMap.photoUrl, 'https://example.com/roberto.jpg');
    });

    testWidgets('ExploreServicesScreen renders worker cards without 28px overflow on narrow width', (tester) async {
      final workerUser = UserModel(
        id: 801,
        name: 'Mateo',
        fullName: 'Mateo Dela Cruz Longname',
        email: 'mateo@serviko.com',
        role: 'worker',
        city: 'Davao City',
        barangay: 'Maa',
        isVerified: true,
      );

      final workerProfile = WorkerProfileModel(
        workerProfileId: 201,
        userId: 801,
        initials: 'MD',
        primarySkill: 'Comprehensive House Plumbing & Leak Repairs',
        bio: 'Professional plumber serving Maa, Davao City',
        avgRating: 4.9,
        totalJobsCompleted: 154,
        availabilityStatus: 'available',
        isIdVerified: true,
        user: workerUser,
      );

      MySqlService().setWorkerProfilesForTesting([workerProfile]);

      final customer = UserModel(
        id: 301,
        name: 'Ana',
        fullName: 'Ana Santos',
        email: 'ana@serviko.com',
        role: 'customer',
        city: 'Davao City',
      );
      AuthService().setCurrentUserForTesting(customer);

      // Narrow screen: 360x640 (where RenderFlex 28px overflow previously occurred)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExploreServicesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no RenderFlex overflow exception occurred
      expect(tester.takeException(), isNull);

      // Check worker card is rendered
      expect(find.text('Mateo Dela Cruz Longname'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);

      // Check star color is AppTheme.sbYellowGreen
      final starFinder = find.byIcon(Icons.star_rounded);
      expect(starFinder, findsWidgets);

      final Icon starIcon = tester.widget(starFinder.first);
      expect(starIcon.color, AppTheme.sbYellowGreen);
    });

    testWidgets('WorkerDashboardScreen uses AppTheme.sbYellowGreen for rating star', (tester) async {
      final worker = UserModel(
        id: 901,
        name: 'Juan',
        fullName: 'Juan Worker',
        email: 'juan@serviko.com',
        role: 'worker',
        isVerified: true,
      );
      AuthService().setCurrentUserForTesting(worker);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Juan Worker'), findsOneWidget);
    });
  });
}
