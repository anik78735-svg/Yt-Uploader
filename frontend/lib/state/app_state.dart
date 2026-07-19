import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yt_uploader_frontend/config/api_config.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _authToken;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  int _diamondBalance = 0;
  bool _isAdmin = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  int get diamondBalance => _diamondBalance;
  bool get isAdmin => _isAdmin;

  Future<Map<String, String>> _authHeaders() async {
    final token = _authToken ?? await _secureStorage.read(key: 'authToken');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> bootstrap() async {
    final token = await _secureStorage.read(key: 'authToken');
    if (token != null) {
      _authToken = token;
    }

    final userJson = _prefs.getString('user');
    if (userJson != null) {
      _user = jsonDecode(userJson);
      _isAuthenticated = true;
      _diamondBalance = (_user!['diamondBalance'] ?? 0) as int;
      _isAdmin = (_user!['role'] ?? 'USER') == 'ADMIN';
      notifyListeners();
    }
  }

  Future<bool> googleLogin({required String idToken}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/google-login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200) {
      return false;
    }

    final payload = jsonDecode(response.body);
    if (payload['success'] != true) {
      return false;
    }

    _user = payload['user'] as Map<String, dynamic>?;
    _authToken = payload['token'] as String?;
    if (_user == null || _authToken == null) {
      return false;
    }

    _isAuthenticated = true;
    _diamondBalance = (_user!['diamondBalance'] ?? 0) as int;
    _isAdmin = (_user!['role'] ?? 'USER') == 'ADMIN';
    await _secureStorage.write(key: 'authToken', value: _authToken!);
    await _prefs.setString('user', jsonEncode(_user));
    notifyListeners();
    return true;
  }

  Future<bool> checkUsernameAvailability(String username) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/check-username?username=${Uri.encodeComponent(username)}');
    final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode != 200) {
      return false;
    }
    final payload = jsonDecode(response.body);
    return payload['success'] == true && payload['available'] == true;
  }

  Future<bool> setUsername(String username) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/set-username');
    final response = await http.patch(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode != 200) {
      return false;
    }

    final payload = jsonDecode(response.body);
    if (payload['success'] != true) {
      return false;
    }

    _user = payload['user'] as Map<String, dynamic>?;
    if (_user == null) {
      return false;
    }

    await _prefs.setString('user', jsonEncode(_user));
    notifyListeners();
    return true;
  }

  Future<String?> getYoutubeAuthUrl() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/youtube-auth-url');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode != 200) {
      return null;
    }

    final payload = jsonDecode(response.body);
    return payload['url'] as String?;
  }

  Future<bool> connectYoutubeChannel({required String code}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/youtube-connect');
    final response = await http.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode != 200) {
      return false;
    }

    final payload = jsonDecode(response.body);
    if (payload['success'] != true) {
      return false;
    }

    _user = payload['user'] as Map<String, dynamic>?;
    if (_user == null) {
      return false;
    }

    await _prefs.setString('user', jsonEncode(_user));
    notifyListeners();
    return true;
  }

  Future<List<dynamic>> fetchSchedules() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/schedules');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode != 200) {
      return [];
    }

    final payload = jsonDecode(response.body);
    if (payload['success'] != true) {
      return [];
    }

    return payload['schedules'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> fetchUsers({String? search}) async {
    final query = search != null && search.trim().isNotEmpty
        ? '?search=${Uri.encodeComponent(search.trim())}'
        : '';
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/users$query');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode != 200) {
      return [];
    }

    final payload = jsonDecode(response.body);
    return payload['users'] as List<dynamic>? ?? [];
  }

  Future<bool> forceLogoutUser(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/users/logout');
    final response = await http.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({'userId': userId}),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, String>> getAuthHeadersForRequest() async {
    return await _authHeaders();
  }

  Future<void> logout() async {
    _authToken = null;
    _isAuthenticated = false;
    _user = null;
    _diamondBalance = 0;
    _isAdmin = false;
    await _secureStorage.delete(key: 'authToken');
    await _prefs.remove('user');
    notifyListeners();
  }
}
