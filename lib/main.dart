import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'login_screen.dart';
import 'giris_screen.dart';
import 'home_screen.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialize
  await SupabaseConfig.initialize();

  // Status bar ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8F9FF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      title: 'Anonim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authService.isAuthenticated ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/register': (context) => const GirisScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
