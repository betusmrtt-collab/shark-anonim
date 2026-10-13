import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Rate limiting için simple counter
  static final Map<String, int> _loginAttempts = {};
  static const int maxLoginAttempts = 5;
  static const Duration rateLimitWindow = Duration(minutes: 15);

  /// Kullanıcı kayıt
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // ✅ Email validasyonu
      final emailValidation = _validateEmail(email);
      if (!emailValidation.isValid) {
        throw Exception(emailValidation.error);
      }

      // ✅ Password validasyonu
      final passwordValidation = _validatePassword(password);
      if (!passwordValidation.isValid) {
        throw Exception(passwordValidation.error);
      }

      // ✅ Username validasyonu
      final usernameValidation = _validateUsername(username);
      if (!usernameValidation.isValid) {
        throw Exception(usernameValidation.error);
      }

      // ✅ Username unique kontrolü
      final isUsernameTaken = await _checkUsernameExists(username);
      if (isUsernameTaken) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      // ✅ Email unique kontrolü (Supabase otomatik yapar ama açık hata mesajı için)
      final isEmailTaken = await _checkEmailExists(email);
      if (isEmailTaken) {
        throw Exception('Bu email adresi zaten kayıtlı');
      }

      AppLogger.auth.info('Kayıt işlemi başlatılıyor: $username');

      // Auth signup
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username.toLowerCase()},
      );

      // Eğer user oluşturulduysa ve oturum açıksa
      if (response.user != null) {
        // Biraz bekle (auth session'ın hazır olması için)
        await Future.delayed(const Duration(milliseconds: 500));

        try {
          // Users tablosuna kullanıcı bilgilerini kaydet
          await _supabase.from('users').upsert(
            {
              'id': response.user!.id,
              'email': email.toLowerCase(),
              'username': username.toLowerCase(),
              'created_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'id',
          );

          AppLogger.auth.success('Kullanıcı kaydı başarılı: $username');
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

  /// Kullanıcı giriş (Email veya Username ile)
  Future<AuthResponse> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      // ✅ Rate limiting kontrolü
      if (_isRateLimited(emailOrUsername)) {
        throw Exception(
          'Çok fazla başarısız deneme yaptınız. Lütfen ${rateLimitWindow.inMinutes} dakika sonra tekrar deneyin.',
        );
      }

      String email = emailOrUsername.toLowerCase();

      // Eğer @ yoksa, username olarak kabul et ve email'i veritabanından al
      if (!emailOrUsername.contains('@')) {
        AppLogger.auth.info('Username ile giriş denemesi: $emailOrUsername');

        try {
          // Username'den email'i bul
          final response = await _supabase
              .from('users')
              .select('email')
              .eq('username', emailOrUsername.toLowerCase())
              .maybeSingle();

          if (response == null) {
            _incrementLoginAttempts(emailOrUsername);
            throw Exception('Kullanıcı adı veya şifre hatalı');
          }

          email = response['email'] as String;
          AppLogger.auth.success('Username\'e karşılık email bulundu');
        } catch (e) {
          _incrementLoginAttempts(emailOrUsername);
          AppLogger.auth.error('Username bulunamadı', e);
          throw Exception('Kullanıcı adı veya şifre hatalı');
        }
      }

      // Email ile giriş yap
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Başarılı giriş - rate limit counter'ı temizle
      _clearLoginAttempts(emailOrUsername);

      AppLogger.auth.success('Kullanıcı girişi başarılı');
      return response;
    } on AuthException catch (e) {
      _incrementLoginAttempts(emailOrUsername);
      AppLogger.auth.error('Giriş hatası', e);

      // Kullanıcı dostu hata mesajları
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Email/kullanıcı adı veya şifre hatalı');
      } else if (e.message.contains('Email not confirmed')) {
        throw Exception('Email adresinizi onaylamanız gerekiyor');
      }

      rethrow;
    } catch (e) {
      _incrementLoginAttempts(emailOrUsername);
      AppLogger.auth.error('Giriş hatası', e);
      rethrow;
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      AppLogger.auth.success('Kullanıcı çıkış yaptı');
    } catch (e) {
      AppLogger.auth.error('Çıkış hatası', e);
      rethrow;
    }
  }

  /// Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      // Email validasyonu
      final emailValidation = _validateEmail(email);
      if (!emailValidation.isValid) {
        throw Exception(emailValidation.error);
      }

      await _supabase.auth.resetPasswordForEmail(email.toLowerCase());
      AppLogger.auth.success('Şifre sıfırlama e-postası gönderildi');
    } catch (e) {
      AppLogger.auth.error('Şifre sıfırlama hatası', e);
      rethrow;
    }
  }

  /// Email değiştirme
  Future<void> updateEmail(String newEmail) async {
    try {
      final emailValidation = _validateEmail(newEmail);
      if (!emailValidation.isValid) {
        throw Exception(emailValidation.error);
      }

      await _supabase.auth.updateUser(UserAttributes(email: newEmail.toLowerCase()));
      AppLogger.auth.success('Email güncelleme isteği gönderildi');
    } catch (e) {
      AppLogger.auth.error('Email güncelleme hatası', e);
      rethrow;
    }
  }

  /// Şifre değiştirme
  Future<void> updatePassword(String newPassword) async {
    try {
      final passwordValidation = _validatePassword(newPassword);
      if (!passwordValidation.isValid) {
        throw Exception(passwordValidation.error);
      }

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      AppLogger.auth.success('Şifre güncellendi');
    } catch (e) {
      AppLogger.auth.error('Şifre güncelleme hatası', e);
      rethrow;
    }
  }

  /// Mevcut kullanıcı
  User? get currentUser => _supabase.auth.currentUser;

  /// Auth state değişikliklerini dinle
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Kullanıcı oturum durumu
  bool get isAuthenticated => currentUser != null;

  /// Email validasyonu
  ValidationResult _validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult(isValid: false, error: 'Email boş olamaz');
    }

    // RFC 5322 basit regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return ValidationResult(isValid: false, error: 'Geçersiz email formatı');
    }

    return ValidationResult(isValid: true);
  }

  /// Password validasyonu
  ValidationResult _validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(isValid: false, error: 'Şifre boş olamaz');
    }

    if (password.length < 8) {
      return ValidationResult(isValid: false, error: 'Şifre en az 8 karakter olmalı');
    }

    if (password.length > 72) {
      return ValidationResult(isValid: false, error: 'Şifre çok uzun (max 72 karakter)');
    }

    // En az bir büyük harf
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return ValidationResult(isValid: false, error: 'Şifre en az bir büyük harf içermeli');
    }

    // En az bir küçük harf
    if (!password.contains(RegExp(r'[a-z]'))) {
      return ValidationResult(isValid: false, error: 'Şifre en az bir küçük harf içermeli');
    }

    // En az bir rakam
    if (!password.contains(RegExp(r'[0-9]'))) {
      return ValidationResult(isValid: false, error: 'Şifre en az bir rakam içermeli');
    }

    return ValidationResult(isValid: true);
  }

  /// Username validasyonu
  ValidationResult _validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationResult(isValid: false, error: 'Kullanıcı adı boş olamaz');
    }

    if (username.length < 3) {
      return ValidationResult(isValid: false, error: 'Kullanıcı adı en az 3 karakter olmalı');
    }

    if (username.length > 20) {
      return ValidationResult(isValid: false, error: 'Kullanıcı adı çok uzun (max 20 karakter)');
    }

    // Sadece harf, rakam ve alt çizgi
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      return ValidationResult(
        isValid: false,
        error: 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir',
      );
    }

    // Rakamla başlayamaz
    if (username[0].contains(RegExp(r'[0-9]'))) {
      return ValidationResult(isValid: false, error: 'Kullanıcı adı rakamla başlayamaz');
    }

    return ValidationResult(isValid: true);
  }

  /// Username var mı kontrolü
  Future<bool> _checkUsernameExists(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('username', username.toLowerCase())
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.auth.error('Username kontrolü hatası', e);
      return false;
    }
  }

  /// Email var mı kontrolü
  Future<bool> _checkEmailExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.auth.error('Email kontrolü hatası', e);
      return false;
    }
  }

  /// Rate limiting kontrolü
  bool _isRateLimited(String identifier) {
    final attempts = _loginAttempts[identifier] ?? 0;
    return attempts >= maxLoginAttempts;
  }

  /// Login attempt sayacını artır
  void _incrementLoginAttempts(String identifier) {
    _loginAttempts[identifier] = (_loginAttempts[identifier] ?? 0) + 1;

    // Belirli süre sonra temizle
    Future.delayed(rateLimitWindow, () {
      _loginAttempts.remove(identifier);
    });
  }

  /// Login attempt sayacını temizle
  void _clearLoginAttempts(String identifier) {
    _loginAttempts.remove(identifier);
  }
}

/// Validasyon sonucu
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});
}
