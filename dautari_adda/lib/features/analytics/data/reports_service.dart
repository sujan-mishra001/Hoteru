import 'package:dautari_adda/core/api/api_service.dart';
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

  // Get sales summary
  Future<Map<String, dynamic>?> getSalesSummary() async {
    try {
      final response = await _apiService.get('/reports/sales-summary');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get Day Book
  Future<Map<String, dynamic>?> getDayBook({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/reports/day-book';
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

  // Get Daily Sales Report
  Future<Map<String, dynamic>?> getDailySales({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final endpoint = '/reports/daily-sales?start_date=$startDate&end_date=$endDate';
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get Purchase Report
  Future<Map<String, dynamic>?> getPurchaseReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/reports/purchase-report';
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
      return null;
    }
  }

  // Export Master Excel Report
  Future<Uint8List?> exportMasterExcel() async {
    try {
      return exportReport(reportType: 'sales', format: 'excel');
    } catch (e) {
      return null;
    }
  }

  // Other report methods (kept for reference or refined)
  Future<Map<String, dynamic>?> getSalesReport({
    String? startDate,
    String? endDate,
  }) async {
    return getDashboardSummary(startDate: startDate, endDate: endDate);
  }
}
