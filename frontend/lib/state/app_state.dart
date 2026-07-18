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
  List<dynamic> _pendingTransactions = [];
  List<dynamic> _users = [];

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  int get diamondBalance => _diamondBalance;
  bool get isAdmin => _isAdmin;
  List<dynamic> get pendingTransactions => _pendingTransactions;
  List<dynamic> get users => _users;

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

  Future<void> registerUser({required String googleId, required String email, String? username, String? refreshToken}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/google-login');
    final response = await http.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'idToken': googleId,
        'email': email,
        'username': username,
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body);
      _user = payload['user'];
      _authToken = payload['token'];
      _isAuthenticated = true;
      _diamondBalance = (_user!['diamondBalance'] ?? 0) as int;
      _isAdmin = (_user!['role'] ?? 'USER') == 'ADMIN';
      await _secureStorage.write(key: 'authToken', value: _authToken);
      await _prefs.setString('user', jsonEncode(_user));
      notifyListeners();
    }
  }

  Future<void> createPaymentLog({required String username, required int amount}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/create');
    final response = await http.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'userId': _user!['_id'],
        'username': username,
        'amount': amount,
      }),
    );
    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body);
      print('payment created: ${payload['transaction']['_id']}');
    }
  }

  Future<void> loadAdminData() async {
    if (!_isAdmin) return;
    final usersResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/users'), headers: await _authHeaders());
    if (usersResponse.statusCode == 200) {
      final usersPayload = jsonDecode(usersResponse.body);
      _users = usersPayload['users'];
    }

    final pendingResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/transactions/pending'), headers: await _authHeaders());
    if (pendingResponse.statusCode == 200) {
      final pendingPayload = jsonDecode(pendingResponse.body);
      _pendingTransactions = pendingPayload['transactions'];
    }
    notifyListeners();
  }

  Future<void> approveTransaction(String transactionId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/approve');
    final response = await http.post(uri, headers: await _authHeaders(), body: jsonEncode({'transactionId': transactionId}));
    if (response.statusCode == 200) {
      await loadAdminData();
    }
  }

  Future<void> rejectTransaction(String transactionId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/reject');
    final response = await http.post(uri, headers: await _authHeaders(), body: jsonEncode({'transactionId': transactionId}));
    if (response.statusCode == 200) {
      await loadAdminData();
    }
  }

  Future<void> forceLogout(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/users/logout');
    await http.post(uri, headers: await _authHeaders(), body: jsonEncode({'userId': userId}));
    await loadAdminData();
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
