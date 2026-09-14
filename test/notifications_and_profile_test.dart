import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scraplink_collector/config/app_theme.dart';
import 'package:scraplink_collector/models/user_model.dart';
import 'package:scraplink_collector/models/scrap_lot_model.dart';
import 'package:scraplink_collector/providers/auth_provider.dart';
import 'package:scraplink_collector/providers/lot_provider.dart';
import 'package:scraplink_collector/screens/home/profile_tab.dart';
import 'package:scraplink_collector/screens/home/home_shell.dart';

Widget createTestEnvironment({
  required AuthProvider authProvider,
  required LotProvider lotProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<LotProvider>.value(value: lotProvider),
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

  group('ProfileTab and Notifications Widget Tests', () {
    testWidgets('ProfileTab displays collector details, total lots, and logout dialog',
        (tester) async {
      final auth = AuthProvider();
      auth.setUser(
        UserModel(
          id: 1,
          name: 'Poo Mathan',
          email: 'collector@scraplink.com',
          phone: '9876543210',
          role: 'collector',
        ),
      );

      final lot = LotProvider();
      lot.setLots([
        ScrapLotModel(id: 'SCRAP-0001', material: 'Copper', estimatedWeight: 10.0, status: 'REQUESTED'),
        ScrapLotModel(id: 'SCRAP-0002', material: 'Aluminum', estimatedWeight: 20.0, status: 'ACCEPTED'),
      ]);

      await tester.pumpWidget(
        createTestEnvironment(
          authProvider: auth,
          lotProvider: lot,
          child: const ProfileTab(),
        ),
      );

      // Verify avatar initial
      expect(find.text('P'), findsOneWidget);

      // Verify user info
      expect(find.text('Poo Mathan'), findsOneWidget);
      expect(find.text('VERIFIED COLLECTOR'), findsOneWidget);
      expect(find.text('collector@scraplink.com'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      // Verify total lots tile
      expect(find.text('Total Lots'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify Total Earnings tile
      expect(find.text('Total Earnings'), findsOneWidget);

      // Verify actions
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Tap Logout to verify confirmation dialog
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out of your ScrapLink Collector account?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('HomeShell renders notification bell icon', (tester) async {
      final auth = AuthProvider();
      final lot = LotProvider();

      await tester.pumpWidget(
        createTestEnvironment(
          authProvider: auth,
          lotProvider: lot,
          child: const HomeShell(),
        ),
      );

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });
  });
}
