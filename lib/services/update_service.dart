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

        print('🆕 GitHub\'daki versiyon: $latestVersion');

        if (_isNewerVersion(currentVersion, latestVersion)) {
          print('✅ Yeni versiyon bulundu!');
          final apkAsset = (data['assets'] as List).firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            print('📦 APK bulundu: ${apkAsset['name']}');
            return {
              'version': latestVersion,
              'downloadUrl': apkAsset['browser_download_url'],
              'releaseNotes': data['body'] ?? 'Yeni güncelleme mevcut',
            };
          } else {
            print('❌ APK asset bulunamadı');
          }
        } else {
          print('ℹ️ Versiyon güncel');
        }
      }
      return null;
    } catch (e) {
      print('❌ Güncelleme kontrolü hatası: $e');
      return null;
    }
  }

  bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  Future<String?> downloadUpdate(String url, Function(double) onProgress) async {
    try {
      final dir = await getExternalStorageDirectory();
      final filePath = '${dir!.path}/anonim_update.apk';

      final request = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final bytes = <int>[];
      final total = request.contentLength ?? 0;
      var received = 0;

      await for (var chunk in request.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress(received / total);
        }
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      print('İndirme hatası: $e');
      return null;
    }
  }

  Future<void> installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final result = await OpenFilex.open(filePath);
        print('APK açılma durumu: ${result.type} - ${result.message}');
      }
    } catch (e) {
      print('Kurulum hatası: $e');
    }
  }
}
