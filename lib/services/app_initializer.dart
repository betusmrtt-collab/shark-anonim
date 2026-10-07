import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

/// Uygulama başlangıç servisi - kritik servisleri optimize şekilde başlatır
class AppInitializer {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// Supabase ve diğer kritik servisleri başlat
  static Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Supabase'i başlat
      await SupabaseConfig.initialize();
      
      _isInitialized = true;
      debugPrint('✅ AppInitializer: Tüm servisler başarıyla başlatıldı');
    } catch (e) {
      debugPrint('❌ AppInitializer: Başlatma hatası - $e');
      // Hata olsa bile uygulama çalışmaya devam etsin
    } finally {
      _isInitializing = false;
    }
  }

  /// Servislerin başlatılıp başlatılmadığını kontrol et
  static bool get isInitialized => _isInitialized;

  /// Servislerin hazır olmasını bekle (timeout ile)
  static Future<void> ensureInitialized({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isInitialized) return;

    final startTime = DateTime.now();
    
    while (!_isInitialized) {
      // Timeout kontrolü
      if (DateTime.now().difference(startTime) > timeout) {
        debugPrint('⚠️ AppInitializer: Başlatma timeout - devam ediliyor');
        break;
      }

      // Kısa bekle
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
