import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scraplink_collector/config/app_theme.dart';
import 'package:scraplink_collector/models/scrap_lot_model.dart';
import 'package:scraplink_collector/providers/auth_provider.dart';
import 'package:scraplink_collector/providers/lot_provider.dart';
import 'package:scraplink_collector/screens/home/my_lots_tab.dart';
import 'package:scraplink_collector/screens/scrap/lot_detail_screen.dart';
import 'package:scraplink_collector/screens/qr/qr_display_screen.dart';

Widget createLotTestApp({
  required LotProvider lotProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
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

  group('MyLotsTab and LotDetailScreen Tests', () {
    testWidgets('MyLotsTab filters lots using filter chips', (tester) async {
      final lotProvider = LotProvider();
      lotProvider.setLots([
        ScrapLotModel(id: 'SCRAP-0001', material: 'Copper', estimatedWeight: 10.0, status: 'REQUESTED'),
        ScrapLotModel(id: 'SCRAP-0002', material: 'Aluminum', estimatedWeight: 20.0, status: 'ACCEPTED'),
        ScrapLotModel(id: 'SCRAP-0003', material: 'Steel', estimatedWeight: 30.0, status: 'COMPLETED'),
      ]);

      await tester.pumpWidget(
        createLotTestApp(
          lotProvider: lotProvider,
          child: const MyLotsTab(),
        ),
      );

      // Verify all 3 lots are visible under 'All'
      expect(find.text('Copper'), findsOneWidget);
      expect(find.text('Aluminum'), findsOneWidget);
      expect(find.text('Steel'), findsOneWidget);

      // Tap 'Requested' filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Requested'));
      await tester.pumpAndSettle();

      // Only 'Copper' should be visible
      expect(find.text('Copper'), findsOneWidget);
      expect(find.text('Aluminum'), findsNothing);
      expect(find.text('Steel'), findsNothing);
    });

    testWidgets('LotDetailScreen renders lot details, timeline, and Show QR button', (tester) async {
      final lotProvider = LotProvider();
      final testLot = ScrapLotModel(
        id: 'SCRAP-0009',
        material: 'Heavy Copper',
        estimatedWeight: 45.0,
        finalWeight: 44.2,
        status: 'COLLECTED',
        latitude: 12.9716,
        longitude: 77.5946,
        recyclerName: 'Bangalore Recyclers Hub',
        qrToken: 'QR-TEST-TOKEN-0009',
        statusHistory: [
          StatusHistoryItem(
            status: 'REQUESTED',
            actor: 'Collector',
            notes: 'Created lot',
          ),
          StatusHistoryItem(
            status: 'COLLECTED',
            actor: 'Bangalore Recyclers Hub',
            notes: 'Weighed and collected',
          ),
        ],
      );

      lotProvider.setLots([testLot]);

      await tester.pumpWidget(
        createLotTestApp(
          lotProvider: lotProvider,
          child: LotDetailScreen(lotId: 'SCRAP-0009', lot: testLot),
        ),
      );
      await tester.pumpAndSettle();

      // Header info
      expect(find.text('Lot ID: SCRAP-0009'), findsOneWidget);
      expect(find.text('Heavy Copper'), findsOneWidget);

      // Weight card
      expect(find.text('Weight Verification'), findsOneWidget);
      expect(find.text('45.0 kg'), findsOneWidget);
      expect(find.text('44.2 kg'), findsOneWidget);

      // Coordinates card
      expect(find.text('Collection Coordinates'), findsOneWidget);
      expect(find.text('Open in Maps'), findsOneWidget);

      // Recycler card
      expect(find.text('Assigned Recycler'), findsOneWidget);
      expect(find.text('Bangalore Recyclers Hub'), findsOneWidget);

      // Journey Timeline
      expect(find.text('Journey Timeline'), findsOneWidget);
      expect(find.text('By: Collector'), findsOneWidget);
      expect(find.text('By: Bangalore Recyclers Hub'), findsOneWidget);

      // Bottom action button for COLLECTED status
      final showQrBtn = find.widgetWithText(ElevatedButton, 'Show Handover QR');
      expect(showQrBtn, findsOneWidget);

      // Tap button and verify navigation to QrDisplayScreen
      await tester.tap(showQrBtn);
      await tester.pumpAndSettle();

      expect(find.byType(QrDisplayScreen), findsOneWidget);
      expect(find.text('QR Code - SCRAP-0009'), findsOneWidget);
    });
  });
}
