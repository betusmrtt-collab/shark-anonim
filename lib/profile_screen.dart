import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'config/supabase_config.dart';
import 'utils/logger.dart';
import 'screens/create_profile_screen.dart';
import 'services/audio_player_service.dart';
import 'services/stats_service.dart';
import 'services/user_service.dart';
import 'services/profile_analytics_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  UserProfile? _userProfile;
  UserStats? _userStats;
  ProfileCompletion? _profileCompletion;
  bool _isCurrentUser = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _statsController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _statsAnimations;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == null;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Staggered animations for stats cards - initialize first
    _statsAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _statsController,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });

    // Load profile after a small delay to ensure animations are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      final targetUserId = widget.userId ?? currentUserId;

      if (targetUserId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Load profile
      final profile = await UserService.getUserProfile(targetUserId);
      if (profile == null) throw Exception('Profil bulunamadı');

      // Load stats
      final stats = await StatsService.getUserStats(targetUserId);

      // Calculate completion
      final completion = UserService.calculateCompletion(profile);

      // Track view if not current user
      if (!_isCurrentUser && currentUserId != null) {
        ProfileAnalyticsService.trackProfileView(
          viewerId: currentUserId,
          profileOwnerId: targetUserId,
        );
      }

      setState(() {
        _userProfile = profile;
        _userStats = stats;
        _profileCompletion = completion;
        _isLoading = false;
      });

      // Debug log
      AppLogger.ui.info('Profile loaded - Tags: ${profile.tags.length} items: ${profile.tags}');

      // Start animations
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _statsController.forward();
        }
      }

      AppLogger.ui.success('Profil yüklendi: ${profile.username}');
    } catch (e) {
      AppLogger.ui.error('Profil yüklenemedi', e);
      setState(() => _isLoading = false);

      // Reset animations to prevent opacity errors
      if (mounted) {
        _fadeController.reset();
        _slideController.reset();
        _statsController.reset();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil yüklenemedi: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF4D6D),
          ),
        );
      }
    }
  }

  void _shareProfile() {
    HapticFeedback.mediumImpact();
    final username = _userProfile?.username ?? 'kullanıcı';
    Share.share(
      'Anonim\'de @$username profilini gör!\n\nhttps://anonim.app/profile/$username',
      subject: 'Profil Paylaş',
    );
  }

  void _openGalleryViewer(int initialIndex) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _GalleryViewerScreen(
          images: _userProfile!.galleryImages,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _openAvatarViewer() {
    HapticFeedback.lightImpact();
    final avatarUrl = _userProfile?.avatarUrl;
    if (avatarUrl == null) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _ImageViewerScreen(imageUrl: avatarUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
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
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.lerp(const Color(0xFFFF5E00), const Color(0xFFFF4D6D), _pulseController.value)!,
                            const Color(0xFFFF4D6D),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E00).withOpacity(0.4 + (_pulseController.value * 0.2)),
                            blurRadius: 24 + (_pulseController.value * 12),
                            spreadRadius: 2,
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
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Profil yükleniyor...',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFF64748B)),
              const SizedBox(height: 16),
              Text(
                'Profil yüklenemedi',
                style: GoogleFonts.dmSans(fontSize: 16, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        color: const Color(0xFFFF5E00),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 20),
                        if (_isCurrentUser && _profileCompletion != null && _profileCompletion!.percentage >= 0) ...[
                          _buildCompletionCard(),
                          const SizedBox(height: 20),
                        ],
                        _buildStatsRow(),
                        const SizedBox(height: 20),
                        if (_userProfile!.bio != null && _userProfile!.bio!.isNotEmpty) ...[
                          _buildBioCard(),
                          const SizedBox(height: 20),
                        ],
                        // *** TAGS HER ZAMAN GÖSTER (DEBUG) ***
                        _buildTagsCard(),
                        const SizedBox(height: 20),
                        if (_userProfile!.voiceBioUrl != null && _userProfile!.voiceBioUrl!.isNotEmpty) ...[
                          _buildVoiceCard(),
                          const SizedBox(height: 20),
                        ],
                        if (_userProfile!.galleryImages.isNotEmpty) ...[
                          _buildGalleryCard(),
                          const SizedBox(height: 20),
                        ],
                        if (_isCurrentUser) _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 0,
      toolbarHeight: 68,
      backgroundColor: Colors.white.withOpacity(0),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85),
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
              ),
            ),
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 14, bottom: 14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back, color: Color(0xFF475569), size: 20),
            ),
          ),
        ),
      ),
      title: Text(
        'Profil',
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.4,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_isCurrentUser)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 14, bottom: 14),
            child: Hero(
              tag: 'edit_profile_button',
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateProfileScreen()),
                      ).then((_) => _loadUserProfile());
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.edit, color: Color(0xFFFF5E00), size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!_isCurrentUser)
          IconButton(
            icon: const Icon(Icons.share, size: 20, color: Color(0xFF475569)),
            onPressed: _shareProfile,
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Material(
      color: Colors.transparent,
      child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFFAFAFA),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: _userProfile!.avatarUrl != null ? _openAvatarViewer : null,
                child: Hero(
                  tag: 'avatar_${_userProfile!.id}',
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(const Color(0xFFFF5E00), const Color(0xFFFF4D6D), _pulseController.value * 0.3)!,
                              const Color(0xFFFF4D6D),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5E00).withOpacity(0.3 + (_pulseController.value * 0.1)),
                              blurRadius: 24 + (_pulseController.value * 8),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipOval(
                            child: _userProfile!.avatarUrl != null && _userProfile!.avatarUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _userProfile!.avatarUrl!,
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
                                    errorWidget: (context, url, error) => Container(
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(
                                        Icons.person,
                                        size: 56,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(
                                      Icons.person,
                                      size: 56,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '@${_userProfile!.username}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.08),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color.lerp(const Color(0xFF06B6D4), const Color(0xFF0EA5E9), _pulseController.value)!,
                                const Color(0xFF0EA5E9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.verified, color: Colors.white, size: 14),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF1F5F9).withOpacity(0.8),
                      const Color(0xFFE2E8F0).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E00).withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _getGenderLabel(_userProfile!.gender),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildCompletionCard() {
    if (_profileCompletion == null) return const SizedBox.shrink();
    final completion = _profileCompletion!;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: completion.percentage / 100),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F172A),
                const Color(0xFF1E293B),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E00).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil Tamamlanması',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        completion.motivationMessage,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${(value * 100).round()}%',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5E00).withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!completion.isComplete) ...[
                const SizedBox(height: 14),
                Text(
                  completion.nextStepMessage,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    // Animasyon listesi hazır değilse basit versiyon göster
    if (_statsAnimations.length < 3) {
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
          const SizedBox(width: 14),
          Expanded(
            child: _buildStatCard(
              Icons.favorite,
              '${_userStats?.matchCount ?? 0}',
              'Eşleşme',
              const Color(0xFFFF4D6D),
              const Color(0xFFF0F4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildStatCard(
              Icons.visibility,
              '${_userStats?.profileViews ?? 0}',
              'Görüntülenme',
              const Color(0xFF06B6D4),
              const Color(0xFFDFF6FF),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _statsAnimations[0],
            builder: (context, child) {
              final value = _statsAnimations[0].value.clamp(0.0, 1.0);
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: _buildStatCard(
                    Icons.local_fire_department,
                    _userStats?.firePointsFormatted ?? '0',
                    'Fire Points',
                    const Color(0xFFFF5E00),
                    const Color(0xFFFFF3EB),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedBuilder(
            animation: _statsAnimations[1],
            builder: (context, child) {
              final value = _statsAnimations[1].value.clamp(0.0, 1.0);
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: _buildStatCard(
                    Icons.favorite,
                    '${_userStats?.matchCount ?? 0}',
                    'Eşleşme',
                    const Color(0xFFFF4D6D),
                    const Color(0xFFFFF0F4),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedBuilder(
            animation: _statsAnimations[2],
            builder: (context, child) {
              final value = _statsAnimations[2].value.clamp(0.0, 1.0);
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: _buildStatCard(
                    Icons.visibility,
                    '${_userStats?.profileViews ?? 0}',
                    'Görüntülenme',
                    const Color(0xFF06B6D4),
                    const Color(0xFFDFF6FF),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
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

  Widget _buildBioCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF1F5F9),
                      const Color(0xFFE2E8F0).withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.format_quote, color: Color(0xFF64748B), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Hakkımda',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile!.bio!,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.7,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.tag, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'İlgi Alanları',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _userProfile!.tags.map((tag) => _buildTag(tag)).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: colorSet[1],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorSet[2], width: 1.5),
      ),
      child: Text(
        tag,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colorSet[0],
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildVoiceCard() {
    return StreamBuilder<AudioPlayerState>(
      stream: AudioPlayerService.stateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.isPlaying == true &&
            snapshot.data?.currentUrl == _userProfile!.voiceBioUrl;
        final position = snapshot.data?.positionText ?? '0:00';
        final duration = snapshot.data?.durationText ?? '0:00';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E00).withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    if (isPlaying) {
                      await AudioPlayerService.pause();
                    } else {
                      await AudioPlayerService.play(_userProfile!.voiceBioUrl!);
                    }
                  } catch (e) {
                    AppLogger.ui.error('Ses oynatma hatası', e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ses oynatılamadı')),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPlaying
                          ? [const Color(0xFFFF4D6D), const Color(0xFFFF5E00)]
                          : [const Color(0xFFFF5E00), const Color(0xFFFF4D6D)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withOpacity(isPlaying ? 0.6 : 0.4),
                        blurRadius: isPlaying ? 16 : 12,
                        spreadRadius: isPlaying ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesli Tanıtım',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  isPlaying ? position : duration,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Galeri',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB0E7F5), width: 1),
                ),
                child: Text(
                  '${_userProfile!.galleryImages.length} Fotoğraf',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF06B6D4),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _userProfile!.galleryImages.length,
            itemBuilder: (context, index) {
              final image = _userProfile!.galleryImages[index];
              return Hero(
                tag: 'gallery_${_userProfile!.id}_$index',
                child: GestureDetector(
                  onTap: () => _openGalleryViewer(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: image.imageUrl,
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
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Color(0xFF94A3B8),
                          size: 32,
                        ),
                      ),
                    ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionItem(
            icon: Icons.analytics_outlined,
            label: 'Profil İstatistikleri',
            color: const Color(0xFF06B6D4),
            onTap: () {
              HapticFeedback.lightImpact();
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
            icon: Icons.settings,
            label: 'Gizlilik Ayarları',
            color: const Color(0xFF64748B),
            onTap: () {
              HapticFeedback.lightImpact();
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: const Color(0xFF94A3B8), size: 16),
            ],
          ),
        ),
      ),
    );
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
}

// Gallery viewer
class _GalleryViewerScreen extends StatefulWidget {
  final List<GalleryImage> images;
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
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(widget.images[index].imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: 'gallery_image_$index'),
              );
            },
            itemCount: widget.images.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
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
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
