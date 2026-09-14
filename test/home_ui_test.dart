import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scraplink_collector/config/app_theme.dart';
import 'package:scraplink_collector/models/user_model.dart';
import 'package:scraplink_collector/models/scrap_lot_model.dart';
import 'package:scraplink_collector/providers/auth_provider.dart';
import 'package:scraplink_collector/providers/lot_provider.dart';
import 'package:scraplink_collector/screens/home/home_shell.dart';
import 'package:scraplink_collector/screens/home/home_tab.dart';
import 'package:scraplink_collector/widgets/status_badge.dart';
import 'package:scraplink_collector/widgets/lot_card.dart';
import 'package:scraplink_collector/widgets/empty_state.dart';

Widget createHomeTestApp({
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

  group('Home UI & Dashboard Tests', () {
    testWidgets('HomeShell displays 4 navigation tabs and app bar', (tester) async {
      final auth = AuthProvider();
      final lot = LotProvider();

      await tester.pumpWidget(
        createHomeTestApp(
          authProvider: auth,
          lotProvider: lot,
          child: const HomeShell(),
        ),
      );

      expect(find.text('ScrapLink'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Lots'), findsOneWidget);
      expect(find.text('Scan QR'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('HomeTab displays greeting, 4 stat cards, and FAB', (tester) async {
      final auth = AuthProvider();
      auth.setUser(UserModel(name: 'Poo Mathan', email: 'collector@scraplink.com', role: 'collector'));

      final lot = LotProvider();
      lot.setLots([
        ScrapLotModel(id: 'SCRAP-0001', material: 'Copper', estimatedWeight: 10.0, status: 'REQUESTED'),
        ScrapLotModel(id: 'SCRAP-0002', material: 'Aluminum', estimatedWeight: 25.0, status: 'COLLECTED'),
        ScrapLotModel(id: 'SCRAP-0003', material: 'Steel', estimatedWeight: 50.0, status: 'COMPLETED'),
      ]);

      await tester.pumpWidget(
        createHomeTestApp(
          authProvider: auth,
          lotProvider: lot,
          child: const HomeTab(),
        ),
      );

      // Greeting
      expect(find.text('Hi, Poo Mathan!'), findsOneWidget);

      // 4 Stat Cards
      expect(find.text('Total Lots'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Total
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(3)); // 1 for requested, 1 for in-progress, 1 for completed

      // Recent Lots
      expect(find.text('Recent Lots'), findsOneWidget);
      expect(find.text('Copper'), findsOneWidget);
      expect(find.text('Aluminum'), findsOneWidget);
      expect(find.text('Steel'), findsOneWidget);

      // FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Scrap'), findsOneWidget);
    });

    testWidgets('StatusBadge renders custom color chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'REQUESTED'),
                StatusBadge(status: 'COLLECTED'),
                StatusBadge(status: 'COMPLETED'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('REQUESTED'), findsOneWidget);
      expect(find.text('COLLECTED'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
    });

    testWidgets('LotCard renders material, weight and ID', (tester) async {
      final sampleLot = ScrapLotModel(
        id: 'SCRAP-0007',
        material: 'Copper Wire',
        estimatedWeight: 12.5,
        status: 'COLLECTED',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LotCard(lot: sampleLot),
          ),
        ),
      );

      expect(find.text('Copper Wire'), findsOneWidget);
      expect(find.text('12.5 kg'), findsOneWidget);
      expect(find.text('•  ID: SCRAP-0007'), findsOneWidget);
      expect(find.text('COLLECTED'), findsOneWidget);
    });

    testWidgets('EmptyState displays icon, title, message and triggers action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Empty Box',
              message: 'Nothing to see here',
              buttonText: 'Click Me',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Empty Box'), findsOneWidget);
      expect(find.text('Nothing to see here'), findsOneWidget);
      expect(find.text('Click Me'), findsOneWidget);

      await tester.tap(find.text('Click Me'));
      await tester.pump();

      expect(actionTriggered, true);
    });
  });
}
