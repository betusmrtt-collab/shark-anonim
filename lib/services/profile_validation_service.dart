import '../utils/logger.dart';

/// Profil validasyon ve güvenlik kontrol servisi
class ProfileValidationService {
  /// Profil tamamlığını doğrula
  static ProfileValidationResult validateProfileCompleteness({
    String? avatarUrl,
    String? bio,
    String? voiceBioUrl,
    List<String>? tags,
    List<String>? galleryImages,
    String? gender,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    // Kritik eksiklikler (errors)
    if (bio == null || bio.trim().isEmpty) {
      errors.add('Biyografi boş olamaz');
    } else if (bio.trim().length < 10) {
      errors.add('Biyografi en az 10 karakter olmalı');
    }

    // Önemli eksiklikler (warnings)
    if (avatarUrl == null || avatarUrl.isEmpty) {
      warnings.add('Profil fotoğrafı eklenmemiş');
    }

    if (gender == null || gender.isEmpty) {
      warnings.add('Cinsiyet bilgisi eklenmemiş');
    }

    if (tags == null || tags.isEmpty) {
      warnings.add('Hiç etiket eklenmemiş');
    } else if (tags.length < 3) {
      warnings.add('En az 3 etiket eklenmesi önerilir');
    }

    // İyileştirme önerileri (suggestions)
    if (voiceBioUrl == null || voiceBioUrl.isEmpty) {
      suggestions.add('Sesli tanıtım ekleyerek öne çıkabilirsin');
    }

    if (galleryImages == null || galleryImages.isEmpty) {
      suggestions.add('Galeri fotoğrafları ekle');
    } else if (galleryImages.length < 3) {
      suggestions.add('Daha fazla galeri fotoğrafı ekleyerek profilini zenginleştir');
    }

    if (bio != null && bio.length < 50) {
      suggestions.add('Daha detaylı bir biyografi yazmayı deneyin');
    }

    final isValid = errors.isEmpty;
    final completionScore = _calculateCompletionScore(
      avatarUrl: avatarUrl,
      bio: bio,
      voiceBioUrl: voiceBioUrl,
      tags: tags,
      galleryImages: galleryImages,
      gender: gender,
    );

    return ProfileValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
      completionScore: completionScore,
    );
  }

  /// Profil içerik güvenliği kontrolü
  static ContentSafetyResult validateContentSafety({
    String? bio,
    List<String>? tags,
  }) {
    final flags = <String>[];
    bool isSafe = true;

    // Yasaklı kelimeler (örnek liste)
    final bannedWords = [
      'instagram',
      'whatsapp',
      'telegram',
      'snap',
      'snapchat',
      'twitter',
      'facebook',
      'phone',
      'telefon',
      'numara',
      '+90',
      '@',
      'www.',
      '.com',
      '.net',
      'http',
    ];

    // Kişisel bilgi pattern'leri
    final patterns = [
      RegExp(r'\b\d{10,11}\b'), // Telefon numarası
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email
      RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b'), // IP adresi
    ];

    // Bio kontrolü
    if (bio != null) {
      final lowerBio = bio.toLowerCase();

      // Yasaklı kelime kontrolü
      for (final word in bannedWords) {
        if (lowerBio.contains(word)) {
          flags.add('Biyografide sosyal medya/iletişim bilgisi: $word');
          isSafe = false;
        }
      }

      // Pattern kontrolü
      for (final pattern in patterns) {
        if (pattern.hasMatch(bio)) {
          flags.add('Biyografide kişisel bilgi tespit edildi');
          isSafe = false;
        }
      }

      // Spam kontrolü
      if (_isSpammy(bio)) {
        flags.add('Biyografi spam içeriyor olabilir');
        isSafe = false;
      }
    }

    // Tag kontrolü
    if (tags != null) {
      for (final tag in tags) {
        final lowerTag = tag.toLowerCase();
        for (final word in bannedWords) {
          if (lowerTag.contains(word)) {
            flags.add('Etiket uygunsuz: $tag');
            isSafe = false;
          }
        }
      }
    }

    return ContentSafetyResult(
      isSafe: isSafe,
      flags: flags,
    );
  }

  /// Bio kalitesi analizi
  static BioQualityScore analyzeBioQuality(String? bio) {
    if (bio == null || bio.trim().isEmpty) {
      return BioQualityScore(
        score: 0,
        feedback: 'Biyografi boş',
        tips: ['Kendinizi tanıtan bir biyografi yazın'],
      );
    }

    int score = 0;
    final tips = <String>[];

    // Uzunluk kontrolü
    final length = bio.trim().length;
    if (length >= 100) {
      score += 30;
    } else if (length >= 50) {
      score += 20;
      tips.add('Daha detaylı bir biyografi yazmayı deneyin');
    } else if (length >= 20) {
      score += 10;
      tips.add('Biyografinizi genişletin (en az 50 karakter önerilir)');
    } else {
      tips.add('Çok kısa bir biyografi. En az 50 karakter yazın');
    }

    // Kelime sayısı
    final wordCount = bio.split(RegExp(r'\s+')).length;
    if (wordCount >= 20) {
      score += 20;
    } else if (wordCount >= 10) {
      score += 10;
    } else {
      tips.add('Daha fazla kelime kullanın');
    }

    // Emoji kullanımı (ölçülü)
    final emojiCount = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true)
        .allMatches(bio)
        .length;
    if (emojiCount > 0 && emojiCount <= 5) {
      score += 10;
    } else if (emojiCount > 5) {
      tips.add('Çok fazla emoji kullanımı. Daha sade bir anlatım deneyin');
    }

    // Noktalama işareti kullanımı
    if (bio.contains('.') || bio.contains('!') || bio.contains('?')) {
      score += 10;
    } else {
      tips.add('Noktalama işaretleri kullanarak daha okunabilir hale getirin');
    }

    // Büyük harf kullanımı
    if (bio[0] == bio[0].toUpperCase()) {
      score += 5;
    }

    // Çeşitlilik (farklı kelimeler)
    final uniqueWords = bio.toLowerCase().split(RegExp(r'\s+')).toSet().length;
    if (uniqueWords >= wordCount * 0.7) {
      score += 15;
    } else {
      tips.add('Kelime çeşitliliğini artırın, aynı kelimeleri tekrar etmeyin');
    }

    // Spam kontrolü
    if (_isSpammy(bio)) {
      score = (score * 0.5).round();
      tips.add('Tekrarlayan ifadelerden kaçının');
    }

    // Maksimum 100 puan
    score = score.clamp(0, 100);

    String feedback;
    if (score >= 80) {
      feedback = 'Harika bir biyografi!';
    } else if (score >= 60) {
      feedback = 'İyi bir biyografi, biraz daha geliştirilebilir';
    } else if (score >= 40) {
      feedback = 'Orta seviye, geliştirmeye açık';
    } else {
      feedback = 'Biyografinizi geliştirin';
    }

    return BioQualityScore(
      score: score,
      feedback: feedback,
      tips: tips,
    );
  }

  /// Spam kontrolü
  static bool _isSpammy(String text) {
    // Tekrarlayan karakterler
    if (RegExp(r'(.)\1{4,}').hasMatch(text)) return true;

    // Çok fazla büyük harf
    final upperCount = text.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (upperCount > text.length * 0.5) return true;

    // Çok fazla noktalama
    final punctCount = text.replaceAll(RegExp(r'[^!?.,:;]'), '').length;
    if (punctCount > text.length * 0.3) return true;

    return false;
  }

  /// Tamamlanma skoru hesaplama
  static int _calculateCompletionScore({
    String? avatarUrl,
    String? bio,
    String? voiceBioUrl,
    List<String>? tags,
    List<String>? galleryImages,
    String? gender,
  }) {
    int score = 0;

    // Avatar (20 puan)
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      score += 20;
    }

    // Bio (25 puan)
    if (bio != null && bio.trim().length >= 20) {
      score += 25;
    } else if (bio != null && bio.trim().length >= 10) {
      score += 15;
    }

    // Voice bio (20 puan)
    if (voiceBioUrl != null && voiceBioUrl.isNotEmpty) {
      score += 20;
    }

    // Tags (15 puan)
    if (tags != null) {
      if (tags.length >= 5) {
        score += 15;
      } else if (tags.length >= 3) {
        score += 10;
      } else if (tags.isNotEmpty) {
        score += 5;
      }
    }

    // Gallery (15 puan)
    if (galleryImages != null) {
      if (galleryImages.length >= 4) {
        score += 15;
      } else if (galleryImages.length >= 2) {
        score += 10;
      } else if (galleryImages.isNotEmpty) {
        score += 5;
      }
    }

    // Gender (5 puan)
    if (gender != null && gender.isNotEmpty) {
      score += 5;
    }

    return score.clamp(0, 100);
  }
}

/// Validasyon sonucu
class ProfileValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestions;
  final int completionScore;

  ProfileValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.suggestions,
    required this.completionScore,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get isPerfect => isValid && !hasWarnings && completionScore == 100;
}

/// İçerik güvenliği sonucu
class ContentSafetyResult {
  final bool isSafe;
  final List<String> flags;

  ContentSafetyResult({
    required this.isSafe,
    required this.flags,
  });

  bool get hasFlags => flags.isNotEmpty;
}

/// Bio kalite skoru
class BioQualityScore {
  final int score;
  final String feedback;
  final List<String> tips;

  BioQualityScore({
    required this.score,
    required this.feedback,
    required this.tips,
  });

  bool get isExcellent => score >= 80;
  bool get isGood => score >= 60;
  bool get needsImprovement => score < 60;
}
