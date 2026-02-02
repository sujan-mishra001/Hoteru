import 'dart:convert';
import 'package:dautari_adda/core/services/api_service.dart';

class SessionService {
  final ApiService _apiService = ApiService();

  // Get all sessions
  Future<List<dynamic>> getSessions({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get('/sessions?skip=$skip&limit=$limit');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get current user's active session
  Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final sessions = await getSessions(limit: 1);
      if (sessions.isNotEmpty) {
        final activeSession = sessions.firstWhere(
          (session) => session['status'] == 'Open',
          orElse: () => null,
        );
        return activeSession;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Open a new POS session
  Future<Map<String, dynamic>?> openSession({
    required double openingCash,
    String? notes,
    int? branchId,
  }) async {
    try {
      final response = await _apiService.post('/sessions', {
        'opening_cash': openingCash,
        'notes': notes,
        'branch_id': branchId,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw error['detail'] ?? 'Failed to open session';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to open session: $e';
    }
  }

  // Close current session
  Future<bool> closeSession({
    required int sessionId,
    double? closingCash,
    double? totalSales,
    String? notes,
  }) async {
    try {
      final response = await _apiService.patch('/sessions/$sessionId', {
        if (closingCash != null) 'closing_cash': closingCash,
        if (totalSales != null) 'total_sales': totalSales,
        if (notes != null) 'notes': notes,
        'status': 'Closed',
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get session details
  Future<Map<String, dynamic>?> getSessionDetails(int sessionId) async {
    try {
      final response = await _apiService.get('/sessions/$sessionId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user has active session
  Future<bool> hasActiveSession() async {
    final session = await getActiveSession();
    return session != null;
  }

  // Get today's session summary
  Future<Map<String, dynamic>?> getTodaySummary() async {
    try {
      final response = await _apiService.get('/reports/dashboard-summary');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
