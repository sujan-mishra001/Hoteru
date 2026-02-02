import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class FloorTableService {
  final ApiService _apiService = ApiService();

  // Floors
  Future<List<dynamic>> getFloors() async {
    try {
      final response = await _apiService.get('/floors');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createFloor(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/floors', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateFloor(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/floors/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFloor(int id) async {
    try {
      final response = await _apiService.delete('/floors/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Tables
  Future<List<dynamic>> getTables({int? floorId}) async {
    try {
      final url = floorId != null ? '/tables?floor_id=$floorId' : '/tables';
      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createTable(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/tables', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTable(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/tables/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTable(int id) async {
    try {
      final response = await _apiService.delete('/tables/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTableStatus(int id, String status) async {
    try {
      final response = await _apiService.patch('/tables/$id', {'status': status});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
