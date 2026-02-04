import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.72:8000/api/v1';
  
  // Use this for static files (removes the /api/v1 prefix)
  static String get baseHostUrl => baseUrl.split('/api/v1')[0];

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
    if (token == null) {
      print('API_DEBUG: WARNING - No token found in storage!');
    } else {
      print('API_DEBUG: Token present (length: ${token.length})');
    }
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

  Future<http.Response> postMultipart(
    String endpoint,
    Map<String, String> fields,
    Map<String, dynamic> files,
  ) async {
    print('API_DEBUG: POST MULTIPART $baseUrl$endpoint');
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add fields
    request.fields.addAll(fields);
    
    // Add files
    for (var entry in files.entries) {
      final file = entry.value;
      request.files.add(await http.MultipartFile.fromPath(entry.key, file.path));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('API_DEBUG: POST MULTIPART $endpoint -> ${response.statusCode}');
    return response;
  }

  Future<http.Response> putMultipart(
    String endpoint,
    Map<String, String> fields,
    Map<String, dynamic> files,
  ) async {
    print('API_DEBUG: PUT MULTIPART $baseUrl$endpoint');
    final token = await getToken();
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl$endpoint'));
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add fields
    request.fields.addAll(fields);
    
    // Add files
    for (var entry in files.entries) {
      final file = entry.value;
      request.files.add(await http.MultipartFile.fromPath(entry.key, file.path));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('API_DEBUG: PUT MULTIPART $endpoint -> ${response.statusCode}');
    return response;
  }
}
