import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scraplink_collector/config/app_theme.dart';
import 'package:scraplink_collector/models/scrap_lot_model.dart';
import 'package:scraplink_collector/providers/auth_provider.dart';
import 'package:scraplink_collector/providers/lot_provider.dart';
import 'package:scraplink_collector/screens/qr/qr_display_screen.dart';
import 'package:scraplink_collector/screens/home/scan_qr_tab.dart';

Widget createQrTestApp({
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

  group('QR Workflow Tests', () {
    testWidgets('QrDisplayScreen renders QR code, countdown timer and lot metadata', (tester) async {
      final lotProvider = LotProvider();
      final testLot = ScrapLotModel(
        id: 'SCRAP-0042',
        material: 'Copper Wire',
        estimatedWeight: 18.5,
        status: 'COLLECTED',
        qrToken: 'SCRAPLINK:LOT:SCRAP-0042:SECURE',
      );

      lotProvider.setLots([testLot]);

      await tester.pumpWidget(
        createQrTestApp(
          lotProvider: lotProvider,
          child: QrDisplayScreen(
            lotId: 'SCRAP-0042',
            lot: testLot,
            qrData: 'SCRAPLINK:LOT:SCRAP-0042:SECURE',
          ),
        ),
      );

      await tester.pump();

      // App bar & QR header
      expect(find.text('QR Code - SCRAP-0042'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('SCRAPLINK:LOT:SCRAP-0042:SECURE'), findsOneWidget);

      // Metadata below QR
      expect(find.text('SCRAP-0042'), findsOneWidget);
      expect(find.text('Copper Wire'), findsOneWidget);
      expect(find.text('18.5 kg'), findsOneWidget);

      // Countdown timer
      expect(find.textContaining('Expires in:'), findsOneWidget);
    });

    testWidgets('ScanQrTab renders manual entry option and opens dialog', (tester) async {
      final lotProvider = LotProvider();

      await tester.pumpWidget(
        createQrTestApp(
          lotProvider: lotProvider,
          child: const ScanQrTab(),
        ),
      );

      // Verify manual entry button is present
      final manualBtn = find.text('Enter Code Manually');
      expect(manualBtn, findsOneWidget);

      // Tap manual entry
      await tester.tap(manualBtn);
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(find.text('Enter QR Code Token'), findsOneWidget);
      expect(find.text('Validate'), findsOneWidget);
    });
  });
}
