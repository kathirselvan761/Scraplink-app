import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scraplink_collector/config/app_theme.dart';
import 'package:scraplink_collector/providers/auth_provider.dart';
import 'package:scraplink_collector/providers/lot_provider.dart';
import 'package:scraplink_collector/screens/splash_screen.dart';
import 'package:scraplink_collector/screens/auth/login_screen.dart';
import 'package:scraplink_collector/screens/auth/register_screen.dart';
import 'package:scraplink_collector/widgets/primary_button.dart';
import 'package:scraplink_collector/widgets/loading_overlay.dart';

Widget createTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => LotProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth UI & Flow Widget Tests', () {
    testWidgets('SplashScreen renders logo and transitions to LoginScreen when unauthenticated',
        (tester) async {
      await tester.pumpWidget(createTestApp(const SplashScreen()));

      expect(find.text('ScrapLink'), findsOneWidget);
      expect(find.text('Collector Portal'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance clock past the splash delay
      await tester.pumpAndSettle();

      // Should now be on LoginScreen
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('LoginScreen form validation triggers on empty fields', (tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      expect(find.text('Welcome Back'), findsOneWidget);

      // Tap Login with empty fields
      await tester.tap(find.widgetWithText(PrimaryButton, 'Log In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('RegisterScreen validates 10-digit phone and password match', (tester) async {
      await tester.pumpWidget(createTestApp(const RegisterScreen()));

      expect(find.text('Join ScrapLink as a Collector'), findsOneWidget);

      // Fill in invalid phone & mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), '12345'); // invalid phone
      await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
      await tester.enterText(find.byType(TextFormField).at(4), 'mismatch123');

      final registerBtn = find.widgetWithText(PrimaryButton, 'Register as Collector');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid 10-digit phone number'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('LoadingOverlay shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              message: 'Please wait...',
              child: Text('Underlying content'),
            ),
          ),
        ),
      );

      expect(find.text('Underlying content'), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
