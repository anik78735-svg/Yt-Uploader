import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _googleIdController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _googleIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Authenticating...',
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
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
                            child: Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Column(
                          children: [
                            const Text('Welcome to YT Uploader', style: AppTextStyles.heading2),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Schedule, Upload, Relax',
                              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      Text('Email', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _emailController,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'your@email.com',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Username', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _usernameController,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: '@your_username',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Google ID Token', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _googleIdController,
                        style: AppTextStyles.body,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Paste your Google ID token',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          text: 'Login with Google',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty ||
        _googleIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AppState>().registerUser(
        googleId: _googleIdController.text,
        email: _emailController.text,
        username: _usernameController.text.isEmpty ? null : _usernameController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
