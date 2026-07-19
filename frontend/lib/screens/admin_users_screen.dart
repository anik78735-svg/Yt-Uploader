import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/config/api_config.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = context.read<AppState>();
    final headers = await state.getAuthHeadersForRequest();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/users${search != null && search.trim().isNotEmpty ? '?search=${Uri.encodeComponent(search.trim())}' : ''}');
      final response = await http.get(uri, headers: headers);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        setState(() {
          _users = payload['users'] as List<dynamic>? ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to load users';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }

  Future<void> _forceLogout(String userId) async {
    final state = context.read<AppState>();
    final headers = await state.getAuthHeadersForRequest();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/logout'),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        await _loadUsers(search: _searchController.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to force logout')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadUsers(search: _searchController.text),
                decoration: InputDecoration(
                  hintText: 'Search users',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => _loadUsers(search: _searchController.text),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _users.isEmpty
                          ? const Center(child: Text('No users match your search'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index] as Map<String, dynamic>;
                                final active = user['isSessionActive'] == true;
                                return GlassCard(
                                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(user['username'] ?? user['email'] ?? 'User', style: AppTextStyles.bodyLarge),
                                            const SizedBox(height: AppSpacing.sm),
                                            Text(user['email'] ?? '', style: AppTextStyles.bodySmall),
                                            const SizedBox(height: AppSpacing.sm),
                                            Wrap(
                                              spacing: AppSpacing.sm,
                                              children: [
                                                _UserChip(label: 'Diamonds: ${user['diamondBalance'] ?? 0}'),
                                                _UserChip(label: user['role'] ?? 'USER'),
                                                _UserChip(label: active ? 'Active' : 'Inactive', color: active ? AppColors.success : AppColors.textMuted),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      ElevatedButton(
                                        onPressed: active ? () => _forceLogout(user['_id']?.toString() ?? '') : null,
                                        child: const Text('Force Logout'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(label, style: TextStyle(color: color ?? AppColors.primary, fontSize: 11)),
    );
  }
}
