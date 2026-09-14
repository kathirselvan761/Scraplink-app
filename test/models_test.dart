import 'package:flutter_test/flutter_test.dart';
import 'package:scraplink_collector/models/user_model.dart';
import 'package:scraplink_collector/models/scrap_lot_model.dart';
import 'package:scraplink_collector/models/material_price_model.dart';
import 'package:scraplink_collector/models/notification_model.dart';
import 'package:scraplink_collector/models/payment_model.dart';

void main() {
  group('Data Models JSON Serialization Tests', () {
    test('UserModel fromJson & toJson', () {
      final json = {
        'id': 101,
        'name': 'Collector John',
        'email': 'john@collector.com',
        'phone': '1234567890',
        'role': 'collector',
        'created_at': '2026-09-13T10:00:00.000Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 101);
      expect(user.name, 'Collector John');
      expect(user.email, 'john@collector.com');
      expect(user.phone, '1234567890');
      expect(user.role, 'collector');
      expect(user.createdAt, isNotNull);

      final outJson = user.toJson();
      expect(outJson['name'], 'Collector John');
      expect(outJson['role'], 'collector');
      expect(outJson['created_at'], isNotNull);
    });

    test('ScrapLotModel fromJson & toJson with StatusHistoryItem', () {
      final json = {
        'id': 'SCRAP-0007',
        'collector_id': 12,
        'material': 'Copper Wire',
        'estimated_weight': 25.5,
        'final_weight': 24.8,
        'status': 'collected',
        'latitude': 13.0827,
        'longitude': 80.2707,
        'image_url': 'https://example.com/scrap.jpg',
        'notes': 'Pure copper scrap',
        'recycler_id': 5,
        'recycler_name': 'Green Recyclers Ltd',
        'qr_token': 'QR-SECURE-TOKEN-999',
        'created_at': '2026-09-13 14:30:00',
        'updated_at': '2026-09-13 15:00:00',
        'status_history': [
          {
            'status': 'pending',
            'timestamp': '2026-09-13 14:30:00',
            'actor': 'Collector John',
            'notes': 'Created lot'
          },
          {
            'status': 'collected',
            'timestamp': '2026-09-13 15:00:00',
            'actor': 'Collector John',
            'notes': 'Collected and weighed'
          }
        ]
      };

      final lot = ScrapLotModel.fromJson(json);
      expect(lot.id, 'SCRAP-0007');
      expect(lot.collectorId, 12);
      expect(lot.material, 'Copper Wire');
      expect(lot.estimatedWeight, 25.5);
      expect(lot.finalWeight, 24.8);
      expect(lot.status, 'collected');
      expect(lot.recyclerName, 'Green Recyclers Ltd');
      expect(lot.statusHistory.length, 2);
      expect(lot.statusHistory[0].status, 'pending');

      final outJson = lot.toJson();
      expect(outJson['id'], 'SCRAP-0007');
      expect(outJson['material'], 'Copper Wire');
      expect(outJson['status_history'], isA<List>());
    });

    test('MaterialPriceModel fromJson & toJson', () {
      final json = {
        'material': 'Aluminum',
        'price_per_kg': 145.50,
        'unit': 'kg',
        'updated_at': '2026-09-13T08:00:00.000Z',
      };

      final price = MaterialPriceModel.fromJson(json);
      expect(price.material, 'Aluminum');
      expect(price.pricePerKg, 145.50);
      expect(price.unit, 'kg');
      expect(price.updatedAt, isNotNull);

      final outJson = price.toJson();
      expect(outJson['material'], 'Aluminum');
      expect(outJson['price_per_kg'], 145.50);
    });

    test('NotificationModel fromJson & toJson', () {
      final json = {
        'id': 1,
        'title': 'New Lot Assigned',
        'message': 'Recycler requested collection for SCRAP-0007',
        'type': 'lot_assigned',
        'is_read': false,
        'related_id': 7,
        'created_at': '2026-09-13T12:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.id, 1);
      expect(notif.title, 'New Lot Assigned');
      expect(notif.isRead, false);
      expect(notif.relatedId, 7);

      final outJson = notif.toJson();
      expect(outJson['id'], 1);
      expect(outJson['is_read'], false);
    });

    test('PaymentModel fromJson & toJson', () {
      final json = {
        'id': 99,
        'scrap_id': 'SCRAP-0007',
        'recycler_name': 'Green Recyclers Ltd',
        'final_weight': 24.8,
        'price_per_kg': 145.50,
        'total_amount': 3608.40,
        'payment_status': 'completed',
        'transaction_id': 'TXN-987654321',
        'payment_date': '2026-09-13T16:00:00.000Z',
      };

      final payment = PaymentModel.fromJson(json);
      expect(payment.id, 99);
      expect(payment.scrapId, 'SCRAP-0007');
      expect(payment.totalAmount, 3608.40);
      expect(payment.paymentStatus, 'completed');
      expect(payment.transactionId, 'TXN-987654321');

      final outJson = payment.toJson();
      expect(outJson['id'], 99);
      expect(outJson['total_amount'], 3608.40);
    });
  });
}
