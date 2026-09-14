import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim();
    }
    return 'http://localhost:5000/api';
  }

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Lots endpoints
  static const String lots = '/lots';
  static const String createLot = '/lots/create';
  static String lotDetail(int id) => '/lots/$id';

  // Prices / Materials
  static const String prices = '/prices';
  static const String materials = '/materials';

  // QR endpoints
  static String generateQr(int id) => '/recyclers/collections/$id/generate-qr';
  static const String validateQr = '/qr/validate';
  static const String handoverQr = '/qr/handover';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadNotificationsCount = '/notifications/unread-count';
  static String markNotificationRead(dynamic id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // Recyclers
  static const String recyclers = '/recyclers';
  static const String registerRecycler = '/register-recycler';

  // Payments
  static const String payments = '/payments';
  static String paymentDetail(int id) => '/payments/$id';
}
