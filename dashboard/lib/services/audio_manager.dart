import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Провайдер для управления аудиосистемой
final audioManagerProvider = StateNotifierProvider<AudioManager, AudioSystemState>((ref) {
  return AudioManager();
});

/// Модель состояния аудиосистемы
class AudioSystemState {
  final List<AudioZone> zones;
  final double globalVolume;
  final bool globalMute;
  final bool isPlaying;
  final bool autoStart;
  final bool speedVolumeAdaptation;
  final bool navigationPriority;
  final bool systemSounds;

  const AudioSystemState({
    required this.zones,
    this.globalVolume = 0.7,
    this.globalMute = false,
    this.isPlaying = false,
    this.autoStart = true,
    this.speedVolumeAdaptation = true,
    this.navigationPriority = true,
    this.systemSounds = true,
  });

  AudioSystemState copyWith({
    List<AudioZone>? zones,
    double? globalVolume,
    bool? globalMute,
    bool? isPlaying,
    bool? autoStart,
    bool? speedVolumeAdaptation,
    bool? navigationPriority,
    bool? systemSounds,
  }) {
    return AudioSystemState(
      zones: zones ?? this.zones,
      globalVolume: globalVolume ?? this.globalVolume,
      globalMute: globalMute ?? this.globalMute,
      isPlaying: isPlaying ?? this.isPlaying,
      autoStart: autoStart ?? this.autoStart,
      speedVolumeAdaptation: speedVolumeAdaptation ?? this.speedVolumeAdaptation,
      navigationPriority: navigationPriority ?? this.navigationPriority,
      systemSounds: systemSounds ?? this.systemSounds,
    );
  }
}

/// Модель аудиозоны
class AudioZone {
  final String name;
  final String id;
  final double volume;
  final double balance; // -1.0 (левый) до 1.0 (правый)
  final double fade;    // -1.0 (задний) до 1.0 (передний) 
  final bool muted;
  final AudioSource currentSource;
  final EqualizerSettings equalizer;
  final RadioState radio;
  final MediaState media;

  const AudioZone({
    required this.name,
    required this.id,
    this.volume = 0.7,
    this.balance = 0.0,
    this.fade = 0.0,
    this.muted = false,
    this.currentSource = AudioSource.bluetooth,
    required this.equalizer,
    required this.radio,
    required this.media,
  });

  AudioZone copyWith({
    String? name,
    String? id,
    double? volume,
    double? balance,
    double? fade,
    bool? muted,
    AudioSource? currentSource,
    EqualizerSettings? equalizer,
    RadioState? radio,
    MediaState? media,
  }) {
    return AudioZone(
      name: name ?? this.name,
      id: id ?? this.id,
      volume: volume ?? this.volume,
      balance: balance ?? this.balance,
      fade: fade ?? this.fade,
      muted: muted ?? this.muted,
      currentSource: currentSource ?? this.currentSource,
      equalizer: equalizer ?? this.equalizer,
      radio: radio ?? this.radio,
      media: media ?? this.media,
    );
  }
}

/// Источники аудио
enum AudioSource {
  bluetooth('Bluetooth'),
  usb('USB'),
  aux('AUX'),
  radio('Радио'),
  cd('CD'),
  streaming('Стриминг');

  const AudioSource(this.displayName);
  final String displayName;
}

/// Настройки эквалайзера
class EqualizerSettings {
  final Map<String, double> bands; // Частота -> Усиление (дБ)
  final String preset;

  const EqualizerSettings({
    required this.bands,
    this.preset = 'Пользовательский',
  });

  EqualizerSettings copyWith({
    Map<String, double>? bands,
    String? preset,
  }) {
    return EqualizerSettings(
      bands: bands ?? this.bands,
      preset: preset ?? this.preset,
    );
  }
}

/// Состояние радио
class RadioState {
  final double frequency; // FM частота в МГц
  final List<RadioStation> stations;
  final int currentStationIndex;
  final bool scanning;
  final double signalStrength;

  const RadioState({
    this.frequency = 101.2,
    required this.stations,
    this.currentStationIndex = 0,
    this.scanning = false,
    this.signalStrength = 0.8,
  });

  RadioState copyWith({
    double? frequency,
    List<RadioStation>? stations,
    int? currentStationIndex,
    bool? scanning,
    double? signalStrength,
  }) {
    return RadioState(
      frequency: frequency ?? this.frequency,
      stations: stations ?? this.stations,
      currentStationIndex: currentStationIndex ?? this.currentStationIndex,
      scanning: scanning ?? this.scanning,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  RadioStation? get currentStation {
    if (stations.isEmpty || currentStationIndex < 0 || currentStationIndex >= stations.length) {
      return null;
    }
    return stations[currentStationIndex];
  }
}

/// Радиостанция
class RadioStation {
  final double frequency;
  final String name;
  final String genre;
  final double signalStrength;

  const RadioStation({
    required this.frequency,
    required this.name,
    this.genre = '',
    this.signalStrength = 1.0,
  });
}

/// Состояние медиаплеера
class MediaState {
  final String? currentTrack;
  final String? artist;
  final String? album;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool shuffle;
  final RepeatMode repeat;
  final List<Track> playlist;
  final int currentTrackIndex;

  const MediaState({
    this.currentTrack,
    this.artist,
    this.album,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.shuffle = false,
    this.repeat = RepeatMode.none,
    required this.playlist,
    this.currentTrackIndex = 0,
  });

  MediaState copyWith({
    String? currentTrack,
    String? artist,
    String? album,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? shuffle,
    RepeatMode? repeat,
    List<Track>? playlist,
    int? currentTrackIndex,
  }) {
    return MediaState(
      currentTrack: currentTrack ?? this.currentTrack,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      shuffle: shuffle ?? this.shuffle,
      repeat: repeat ?? this.repeat,
      playlist: playlist ?? this.playlist,
      currentTrackIndex: currentTrackIndex ?? this.currentTrackIndex,
    );
  }

  Track? get currentTrackObject {
    if (playlist.isEmpty || currentTrackIndex < 0 || currentTrackIndex >= playlist.length) {
      return null;
    }
    return playlist[currentTrackIndex];
  }
}

/// Режимы повтора
enum RepeatMode {
  none('Выкл'),
  one('Один'),
  all('Все');

  const RepeatMode(this.displayName);
  final String displayName;
}

/// Трек
class Track {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? coverUrl;

  const Track({
    required this.title,
    required this.artist,
    this.album = '',
    required this.duration,
    this.coverUrl,
  });
}

/// Менеджер аудиосистемы
class AudioManager extends StateNotifier<AudioSystemState> {
  static final Logger _logger = Logger();
  Timer? _positionTimer;

  AudioManager() : super(_createInitialState()) {
    _logger.i('Инициализация аудиоменеджера');
  }

  /// Создание начального состояния
  static AudioSystemState _createInitialState() {
    // Предустановленные радиостанции
    final radioStations = [
      RadioStation(frequency: 101.2, name: 'Радио России', genre: 'Новости'),
      RadioStation(frequency: 103.7, name: 'Европа Плюс', genre: 'Поп'),
      RadioStation(frequency: 106.2, name: 'Русское Радио', genre: 'Русская музыка'),
      RadioStation(frequency: 107.0, name: 'Rock FM', genre: 'Рок'),
      RadioStation(frequency: 89.1, name: 'Классическая музыка', genre: 'Классика'),
    ];

    // Демо плейлист
    final playlist = [
      Track(
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: Duration(minutes: 5, seconds: 55),
      ),
      Track(
        title: 'Hotel California',
        artist: 'Eagles',
        album: 'Hotel California',
        duration: Duration(minutes: 6, seconds: 30),
      ),
      Track(
        title: 'Stairway to Heaven',
        artist: 'Led Zeppelin',
        album: 'Led Zeppelin IV',
        duration: Duration(minutes: 8, seconds: 2),
      ),
    ];

    // Настройки эквалайзера по умолчанию
    final defaultEqualizer = EqualizerSettings(
      bands: {
        '60Hz': 0.0,
        '170Hz': 0.0,
        '310Hz': 0.0,
        '600Hz': 0.0,
        '1kHz': 0.0,
        '3kHz': 0.0,
        '6kHz': 0.0,
        '12kHz': 0.0,
        '14kHz': 0.0,
        '16kHz': 0.0,
      },
    );

    // Создание зон
    final zones = [
      AudioZone(
        name: 'Водитель',
        id: 'driver',
        balance: -0.3, // Немного влево
        fade: 0.2,     // Немного вперед
        equalizer: defaultEqualizer,
        radio: RadioState(
          frequency: 101.2,
          stations: radioStations,
        ),
        media: MediaState(
          playlist: playlist,
          currentTrack: playlist.first.title,
          artist: playlist.first.artist,
          album: playlist.first.album,
          duration: playlist.first.duration,
        ),
      ),
      AudioZone(
        name: 'Пассажир',
        id: 'passenger',
        balance: 0.3,  // Немного вправо
        fade: 0.2,     // Немного вперед
        equalizer: defaultEqualizer,
        radio: RadioState(
          frequency: 103.7,
          stations: radioStations,
          currentStationIndex: 1,
        ),
        media: MediaState(playlist: playlist),
      ),
      AudioZone(
        name: 'Задние',
        id: 'rear',
        balance: 0.0,
        fade: -0.5,    // Назад
        equalizer: defaultEqualizer,
        radio: RadioState(
          frequency: 106.2,
          stations: radioStations,
          currentStationIndex: 2,
        ),
        media: MediaState(playlist: playlist),
      ),
    ];

    return AudioSystemState(zones: zones);
  }

  /// Инициализация аудиосистемы
  Future<void> initialize() async {
    try {
      _logger.i('Инициализация аудиосистемы...');
      
      // Симуляция подключения к аудиосистеме
      await Future.delayed(Duration(milliseconds: 500));
      
      // Запуск таймера для обновления позиции трека
      _startPositionTimer();
      
      _logger.i('Аудиосистема инициализирована');
    } catch (e) {
      _logger.e('Ошибка инициализации аудиосистемы: $e');
    }
  }

  /// Запуск таймера позиции трека
  void _startPositionTimer() {
    _positionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state.isPlaying) {
        _updateTrackPosition();
      }
    });
  }

  /// Обновление позиции трека
  void _updateTrackPosition() {
    final updatedZones = state.zones.map((zone) {
      if (zone.media.isPlaying && zone.currentSource == AudioSource.bluetooth) {
        final newPosition = zone.media.position + Duration(seconds: 1);
        
        // Переход к следующему треку при достижении конца
        if (newPosition >= zone.media.duration) {
          return _handleTrackEnd(zone);
        }
        
        return zone.copyWith(
          media: zone.media.copyWith(position: newPosition),
        );
      }
      return zone;
    }).toList();

    state = state.copyWith(zones: updatedZones);
  }

  /// Обработка окончания трека
  AudioZone _handleTrackEnd(AudioZone zone) {
    switch (zone.media.repeat) {
      case RepeatMode.one:
        // Повтор текущего трека
        return zone.copyWith(
          media: zone.media.copyWith(position: Duration.zero),
        );
        
      case RepeatMode.all:
      case RepeatMode.none:
        // Переход к следующему треку
        final nextIndex = zone.media.shuffle
            ? math.Random().nextInt(zone.media.playlist.length)
            : (zone.media.currentTrackIndex + 1) % zone.media.playlist.length;
        
        final nextTrack = zone.media.playlist[nextIndex];
        
        return zone.copyWith(
          media: zone.media.copyWith(
            currentTrackIndex: nextIndex,
            currentTrack: nextTrack.title,
            artist: nextTrack.artist,
            album: nextTrack.album,
            duration: nextTrack.duration,
            position: Duration.zero,
            isPlaying: zone.media.repeat == RepeatMode.all,
          ),
        );
    }
  }

  /// Установка громкости зоны
  void setZoneVolume(int zoneIndex, double volume) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = updatedZones[zoneIndex].copyWith(volume: volume);
    
    state = state.copyWith(zones: updatedZones);
    _logger.d('Громкость зоны ${updatedZones[zoneIndex].name}: ${(volume * 100).toInt()}%');
  }

  /// Установка баланса зоны
  void setZoneBalance(int zoneIndex, double balance) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = updatedZones[zoneIndex].copyWith(balance: balance);
    
    state = state.copyWith(zones: updatedZones);
    _logger.d('Баланс зоны ${updatedZones[zoneIndex].name}: $balance');
  }

  /// Установка источника зоны
  void setZoneSource(int zoneIndex, AudioSource source) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = updatedZones[zoneIndex].copyWith(currentSource: source);
    
    state = state.copyWith(zones: updatedZones);
    _logger.i('Источник зоны ${updatedZones[zoneIndex].name}: ${source.displayName}');
  }

  /// Установка общей громкости
  void setGlobalVolume(double volume) {
    state = state.copyWith(globalVolume: volume);
    _logger.d('Общая громкость: ${(volume * 100).toInt()}%');
  }

  /// Установка общего mute
  void setGlobalMute(bool mute) {
    state = state.copyWith(globalMute: mute);
    _logger.i('Общий mute: $mute');
  }

  /// Переключение воспроизведения/паузы
  void togglePlayPause(int zoneIndex) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final zone = state.zones[zoneIndex];
    final isPlaying = !zone.media.isPlaying;
    
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = zone.copyWith(
      media: zone.media.copyWith(isPlaying: isPlaying),
    );
    
    // Обновляем общее состояние воспроизведения
    final anyPlaying = updatedZones.any((z) => z.media.isPlaying);
    
    state = state.copyWith(
      zones: updatedZones,
      isPlaying: anyPlaying,
    );
    
    _logger.i('Воспроизведение зоны ${zone.name}: $isPlaying');
  }

  /// Предыдущий трек
  void previousTrack(int zoneIndex) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final zone = state.zones[zoneIndex];
    final prevIndex = zone.media.currentTrackIndex > 0
        ? zone.media.currentTrackIndex - 1
        : zone.media.playlist.length - 1;
    
    final prevTrack = zone.media.playlist[prevIndex];
    
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = zone.copyWith(
      media: zone.media.copyWith(
        currentTrackIndex: prevIndex,
        currentTrack: prevTrack.title,
        artist: prevTrack.artist,
        album: prevTrack.album,
        duration: prevTrack.duration,
        position: Duration.zero,
      ),
    );
    
    state = state.copyWith(zones: updatedZones);
    _logger.i('Предыдущий трек в зоне ${zone.name}: ${prevTrack.title}');
  }

  /// Следующий трек
  void nextTrack(int zoneIndex) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final zone = state.zones[zoneIndex];
    final nextIndex = (zone.media.currentTrackIndex + 1) % zone.media.playlist.length;
    
    final nextTrack = zone.media.playlist[nextIndex];
    
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = zone.copyWith(
      media: zone.media.copyWith(
        currentTrackIndex: nextIndex,
        currentTrack: nextTrack.title,
        artist: nextTrack.artist,
        album: nextTrack.album,
        duration: nextTrack.duration,
        position: Duration.zero,
      ),
    );
    
    state = state.copyWith(zones: updatedZones);
    _logger.i('Следующий трек в зоне ${zone.name}: ${nextTrack.title}');
  }

  /// Установка частоты радио
  void setRadioFrequency(int zoneIndex, double frequency) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final zone = state.zones[zoneIndex];
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = zone.copyWith(
      radio: zone.radio.copyWith(frequency: frequency),
    );
    
    state = state.copyWith(zones: updatedZones);
    _logger.i('Частота радио зоны ${zone.name}: ${frequency.toStringAsFixed(1)} МГц');
  }

  /// Установка радиостанции
  void setRadioStation(int zoneIndex, int stationIndex) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final zone = state.zones[zoneIndex];
    if (stationIndex < 0 || stationIndex >= zone.radio.stations.length) return;
    
    final station = zone.radio.stations[stationIndex];
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = zone.copyWith(
      radio: zone.radio.copyWith(
        currentStationIndex: stationIndex,
        frequency: station.frequency,
      ),
    );
    
    state = state.copyWith(zones: updatedZones);
    _logger.i('Радиостанция зоны ${zone.name}: ${station.name}');
  }

  /// Установка эквалайзера
  void setZoneEqualizer(int zoneIndex, EqualizerSettings equalizer) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = updatedZones[zoneIndex].copyWith(equalizer: equalizer);
    
    state = state.copyWith(zones: updatedZones);
    _logger.i('Эквалайзер зоны ${updatedZones[zoneIndex].name}: ${equalizer.preset}');
  }

  /// Настройки системы
  void setAutoStart(bool value) {
    state = state.copyWith(autoStart: value);
    _logger.i('Автозапуск: $value');
  }

  void setSpeedVolumeAdaptation(bool value) {
    state = state.copyWith(speedVolumeAdaptation: value);
    _logger.i('Адаптивная громкость: $value');
  }

  void setNavigationPriority(bool value) {
    state = state.copyWith(navigationPriority: value);
    _logger.i('Приоритет навигации: $value');
  }

  void setSystemSounds(bool value) {
    state = state.copyWith(systemSounds: value);
    _logger.i('Системные звуки: $value');
  }

  /// Сброс зоны к настройкам по умолчанию
  void resetZone(int zoneIndex) {
    if (zoneIndex < 0 || zoneIndex >= state.zones.length) return;
    
    final defaultState = _createInitialState();
    final updatedZones = List<AudioZone>.from(state.zones);
    updatedZones[zoneIndex] = defaultState.zones[zoneIndex];
    
    state = state.copyWith(zones: updatedZones);
    _logger.i('Сброс настроек зоны ${updatedZones[zoneIndex].name}');
  }

  /// Сброс всех настроек
  void resetAll() {
    state = _createInitialState();
    _logger.i('Сброс всех настроек аудиосистемы');
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _logger.i('Остановка аудиоменеджера');
    super.dispose();
  }
}