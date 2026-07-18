import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

// Make sure the Android SHA-1 fingerprint is registered in Google Cloud Console for Google Sign-In.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  bool _isLoading = false;

  @override
  void dispose() {
    _googleSignIn.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Signing in with Google...',
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
                            child: Icon(Icons.play_arrow_rounded,
                                size: 40, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Column(
                          children: [
                            const Text('Welcome to YT Uploader',
                                style: AppTextStyles.heading2),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Sign in with Google to continue',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          text: 'Continue with Google',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted),
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
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Google ID token not available');
      }

      final success = await appState.googleLogin(idToken: idToken);
      if (!success) {
        throw Exception('Unable to sign in with Google');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
