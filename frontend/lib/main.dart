import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/screens/auth_screen.dart';
import 'package:yt_uploader_frontend/screens/dashboard_shell.dart';
import 'package:yt_uploader_frontend/screens/splash_screen.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(prefs),
    child: const YtUploaderApp(),
  ));
}

class YtUploaderApp extends StatelessWidget {
  const YtUploaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yt Uploader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<AppState>().bootstrap(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final state = context.watch<AppState>();
        return state.isAuthenticated ? const DashboardShell() : const AuthScreen();
      },
    );
  }
}

