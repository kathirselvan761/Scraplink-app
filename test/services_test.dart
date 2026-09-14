import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scraplink_collector/config/api_config.dart';
import 'package:scraplink_collector/services/storage_service.dart';
import 'package:scraplink_collector/services/api_service.dart';
import 'package:scraplink_collector/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageService Tests', () {
    test('Token save, retrieve, and delete', () async {
      expect(await StorageService.isLoggedIn(), false);
      expect(await StorageService.getToken(), isNull);

      await StorageService.saveToken('dummy_jwt_token_123');
      expect(await StorageService.getToken(), 'dummy_jwt_token_123');
      expect(await StorageService.isLoggedIn(), true);

      await StorageService.deleteToken();
      expect(await StorageService.getToken(), isNull);
      expect(await StorageService.isLoggedIn(), false);
    });

    test('User data save, retrieve, and delete', () async {
      expect(await StorageService.getUser(), isNull);

      final testUser = {
        'id': 42,
        'name': 'Poo Mathan',
        'email': 'collector@scraplink.com',
        'role': 'collector',
      };

      await StorageService.saveUser(testUser);
      final retrieved = await StorageService.getUser();
      expect(retrieved, isNotNull);
      expect(retrieved?['id'], 42);
      expect(retrieved?['role'], 'collector');

      await StorageService.deleteUser();
      expect(await StorageService.getUser(), isNull);
    });
  });

  group('ApiConfig Tests', () {
    test('Endpoints getters are defined', () {
      expect(ApiConfig.login, '/auth/login');
      expect(ApiConfig.register, '/auth/register');
      expect(ApiConfig.me, '/auth/me');
      expect(ApiConfig.lots, '/lots');
      expect(ApiConfig.createLot, '/lots/create');
      expect(ApiConfig.lotDetail(5), '/lots/5');
      expect(ApiConfig.prices, '/prices');
      expect(ApiConfig.materials, '/materials');
      expect(ApiConfig.generateQr(12), '/recyclers/collections/12/generate-qr');
      expect(ApiConfig.validateQr, '/qr/validate');
      expect(ApiConfig.handoverQr, '/qr/handover');
      expect(ApiConfig.notifications, '/notifications');
      expect(ApiConfig.unreadNotificationsCount, '/notifications/unread-count');
      expect(ApiConfig.recyclers, '/recyclers');
      expect(ApiConfig.registerRecycler, '/register-recycler');
      expect(ApiConfig.payments, '/payments');
      expect(ApiConfig.paymentDetail(8), '/payments/8');
    });
  });

  group('ApiService and AuthService Stubs', () {
    test('ApiService singleton instance', () {
      final api1 = ApiService();
      final api2 = ApiService();
      expect(identical(api1, api2), true);
    });

    test('ApiException holds message and statusCode', () {
      final ex = ApiException('Unauthorized access', 401);
      expect(ex.message, 'Unauthorized access');
      expect(ex.statusCode, 401);
      expect(ex.toString(), 'Unauthorized access');
    });

    test('AuthService instantiates cleanly', () {
      final authService = AuthService();
      expect(authService, isNotNull);
    });
  });
}
