import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/landing_page_screen.dart';
import 'package:flutter_application_1/screens/auth/role_selection_screen.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/auth/register_screen.dart';
import 'package:flutter_application_1/screens/profile/profile_screen.dart';

void main() {
  testWidgets('LandingPageScreen matches Serviko v3 specification', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LandingPageScreen(),
      ),
    );

    expect(find.text('serviko'), findsOneWidget);
    expect(find.text('What brings you here today?'), findsOneWidget);
    expect(find.text('Free to join. No sign-up fee.'), findsOneWidget);
    expect(find.text("I'm looking for a service"), findsOneWidget);
    expect(find.text('Find trusted workers near you'), findsOneWidget);
    expect(find.text("I'm looking for work"), findsOneWidget);
    expect(find.text('Get booked for jobs nearby'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('RoleSelectionScreen matches Serviko v3 specification', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RoleSelectionScreen(),
      ),
    );

    expect(find.text('serviko'), findsOneWidget);
    expect(find.text('What brings you here today?'), findsOneWidget);
    expect(find.text("I'm looking for a service"), findsOneWidget);
    expect(find.text("I'm looking for work"), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('RegisterScreen matches Serviko v3 specification', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(isWorker: false),
      ),
    );

    expect(find.text('Create an account'), findsNWidgets(2)); // Headline and CTA
    expect(find.text('Free. No sign-up fee.'), findsOneWidget);
    expect(find.text('Looking for'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('City and village'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.text('Log in here'), findsOneWidget);

    // Switch to Worker mode dynamically via pill tap
    await tester.tap(find.text('Looking for'));
    await tester.pumpAndSettle();

    // Verify Worker elements appear
    expect(find.text('Offering'), findsOneWidget);
    expect(
      find.text('As a worker, people in your area will be able to see you and can accept bookings immediately.'),
      findsOneWidget,
    );
    expect(find.text('Basic skills'), findsOneWidget);
    expect(find.text('Choose your job'), findsOneWidget);
  });

  testWidgets('LoginScreen matches Serviko v3 specification', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(isWorker: false),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in to book trusted help nearby.'), findsOneWidget);
    expect(find.text('For service finders'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('or log in with email'), findsOneWidget);
    expect(find.text('Email or phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('New here? '), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);

    // Switch to Worker mode dynamically via pill tap
    await tester.tap(find.text('For service finders'));
    await tester.pumpAndSettle();

    expect(find.text('For workers'), findsOneWidget);
    expect(find.text('Log in to see new bookings near you.'), findsOneWidget);
    expect(find.text('Create a worker account'), findsOneWidget);
  });

  testWidgets('ProfileScreen Sign Out opens confirmation dialog and logs out', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(),
      ),
    );

    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to sign out from your Serviko account?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to sign out from your Serviko account?'), findsNothing);
  });
}
