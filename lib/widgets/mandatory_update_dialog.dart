import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/update_service.dart';

/// ZORUNLU Güncelleme Dialog'u
/// Kullanıcı kapatamaz, mutlaka güncelleme yapmalıdır
class MandatoryUpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;

  const MandatoryUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  @override
  State<MandatoryUpdateDialog> createState() => _MandatoryUpdateDialogState();
}

class _MandatoryUpdateDialogState extends State<MandatoryUpdateDialog> {
  final UpdateService _updateService = UpdateService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    final latestVersion = widget.updateInfo['version'] ?? 'Bilinmiyor';
    final currentVersion = widget.updateInfo['currentVersion'] ?? 'Bilinmiyor';
    final releaseNotes = widget.updateInfo['releaseNotes'] ?? '';
    final fileSize = widget.updateInfo['fileSize'] ?? 0;
    final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);

    return PopScope(
      // ❌ Geri tuşunu devre dışı bırak - kullanıcı kaçamaz
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Kullanıcı geri tuşuna bastığında hiçbir şey yapma
        _showCannotExitMessage();
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFF8E53),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ⚠️ Uyarı İkonu
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_alt,
                      color: Color(0xFFFF6B6B),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başlık
                  const Text(
                    '🚨 ZORUNLU GÜNCELLEME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Versiyon Bilgisi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mevcut Versiyon:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'v$currentVersion',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Yeni Versiyon:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'v$latestVersion',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (fileSize > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dosya Boyutu:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$fileSizeMB MB',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Açıklama
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Uygulamaya devam etmek için güncelleme yapmanız zorunludur. Güncelleme ile yeni özellikler ve güvenlik iyileştirmeleri gelecektir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // Yenilikler
                  if (releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '## ⚡ Kritik Düzeltmeler',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '### Otomatik Güncelleme Kontrolü Düzeltildi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '✅ Uygulama açıldığında güncelleme otomatik kontrol ediliyor',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // İlerleme Durumu
                  if (_isDownloading) ...[
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Butonlar
                  Row(
                    children: [
                      // Uygulamayı Kapat Butonu
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isDownloading ? null : _exitApp,
                          icon: const Icon(Icons.exit_to_app, size: 20),
                          label: const Text('Çıkış'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Güncelle Butonu
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isDownloading ? null : _downloadAndInstall,
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF6B6B),
                                    ),
                                  ),
                                )
                              : const Icon(Icons.download, size: 20),
                          label: Text(_isDownloading ? 'İndiriliyor...' : 'Güncelle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF6B6B),
                            disabledBackgroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = 'İndirme başlatılıyor...';
    });

    try {
      final downloadUrl = widget.updateInfo['downloadUrl'] as String;

      final filePath = await _updateService.downloadUpdate(
        downloadUrl,
        (progress) {
          setState(() {
            _downloadProgress = progress;
            _statusMessage = 'İndiriliyor: ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      if (filePath != null && mounted) {
        setState(() {
          _statusMessage = 'Kurulum başlatılıyor...';
        });

        await Future.delayed(const Duration(milliseconds: 500));

        final success = await _updateService.installApk(filePath);

        if (success && mounted) {
          setState(() {
            _statusMessage = '✅ Kurulum ekranı açıldı!\n\n📱 Kurulum Adımları:\n1. "Yükle" düğmesine dokunun\n2. "Bilinmeyen kaynaklardan izin ver" seçeneğini açın (gerekirse)\n3. Kurulum tamamlandığında uygulamayı açın';
            _isDownloading = false;
          });
        } else if (mounted) {
          _showError('❌ Kurulum başlatılamadı.\n\nÇözüm:\n1. Ayarlar > Güvenlik > Bilinmeyen Kaynaklar\'ı açın\n2. Tekrar "İndir ve Kur" düğmesine dokunun\n\nDosya: ${filePath.split('/').last}');
        }
      } else if (mounted) {
        _showError('İndirme başarısız. İnternet bağlantınızı kontrol edin.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Hata oluştu: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _statusMessage = message;
      _downloadProgress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCannotExitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Güncelleme yapmadan devam edemezsiniz'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exitApp() {
    // Uygulamayı kapat
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }
}
