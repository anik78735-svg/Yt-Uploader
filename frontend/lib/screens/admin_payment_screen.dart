import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/config/api_config.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  bool _loading = true;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final state = context.read<AppState>();
    if (!state.isAdmin) return;
    final headers = await state.getAuthHeadersForRequest();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payment-requests/admin/pending'),
        headers: headers,
      );
      if (!mounted) return;
      final payload = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _payments = payload['payments'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String paymentId) async {
    final state = context.read<AppState>();
    final headers = await state.getAuthHeadersForRequest();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/payment-requests/admin/approve'),
      headers: headers,
      body: jsonEncode({'paymentId': paymentId, 'notes': 'Approved from app'}),
    );
    if (response.statusCode == 200) {
      _loadPayments();
    }
  }

  Future<void> _reject(String paymentId) async {
    final state = context.read<AppState>();
    final headers = await state.getAuthHeadersForRequest();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/payment-requests/admin/reject'),
      headers: headers,
      body: jsonEncode(
          {'paymentId': paymentId, 'rejectionReason': 'Rejected from app'}),
    );
    if (response.statusCode == 200) {
      _loadPayments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Requests'),
        backgroundColor: AppColors.surfaceLight,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _payments.length,
                itemBuilder: (context, index) {
                  final payment = _payments[index];
                  final user = payment['userId'];
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment['paymentId'] ?? '',
                            style: AppTextStyles.bodyLarge),
                        const SizedBox(height: AppSpacing.sm),
                        Text(user?['username'] ?? 'User',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                            '${payment['diamonds'] ?? 0} diamonds • ₹${payment['amount'] ?? 0}',
                            style: AppTextStyles.body),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                                child: GradientButton(
                                    text: 'Approve',
                                    onPressed: () =>
                                        _approve(payment['paymentId']),
                                    gradientStart: AppColors.success,
                                    gradientEnd: AppColors.success)),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                                child: GradientButton(
                                    text: 'Reject',
                                    onPressed: () =>
                                        _reject(payment['paymentId']),
                                    gradientStart: AppColors.error,
                                    gradientEnd: AppColors.error)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
