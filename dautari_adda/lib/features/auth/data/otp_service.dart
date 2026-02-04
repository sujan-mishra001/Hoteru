import 'dart:convert';
import 'package:dautari_adda/core/api/api_service.dart';

/// OTP Service for email verification and password reset
/// 
/// This service uses the Ratala POS backend OTP endpoints
/// integrated with FastAPI (Python) instead of the old Node.js server
class OtpService {
  final ApiService _apiService = ApiService();

  /// Send OTP to email
  /// 
  /// [email] - Email address to send OTP to
  /// [type] - Type of OTP: 'signup' or 'reset'
  /// 
  /// Returns a map with 'success' and 'message' keys
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    String type = 'signup',
  }) async {
    try {
      final response = await _apiService.post('/otp/send-otp', {
        'email': email,
        'type': type,
      });

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['detail'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('OTP_DEBUG: Send OTP error: $e');
      return {
        'success': false,
        'message': 'Network error: Could not send OTP. Please check your connection.',
      };
    }
  }

  /// Verify OTP code
  /// 
  /// [email] - Email address
  /// [code] - 6-digit OTP code
  /// 
  /// Returns a map with 'success' and 'message' keys
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    bool consume = true,
  }) async {
    try {
      final response = await _apiService.post('/otp/verify-otp', {
        'email': email,
        'code': code,
        'consume': consume,
      });

      final data = jsonDecode(response.body);
      
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Verification failed',
      };
    } catch (e) {
      print('OTP_DEBUG: Verify OTP error: $e');
      return {
        'success': false,
        'message': 'Network error: Could not verify OTP.',
      };
    }
  }

  /// Complete password reset with OTP verification
  /// 
  /// [email] - Email address
  /// [code] - 6-digit OTP code
  /// [newPassword] - New password to set
  /// 
  /// Returns a map with 'success' and 'message' keys
  Future<Map<String, dynamic>> completePasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post('/otp/complete-password-reset', {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });

      final data = jsonDecode(response.body);
      
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Password reset failed',
      };
    } catch (e) {
      print('OTP_DEBUG: Password reset error: $e');
      return {
        'success': false,
        'message': 'Network error: Could not reset password.',
      };
    }
  }

  /// Check OTP service health
  /// 
  /// Returns true if the OTP service is reachable and healthy
  Future<bool> checkHealth() async {
    try {
      final response = await _apiService.get('/otp/health');
      return response.statusCode == 200;
    } catch (e) {
      print('OTP_DEBUG: Health check error: $e');
      return false;
    }
  }
}
