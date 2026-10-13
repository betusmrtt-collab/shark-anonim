import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';
import 'file_security_service.dart';

/// Storage işlemlerini yöneten servis
/// Bucket kontrolleri, validasyon ve hata yönetimi içerir
class StorageService {
  static final _client = SupabaseConfig.client;

  // File size limits (bytes)
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB
  static const int maxGallerySize = 15 * 1024 * 1024; // 15MB
  static const int maxVoiceBioSize = 10 * 1024 * 1024; // 10MB

  /// Avatar yükleme
  static Future<String?> uploadAvatar(String filePath, String userId) async {
    try {
      AppLogger.storage.info('Avatar yükleniyor...');
      final file = File(filePath);

      // ✅ Dosya boyutu kontrolü
      final fileSize = await file.length();
      if (fileSize > maxAvatarSize) {
        throw Exception('Avatar dosyası çok büyük (max 5MB)');
      }

      // ✅ Dosya validasyonu
      final validation = await FileSecurityService.validateImage(
        file,
        type: ImageType.avatar,
      );
      if (!validation.isValid) {
        throw Exception(validation.error);
      }

      // ✅ Eski avatar'ı sil
      try {
        await _deleteOldAvatar(userId);
      } catch (e) {
        AppLogger.storage.error('Eski avatar silinemedi (devam ediliyor)', e);
      }

      final extension = filePath.split('.').last.toLowerCase();
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Progress tracking için
      await _client.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$extension',
            ),
          );

      final url = _client.storage.from('avatars').getPublicUrl(fileName);
      AppLogger.storage.success('Avatar yüklendi: $fileName');
      return url;
    } on StorageException catch (e) {
      _handleStorageException(e, 'avatars', 'Avatar');
    } catch (e) {
      AppLogger.storage.error('Avatar yükleme hatası', e);
      rethrow;
    }
  }

  /// Eski avatar'ı sil
  static Future<void> _deleteOldAvatar(String userId) async {
    try {
      final files = await _client.storage.from('avatars').list(path: userId);
      for (final file in files) {
        await _client.storage.from('avatars').remove(['$userId/${file.name}']);
      }
      AppLogger.storage.success('Eski avatar silindi');
    } catch (e) {
      AppLogger.storage.error('Eski avatar silinirken hata', e);
    }
  }

  /// Sesli biyografi yükleme
  static Future<String?> uploadVoiceBio(String filePath, String userId) async {
    try {
      AppLogger.storage.info('Sesli biyografi yükleniyor...');
      final file = File(filePath);

      if (!await file.exists()) {
        AppLogger.storage.warning('Ses dosyası bulunamadı, atlanıyor');
        return null;
      }

      // ✅ Dosya boyutu kontrolü
      final fileSize = await file.length();
      if (fileSize > maxVoiceBioSize) {
        throw Exception('Ses dosyası çok büyük (max 10MB)');
      }

      // ✅ Ses dosyası validasyonu
      final validation = await FileSecurityService.validateAudio(file);
      if (!validation.isValid) {
        throw Exception(validation.error);
      }

      // ✅ Eski ses dosyasını sil
      try {
        await _deleteOldVoiceBio(userId);
      } catch (e) {
        AppLogger.storage.error('Eski ses dosyası silinemedi (devam ediliyor)', e);
      }

      final extension = filePath.split('.').last.toLowerCase();
      final fileName = '$userId/voice_bio_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from('voice_bios').upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'audio/$extension',
            ),
          );

      final url = _client.storage.from('voice_bios').getPublicUrl(fileName);
      AppLogger.storage.success('Sesli biyografi yüklendi: $fileName');
      return url;
    } on StorageException catch (e) {
      _handleStorageException(e, 'voice_bios', 'Sesli biyografi');
    } catch (e) {
      AppLogger.storage.error('Sesli biyografi yükleme hatası', e);
      rethrow;
    }
  }

  /// Eski sesli biyografiyi sil
  static Future<void> _deleteOldVoiceBio(String userId) async {
    try {
      final files = await _client.storage.from('voice_bios').list(path: userId);
      for (final file in files) {
        await _client.storage.from('voice_bios').remove(['$userId/${file.name}']);
      }
      AppLogger.storage.success('Eski ses dosyası silindi');
    } catch (e) {
      AppLogger.storage.error('Eski ses dosyası silinirken hata', e);
    }
  }

  /// Galeri resmi yükleme
  static Future<String> uploadGalleryImage(String filePath, String userId, int index) async {
    try {
      final file = File(filePath);

      // ✅ Dosya boyutu kontrolü
      final fileSize = await file.length();
      if (fileSize > maxGallerySize) {
        throw Exception('Galeri resmi çok büyük (max 15MB)');
      }

      // ✅ Dosya validasyonu
      final validation = await FileSecurityService.validateImage(
        file,
        type: ImageType.gallery,
      );
      if (!validation.isValid) {
        throw Exception(validation.error);
      }

      final extension = filePath.split('.').last.toLowerCase();
      final fileName = '$userId/gallery_${index}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from('gallery').upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$extension',
            ),
          );

      final url = _client.storage.from('gallery').getPublicUrl(fileName);
      AppLogger.storage.success('Galeri resmi yüklendi: $fileName');
      return url;
    } on StorageException catch (e) {
      _handleStorageException(e, 'gallery', 'Galeri resmi');
    } catch (e) {
      AppLogger.storage.error('Galeri resmi yükleme hatası', e);
      rethrow;
    }
  }

  /// Galeri resmini sil
  static Future<void> deleteGalleryImage(String imageUrl) async {
    try {
      // URL'den dosya adını çıkar
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.sublist(pathSegments.length - 2).join('/');

      await _client.storage.from('gallery').remove([fileName]);
      AppLogger.storage.success('Galeri resmi silindi: $fileName');
    } catch (e) {
      AppLogger.storage.error('Galeri resmi silme hatası', e);
      rethrow;
    }
  }

  /// Kullanıcının tüm galeri resimlerini sil
  static Future<void> deleteAllGalleryImages(String userId) async {
    try {
      final files = await _client.storage.from('gallery').list(path: userId);
      final fileNames = files.map((f) => '$userId/${f.name}').toList();

      if (fileNames.isNotEmpty) {
        await _client.storage.from('gallery').remove(fileNames);
        AppLogger.storage.success('Tüm galeri resimleri silindi (${fileNames.length} adet)');
      }
    } catch (e) {
      AppLogger.storage.error('Galeri resimleri silme hatası', e);
      rethrow;
    }
  }

  /// Storage hatalarını yönet
  /// ✅ DÜZELTME: Never yerine Exception throw et
  static Never _handleStorageException(StorageException e, String bucketName, String resourceName) {
    if (e.message.contains('Bucket not found') || e.statusCode == '404') {
      AppLogger.storage.error(
        '$resourceName bucket bulunamadı. Lütfen Supabase Storage\'da "$bucketName" bucket\'ını oluşturun.',
        e,
      );
      throw Exception(
        'Storage yapılandırması eksik.\n\n'
        'Lütfen Supabase Dashboard\'a giderek şu bucket\'ları oluşturun:\n'
        '• avatars (Public)\n'
        '• voice_bios (Public)\n'
        '• gallery (Public)\n\n'
        'Veya uygulamayı güncelleyin.',
      );
    }

    AppLogger.storage.error('$resourceName yükleme hatası', e);
    throw Exception('$resourceName yüklenirken hata oluştu: ${e.message}');
  }

  /// Bucket'ların varlığını kontrol et (opsiyonel - admin yetkisi gerektirir)
  static Future<Map<String, bool>> checkBuckets() async {
    final buckets = ['avatars', 'voice_bios', 'gallery'];
    final results = <String, bool>{};

    for (final bucket in buckets) {
      try {
        // Bucket'a erişmeyi dene
        await _client.storage.from(bucket).list(
              path: '',
              searchOptions: const SearchOptions(limit: 1),
            );
        results[bucket] = true;
        AppLogger.storage.success('Bucket mevcut: $bucket');
      } catch (e) {
        results[bucket] = false;
        AppLogger.storage.warning('Bucket bulunamadı: $bucket');
      }
    }

    return results;
  }

  /// Upload progress tracking için stream
  static Stream<double> uploadWithProgress(String filePath, String bucket, String fileName) async* {
    final file = File(filePath);
    final fileSize = await file.length();
    int uploadedBytes = 0;

    // Chunked upload simülasyonu (Supabase SDK native progress desteklemiyor)
    // Production'da tus.io veya custom implementation kullanılabilir
    const chunkSize = 1024 * 1024; // 1MB chunks

    while (uploadedBytes < fileSize) {
      await Future.delayed(const Duration(milliseconds: 100));
      uploadedBytes += chunkSize;
      final progress = (uploadedBytes / fileSize).clamp(0.0, 1.0);
      yield progress;
    }
  }

  /// Retry mekanizması ile upload
  static Future<T> uploadWithRetry<T>(
    Future<T> Function() uploadFunction, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await uploadFunction();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        AppLogger.storage.warning('Upload başarısız, yeniden deneniyor ($attempts/$maxRetries)');
        await Future.delayed(retryDelay * attempts);
      }
    }

    throw Exception('Upload başarısız oldu ($maxRetries deneme sonrası)');
  }
}
