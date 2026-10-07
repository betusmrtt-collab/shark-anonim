import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    // Frame render olduktan sonra güncelleme kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      print('🔄 Güncelleme kontrolü başlatılıyor...');
      final updateInfo = await _updateService.checkForUpdate();

      if (updateInfo != null && mounted) {
        print('✅ Güncelleme bulundu, dialog gösteriliyor...');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
      } else {
        print('ℹ️ Güncelleme bulunamadı');
      }
    } catch (e) {
      print('❌ Güncelleme kontrolü hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme kontrolü başarısız: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Stitches',
          style: TextStyle(
            color: Color(0xFF0B1C30),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.system_update, color: Color(0xFF00687A)),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Güncelleme kontrol ediliyor...')),
              );
              await _checkForUpdates();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF00687A)),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00687A), Color(0xFF57DFFE)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00687A).withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 30),
              
              // Welcome message
              const Text(
                'Hoş Geldin! 🎉',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 10),
              
              const Text(
                'Supabase bağlantısı başarılı!',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF76777D),
                ),
              ),
              const SizedBox(height: 40),
              
              // User info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kullanıcı Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'User ID',
                      value: user?.id ?? 'Bilinmiyor',
                    ),
                    const SizedBox(height: 10),
                    
                    _buildInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: user?.email ?? 'Bilinmiyor',
                    ),
                    const SizedBox(height: 10),
                    
                    _buildInfoRow(
                      icon: Icons.verified_user,
                      label: 'Durum',
                      value: 'Aktif',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Status badges
              Wrap(
                spacing: 10,
                children: [
                  _buildBadge('🔐 Şifreli', const Color(0xFF00687A)),
                  _buildBadge('✅ Bağlı', const Color(0xFF00AA00)),
                  _buildBadge('⚡ Hazır', const Color(0xFF57DFFE)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE5EEFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF00687A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF76777D),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1C30),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
