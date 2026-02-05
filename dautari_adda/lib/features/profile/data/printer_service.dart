import 'dart:convert';
import 'package:dautari_adda/core/api/api_service.dart';

class PrinterService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getPrinters() async {
    try {
      final response = await _apiService.get('/printers/');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching printers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createPrinter(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/printers/', data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating printer: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updatePrinter(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/printers/$id', data);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error updating printer: $e');
      return null;
    }
  }

  Future<bool> deletePrinter(int id) async {
    try {
      final response = await _apiService.delete('/printers/$id');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting printer: $e');
      return false;
    }
  }
}
