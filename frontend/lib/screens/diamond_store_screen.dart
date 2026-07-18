import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class DiamondStoreScreen extends StatefulWidget {
  const DiamondStoreScreen({super.key});

  @override
  State<DiamondStoreScreen> createState() => _DiamondStoreScreenState();
}

class _DiamondStoreScreenState extends State<DiamondStoreScreen> {
  final List<DiamondPackage> packages = [
    DiamondPackage(id: 'pkg_100', diamonds: 100, price: 99, badge: 'NONE'),
    DiamondPackage(id: 'pkg_500', diamonds: 500, price: 399, badge: 'POPULAR'),
    DiamondPackage(id: 'pkg_1000', diamonds: 1000, price: 699, badge: 'NONE'),
    DiamondPackage(id: 'pkg_5000', diamonds: 5000, price: 2999, badge: 'DISCOUNT'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diamond Store'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<AppState>(
                  builder: (context, state, _) {
                    return DiamondBalance(diamonds: state.diamondBalance);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('Choose Package', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.lg),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    return _DiamondPackageCard(
                      package: packages[index],
                      onBuy: () => _handleBuyDiamonds(packages[index]),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildAutoRefillCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBuyDiamonds(DiamondPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Purchase Diamonds', style: AppTextStyles.heading3),
        content: Text(
          'Buy ${package.diamonds} diamonds for ₹${package.price}?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initiatePayment(package);
            },
            child: const Text(
              'Proceed',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _initiatePayment(DiamondPackage package) {
    // Show payment page with QR code and UPI ID
    showDialog(
      context: context,
      builder: (context) => const PaymentDialog(),
    );
  }

  Widget _buildAutoRefillCard() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto-Refill', style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'When balance reaches 0',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: false,
            onChanged: (_) {},
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class DiamondPackage {
  final String id;
  final int diamonds;
  final int price;
  final String badge;

  DiamondPackage({
    required this.id,
    required this.diamonds,
    required this.price,
    required this.badge,
  });
}

class _DiamondPackageCard extends StatelessWidget {
  final DiamondPackage package;
  final VoidCallback onBuy;

  const _DiamondPackageCard({
    required this.package,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final isPrime = package.badge == 'POPULAR';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      border: isPrime
          ? Border.all(color: AppColors.primary, width: 2)
          : Border.all(color: AppColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond_rounded, color: AppColors.diamond, size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${package.diamonds} Diamonds',
                        style: AppTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '₹${package.price}',
                        style: AppTextStyles.heading3,
                      ),
                    ],
                  ),
                ],
              ),
              if (package.badge.isNotEmpty && package.badge != 'NONE')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: package.badge == 'POPULAR'
                        ? AppColors.warning.withOpacity(0.2)
                        : AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    package.badge,
                    style: TextStyle(
                      fontSize: 11,
                      color: package.badge == 'POPULAR' ? AppColors.warning : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: 'Buy Now',
              onPressed: onBuy,
              gradientStart: isPrime ? AppColors.warning : AppColors.primary,
              gradientEnd: isPrime ? AppColors.diamond : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentDialog extends StatelessWidget {
  const PaymentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Complete Payment', style: AppTextStyles.heading2),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Center(
                  child: Text('[QR Code Here]', style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Column(
                  children: [
                    const Text('Or scan with UPI App', style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.lg),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'uploader@okhdfcbank',
                                style: AppTextStyles.bodyLarge,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Text(
                                'Copy',
                                style: TextStyle(fontSize: 12, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'I Have Completed Payment',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
