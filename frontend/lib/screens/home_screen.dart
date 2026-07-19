import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';
import 'package:yt_uploader_frontend/screens/diamond_store_screen.dart';
import 'package:yt_uploader_frontend/screens/wallet_screen.dart';
import 'package:yt_uploader_frontend/screens/upload_screen.dart';
import 'package:yt_uploader_frontend/screens/upcoming_videos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Load user data and dashboard info
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.xxl),
              _buildDiamondCard(),
              const SizedBox(height: AppSpacing.xl),
              _buildStatsGrid(),
              const SizedBox(height: AppSpacing.xl),
              _buildUpcomingVideos(),
              const SizedBox(height: AppSpacing.xl),
              _buildQuickActions(),
              const SizedBox(height: AppSpacing.xl),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Back!', style: AppTextStyles.heading2),
        const SizedBox(height: AppSpacing.sm),
        Consumer<AppState>(
          builder: (context, state, _) {
            return Text(
              state.user?['youtubeChannelName'] ?? 'Channel',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiamondCard() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return DiamondBalance(
          diamonds: state.diamondBalance,
          onBuyMore: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DiamondStoreScreen()));
          },
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.lg,
      mainAxisSpacing: AppSpacing.lg,
      children: [
        _StatCard(
          icon: Icons.cloud_upload_rounded,
          label: "Today's Uploads",
          value: '0',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.schedule_rounded,
          label: 'Scheduled',
          value: '3',
          color: AppColors.secondary,
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          label: 'Completed',
          value: '12',
          color: AppColors.success,
        ),
        _StatCard(
          icon: Icons.trending_up_rounded,
          label: 'Views (30d)',
          value: '2.5K',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildUpcomingVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Videos', style: AppTextStyles.heading3),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpcomingVideosScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '10 AI Tools That Will Blow Your Mind',
                style: AppTextStyles.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Text(
                      'Scheduled',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text(
                    'Tomorrow at 10:00 PM',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Upload Video',
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UploadScreen()));
                },
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: GradientButton(
                text: 'Schedule',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Buy Diamonds',
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DiamondStoreScreen()));
                },
                gradientStart: AppColors.diamond,
                gradientEnd: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.glassBorder),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WalletScreen()));
                    },
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: const Center(
                      child: Text('Wallet', style: AppTextStyles.button),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.lg),
          _ActivityItem(
              title: 'Diamond purchase approved',
              subtitle: 'Your latest refill has been credited',
              icon: Icons.workspace_premium_rounded),
          const SizedBox(height: AppSpacing.md),
          _ActivityItem(
              title: 'Upload scheduled successfully',
              subtitle: 'Your video is queued for tomorrow',
              icon: Icons.schedule_rounded),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityItem(
      {required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, color: color, size: 32),
          Text(label,
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          Text(value, style: AppTextStyles.heading2),
        ],
      ),
    );
  }
}
