import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../utils/logger.dart';

/// Dosya güvenlik ve validasyon servisi
class FileSecurityService {
  // İzin verilen MIME tipleri
  static const List<String> _allowedImageMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  static const List<String> _allowedAudioMimeTypes = [
    'audio/mp4',
    'audio/m4a',
    'audio/aac',
    'audio/mpeg',
  ];

  // İzin verilen dosya uzantıları
  static const List<String> _allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  static const List<String> _allowedAudioExtensions = [
    '.m4a',
    '.mp3',
    '.aac',
  ];

  // Boyut limitleri (byte)
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB
  static const int maxGalleryImageSize = 15 * 1024 * 1024; // 15MB
  static const int maxVoiceSize = 10 * 1024 * 1024; // 10MB

  // Çözünürlük limitleri
  static const int avatarMaxWidth = 512;
  static const int avatarMaxHeight = 512;
  static const int galleryMaxWidth = 1920;
  static const int galleryMaxHeight = 1920;

  /// Resim dosyası validasyonu ve güvenlik kontrolü
  static Future<ValidationResult> validateImage(
    File file, {
    required ImageType type,
  }) async {
    try {
      // 1. Dosya var mı?
      if (!await file.exists()) {
        return ValidationResult(
          isValid: false,
          error: 'Dosya bulunamadı',
        );
      }

      // 2. Uzantı kontrolü
      final extension = file.path.toLowerCase().split('.').last;
      if (!_allowedImageExtensions.contains('.$extension')) {
        return ValidationResult(
          isValid: false,
          error: 'Geçersiz dosya formatı. Sadece JPG, PNG, WEBP desteklenir.',
        );
      }

      // 3. Boyut kontrolü
      final fileSize = await file.length();
      final maxSize = type == ImageType.avatar ? maxAvatarSize : maxGalleryImageSize;

      if (fileSize > maxSize) {
        return ValidationResult(
          isValid: false,
          error: 'Dosya çok büyük. Maksimum ${maxSize ~/ (1024 * 1024)}MB olmalı.',
        );
      }

      // 4. Gerçek resim mi? (Magic bytes kontrolü)
      final bytes = await file.readAsBytes();
      if (!_isValidImageFile(bytes)) {
        return ValidationResult(
          isValid: false,
          error: 'Geçersiz resim dosyası. Dosya içeriği bozuk.',
        );
      }

      // 5. Resim decode edilebiliyor mu?
      final image = img.decodeImage(bytes);
      if (image == null) {
        return ValidationResult(
          isValid: false,
          error: 'Resim okunamadı. Dosya bozuk olabilir.',
        );
      }

      AppLogger.storage.success(
        'Resim validasyonu başarılı: ${file.path} (${fileSize ~/ 1024}KB, ${image.width}x${image.height})',
      );

      return ValidationResult(
        isValid: true,
        width: image.width,
        height: image.height,
        size: fileSize,
      );
    } catch (e) {
      AppLogger.storage.error('Resim validasyon hatası', e);
      return ValidationResult(
        isValid: false,
        error: 'Dosya işlenirken hata oluştu',
      );
    }
  }

  /// Ses dosyası validasyonu
  static Future<ValidationResult> validateAudio(File file) async {
    try {
      if (!await file.exists()) {
        return ValidationResult(isValid: false, error: 'Dosya bulunamadı');
      }

      final extension = file.path.toLowerCase().split('.').last;
      if (!_allowedAudioExtensions.contains('.$extension')) {
        return ValidationResult(
          isValid: false,
          error: 'Geçersiz ses formatı. Sadece M4A, MP3, AAC desteklenir.',
        );
      }

      final fileSize = await file.length();
      if (fileSize > maxVoiceSize) {
        return ValidationResult(
          isValid: false,
          error: 'Ses dosyası çok büyük. Maksimum ${maxVoiceSize ~/ (1024 * 1024)}MB olmalı.',
        );
      }

      return ValidationResult(isValid: true, size: fileSize);
    } catch (e) {
      AppLogger.storage.error('Ses validasyon hatası', e);
      return ValidationResult(isValid: false, error: 'Dosya işlenirken hata oluştu');
    }
  }

  /// Resmi yeniden boyutlandır ve optimize et
  static Future<File> resizeAndOptimizeImage(
    File file, {
    required ImageType type,
  }) async {
    try {
      AppLogger.storage.info('Resim optimize ediliyor...');

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Resim decode edilemedi');
      }

      final maxWidth = type == ImageType.avatar ? avatarMaxWidth : galleryMaxWidth;
      final maxHeight = type == ImageType.avatar ? avatarMaxHeight : galleryMaxHeight;

      // Resize gerekli mi?
      img.Image resized = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        resized = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
          interpolation: img.Interpolation.linear,
        );
        AppLogger.storage.info('Resim boyutlandırıldı: ${image.width}x${image.height} → ${resized.width}x${resized.height}');
      }

      // JPEG olarak kaydet (optimize edilmiş)
      final quality = type == ImageType.avatar ? 85 : 80;
      final optimizedBytes = img.encodeJpg(resized, quality: quality);

      // Optimize edilmiş dosyayı kaydet
      final optimizedFile = File('${file.path}_optimized.jpg');
      await optimizedFile.writeAsBytes(optimizedBytes);

      final originalSize = await file.length();
      final optimizedSize = optimizedBytes.length;
      final savedPercent = ((originalSize - optimizedSize) / originalSize * 100).toInt();

      AppLogger.storage.success(
        'Resim optimize edildi: ${originalSize ~/ 1024}KB → ${optimizedSize ~/ 1024}KB (%$savedPercent tasarruf)',
      );

      return optimizedFile;
    } catch (e) {
      AppLogger.storage.error('Resim optimizasyon hatası', e);
      rethrow;
    }
  }

  /// Magic bytes ile gerçek dosya tipi kontrolü
  static bool _isValidImageFile(List<int> bytes) {
    if (bytes.length < 12) return false;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes.length > 11 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    return false;
  }
}

/// Resim tipi enum
enum ImageType {
  avatar,
  gallery,
}

/// Validasyon sonucu
class ValidationResult {
  final bool isValid;
  final String? error;
  final int? width;
  final int? height;
  final int? size;

  ValidationResult({
    required this.isValid,
    this.error,
    this.width,
    this.height,
    this.size,
  });
}
