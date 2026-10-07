import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Kullanıcı kayıt
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Önce auth.signUp yap
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      
      // Eğer user oluşturulduysa ve oturum açıksa
      if (response.user != null) {
        // Biraz bekle (auth session'ın hazır olması için)
        await Future.delayed(const Duration(milliseconds: 500));

        try {
          // Users tablosuna kullanıcı bilgilerini kaydet
          await _supabase.from('users').upsert({
            'id': response.user!.id,
            'email': email,
            'username': username,
          }, onConflict: 'id');

          AppLogger.auth.success('Kullanıcı kaydı başarılı');
        } catch (e) {
          AppLogger.auth.error('Users tablosuna ekleme hatası', e);
          // Auth başarılı ama tablo kaydı başarısız
          // Yine de devam edebilir, user zaten auth'da var
        }
      }

      return response;
    } catch (e) {
      AppLogger.auth.error('Kayıt hatası', e);
      rethrow;
    }
  }

  // Kullanıcı giriş
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLogger.auth.success('Kullanıcı girişi başarılı');
      return response;
    } catch (e) {
      AppLogger.auth.error('Giriş hatası', e);
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      AppLogger.auth.success('Kullanıcı çıkış yaptı');
    } catch (e) {
      AppLogger.auth.error('Çıkış hatası', e);
      rethrow;
    }
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      AppLogger.auth.success('Şifre sıfırlama e-postası gönderildi');
    } catch (e) {
      AppLogger.auth.error('Şifre sıfırlama hatası', e);
      rethrow;
    }
  }

  // Mevcut kullanıcı
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state değişikliklerini dinle
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Kullanıcı oturum durumu
  bool get isAuthenticated => currentUser != null;
}
