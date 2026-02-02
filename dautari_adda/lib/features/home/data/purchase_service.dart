import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class PurchaseService {
  final ApiService _apiService = ApiService();

  // ============ SUPPLIERS ============

  Future<List<dynamic>> getSuppliers() async {
    try {
      final response = await _apiService.get('/purchase/suppliers');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createSupplier(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/purchase/suppliers', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSupplier(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/purchase/suppliers/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      final response = await _apiService.delete('/purchase/suppliers/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ PURCHASE BILLS ============

  Future<List<dynamic>> getPurchaseBills() async {
    try {
      final response = await _apiService.get('/purchase/bills');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> getPurchaseBill(int id) async {
    try {
      final response = await _apiService.get('/purchase/bills/$id');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createPurchaseBill(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/purchase/bills', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePurchaseBill(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/purchase/bills/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePurchaseBill(int id) async {
    try {
      final response = await _apiService.delete('/purchase/bills/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ PURCHASE RETURNS ============

  Future<List<dynamic>> getPurchaseReturns() async {
    try {
      final response = await _apiService.get('/purchase/returns');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createPurchaseReturn(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/purchase/returns', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePurchaseReturn(int id) async {
    try {
      final response = await _apiService.delete('/purchase/returns/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
