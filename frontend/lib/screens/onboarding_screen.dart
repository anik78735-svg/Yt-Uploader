import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yt_uploader_frontend/screens/auth_screen.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardingPage(
        icon: Icons.cloud_upload_rounded,
        title: 'Schedule videos from anywhere.',
        description: 'Plan your uploads from the comfort of your phone or desktop.',
        showSkip: true,
        isLast: false,
      ),
      _OnboardingPage(
        icon: Icons.phone_iphone_rounded,
        title: 'Phone off? Video still uploads.',
        description: 'Let TubePilot hold the queue while you stay focused.',
        showSkip: true,
        isLast: false,
      ),
      _OnboardingPage(
        icon: Icons.diamond_rounded,
        title: 'Earn time, not stress.',
        description: 'Keep your schedule flowing and your content moving.',
        showSkip: false,
        isLast: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (_, index) => pages[index],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  final active = index == _currentPage;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.textMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                  onPressed: () async {
                    if (_currentPage < pages.length - 1) {
                      await _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      await _finishOnboarding();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.showSkip,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool showSkip;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, size: 44, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: AppTextStyles.heading2, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Text(description, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
