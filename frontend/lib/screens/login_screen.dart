import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/screens/dashboard_shell.dart';
import 'package:yt_uploader_frontend/screens/signup_screen.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '786154227390-53bnnlk9940qopm73teh8k2j46rgglrt.apps.googleusercontent.com',
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
        message: 'Signing you in...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text('Welcome back', style: AppTextStyles.heading2),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Log in with your email and password, or continue with Google.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_formError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          _formError!,
                          style: AppTextStyles.body.copyWith(color: AppColors.error),
                        ),
                      ),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GradientButton(
                      text: 'Log In',
                      onPressed: _submitLogin,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Row(children: [Expanded(child: Divider()), SizedBox(width: AppSpacing.md), Text('or'), SizedBox(width: AppSpacing.md), Expanded(child: Divider())]),
                    const SizedBox(height: AppSpacing.lg),
                    GradientButton(
                      text: 'Continue with Google',
                      onPressed: _handleGoogleLogin,
                      gradientStart: AppColors.secondary,
                      gradientEnd: AppColors.primary,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignupScreen()));
                        },
                        child: const Text('Don\'t have an account? Sign up'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _formError = 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      final appState = context.read<AppState>();
      final result = await appState.emailLogin(email: email, password: password);
      if (result['success'] != true) {
        setState(() => _formError = result['error']?.toString() ?? 'Invalid email or password');
        return;
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardShell()));
      }
    } catch (_) {
      setState(() => _formError = 'Unable to log in. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
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
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardShell()));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: ${error.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
