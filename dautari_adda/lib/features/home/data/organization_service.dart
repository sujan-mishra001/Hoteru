import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class OrganizationService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getOrganizations() async {
    try {
      final response = await _apiService.get('/organizations');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMyOrganization() async {
    try {
      final response = await _apiService.get('/organizations/my/organization');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createOrganization({
    required String name,
    required String slug,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _apiService.post('/organizations', {
        'name': name,
        'slug': slug,
        'address': address,
        'phone': phone,
        'email': email,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        throw data['detail'] ?? 'Failed to create organization';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create organization: $e';
    }
  }

  Future<bool> updateOrganization(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/organizations/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteOrganization(int id) async {
    try {
      final response = await _apiService.delete('/organizations/$id');
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getValidation(int id) async {
    try {
      final response = await _apiService.get('/organizations/$id/validation');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
