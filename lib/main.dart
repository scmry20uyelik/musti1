import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/home/presentation/pages/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialization
  await Supabase.initialize(
    url: 'https://gohrxehnreohljgsxlig.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvaHJ4ZWhucmVvaGxqZ3N4bGlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NjM2MDQsImV4cCI6MjA4MzUzOTYwNH0.OrIQIoxV2-9jUK2fNvv-scTuejetftm1RISB1bEZwl4',
  );

  runApp(const ProviderScope(child: MirmirApp()));
}

class MirmirApp extends StatelessWidget {
  const MirmirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Almanca AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.hasData ? snapshot.data!.session : null;

          if (session != null) {
            return const MainScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
