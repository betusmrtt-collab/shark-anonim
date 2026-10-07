import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'login_screen.dart';
import 'giris_screen.dart';
import 'home_screen.dart';
import 'services/auth_service.dart';
import 'services/app_initializer.dart';
import 'services/update_service.dart';
import 'widgets/mandatory_update_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar ayarları - hemen uygula
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8F9FF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Servisleri arka planda başlat - uygulamayı bloklamadan
  AppInitializer.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anonim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/register': (context) => const GirisScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

/// Hızlı açılan splash screen - arka planda auth kontrolü yapar
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Servislerin hazır olmasını bekle (max 3 saniye)
    await AppInitializer.ensureInitialized(
      timeout: const Duration(seconds: 3),
    );
    
    // Minimum splash süresi (çok hızlı geçişi önlemek için)
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    // ⭐ ZORUNLU GÜNCELLEME KONTROLÜ - İlk önce kontrol et
    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdate();
    
    if (updateInfo != null && updateInfo['isMandatory'] == true) {
      // Zorunlu güncelleme var - kullanıcı uygulamaya giremez
      if (mounted) {
        _showMandatoryUpdateDialog(updateInfo);
      }
      return; // Auth kontrolüne geçme, güncelleme zorunlu
    }
    
    // Güncelleme yoksa normal auth kontrolüne devam et
    _navigateToAuthScreen();
  }

  void _showMandatoryUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ Kullanıcı kapatamaz
      builder: (context) => MandatoryUpdateDialog(updateInfo: updateInfo),
    );
  }

  void _navigateToAuthScreen() {
    if (!mounted) return;
    
    // Auth durumunu kontrol et
    final authService = AuthService();
    final isAuthenticated = authService.isAuthenticated;
    
    // Doğru ekrana yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => isAuthenticated 
            ? const HomeScreen() 
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo veya uygulama adı
            Text(
              'Anonim',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
