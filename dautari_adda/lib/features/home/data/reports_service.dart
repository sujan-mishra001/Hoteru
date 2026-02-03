import 'package:dautari_adda/core/services/api_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class ReportsService {
  final ApiService _apiService = ApiService();

  // Get dashboard summary
  Future<Map<String, dynamic>?> getDashboardSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/reports/dashboard-summary';
      final params = <String>[];
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get sales report
  Future<Map<String, dynamic>?> getSalesReport({
    String? startDate,
    String? endDate,
    String? reportType,
  }) async {
    try {
      String endpoint = '/reports/sales';
      final params = <String>[];
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      if (reportType != null) params.add('report_type=$reportType');
      
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get inventory report
  Future<Map<String, dynamic>?> getInventoryReport() async {
    try {
      final response = await _apiService.get('/reports/inventory');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get staff performance report
  Future<Map<String, dynamic>?> getStaffPerformanceReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/reports/staff-performance';
      final params = <String>[];
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get daily sales summary
  Future<List<dynamic>> getDailySalesSummary({
    int days = 7,
  }) async {
    try {
      final response = await _apiService.get('/reports/daily-sales?days=$days');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get top selling items
  Future<List<dynamic>> getTopSellingItems({
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/reports/top-items?limit=$limit';
      if (startDate != null) endpoint += '&start_date=$startDate';
      if (endDate != null) endpoint += '&end_date=$endDate';
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Export any report as PDF or Excel
  Future<Uint8List?> exportReport({
    required String reportType,
    required String format, // 'pdf' or 'excel'
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = reportType == 'sessions' && format == 'pdf'
          ? '/reports/export/sessions/pdf'
          : '/reports/export/$format/$reportType';
          
      final params = <String>[];
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('DEBUG: Export error: $e');
      return null;
    }
  }

  // Export Master Excel
  Future<Uint8List?> exportMasterExcel() async {
    try {
      final response = await _apiService.get('/reports/export/all/excel');
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Export Sessions PDF
  Future<Uint8List?> exportSessionsPDF() async {
    try {
      final response = await _apiService.get('/reports/export/sessions/pdf');
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get payment summary
  Future<Map<String, dynamic>?> getPaymentSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/reports/payment-summary';
      final params = <String>[];
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get category-wise sales
  Future<List<dynamic>> getCategorySales({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/reports/category-sales';
      final params = <String>[];
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      
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

  // Get hourly sales analysis
  Future<List<dynamic>> getHourlySalesAnalysis({
    String? date,
  }) async {
    try {
      String endpoint = '/reports/hourly-sales';
      if (date != null) endpoint += '?date=$date';
      
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
