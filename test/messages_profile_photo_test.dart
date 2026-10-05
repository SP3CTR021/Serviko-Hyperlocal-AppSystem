import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/booking_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/screens/chat/conversation_screen.dart';
import 'package:flutter_application_1/screens/chat/chat_screen.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/mysql_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Messages & Chat Profile Pictures Tests', () {
    setUp(() {
      MySqlService().clearLocalCache();
    });

    testWidgets('ConversationScreen displays other user profile photo in AppBar and initials fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ConversationScreen(
            otherUserId: 101,
            otherUserName: 'Juan Cruz',
            serviceTitle: 'Plumbing Specialist',
            otherUserPhoto: 'https://example.com/juan_cruz.jpg',
          ),
        ),
      );
      await tester.pump();

      // Verify the screen renders
      expect(find.text('Juan Cruz'), findsOneWidget);
      expect(find.text('Plumbing Specialist'), findsWidgets);

      // Verify Image.network widget is present for the profile photo
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('ConversationScreen renders fallback initials when photo is absent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ConversationScreen(
            otherUserId: 102,
            otherUserName: 'Maria Santos',
            serviceTitle: 'Electrical Works',
            otherUserPhoto: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Maria Santos'), findsOneWidget);
      // Fallback initial 'M' is displayed
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('ChatListScreen renders search bar and empty state gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ChatListScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Messages'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('ChatListScreen displays conversation item with profile photo when booking exists', (tester) async {
      final customer = UserModel(
        id: 9001,
        uid: 'uid_cust_9001',
        name: 'Carlos',
        fullName: 'Carlos Yulo',
        email: 'carlos@serviko.com',
        role: 'customer',
      );
      AuthService().setCurrentUserForTesting(customer);

      final worker = UserModel(
        id: 9002,
        uid: 'uid_worker_9002',
        name: 'Mateo',
        fullName: 'Mateo Lorenzo',
        email: 'mateo@serviko.com',
        role: 'worker',
        profilePhotoUrl: 'https://example.com/mateo.jpg',
      );

      final booking = BookingModel(
        bookingId: 9901,
        customerId: 9001,
        workerId: 9002,
        serviceName: 'Carpentry Services',
        customer: customer,
        worker: worker,
        status: 'accepted',
        totalAmount: 1200.0,
        createdAt: DateTime.now(),
      );

      await MySqlService().createBooking(booking);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ChatListScreen(),
        ),
      );
      await tester.pump();

      // Conversation item with Mateo Lorenzo should be displayed
      expect(find.text('Mateo Lorenzo'), findsOneWidget);
      // Profile photo image widget is present in the conversation list item
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
