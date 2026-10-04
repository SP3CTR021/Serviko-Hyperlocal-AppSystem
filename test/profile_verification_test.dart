import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/widgets/profile_completion_banner.dart';
import 'package:flutter_application_1/utils/verification_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Verification & Completion Tests', () {
    testWidgets('ProfileCompletionBanner displays subtle progress reminder for unverified user', (tester) async {
      final auth = AuthService();
      auth.switchDemoRole('customer');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionBanner(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for subtle progress header and step
      expect(find.text('Complete your Profile'), findsOneWidget);
      expect(find.text('Step 1 of 3 · 30%'), findsOneWidget);
    });

    testWidgets('VerificationGuard restricts action and displays alert for unverified user', (tester) async {
      final auth = AuthService();
      auth.switchDemoRole('customer');

      bool actionExecuted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  if (!VerificationGuard.check(context, actionName: 'book a service')) return;
                  actionExecuted = true;
                },
                child: const Text('Try Book'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the action button
      await tester.tap(find.text('Try Book'));
      await tester.pumpAndSettle();

      // VerificationGuard should block execution and show modal
      expect(actionExecuted, isFalse);
      expect(find.text('Verification Required'), findsOneWidget);
      expect(find.textContaining('Action Restricted: book a service'), findsOneWidget);
      expect(find.text('Verify ID Now'), findsOneWidget);
    });

    test('User can be verified with ID number only without ID photo', () async {
      final auth = AuthService();
      auth.switchDemoRole('customer');
      expect(auth.currentUser!.isVerified, isFalse);

      final success = await auth.submitVerification(
        idType: 'PhilSys National ID',
        idNumber: '1234-5678-9012',
        // idPhotoUrl is omitted / null
      );

      expect(success, isTrue);
      expect(auth.currentUser!.isVerified, isTrue);
      expect(auth.currentUser!.idNumber, '1234-5678-9012');
    });
  });
}
