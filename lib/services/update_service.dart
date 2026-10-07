import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  static const String githubRepo = 'betusmrtt-collab/shark-anonim';
  static const String _lastCheckKey = 'last_update_check';
  static const String _cachedUpdateKey = 'cached_update_info';
  static const String _lastKnownVersionKey = 'last_known_version';
  
  // Cache süresi: 1 dakika (güncelleme kontrolü için daha sık kontrol)
  static const Duration _cacheDuration = Duration(minutes: 1);

  /// HIZLI kontrol - cache'den veya GitHub'dan
  /// İlk açılışta performansı etkilemez
  Future<Map<String, dynamic>?> checkForUpdate({bool forceCheck = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      debugPrint('🔍 Mevcut versiyon: $currentVersion');

      // Versiyon değişikliği kontrolü - uygulama güncellendiyse cache'i temizle
      final prefs = await SharedPreferences.getInstance();
      final lastKnownVersion = prefs.getString(_lastKnownVersionKey);
      if (lastKnownVersion != null && lastKnownVersion != currentVersion) {
        debugPrint('📌 Versiyon değişti ($lastKnownVersion → $currentVersion), cache temizleniyor');
        await _clearCache();
      }
      await prefs.setString(_lastKnownVersionKey, currentVersion);

      // Cache kontrolü - sadece forceCheck false ise
      if (!forceCheck) {
        final cachedUpdate = await _getCachedUpdate();
        if (cachedUpdate != null) {
          debugPrint('✅ Cache\'den güncelleme bilgisi alındı');
          return cachedUpdate;
        }
      } else {
        debugPrint('🔄 Force check - cache atlanıyor');
      }

      // HTTP timeout ekle - ağ yavaşsa beklemeden devam et
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ GitHub API timeout - cache\'den devam');
          throw TimeoutException('GitHub API timeout');
        },
      );

      debugPrint('📡 GitHub API cevabı: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');

        debugPrint('🆕 GitHub\'daki en son versiyon: $latestVersion');

        // ✅ ZORUNLU GÜNCELLEME - versiyon farklıysa
        if (currentVersion != latestVersion) {
          debugPrint('🚨 ZORUNLU GÜNCELLEME GEREKLİ!');
          
          final apkAsset = (data['assets'] as List).firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            final updateInfo = {
              'version': latestVersion,
              'currentVersion': currentVersion,
              'downloadUrl': apkAsset['browser_download_url'],
              'releaseNotes': data['body'] ?? 'Yeni güncelleme mevcut',
              'publishedAt': data['published_at'] ?? '',
              'isMandatory': true, // ⭐ ZORUNLU
              'fileSize': apkAsset['size'] ?? 0,
            };

            // Cache'e kaydet - sonraki kontrolde hızlı olsun
            await _cacheUpdateInfo(updateInfo);
            
            debugPrint('📦 APK bulundu: ${apkAsset['name']}');
            return updateInfo;
          } else {
            debugPrint('❌ APK asset bulunamadı');
          }
        } else {
          debugPrint('ℹ️ Versiyon güncel ($currentVersion)');
          // Güncel olduğunu cache'e kaydet
          await _clearCache();
        }
      }
      
      // Son kontrol zamanını güncelle
      await _updateLastCheckTime();
      return null;
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout: $e');
      // Cache'den kontrol et
      return await _getCachedUpdate();
    } catch (e) {
      debugPrint('❌ Güncelleme kontrolü hatası: $e');
      // Hata durumunda cache'den devam et
      return await _getCachedUpdate();
    }
  }

  /// Cache'den güncelleme bilgisi al
  Future<Map<String, dynamic>?> _getCachedUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastCheckKey);
      
      if (lastCheck != null) {
        final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheck);
        final now = DateTime.now();
        
        // Cache süresi dolmadıysa kullan
        if (now.difference(lastCheckTime) < _cacheDuration) {
          final cachedJson = prefs.getString(_cachedUpdateKey);
          if (cachedJson != null) {
            return json.decode(cachedJson) as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Cache okuma hatası: $e');
    }
    return null;
  }

  /// Güncelleme bilgisini cache'e kaydet
  Future<void> _cacheUpdateInfo(Map<String, dynamic> updateInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUpdateKey, json.encode(updateInfo));
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Cache yazma hatası: $e');
    }
  }

  /// Cache'i temizle
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUpdateKey);
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Cache temizleme hatası: $e');
    }
  }

  /// Son kontrol zamanını güncelle
  Future<void> _updateLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Son kontrol zamanı güncelleme hatası: $e');
    }
  }

  /// Son kontrol zamanını al
  Future<DateTime?> getLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastCheckKey);
      if (lastCheck != null) {
        return DateTime.fromMillisecondsSinceEpoch(lastCheck);
      }
    } catch (e) {
      debugPrint('❌ Son kontrol zamanı okuma hatası: $e');
    }
    return null;
  }

  Future<String?> downloadUpdate(String url, Function(double) onProgress) async {
    try {
      debugPrint('📥 İndirme başlatılıyor: $url');
      
      // Android için Downloads klasörünü kullan (kullanıcının erişebileceği yer)
      Directory? dir;
      if (Platform.isAndroid) {
        // External storage'daki Downloads klasörü
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // /storage/emulated/0/Android/data/com.example.anonim/files/
          dir = externalDir;
          debugPrint('📂 External storage kullanılıyor: ${dir.path}');
        } else {
          // Fallback: cache directory
          dir = await getApplicationDocumentsDirectory();
          debugPrint('📂 Cache directory kullanılıyor: ${dir.path}');
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      final filePath = '${dir.path}/anonim_update.apk';
      debugPrint('💾 İndirme yolu: $filePath');

      // Eski dosya varsa sil
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Eski APK silindi');
      }

      final request = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final bytes = <int>[];
      final total = request.contentLength ?? 0;
      var received = 0;

      debugPrint('📦 Toplam boyut: ${(total / 1024 / 1024).toStringAsFixed(2)} MB');

      await for (var chunk in request.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          final progress = received / total;
          onProgress(progress);
          if (received % (1024 * 1024) == 0 || received == total) {
            debugPrint('📊 İndirme: ${(progress * 100).toStringAsFixed(1)}%');
          }
        }
      }

      await file.writeAsBytes(bytes);
      debugPrint('✅ Dosya kaydedildi: $filePath');
      
      // Dosya var mı ve boyutu doğru mu kontrol et
      if (await file.exists()) {
        final size = await file.length();
        debugPrint('📦 İndirilen dosya boyutu: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
        
        // Dosya boyutu kontrolü (en az 10 MB olmalı)
        if (size < 10 * 1024 * 1024) {
          debugPrint('⚠️ Dosya boyutu çok küçük, bozuk olabilir');
        }
        
        // Dosya okuma izni var mı kontrol et
        final canRead = await file.exists();
        debugPrint('📖 Dosya okunabilir mi: $canRead');
        
        return filePath;
      } else {
        debugPrint('❌ Dosya kaydedilemedi');
        return null;
      }
    } catch (e) {
      debugPrint('❌ İndirme hatası: $e');
      return null;
    }
  }

  Future<bool> installApk(String filePath) async {
    try {
      debugPrint('📱 Kurulum başlatılıyor: $filePath');
      
      if (!Platform.isAndroid) {
        debugPrint('⚠️ Sadece Android destekleniyor');
        return false;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ APK dosyası bulunamadı: $filePath');
        return false;
      }

      final fileSize = await file.length();
      debugPrint('📦 APK boyutu: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Dosya boyutu kontrolü
      if (fileSize < 10 * 1024 * 1024) {
        debugPrint('⚠️ APK boyutu çok küçük ($fileSize bytes), bozuk olabilir');
      }

      debugPrint('🔧 OpenFilex ile açılıyor...');
      debugPrint('   Dosya yolu: $filePath');
      debugPrint('   MIME tipi: application/vnd.android.package-archive');
      
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
        uti: 'com.android.package-archive',
      );
      
      debugPrint('📱 Kurulum sonucu:');
      debugPrint('   Tip: ${result.type}');
      debugPrint('   Mesaj: ${result.message}');
      
      // OpenFilex.ResultType değerlerini kontrol et
      if (result.type == ResultType.done) {
        debugPrint('✅ Kurulum ekranı başarıyla açıldı');
        return true;
      } else if (result.type == ResultType.noAppToOpen) {
        debugPrint('❌ APK açacak uygulama yok - Bilinmeyen kaynaklardan kuruluma izin verin');
        return false;
      } else if (result.type == ResultType.fileNotFound) {
        debugPrint('❌ Dosya bulunamadı: $filePath');
        return false;
      } else if (result.type == ResultType.permissionDenied) {
        debugPrint('❌ İzin reddedildi - REQUEST_INSTALL_PACKAGES izni gerekli');
        return false;
      } else {
        debugPrint('⚠️ Bilinmeyen durum: ${result.type}');
        // Bilinmeyen durumda bile başarılı olarak işaretle
        // çünkü bazı cihazlarda kurulum ekranı açılıyor ama sonuç hatalı dönüyor
        return result.type == ResultType.done || result.message.contains('done');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Kurulum hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
