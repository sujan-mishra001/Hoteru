import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dautari_adda/core/api/api_service.dart';

class KotService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getKots({String? type, String? status}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final branchId = prefs.getInt('selectedBranchId');
      
      final params = <String>[];
      if (type != null) params.add('kot_type=$type');
      if (status != null) params.add('status=$status');
      if (branchId != null) params.add('branch_id=$branchId');
      
      String query = params.isNotEmpty ? '?${params.join('&')}' : '';
      
      final response = await _apiService.get('/kots$query');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getKot(int id) async {
    try {
      final response = await _apiService.get('/kots/$id');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createKot(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/kots', data);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        throw responseData['detail'] ?? 'Failed to create KOT';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create KOT: $e';
    }
  }

  Future<bool> updateKot(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/kots/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateKotStatus(int id, String status) async {
    try {
      final response = await _apiService.put('/kots/$id/status', {'status': status});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> printKot(int id) async {
    try {
      final response = await _apiService.post('/kots/$id/print', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
