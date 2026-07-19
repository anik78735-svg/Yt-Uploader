import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/screens/dashboard_shell.dart';
import 'package:yt_uploader_frontend/screens/login_screen.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '786154227390-53bnnlk9940qopm73teh8k2j46rgglrt.apps.googleusercontent.com',
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = false;
  String? _usernameError;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
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
        message: 'Creating your account...',
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
                      child: Text('Create account', style: AppTextStyles.heading2),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sign up with email and password, or continue with Google.',
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
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm Password'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _usernameController,
                      onChanged: (_) => _validateUsername(),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        errorText: _usernameError,
                        suffixIcon: _isCheckingUsername
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_isUsernameAvailable
                                ? const Icon(Icons.check_circle, color: AppColors.success)
                                : null),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GradientButton(
                      text: 'Sign Up',
                      onPressed: _submitSignup,
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
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        child: const Text('Already have an account? Log in'),
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

  Future<void> _validateUsername() async {
    final username = _usernameController.text.trim();
    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = null;
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Use letters, numbers, or underscores only';
      });
      return;
    }

    setState(() => _isCheckingUsername = true);
    try {
      final available = await context.read<AppState>().checkUsernameAvailability(username);
      setState(() {
        _isUsernameAvailable = available;
        _usernameError = available ? null : 'That username is already taken';
      });
    } catch (_) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Unable to check username';
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingUsername = false);
      }
    }
  }

  Future<void> _submitSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final username = _usernameController.text.trim();
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || username.isEmpty) {
      setState(() => _formError = 'Please fill in all fields');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _formError = 'Please enter a valid email');
      return;
    }
    if (password.length < 8) {
      setState(() => _formError = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _formError = 'Passwords do not match');
      return;
    }
    if (!_isUsernameAvailable) {
      setState(() => _formError = 'Please choose an available username');
      return;
    }

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      final appState = context.read<AppState>();
      final result = await appState.emailSignup(email: email, password: password, username: username);
      if (result['success'] != true) {
        setState(() => _formError = result['error']?.toString() ?? 'Unable to create account');
        return;
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardShell()));
      }
    } catch (_) {
      setState(() => _formError = 'Unable to create account. Please try again.');
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
