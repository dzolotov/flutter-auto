import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Аудио сервис для управления воспроизведением музыки через GStreamer
class AudioService extends StateNotifier<AudioState> {
  AudioService() : super(const AudioState.stopped());

  Process? _gstreamerProcess;
  static const String _musicUrl = 'https://file-examples.com/storage/fee57a7384689ca07a1c3d3/2017/11/file_example_MP3_5MG.mp3';

  /// Включить/выключить музыку
  Future<void> toggleMusic() async {
    switch (state) {
      case AudioStateStopped():
        await _startMusic();
        break;
      case AudioStatePlaying():
        await _stopMusic();
        break;
      case AudioStateLoading():
        // Игнорируем если уже загружается
        break;
    }
  }

  /// Запустить воспроизведение через GStreamer
  Future<void> _startMusic() async {
    try {
      state = const AudioState.loading();
      
      // Команда GStreamer для воспроизведения MP3 из URL
      final result = await Process.start('gst-launch-1.0', [
        'souphttpsrc',
        'location=$_musicUrl',
        '!',
        'decodebin',
        '!',
        'audioconvert',
        '!',
        'audioresample',
        '!',
        'alsasink'
      ]);

      _gstreamerProcess = result;
      
      // Слушаем завершение процесса
      result.exitCode.then((exitCode) {
        if (exitCode != 0) {
          print('GStreamer exited with code: $exitCode');
        }
        _gstreamerProcess = null;
        if (mounted) {
          state = const AudioState.stopped();
        }
      });

      state = const AudioState.playing();
      print('Музыка запущена через GStreamer');
      
    } catch (e) {
      print('Ошибка запуска музыки: $e');
      state = const AudioState.stopped();
    }
  }

  /// Остановить воспроизведение
  Future<void> _stopMusic() async {
    try {
      _gstreamerProcess?.kill();
      _gstreamerProcess = null;
      state = const AudioState.stopped();
      print('Музыка остановлена');
    } catch (e) {
      print('Ошибка остановки музыки: $e');
    }
  }

  @override
  void dispose() {
    _stopMusic();
    super.dispose();
  }
}

/// Состояния аудио плеера
sealed class AudioState {
  const AudioState();
  
  const factory AudioState.stopped() = AudioStateStopped;
  const factory AudioState.loading() = AudioStateLoading;
  const factory AudioState.playing() = AudioStatePlaying;
}

class AudioStateStopped extends AudioState {
  const AudioStateStopped();
}

class AudioStateLoading extends AudioState {
  const AudioStateLoading();
}

class AudioStatePlaying extends AudioState {
  const AudioStatePlaying();
}

/// Provider для аудио сервиса
final audioServiceProvider = StateNotifierProvider<AudioService, AudioState>((ref) {
  return AudioService();
});