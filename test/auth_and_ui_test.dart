import 'dart:convert';
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
import 'package:application/screens/profile/profile_screen.dart';
import 'package:application/widgets/stat_card.dart';
import 'package:application/widgets/collection_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService & AuthRepository Tests', () {
    test('AuthService logs in collector and returns token and collector model', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'collector@demo.scraplink.local');
        expect(body['password'], 'Collector@123');

        return http.Response(
          jsonEncode({
            'success': true,
            'token': 'mock-jwt-collector-token',
            'user': {
              'id': 2,
              'name': 'DEMO - Collector User',
              'email': 'collector@demo.scraplink.local',
              'phone': '+91 9000000002',
              'role': 'collector',
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
      final result = await authService.login(
        identifier: 'collector@demo.scraplink.local',
        password: 'Collector@123',
      );

      expect(result.token, 'mock-jwt-collector-token');
      expect(result.collector.id, 2);
      expect(result.collector.name, 'DEMO - Collector User');
      expect(result.collector.role, 'collector');
    });

    test('AuthService rejects non-collector roles with 403 ApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'token': 'mock-recycler-token',
            'user': {
              'id': 3,
              'name': 'DEMO - Recycler Partner',
              'email': 'recycler@demo.scraplink.local',
              'role': 'recycler', // Recycler role instead of collector
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
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('SessionService saves and restores session', () async {
      final sessionService = SessionService();
      const testCollector = Collector(
        id: 2,
        name: 'DEMO - Collector User',
        email: 'collector@demo.scraplink.local',
        phone: '+91 9000000002',
      );

      await sessionService.saveSession(
        token: 'test-token-12345',
        collector: testCollector,
      );

      final token = await sessionService.getToken();
      final collector = await sessionService.getCollector();

      expect(token, 'test-token-12345');
      expect(collector?.id, 2);
      expect(collector?.name, 'DEMO - Collector User');

      await sessionService.clearSession();
      expect(await sessionService.getToken(), isNull);
      expect(await sessionService.getCollector(), isNull);
    });
  });

  group('UI Widgets Tests', () {
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

    testWidgets('ProfileScreen renders collector information and logout button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      expect(find.text('Collector Profile'), findsOneWidget);
      expect(find.text('AUTHORIZED COLLECTOR'), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Log Out Session', skipOffstage: false), findsOneWidget);
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

