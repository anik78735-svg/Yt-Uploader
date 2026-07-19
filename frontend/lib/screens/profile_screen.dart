import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';
import 'package:yt_uploader_frontend/screens/admin_payment_screen.dart';
import 'package:yt_uploader_frontend/screens/admin_users_screen.dart';
import 'package:yt_uploader_frontend/screens/diamond_store_screen.dart';
import 'package:yt_uploader_frontend/screens/wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildProfileStats(context),
              const SizedBox(height: AppSpacing.xl),
              _buildQuickLinks(context),
              const SizedBox(height: AppSpacing.xl),
              _buildSettings(context),
              const SizedBox(height: AppSpacing.xl),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Center(
                  child:
                      Icon(Icons.person_rounded, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.user?['username'] ?? 'User',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.user?['email'] ?? 'email@example.com',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Text(
                        'Verified',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileStats(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          children: [
            _ProfileStatCard(label: 'Uploads', value: '24'),
            _ProfileStatCard(
                label: 'Diamonds', value: state.diamondBalance.toString()),
            _ProfileStatCard(label: 'Scheduled', value: '3'),
          ],
        );
      },
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final isAdmin = state.isAdmin;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Links', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.lg),
            _ProfileMenuItem(
              icon: Icons.diamond_rounded,
              label: 'Buy Diamonds',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiamondStoreScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileMenuItem(
              icon: Icons.wallet_rounded,
              label: 'Wallet & History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileMenuItem(
              icon: Icons.youtube_searched_for_rounded,
              label: 'Connect YouTube Channel',
              onTap: () => _handleConnectYoutube(context),
            ),
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.md),
              _ProfileMenuItem(
                icon: Icons.payment_rounded,
                label: 'Payment Requests',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPaymentScreen()),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileMenuItem(
                icon: Icons.group_rounded,
                label: 'Manage Users',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _handleConnectYoutube(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final state = context.read<AppState>();
    bool isDialogShown = false;

    try {
      isDialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final authUrl = await state.getYoutubeAuthUrl();
      if (authUrl == null || authUrl.isEmpty) {
        throw Exception('Unable to start YouTube authorization');
      }

      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'com.tubepilot.app',
      );

      final parsed = Uri.tryParse(callbackUrl);
      final code = parsed?.queryParameters['code'];
      final error = parsed?.queryParameters['error'];

      if (error != null && error.isNotEmpty) {
        throw Exception(error);
      }
      if (code == null || code.isEmpty) {
        throw Exception('Authorization code was not returned');
      }

      final success = await state.connectYoutubeChannel(code: code);
      if (!success) {
        throw Exception('Unable to connect the YouTube channel');
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('YouTube channel connected successfully')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (isDialogShown) {
        try {
          navigator.pop();
        } catch (_) {}
      }
    }
  }

  Widget _buildSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settings', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.lg),
        _ProfileMenuItem(
          icon: Icons.notifications_rounded,
          label: 'Notifications',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileMenuItem(
          icon: Icons.security_rounded,
          label: 'Privacy & Security',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileMenuItem(
          icon: Icons.help_rounded,
          label: 'Help & Support',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileMenuItem(
          icon: Icons.info_rounded,
          label: 'About',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.error),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<AppState>().logout();
            },
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: const Center(
              child: Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          const Icon(Icons.arrow_forward_rounded,
              color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
