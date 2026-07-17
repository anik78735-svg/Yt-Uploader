import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/screens/auth_screen.dart';
import 'package:yt_uploader_frontend/screens/dashboard_screen.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF060816),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF7C3AED), secondary: Color(0xFF06B6D4)),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return state.isAuthenticated ? const DashboardScreen() : const AuthScreen();
  }
}
