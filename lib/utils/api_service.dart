import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'app_config.dart';

class ApiService {
  // ── JSON parser ───────────────────────────────────────────────────────────
  static Map<String, dynamic> _parseJson(http.Response response) {
    final body = response.body.trim();
    if (body.startsWith('<')) {
      throw Exception(
        'Backend URL is wrong or unreachable.\n'
        'Go to App Settings and set the correct server address.',
      );
    }
    return json.decode(body) as Map<String, dynamic>;
  }

  static Future<Map<String, String>> _authHeaders() async {
    return {};
  }

  /// Attach auth headers to a MultipartRequest.
  static Future<void> _addAuth(http.MultipartRequest request) async {
    // No auth required
  }

  // ── Auth: Login ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse(await AppConfig.apiUrl('/api/auth/login'));
    final response = await http
        .post(
          uri,
          body: {'username': username, 'password': password},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = _parseJson(response);
      await AppConfig.saveTokens(
        accessToken:  data['access_token'],
        refreshToken: data['refresh_token'],
        role:         data['role'],
        username:     username,
      );
      return data;
    }
    throw Exception(_parseJson(response)['detail'] ?? 'Login failed');
  }

  static Future<void> logout() async {
    await AppConfig.clearTokens();
  }

  // ── Register ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String className,
    required String roll,
    String? aadhar,
    List<String> allergies = const [],
    required String consentRefId,
    required File faceImage,
  }) async {
    final uri = Uri.parse(await AppConfig.apiUrl('/api/register'));
    final request = http.MultipartRequest('POST', uri);
    await _addAuth(request);
    request.fields['name']           = name;
    request.fields['class_name']     = className;
    request.fields['roll']           = roll;
    request.fields['allergies']      = jsonEncode(allergies);
    request.fields['consent_ref_id'] = consentRefId;
    if (aadhar != null && aadhar.isNotEmpty) {
      request.fields['aadhar'] = aadhar;
    }
    request.files.add(await http.MultipartFile.fromPath(
      'face_image', faceImage.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 30)));
    if (response.statusCode == 200) return _parseJson(response);
    throw Exception(_parseJson(response)['detail'] ?? 'Registration failed');
  }

  // ── Recognize ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> recognizeUser({
    required String userId,
    required File faceImage,
  }) async {
    final uri = Uri.parse(await AppConfig.apiUrl('/api/recognize'));
    final request = http.MultipartRequest('POST', uri);
    await _addAuth(request);
    request.fields['user_id'] = userId;
    request.files.add(await http.MultipartFile.fromPath(
      'face_image', faceImage.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 30)));
    if (response.statusCode == 200) return _parseJson(response);
    throw Exception(_parseJson(response)['detail'] ?? 'Recognition failed');
  }

  // ── Analyze Food ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> analyzeFood({
    required String userId,
    required File foodImage,
  }) async {
    final uri = Uri.parse(await AppConfig.apiUrl('/api/analyze-food'));
    final request = http.MultipartRequest('POST', uri);
    await _addAuth(request);
    request.fields['user_id'] = userId;
    // Pass the Gemini key from app settings so it can be changed without rebuilding docker
    final geminiKey = await AppConfig.getGeminiKey();
    if (geminiKey.isNotEmpty) {
      request.fields['gemini_key'] = geminiKey;
    }
    request.files.add(await http.MultipartFile.fromPath(
      'food_image', foodImage.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 60)));
    if (response.statusCode == 200) return _parseJson(response);
    // 409 = already served today
    if (response.statusCode == 409) {
      throw Exception(_parseJson(response)['detail'] ?? 'Already served today');
    }
    throw Exception(_parseJson(response)['detail'] ?? 'Food analysis failed');
  }

  // ── Get User ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUser(String userId) async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse(await AppConfig.apiUrl('/api/user/$userId')),
             headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) return _parseJson(response);
    throw Exception(_parseJson(response)['detail'] ?? 'User not found');
  }

  // ── Logs ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getLogs() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse(await AppConfig.apiUrl('/api/logs')),
             headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) return _parseJson(response);
    throw Exception('Failed to fetch logs');
  }

  // ── Monthly Report ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMonthlyReport({String month = ''}) async {
    final headers = await _authHeaders();
    final base = await AppConfig.apiUrl('/api/monthly-report');
    final url  = month.isEmpty ? base : '$base?month=$month';
    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) return _parseJson(response);
    throw Exception('Failed to fetch monthly report');
  }

  // ── Health ────────────────────────────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(await AppConfig.apiUrl('/healthz')))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String> getLogsExcelUrl() async =>
      AppConfig.apiUrl('/api/logs/excel');
}
