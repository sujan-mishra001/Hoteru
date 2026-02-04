import 'dart:convert';
import 'package:dautari_adda/core/api/api_service.dart';

class QrService {
  final ApiService _apiService = ApiService();

  /// Fetch all active QR codes for payment
  Future<List<dynamic>> getActiveQRCodes() async {
    try {
      final response = await _apiService.get('/qr-codes/?is_active=true');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as List;
      }
      return [];
    } catch (e) {
      print('QR_SERVICE_ERROR: Failed to fetch QR codes: $e');
      return [];
    }
  }

  /// Fetch all QR codes (including inactive)
  Future<List<dynamic>> getAllQRCodes() async {
    try {
      final response = await _apiService.get('/qr-codes/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as List;
      }
      return [];
    } catch (e) {
      print('QR_SERVICE_ERROR: Failed to fetch all QR codes: $e');
      return [];
    }
  }
}
