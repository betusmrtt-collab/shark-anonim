import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../widgets/mandatory_update_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UpdateService _updateService = UpdateService();
  bool _isCheckingUpdate = false;
  
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _waveController;
  
  int _selectedNavIndex = 0;
  final String _selectedFilter = 'Rezonans Odak';

  @override
  void initState() {
    super.initState();
    
    // Animasyon controller'ları
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _checkForMandatoryUpdate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _checkForMandatoryUpdate() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    try {
      final updateInfo = await _updateService.checkForUpdate();
      if (updateInfo != null && mounted) {
        if (updateInfo['isMandatory'] == true) {
          _showMandatoryUpdateDialog(updateInfo);
        } else {
          _showUpdateAvailableSnackbar();
        }
      }
    } catch (e) {
      debugPrint('[HOME] Güncelleme kontrolü hatası: $e');
    }
  }

  void _showMandatoryUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MandatoryUpdateDialog(updateInfo: updateInfo),
    );
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    
    try {
      final updateInfo = await _updateService.checkForUpdate(forceCheck: true);
      if (!mounted) return;

      if (updateInfo != null) {
        if (updateInfo['isMandatory'] == true) {
          _showMandatoryUpdateDialog(updateInfo);
        } else {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => UpdateDialog(updateInfo: updateInfo),
          );
        }
      } else {
        _showMessage('Uygulamanız güncel');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Güncelleme kontrolü başarısız', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  void _showUpdateAvailableSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉 Yeni güncelleme mevcut!'),
        action: SnackBarAction(
          label: 'GÖRÜNTÜLE',
          onPressed: _checkForUpdates,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0b0f19),
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Ambient Cyber Gradients & Background
          _buildCosmicBackground(),
          
          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(user),
                
                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      const SizedBox(height: 12),
                      
                      // Filter Chips
                      _buildFilterChips(),
                      
                      const SizedBox(height: 16),
                      
                      // Hero: Magnetic Cosmic Frequency Radar
                      _buildHeroRadarCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Quick Match Capsules
                      _buildQuickMatchCapsules(),
                      
                      const SizedBox(height: 16),
                      
                      // Interactive Ice Breakers
                      _buildIceBreakers(),
                      
                      const SizedBox(height: 16),
                      
                      // Live Audio Rooms
                      _buildLiveAudioRooms(),
                      
                      const SizedBox(height: 16),
                      
                      // VIP Cyber Aura Pass
                      _buildVipSection(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildCosmicBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Gradient Orbs
          Positioned(
            top: -60,
            left: -50,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFff2e63).withValues(alpha: 0.15 + _pulseController.value * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF9d4edd).withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00f0ff).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0b0f19).withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Brand
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFff2e63), Color(0xFFffd9dd)],
                ).createShader(bounds),
                child: const Text(
                  'STITCHES',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00f0ff),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00f0ff).withValues(alpha: 0.6 + _pulseController.value * 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Telemetry Live Frequency
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1a253e).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFff2e63).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00f0ff), Color(0xFFff2e63)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00f0ff).withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: _pulseController.value * 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  '58.420 Dalga',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFf1f5f9),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Notifications
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1a253e).withValues(alpha: 0.8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 19,
                    color: Color(0xFF94a3b8),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFff2e63),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFff2e63).withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Profile Avatar
          GestureDetector(
            onTap: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFff2e63), Color(0xFF00f0ff), Color(0xFFff9a3c)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFff2e63).withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF070a12),
                ),
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: Color(0xFFff2e63),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'icon': Icons.radar, 'label': 'Rezonans Odak'},
      {'icon': Icons.mic, 'label': 'Yalnızca Ses'},
      {'emoji': '👻', 'label': 'Hayalet Mod'},
      {'emoji': '🔮', 'label': 'Aura Çifti'},
    ];
    
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter['label'] == _selectedFilter;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFff2e63), Color(0xFFff6b8b)],
                    )
                  : null,
              color: isSelected ? null : const Color(0xFF1a253e).withValues(alpha: 0.7),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFffd9dd).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFff2e63).withValues(alpha: 0.5),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (filter['icon'] != null)
                  Icon(
                    filter['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : const Color(0xFF00f0ff),
                  )
                else
                  Text(filter['emoji'] as String, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  filter['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF94a3b8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroRadarCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFff2e63).withValues(alpha: 0.2),
              const Color(0xFF00f0ff).withValues(alpha: 0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFff2e63).withValues(alpha: 0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(1.5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFF0c1222).withValues(alpha: 0.95),
          ),
          child: Column(
            children: [
              // Top Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFff2e63).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _rotateController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotateController.value * 2 * math.pi,
                              child: const Icon(
                                Icons.cyclone,
                                size: 15,
                                color: Color(0xFF00f0ff),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'MANYETİK PORTAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00f0ff),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFff2e63).withValues(alpha: 0.3),
                          const Color(0xFFff9a3c).withValues(alpha: 0.3),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFff2e63).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF34d399),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF34d399).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: _pulseController.value * 2,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '%98 Senkron',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Central Radar Display
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Entity Alpha
                    _buildResonanceNode(
                      color: const Color(0xFFff2e63),
                      icon: Icons.fingerprint,
                      label: 'Ruh #409',
                    ),
                    
                    // Equalizer Wave
                    _buildEqualizerWave(),
                    
                    // Entity Beta
                    _buildResonanceNode(
                      color: const Color(0xFF00f0ff),
                      icon: Icons.graphic_eq,
                      label: 'Ruh #882',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Kör Ses Eşleşmesi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 4),
              
              const Text(
                'Yüz Yok • Saf Enerji • Sadece anlık rezonansınla frekansı yakala',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94a3b8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bottom Action
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Icon(
                              Icons.podcasts,
                              size: 17,
                              color: Color.lerp(
                                const Color(0xFFff9a3c),
                                Colors.white,
                                _pulseController.value,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '3.120 Yayında',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94a3b8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff2e63), Color(0xFFff9a3c)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFff2e63).withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Icon(
                                Icons.mic,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.9 + _pulseController.value * 0.1),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Frekansa Bağlan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.bolt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResonanceNode({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 20,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF0c1222),
            ),
            child: Icon(
              icon,
              size: 22,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
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
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFf1f5f9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEqualizerWave() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final height = 10 + math.sin(_waveController.value * math.pi * 2 + index * 0.5) * 15;
              final colors = [
                const Color(0xFFff2e63),
                const Color(0xFF00f0ff),
                const Color(0xFFff9a3c),
                const Color(0xFF9d4edd),
              ];
              
              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [colors[index % colors.length], Colors.white],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors[index % colors.length].withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildQuickMatchCapsules() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildCapsule(
              title: 'Kör Fısıltı',
              description: 'Anonim sesli & şifreli sohbet. Kimliğini sadece frekans belirler.',
              icon: Icons.lock_clock,
              color: const Color(0xFF9d4edd),
              badge: '3 DK LİMİT',
              buttonText: 'Fısıltı Başlat',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCapsule(
              title: 'Hayalet Portalı',
              description: '5 dakika sonunda tüm mesaj ve ses dalgaları sonsuza dek buharlaşır.',
              icon: Icons.auto_delete,
              emoji: '👻',
              color: const Color(0xFF00f0ff),
              badge: '0 İZ • SİLİNİR',
              buttonText: 'Hayalete Gir',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsule({
    required String title,
    required String description,
    IconData? icon,
    String? emoji,
    required Color color,
    required String badge,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1a253e).withValues(alpha: 0.7),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: emoji != null
                    ? Center(child: Text(emoji, style: const TextStyle(fontSize: 19)))
                    : Icon(icon, size: 19, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFff9a3c).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFff9a3c).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFff9a3c),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.2)],
              ),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              buttonText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIceBreakers() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Icon(
                    Icons.casino,
                    size: 18,
                    color: Color.lerp(
                      const Color(0xFFff9a3c),
                      Colors.white,
                      _pulseController.value,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Kozmik Buz Kırıcılar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFff9a3c),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFff9a3c).withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: _pulseController.value * 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'CANLI DÜELLO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFff9a3c),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildGameCard(
                  title: 'Frekans Ruleti',
                  description: 'Mistik ses tonu ve jeton kazan',
                  icon: Icons.rotate_right,
                  color: const Color(0xFFff9a3c),
                  badge: 'Hediye & Ses',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGameCard(
                  title: 'D mi C mi?',
                  description: 'Canlı sesli ikilem soruları',
                  icon: Icons.psychology_alt,
                  color: const Color(0xFF00f0ff),
                  badge: 'Sesli Düello',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1a253e).withValues(alpha: 0.7),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meydan Oku',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Icon(
                  Icons.play_circle,
                  size: 14,
                  color: color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAudioRooms() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Canlı Ses Odaları',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFff2e63),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFff2e63).withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: _pulseController.value * 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFff2e63).withValues(alpha: 0.2),
                      const Color(0xFF9d4edd).withValues(alpha: 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFff2e63).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 14, color: Color(0xFFffd9dd)),
                    SizedBox(width: 4),
                    Text(
                      'Oda Aç',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFffd9dd),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildAudioRoomCard(
            title: '🌙 Gece Kuşları & Lo-Fi',
            listeners: 340,
            speakers: 6,
            isLive: true,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildAudioRoomCard(
            title: '🎭 Anonim İtiraflar • FX',
            listeners: 195,
            subtitle: 'Siber Fısıltı FX Aktif',
            isLive: false,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioRoomCard({
    required String title,
    required int listeners,
    int? speakers,
    String? subtitle,
    required bool isLive,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1a253e).withValues(alpha: 0.7),
        border: Border.all(
          color: const Color(0xFFff2e63).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff2e63).withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFff2e63),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFff2e63).withValues(alpha: 0.5 + _pulseController.value * 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFff2e63), Color(0xFF9d4edd)],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00f0ff),
                        border: Border.all(
                          color: const Color(0xFF0b0f19),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00f0ff).withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFff2e63).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFff2e63).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'CANLI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFffd9dd),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.headphones, size: 13, color: Color(0xFF00f0ff)),
                        const SizedBox(width: 4),
                        Text(
                          '$listeners Dinliyor',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF00f0ff),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (speakers != null) ...[
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: Color(0xFF94a3b8))),
                          const SizedBox(width: 8),
                          const Icon(Icons.mic, size: 13, color: Color(0xFFff9a3c)),
                          const SizedBox(width: 4),
                          Text(
                            '$speakers Konuşuyor',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFff9a3c),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (subtitle != null)
                          Expanded(
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94a3b8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Join Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff2e63), Color(0xFFff6b8b)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFff2e63).withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  isLive ? 'Işınlan' : 'Dinle',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (isLive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatars
                  Row(
                    children: List.generate(3, (index) {
                      return Container(
                        margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFff2e63).withValues(alpha: 0.5),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFff2e63).withValues(alpha: 0.8),
                              const Color(0xFF9d4edd).withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  // Live Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00f0ff).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildEqualizerWave(),
                        const SizedBox(width: 6),
                        const Text(
                          'Yayında',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00f0ff),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVipSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFff9a3c), Color(0xFFff2e63), Color(0xFF9d4edd)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFff9a3c).withValues(alpha: 0.4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color(0xFF0c1322),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff9a3c), Color(0xFFffc107)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFff9a3c).withValues(alpha: 0.7),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(Icons.diamond, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AURA PASS VIP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            backgroundColor: Color(0xFFffc107),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sınırsız kör arama & siber aura kanatları',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94a3b8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff9a3c), Color(0xFFff2e63)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFff9a3c).withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Text(
                  'Yükselt ✨',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final navItems = [
      {'icon': Icons.local_fire_department, 'label': 'Akış'},
      {'icon': Icons.amp_stories, 'label': 'Story'},
      {'icon': Icons.chat_bubble, 'label': 'Fısıltı'},
      {'icon': Icons.radar, 'label': 'Radar'},
      {'icon': Icons.diamond, 'label': 'Lüks'},
      {'icon': Icons.account_circle, 'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0b0f19).withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = index == _selectedNavIndex;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 22,
                            color: isSelected
                                ? const Color(0xFFff2e63)
                                : const Color(0xFF94a3b8),
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: -4,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 6,
                                width: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFff2e63),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFff2e63).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFff2e63)
                              : const Color(0xFF94a3b8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
