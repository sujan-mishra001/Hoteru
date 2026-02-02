import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

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

  // Sign Up (Ratala signup creates organization)
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _apiService.post('/auth/signup', {
        'email': email,
        'full_name': name,
        'password': password,
        'role': 'admin', // First user is admin/owner
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        throw data['detail'] ?? 'Signup failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Login
  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await _apiService.postForm('/auth/token', {
        'username': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _apiService.saveToken(data['access_token']);
        // You might want to save role, branch_id etc. to storage or a Provider state
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw data['detail'] ?? 'Login failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.clearToken();
  }

  // Simple getter for current user email (can be cached after /token)
  Future<String?> getCurrentUserEmail() async {
    // In a real app, you'd call /auth/users/me
    return null; 
  }
}
