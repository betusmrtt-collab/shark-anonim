import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/input_security_service.dart';
import 'screens/create_profile_screen.dart';

class GirisScreen extends StatefulWidget {
  const GirisScreen({super.key});

  @override
  State<GirisScreen> createState() => _GirisScreenState();
}

class _GirisScreenState extends State<GirisScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _isLoading = false;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  // Password strength tracking
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;
  
  // Password match tracking
  bool _passwordsMatch = true;
  
  // Future feature: Random username generation
  // final Set<String> _usedUsernames = {};
  // final List<String> _randomHandles = [
  //   'fısıltı_',
  //   'akustik_',
  //   'yankı_dalga',
  //   'gece_frekansı',
  //   'aurora_77',
  //   'izole_ses'
  // ];

  void _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    double strength = 0.0;
    
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.15;
    
    String strengthText;
    Color strengthColor;
    
    if (strength < 0.3) {
      strengthText = 'Zayıf';
      strengthColor = const Color(0xFFFF4444);
    } else if (strength < 0.6) {
      strengthText = 'Orta';
      strengthColor = const Color(0xFFFFAA00);
    } else if (strength < 0.8) {
      strengthText = 'İyi';
      strengthColor = const Color(0xFF00AA00);
    } else {
      strengthText = 'Güçlü';
      strengthColor = const Color(0xFF00687A);
    }
    
    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
      _passwordStrengthColor = strengthColor;
    });
  }
  
  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch = _passwordConfirmController.text.isEmpty || 
                        _passwordController.text == _passwordConfirmController.text;
    });
  }

  // Future feature: Random username generator
  // void _generateRandomUsername() {
  //   final random = Random();
  //   String newUsername;
  //   int attempts = 0;
  //   
  //   do {
  //     final handle = _randomHandles[random.nextInt(_randomHandles.length)];
  //     if (handle.endsWith('_')) {
  //       newUsername = '$handle${100 + random.nextInt(900)}';
  //     } else {
  //       newUsername = handle;
  //     }
  //     attempts++;
  //   } while (_usedUsernames.contains(newUsername) && attempts < 100);
  //   
  //   _usedUsernames.add(newUsername);
  //   setState(() {
  //     _usernameController.text = newUsername;
  //   });
  // }
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    
    _passwordController.addListener(() {
      _calculatePasswordStrength(_passwordController.text);
      _checkPasswordsMatch();
    });
    _passwordConfirmController.addListener(_checkPasswordsMatch);
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          // Elegant background shapes
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF57DFFE).withValues(alpha: 0.08),
                    const Color(0xFF57DFFE).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00687A).withValues(alpha: 0.06),
                    const Color(0xFF00687A).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFACEDFF).withValues(alpha: 0.1),
                    const Color(0xFFACEDFF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // Enhanced Header
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            const Color(0xFFE5EEFF).withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00687A).withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Back button & Badge row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back button
                              Material(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.arrow_back,
                                      size: 20,
                                      color: Color(0xFF0B1C30),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Encrypted badge
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF00687A).withValues(alpha: 0.1),
                                            const Color(0xFF57DFFE).withValues(alpha: 0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF00687A).withValues(alpha: 0.2),
                                          width: 1,
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
                                              color: const Color(0xFF00687A),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF00687A).withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'UÇTAN UCA ŞİFRELİ',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                              color: const Color(0xFF00687A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Logo with enhanced design
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer glow ring
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(0xFF57DFFE).withValues(alpha: 0.0),
                                            const Color(0xFF57DFFE).withValues(alpha: 0.2),
                                            const Color(0xFF00687A).withValues(alpha: 0.1),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Main logo
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF00687A), Color(0xFF57DFFE)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00687A).withValues(alpha: 0.4),
                                            blurRadius: 25,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          
                          // Stitches text with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF00687A), Color(0xFF57DFFE)],
                            ).createShader(bounds),
                            child: Text(
                              'Stitches',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          
                          // Title with background
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00687A).withValues(alpha: 0.1),
                                  const Color(0xFF57DFFE).withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Anonim Dünyaya Katıl',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0B1C30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          Text(
                            'Telefon veya e-posta yok. Sadece sen ve gizli kimliğin.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF76777D),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            
            // Form
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        _buildLabel(
                          theme,
                          'E-posta',
                          badge: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield,
                                size: 12,
                                color: Color(0xFF00687A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Gizli',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF00687A),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildEmailField(theme),
                        const SizedBox(height: 8),
                        
                        // Username
                        _buildLabel(
                          theme,
                          'Anonim Rumuz',
                          badge: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield,
                                size: 12,
                                color: Color(0xFF00687A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Gizli Kimlik',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF00687A),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildUsernameField(theme),
                        const SizedBox(height: 8),
                        
                        // Password
                        _buildLabel(
                          theme,
                          'Geçiş Anahtarı',
                          badge: Text(
                            'En az 8 karakter',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF76777D),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildPasswordField(theme),
                        
                        // Password strength
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _buildPasswordStrength(theme),
                        ],
                        const SizedBox(height: 8),
                        
                        // Confirm password
                        _buildLabel(
                          theme,
                          'Anahtar Tekrarı',
                          badge: _passwordConfirmController.text.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _passwordsMatch ? Icons.check_circle : Icons.error,
                                      size: 12,
                                      color: _passwordsMatch
                                          ? const Color(0xFF00687A)
                                          : const Color(0xFFFF4444),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _passwordsMatch ? 'Eşleşti' : 'Eşleşmiyor',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: _passwordsMatch
                                            ? const Color(0xFF00687A)
                                            : const Color(0xFFFF4444),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        _buildConfirmPasswordField(theme),
                        const SizedBox(height: 10),
                        
                        // Submit button
                        _buildSubmitButton(theme),
                        const SizedBox(height: 8),
                        
                        // Security badge
                        _buildSecurityBadge(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Login prompt
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 30, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zaten bir rumuzun var mı?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF76777D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Giriş Yap',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF00687A),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Extra space for keyboard
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ),
          ],
        ),
      ),
    ],
    ),
    );
  }

  Widget _buildLabel(ThemeData theme, String label, {Widget? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: const Color(0xFF0B1C30),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (badge != null) badge,
      ],
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.email,
          size: 20,
          color: Color(0xFF76777D),
        ),
        hintText: 'ornek@email.com',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFC6C6CD),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00687A),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField(ThemeData theme) {
    return TextField(
      controller: _usernameController,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Text(
            '@',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF45464D),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        hintText: 'kullanıcı_adı',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFC6C6CD),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00687A),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.key,
          size: 20,
          color: Color(0xFF76777D),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: const Color(0xFF76777D),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        hintText: '••••••••••••',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFC6C6CD),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00687A),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField(ThemeData theme) {
    return TextField(
      controller: _passwordConfirmController,
      obscureText: _obscurePasswordConfirm,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.lock_reset,
          size: 20,
          color: Color(0xFF76777D),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: const Color(0xFF76777D),
          ),
          onPressed: () {
            setState(() {
              _obscurePasswordConfirm = !_obscurePasswordConfirm;
            });
          },
        ),
        hintText: 'Tekrar girin',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFC6C6CD),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00687A),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrength(ThemeData theme) {
    return Row(
      children: [
        ...List.generate(4, (index) {
          final isActive = (index + 1) <= (_passwordStrength * 4).ceil();
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: isActive ? _passwordStrengthColor : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          _passwordStrengthText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: _passwordStrengthColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF1a1a1a)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF57DFFE).withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF00687A).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isLoading ? null : _handleRegister,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF57DFFE),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF57DFFE).withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Anonim Profil Oluştur',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      if (!_isLoading) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF57DFFE),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun', isError: true);
      return;
    }

    // ✅ GÜVENLIK: Username validasyonu
    final usernameResult = InputSecurityService.validateUsername(_usernameController.text);
    if (!usernameResult.isValid) {
      _showMessage(usernameResult.error!, isError: true);
      return;
    }

    // ✅ GÜVENLIK: Email validasyonu
    final emailResult = InputSecurityService.validateEmail(_emailController.text);
    if (!emailResult.isValid) {
      _showMessage(emailResult.error!, isError: true);
      return;
    }

    if (_passwordController.text.length < 8) {
      _showMessage('Şifre en az 8 karakter olmalı', isError: true);
      return;
    }

    if (!_passwordsMatch) {
      _showMessage('Şifreler eşleşmiyor', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: emailResult.sanitized!,
        password: _passwordController.text,
        username: usernameResult.sanitized!,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateProfileScreen()),
        );
      }
    } catch (e) {
      _showMessage('Kayıt başarısız: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF4444) : const Color(0xFF00687A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSecurityBadge(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + ((_pulseAnimation.value - 1.0) * 0.2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00687A),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00687A).withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AES-256 Aktif • Uçtan uca şifreli',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF76777D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
