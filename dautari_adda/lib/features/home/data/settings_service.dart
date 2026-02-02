import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class SettingsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiService.get('/settings');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/settings', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Currency Settings
  Future<Map<String, dynamic>> getCurrencySettings() async {
    try {
      final response = await _apiService.get('/settings/currency');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateCurrencySettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/settings/currency', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Tax Settings
  Future<List<dynamic>> getTaxSettings() async {
    try {
      final response = await _apiService.get('/settings/taxes');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateTaxSettings(List<dynamic> taxes) async {
    try {
      final response = await _apiService.put('/settings/taxes', taxes);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Printer Settings
  Future<Map<String, dynamic>> getPrinterSettings() async {
    try {
      final response = await _apiService.get('/settings/printer');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> updatePrinterSettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/settings/printer', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Notifications Settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _apiService.get('/settings/notifications');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateNotificationSettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/settings/notifications', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Receipt Settings
  Future<Map<String, dynamic>> getReceiptSettings() async {
    try {
      final response = await _apiService.get('/settings/receipt');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateReceiptSettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/settings/receipt', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
