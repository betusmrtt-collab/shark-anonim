import 'package:flutter/foundation.dart';
import 'dart:io';

/// Merkezi log yönetim sistemi
class AppLogger {
  static const bool _enableLogs = true; // Production'da false yapılabilir
  static final List<String> _logHistory = [];
  static const int _maxHistorySize = 1000;

  // Log seviyeleri
  static const String _debug = '🔍 DEBUG';
  static const String _info = 'ℹ️ INFO';
  static const String _warning = '⚠️ WARNING';
  static const String _error = '❌ ERROR';
  static const String _success = '✅ SUCCESS';

  /// Debug log - Geliştirme aşamasında detaylı bilgiler
  static void debug(String message, [String? tag]) {
    _log(_debug, message, tag);
  }

  /// Info log - Genel bilgilendirme mesajları
  static void info(String message, [String? tag]) {
    _log(_info, message, tag);
  }

  /// Warning log - Uyarılar
  static void warning(String message, [String? tag]) {
    _log(_warning, message, tag);
  }

  /// Error log - Hatalar
  static void error(String message, [String? tag, dynamic error, StackTrace? stackTrace]) {
    final errorMsg = error != null ? '\n  Error: $error' : '';
    final stackMsg = stackTrace != null ? '\n  Stack: ${stackTrace.toString().split('\n').take(3).join('\n  ')}' : '';
    _log(_error, '$message$errorMsg$stackMsg', tag);
  }

  /// Success log - Başarılı işlemler
  static void success(String message, [String? tag]) {
    _log(_success, message, tag);
  }

  /// Ana log fonksiyonu
  static void _log(String level, String message, [String? tag]) {
    if (!_enableLogs && !kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23); // HH:MM:SS.mmm
    final tagStr = tag != null ? '[$tag]' : '';
    final logMessage = '$timestamp $level $tagStr $message';

    // Console'a yazdır
    if (kDebugMode) {
      debugPrint(logMessage);
    }

    // Log geçmişine ekle
    _logHistory.add(logMessage);
    if (_logHistory.length > _maxHistorySize) {
      _logHistory.removeAt(0);
    }
  }

  /// Log geçmişini getir
  static List<String> getHistory() => List.unmodifiable(_logHistory);

  /// Log geçmişini temizle
  static void clearHistory() => _logHistory.clear();

  /// Log geçmişini dosyaya kaydet
  static Future<String?> exportLogs() async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'anonim_logs_$timestamp.txt';

      // Geçici dizinde kaydet
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(_logHistory.join('\n'));

      info('Loglar dışa aktarıldı: ${file.path}', 'Logger');
      return file.path;
    } catch (e) {
      error('Log dışa aktarma hatası', 'Logger', e);
      return null;
    }
  }

  // Kategori bazlı logger'lar
  static final auth = _CategoryLogger('AUTH');
  static final database = _CategoryLogger('DATABASE');
  static final ui = _CategoryLogger('UI');
  static final network = _CategoryLogger('NETWORK');
  static final storage = _CategoryLogger('STORAGE');
}

/// Kategori özelinde logger
class _CategoryLogger {
  final String category;

  _CategoryLogger(this.category);

  void debug(String message) => AppLogger.debug(message, category);
  void info(String message) => AppLogger.info(message, category);
  void warning(String message) => AppLogger.warning(message, category);
  void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      AppLogger.error(message, category, error, stackTrace);
  void success(String message) => AppLogger.success(message, category);
}
