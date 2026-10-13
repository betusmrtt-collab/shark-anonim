import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'config/supabase_config.dart';
import 'utils/logger.dart';
import 'screens/create_profile_screen.dart';
import 'services/audio_player_service.dart';
import 'services/stats_service.dart';
import 'services/cache_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // null = current user

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _galleryImages = [];
  UserStats? _userStats;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == null;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      final targetUserId = widget.userId ?? currentUserId;

      if (targetUserId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Cache kontrol et
      final cachedData = CacheService.getCachedProfile(targetUserId);
      if (cachedData != null) {
        setState(() {
          _userData = cachedData;
          _isLoading = false;
        });
        AppLogger.ui.info('Profil cache\'den yüklendi');
      }

      // Profil verilerini al
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', targetUserId)
          .single();

      final galleryResponse = await SupabaseConfig.client
          .from('user_gallery')
          .select()
          .eq('user_id', targetUserId)
          .order('display_order');

      // Stats al
      _userStats = await StatsService.getUserStats(targetUserId);

      setState(() {
        _userData = userResponse;
        _galleryImages = List<Map<String, dynamic>>.from(galleryResponse);
        _isLoading = false;
      });

      // Cache'e kaydet
      await CacheService.cacheProfile(targetUserId, userResponse);

      // Kendi profilin değilse, profile view artır
      if (!_isCurrentUser && currentUserId != null) {
        StatsService.incrementProfileViews(targetUserId);
      }

      AppLogger.ui.success('Profil bilgileri yüklendi');
    } catch (e) {
      AppLogger.ui.error('Profil yüklenemedi', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil yüklenemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getGenderLabel(String? gender) {
    switch (gender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      case 'other':
        return 'Diğer';
      default:
        return 'Belirtilmedi';
    }
  }

  void _shareProfile() {
    final username = _userData['username'] ?? 'kullanıcı';
    Share.share(
      'Anonim\'de @$username profilini gör!\n\nhttps://anonim.app/profile/$username',
      subject: 'Profil Paylaş',
    );
  }

  void _openGalleryViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _GalleryViewerScreen(
          images: _galleryImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openAvatarViewer() {
    final avatarUrl = _userData['avatar_url'];
    if (avatarUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(imageUrl: avatarUrl),
      ),
    );
  }

  Future<void> _toggleGhostMode() async {
    if (_userStats == null) return;

    try {
      final newValue = !_userStats!.ghostMode;
      await StatsService.toggleGhostMode(_userData['id'], newValue);

      setState(() {
        _userStats = UserStats(
          userId: _userStats!.userId,
          firePoints: _userStats!.firePoints,
          matchCount: _userStats!.matchCount,
          profileViews: _userStats!.profileViews,
          likesReceived: _userStats!.likesReceived,
          ghostMode: newValue,
          profileVisibility: _userStats!.profileVisibility,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue ? 'Hayalet Mod Aktif' : 'Hayalet Mod Kapalı'),
          backgroundColor: const Color(0xFF00687A),
        ),
      );
    } catch (e) {
      AppLogger.ui.error('Ghost mode toggle hatası', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Profil yükleniyor...',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final username = _userData['username'] ?? 'kullanıcı';
    final avatarUrl = _userData['avatar_url'];
    final bio = _userData['bio'] ?? '';
    final tags = _userData['tags'] as List? ?? [];
    final gender = _userData['gender'];
    final voiceBioUrl = _userData['voice_bio_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                    child: Column(
                      children: [
                        _buildProfileHeader(username, avatarUrl, gender),
                        const SizedBox(height: 20),
                        _buildStatsRow(),
                        const SizedBox(height: 20),
                        if (bio.isNotEmpty) ...[
                          _buildBioCard(bio),
                          const SizedBox(height: 20),
                        ],
                        if (tags.isNotEmpty) ...[
                          _buildTagsCard(tags),
                          const SizedBox(height: 20),
                        ],
                        if (voiceBioUrl != null && voiceBioUrl.toString().isNotEmpty) ...[
                          _buildVoiceCard(voiceBioUrl),
                          const SizedBox(height: 20),
                        ],
                        if (_galleryImages.isNotEmpty) ...[
                          _buildGalleryCard(),
                          const SizedBox(height: 20),
                        ],
                        if (_isCurrentUser) _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 0,
      toolbarHeight: 64,
      backgroundColor: Colors.white.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF475569), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        'Profil',
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_isCurrentUser)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFFF5E00), size: 18),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateProfileScreen(),
                  ),
                ).then((_) => _loadUserProfile());
              },
            ),
          ),
        if (!_isCurrentUser)
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: _shareProfile,
          ),
      ],
    );
  }

  Widget _buildProfileHeader(String username, String? avatarUrl, String? gender) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: avatarUrl != null ? _openAvatarViewer : null,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF5E00),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                AppLogger.ui.error('Avatar yüklenemedi', error);
                                return Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF94A3B8),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                      ),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.verified, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '@$username',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF5E00),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getGenderLabel(gender),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.local_fire_department,
            _userStats?.firePointsFormatted ?? '0',
            'Fire Points',
            const Color(0xFFFF5E00),
            const Color(0xFFFFF3EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.favorite,
            '${_userStats?.matchCount ?? 0}',
            'Eşleşme',
            const Color(0xFFFF4D6D),
            const Color(0xFFFFF0F4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _isCurrentUser ? _toggleGhostMode : null,
            child: _buildStatCard(
              Icons.visibility_off,
              _userStats?.ghostMode == true ? 'Aktif' : 'Kapalı',
              'Hayalet Mod',
              const Color(0xFF06B6D4),
              const Color(0xFFDFF6FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(String bio) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.format_quote, color: Color(0xFF64748B), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Hakkımda',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            bio,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard(List tags) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tag, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'İlgi Alanları',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => _buildTag(tag.toString())).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    final colors = [
      [const Color(0xFFFF5E00), const Color(0xFFFFF3EB), const Color(0xFFFFD9BF)],
      [const Color(0xFF06B6D4), const Color(0xFFDFF6FF), const Color(0xFFB0E7F5)],
      [const Color(0xFFFF4D6D), const Color(0xFFFFF0F4), const Color(0xFFFFD9E0)],
      [const Color(0xFF8B5CF6), const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)],
    ];
    final colorSet = colors[tag.hashCode.abs() % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorSet[1],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorSet[2], width: 1),
      ),
      child: Text(
        tag,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorSet[0],
        ),
      ),
    );
  }

  Widget _buildVoiceCard(String voiceBioUrl) {
    return StreamBuilder<AudioPlayerState>(
      stream: AudioPlayerService.stateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.isPlaying == true &&
                         snapshot.data?.currentUrl == voiceBioUrl;
        final position = snapshot.data?.positionText ?? '0:00';
        final duration = snapshot.data?.durationText ?? '0:00';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E00).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    if (isPlaying) {
                      await AudioPlayerService.pause();
                    } else {
                      await AudioPlayerService.play(voiceBioUrl);
                    }
                  } catch (e) {
                    AppLogger.ui.error('Ses oynatma hatası', e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ses oynatılamadı')),
                    );
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesli Tanıtım',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPlaying ? 'Oynatılıyor...' : 'Sesimi dinle ve beni tanı',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  isPlaying ? position : duration,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Galeri',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB0E7F5), width: 1),
                ),
                child: Text(
                  '${_galleryImages.length} Fotoğraf',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF06B6D4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _galleryImages.length,
            itemBuilder: (context, index) {
              final imageUrl = _galleryImages[index]['image_url'];
              return GestureDetector(
                onTap: () => _openGalleryViewer(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      AppLogger.ui.error('Galeri resmi yüklenemedi', error);
                      return Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Color(0xFF94A3B8),
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionItem(
            icon: Icons.lock,
            label: 'Gizlilik Ayarları',
            color: const Color(0xFF06B6D4),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yakında eklenecek')),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildActionItem(
            icon: Icons.share,
            label: 'Profili Paylaş',
            color: const Color(0xFF8B5CF6),
            onTap: _shareProfile,
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildActionItem(
            icon: Icons.help_outline,
            label: 'Yardım & Destek',
            color: const Color(0xFF64748B),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yakında eklenecek')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF94A3B8), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.8), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(icon: Icons.explore, label: 'Keşfet', isActive: false),
                  _buildNavItem(icon: Icons.graphic_eq, label: 'Odalar', isActive: false),
                  _buildNavItem(icon: Icons.chat_bubble, label: 'Mesajlar', isActive: false),
                  _buildNavItem(icon: Icons.person, label: 'Profil', isActive: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isActive}) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pop(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? const Color(0xFFFF4D6D) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFFFF4D6D) : const Color(0xFF94A3B8),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Gallery viewer screen
class _GalleryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  const _GalleryViewerScreen({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<_GalleryViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final imageUrl = widget.images[index]['image_url'];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            itemCount: widget.images.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Single image viewer
class _ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const _ImageViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
