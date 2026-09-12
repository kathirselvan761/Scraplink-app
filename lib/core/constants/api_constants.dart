/// API Constants reflecting the exact endpoints provided by the existing
/// ScrapLink Backend API server.
class ApiConstants {
  ApiConstants._();

  // Standard Development Host & Base URLs
  // 1. Localhost (Used for Desktop, Web, and Physical Android via `adb reverse tcp:5000 tcp:5000`)
  static const String defaultLocalBaseUrl = 'http://localhost:5000/api';

  // 2. Wi-Fi / LAN IP (Direct access across local Wi-Fi router for physical devices)
  static const String defaultLanBaseUrl = 'http://192.168.1.18:5000/api';

  // 3. Android Emulator Loopback (Only for QEMU/Android Studio virtual devices)
  static const String defaultAndroidEmulatorBaseUrl = 'http://10.0.2.2:5000/api';

  // Health Check
  static const String health = '/health';

  // Scrap Lots / Collections (Existing backend endpoints in scrapLotRoutes.js)
  static const String lots = '/lots';
  static const String nextLotId = '/lots/next-id';
  static String lotById(String lotId) => '/lots/$lotId';
  static String lotStatus(String lotId) => '/lots/$lotId/status';

  // Tracking Endpoints (Existing backend endpoints in trackingRoutes.js)
  static String tracking(String lotId) => '/tracking/$lotId';
  static String trackingStatus(String lotId) => '/tracking/$lotId/status';

  // Collector Endpoints (Existing backend endpoints in collectorRoutes.js)
  static const String collectors = '/collectors';
  static String collectorById(int id) => '/collectors/$id';

  // Recycler Endpoints (Existing backend endpoints in recyclerRoutes.js)
  static const String recyclers = '/recyclers';
  static String recyclerById(int id) => '/recyclers/$id';
  static const String nearbyRecyclers = '/recyclers/nearby';
  static const String recyclerCollections = '/recycler/collections';

  // Price Endpoints (Existing backend endpoints in priceRoutes.js)
  static const String prices = '/prices';
  static const String calculatePrice = '/prices/calculate';

  // Authentication Endpoints (Existing backend endpoints in authRoutes.js)
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';

  // Standard Header Keys
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';
  static const String contentTypeJson = 'application/json';
}
