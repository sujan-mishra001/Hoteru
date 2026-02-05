import 'dart:convert';
import 'package:dautari_adda/core/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Get current user (using token presence for now)
  Future<bool> get isLoggedIn async {
    final token = await _apiService.getToken();
    return token != null;
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _apiService.get('/auth/users/me');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Upload profile picture
  Future<bool> uploadProfilePicture(dynamic file) async {
    try {
      final response = await _apiService.uploadFile(
        '/auth/users/me/profile-picture',
        file,
        fieldName: 'file',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return false;
    }
  }

  // Sign Up (Ratala signup creates organization)
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('AUTH_DEBUG: Attempting signup for: $email');
      
      final response = await _apiService.post('/auth/signup', {
        'email': email,
        'full_name': name,
        'password': password,
        'role': 'admin', // First user is admin/owner
      });

      print('AUTH_DEBUG: Signup response status: ${response.statusCode}');
      print('AUTH_DEBUG: Signup response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Account created successfully! Please login.'};
      } else {
        throw data['detail'] ?? data['message'] ?? 'Signup failed';
      }
    } catch (e) {
      print('AUTH_DEBUG: Signup error: $e');
      if (e is String) throw e;
      throw 'Network error: Please check if your computer is reachable at the IP in .env and that the backend is running.';
    }
  }

  // Login
  Future<bool> login({required String email, required String password}) async {
    try {
      print('AUTH_DEBUG: Attempting login for: $email');
      final response = await _apiService.postForm('/auth/token', {
        'username': email,
        'password': password,
      });

      print('AUTH_DEBUG: Login response status: ${response.statusCode}');
      print('AUTH_DEBUG: Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _apiService.saveToken(data['access_token']);
        print('AUTH_DEBUG: Login successful, token saved');
        return true;
      } else {
        final data = jsonDecode(response.body);
        final error = data['detail'] ?? data['message'] ?? 'Login failed';
        print('AUTH_DEBUG: Login failed - $error');
        throw error;
      }
    } catch (e) {
      print('AUTH_DEBUG: Login error: $e');
      if (e is String) throw e;
      throw 'Login failed: Could not reach the server. Please check your network connection and ensure backend is running on ${ApiService.baseUrl}';
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.clearToken();
  }

  // Get user branches
  Future<List<dynamic>> getUserBranches() async {
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

  // Switch branch
  Future<bool> switchBranch(int branchId) async {
    try {
      print('AUTH_DEBUG: Switching to branch: $branchId');
      final response = await _apiService.post('/auth/select-branch', {
        'branch_id': branchId,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save the new token received from branch selection
        if (data['access_token'] != null) {
          await _apiService.saveToken(data['access_token']);
        }
        
        // Save selected branch ID for other services to use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('selectedBranchId', branchId);
        
        print('AUTH_DEBUG: Branch switch successful, token and branchId saved');
        return true;
      } else {
        final data = jsonDecode(response.body);
        print('AUTH_DEBUG: Branch switch failed: ${data['detail']}');
        return false;
      }
    } catch (e) {
      print('AUTH_DEBUG: Branch switch error: $e');
      return false;
    }
  }

  // Get current session info
  Future<Map<String, dynamic>?> getCurrentSession() async {
    try {
      final response = await _apiService.get('/auth/users/me');
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return {
          'user': userData,
          'current_branch_id': userData['current_branch_id'],
          'role': userData['role'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
