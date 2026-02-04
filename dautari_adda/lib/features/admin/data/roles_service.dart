import 'dart:convert';
import 'package:dautari_adda/core/api/api_service.dart';

class RolesService {
  final ApiService _apiService = ApiService();

  // Get all roles
  Future<List<dynamic>> getRoles({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get('/roles?skip=$skip&limit=$limit');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get specific role
  Future<Map<String, dynamic>?> getRole(int roleId) async {
    try {
      final response = await _apiService.get('/roles/$roleId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get available permissions
  Future<List<String>> getAvailablePermissions() async {
    try {
      final response = await _apiService.get('/roles/permissions');
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create new role (Admin only)
  Future<Map<String, dynamic>> createRole({
    required String name,
    String? description,
    List<String>? permissions,
  }) async {
    try {
      final response = await _apiService.post('/roles', {
        'name': name,
        if (description != null) 'description': description,
        if (permissions != null) 'permissions': permissions,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        throw data['detail'] ?? 'Failed to create role';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create role: $e';
    }
  }

  // Update role (Admin only)
  Future<bool> updateRole(int roleId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/roles/$roleId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete role (Admin only)
  Future<bool> deleteRole(int roleId) async {
    try {
      final response = await _apiService.delete('/roles/$roleId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
