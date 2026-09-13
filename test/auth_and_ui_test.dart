import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application/core/config/app_config.dart';
import 'package:application/core/network/api_client.dart';
import 'package:application/core/network/api_exception.dart';
import 'package:application/models/collector.dart';
import 'package:application/models/collection.dart';
import 'package:application/models/collection_status.dart';
import 'package:application/models/scrap.dart';
import 'package:application/services/auth_service.dart';
import 'package:application/services/session_service.dart';
import 'package:application/screens/auth/login_screen.dart';
import 'package:application/screens/dashboard/dashboard_screen.dart';
import 'package:application/widgets/stat_card.dart';
import 'package:application/widgets/collection_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step 1 Collector Authentication Test Matrix (CASES 1-8)', () {
    // CASE 1: Valid Collector credentials -> Login succeeds
    test('CASE 1: Valid Collector credentials -> Login succeeds and returns token & collector', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'collector@demo.scraplink.local');
        expect(body['password'], 'Collector@123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'token': 'mock-jwt-collector-token',
            'user': {
              'id': 2,
              'name': 'DEMO - Collector User',
              'email': 'collector@demo.scraplink.local',
              'phone': '+91 9000000002',
              'role': 'collector',
              'is_active': 1,
              'status': 'ACTIVE',
            }
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final authService = AuthService(client: apiClient);
      final result = await authService.login(
        identifier: 'collector@demo.scraplink.local',
        password: 'Collector@123',
      );

      expect(result.token, 'mock-jwt-collector-token');
      expect(result.collector.id, 2);
      expect(result.collector.name, 'DEMO - Collector User');
      expect(result.collector.email, 'collector@demo.scraplink.local');
      expect(result.collector.phone, '+91 9000000002');
      expect(result.collector.role, 'collector');
      expect(result.collector.isActive, isTrue);
    });

    // CASE 2: Invalid password -> Backend rejects (HTTP 401)
    test('CASE 2: Invalid password -> Backend rejects with 401 and error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid email or password',
          }),
          401,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final authService = AuthService(client: apiClient);

      expect(
        () => authService.login(
          identifier: 'collector@demo.scraplink.local',
          password: 'WrongPassword!',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Invalid email or password')),
      );
    });

    // CASE 3: Invalid Collector ID/email -> Backend rejects (HTTP 401)
    test('CASE 3: Invalid Collector ID/email -> Backend rejects with 401 and error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid email or password',
          }),
          401,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final authService = AuthService(client: apiClient);

      expect(
        () => authService.login(
          identifier: 'nonexistent@demo.scraplink.local',
          password: 'Collector@123',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Invalid email or password')),
      );
    });

    // CASE 4: Non-Collector account -> Access denied
    test('CASE 4: Non-Collector account (e.g. recycler) -> Access denied with 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'token': 'mock-recycler-token',
            'user': {
              'id': 3,
              'name': 'DEMO - Recycler Partner',
              'email': 'recycler@demo.scraplink.local',
              'role': 'recycler',
              'is_active': 1,
            }
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final authService = AuthService(client: apiClient);

      expect(
        () => authService.login(
          identifier: 'recycler@demo.scraplink.local',
          password: 'Password@123',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.message, 'message', contains('Access Restricted: This application is only for verified collectors'))),
      );
    });

    // CASE 5: Inactive Collector -> Access denied according to backend rules (HTTP 401 deactivated)
    test('CASE 5: Inactive Collector -> Backend rejects with 401 User account is deactivated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'User account is deactivated',
          }),
          401,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final authService = AuthService(client: apiClient);

      expect(
        () => authService.login(
          identifier: 'collector@demo.scraplink.local',
          password: 'Collector@123',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'User account is deactivated')),
      );
    });

    // CASE 6: Backend unavailable -> Proper network/server error
    test('CASE 6: Backend unavailable -> Throws network/unreachable ApiException', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Connection refused');
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final authService = AuthService(client: apiClient);

      expect(
        () => authService.login(
          identifier: 'collector@demo.scraplink.local',
          password: 'Collector@123',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.type, 'type', ApiExceptionType.unreachable)),
      );
    });

    // CASE 7: Close and reopen app -> Existing valid session is restored
    test('CASE 7: App restart restores saved token and collector profile', () async {
      final sessionService = SessionService();
      const testCollector = Collector(
        id: 2,
        name: 'DEMO - Collector User',
        email: 'collector@demo.scraplink.local',
        phone: '+91 9000000002',
        role: 'collector',
      );

      // Simulate prior successful login
      await sessionService.saveSession(
        token: 'persisted-jwt-collector-token',
        collector: testCollector,
      );

      expect(await sessionService.hasValidSession(), isTrue);

      final token = await sessionService.getToken();
      final collector = await sessionService.getCollector();

      expect(token, 'persisted-jwt-collector-token');
      expect(collector?.id, 2);
      expect(collector?.name, 'DEMO - Collector User');
      expect(collector?.email, 'collector@demo.scraplink.local');
      expect(collector?.role, 'collector');
    });

    // CASE 8: Logout -> Session/token cleared -> Session becomes invalid
    test('CASE 8: Logout clears session and token from storage', () async {
      final sessionService = SessionService();
      const testCollector = Collector(
        id: 2,
        name: 'DEMO - Collector User',
        email: 'collector@demo.scraplink.local',
      );

      await sessionService.saveSession(
        token: 'active-session-token',
        collector: testCollector,
      );

      expect(await sessionService.hasValidSession(), isTrue);

      // Execute logout
      await sessionService.clearSession();

      expect(await sessionService.hasValidSession(), isFalse);
      expect(await sessionService.getToken(), isNull);
      expect(await sessionService.getCollector(), isNull);
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('LoginScreen renders inputs, buttons, and credentials card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Collector Login'), findsOneWidget);
      expect(find.text('Collector Email / ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In to Dashboard'), findsOneWidget);
      expect(find.text('Backend Collector Credentials'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders collector info and active session details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );

      expect(find.text('Collector Dashboard'), findsOneWidget);
      expect(find.text('Authentication Verified'), findsOneWidget);
      expect(find.text('COLLECTOR'), findsOneWidget);
      expect(find.text('COLLECTOR (Granted)'), findsOneWidget);
      expect(find.text('ACTIVE SESSION DETAILS'), findsOneWidget);
      expect(find.text('Log Out of Collector Session'), findsOneWidget);
    });

    testWidgets('StatCard renders title, value, and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Assigned Collections',
              value: '12',
              icon: Icons.assignment_outlined,
              accentColor: Color(0xFF3B82F6),
            ),
          ),
        ),
      );

      expect(find.text('Assigned Collections'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('CollectionCard renders scrap id, customer, material and handles tap', (tester) async {
      final collection = Collection(
        scrap: const Scrap(
          id: 5,
          lotId: 'SCRAP-0005',
          collectorId: 2,
          material: 'Copper',
          weight: 10.0,
          estimatedPrice: 5000.0,
          notes: 'Anna Nagar Collection Site',
        ),
        status: CollectionStatus.collectionAssigned,
        customerName: 'Priya Sharma',
      );

      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionCard(
              collection: collection,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('SCRAP-0005'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Copper'), findsOneWidget);
      expect(find.text('Anna Nagar Collection Site'), findsOneWidget);

      await tester.tap(find.byType(CollectionCard));
      expect(tapped, isTrue);
    });
  });
}
