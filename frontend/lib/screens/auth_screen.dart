import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _googleIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF111827)]),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 18)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Neo-Brutal Auth', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Secure Google onboarding, username creation, and diamond startup.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username @tech_creator')),
                const SizedBox(height: 12),
                TextField(controller: _googleIdController, decoration: const InputDecoration(labelText: 'Google ID Token')),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await state.registerUser(
                        googleId: _googleIdController.text,
                        email: _emailController.text,
                        username: _usernameController.text.isEmpty ? null : _usernameController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Enter the Matrix'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
