import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// Ses kayıt servisi - Platform-safe implementation
class AudioRecorderService {
  static String? _currentRecordingPath;
  static Timer? _durationTimer;
  static int _recordingSeconds = 0;
  static final StreamController<RecordingState> _stateController = StreamController<RecordingState>.broadcast();
  static bool _isRecording = false;

  static const int maxRecordingDuration = 60; // 60 saniye max

  /// State stream
  static Stream<RecordingState> get stateStream => _stateController.stream;

  /// Platform desteği kontrolü
  static bool get isPlatformSupported {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Kayıt başlat
  static Future<void> startRecording() async {
    try {
      // Platform kontrolü
      if (!isPlatformSupported) {
        throw Exception('Ses kaydı sadece Android ve iOS\'ta destekleniyor');
      }

      // Kayıt dizini oluştur
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_bio_$timestamp.m4a';

      _isRecording = true;
      _recordingSeconds = 0;

      // State güncelle
      _updateState(
        isRecording: true,
        duration: Duration.zero,
        amplitude: 0.0,
      );

      // Duration timer başlat
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingSeconds++;

        _updateState(
          isRecording: true,
          duration: Duration(seconds: _recordingSeconds),
          amplitude: 0.5, // Mock amplitude
        );

        // Max duration kontrolü
        if (_recordingSeconds >= maxRecordingDuration) {
          stopRecording();
        }
      });

      AppLogger.database.success('Ses kaydı başlatıldı (mock)');
    } catch (e) {
      AppLogger.database.error('Ses kaydı başlatma hatası', e);
      _isRecording = false;
      _updateState(isRecording: false, duration: Duration.zero, amplitude: 0.0);
      rethrow;
    }
  }

  /// Kayıt durdur
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      _durationTimer?.cancel();
      _isRecording = false;

      _updateState(
        isRecording: false,
        duration: Duration(seconds: _recordingSeconds),
        amplitude: 0.0,
      );

      AppLogger.database.success('Ses kaydı durduruldu (mock): ${_recordingSeconds}s');

      // Mock: Boş dosya oluştur (gerçek kayıt için record paketi gerekli)
      if (_currentRecordingPath != null && _recordingSeconds > 0) {
        final file = File(_currentRecordingPath!);
        await file.writeAsBytes([]); // Mock empty file
        return _currentRecordingPath;
      }

      return null;
    } catch (e) {
      AppLogger.database.error('Ses kaydı durdurma hatası', e);
      return null;
    }
  }

  /// Kayıt iptal et
  static Future<void> cancelRecording() async {
    try {
      _durationTimer?.cancel();
      _isRecording = false;

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _updateState(isRecording: false, duration: Duration.zero, amplitude: 0.0);
      _currentRecordingPath = null;
      _recordingSeconds = 0;

      AppLogger.database.info('Ses kaydı iptal edildi');
    } catch (e) {
      AppLogger.database.error('Ses kaydı iptal hatası', e);
    }
  }

  /// Pause kayıt
  static Future<void> pauseRecording() async {
    if (_isRecording) {
      _durationTimer?.cancel();
      _updateState(
        isRecording: false,
        duration: Duration(seconds: _recordingSeconds),
        amplitude: 0.0,
      );
      AppLogger.database.info('Ses kaydı duraklatıldı');
    }
  }

  /// Resume kayıt
  static Future<void> resumeRecording() async {
    if (_currentRecordingPath != null && !_isRecording) {
      _isRecording = true;

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingSeconds++;
        _updateState(
          isRecording: true,
          duration: Duration(seconds: _recordingSeconds),
          amplitude: 0.5,
        );

        if (_recordingSeconds >= maxRecordingDuration) {
          stopRecording();
        }
      });

      AppLogger.database.info('Ses kaydı devam ettiriliyor');
    }
  }

  /// State güncelle
  static void _updateState({
    required bool isRecording,
    required Duration duration,
    required double amplitude,
  }) {
    _stateController.add(RecordingState(
      isRecording: isRecording,
      duration: duration,
      amplitude: amplitude,
    ));
  }

  /// Kaynakları temizle
  static Future<void> dispose() async {
    _durationTimer?.cancel();
    await _stateController.close();
  }
}

/// Kayıt durumu
class RecordingState {
  final bool isRecording;
  final Duration duration;
  final double amplitude; // 0.0 - 1.0

  RecordingState({
    required this.isRecording,
    required this.duration,
    required this.amplitude,
  });

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
