import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:application/core/config/app_config.dart';
import 'package:application/core/network/api_client.dart';
import 'package:application/core/network/api_exception.dart' show ApiException;
import 'package:application/models/collection.dart';
import 'package:application/models/collection_status.dart';
import 'package:application/models/collector.dart';
import 'package:application/models/recycler.dart';
import 'package:application/models/scrap.dart';
import 'package:application/models/material_item.dart';
import 'package:application/models/recycler_request.dart';
import 'package:application/services/collection_service.dart';
import 'package:application/services/material_service.dart';
import 'package:application/services/offer_service.dart';
import 'package:application/services/scrap_service.dart';
import 'package:application/services/tracking_service.dart';
import 'package:application/repositories/collection_repository.dart';

void main() {
  group('CollectionStatus Enum Mapping', () {
    test('Maps backend status strings to enum correctly', () {
      expect(
        CollectionStatus.fromString('REQUESTED'),
        CollectionStatus.requested,
      );
      expect(
        CollectionStatus.fromString('ACCEPTED'),
        CollectionStatus.accepted,
      );
      expect(
        CollectionStatus.fromString('COLLECTION_ASSIGNED'),
        CollectionStatus.collectionAssigned,
      );
      expect(
        CollectionStatus.fromString('PICKUP_IN_PROGRESS'),
        CollectionStatus.pickupInProgress,
      );
      expect(
        CollectionStatus.fromString('COLLECTED'),
        CollectionStatus.collected,
      );
      expect(CollectionStatus.fromString('WEIGHED'), CollectionStatus.weighed);
      expect(
        CollectionStatus.fromString('RECEIVED'),
        CollectionStatus.received,
      );
      expect(
        CollectionStatus.fromString('PROCESSING'),
        CollectionStatus.processing,
      );
      expect(
        CollectionStatus.fromString('RECYCLED'),
        CollectionStatus.recycled,
      );
      expect(
        CollectionStatus.fromString('COMPLETED'),
        CollectionStatus.completed,
      );
    });

    test('Maps legacy aliases cleanly', () {
      expect(CollectionStatus.fromString('CREATED'), CollectionStatus.created);
      expect(
        CollectionStatus.fromString('AVAILABLE'),
        CollectionStatus.available,
      );
      expect(
        CollectionStatus.fromString('PENDING'),
        CollectionStatus.requested,
      );
      expect(
        CollectionStatus.fromString('ASSIGNED'),
        CollectionStatus.collectionAssigned,
      );
    });

    test('toBackendString generates exact wire strings', () {
      expect(CollectionStatus.requested.toBackendString(), 'REQUESTED');
      expect(CollectionStatus.accepted.toBackendString(), 'ACCEPTED');
      expect(CollectionStatus.collected.toBackendString(), 'COLLECTED');
      expect(CollectionStatus.completed.toBackendString(), 'COMPLETED');
    });
  });

  group('Scrap Model & SCRAP-0005 Identity', () {
    test('Preserves SCRAP-0005 verbatim without secondary ID', () {
      final json = {
        'id': 5,
        'lot_id': 'SCRAP-0005',
        'collector_id': 2,
        'recycler_id': 1,
        'material': 'Copper',
        'weight': '10.00',
        'final_weight': null,
        'estimated_price': '5000.00',
        'status': 'REQUESTED',
        'notes': 'Chennai Central E-Waste Collection Point',
      };

      final scrap = Scrap.fromJson(json);
      expect(scrap.lotId, 'SCRAP-0005');
      expect(scrap.material, 'Copper');
      expect(scrap.weight, 10.0);
      expect(scrap.estimatedPrice, 5000.0);
      expect(scrap.collectorId, 2);

      final exported = scrap.toJson();
      expect(exported['lot_id'], 'SCRAP-0005');
      expect(exported['material'], 'Copper');
    });

    test('Handles 5-digit sequential lot ID format (SL-2026-00001)', () {
      final json = {
        'id': 1,
        'lot_id': 'SL-2026-00001',
        'collector_id': 2,
        'material': 'E-waste',
        'weight': 25.5,
        'estimated_price': 5610.0,
      };

      final scrap = Scrap.fromJson(json);
      expect(scrap.lotId, 'SL-2026-00001');
      expect(scrap.material, 'E-waste');
      expect(scrap.weight, 25.5);
    });
  });

  group('Collector & Recycler Models', () {
    test('Collector model parses backend users table schema', () {
      final json = {
        'id': 2,
        'name': 'DEMO - Collector User',
        'email': 'collector@demo.scraplink.local',
        'phone': '+91 9000000002',
        'role': 'collector',
        'is_active': 1,
        'total_lots': 3,
      };

      final collector = Collector.fromJson(json);
      expect(collector.id, 2);
      expect(collector.name, 'DEMO - Collector User');
      expect(collector.isActive, true);
      expect(collector.totalLots, 3);
    });

    test('Recycler model parses backend recyclers table schema', () {
      final json = {
        'id': 1,
        'name': 'DEMO - GreenMetal Recycling Hub',
        'email': 'greenmetal@demo.scraplink.local',
        'phone': '+91 9876543210',
        'address': '12 Industrial Zone, Chennai, TN',
        'authorized': 1,
        'rate_per_kg': '660.00',
        'status': 'ACTIVE',
        'verification_status': 'APPROVED',
      };

      final recycler = Recycler.fromJson(json);
      expect(recycler.id, 1);
      expect(recycler.name, 'DEMO - GreenMetal Recycling Hub');
      expect(recycler.authorized, true);
      expect(recycler.ratePerKg, 660.0);
    });
  });

  group('Collection Model', () {
    test('Parses full collection with status and party joins', () {
      final json = {
        'id': 5,
        'lot_id': 'SCRAP-0005',
        'collector_id': 2,
        'recycler_id': 1,
        'material': 'Copper',
        'weight': 10.00,
        'estimated_price': 5000.00,
        'status': 'ACCEPTED',
        'collector_name': 'DEMO - Collector User',
        'recycler_name': 'GreenMetal Hub',
        'tracking_history': [
          {'status': 'REQUESTED', 'notes': 'Scrap created'},
          {'status': 'ACCEPTED', 'notes': 'Recycler accepted request'},
        ],
      };

      final collection = Collection.fromJson(json);
      expect(collection.lotId, 'SCRAP-0005');
      expect(collection.status, CollectionStatus.accepted);
      expect(collection.collectorName, 'DEMO - Collector User');
      expect(collection.recyclerName, 'GreenMetal Hub');
      expect(collection.trackingHistory.length, 2);
      expect(collection.trackingHistory.first.status, 'REQUESTED');
    });
  });

  group('ApiClient and Services Mock Verification', () {
    test('ApiClient builds correct URI and handles successful GET', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/lots');
        expect(request.url.queryParameters['collector_id'], '2');

        return http.Response(
          jsonEncode({
            'success': true,
            'count': 1,
            'data': [
              {
                'id': 5,
                'lot_id': 'SCRAP-0005',
                'collector_id': 2,
                'material': 'Copper',
                'weight': 10.0,
                'estimated_price': 5000.0,
                'status': 'REQUESTED',
              },
            ],
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final collectionService = CollectionService(client: apiClient);
      final collections = await collectionService.getAssignedCollections(2);

      expect(collections.length, 1);
      expect(collections.first.lotId, 'SCRAP-0005');
      expect(collections.first.material, 'Copper');
      expect(collections.first.status, CollectionStatus.requested);
    });

    test('ApiClient handles HTTP 404 cleanly with ApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Scrap lot not found'}),
          404,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final scrapService = ScrapService(client: apiClient);

      expect(
        () => scrapService.getScrapLotById('NON-EXISTENT'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test(
      'CollectionRepository enforces collector isolation pre-check',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 5,
                'lot_id': 'SCRAP-0005',
                'collector_id': 99, // Owned by Collector 99
                'material': 'Copper',
                'weight': 10.0,
                'status': 'ACCEPTED',
              },
            }),
            200,
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          config: AppConfig(baseUrl: 'http://localhost:5000/api'),
        );

        final collectionRepo = CollectionRepository(
          service: CollectionService(client: apiClient),
        );

        // Collector 2 attempts to update collection owned by Collector 99
        expect(
          () => collectionRepo.updateStatus(
            'SCRAP-0005',
            CollectionStatus.collected,
            collectorIdVerification: 2,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('Collector Workflow & State Machine Tests', () {
    final repo = CollectionRepository();

    test('Collector state transitions strictly follow authorization matrix', () {
      // REQUESTED -> PICKUP_IN_PROGRESS
      expect(
        repo.getCollectorAllowedNextStatus(CollectionStatus.requested),
        CollectionStatus.pickupInProgress,
      );
      // COLLECTION_ASSIGNED -> PICKUP_IN_PROGRESS
      expect(
        repo.getCollectorAllowedNextStatus(CollectionStatus.collectionAssigned),
        CollectionStatus.pickupInProgress,
      );
      // ACCEPTED -> PICKUP_IN_PROGRESS
      expect(
        repo.getCollectorAllowedNextStatus(CollectionStatus.accepted),
        CollectionStatus.pickupInProgress,
      );
      // PICKUP_IN_PROGRESS -> COLLECTED
      expect(
        repo.getCollectorAllowedNextStatus(CollectionStatus.pickupInProgress),
        CollectionStatus.collected,
      );

      // Downstream recycler/admin stages must NOT permit collector transitions
      expect(repo.getCollectorAllowedNextStatus(CollectionStatus.collected), isNull);
      expect(repo.getCollectorAllowedNextStatus(CollectionStatus.weighed), isNull);
      expect(repo.getCollectorAllowedNextStatus(CollectionStatus.received), isNull);
      expect(repo.getCollectorAllowedNextStatus(CollectionStatus.processing), isNull);
      expect(repo.getCollectorAllowedNextStatus(CollectionStatus.completed), isNull);
    });

    test('isCollectorActionAllowed returns true only for collector actionable states', () {
      expect(repo.isCollectorActionAllowed(CollectionStatus.requested), isTrue);
      expect(repo.isCollectorActionAllowed(CollectionStatus.collectionAssigned), isTrue);
      expect(repo.isCollectorActionAllowed(CollectionStatus.pickupInProgress), isTrue);
      expect(repo.isCollectorActionAllowed(CollectionStatus.collected), isFalse);
      expect(repo.isCollectorActionAllowed(CollectionStatus.completed), isFalse);
    });

    test('getCollectorActionLabel returns user-friendly labels', () {
      expect(
        repo.getCollectorActionLabel(CollectionStatus.collectionAssigned),
        'Start Pickup (En Route)',
      );
      expect(
        repo.getCollectorActionLabel(CollectionStatus.pickupInProgress),
        'Confirm Scrap Collected',
      );
      expect(
        repo.getCollectorActionLabel(CollectionStatus.collected),
        'Collected (Awaiting Recycler Receipt)',
      );
      expect(
        repo.getCollectorActionLabel(CollectionStatus.completed),
        'Collection Completed',
      );
    });

    test('canStartPickup, isPickupInProgress, and canMarkCollected enforce strict state gates', () {
      // canStartPickup
      expect(repo.canStartPickup(CollectionStatus.requested), isTrue);
      expect(repo.canStartPickup(CollectionStatus.collectionAssigned), isTrue);
      expect(repo.canStartPickup(CollectionStatus.accepted), isTrue);
      expect(repo.canStartPickup(CollectionStatus.pickupInProgress), isFalse);
      expect(repo.canStartPickup(CollectionStatus.collected), isFalse);

      // isPickupInProgress
      expect(repo.isPickupInProgress(CollectionStatus.pickupInProgress), isTrue);
      expect(repo.isPickupInProgress(CollectionStatus.inTransit), isTrue);
      expect(repo.isPickupInProgress(CollectionStatus.collectionAssigned), isFalse);
      expect(repo.isPickupInProgress(CollectionStatus.collected), isFalse);

      // canMarkCollected
      expect(repo.canMarkCollected(CollectionStatus.pickupInProgress), isTrue);
      expect(repo.canMarkCollected(CollectionStatus.inTransit), isTrue);
      expect(repo.canMarkCollected(CollectionStatus.collectionAssigned), isFalse);
      expect(repo.canMarkCollected(CollectionStatus.collected), isFalse);
    });

    test('Collection customer and address getters extract real backend fields with fallback', () {
      final jsonWithNotes = {
        'id': 5,
        'lot_id': 'SCRAP-0005',
        'collector_id': 2,
        'material': 'Copper',
        'weight': 10.0,
        'status': 'COLLECTION_ASSIGNED',
        'notes': 'Flat 402, Green Heights, Anna Nagar, Chennai',
        'customer_name': 'Ramesh Kumar',
        'customer_phone': '+91 9840123456',
      };
      final col = Collection.fromJson(jsonWithNotes);

      expect(col.displayCustomerName, 'Ramesh Kumar');
      expect(col.customerPhone, '+91 9840123456');
      expect(col.pickupAddress, 'Flat 402, Green Heights, Anna Nagar, Chennai');

      // Fallback when customer_name is null
      final jsonFallback = {
        'id': 6,
        'lot_id': 'SCRAP-0006',
        'collector_id': 2,
        'material': 'Aluminum',
        'weight': 5.0,
        'status': 'REQUESTED',
      };
      final colFallback = Collection.fromJson(jsonFallback);
      expect(colFallback.displayCustomerName, 'Residential Collection');
      expect(colFallback.pickupAddress, 'Regional Collection Point, Chennai');
    });

    test('updateStatus calls real backend endpoint PUT /api/lots/:lotId/status for PICKUP_IN_PROGRESS', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/lots/SCRAP-0005/status');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], 'PICKUP_IN_PROGRESS');
        expect(body['notes'], contains('Collector began pickup'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 5,
              'lot_id': 'SCRAP-0005',
              'collector_id': 2,
              'material': 'Copper',
              'weight': 10.0,
              'status': 'PICKUP_IN_PROGRESS',
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final customRepo = CollectionRepository(
        service: CollectionService(client: apiClient),
      );

      final result = await customRepo.updateStatus(
        'SCRAP-0005',
        CollectionStatus.pickupInProgress,
      );

      expect(result.lotId, 'SCRAP-0005');
      expect(result.status, CollectionStatus.pickupInProgress);
    });

    test('updateStatus calls real backend endpoint PUT /api/lots/:lotId/status for COLLECTED', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/lots/SCRAP-0005/status');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], 'COLLECTED');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 5,
              'lot_id': 'SCRAP-0005',
              'collector_id': 2,
              'material': 'Copper',
              'weight': 10.0,
              'status': 'COLLECTED',
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final customRepo = CollectionRepository(
        service: CollectionService(client: apiClient),
      );

      final result = await customRepo.updateStatus(
        'SCRAP-0005',
        CollectionStatus.collected,
      );

      expect(result.lotId, 'SCRAP-0005');
      expect(result.status, CollectionStatus.collected);
    });

    test('updateStatus handles backend 409 conflict and 403 forbidden cleanly with ApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Status conflict: lot already in state COLLECTED',
          }),
          409,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final customRepo = CollectionRepository(
        service: CollectionService(client: apiClient),
      );

      expect(
        () => customRepo.updateStatus('SCRAP-0005', CollectionStatus.pickupInProgress),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );
    });
  });

  group('MaterialService & Pricing Tests', () {
    test('MaterialItem parses backend prices row and defaults work', () {
      final json = {
        'id': 1,
        'material': 'Copper',
        'price_per_kg': '650.00',
        'is_active': 1,
      };
      final item = MaterialItem.fromJson(json);
      expect(item.id, 1);
      expect(item.material, 'Copper');
      expect(item.pricePerKg, 650.0);
      expect(item.isActive, isTrue);

      expect(MaterialItem.defaultMaterials.isNotEmpty, isTrue);
      expect(MaterialItem.defaultMaterials.first.material, 'Copper');
    });

    test('MaterialService retrieves materials from GET /api/prices', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/prices');
        return http.Response(
          jsonEncode({
            'success': true,
            'count': 2,
            'data': [
              {'id': 1, 'material': 'Copper', 'price_per_kg': 650.0},
              {'id': 2, 'material': 'Aluminum', 'price_per_kg': 180.0},
            ],
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final service = MaterialService(client: apiClient);
      final list = await service.getActiveMaterials();
      expect(list.length, 2);
      expect(list[0].material, 'Copper');
      expect(list[1].pricePerKg, 180.0);
    });

    test('MaterialService calculates price for material & weight', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/prices/Copper');
        expect(request.url.queryParameters['weight'], '10.0');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'material': 'Copper',
              'weight_kg': 10.0,
              'price_per_kg': 650.0,
              'estimated_price': 6500.0,
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final service = MaterialService(client: apiClient);
      final price = await service.calculateEstimatedPrice('Copper', 10.0);
      expect(price, 6500.0);
    });
  });

  group('ScrapService Add Scrap & Canonical ID Tests', () {
    test('createScrapLot sends POST /api/lots and receives canonical SL-2026-00001 ID', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/lots');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Scrap lot created successfully',
            'data': {
              'id': 12,
              'lot_id': 'SL-2026-00001',
              'collector_id': 2,
              'material': 'E-waste',
              'weight': 15.5,
              'estimated_price': 3410.0,
              'status': 'AVAILABLE',
              'notes': 'Old computer motherboards',
            },
          }),
          201,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final service = ScrapService(client: apiClient);
      final scrap = await service.createScrapLot(
        material: 'E-waste',
        weight: 15.5,
        estimatedPrice: 3410.0,
        notes: 'Old computer motherboards',
        collectorId: 2,
      );

      expect(scrap.lotId, 'SL-2026-00001');
      expect(scrap.material, 'E-waste');
      expect(scrap.weight, 15.5);
      expect(scrap.estimatedPrice, 3410.0);
      expect(scrap.status, CollectionStatus.available);
    });
  });

  group('RecyclerRequest & Handover Tests', () {
    test('RecyclerRequest model correctly parses backend offer JSON', () {
      final json = {
        'id': 101,
        'lot_id': 'SL-2026-00001',
        'recycler_id': 1,
        'recycler_name': 'GreenMetal Recycling Hub',
        'recycler_phone': '+91 9876543210',
        'material': 'Copper Wire',
        'weight': '12.5',
        'offered_rate': '660.00',
        'offer_amount': '8250.00',
        'status': 'PENDING',
      };

      final req = RecyclerRequest.fromJson(json);
      expect(req.id, 101);
      expect(req.lotId, 'SL-2026-00001');
      expect(req.recyclerName, 'GreenMetal Recycling Hub');
      expect(req.weight, 12.5);
      expect(req.offeredRate, 660.0);
      expect(req.offerAmount, 8250.0);
      expect(req.isPending, isTrue);
      expect(req.isCompleted, isFalse);
    });

    test('confirmHandover calls real POST /api/qr/handover endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/qr/handover');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['scrap_request_id'], 'SL-2026-00001');
        expect(body['final_weight'], 12.5);

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Handover confirmed for SL-2026-00001. Status updated to RECEIVED.',
            'data': {
              'scrap_id': 'SL-2026-00001',
              'status': 'RECEIVED',
              'final_weight': 12.5,
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final offerService = OfferService(client: apiClient);
      final res = await offerService.confirmHandover(
        scrapRequestId: 'SL-2026-00001',
        finalWeight: 12.5,
      );

      expect(res['success'], isTrue);
      expect(res['data']['status'], 'RECEIVED');
    });
  });

  group('TrackingService Lifecycle Tests', () {
    test('getTrackingDetails calls GET /api/tracking/:lotId and parses events', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/tracking/SL-2026-00001');

        return http.Response(
          jsonEncode({
            'success': true,
            'lot_id': 'SL-2026-00001',
            'current_status': 'RECEIVED',
            'status_history': [
              {
                'status': 'AVAILABLE',
                'description': 'Scrap lot registered by Collector',
                'location': 'Koramangala, Bengaluru',
                'created_at': '2026-09-12T10:00:00Z',
              },
              {
                'status': 'RECEIVED',
                'description': 'Handover complete to Recycler',
                'location': 'GreenMetal Hub',
                'created_at': '2026-09-12T14:30:00Z',
              },
            ],
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        config: AppConfig(baseUrl: 'http://localhost:5000/api'),
      );

      final trackingService = TrackingService(client: apiClient);
      final events = await trackingService.getTrackingEvents('SL-2026-00001');

      expect(events.length, 2);
      expect(events[0].status, 'AVAILABLE');
      expect(events[1].status, 'RECEIVED');
      expect(events[1].notes, 'Handover complete to Recycler');
    });
  });
}


