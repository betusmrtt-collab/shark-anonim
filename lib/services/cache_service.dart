import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

/// Cache servisi - Profil ve user verilerini cache'ler
class CacheService {
  static const String _profileBoxName = 'profile_cache';
  static const String _userBoxName = 'user_cache';
  static const String _statsBoxName = 'stats_cache';

  static Box<dynamic>? _profileBox;
  static Box<dynamic>? _userBox;
  static Box<dynamic>? _statsBox;

  // TTL (Time To Live) - 30 dakika
  static const Duration cacheTTL = Duration(minutes: 30);

  /// Initialize Hive
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _profileBox = await Hive.openBox(_profileBoxName);
      _userBox = await Hive.openBox(_userBoxName);
      _statsBox = await Hive.openBox(_statsBoxName);
      AppLogger.database.success('Cache servisi başlatıldı');
    } catch (e) {
      AppLogger.database.error('Cache init hatası', e);
    }
  }

  /// Profil cache'le
  static Future<void> cacheProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final cacheData = {
        'data': profileData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _profileBox?.put(userId, cacheData);
      AppLogger.database.debug('Profil cache\'lendi: $userId');
    } catch (e) {
      AppLogger.database.error('Profil cache hatası', e);
    }
  }

  /// Cache'den profil al
  static Map<String, dynamic>? getCachedProfile(String userId) {
    try {
      final cacheData = _profileBox?.get(userId);
      if (cacheData == null) return null;

      // TTL kontrolü
      final timestamp = cacheData['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (cacheAge > cacheTTL.inMilliseconds) {
        // Cache expired
        _profileBox?.delete(userId);
        AppLogger.database.debug('Cache expired: $userId');
        return null;
      }

      AppLogger.database.debug('Cache hit: $userId');
      return Map<String, dynamic>.from(cacheData['data']);
    } catch (e) {
      AppLogger.database.error('Cache okuma hatası', e);
      return null;
    }
  }

  /// User data cache'le
  static Future<void> cacheUser(String userId, Map<String, dynamic> userData) async {
    try {
      final cacheData = {
        'data': userData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _userBox?.put(userId, cacheData);
      AppLogger.database.debug('User cache\'lendi: $userId');
    } catch (e) {
      AppLogger.database.error('User cache hatası', e);
    }
  }

  /// Cache'den user al
  static Map<String, dynamic>? getCachedUser(String userId) {
    try {
      final cacheData = _userBox?.get(userId);
      if (cacheData == null) return null;

      final timestamp = cacheData['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (cacheAge > cacheTTL.inMilliseconds) {
        _userBox?.delete(userId);
        return null;
      }

      return Map<String, dynamic>.from(cacheData['data']);
    } catch (e) {
      AppLogger.database.error('User cache okuma hatası', e);
      return null;
    }
  }

  /// Stats cache'le
  static Future<void> cacheStats(String userId, Map<String, dynamic> statsData) async {
    try {
      final cacheData = {
        'data': statsData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _statsBox?.put(userId, cacheData);
      AppLogger.database.debug('Stats cache\'lendi: $userId');
    } catch (e) {
      AppLogger.database.error('Stats cache hatası', e);
    }
  }

  /// Cache'den stats al
  static Map<String, dynamic>? getCachedStats(String userId) {
    try {
      final cacheData = _statsBox?.get(userId);
      if (cacheData == null) return null;

      final timestamp = cacheData['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (cacheAge > cacheTTL.inMilliseconds) {
        _statsBox?.delete(userId);
        return null;
      }

      return Map<String, dynamic>.from(cacheData['data']);
    } catch (e) {
      AppLogger.database.error('Stats cache okuma hatası', e);
      return null;
    }
  }

  /// Belirli bir kullanıcının cache'ini temizle
  static Future<void> invalidateUser(String userId) async {
    try {
      await _profileBox?.delete(userId);
      await _userBox?.delete(userId);
      await _statsBox?.delete(userId);
      AppLogger.database.info('Cache invalidated: $userId');
    } catch (e) {
      AppLogger.database.error('Cache invalidation hatası', e);
    }
  }

  /// Tüm cache'i temizle
  static Future<void> clearAll() async {
    try {
      await _profileBox?.clear();
      await _userBox?.clear();
      await _statsBox?.clear();
      AppLogger.database.success('Tüm cache temizlendi');
    } catch (e) {
      AppLogger.database.error('Cache temizleme hatası', e);
    }
  }

  /// Expired cache'leri temizle
  static Future<void> cleanupExpired() async {
    try {
      int cleaned = 0;

      // Profile cache cleanup
      for (final key in _profileBox?.keys ?? []) {
        final cacheData = _profileBox?.get(key);
        if (cacheData != null) {
          final timestamp = cacheData['timestamp'] as int;
          final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (cacheAge > cacheTTL.inMilliseconds) {
            await _profileBox?.delete(key);
            cleaned++;
          }
        }
      }

      // User cache cleanup
      for (final key in _userBox?.keys ?? []) {
        final cacheData = _userBox?.get(key);
        if (cacheData != null) {
          final timestamp = cacheData['timestamp'] as int;
          final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (cacheAge > cacheTTL.inMilliseconds) {
            await _userBox?.delete(key);
            cleaned++;
          }
        }
      }

      // Stats cache cleanup
      for (final key in _statsBox?.keys ?? []) {
        final cacheData = _statsBox?.get(key);
        if (cacheData != null) {
          final timestamp = cacheData['timestamp'] as int;
          final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (cacheAge > cacheTTL.inMilliseconds) {
            await _statsBox?.delete(key);
            cleaned++;
          }
        }
      }

      if (cleaned > 0) {
        AppLogger.database.success('$cleaned expired cache temizlendi');
      }
    } catch (e) {
      AppLogger.database.error('Expired cache cleanup hatası', e);
    }
  }

  /// Cache istatistikleri
  static Map<String, int> getStats() {
    return {
      'profile_count': _profileBox?.length ?? 0,
      'user_count': _userBox?.length ?? 0,
      'stats_count': _statsBox?.length ?? 0,
    };
  }

  /// Dispose
  static Future<void> dispose() async {
    await _profileBox?.close();
    await _userBox?.close();
    await _statsBox?.close();
  }
}
