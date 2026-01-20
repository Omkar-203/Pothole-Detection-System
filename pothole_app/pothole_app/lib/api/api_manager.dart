import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

class ApiManager {
  ApiManager._();
  static final instance = ApiManager._();

  final _baseUrl =
      'http://10.246.145.66:8000'; // Updated to match working curl command

  String get baseUrl => _baseUrl;

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> _getHeaders() {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.get(uri, headers: _getHeaders());
    return _handleResponse(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.post(uri,
        headers: _getHeaders(), body: body != null ? jsonEncode(body) : null);
    return _handleResponse(res);
  }

  Future<dynamic> postMultipart(String path, Map<String, String> fields,
      String fileField, List<int> fileBytes, String fileName) async {
    final uri = Uri.parse('$_baseUrl$path');
    print('API Call: POST $uri');
    print('Token present: ${_token != null}');
    var request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    fields.forEach((key, value) {
      request.fields[key] = value;
    });
    request.files.add(
        http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName));
    print('Sending multipart request with ${fileBytes.length} bytes');
    final res = await request.send();
    final response = await http.Response.fromStream(res);
    print('API Response status: ${response.statusCode}');
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.delete(uri, headers: _getHeaders());
    return _handleResponse(res);
  }

  // Auth APIs
  Future<Map<String, dynamic>> register(String email, String password,
      {String role = 'user'}) async {
    final body = {'email': email, 'password': password, 'role': role};
    return await post('/auth/register', body: body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = {'email': email, 'password': password};
    final result = await post('/auth/login', body: body);
    if (result['access_token'] != null) {
      setToken(result['access_token']);
    }
    return result;
  }

  // Pothole APIs
  Future<Map<String, dynamic>> uploadPothole(double latitude, double longitude,
      List<int> imageBytes, String fileName) async {
    final fields = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString()
    };
    return await postMultipart(
        '/potholes/', fields, 'file', imageBytes, fileName);
  }

  Future<List<dynamic>> getMyPotholes() async {
    return await get('/potholes/my');
  }

  Future<List<dynamic>> getAllPotholes() async {
    return await get('/potholes/all');
  }

  Future<Map<String, dynamic>> deletePothole(int requestId) async {
    return await delete('/potholes/$requestId');
  }

  // Profile APIs
  Future<Map<String, dynamic>> getProfile() async {
    return await get('/auth/profile');
  }

  // Dashboard APIs
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await get('/potholes/dashboard/stats');
  }

  Future<Map<String, dynamic>> getWeeklyAnalytics() async {
    return await get('/potholes/dashboard/weekly-analytics');
  }

  Future<Map<String, dynamic>> getNearbyPotholes() async {
    return await get('/potholes/dashboard/nearby');
  }

  // Reports APIs
  Future<List<dynamic>> getReports() async {
    return await get('/potholes/my');
  }

  dynamic _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw ApiException('Request failed',
        statusCode: res.statusCode, body: res.body);
  }
}
