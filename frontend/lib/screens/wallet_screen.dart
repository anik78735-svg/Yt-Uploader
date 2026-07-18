import 'package:flutter/material.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _buildWalletSummary(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionHistory(),
                  _buildPurchaseHistory(),
                  _buildUsageHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSummary() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet Summary', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Balance', style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  const Row(
                    children: [
                      Icon(Icons.diamond_rounded, color: AppColors.diamond, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('1000', style: AppTextStyles.heading2),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Text('+ Buy More', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _WalletStatCard(label: 'Purchased', value: '5000'),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _WalletStatCard(label: 'Used', value: '4000'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surfaceLight,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Purchases'),
          Tab(text: 'Usage'),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return _TransactionItem(
            type: index % 2 == 0 ? 'Purchase' : 'Usage',
            amount: index % 2 == 0 ? '+500' : '-100',
            date: 'May ${20 - index}, 2025',
            description: index % 2 == 0
                ? 'Diamond Package Purchase'
                : 'Video Upload',
          );
        },
      ),
    );
  }

  Widget _buildPurchaseHistory() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return _TransactionItem(
            type: 'Purchase',
            amount: '+${(index + 1) * 100}',
            date: 'May ${20 - (index * 3)}, 2025',
            description: 'Starter Pack',
          );
        },
      ),
    );
  }

  Widget _buildUsageHistory() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) {
          return _TransactionItem(
            type: 'Usage',
            amount: '-10',
            date: 'May ${18 - index}, 2025',
            description: 'Video Upload',
          );
        },
      ),
    );
  }
}

class _WalletStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _WalletStatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.diamond_rounded, color: AppColors.diamond, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text(value, style: AppTextStyles.heading3),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String type;
  final String amount;
  final String date;
  final String description;

  const _TransactionItem({
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = amount.startsWith('+');
    final color = isIncome ? AppColors.success : AppColors.error;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(
              child: Icon(
                isIncome ? Icons.add_rounded : Icons.remove_rounded,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(date, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
