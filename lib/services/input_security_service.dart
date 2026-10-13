import '../utils/logger.dart';

/// Input sanitization ve güvenlik servisi
class InputSecurityService {
  // SQL injection tehlikeli karakterler
  static final RegExp _sqlInjectionPattern = RegExp(
    r"('|(--)|;|\/\*|\*\/|xp_|sp_|exec|execute|select|insert|update|delete|drop|create|alter|union|script|javascript|<script|onclick|onerror)",
    caseSensitive: false,
  );

  // XSS tehlikeli karakterler
  static final RegExp _xssPattern = RegExp(
    r'<script|javascript:|onerror=|onclick=|onload=|<iframe|<embed|<object',
    caseSensitive: false,
  );

  // Username için izin verilen karakterler (alfanumerik, alt çizgi, tire)
  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9_-]+$');

  // Email regex (basit)
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Username validasyonu ve sanitization
  static ValidationResult validateUsername(String username) {
    // Boş kontrol
    if (username.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Kullanıcı adı boş olamaz',
      );
    }

    // @ işareti varsa kaldır
    String cleaned = username.trim();
    if (cleaned.startsWith('@')) {
      cleaned = cleaned.substring(1);
    }

    // Uzunluk kontrolü
    if (cleaned.length < 3) {
      return ValidationResult(
        isValid: false,
        error: 'Kullanıcı adı en az 3 karakter olmalı',
      );
    }

    if (cleaned.length > 30) {
      return ValidationResult(
        isValid: false,
        error: 'Kullanıcı adı en fazla 30 karakter olmalı',
      );
    }

    // Karakter kontrolü (sadece alfanumerik, _ ve -)
    if (!_usernamePattern.hasMatch(cleaned)) {
      return ValidationResult(
        isValid: false,
        error: 'Kullanıcı adı sadece harf, rakam, _ ve - içerebilir',
      );
    }

    // SQL injection kontrolü
    if (_sqlInjectionPattern.hasMatch(cleaned)) {
      AppLogger.warning('SQL injection denemesi tespit edildi', 'SECURITY');
      return ValidationResult(
        isValid: false,
        error: 'Geçersiz karakter kullanıldı',
      );
    }

    AppLogger.debug('Username validasyonu başarılı: $cleaned', 'SECURITY');
    return ValidationResult(isValid: true, sanitized: cleaned);
  }

  /// Email validasyonu
  static ValidationResult validateEmail(String email) {
    final cleaned = email.trim().toLowerCase();

    if (cleaned.isEmpty) {
      return ValidationResult(isValid: false, error: 'Email boş olamaz');
    }

    if (!_emailPattern.hasMatch(cleaned)) {
      return ValidationResult(
        isValid: false,
        error: 'Geçersiz email formatı',
      );
    }

    if (cleaned.length > 254) {
      return ValidationResult(
        isValid: false,
        error: 'Email çok uzun',
      );
    }

    // SQL injection kontrolü
    if (_sqlInjectionPattern.hasMatch(cleaned)) {
      AppLogger.warning('Email alanında SQL injection denemesi', 'SECURITY');
      return ValidationResult(isValid: false, error: 'Geçersiz email formatı');
    }

    return ValidationResult(isValid: true, sanitized: cleaned);
  }

  /// Biyografi sanitization
  static ValidationResult sanitizeBio(String bio) {
    String cleaned = bio.trim();

    // Uzunluk kontrolü
    if (cleaned.isEmpty) {
      return ValidationResult(isValid: false, error: 'Biyografi boş olamaz');
    }

    if (cleaned.length > 500) {
      return ValidationResult(
        isValid: false,
        error: 'Biyografi en fazla 500 karakter olabilir',
      );
    }

    // SQL injection kontrolü
    if (_sqlInjectionPattern.hasMatch(cleaned)) {
      AppLogger.warning('Biyografide SQL injection denemesi tespit edildi', 'SECURITY');
      return ValidationResult(
        isValid: false,
        error: 'Biyografi geçersiz karakter içeriyor',
      );
    }

    // XSS kontrolü
    if (_xssPattern.hasMatch(cleaned)) {
      AppLogger.warning('Biyografide XSS denemesi tespit edildi', 'SECURITY');
      return ValidationResult(
        isValid: false,
        error: 'Biyografi geçersiz içerik barındırıyor',
      );
    }

    // HTML encode (< > & " ' karakterlerini temizle)
    cleaned = _htmlEncode(cleaned);

    return ValidationResult(isValid: true, sanitized: cleaned);
  }

  /// Hashtag validasyonu
  static ValidationResult validateHashtag(String tag) {
    String cleaned = tag.trim();

    // # işareti varsa kaldır
    if (cleaned.startsWith('#')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.isEmpty) {
      return ValidationResult(isValid: false, error: 'Etiket boş olamaz');
    }

    if (cleaned.length > 50) {
      return ValidationResult(
        isValid: false,
        error: 'Etiket en fazla 50 karakter olabilir',
      );
    }

    // Sadece alfanumerik ve Türkçe karakterler
    final validPattern = RegExp(r'^[a-zA-Z0-9ğüşıöçĞÜŞİÖÇ_]+$');
    if (!validPattern.hasMatch(cleaned)) {
      return ValidationResult(
        isValid: false,
        error: 'Etiket sadece harf, rakam ve _ içerebilir',
      );
    }

    // SQL injection kontrolü
    if (_sqlInjectionPattern.hasMatch(cleaned)) {
      AppLogger.warning('Etikette SQL injection denemesi', 'SECURITY');
      return ValidationResult(isValid: false, error: 'Geçersiz etiket');
    }

    return ValidationResult(isValid: true, sanitized: '#$cleaned');
  }

  /// Genel metin sanitization
  static String sanitizeText(String text) {
    return _htmlEncode(text.trim());
  }

  /// HTML encode
  static String _htmlEncode(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Şifre güvenlik kontrolü
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(
        strength: 0.0,
        level: 'Zayıf',
        message: 'Şifre boş',
      );
    }

    double strength = 0.0;

    // Uzunluk
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;

    // Küçük harf
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.15;

    // Büyük harf
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;

    // Rakam
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;

    // Özel karakter
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.15;

    String level;
    String message;

    if (strength < 0.3) {
      level = 'Zayıf';
      message = 'Daha güçlü bir şifre kullanın';
    } else if (strength < 0.6) {
      level = 'Orta';
      message = 'İyileştirilebilir';
    } else if (strength < 0.8) {
      level = 'İyi';
      message = 'Güvenli şifre';
    } else {
      level = 'Güçlü';
      message = 'Çok güvenli';
    }

    return PasswordStrength(
      strength: strength,
      level: level,
      message: message,
    );
  }
}

/// Validasyon sonucu
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? sanitized;

  ValidationResult({
    required this.isValid,
    this.error,
    this.sanitized,
  });
}

/// Şifre güvenlik seviyesi
class PasswordStrength {
  final double strength; // 0.0 - 1.0
  final String level; // Zayıf, Orta, İyi, Güçlü
  final String message;

  PasswordStrength({
    required this.strength,
    required this.level,
    required this.message,
  });
}
