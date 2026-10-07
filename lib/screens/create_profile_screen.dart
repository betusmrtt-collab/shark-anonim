import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../home_screen.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';
import '../services/file_security_service.dart';
import '../services/input_security_service.dart';
import '../services/storage_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _bioController = TextEditingController(
    text: 'Kelimelerin ağırlığına inanan, gecenin sessizliğinde derin frekanslar arayan bir ses.',
  );

  String _selectedGender = 'male';
  final List<String> _selectedTags = ['#GeceKuşu', '#Felsefe', '#Müzik', '#Sinema'];
  final int _maxTags = 8;
  final int _maxBioLength = 160;
  String? _avatarImage;
  final List<String> _galleryImages = [];
  final int _maxGalleryImages = 6;
  final ImagePicker _picker = ImagePicker();
  bool _isBioTouched = false;
  String _username = '';

  String? _voiceBioPath;
  bool _isRecording = false;
  // Future feature: Voice playback
  // bool _isPlaying = false;
  int _recordingSeconds = 0;
  bool _isLoading = false; // ✅ Loading state

  AnimationController? _waveAnimationController;
  Animation<double>? _waveAnimation;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      setState(() {});
    });
    _loadUserData();

    // Ses dalgaları animasyonu
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _waveAnimationController!, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await SupabaseConfig.client
            .from('users')
            .select('username')
            .eq('id', userId)
            .single();

        setState(() {
          _username = response['username'] ?? '';
        });
        AppLogger.ui.success('Kullanıcı bilgisi yüklendi');
      }
    } catch (e) {
      AppLogger.ui.error('Kullanıcı bilgisi yüklenemedi', e);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _waveAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceRecording() async {
    // Platform kontrolü - sadece Android/iOS'ta çalışır
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses kaydı sadece mobil cihazlarda destekleniyor')),
        );
      }
      return;
    }

    if (_isRecording) {
      // Kaydı durdur
      setState(() {
        _voiceBioPath = 'mock_voice_bio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _isRecording = false;
        _recordingSeconds = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses kaydı tamamlandı'),
            backgroundColor: Color(0xFF00687A),
          ),
        );
      }
    } else {
      // Kaydı başlat
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Sayaç başlat (her saniye güncelle, 60 saniyede durdur)
      for (int i = 1; i <= 60; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (!_isRecording || !mounted) break;

        setState(() {
          _recordingSeconds = i;
        });

        // 60 saniyeye ulaşınca otomatik durdur
        if (i == 60) {
          _toggleVoiceRecording();
        }
      }
    }
  }

  void _deleteVoiceBio() {
    setState(() {
      _voiceBioPath = null;
    });
  }

  Widget _buildWaveBar(double heightFactor) {
    if (_waveAnimation == null) {
      return Container(
        width: 2.5,
        height: 14 * heightFactor,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _waveAnimation!,
      builder: (context, child) {
        return Container(
          width: 2.5,
          height: 14 * heightFactor * _waveAnimation!.value,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      // ✅ GÜVENLIK: Dosya validasyonu
      final file = File(image.path);
      final validation = await FileSecurityService.validateImage(
        file,
        type: ImageType.avatar,
      );

      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation.error!),
              backgroundColor: const Color(0xFFFF4444),
            ),
          );
        }
        AppLogger.storage.warning('Avatar validasyonu başarısız: ${validation.error}');
        return;
      }

      // ✅ GÜVENLIK: Resmi optimize et
      try {
        final optimizedFile = await FileSecurityService.resizeAndOptimizeImage(
          file,
          type: ImageType.avatar,
        );
        setState(() {
          _avatarImage = optimizedFile.path;
        });
        AppLogger.storage.success('Avatar optimize edildi');
      } catch (e) {
        AppLogger.storage.error('Avatar optimizasyonu başarısız', e);
        // Fallback: orijinal dosyayı kullan
        setState(() {
          _avatarImage = image.path;
        });
      }
    }
  }

  Future<void> _pickGalleryImage() async {
    if (_galleryImages.length >= _maxGalleryImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maksimum $_maxGalleryImages fotoğraf ekleyebilirsiniz')),
      );
      return;
    }

    // Çoklu resim seçimi
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (images.isEmpty) return;

    // Maksimum limit kontrolü
    final remainingSlots = _maxGalleryImages - _galleryImages.length;
    final imagesToProcess = images.take(remainingSlots).toList();

    if (images.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sadece $remainingSlots fotoğraf eklenebilir (toplam limit: $_maxGalleryImages)'),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }

    // Her resmi sırayla işle
    for (final image in imagesToProcess) {
      // ✅ GÜVENLIK: Dosya validasyonu
      final file = File(image.path);
      final validation = await FileSecurityService.validateImage(
        file,
        type: ImageType.gallery,
      );

      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${image.name}: ${validation.error}'),
              backgroundColor: const Color(0xFFFF4444),
            ),
          );
        }
        AppLogger.storage.warning('Galeri validasyonu başarısız (${image.name}): ${validation.error}');
        continue; // Bu resmi atla, diğerlerine devam et
      }

      // ✅ GÜVENLIK: Resmi optimize et
      try {
        final optimizedFile = await FileSecurityService.resizeAndOptimizeImage(
          file,
          type: ImageType.gallery,
        );
        setState(() {
          _galleryImages.add(optimizedFile.path);
        });
        AppLogger.storage.success('Galeri resmi optimize edildi: ${image.name}');
      } catch (e) {
        AppLogger.storage.error('Galeri optimizasyonu başarısız (${image.name})', e);
        // Fallback: orijinal dosyayı kullan
        setState(() {
          _galleryImages.add(image.path);
        });
      }
    }

    // Başarı mesajı
    if (mounted && imagesToProcess.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${imagesToProcess.length} fotoğraf eklendi'),
          backgroundColor: const Color(0xFF00687A),
        ),
      );
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImages.removeAt(index);
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _addTag() {
    // Etiket ekleme dialogu göster
    showDialog(
      context: context,
      builder: (context) => _AddTagDialog(
        onTagAdded: (tag) {
          if (_selectedTags.length < _maxTags && !_selectedTags.contains(tag)) {
            setState(() {
              _selectedTags.add(tag);
            });
          }
        },
      ),
    );
  }

  void _saveProfile() async {
    // ✅ Çift tıklama önleme
    if (_isLoading) return;

    // Biyografi kontrolü
    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir biyografi yazın'),
          backgroundColor: Color(0xFFFF4444),
        ),
      );
      AppLogger.ui.warning('Profil kaydedilemedi: Boş biyografi');
      return;
    }

    // ✅ GÜVENLIK: Biyografi sanitization
    final bioResult = InputSecurityService.sanitizeBio(_bioController.text.trim());
    if (!bioResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bioResult.error!),
          backgroundColor: const Color(0xFFFF4444),
        ),
      );
      AppLogger.ui.warning('Profil kaydedilemedi: ${bioResult.error}');
      return;
    }
    final sanitizedBio = bioResult.sanitized!;

    setState(() => _isLoading = true); // ✅ Loading başlat

    AppLogger.database.info('Profil kaydetme işlemi başlatıldı');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil kaydediliyor...')),
    );

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      AppLogger.database.debug('User ID: $userId');

      // 1. Avatar yükle (eğer varsa)
      String? avatarUrl;
      if (_avatarImage != null) {
        avatarUrl = await StorageService.uploadAvatar(_avatarImage!, userId);
      }

      // 2. Sesli biyografi yükle (eğer varsa)
      String? voiceBioUrl;
      if (_voiceBioPath != null && _voiceBioPath!.isNotEmpty && !_voiceBioPath!.startsWith('mock_')) {
        // Gerçek ses dosyası varsa yükle (mock değilse)
        voiceBioUrl = await StorageService.uploadVoiceBio(_voiceBioPath!, userId);
      } else if (_voiceBioPath != null && _voiceBioPath!.startsWith('mock_')) {
        AppLogger.storage.info('Mock ses kaydı - Production\'da gerçek kayıt yapılacak');
        // Mock ses kaydı, şimdilik URL'i null bırak
      }

      // 3. Profil bilgilerini güncelle
      AppLogger.database.info('Profil bilgileri güncelleniyor...');
      await SupabaseConfig.client.from('users').update({
        'avatar_url': avatarUrl,
        'bio': sanitizedBio, // ✅ GÜVENLIK: Sanitized bio kullanılıyor
        'voice_bio_url': voiceBioUrl,
        'gender': _selectedGender,
        'tags': _selectedTags,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      AppLogger.database.success('Profil bilgileri güncellendi');

      // 4. Galeri resimlerini yükle (paralel)
      if (_galleryImages.isNotEmpty) {
        AppLogger.storage.info('Galeri resimleri yükleniyor: ${_galleryImages.length} adet');
        await SupabaseConfig.client.from('user_gallery').delete().eq('user_id', userId);

        // ⚡ PERFORMANS: Paralel upload
        final uploadFutures = <Future>[];
        for (int i = 0; i < _galleryImages.length; i++) {
          uploadFutures.add(() async {
            final galleryUrl = await StorageService.uploadGalleryImage(_galleryImages[i], userId, i);

            await SupabaseConfig.client.from('user_gallery').insert({
              'user_id': userId,
              'image_url': galleryUrl,
              'display_order': i,
            });
          }());
        }
        await Future.wait(uploadFutures);
        AppLogger.storage.success('Galeri resimleri yüklendi: ${_galleryImages.length} adet');
      }

      AppLogger.database.success('Profil başarıyla kaydedildi');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla kaydedildi!'),
            backgroundColor: Color(0xFF00687A),
          ),
        );

        // Ana ekrana yönlendir
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        });
      }
    } catch (e) {
      AppLogger.database.error('Profil kaydetme hatası', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF4444),
          ),
        );
      }
    } finally {
      // ✅ Loading bitir
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    _buildAvatarSection(),
                    const SizedBox(height: 16),
                    _buildMediaShowcaseCard(),
                    const SizedBox(height: 16),
                    _buildBioCard(),
                    const SizedBox(height: 16),
                    _buildTagsCard(),
                    const SizedBox(height: 16),
                    _buildPrivacyNote(),
                    const SizedBox(height: 12),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5EEFF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profili Düzenle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00687A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ŞİFRELİ OTURUM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00687A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: _isLoading ? null : _saveProfile, // ✅ Disable when loading
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF000000), Color(0xFF1a1a1a)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF57DFFE).withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00687A).withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: -1,
                    offset: const Offset(0, 2),
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
                      color: const Color(0xFF57DFFE),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF57DFFE).withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isLoading // ✅ Loading indicator
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                    'Kaydet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!_isLoading) // ✅ Hide arrow when loading
                    const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF57DFFE),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5EEFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _avatarImage != null
                      ? Image.file(File(_avatarImage!), fit: BoxFit.cover)
                      : const Icon(
                          Icons.account_circle,
                          size: 90,
                          color: Color(0xFF7C839B),
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.photo_camera, size: 16, color: Colors.white),
                  onPressed: _pickImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _username.isEmpty ? '@kullanıcı' : '@$_username',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF57DFFE),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified,
                size: 12,
                color: Color(0xFF006172),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Anonim Üye • Gizli Profil',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF76777D),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        _buildGenderSelector(),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE9FF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGenderButton('Kadın', 'female'),
          _buildGenderButton('Erkek', 'male'),
          _buildGenderButton('Belirtilmedi', 'unspecified'),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF57DFFE),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF45464D),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaShowcaseCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.perm_media, color: Color(0xFF00687A), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Medya Vitrini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD3E4FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.blur_on, color: Color(0xFF00687A), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '${_galleryImages.length}/$_maxGalleryImages',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00687A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _galleryImages.isEmpty
              ? GestureDetector(
                  onTap: _pickGalleryImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCE9FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            color: Color(0xFF00687A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fotoğraf Yüklemek İçin Dokun',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Yüzler ve hassas unsurlar gizliliğiniz için\notomatik filtrelenir',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF45464D),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildChip('JPEG', false),
                            const SizedBox(width: 8),
                            _buildChip('PNG', false),
                            const SizedBox(width: 8),
                            _buildChip('Maks. 15MB', true),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _galleryImages.length + (_galleryImages.length < _maxGalleryImages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _galleryImages.length) {
                      return GestureDetector(
                        onTap: _pickGalleryImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD3E4FE),
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            color: Color(0xFF00687A),
                            size: 32,
                          ),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(File(_galleryImages[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeGalleryImage(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFDCE9FF) : const Color(0xFFE5EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
          color: isHighlighted ? const Color(0xFF00687A) : const Color(0xFF76777D),
        ),
      ),
    );
  }

  Widget _buildBioCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note, color: Color(0xFF00687A), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Biyografi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                ],
              ),
              Text(
                '${_bioController.text.length} / $_maxBioLength',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF76777D),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _bioController,
                  maxLength: _maxBioLength,
                  maxLines: 2,
                  onTap: () {
                    if (!_isBioTouched) {
                      setState(() {
                        _isBioTouched = true;
                        _bioController.clear();
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'Kendinizi tanıtın...',
                    hintStyle: TextStyle(color: Color(0xFF76777D)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0B1C30),
                    height: 1.4,
                  ),
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _voiceBioPath == null ? _toggleVoiceRecording : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? const Color(0xFFFF6B6B).withOpacity(0.2)
                              : _voiceBioPath != null
                                  ? const Color(0xFF4CD7F6).withOpacity(0.2)
                                  : const Color(0xFFE5EEFF),
                          borderRadius: BorderRadius.circular(20),
                          border: _isRecording
                              ? Border.all(color: const Color(0xFFFF6B6B), width: 2)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRecording)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildWaveBar(0.4),
                                  const SizedBox(width: 2),
                                  _buildWaveBar(0.7),
                                  const SizedBox(width: 2),
                                  _buildWaveBar(1.0),
                                  const SizedBox(width: 2),
                                  _buildWaveBar(0.6),
                                  const SizedBox(width: 2),
                                  _buildWaveBar(0.9),
                                  const SizedBox(width: 6),
                                ],
                              )
                            else
                              Icon(
                                _voiceBioPath != null ? Icons.check_circle : Icons.mic,
                                color: _voiceBioPath != null
                                    ? const Color(0xFF00687A)
                                    : const Color(0xFF00687A),
                                size: 14,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              _isRecording
                                  ? '$_recordingSeconds sn'
                                  : _voiceBioPath != null
                                      ? 'Ses Kaydedildi'
                                      : 'Sesli Biyografi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _isRecording
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF00687A),
                              ),
                            ),
                            if (_isRecording) ...[
                              const SizedBox(width: 6),
                              const Text(
                                '/ 60sn',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF76777D),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_voiceBioPath != null)
                      GestureDetector(
                        onTap: _deleteVoiceBio,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE5E5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      )
                    else if (_isRecording)
                      GestureDetector(
                        onTap: _toggleVoiceRecording,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B).withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.stop,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5EEFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sentiment_satisfied,
                          size: 16,
                          color: Color(0xFF76777D),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tag, color: Color(0xFF00687A), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'İlgi & Ruh Hali Etiketleri',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                ],
              ),
              Text(
                '${_selectedTags.length} / $_maxTags Seçildi',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00687A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._selectedTags.map((tag) => _buildTagChip(tag)),
              if (_selectedTags.length < _maxTags) _buildAddTagButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00687A),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFE5EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Color(0xFF76777D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTagButton() {
    return GestureDetector(
      onTap: _addTag,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD3E4FE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Color(0xFF00687A)),
            SizedBox(width: 4),
            Text(
              'Etiket Ekle',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00687A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE9FF).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF4CD7F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user,
              size: 16,
              color: Color(0xFF006172),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uçtan Uca Anonimlik',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Profil güncellemeleriniz topluluk kurallarına tabi olup gerçek kimliğinizi ele verecek veriler sistem tarafından sansürlenerek korunur.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF45464D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF1a1a1a)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF57DFFE).withOpacity(0.35),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF00687A).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProfile, // ✅ Disable when loading
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF57DFFE),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF57DFFE).withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _isLoading // ✅ Loading indicator
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                  'Değişiklikleri Kaydet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isLoading) // ✅ Hide arrow when loading
                  const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF57DFFE),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTagDialog extends StatefulWidget {
  final Function(String) onTagAdded;

  const _AddTagDialog({required this.onTagAdded});

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Etiket Ekle'),
      content: TextField(
        controller: _tagController,
        decoration: const InputDecoration(
          hintText: '#etiket',
          prefixText: '#',
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            // ✅ GÜVENLIK: Hashtag validasyonu
            final tagResult = InputSecurityService.validateHashtag(value);
            if (tagResult.isValid) {
              widget.onTagAdded(tagResult.sanitized!);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tagResult.error!)),
              );
            }
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            if (_tagController.text.isNotEmpty) {
              // ✅ GÜVENLIK: Hashtag validasyonu
              final tagResult = InputSecurityService.validateHashtag(_tagController.text);
              if (tagResult.isValid) {
                widget.onTagAdded(tagResult.sanitized!);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tagResult.error!)),
                );
              }
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
