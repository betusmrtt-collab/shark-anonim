import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../utils/logger.dart';

/// Ses oynatma servisi
class AudioPlayerService {
  static final AudioPlayer _player = AudioPlayer();
  static String? _currentlyPlayingUrl;
  static final StreamController<AudioPlayerState> _stateController = StreamController<AudioPlayerState>.broadcast();

  /// State stream
  static Stream<AudioPlayerState> get stateStream => _stateController.stream;

  /// Ses çal
  static Future<void> play(String url) async {
    try {
      AppLogger.ui.info('Ses oynatılıyor: $url');

      // Aynı ses zaten çalıyorsa pause yap
      if (_currentlyPlayingUrl == url && _player.playing) {
        await pause();
        return;
      }

      // Farklı ses yükle
      if (_currentlyPlayingUrl != url) {
        await _player.setUrl(url);
        _currentlyPlayingUrl = url;
      }

      await _player.play();
      _emitState();

      AppLogger.ui.success('Ses oynatılıyor');
    } catch (e) {
      AppLogger.ui.error('Ses oynatma hatası', e);
      _emitState();
      rethrow;
    }
  }

  /// Pause
  static Future<void> pause() async {
    try {
      await _player.pause();
      _emitState();
      AppLogger.ui.info('Ses duraklatıldı');
    } catch (e) {
      AppLogger.ui.error('Pause hatası', e);
      rethrow;
    }
  }

  /// Stop ve temizle
  static Future<void> stop() async {
    try {
      await _player.stop();
      _currentlyPlayingUrl = null;
      _emitState();
      AppLogger.ui.info('Ses durduruldu');
    } catch (e) {
      AppLogger.ui.error('Stop hatası', e);
      rethrow;
    }
  }

  /// Seek (belirli pozisyona git)
  static Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _emitState();
    } catch (e) {
      AppLogger.ui.error('Seek hatası', e);
      rethrow;
    }
  }

  /// Ses seviyesi ayarla (0.0 - 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      AppLogger.ui.error('Volume ayarlama hatası', e);
      rethrow;
    }
  }

  /// Şu an çalan ses URL'i
  static String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  /// Çalma durumu
  static bool get isPlaying => _player.playing;

  /// Ses süresi
  static Duration? get duration => _player.duration;

  /// Şu anki pozisyon
  static Duration get position => _player.position;

  /// Progress stream (0.0 - 1.0)
  static Stream<double> get progressStream => _player.positionStream.map((position) {
        final total = _player.duration;
        if (total == null || total.inMilliseconds == 0) return 0.0;
        return (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
      });

  /// Position stream
  static Stream<Duration> get positionStream => _player.positionStream;

  /// State'i emit et
  static void _emitState() {
    _stateController.add(AudioPlayerState(
      isPlaying: _player.playing,
      currentUrl: _currentlyPlayingUrl,
      position: _player.position,
      duration: _player.duration,
    ));
  }

  /// Dispose (uygulama kapanırken çağrılmalı)
  static Future<void> dispose() async {
    await _player.dispose();
    await _stateController.close();
  }

  /// Player'ı sıfırla
  static Future<void> reset() async {
    await stop();
    _currentlyPlayingUrl = null;
  }
}

/// Audio player state
class AudioPlayerState {
  final bool isPlaying;
  final String? currentUrl;
  final Duration position;
  final Duration? duration;

  AudioPlayerState({
    required this.isPlaying,
    this.currentUrl,
    required this.position,
    this.duration,
  });

  double get progress {
    if (duration == null || duration!.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration!.inMilliseconds).clamp(0.0, 1.0);
  }

  String get positionText => _formatDuration(position);
  String get durationText => duration != null ? _formatDuration(duration!) : '0:00';

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
