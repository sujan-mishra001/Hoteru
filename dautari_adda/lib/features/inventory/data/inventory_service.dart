import 'dart:convert';
import 'package:dautari_adda/core/api/api_service.dart';

class InventoryService {
  final ApiService _apiService = ApiService();

  // ==========================================================================
  // PRODUCTS
  // ==========================================================================

  // Get all products with derived stock
  Future<List<dynamic>> getProducts() async {
    try {
      final response = await _apiService.get('/inventory/products');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create product
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/inventory/products', data);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        throw responseData['detail'] ?? 'Failed to create product';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create product: $e';
    }
  }

  // Update product
  Future<bool> updateProduct(int productId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/inventory/products/$productId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(int productId) async {
    try {
      final response = await _apiService.delete('/inventory/products/$productId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // UNITS
  // ==========================================================================

  // Get all units
  Future<List<dynamic>> getUnits() async {
    try {
      final response = await _apiService.get('/inventory/units');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create unit
  Future<bool> createUnit(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/inventory/units', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Update unit
  Future<bool> updateUnit(int unitId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/inventory/units/$unitId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete unit
  Future<bool> deleteUnit(int unitId) async {
    try {
      final response = await _apiService.delete('/inventory/units/$unitId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // TRANSACTIONS & ADJUSTMENTS
  // ==========================================================================

  // Create transaction (IN)
  Future<bool> createTransaction(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/inventory/transactions', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Get transactions
  Future<List<dynamic>> getTransactions() async {
    try {
      final response = await _apiService.get('/inventory/transactions');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create adjustment
  Future<bool> createAdjustment(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/inventory/adjustments', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Get adjustments
  Future<List<dynamic>> getAdjustments() async {
    try {
      final response = await _apiService.get('/inventory/adjustments');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================================================
  // COUNTS
  // ==========================================================================

  // Create physical count
  Future<bool> createCount(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/inventory/counts', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Get counts
  Future<List<dynamic>> getCounts() async {
    try {
      final response = await _apiService.get('/inventory/counts');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================================================
  // BILL OF MATERIALS (BOM)
  // ==========================================================================

  // Get all BOMs
  Future<List<dynamic>> getBoms() async {
    try {
      final response = await _apiService.get('/inventory/boms');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create BOM
  Future<bool> createBom(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/inventory/boms', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Update BOM
  Future<bool> updateBom(int bomId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/inventory/boms/$bomId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // PRODUCTIONS
  // ==========================================================================

  // Create production
  Future<bool> createProduction(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/inventory/productions', data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Get productions
  Future<List<dynamic>> getProductions() async {
    try {
      final response = await _apiService.get('/inventory/productions');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================================================
  // LEGACY METHODS (Kept for compatibility or refined)
  // ==========================================================================

  // Refined getInventory to use products endpoint
  Future<List<dynamic>> getInventory({String? search}) async {
    final products = await getProducts();
    if (search == null || search.isEmpty) return products;
    return products.where((p) => p['name'].toString().toLowerCase().contains(search.toLowerCase())).toList();
  }

  Future<List<dynamic>> getLowStockItems() async {
    final products = await getProducts();
    return products.where((p) => (p['current_stock'] ?? 0.0) <= (p['min_stock'] ?? 0.0)).toList();
  }

  Future<bool> updateStock(int productId, double quantity, String type) async {
    if (type == 'add') {
      return createTransaction({'product_id': productId, 'quantity': quantity, 'notes': 'Manual Stock Add'});
    } else {
      return createAdjustment({'product_id': productId, 'quantity': -quantity, 'notes': 'Manual Stock Remove'});
    }
  }

  Future<bool> updateInventoryItem(int itemId, Map<String, dynamic> data) async => updateProduct(itemId, data);
  Future<bool> deleteInventoryItem(int itemId) async => deleteProduct(itemId);

  Future<Map<String, dynamic>> createInventoryItem({
    required String name,
    required String unit,
    double? quantity,
    double? minQuantity,
    String? category,
  }) async {
    // Need unit_id, so let's try to find or create unit first (simplified for now)
    final units = await getUnits();
    var unitObj = units.firstWhere((u) => u['abbreviation'] == unit || u['name'] == unit, orElse: () => null);

    int? unitId;
    if (unitObj != null) {
      unitId = unitObj['id'];
    }

    return createProduct({
      'name': name,
      'unit_id': unitId,
      'min_stock': minQuantity,
      'category': category,
      'current_stock': quantity,
    });
  }
}
