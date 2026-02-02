import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class InventoryService {
  final ApiService _apiService = ApiService();

  // Get all inventory items
  Future<List<dynamic>> getInventory({
    int skip = 0,
    int limit = 100,
    String? category,
    String? search,
  }) async {
    try {
      String endpoint = '/inventory?skip=$skip&limit=$limit';
      if (category != null) endpoint += '&category=$category';
      if (search != null) endpoint += '&search=$search';
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get specific inventory item
  Future<Map<String, dynamic>?> getInventoryItem(int itemId) async {
    try {
      final response = await _apiService.get('/inventory/$itemId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create inventory item
  Future<Map<String, dynamic>> createInventoryItem({
    required String name,
    required String unit,
    double? quantity,
    double? minQuantity,
    double? price,
    String? category,
    String? description,
  }) async {
    try {
      final response = await _apiService.post('/inventory', {
        'name': name,
        'unit': unit,
        if (quantity != null) 'quantity': quantity,
        if (minQuantity != null) 'min_quantity': minQuantity,
        if (price != null) 'price': price,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        throw data['detail'] ?? 'Failed to create inventory item';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create inventory item: $e';
    }
  }

  // Update inventory item
  Future<bool> updateInventoryItem(int itemId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/inventory/$itemId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete inventory item
  Future<bool> deleteInventoryItem(int itemId) async {
    try {
      final response = await _apiService.delete('/inventory/$itemId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Update stock quantity
  Future<bool> updateStock(int itemId, double quantity, String type) async {
    try {
      final response = await _apiService.post('/inventory/$itemId/stock', {
        'quantity': quantity,
        'type': type, // 'add' or 'remove'
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get low stock items
  Future<List<dynamic>> getLowStockItems() async {
    try {
      final response = await _apiService.get('/inventory/low-stock');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get inventory categories
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _apiService.get('/inventory/categories');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Purchase order methods
  Future<List<dynamic>> getPurchaseOrders() async {
    try {
      final response = await _apiService.get('/purchase');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createPurchaseOrder({
    required List<Map<String, dynamic>> items,
    String? supplierId,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post('/purchase', {
        'items': items,
        if (supplierId != null) 'supplier_id': supplierId,
        if (notes != null) 'notes': notes,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        throw data['detail'] ?? 'Failed to create purchase order';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create purchase order: $e';
    }
  }
}
