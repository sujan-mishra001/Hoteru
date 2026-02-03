import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  // Get all orders with optional filters
  Future<List<dynamic>> getOrders({
    String? orderType,
    String? status,
  }) async {
    try {
      String endpoint = '/orders';
      final params = <String>[];
      if (orderType != null) params.add('order_type=$orderType');
      if (status != null) params.add('status=$status');
      
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Alias for getOrders() to match cashier_screen and day_book_screen usage
  Future<List<dynamic>> getAllOrders() async {
    return getOrders();
  }

  // Get specific order
  Future<Map<String, dynamic>?> getOrder(int orderId) async {
    try {
      final response = await _apiService.get('/orders/$orderId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create new order
  Future<Map<String, dynamic>> createOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
    String? customerId,
    String orderType = 'Table',
    String? notes,
    int? customerIdInt,
  }) async {
    try {
      final response = await _apiService.post('/orders', {
        'table_id': tableId,
        'items': items,
        'order_type': orderType,
        'notes': notes,
        if (customerIdInt != null) 'customer_id': customerIdInt,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        throw data['detail'] ?? 'Failed to create order';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create order: $e';
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _apiService.patch('/orders/$orderId', {
        'status': status,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Update order details
  Future<bool> updateOrder(int orderId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/orders/$orderId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Add items to existing order
  Future<bool> addItemsToOrder(int orderId, List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiService.post('/orders/$orderId/items', {
        'items': items,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Remove item from order
  Future<bool> removeItemFromOrder(int orderId, int itemId) async {
    try {
      final response = await _apiService.delete('/orders/$orderId/items/$itemId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Generate KOT for order
  Future<Map<String, dynamic>?> generateKOT(int orderId) async {
    try {
      final response = await _apiService.post('/kots/generate/$orderId', {});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get KOTs for order
  Future<List<dynamic>> getKOTs(int orderId) async {
    try {
      final response = await _apiService.get('/kots/order/$orderId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get active orders
  Future<List<dynamic>> getActiveOrders() async {
    return getOrders(status: 'Pending');
  }

  // Get completed orders
  Future<List<dynamic>> getCompletedOrders() async {
    return getOrders(status: 'Completed');
  }

  // Get today's orders
  Future<List<dynamic>> getTodayOrders() async {
    try {
      final response = await _apiService.get('/orders');
      if (response.statusCode == 200) {
        final orders = jsonDecode(response.body);
        // Filter for today's orders on client side
        final now = DateTime.now();
        final todayOrders = orders.where((order) {
          final orderDate = DateTime.parse(order['created_at']);
          return orderDate.day == now.day &&
                 orderDate.month == now.month &&
                 orderDate.year == now.year;
        }).toList();
        return todayOrders;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
