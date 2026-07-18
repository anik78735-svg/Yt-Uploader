import 'package:flutter/material.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xl),
              _buildPeriodSelector(),
              const SizedBox(height: AppSpacing.xl),
              _buildAnalyticsCards(),
              const SizedBox(height: AppSpacing.xl),
              _buildChart(),
              const SizedBox(height: AppSpacing.xl),
              _buildTopVideos(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['Today', 'Week', 'Month', 'Year'].map((period) {
        final isSelected = period == 'Month';
        return Expanded(
          child: Container(
            height: 40,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalyticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.lg,
      mainAxisSpacing: AppSpacing.lg,
      children: [
        _AnalyticsCard(label: 'Views', value: '12.5K', change: '+18.2%'),
        _AnalyticsCard(label: 'Watch Time', value: '234.5h', change: '+12.3%'),
        _AnalyticsCard(label: 'CTR', value: '8.4%', change: '+2.1%'),
        _AnalyticsCard(label: 'Subscribers', value: '+345', change: '+15.3%'),
      ],
    );
  }

  Widget _buildChart() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Views Over Time', style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final heights = [0.3, 0.5, 0.7, 0.4, 0.8, 0.6, 0.9];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: heights[index] * 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('May ${15 + index}', style: AppTextStyles.caption),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Performing Videos', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.lg),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return GlassCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text('${index + 1}', style: AppTextStyles.heading2),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Video Title ${index + 1}', style: AppTextStyles.bodyLarge),
                        const SizedBox(height: AppSpacing.sm),
                        Text('${(index + 1) * 1250} views', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      '+${(index + 1) * 5}%',
                      style: const TextStyle(fontSize: 11, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;

  const _AnalyticsCard({
    required this.label,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.heading2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(change, style: const TextStyle(fontSize: 11, color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}
