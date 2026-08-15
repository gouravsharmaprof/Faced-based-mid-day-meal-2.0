import 'package:shared_preferences/shared_preferences.dart';

/// AppConfig — stores backend URL, JWT tokens, and user role.
/// The hardcoded Gemini key has been removed — food analysis is handled server-side.
class AppConfig {
  static const String _keyBackendUrl   = 'backend_url';
  static const String _keyAccessToken  = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserRole     = 'user_role';
  static const String _keyUsername     = 'username';

  static const String defaultBackendUrl = 'http://10.93.124.239:8000';

  // ── Backend URL ──────────────────────────────────────────────────────────
  static Future<String> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendUrl) ?? defaultBackendUrl;
  }

  static Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyBackendUrl, url.trimRight().replaceAll(RegExp(r'/$'), ''));
  }

  static Future<String> apiUrl(String endpoint) async {
    final base = await getBackendUrl();
    return '$base$endpoint';
  }

  // ── JWT Token management ─────────────────────────────────────────────────
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUsername, username);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUsername);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? '';
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? '';
  }

  static const String _keyGeminiKey = 'gemini_key';

  // ── Legacy: kept for backward compat with settings_screen ────────────────
  static Future<String> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiKey) ?? '';
  }

  static Future<void> setGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiKey, key);
  }
}
