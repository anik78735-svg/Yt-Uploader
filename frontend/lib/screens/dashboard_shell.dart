import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/bottom_navigation.dart';
import 'package:yt_uploader_frontend/screens/home_screen.dart';
import 'package:yt_uploader_frontend/screens/upload_screen.dart';
import 'package:yt_uploader_frontend/screens/analytics_screen.dart';
import 'package:yt_uploader_frontend/screens/profile_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  NavigationItem _currentItem = NavigationItem.home;

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildCurrentScreen(),
      bottomNavigationBar: CustomBottomNavigation(
        currentItem: _currentItem,
        onItemSelected: (item) {
          setState(() {
            _currentItem = item;
          });
        },
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentItem) {
      case NavigationItem.home:
        return const HomeScreen();
      case NavigationItem.upload:
        return const UploadScreen();
      case NavigationItem.schedule:
        return const UploadScreen();
      case NavigationItem.analytics:
        return const AnalyticsScreen();
      case NavigationItem.profile:
        return const ProfileScreen();
    }
  }
}
