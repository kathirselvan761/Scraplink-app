import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scraplink_collector/providers/auth_provider.dart';
import 'package:scraplink_collector/providers/lot_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Providers Tests', () {
    test('AuthProvider initial state and checkAuthStatus with no token', () async {
      final authProvider = AuthProvider();
      expect(authProvider.currentUser, isNull);
      expect(authProvider.token, isNull);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);

      final loggedIn = await authProvider.checkAuthStatus();
      expect(loggedIn, false);
      expect(authProvider.isAuthenticated, false);
    });

    test('LotProvider initial state', () {
      final lotProvider = LotProvider();
      expect(lotProvider.myLots, isEmpty);
      expect(lotProvider.materialPrices, isEmpty);
      expect(lotProvider.isLoading, false);
      expect(lotProvider.errorMessage, isNull);
    });

    testWidgets('MultiProvider supplies AuthProvider and LotProvider to widget tree',
        (tester) async {
      late AuthProvider foundAuth;
      late LotProvider foundLot;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => LotProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                foundAuth = Provider.of<AuthProvider>(context, listen: false);
                foundLot = Provider.of<LotProvider>(context, listen: false);
                return const Scaffold(body: Text('Providers Loaded'));
              },
            ),
          ),
        ),
      );

      expect(find.text('Providers Loaded'), findsOneWidget);
      expect(foundAuth, isNotNull);
      expect(foundLot, isNotNull);
    });
  });
}
