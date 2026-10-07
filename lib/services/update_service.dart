import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  static const String githubRepo = 'betusmrtt-collab/shark-anonim';

  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      print('🔍 Mevcut versiyon: $currentVersion');

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest'),
      );

      print('📡 GitHub API cevabı: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');

        print('🆕 GitHub\'daki en son versiyon: $latestVersion');

        // ✅ HER ZAMAN EN SON VERSİYONA GÜNCELLE
        // Mevcut versiyon farklıysa (daha eski veya farklı bir şey) güncelle
        if (currentVersion != latestVersion) {
          print('✅ Versiyon farklı! Güncelleme mevcut.');
          final apkAsset = (data['assets'] as List).firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            print('📦 APK bulundu: ${apkAsset['name']}');
            return {
              'version': latestVersion,
              'currentVersion': currentVersion,
              'downloadUrl': apkAsset['browser_download_url'],
              'releaseNotes': data['body'] ?? 'Yeni güncelleme mevcut',
              'publishedAt': data['published_at'] ?? '',
            };
          } else {
            print('❌ APK asset bulunamadı');
          }
        } else {
          print('ℹ️ Versiyon güncel ($currentVersion)');
        }
      }
      return null;
    } catch (e) {
      print('❌ Güncelleme kontrolü hatası: $e');
      return null;
    }
  }

  Future<String?> downloadUpdate(String url, Function(double) onProgress) async {
    try {
      print('📥 İndirme başlatılıyor: $url');
      
      // Android için external storage yerine cache kullan (daha güvenilir)
      final dir = Platform.isAndroid 
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      
      final filePath = '${dir!.path}/anonim_update.apk';
      print('💾 İndirme yolu: $filePath');

      // Eski dosya varsa sil
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Eski APK silindi');
      }

      final request = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final bytes = <int>[];
      final total = request.contentLength ?? 0;
      var received = 0;

      print('📦 Toplam boyut: ${(total / 1024 / 1024).toStringAsFixed(2)} MB');

      await for (var chunk in request.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          final progress = received / total;
          onProgress(progress);
          if (received % (1024 * 1024) == 0 || received == total) {
            print('📊 İndirme: ${(progress * 100).toStringAsFixed(1)}%');
          }
        }
      }

      await file.writeAsBytes(bytes);
      print('✅ Dosya kaydedildi: $filePath');
      
      // Dosya var mı kontrol et
      if (await file.exists()) {
        final size = await file.length();
        print('📦 İndirilen dosya boyutu: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
        return filePath;
      } else {
        print('❌ Dosya kaydedilemedi');
        return null;
      }
    } catch (e) {
      print('❌ İndirme hatası: $e');
      return null;
    }
  }

  Future<bool> installApk(String filePath) async {
    try {
      print('📱 Kurulum başlatılıyor: $filePath');
      
      if (!Platform.isAndroid) {
        print('⚠️ Sadece Android destekleniyor');
        return false;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ APK dosyası bulunamadı: $filePath');
        return false;
      }

      print('🔧 OpenFilex ile açılıyor...');
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      
      print('📱 Kurulum sonucu:');
      print('   Tip: ${result.type}');
      print('   Mesaj: ${result.message}');
      
      // OpenFilex.ResultType değerlerini kontrol et
      if (result.type == ResultType.done) {
        print('✅ Kurulum ekranı açıldı');
        return true;
      } else if (result.type == ResultType.noAppToOpen) {
        print('❌ APK açacak uygulama yok');
        return false;
      } else if (result.type == ResultType.fileNotFound) {
        print('❌ Dosya bulunamadı');
        return false;
      } else if (result.type == ResultType.permissionDenied) {
        print('❌ İzin reddedildi');
        return false;
      } else {
        print('⚠️ Bilinmeyen durum: ${result.type}');
        return false;
      }
    } catch (e) {
      print('❌ Kurulum hatası: $e');
      return false;
    }
  }
}
