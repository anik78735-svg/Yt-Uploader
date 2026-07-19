import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:yt_uploader_frontend/config/api_config.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class PaymentPageScreen extends StatefulWidget {
  final String paymentId;
  final String token;
  const PaymentPageScreen(
      {super.key, required this.paymentId, required this.token});

  @override
  State<PaymentPageScreen> createState() => _PaymentPageScreenState();
}

class _PaymentPageScreenState extends State<PaymentPageScreen> {
  bool _loading = true;
  Map<String, dynamic>? _paymentData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/payment-requests/request/${widget.paymentId}?token=${widget.token}'),
      );
      if (!mounted) return;
      final payload = jsonDecode(response.body);
      if (response.statusCode == 200 && payload['success'] == true) {
        setState(() {
          _paymentData = payload;
          _loading = false;
        });
      } else {
        setState(() {
          _error = payload['error'] ?? 'Unable to load payment details';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _completePayment() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/payment-requests/request/${widget.paymentId}/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token}),
      );
      if (!mounted) return;
      final payload = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(payload['message'] ??
                  'Payment request submitted for review')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _error = payload['error'] ?? 'Unable to submit payment completion';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = _paymentData?['paymentRequest'];
    final settings = _paymentData?['paymentSettings'];
    final userInfo = _paymentData?['userInfo'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: AppColors.surfaceLight,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(settings?['merchantName'] ?? 'YT Uploader',
                                  style: AppTextStyles.heading2),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                  'Secure payment link for ${payment?['diamonds'] ?? 0} diamonds',
                                  style: AppTextStyles.bodySmall),
                              const SizedBox(height: AppSpacing.lg),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDark,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Center(
                                  child: settings?['qrImageUrl'] != null
                                      ? Image.network(
                                          settings!['qrImageUrl'],
                                          height: 220,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              const Icon(Icons.qr_code_rounded,
                                                  size: 160),
                                        )
                                      : const Icon(Icons.qr_code_rounded,
                                          size: 160),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Payment Details',
                                  style: AppTextStyles.heading3),
                              const SizedBox(height: AppSpacing.lg),
                              _infoRow('UPI ID', settings?['upiId'] ?? ''),
                              _infoRow('Package',
                                  '${payment?['diamonds'] ?? 0} Diamonds'),
                              _infoRow('Price', '₹${payment?['amount'] ?? 0}'),
                              _infoRow('User', userInfo?['username'] ?? ''),
                              _infoRow(
                                  'Payment ID', payment?['paymentId'] ?? ''),
                              _infoRow('Instructions',
                                  settings?['paymentInstructions'] ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                                child: GradientButton(
                                    text: 'Copy UPI',
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: settings?['upiId'] ?? ''),
                                      );
                                      if (!mounted) return;
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('UPI ID copied to clipboard')),
                                      );
                                    })),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                                child: GradientButton(
                                    text: 'Share Link',
                                    onPressed: () {
                                      final message = 'Payment request for ${payment?['diamonds'] ?? 0} diamonds. UPI ID: ${settings?['upiId'] ?? ''}. Amount: ₹${payment?['amount'] ?? 0}. Payment ID: ${payment?['paymentId'] ?? ''}';
                                      Share.share(message);
                                    })),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            text: 'I Have Completed Payment',
                            onPressed: _completePayment,
                            gradientStart: AppColors.success,
                            gradientEnd: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90, child: Text(label, style: AppTextStyles.bodySmall)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(value, style: AppTextStyles.bodyLarge)),
        ],
      ),
    );
  }
}
