import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Profil analytics ve istatistik servisi
class ProfileAnalyticsService {
  static final _supabase = SupabaseConfig.client;

  /// Profil görüntüleme sayısını artır
  static Future<void> trackProfileView({
    required String viewerId,
    required String profileOwnerId,
  }) async {
    if (viewerId == profileOwnerId) return; // Kendi profilini sayma

    try {
      // Profile view kaydet
      await _supabase.from('profile_views').insert({
        'viewer_id': viewerId,
        'profile_owner_id': profileOwnerId,
        'viewed_at': DateTime.now().toIso8601String(),
      });

      // Stats'ı güncelle
      await _supabase.rpc('increment_profile_views', params: {
        'user_id': profileOwnerId,
      });

      AppLogger.database.info('Profil görüntüleme kaydedildi: $profileOwnerId');
    } catch (e) {
      AppLogger.database.error('Profil view tracking hatası', e);
    }
  }

  /// Profil ziyaretçilerini getir
  static Future<List<ProfileVisitor>> getRecentVisitors({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('profile_views')
          .select('viewer_id, viewed_at, users!viewer_id(username, avatar_url)')
          .eq('profile_owner_id', userId)
          .order('viewed_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => ProfileVisitor.fromJson(json)).toList();
    } catch (e) {
      AppLogger.database.error('Ziyaretçi listesi hatası', e);
      return [];
    }
  }

  /// Profil etkileşim skoru hesapla
  static Future<ProfileEngagementScore> calculateEngagementScore(String userId) async {
    try {
      final response = await _supabase.rpc('calculate_profile_engagement', params: {
        'user_id': userId,
      });

      return ProfileEngagementScore.fromJson(response);
    } catch (e) {
      AppLogger.database.error('Engagement score hesaplama hatası', e);
      return ProfileEngagementScore.empty();
    }
  }

  /// En çok görüntülenen profiller (leaderboard)
  static Future<List<ProfileRanking>> getTopProfiles({
    String period = 'week', // day, week, month, all
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.rpc('get_top_profiles', params: {
        'period': period,
        'limit_count': limit,
      });

      return (response as List).map((json) => ProfileRanking.fromJson(json)).toList();
    } catch (e) {
      AppLogger.database.error('Top profiles hatası', e);
      return [];
    }
  }

  /// Profil etkileşim geçmişi (timeline)
  static Future<List<ProfileActivity>> getActivityTimeline({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('profile_activities')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => ProfileActivity.fromJson(json)).toList();
    } catch (e) {
      AppLogger.database.error('Activity timeline hatası', e);
      return [];
    }
  }

  /// Profil güncelleme kaydı
  static Future<void> logProfileUpdate({
    required String userId,
    required String updateType, // avatar, bio, voice, gallery, tags
    String? details,
  }) async {
    try {
      await _supabase.from('profile_activities').insert({
        'user_id': userId,
        'activity_type': 'profile_update',
        'update_type': updateType,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.database.info('Profil güncelleme kaydedildi: $updateType');
    } catch (e) {
      AppLogger.database.error('Profile update log hatası', e);
    }
  }

  /// Profil benzerlik analizi
  static Future<List<SimilarProfile>> findSimilarProfiles({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.rpc('find_similar_profiles', params: {
        'target_user_id': userId,
        'limit_count': limit,
      });

      return (response as List).map((json) => SimilarProfile.fromJson(json)).toList();
    } catch (e) {
      AppLogger.database.error('Similar profiles hatası', e);
      return [];
    }
  }

  /// Haftalık profil istatistikleri
  static Future<WeeklyProfileStats> getWeeklyStats(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Son 7 günün view sayısı
      final viewsResponse = await _supabase
          .from('profile_views')
          .select('id')
          .eq('profile_owner_id', userId)
          .gte('viewed_at', weekAgo.toIso8601String());

      // Son 7 günün unique visitor sayısı
      final uniqueViewsResponse = await _supabase
          .from('profile_views')
          .select('viewer_id')
          .eq('profile_owner_id', userId)
          .gte('viewed_at', weekAgo.toIso8601String());

      final uniqueViewers = (uniqueViewsResponse as List)
          .map((e) => e['viewer_id'])
          .toSet()
          .length;

      // Profil completion değişimi
      final activitiesResponse = await _supabase
          .from('profile_activities')
          .select()
          .eq('user_id', userId)
          .gte('created_at', weekAgo.toIso8601String());

      return WeeklyProfileStats(
        totalViews: (viewsResponse as List).length,
        uniqueVisitors: uniqueViewers,
        profileUpdates: (activitiesResponse as List).length,
        weekStart: weekAgo,
        weekEnd: now,
      );
    } catch (e) {
      AppLogger.database.error('Weekly stats hatası', e);
      return WeeklyProfileStats.empty();
    }
  }
}

/// Profil ziyaretçi modeli
class ProfileVisitor {
  final String viewerId;
  final String username;
  final String? avatarUrl;
  final DateTime viewedAt;

  ProfileVisitor({
    required this.viewerId,
    required this.username,
    this.avatarUrl,
    required this.viewedAt,
  });

  factory ProfileVisitor.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;
    return ProfileVisitor(
      viewerId: json['viewer_id'] as String,
      username: userData?['username'] as String? ?? 'Unknown',
      avatarUrl: userData?['avatar_url'] as String?,
      viewedAt: DateTime.parse(json['viewed_at']),
    );
  }
}

/// Profil etkileşim skoru
class ProfileEngagementScore {
  final int totalScore;
  final int viewScore;
  final int likeScore;
  final int matchScore;
  final int completionScore;
  final String tier; // bronze, silver, gold, platinum, diamond

  ProfileEngagementScore({
    required this.totalScore,
    required this.viewScore,
    required this.likeScore,
    required this.matchScore,
    required this.completionScore,
    required this.tier,
  });

  factory ProfileEngagementScore.fromJson(Map<String, dynamic> json) {
    return ProfileEngagementScore(
      totalScore: json['total_score'] as int? ?? 0,
      viewScore: json['view_score'] as int? ?? 0,
      likeScore: json['like_score'] as int? ?? 0,
      matchScore: json['match_score'] as int? ?? 0,
      completionScore: json['completion_score'] as int? ?? 0,
      tier: json['tier'] as String? ?? 'bronze',
    );
  }

  factory ProfileEngagementScore.empty() {
    return ProfileEngagementScore(
      totalScore: 0,
      viewScore: 0,
      likeScore: 0,
      matchScore: 0,
      completionScore: 0,
      tier: 'bronze',
    );
  }
}

/// Profil sıralaması
class ProfileRanking {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int viewCount;
  final int rank;

  ProfileRanking({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.viewCount,
    required this.rank,
  });

  factory ProfileRanking.fromJson(Map<String, dynamic> json) {
    return ProfileRanking(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
    );
  }
}

/// Profil aktivite kaydı
class ProfileActivity {
  final String activityType;
  final String? updateType;
  final String? details;
  final DateTime createdAt;

  ProfileActivity({
    required this.activityType,
    this.updateType,
    this.details,
    required this.createdAt,
  });

  factory ProfileActivity.fromJson(Map<String, dynamic> json) {
    return ProfileActivity(
      activityType: json['activity_type'] as String,
      updateType: json['update_type'] as String?,
      details: json['details'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayText {
    switch (activityType) {
      case 'profile_update':
        switch (updateType) {
          case 'avatar':
            return 'Profil fotoğrafını güncelledi';
          case 'bio':
            return 'Biyografisini güncelledi';
          case 'voice':
            return 'Sesli tanıtım ekledi';
          case 'gallery':
            return 'Galeri fotoğraflarını güncelledi';
          case 'tags':
            return 'İlgi alanlarını güncelledi';
          default:
            return 'Profilini güncelledi';
        }
      default:
        return activityType;
    }
  }
}

/// Benzer profil
class SimilarProfile {
  final String userId;
  final String username;
  final String? avatarUrl;
  final double similarityScore;
  final List<String> commonTags;

  SimilarProfile({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.similarityScore,
    required this.commonTags,
  });

  factory SimilarProfile.fromJson(Map<String, dynamic> json) {
    return SimilarProfile(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      commonTags: json['common_tags'] != null
          ? List<String>.from(json['common_tags'])
          : [],
    );
  }
}

/// Haftalık istatistikler
class WeeklyProfileStats {
  final int totalViews;
  final int uniqueVisitors;
  final int profileUpdates;
  final DateTime weekStart;
  final DateTime weekEnd;

  WeeklyProfileStats({
    required this.totalViews,
    required this.uniqueVisitors,
    required this.profileUpdates,
    required this.weekStart,
    required this.weekEnd,
  });

  factory WeeklyProfileStats.empty() {
    final now = DateTime.now();
    return WeeklyProfileStats(
      totalViews: 0,
      uniqueVisitors: 0,
      profileUpdates: 0,
      weekStart: now.subtract(const Duration(days: 7)),
      weekEnd: now,
    );
  }

  double get averageViewsPerDay => totalViews / 7;

  String get summary {
    if (totalViews == 0) return 'Bu hafta henüz görüntülenme yok';
    return '$totalViews görüntülenme, $uniqueVisitors farklı kişi';
  }
}
