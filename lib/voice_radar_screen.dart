import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;

class VoiceRadarScreen extends StatefulWidget {
  const VoiceRadarScreen({super.key});

  @override
  State<VoiceRadarScreen> createState() => _VoiceRadarScreenState();
}

class _VoiceRadarScreenState extends State<VoiceRadarScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _pulseController3;
  late AnimationController _centerGlowController;
  late AnimationController _sonarController;
  late AnimationController _progressController;

  late List<AnimationController> _soundBarControllers;

  bool _isMuted = false;
  int _currentStateIndex = 0;
  Timer? _stateTimer;

  final List<Map<String, dynamic>> _searchStates = [
    {
      'title': 'Ses Frekansın Eşleştiriliyor...',
      'progress': 0.48,
      'freq': '432 Hz Harmoni'
    },
    {
      'title': 'Ortak İlgi Alanları Taranıyor...',
      'progress': 0.76,
      'freq': '440 Hz Akustik Dalga'
    },
    {
      'title': 'Aday Bulundu! Sinyal Kuruluyor...',
      'progress': 0.96,
      'freq': '528 Hz Rezonans'
    },
  ];

  @override
  void initState() {
    super.initState();

    // Radar pulse rings
    _pulseController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _pulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _pulseController3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Start delays for pulse rings
    Future.delayed(const Duration(milliseconds: 1350), () {
      if (mounted) _pulseController2.repeat();
    });

    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) _pulseController3.repeat();
    });

    // Center avatar glow
    _centerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Sonar sweep
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: _searchStates[0]['progress'],
    );

    // Sound bars (5 bars)
    _soundBarControllers = List.generate(5, (index) {
      final durations = [650, 850, 500, 700, 900];
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durations[index]),
      )..repeat(reverse: true);
    });

    // State change timer
    _stateTimer = Timer.periodic(const Duration(milliseconds: 2800), (timer) {
      if (mounted) {
        setState(() {
          _currentStateIndex = (_currentStateIndex + 1) % _searchStates.length;
          _progressController.animateTo(
            _searchStates[_currentStateIndex]['progress'],
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController1.dispose();
    _pulseController2.dispose();
    _pulseController3.dispose();
    _centerGlowController.dispose();
    _sonarController.dispose();
    _progressController.dispose();
    for (var controller in _soundBarControllers) {
      controller.dispose();
    }
    _stateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Stack(
        children: [
          // Ambient glow background
          Positioned(
            top: -96,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2E8F0).withOpacity(0.4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE2E8F0).withOpacity(0.3),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildHeader(),
                          const SizedBox(height: 4),
                          _buildRadarArena(),
                          const SizedBox(height: 4),
                          _buildStatusCard(),
                          const SizedBox(height: 10),
                          _buildBoostCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC).withOpacity(0.85),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x0A0B0F17),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x0D0B0F17),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 21,
                color: Color(0xFF0B0F17),
              ),
            ),
          ),

          // Center title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E5FF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Canlı Ses Radarı',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B0F17),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Text(
                'FREKANS EŞLEŞMESI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF5500),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          // Online count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x0D0B0F17),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '3.480 ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B0F17),
                  ),
                ),
                Text(
                  'canlı',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0x990B0F17),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xE6E2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B0F17),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'CANLI FREKANS TARAMASI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xBF0B0F17),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sana En Yakın Ruhu Dinle',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0B0F17),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Ses tınısı ve zevklerinle eşleşen kullanıcılar taranıyor',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0x990B0F17),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRadarArena() {
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Static rings
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x99E2E8F0),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xCCE2E8F0),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),

          // Sonar sweep
          AnimatedBuilder(
            animation: _sonarController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _sonarController.value * 2 * math.pi,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.transparent,
                        const Color(0xFF06B6D4).withOpacity(0.15),
                        const Color(0xFF06B6D4).withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.75, 0.85, 0.94, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating avatars
          Positioned(
            top: 12,
            right: 32,
            child: _buildFloatingAvatar(
              'Derin, 24',
              'assets/images/avatars/radar_derin.jpg',
              44,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 24,
            child: _buildFloatingAvatar(
              'Can, 26',
              'assets/images/avatars/radar_can.jpg',
              44,
            ),
          ),
          Positioned(
            top: 48,
            left: 32,
            child: Opacity(
              opacity: 0.6,
              child: _buildFloatingAvatar(
                'Ece, 23',
                'assets/images/avatars/radar_ece.jpg',
                36,
              ),
            ),
          ),

          // Center avatar
          AnimatedBuilder(
            animation: _centerGlowController,
            builder: (context, child) {
              return Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2E8F0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(
                        0.45 * (1 - (_centerGlowController.value - 0.5).abs() * 2),
                      ),
                      blurRadius: 35 + (15 * _centerGlowController.value),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/avatars/radar_user.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Status badge below center avatar
          Positioned(
            bottom: 140,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F17),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Frekans Taranıyor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAvatar(String name, String imagePath, double size) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
              ),
            ],
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x0D0B0F17),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: size > 40 ? 11 : 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xCC0B0F17),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x0D0B0F17),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -15,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0x0D0B0F17),
                        ),
                      ),
                      child: const Icon(
                        Icons.graphic_eq,
                        size: 20,
                        color: Color(0xFF0B0F17),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _searchStates[_currentStateIndex]['title'],
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0B0F17),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 13,
                                color: Color(0x660B0F17),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tahmini süre: ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0x990B0F17),
                                ),
                              ),
                              Text(
                                '~6 sn',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0B0F17),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Sound bars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xB3E2E8F0),
                  ),
                ),
                child: Row(
                  children: List.generate(5, (index) {
                    final heights = [10.0, 16.0, 22.0, 14.0, 18.0];
                    final opacities = [0.7, 0.4, 1.0, 0.6, 0.8];
                    return AnimatedBuilder(
                      animation: _soundBarControllers[index],
                      builder: (context, child) {
                        return Container(
                          width: 2.5,
                          height: heights[index] * (0.4 + 0.6 * _soundBarControllers[index].value),
                          margin: EdgeInsets.only(left: index > 0 ? 3 : 0),
                          decoration: BoxDecoration(
                            color: Color(0xFF0B0F17).withOpacity(opacities[index]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressController.value,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B0F17)),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Frekans: ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xA60B0F17),
                    ),
                  ),
                  Text(
                    _searchStates[_currentStateIndex]['freq'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B0F17),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Akustik Uyum: Yüksek',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xBF0B0F17),
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

  Widget _buildBoostCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x0D0B0F17),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -15,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF5500).withOpacity(0.15),
                  const Color(0xFFFF2E7E).withOpacity(0.15),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFFF5500).withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.bolt,
              size: 18,
              color: Color(0xFFFF5500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Radar Boost',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B0F17),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xCCE2E8F0),
                        ),
                      ),
                      child: Text(
                        '2X HIZ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xBF0B0F17),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Eşleşme süresini 3 saniyeye indir',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0x990B0F17),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F17),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.diamond,
                    size: 13,
                    color: Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hızlandır',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mute toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0x0D0B0F17),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: -15,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isMuted
                        ? const Color(0xFFFF5500).withOpacity(0.15)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    size: 20,
                    color: _isMuted ? const Color(0xFFFF5500) : const Color(0xFF0B0F17),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mikrofonu Önceden Sustur',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B0F17),
                        ),
                      ),
                      Text(
                        'Bağlandığın anda sessiz başlarsın',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0x990B0F17),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _isMuted ? const Color(0xFFFF5500) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: _isMuted ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
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
          const SizedBox(height: 10),

          // Cancel button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F17),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -15,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aramayı İptal Et',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
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
