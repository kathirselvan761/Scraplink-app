import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scraplink_collector/config/app_theme.dart';
import 'package:scraplink_collector/providers/auth_provider.dart';
import 'package:scraplink_collector/providers/lot_provider.dart';
import 'package:scraplink_collector/screens/scrap/create_lot_screen.dart';
import 'package:scraplink_collector/services/connectivity_service.dart';
import 'package:scraplink_collector/widgets/primary_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConnectivityService().mockIsOnline = true;
  });

  group('CreateLotScreen Widget Tests', () {
    testWidgets('Renders all 7 sections and calculates estimated payout', (tester) async {
      final lotProvider = LotProvider();
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<LotProvider>.value(value: lotProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateLotScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify sections are visible
      expect(find.text('Add Scrap Lot'), findsOneWidget);
      expect(find.text('Scrap Material'), findsOneWidget);
      expect(find.text('Estimated Weight (kg)'), findsOneWidget);
      expect(find.text('Scrap Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Collection Location'), findsOneWidget);
      expect(find.text('Notes (Optional)'), findsOneWidget);
      expect(find.text('Estimated Payout'), findsOneWidget);
      expect(find.text('₹0.00'), findsOneWidget);
      expect(find.widgetWithText(PrimaryButton, 'Submit Scrap Lot'), findsOneWidget);

      // Enter weight
      final weightField = find.widgetWithText(TextFormField, 'e.g. 25.5');
      await tester.enterText(weightField, '10');
      await tester.pump();

      // Payout should calculate when material is selected (initially 0 without selected material)
      expect(find.text('₹0.00'), findsOneWidget);
    });

    testWidgets('Form validation prevents submit when required fields are missing', (tester) async {
      final lotProvider = LotProvider();
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<LotProvider>.value(value: lotProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateLotScreen(),
          ),
        ),
      );
      await tester.pump();

      final submitBtn = find.widgetWithText(PrimaryButton, 'Submit Scrap Lot');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Weight validation error appears
      expect(find.text('Please enter the estimated weight'), findsOneWidget);
    });

    testWidgets('Blocks submit when offline with warning message', (tester) async {
      ConnectivityService().mockIsOnline = false;

      final lotProvider = LotProvider();
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<LotProvider>.value(value: lotProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateLotScreen(),
          ),
        ),
      );
      await tester.pump();

      final submitBtn = find.widgetWithText(PrimaryButton, 'Submit Scrap Lot');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No internet. Please try again when connected.'), findsOneWidget);
    });

    testWidgets('Shows confirmation dialog on back press when unsaved data exists', (tester) async {
      final lotProvider = LotProvider();
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<LotProvider>.value(value: lotProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateLotScreen(),
          ),
        ),
      );
      await tester.pump();

      // Enter some unsaved weight
      final weightField = find.widgetWithText(TextFormField, 'e.g. 25.5');
      await tester.enterText(weightField, '15.0');
      await tester.pump();

      // Simulate system back button
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirm dialog should appear
      expect(find.text('Discard Unsaved Scrap Lot?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });
  });
}
