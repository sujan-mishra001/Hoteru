import 'dart:convert';
import 'package:dautari_adda/core/api/api_service.dart';

class BranchService {
  final ApiService _apiService = ApiService();

  // Get all branches for current user
  Future<List<dynamic>> getBranches() async {
    try {
      final response = await _apiService.get('/branches/');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get user's assigned branches
  Future<List<dynamic>> getMyBranches() async {
    try {
      final response = await _apiService.get('/branches/my/branches');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get specific branch details
  Future<Map<String, dynamic>?> getBranch(int branchId) async {
    try {
      final response = await _apiService.get('/branches/$branchId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create new branch (Admin only)
  Future<Map<String, dynamic>> createBranch({
    required String name,
    required String code,
    String? address,
    String? phone,
    String? email,
    String? location,
  }) async {
    try {
      final response = await _apiService.post('/branches/', {
        'name': name,
        'code': code,
        'address': address,
        'phone': phone,
        'email': email,
        'location': location,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        throw data['detail'] ?? 'Failed to create branch';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create branch: $e';
    }
  }

  // Update branch
  Future<bool> updateBranch(int branchId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/branches/$branchId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete branch
  Future<bool> deleteBranch(int branchId) async {
    try {
      final response = await _apiService.delete('/branches/$branchId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Select/switch to a branch
  Future<bool> selectBranch(int branchId) async {
    try {
      final response = await _apiService.post('/auth/select-branch', {
        'branch_id': branchId,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get users assigned to a branch
  Future<List<dynamic>> getBranchUsers(int branchId) async {
    try {
      final response = await _apiService.get('/branches/$branchId/users');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Assign user to branch (Admin only)
  Future<bool> assignUserToBranch({
    required int userId,
    required int branchId,
    bool isPrimary = false,
  }) async {
    try {
      final response = await _apiService.post('/branches/$branchId/assign-user', {
        'user_id': userId,
        'is_primary': isPrimary,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Remove user from branch
  Future<bool> removeUserFromBranch({
    required int userId,
    required int branchId,
  }) async {
    try {
      final response = await _apiService.delete('/branches/$branchId/users/$userId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
