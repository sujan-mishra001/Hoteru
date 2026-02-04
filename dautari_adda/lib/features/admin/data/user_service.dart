import 'dart:convert';
import 'package:dautari_adda/core/api/api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  // Get all users (Admin only)
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await _apiService.get('/users');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get specific user
  Future<Map<String, dynamic>?> getUser(int userId) async {
    try {
      final response = await _apiService.get('/users/$userId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create new user (Admin only)
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    int? branchId,
    String? username,
  }) async {
    try {
      final response = await _apiService.post('/users', {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        if (branchId != null) 'branch_id': branchId,
        if (username != null) 'username': username,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        throw data['detail'] ?? 'Failed to create user';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create user: $e';
    }
  }

  // Update user
  Future<bool> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/users/$userId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await _apiService.delete('/users/$userId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Disable user
  Future<bool> disableUser(int userId, bool disabled) async {
    try {
      final response = await _apiService.patch('/users/$userId', {
        'disabled': disabled,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get user permissions/role details
  Future<Map<String, dynamic>?> getUserPermissions(int userId) async {
    try {
      final response = await _apiService.get('/users/$userId/permissions');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
