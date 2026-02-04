import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dautari_adda/core/api/api_service.dart';

class FloorTableService {
  final ApiService _apiService = ApiService();

  // Floors
  Future<List<dynamic>> getFloors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final branchId = prefs.getInt('selectedBranchId');
      String url = '/floors';
      if (branchId != null) url += '?branch_id=$branchId';
      
      final response = await _apiService.get(url);
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
      final prefs = await SharedPreferences.getInstance();
      final branchId = prefs.getInt('selectedBranchId');
      
      final params = <String>[];
      if (floorId != null) params.add('floor_id=$floorId');
      if (branchId != null) params.add('branch_id=$branchId');
      
      String url = '/tables';
      if (params.isNotEmpty) url += '?${params.join('&')}';
      
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
