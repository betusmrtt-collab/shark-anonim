import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';
import 'cache_service.dart';

/// Kullanıcı profil yönetimi servisi
class UserService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Tam profil bilgilerini al (cache destekli)
  static Future<UserProfile?> getUserProfile(String userId, {bool forceRefresh = false}) async {
    try {
      // Cache kontrol
      if (!forceRefresh) {
        final cached = CacheService.getCachedProfile(userId);
        if (cached != null) {
          AppLogger.database.info('Profil cache\'den yüklendi: $userId');
          return UserProfile.fromJson(cached);
        }
      }

      // Database'den çek
      final response = await _supabase
          .from('users')
          .select('*, user_gallery(*)')
          .eq('id', userId)
          .single();

      final profile = UserProfile.fromJson(Map<String, dynamic>.from(response));

      // Cache'e kaydet
      await CacheService.cacheProfile(userId, response);

      AppLogger.database.success('Profil yüklendi: ${profile.username}');
      return profile;
    } catch (e) {
      AppLogger.database.error('Profil yükleme hatası', e);
      return null;
    }
  }

  /// Profil güncelle
  static Future<bool> updateProfile({
    required String userId,
    String? bio,
    String? avatarUrl,
    String? voiceBioUrl,
    String? gender,
    List<String>? tags,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (voiceBioUrl != null) updates['voice_bio_url'] = voiceBioUrl;
      if (gender != null) updates['gender'] = gender;
      if (tags != null) updates['tags'] = tags;

      await _supabase.from('users').update(updates).eq('id', userId);

      // Cache'i temizle
      await CacheService.invalidateUser(userId);

      AppLogger.database.success('Profil güncellendi: $userId');
      return true;
    } catch (e) {
      AppLogger.database.error('Profil güncelleme hatası', e);
      return false;
    }
  }

  /// Galeri güncelle
  static Future<bool> updateGallery({
    required String userId,
    required List<String> imageUrls,
  }) async {
    try {
      // Mevcut galerileri sil
      await _supabase.from('user_gallery').delete().eq('user_id', userId);

      // Yeni galerileri ekle
      if (imageUrls.isNotEmpty) {
        final insertData = imageUrls.asMap().entries.map((entry) {
          return {
            'user_id': userId,
            'image_url': entry.value,
            'display_order': entry.key,
          };
        }).toList();

        await _supabase.from('user_gallery').insert(insertData);
      }

      // Cache'i temizle
      await CacheService.invalidateUser(userId);

      AppLogger.database.success('Galeri güncellendi: ${imageUrls.length} fotoğraf');
      return true;
    } catch (e) {
      AppLogger.database.error('Galeri güncelleme hatası', e);
      return false;
    }
  }

  /// Profil tamamlanma yüzdesini hesapla
  static ProfileCompletion calculateCompletion(UserProfile profile) {
    int completedSteps = 0;
    const int totalSteps = 6;
    final List<String> missingSteps = [];

    // 1. Avatar
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      completedSteps++;
    } else {
      missingSteps.add('Profil fotoğrafı ekle');
    }

    // 2. Bio
    if (profile.bio != null && profile.bio!.length >= 20) {
      completedSteps++;
    } else {
      missingSteps.add('Anlamlı bir biyografi yaz (min 20 karakter)');
    }

    // 3. Sesli bio
    if (profile.voiceBioUrl != null && profile.voiceBioUrl!.isNotEmpty) {
      completedSteps++;
    } else {
      missingSteps.add('Sesli tanıtım ekle');
    }

    // 4. Tags (min 3)
    if (profile.tags.length >= 3) {
      completedSteps++;
    } else {
      missingSteps.add('En az 3 ilgi alanı ekle');
    }

    // 5. Galeri (min 2)
    if (profile.galleryImages.length >= 2) {
      completedSteps++;
    } else {
      missingSteps.add('En az 2 galeri fotoğrafı ekle');
    }

    // 6. Gender
    if (profile.gender != null && profile.gender!.isNotEmpty) {
      completedSteps++;
    } else {
      missingSteps.add('Cinsiyet bilgisi ekle');
    }

    final percentage = (completedSteps / totalSteps * 100).round();

    return ProfileCompletion(
      percentage: percentage,
      completedSteps: completedSteps,
      totalSteps: totalSteps,
      missingSteps: missingSteps,
      isComplete: percentage == 100,
    );
  }

  /// Kullanıcı arama
  static Future<List<UserProfile>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .or('username.ilike.%$query%,bio.ilike.%$query%')
          .limit(limit);

      final profiles = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();

      AppLogger.database.success('${profiles.length} kullanıcı bulundu');
      return profiles;
    } catch (e) {
      AppLogger.database.error('Kullanıcı arama hatası', e);
      return [];
    }
  }

  /// Tag'e göre kullanıcı bul
  static Future<List<UserProfile>> getUsersByTag({
    required String tag,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .contains('tags', [tag])
          .limit(limit);

      final profiles = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();

      AppLogger.database.success('${profiles.length} kullanıcı bulundu (tag: $tag)');
      return profiles;
    } catch (e) {
      AppLogger.database.error('Tag arama hatası', e);
      return [];
    }
  }

  /// Online durumunu güncelle
  static Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _supabase.from('users').update({
        'last_seen': DateTime.now().toIso8601String(),
        'is_online': isOnline,
      }).eq('id', userId);
    } catch (e) {
      AppLogger.database.error('Online status güncelleme hatası', e);
    }
  }

  /// Kullanıcı engelle
  static Future<bool> blockUser(String userId, String targetUserId) async {
    try {
      await _supabase.from('blocked_users').insert({
        'user_id': userId,
        'blocked_user_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.database.success('Kullanıcı engellendi: $targetUserId');
      return true;
    } catch (e) {
      AppLogger.database.error('Engelleme hatası', e);
      return false;
    }
  }

  /// Kullanıcı engel kaldır
  static Future<bool> unblockUser(String userId, String targetUserId) async {
    try {
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('user_id', userId)
          .eq('blocked_user_id', targetUserId);

      AppLogger.database.success('Engel kaldırıldı: $targetUserId');
      return true;
    } catch (e) {
      AppLogger.database.error('Engel kaldırma hatası', e);
      return false;
    }
  }

  /// Engellenen kullanıcıları getir
  static Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final response = await _supabase
          .from('blocked_users')
          .select('blocked_user_id')
          .eq('user_id', userId);

      return (response as List)
          .map((e) => e['blocked_user_id'] as String)
          .toList();
    } catch (e) {
      AppLogger.database.error('Engellenen kullanıcılar getirme hatası', e);
      return [];
    }
  }
}

/// Kullanıcı profil modeli
class UserProfile {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String? voiceBioUrl;
  final String? gender;
  final List<String> tags;
  final List<GalleryImage> galleryImages;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    this.voiceBioUrl,
    this.gender,
    this.tags = const [],
    this.galleryImages = const [],
    this.createdAt,
    this.lastSeen,
    this.isOnline = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final List<GalleryImage> gallery = [];
    if (json['user_gallery'] != null) {
      gallery.addAll(
        (json['user_gallery'] as List).map((g) => GalleryImage.fromJson(Map<String, dynamic>.from(g))),
      );
    }

    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      voiceBioUrl: json['voice_bio_url'] as String?,
      gender: json['gender'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      galleryImages: gallery,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      isOnline: json['is_online'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'voice_bio_url': voiceBioUrl,
      'gender': gender,
      'tags': tags,
      'created_at': createdAt?.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
      'is_online': isOnline,
    };
  }
}

/// Galeri resmi modeli
class GalleryImage {
  final String imageUrl;
  final int displayOrder;

  GalleryImage({
    required this.imageUrl,
    required this.displayOrder,
  });

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      imageUrl: json['image_url'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}

/// Profil tamamlanma modeli
class ProfileCompletion {
  final int percentage;
  final int completedSteps;
  final int totalSteps;
  final List<String> missingSteps;
  final bool isComplete;

  ProfileCompletion({
    required this.percentage,
    required this.completedSteps,
    required this.totalSteps,
    required this.missingSteps,
    required this.isComplete,
  });

  String get motivationMessage {
    if (percentage == 100) return '🎉 Profilin mükemmel!';
    if (percentage >= 80) return '🔥 Neredeyse tamam!';
    if (percentage >= 50) return '💪 Yarıdan fazlasını tamamladın!';
    if (percentage >= 30) return '👍 İyi gidiyorsun!';
    return '🚀 Hadi başlayalım!';
  }

  String get nextStepMessage {
    if (missingSteps.isEmpty) return 'Tebrikler! Profilin tamam.';
    return 'Sonraki adım: ${missingSteps.first}';
  }
}
