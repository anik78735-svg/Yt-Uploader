import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isAvailable = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.user?['hasCustomUsername'] == true) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Saving username...',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Choose your username', style: AppTextStyles.heading2),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Create a memorable username for your YT Uploader profile.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text('Username', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _usernameController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      prefixText: '@',
                      hintText: 'yourusername',
                      errorText: _errorText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: 'Save username',
                      isLoading: _isLoading,
                      onPressed: _saveUsername,
                    ),
                  ),
                  if (_isAvailable && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        'Username available',
                        style: AppTextStyles.body.copyWith(color: AppColors.success),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorText = 'Username cannot be empty');
      return;
    }

    if (!_isValidUsername(username)) {
      setState(() => _errorText = 'Use letters, numbers, underscores only');
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();
      final isAvailable = await appState.checkUsernameAvailability(username);
      if (!isAvailable) {
        setState(() {
          _errorText = 'That username is already taken';
          _isAvailable = false;
        });
        return;
      }

      final saved = await appState.setUsername(username);
      if (!saved) {
        setState(() => _errorText = 'Unable to save username. Please try again.');
      }
    } catch (error) {
      setState(() => _errorText = 'Failed to save username. Check your connection.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidUsername(String username) {
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
    return usernameRegExp.hasMatch(username);
  }
}
