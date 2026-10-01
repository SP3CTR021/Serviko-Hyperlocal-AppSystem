import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/splash_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

void main() {
  testWidgets('Serviko splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
    // The splash screen renders and shows the SplashScreen widget
    expect(find.byType(SplashScreen), findsOneWidget);
    // After the entrance animation, the brand name RichText appears
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RichText), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
