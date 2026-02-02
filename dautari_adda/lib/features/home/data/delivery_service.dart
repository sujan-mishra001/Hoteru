import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class DeliveryService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getDeliveryPartners() async {
    try {
      final response = await _apiService.get('/delivery');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createDeliveryPartner(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/delivery', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDeliveryPartner(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/delivery/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDeliveryPartner(int id) async {
    try {
      final response = await _apiService.delete('/delivery/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
