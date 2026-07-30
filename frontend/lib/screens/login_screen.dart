import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _goToApp(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainNavigationScreen(user: user)),
    );
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    User? user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      _goToApp(user);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-In Failed. Please try again.")),
      );
    }
  }

  void _handleSkip() async {
    setState(() => _isLoading = true);
    User? user = await _authService.signInAsGuest();
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      _goToApp(user);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not continue as guest.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.white38 : Colors.black26;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/splash.png", width: 90, height: 90, fit: BoxFit.contain),
              const SizedBox(height: 24),
              Text(
                "Login to Continue",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator(color: AppColors.primary)
                  : Column(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.login, color: Colors.redAccent),
                          label: Text(
                            "Continue with Google",
                            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _handleSkip,
                          child: Text(
                            "Skip for now",
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
