import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';
import 'dart:io';
import '../home_screen_new.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';
import '../services/file_security_service.dart';
import '../services/input_security_service.dart';
import '../services/storage_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';
import '../services/stats_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedGender = 'male';
  final List<String> _selectedTags = [];
  final int _maxTags = 10;
  final int _maxBioLength = 500;
  String? _avatarImage;
  String? _existingAvatarUrl;
  final List<String> _galleryImages = [];
  final int _maxGalleryImages = 6;
  bool _isBioTouched = false;
  String _username = '';
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  String? _voiceBioPath;
  String? _existingVoiceBioUrl;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordingSeconds = 0;
  double _uploadProgress = 0.0;

  // Popüler taglar
  final List<String> _popularTags = [
    '#GeceKuşu', '#Felsefe', '#Müzik', '#Sinema', '#Sanat', '#Kitap',
    '#Yolculuk', '#Fotoğraf', '#Yoga', '#Kahve', '#Derin Sohbet', '#Doğa'
  ];

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      setState(() {
        _hasUnsavedChanges = true;
      });
    });
    _loadUserData();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  /// Audio listener'ları kur
  void _setupAudioListeners() {
    AudioRecorderService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isRecording = state.isRecording;
          _recordingSeconds = state.duration.inSeconds;
        });
      }
    });

    AudioPlayerService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.isPlaying && state.currentUrl == _voiceBioPath;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await SupabaseConfig.client
          .from('users')
          .select('username, avatar_url, bio, gender, tags, voice_bio_url')
          .eq('id', userId)
          .single();

      final galleryResponse = await SupabaseConfig.client
          .from('user_gallery')
          .select('image_url')
          .eq('user_id', userId)
          .order('display_order');

      setState(() {
        _username = response['username'] ?? '';
        _existingAvatarUrl = response['avatar_url'];

        if (response['bio'] != null && response['bio'].toString().isNotEmpty) {
          _bioController.text = response['bio'];
          _isBioTouched = true;
        }
        if (response['gender'] != null) {
          _selectedGender = response['gender'];
        }
        if (response['tags'] != null && response['tags'] is List) {
          _selectedTags.clear();
          _selectedTags.addAll((response['tags'] as List).map((e) => e.toString()).toList());
        }

        if (response['voice_bio_url'] != null && response['voice_bio_url'].toString().isNotEmpty) {
          _existingVoiceBioUrl = response['voice_bio_url'];
          _voiceBioPath = response['voice_bio_url'];
        }

        _galleryImages.clear();
        for (var item in galleryResponse) {
          if (item['image_url'] != null) {
            _galleryImages.add(item['image_url'].toString());
          }
        }

        _hasUnsavedChanges = false;
      });

      AppLogger.ui.success('Profil verileri yüklendi');
    } catch (e) {
      AppLogger.ui.error('Profil yükleme hatası', e);
      _showError('Profil yüklenemedi: ${e.toString()}');
    }
  }

  /// Avatar seç
  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      final file = File(image.path);
      final validation = await FileSecurityService.validateImage(file, type: ImageType.avatar);

      if (!validation.isValid) {
        _showError(validation.error!);
        return;
      }

      try {
        final optimizedFile = await FileSecurityService.resizeAndOptimizeImage(file, type: ImageType.avatar);
        setState(() {
          _avatarImage = optimizedFile.path;
          _hasUnsavedChanges = true;
        });
      } catch (e) {
        setState(() {
          _avatarImage = image.path;
          _hasUnsavedChanges = true;
        });
      }
    }
  }

  /// Avatar kaldır
  void _removeAvatar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avatar Kaldır'),
        content: const Text('Avatar resminizi kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _avatarImage = null;
                _existingAvatarUrl = null;
                _hasUnsavedChanges = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Kaldır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Galeri resmi ekle
  Future<void> _pickGalleryImages() async {
    if (_galleryImages.length >= _maxGalleryImages) {
      _showError('Maksimum $_maxGalleryImages fotoğraf ekleyebilirsiniz');
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (images.isEmpty) return;

    final remainingSlots = _maxGalleryImages - _galleryImages.length;
    final imagesToProcess = images.take(remainingSlots).toList();

    if (images.length > remainingSlots) {
      _showError('Sadece $remainingSlots fotoğraf eklenebilir (limit: $_maxGalleryImages)');
    }

    for (final image in imagesToProcess) {
      final file = File(image.path);
      final validation = await FileSecurityService.validateImage(file, type: ImageType.gallery);

      if (!validation.isValid) {
        _showError('${image.name}: ${validation.error}');
        continue;
      }

      try {
        final optimizedFile = await FileSecurityService.resizeAndOptimizeImage(file, type: ImageType.gallery);
        setState(() {
          _galleryImages.add(optimizedFile.path);
          _hasUnsavedChanges = true;
        });
      } catch (e) {
        setState(() {
          _galleryImages.add(image.path);
          _hasUnsavedChanges = true;
        });
      }
    }

    if (imagesToProcess.isNotEmpty) {
      _showSuccess('${imagesToProcess.length} fotoğraf eklendi');
    }
  }

  /// Galeri resmi sil
  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImages.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  /// Galeri sıralama
  void _onReorderGallery(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _galleryImages.removeAt(oldIndex);
      _galleryImages.insert(newIndex, item);
      _hasUnsavedChanges = true;
    });
  }

  /// Ses kaydı başlat/durdur
  Future<void> _toggleVoiceRecording() async {
    try {
      if (_isRecording) {
        final path = await AudioRecorderService.stopRecording();
        if (path != null) {
          setState(() {
            _voiceBioPath = path;
            _hasUnsavedChanges = true;
          });
          _showSuccess('Ses kaydı tamamlandı');
        }
      } else {
        await AudioRecorderService.startRecording();
        _showSuccess('Ses kaydı başladı');
      }
    } catch (e) {
      _showError('Ses kaydı hatası: ${e.toString()}');
    }
  }

  /// Ses kaydını sil
  void _deleteVoiceBio() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ses Kaydını Sil'),
        content: const Text('Sesli biyografinizi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _voiceBioPath = null;
                _existingVoiceBioUrl = null;
                _hasUnsavedChanges = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Ses oynat/durdur
  Future<void> _toggleVoicePlayback() async {
    try {
      if (_voiceBioPath == null) return;

      if (_isPlaying) {
        await AudioPlayerService.pause();
      } else {
        await AudioPlayerService.play(_voiceBioPath!);
      }
    } catch (e) {
      _showError('Ses oynatma hatası: ${e.toString()}');
    }
  }

  /// Tag ekle
  void _addTag(String tag) {
    if (_selectedTags.length >= _maxTags) {
      _showError('Maksimum $_maxTags etiket ekleyebilirsiniz');
      return;
    }

    final tagResult = InputSecurityService.validateHashtag(tag);
    if (!tagResult.isValid) {
      _showError(tagResult.error!);
      return;
    }

    final sanitizedTag = tagResult.sanitized!;
    if (_selectedTags.contains(sanitizedTag)) {
      _showError('Bu etiket zaten ekli');
      return;
    }

    setState(() {
      _selectedTags.add(sanitizedTag);
      _hasUnsavedChanges = true;
    });
  }

  /// Tag sil
  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
      _hasUnsavedChanges = true;
    });
  }

  /// Profili kaydet
  Future<void> _saveProfile() async {
    if (_isLoading) return;

    // Validasyon
    if (_bioController.text.trim().isEmpty) {
      _showError('Lütfen bir biyografi yazın');
      return;
    }

    final bioResult = InputSecurityService.sanitizeBio(_bioController.text.trim());
    if (!bioResult.isValid) {
      _showError(bioResult.error!);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Oturum bulunamadı');

      // Avatar yükle
      String? avatarUrl = _existingAvatarUrl;
      if (_avatarImage != null && !_avatarImage!.startsWith('http')) {
        setState(() => _uploadProgress = 0.1);
        avatarUrl = await StorageService.uploadAvatar(_avatarImage!, userId);
        setState(() => _uploadProgress = 0.3);
      }

      // Sesli biyografi yükle
      String? voiceBioUrl = _existingVoiceBioUrl;
      if (_voiceBioPath != null && !_voiceBioPath!.startsWith('http')) {
        setState(() => _uploadProgress = 0.4);
        voiceBioUrl = await StorageService.uploadVoiceBio(_voiceBioPath!, userId);
        setState(() => _uploadProgress = 0.6);
      }

      // Profil güncelle
      await SupabaseConfig.client.from('users').update({
        'avatar_url': avatarUrl,
        'bio': bioResult.sanitized!,
        'voice_bio_url': voiceBioUrl,
        'gender': _selectedGender,
        'tags': _selectedTags,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      setState(() => _uploadProgress = 0.7);

      // Galeri güncelle
      await SupabaseConfig.client.from('user_gallery').delete().eq('user_id', userId);

      if (_galleryImages.isNotEmpty) {
        final uploadFutures = <Future>[];
        for (int i = 0; i < _galleryImages.length; i++) {
          uploadFutures.add(_uploadGalleryImage(userId, i));
        }
        await Future.wait(uploadFutures);
      }

      setState(() => _uploadProgress = 0.9);

      // Stats güncelle (profile completion)
      final points = StatsService.calculateProfileCompletionPoints(
        avatarUrl != null,
        bioResult.sanitized!.isNotEmpty,
        voiceBioUrl != null,
        _galleryImages.length,
        _selectedTags.length,
      );
      await StatsService.addFirePoints(userId, points);

      setState(() => _uploadProgress = 1.0);

      _showSuccess('Profil başarıyla kaydedildi!');
      _hasUnsavedChanges = false;

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreenNew()),
        );
      }
    } catch (e) {
      AppLogger.database.error('Profil kaydetme hatası', e);
      _showError('Hata: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _uploadGalleryImage(String userId, int index) async {
    final imagePath = _galleryImages[index];
    String galleryUrl;

    if (imagePath.startsWith('http')) {
      galleryUrl = imagePath;
    } else {
      galleryUrl = await StorageService.uploadGalleryImage(imagePath, userId, index);
    }

    await SupabaseConfig.client.from('user_gallery').insert({
      'user_id': userId,
      'image_url': galleryUrl,
      'display_order': index,
    });
  }

  /// Geri butonuna basıldığında
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Değişiklikler Kaydedilmedi'),
        content: const Text('Yaptığınız değişiklikler kaybolacak. Çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Geri Dön'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çık', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00687A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  if (_isLoading && _uploadProgress > 0) _buildProgressBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          _buildAvatarSection(),
                          const SizedBox(height: 16),
                          _buildBioCard(),
                          const SizedBox(height: 16),
                          _buildVoiceCard(),
                          const SizedBox(height: 16),
                          _buildMediaShowcaseCard(),
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
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
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
              onPressed: () async {
                if (await _onWillPop()) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profili Düzenle',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B1C30),
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
                  Text(
                    'ŞİFRELİ OTURUM',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00687A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: _isLoading ? null : _saveProfile,
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
                  _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Kaydet',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                  if (!_isLoading) const SizedBox(width: 6),
                  if (!_isLoading)
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

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _uploadProgress,
      backgroundColor: const Color(0xFFE5EEFF),
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00687A)),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Profil kaydediliyor...',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
                ),
                child: ClipOval(
                  child: _avatarImage != null
                      ? Image.file(File(_avatarImage!), fit: BoxFit.cover)
                      : _existingAvatarUrl != null
                          ? Image.network(_existingAvatarUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.account_circle, size: 90, color: Color(0xFF7C839B)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera, size: 16, color: Colors.white),
                ),
              ),
            ),
            if (_avatarImage != null || _existingAvatarUrl != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _removeAvatar,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
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
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF57DFFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, size: 12, color: Color(0xFF006172)),
            ),
          ],
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
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGenderButton('Kadın', 'female'),
          _buildGenderButton('Erkek', 'male'),
          _buildGenderButton('Diğer', 'other'),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
          _hasUnsavedChanges = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF45464D),
          ),
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
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: Color(0xFF00687A), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Biyografi',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1C30),
                    ),
                  ),
                ],
              ),
              Text(
                '${_bioController.text.length} / $_maxBioLength',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFF76777D),
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
            ),
            child: TextField(
              controller: _bioController,
              maxLength: _maxBioLength,
              maxLines: 3,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Kendinizi tanıtın...',
                hintStyle: TextStyle(color: Color(0xFF76777D)),
              ),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF0B1C30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, color: Color(0xFF00687A), size: 18),
              const SizedBox(width: 6),
              Text(
                'Sesli Biyografi',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B1C30),
                ),
              ),
              const Spacer(),
              if (_voiceBioPath != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: _deleteVoiceBio,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_voiceBioPath == null && !_isRecording)
            _buildRecordButton()
          else if (_isRecording)
            _buildRecordingIndicator()
          else
            _buildVoicePlayer(),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _toggleVoiceRecording,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, color: Color(0xFFFF4D6D)),
            const SizedBox(width: 8),
            Text(
              'Kayda Başla (max 60sn)',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Kaydediliyor... ${_recordingSeconds}s / 60s',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: _toggleVoiceRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleVoicePlayback,
            color: const Color(0xFF00687A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sesli biyografi kaydedildi',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF0B1C30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaShowcaseCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_library, color: Color(0xFF00687A), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Galeri',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1C30),
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
                child: Text(
                  '${_galleryImages.length}/$_maxGalleryImages',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00687A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_galleryImages.isEmpty)
            _buildEmptyGallery()
          else
            _buildReorderableGallery(),
        ],
      ),
    );
  }

  Widget _buildEmptyGallery() {
    return GestureDetector(
      onTap: _pickGalleryImages,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_photo_alternate, size: 40, color: Color(0xFF00687A)),
            const SizedBox(height: 8),
            Text(
              'Fotoğraf Ekle',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableGallery() {
    return ReorderableWrap(
      spacing: 8,
      runSpacing: 8,
      onReorder: _onReorderGallery,
      children: [
        ..._galleryImages.asMap().entries.map((entry) {
          final index = entry.key;
          final imagePath = entry.value;
          return _buildGalleryTile(imagePath, index);
        }),
        if (_galleryImages.length < _maxGalleryImages) _buildAddGalleryTile(),
      ],
    );
  }

  Widget _buildGalleryTile(String imagePath, int index) {
    final isUrl = imagePath.startsWith('http');
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: isUrl ? NetworkImage(imagePath) : FileImage(File(imagePath)) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeGalleryImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGalleryTile() {
    return GestureDetector(
      onTap: _pickGalleryImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD3E4FE), width: 2),
        ),
        child: const Icon(Icons.add, size: 32, color: Color(0xFF00687A)),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tag, color: Color(0xFF00687A), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'İlgi Alanları',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1C30),
                    ),
                  ),
                ],
              ),
              Text(
                '${_selectedTags.length}/$_maxTags',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00687A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._selectedTags.map((tag) => _buildSelectedTag(tag)),
              if (_selectedTags.length < _maxTags) _buildAddTagButton(),
            ],
          ),
          if (_selectedTags.length < _maxTags) ...[
            const SizedBox(height: 12),
            Text(
              'Popüler Etiketler:',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF76777D),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _popularTags
                  .where((tag) => !_selectedTags.contains(tag))
                  .take(6)
                  .map((tag) => _buildPopularTag(tag))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00687A),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: const Icon(Icons.close, size: 14, color: Color(0xFF76777D)),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTag(String tag) {
    return GestureDetector(
      onTap: () => _addTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EEFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          tag,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF45464D),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTagButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _AddTagDialog(onTagAdded: _addTag),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD3E4FE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: Color(0xFF00687A)),
            const SizedBox(width: 4),
            Text(
              'Ekle',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00687A),
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
            child: const Icon(Icons.verified_user, size: 16, color: Color(0xFF006172)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uçtan Uca Anonimlik',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1C30),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Profil güncellemeleriniz topluluk kurallarına tabi olup gerçek kimliğinizi ele verecek veriler sistem tarafından sansürlenerek korunur.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF45464D),
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
        gradient: const LinearGradient(colors: [Color(0xFF000000), Color(0xFF1a1a1a)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF57DFFE).withOpacity(0.35),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProfile,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF57DFFE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Değişiklikleri Kaydet',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Color(0xFF57DFFE), size: 20),
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
          hintText: 'etiket',
          prefixText: '#',
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.onTagAdded(value);
            Navigator.pop(context);
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
              widget.onTagAdded(_tagController.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
