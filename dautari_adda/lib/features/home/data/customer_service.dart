import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class CustomerService {
  final ApiService _apiService = ApiService();

  // Get all customers
  Future<List<dynamic>> getCustomers({
    int skip = 0,
    int limit = 100,
    String? search,
  }) async {
    try {
      String endpoint = '/customers?skip=$skip&limit=$limit';
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

  // Alias for getCustomers() to match communications_screen usage
  Future<List<dynamic>> getAllCustomers() async {
    return getCustomers();
  }

  // Get specific customer
  Future<Map<String, dynamic>?> getCustomer(int customerId) async {
    try {
      final response = await _apiService.get('/customers/$customerId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create new customer
  Future<Map<String, dynamic>> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post('/customers', {
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        throw data['detail'] ?? 'Failed to create customer';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to create customer: $e';
    }
  }

  // Update customer
  Future<bool> updateCustomer(int customerId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/customers/$customerId', data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(int customerId) async {
    try {
      final response = await _apiService.delete('/customers/$customerId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get customer orders
  Future<List<dynamic>> getCustomerOrders(int customerId) async {
    try {
      final response = await _apiService.get('/customers/$customerId/orders');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
