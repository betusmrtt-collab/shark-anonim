import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Stats ve gamification servisi
class StatsService {
  static final _client = SupabaseConfig.client;

  /// Kullanıcının stats'ını al
  static Future<UserStats?> getUserStats(String userId) async {
    try {
      final response = await _client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Stats yoksa oluştur
        return await _createDefaultStats(userId);
      }

      return UserStats.fromJson(response);
    } catch (e) {
      AppLogger.database.error('Stats yükleme hatası', e);
      return null;
    }
  }

  /// Default stats oluştur
  static Future<UserStats> _createDefaultStats(String userId) async {
    try {
      final response = await _client.from('user_stats').insert({
        'user_id': userId,
        'fire_points': 0,
        'match_count': 0,
        'profile_views': 0,
        'likes_received': 0,
        'ghost_mode': false,
        'profile_visibility': 'public',
      }).select().single();

      AppLogger.database.success('Default stats oluşturuldu');
      return UserStats.fromJson(response);
    } catch (e) {
      AppLogger.database.error('Stats oluşturma hatası', e);
      rethrow;
    }
  }

  /// Fire points ekle
  static Future<void> addFirePoints(String userId, int points) async {
    try {
      final currentStats = await getUserStats(userId);
      if (currentStats == null) return;

      await _client.from('user_stats').update({
        'fire_points': currentStats.firePoints + points,
      }).eq('user_id', userId);

      AppLogger.database.success('Fire points eklendi: +$points');
    } catch (e) {
      AppLogger.database.error('Fire points ekleme hatası', e);
    }
  }

  /// Match count artır
  static Future<void> incrementMatchCount(String userId) async {
    try {
      final currentStats = await getUserStats(userId);
      if (currentStats == null) return;

      await _client.from('user_stats').update({
        'match_count': currentStats.matchCount + 1,
      }).eq('user_id', userId);

      AppLogger.database.success('Match count artırıldı');
    } catch (e) {
      AppLogger.database.error('Match count artırma hatası', e);
    }
  }

  /// Profile view artır
  static Future<void> incrementProfileViews(String userId) async {
    try {
      final currentStats = await getUserStats(userId);
      if (currentStats == null) return;

      await _client.from('user_stats').update({
        'profile_views': currentStats.profileViews + 1,
      }).eq('user_id', userId);

      AppLogger.database.debug('Profile view artırıldı');
    } catch (e) {
      AppLogger.database.error('Profile view artırma hatası', e);
    }
  }

  /// Ghost mode toggle
  static Future<void> toggleGhostMode(String userId, bool enabled) async {
    try {
      await _client.from('user_stats').update({
        'ghost_mode': enabled,
      }).eq('user_id', userId);

      AppLogger.database.success('Ghost mode: ${enabled ? 'AÇIK' : 'KAPALI'}');
    } catch (e) {
      AppLogger.database.error('Ghost mode toggle hatası', e);
      rethrow;
    }
  }

  /// Profile visibility değiştir
  static Future<void> updateProfileVisibility(String userId, ProfileVisibility visibility) async {
    try {
      await _client.from('user_stats').update({
        'profile_visibility': visibility.value,
      }).eq('user_id', userId);

      AppLogger.database.success('Profile visibility güncellendi: ${visibility.value}');
    } catch (e) {
      AppLogger.database.error('Profile visibility güncelleme hatası', e);
      rethrow;
    }
  }

  /// Leaderboard - en çok fire points'e sahip kullanıcılar
  static Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _client
          .from('user_stats')
          .select('user_id, fire_points, users!inner(username, avatar_url)')
          .order('fire_points', ascending: false)
          .limit(limit);

      return (response as List).map((item) => LeaderboardEntry.fromJson(item)).toList();
    } catch (e) {
      AppLogger.database.error('Leaderboard yükleme hatası', e);
      return [];
    }
  }

  /// Fire points hesaplama kuralları
  static int calculateProfileCompletionPoints(
    bool hasAvatar,
    bool hasBio,
    bool hasVoiceBio,
    int galleryCount,
    int tagCount,
  ) {
    int points = 0;

    if (hasAvatar) points += 10;
    if (hasBio) points += 15;
    if (hasVoiceBio) points += 25;
    points += galleryCount * 5; // Her galeri resmi 5 puan
    points += tagCount * 2; // Her tag 2 puan

    return points;
  }

  /// Profil tamamlanma yüzdesi
  static int calculateProfileCompletionPercentage(
    bool hasAvatar,
    bool hasBio,
    bool hasVoiceBio,
    int galleryCount,
    int tagCount,
  ) {
    int completed = 0;
    const int total = 5;

    if (hasAvatar) completed++;
    if (hasBio) completed++;
    if (hasVoiceBio) completed++;
    if (galleryCount >= 3) completed++; // En az 3 galeri resmi
    if (tagCount >= 3) completed++; // En az 3 tag

    return ((completed / total) * 100).round();
  }
}

/// User stats model
class UserStats {
  final String userId;
  final int firePoints;
  final int matchCount;
  final int profileViews;
  final int likesReceived;
  final bool ghostMode;
  final ProfileVisibility profileVisibility;

  UserStats({
    required this.userId,
    required this.firePoints,
    required this.matchCount,
    required this.profileViews,
    required this.likesReceived,
    required this.ghostMode,
    required this.profileVisibility,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] as String,
      firePoints: json['fire_points'] as int? ?? 0,
      matchCount: json['match_count'] as int? ?? 0,
      profileViews: json['profile_views'] as int? ?? 0,
      likesReceived: json['likes_received'] as int? ?? 0,
      ghostMode: json['ghost_mode'] as bool? ?? false,
      profileVisibility: ProfileVisibility.fromString(json['profile_visibility'] as String? ?? 'public'),
    );
  }

  String get firePointsFormatted {
    if (firePoints >= 1000) {
      return '${(firePoints / 1000).toStringAsFixed(1)}K';
    }
    return firePoints.toString();
  }
}

/// Profile visibility enum
enum ProfileVisibility {
  public('public'),
  private('private'),
  friends('friends');

  final String value;
  const ProfileVisibility(this.value);

  static ProfileVisibility fromString(String value) {
    return ProfileVisibility.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProfileVisibility.public,
    );
  }

  String get displayName {
    switch (this) {
      case ProfileVisibility.public:
        return 'Herkese Açık';
      case ProfileVisibility.private:
        return 'Gizli';
      case ProfileVisibility.friends:
        return 'Sadece Arkadaşlar';
    }
  }
}

/// Leaderboard entry
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int firePoints;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.firePoints,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>;
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      username: user['username'] as String,
      avatarUrl: user['avatar_url'] as String?,
      firePoints: json['fire_points'] as int? ?? 0,
    );
  }
}
