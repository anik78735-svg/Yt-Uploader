import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs);

  final SharedPreferences _prefs;
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

  Future<void> bootstrap() async {
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
    final uri = Uri.parse('http://10.0.2.2:5000/api/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'googleId': googleId,
        'email': email,
        'username': username,
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body);
      _user = payload['user'];
      _isAuthenticated = true;
      _diamondBalance = (_user!['diamondBalance'] ?? 0) as int;
      _isAdmin = (_user!['role'] ?? 'USER') == 'ADMIN';
      await _prefs.setString('user', jsonEncode(_user));
      notifyListeners();
    }
  }

  Future<void> createPaymentLog({required String username, required int amount}) async {
    final uri = Uri.parse('http://10.0.2.2:5000/api/payments/create');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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
    final usersResponse = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/users'));
    if (usersResponse.statusCode == 200) {
      final usersPayload = jsonDecode(usersResponse.body);
      _users = usersPayload['users'];
    }

    final pendingResponse = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/transactions/pending'));
    if (pendingResponse.statusCode == 200) {
      final pendingPayload = jsonDecode(pendingResponse.body);
      _pendingTransactions = pendingPayload['transactions'];
    }
    notifyListeners();
  }

  Future<void> approveTransaction(String transactionId) async {
    final uri = Uri.parse('http://10.0.2.2:5000/api/payments/approve');
    final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'transactionId': transactionId}));
    if (response.statusCode == 200) {
      await loadAdminData();
    }
  }

  Future<void> rejectTransaction(String transactionId) async {
    final uri = Uri.parse('http://10.0.2.2:5000/api/payments/reject');
    final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'transactionId': transactionId}));
    if (response.statusCode == 200) {
      await loadAdminData();
    }
  }

  Future<void> forceLogout(String userId) async {
    final uri = Uri.parse('http://10.0.2.2:5000/api/admin/users/logout');
    await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'userId': userId}));
    await loadAdminData();
  }
}
