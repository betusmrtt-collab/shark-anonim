import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Storage işlemlerini yöneten servis
/// Bucket kontrolleri ve hata yönetimi içerir
class StorageService {
  static final _client = SupabaseConfig.client;

  /// Avatar yükleme
  static Future<String?> uploadAvatar(String filePath, String userId) async {
    try {
      AppLogger.storage.info('Avatar yükleniyor...');
      final file = File(filePath);
      final fileName = 'avatar_$userId.${filePath.split('.').last}';
      
      await _client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: FileOptions(upsert: true));
      
      final url = _client.storage.from('avatars').getPublicUrl(fileName);
      AppLogger.storage.success('Avatar yüklendi: $fileName');
      return url;
    } on StorageException catch (e) {
      return _handleStorageException(e, 'avatars', 'Avatar');
    } catch (e) {
      AppLogger.storage.error('Avatar yükleme hatası', e);
      rethrow;
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

      final fileName = 'voice_bio_$userId.m4a';
      
      await _client.storage
          .from('voice_bios')
          .upload(fileName, file, fileOptions: FileOptions(upsert: true));
      
      final url = _client.storage.from('voice_bios').getPublicUrl(fileName);
      AppLogger.storage.success('Sesli biyografi yüklendi: $fileName');
      return url;
    } on StorageException catch (e) {
      return _handleStorageException(e, 'voice_bios', 'Sesli biyografi');
    } catch (e) {
      AppLogger.storage.error('Sesli biyografi yükleme hatası', e);
      rethrow;
    }
  }

  /// Galeri resmi yükleme
  static Future<String> uploadGalleryImage(String filePath, String userId, int index) async {
    try {
      final file = File(filePath);
      final fileName = 'gallery_${userId}_$index.${filePath.split('.').last}';
      
      await _client.storage
          .from('gallery')
          .upload(fileName, file, fileOptions: FileOptions(upsert: true));
      
      final url = _client.storage.from('gallery').getPublicUrl(fileName);
      return url;
    } on StorageException catch (e) {
      return _handleStorageException(e, 'gallery', 'Galeri resmi');
    } catch (e) {
      AppLogger.storage.error('Galeri resmi yükleme hatası', e);
      rethrow;
    }
  }

  /// Storage hatalarını yönet
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
}
