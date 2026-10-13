import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui';
import 'voice_radar_screen.dart';

class HomeScreenStitch extends StatefulWidget {
  const HomeScreenStitch({super.key});

  @override
  State<HomeScreenStitch> createState() => _HomeScreenStitchState();
}

class _HomeScreenStitchState extends State<HomeScreenStitch> with TickerProviderStateMixin {
  bool _ghostModeActive = true;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(hours: 23, minutes: 59, seconds: 59);

  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _soundBarController;
  late List<Animation<double>> _soundBarAnimations;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _pulseController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    _pulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _soundBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _soundBarAnimations = List.generate(4, (index) {
      final intervals = [
        [0.0, 0.5],
        [0.15, 0.65],
        [0.3, 0.8],
        [0.45, 0.95],
      ];
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _soundBarController,
          curve: Interval(
            intervals[index][0],
            intervals[index][1],
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController1.dispose();
    _pulseController2.dispose();
    _soundBarController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
          } else {
            _remainingTime = const Duration(hours: 23, minutes: 59, seconds: 59);
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  void _handleVoiceRadarTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceRadarScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
                  child: Column(
                    children: [
                      _buildVoiceMatchHero(),
                      const SizedBox(height: 20),
                      _buildGhostChatCard(),
                      const SizedBox(height: 20),
                      _buildInvisibleBrowsing(),
                      const SizedBox(height: 20),
                      _buildLivePartyRooms(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
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
      leading: null,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController1,
                builder: (context, child) {
                  return Opacity(
                    opacity: 1 - _pulseController1.value,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF06B6D4).withOpacity(0.2),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A),
                  border: Border.all(color: const Color(0xFF1E293B), width: 1),
                ),
                child: const Icon(Icons.bolt, color: Color(0xFF06B6D4), size: 18),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HAYALET MODU',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF06B6D4),
                    letterSpacing: 1.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Canlı Eşleşme',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.visibility_off, color: Color(0xFF06B6D4), size: 17),
              const SizedBox(width: 6),
              Text(
                'Aktif',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFF0F172A), size: 17),
              const SizedBox(width: 6),
              Text(
                '1.480',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(Icons.person, color: Color(0xFF475569), size: 19),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildVoiceMatchHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD9E0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF4D6D),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'HIZLI SESLİ EŞLEŞME',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF4D6D),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Konuşarak Tanış',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Kaydırmayı bırak. Dokun ve 10 saniyede aynı frekansta olduğun biriyle sesli sohbete bağlan.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Main radar button
          SizedBox(
            width: 288,
            height: 288,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Animated pulse rings
                AnimatedBuilder(
                  animation: _pulseController1,
                  builder: (context, child) {
                    final opacity = (1.0 - _pulseController1.value) * 0.35;
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 288,
                        height: 288,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF9A62).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withOpacity(0.3),
                      width: 1,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF06B6D4).withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                Container(
                  width: 224,
                  height: 224,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF4D6D).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                ),

                Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCDB2).withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                ),

                // User cards
                Positioned(
                  top: -4,
                  right: 8,
                  child: _buildUserCard('Selin, 24', 'Sesli', const Color(0xFFFF4D6D), 'assets/images/avatars/avatar_woman_1.jpg'),
                ),

                Positioned(
                  bottom: -4,
                  left: 4,
                  child: _buildUserCard('Mert, 26', 'Hazır', const Color(0xFFFF5E00), 'assets/images/avatars/avatar_man_1.jpg'),
                ),

                // Main button
                GestureDetector(
                  onTap: _handleVoiceRadarTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          const Color(0xFFFFF3EB).withOpacity(0.5),
                          Colors.white.withOpacity(0.9),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5E00).withOpacity(0.22),
                          blurRadius: 48,
                          offset: const Offset(0, 22),
                          spreadRadius: -10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                          spreadRadius: -6,
                        ),
                      ],
                      border: Border.all(color: Colors.white),
                    ),
                    child: Container(
                      width: 176,
                      height: 176,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            const Color(0xFFFFF3EB).withOpacity(0.3),
                            const Color(0xFFFFF0F4).withOpacity(0.4),
                          ],
                        ),
                        border: Border.all(color: Colors.white),
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF5E00).withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFCDB2).withOpacity(0.8),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D), Color(0xFFFF3366)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5E00).withOpacity(0.38),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF06B6D4),
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'BAĞLAN',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: 2.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dokun & Konuş',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF5E00),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                final heights = [8.0, 16.0, 10.0, 14.0, 8.0];
                                return AnimatedBuilder(
                                  animation: _soundBarAnimations[index % 4],
                                  builder: (context, child) {
                                    return Container(
                                      width: 4,
                                      height: heights[index] * _soundBarAnimations[index % 4].value,
                                      margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                                      decoration: BoxDecoration(
                                        color: index.isEven ? const Color(0xFFFF5E00) : const Color(0xFFFF4D6D),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq, color: Color(0xFFFF5E00), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Şu an sırada bekleyen: ',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '2.190 kişi',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF4D6D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(String name, String status, Color color, String imagePath) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 10, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.7), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: color.withOpacity(0.1),
                  child: Icon(Icons.person, color: color, size: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGhostChatCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Color(0xFFFF4D6D), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '24 SAAT SONRA YOK OLUR',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD9E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF4D6D),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_remainingTime),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF4D6D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'Hayalet Yazılı Eşleşme',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Fotoğrafsız, tamamen anonim başla. İki taraf da onay verene kadar sohbet tamamen gizli kalır ve süre bitince buharlaşır.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD9BF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.no_photography, color: Color(0xFFFF5E00), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ekran Kaydı Engelli',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD9E0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep, color: Color(0xFFFF4D6D), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '24s Otomatik İmha',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFF4D6D)],
                      ),
                    ),
                    child: const Icon(Icons.forum, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Anonim Yazılı Eşleşme',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.bolt, color: Color(0xFFFFA726), size: 14),
                          ],
                        ),
                        Text(
                          'Uçtan uca şifreli · 24s sonra imha',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '980 aktif',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF06B6D4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFF64748B), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvisibleBrowsing() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.theater_comedy, color: Color(0xFF06B6D4), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Görünmez Gezinme',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Aktif',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Profilin gizli, ses net',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _ghostModeActive = !_ghostModeActive;
              });
            },
            child: Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: _ghostModeActive ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(2),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _ghostModeActive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _ghostModeActive ? const Color(0xFF06B6D4) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _ghostModeActive ? Icons.visibility_off : Icons.lock_open,
                    size: 14,
                    color: _ghostModeActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePartyRooms() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration, color: Color(0xFFFF5E00), size: 22),
                const SizedBox(width: 6),
                Text(
                  'Canlı Parti Odaları',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Tümünü Gör (18)',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF5E00),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD9E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.headphones, color: Color(0xFFFF4D6D), size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'DJ YAYINI',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF4D6D),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(4, (index) {
                      final heights = [8.0, 14.0, 10.0, 14.0];
                      return AnimatedBuilder(
                        animation: _soundBarAnimations[index],
                        builder: (context, child) {
                          return Container(
                            width: 4,
                            height: heights[index] * _soundBarAnimations[index].value,
                            margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: index.isEven ? const Color(0xFFFF4D6D) : const Color(0xFFFF5E00),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'DJ Flört Lounge & Sohbet',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),

              Text(
                'Deep house ritimleriyle mikrofon açık, serbest sohbet.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 120,
                    height: 36,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: _buildAvatar('assets/images/avatars/dj_woman.jpg'),
                        ),
                        Positioned(
                          left: 28,
                          child: _buildAvatar('assets/images/avatars/man_laughing.jpg'),
                        ),
                        Positioned(
                          left: 56,
                          child: _buildAvatar('assets/images/avatars/artist_woman.jpg'),
                        ),
                        Positioned(
                          left: 84,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFF3EB),
                              border: Border.all(color: const Color(0xFFFFD9BF), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '+5',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF5E00),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group, color: Color(0xFF64748B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '142',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Color(0xFFFF4D6D), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '890',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFF5E00),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.headphones, color: Color(0xFFFF5E00), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Odaya Katıl',
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'CANLI',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFFA726),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, color: Color(0xFFFFA726), size: 13),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD9E0)),
                    ),
                    child: const Icon(Icons.celebration, color: Color(0xFFFF4D6D), size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String imagePath) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFE2E8F0),
            child: const Icon(Icons.person, color: Color(0xFF94A3B8), size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
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
                    _buildNavItem(Icons.explore, 'Keşfet', false),
                    _buildNavItem(Icons.graphic_eq, 'Odalar', true),
                    _buildNavItem(Icons.chat_bubble, 'Mesajlar', false, hasNotif: true),
                    _buildNavItem(Icons.person, 'Profil', false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {bool hasNotif = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? const Color(0xFFFF4D6D) : const Color(0xFF94A3B8),
            ),
            if (hasNotif)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF4D6D),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFFFF4D6D) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
