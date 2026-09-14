import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/scrap_lot_model.dart';
import '../models/material_price_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class LotProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<ScrapLotModel> _myLots = [];
  List<MaterialPriceModel> _materialPrices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ScrapLotModel> get myLots => _myLots;
  List<MaterialPriceModel> get materialPrices => _materialPrices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setLots(List<ScrapLotModel> lots) {
    _myLots = lots;
    notifyListeners();
  }

  List<dynamic> _extractList(dynamic response, [String key = 'data']) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      if (response[key] is List) return response[key] as List;
      if (response['data'] is List) return response['data'] as List;
      if (response['lots'] is List) return response['lots'] as List;
      if (response['prices'] is List) return response['prices'] as List;
    }
    return [];
  }

  Future<void> loadMaterialPrices() async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _api.get(ApiConfig.prices);
      final list = _extractList(response, 'prices');
      _materialPrices = list
          .whereType<Map<String, dynamic>>()
          .map((item) => MaterialPriceModel.fromJson(item))
          .toList();
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load material prices: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> loadMyLots([int? collectorId]) async {
    _setLoading(true);
    _setError(null);
    try {
      int? cid = collectorId;
      if (cid == null) {
        final user = await StorageService.getUser();
        if (user != null && user['id'] != null) {
          cid = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
        }
      }

      final endpoint = cid != null ? '${ApiConfig.lots}?collector_id=$cid' : ApiConfig.lots;
      final response = await _api.get(endpoint);
      final list = _extractList(response, 'lots');
      _myLots = list
          .whereType<Map<String, dynamic>>()
          .map((item) => ScrapLotModel.fromJson(item))
          .toList();
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load lots: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<ScrapLotModel?> loadLotDetail(dynamic lotId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _api.get('${ApiConfig.lots}/$lotId');
      Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      } else if (data.containsKey('lot') && data['lot'] is Map<String, dynamic>) {
        data = data['lot'] as Map<String, dynamic>;
      }
      final lot = ScrapLotModel.fromJson(data);
      _setLoading(false);
      return lot;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Failed to load lot detail: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<ScrapLotModel?> createLot({
    required String material,
    required double weight,
    double? lat,
    double? lng,
    String? notes,
    File? imageFile,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final fields = <String, String>{
        'material': material,
        'material_type': material,
        'weight': weight.toString(),
        'estimated_weight': weight.toString(),
      };

      if (lat != null) fields['latitude'] = lat.toString();
      if (lng != null) fields['longitude'] = lng.toString();
      if (notes != null && notes.isNotEmpty) fields['notes'] = notes;

      List<http.MultipartFile>? files;
      if (imageFile != null) {
        files = [
          await http.MultipartFile.fromPath('image', imageFile.path),
        ];
      }

      final response = await _api.postMultipart(
        ApiConfig.lots,
        fields: fields,
        files: files,
      );

      Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      } else if (data.containsKey('lot') && data['lot'] is Map<String, dynamic>) {
        data = data['lot'] as Map<String, dynamic>;
      }

      final createdLot = ScrapLotModel.fromJson(data);

      // Reload lot list after creation
      await loadMyLots();

      _setLoading(false);
      return createdLot;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Failed to create scrap lot: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<dynamic> generateQr(dynamic lotId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _api.post(ApiConfig.generateQr(
        lotId is int ? lotId : int.tryParse(lotId.toString()) ?? 0,
      ));
      _setLoading(false);
      return response;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setError('Failed to generate QR: ${e.toString()}');
      _setLoading(false);
      rethrow;
    }
  }

  Future<dynamic> validateQr(String token) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _api.post(
        ApiConfig.validateQr,
        body: {'token': token, 'qr_token': token},
      );
      _setLoading(false);
      return response;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setError('Failed to validate QR: ${e.toString()}');
      _setLoading(false);
      rethrow;
    }
  }

  Future<dynamic> handoverQr(String token) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _api.post(
        ApiConfig.handoverQr,
        body: {'token': token, 'qr_token': token},
      );
      await loadMyLots();
      _setLoading(false);
      return response;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setError('Failed to complete handover: ${e.toString()}');
      _setLoading(false);
      rethrow;
    }
  }
}
