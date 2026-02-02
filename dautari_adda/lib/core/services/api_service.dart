import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.80:8000/api/v1';

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    print('API_DEBUG: GET $baseUrl$endpoint');
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    print('API_DEBUG: GET $endpoint -> ${response.statusCode}');
    return response;
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    print('API_DEBUG: POST $baseUrl$endpoint');
    print('API_DEBUG: Body: $body');
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    print('API_DEBUG: POST $endpoint -> ${response.statusCode}');
    return response;
  }
  
  // For OAuth2 Form data (login)
  Future<http.Response> postForm(String endpoint, Map<String, String> body) async {
    print('API_DEBUG: POST FORM $baseUrl$endpoint');
    print('API_DEBUG: Form data keys: ${body.keys.toList()}');
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    print('API_DEBUG: POST FORM $endpoint -> ${response.statusCode}');
    print('API_DEBUG: Response: ${response.body}');
    return response;
  }

  Future<http.Response> put(String endpoint, dynamic body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> patch(String endpoint, dynamic body) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return response;
  }
}
