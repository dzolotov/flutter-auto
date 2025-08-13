import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../core/theme/automotive_theme.dart';

// Провайдер для управления медиаплеером
final mediaPlayerProvider = StateNotifierProvider<MediaPlayerNotifier, MediaPlayerState>((ref) {
  return MediaPlayerNotifier();
});

// Состояние медиаплеера
class MediaPlayerState {
  final String currentTrack;
  final String artist;
  final String album;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final double volume;
  final bool isShuffle;
  final bool isRepeat;
  final int currentTrackIndex;
  final List<Map<String, String>> playlist;
  
  MediaPlayerState({
    required this.currentTrack,
    required this.artist,
    required this.album,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.volume,
    required this.isShuffle,
    required this.isRepeat,
    required this.currentTrackIndex,
    required this.playlist,
  });
  
  MediaPlayerState copyWith({
    String? currentTrack,
    String? artist,
    String? album,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    double? volume,
    bool? isShuffle,
    bool? isRepeat,
    int? currentTrackIndex,
    List<Map<String, String>>? playlist,
  }) {
    return MediaPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      currentTrackIndex: currentTrackIndex ?? this.currentTrackIndex,
      playlist: playlist ?? this.playlist,
    );
  }
}

class MediaPlayerNotifier extends StateNotifier<MediaPlayerState> {
  Timer? _timer;
  
  MediaPlayerNotifier() : super(MediaPlayerState(
    currentTrack: 'Highway to Hell',
    artist: 'AC/DC',
    album: 'Highway to Hell',
    duration: Duration(minutes: 3, seconds: 28),
    position: Duration.zero,
    isPlaying: false,
    volume: 0.7,
    isShuffle: false,
    isRepeat: false,
    currentTrackIndex: 0,
    playlist: [
      {'title': 'Highway to Hell', 'artist': 'AC/DC', 'album': 'Highway to Hell', 'duration': '3:28'},
      {'title': 'Thunderstruck', 'artist': 'AC/DC', 'album': 'The Razors Edge', 'duration': '4:52'},
      {'title': 'Back In Black', 'artist': 'AC/DC', 'album': 'Back In Black', 'duration': '4:15'},
      {'title': 'Sweet Child O\' Mine', 'artist': 'Guns N\' Roses', 'album': 'Appetite for Destruction', 'duration': '5:56'},
      {'title': 'Welcome to the Jungle', 'artist': 'Guns N\' Roses', 'album': 'Appetite for Destruction', 'duration': '4:34'},
      {'title': 'Paradise City', 'artist': 'Guns N\' Roses', 'album': 'Appetite for Destruction', 'duration': '6:46'},
      {'title': 'Enter Sandman', 'artist': 'Metallica', 'album': 'Metallica', 'duration': '5:31'},
      {'title': 'Nothing Else Matters', 'artist': 'Metallica', 'album': 'Metallica', 'duration': '6:28'},
      {'title': 'Master of Puppets', 'artist': 'Metallica', 'album': 'Master of Puppets', 'duration': '8:36'},
    ],
  ));
  
  void playPause() {
    if (state.isPlaying) {
      _timer?.cancel();
      state = state.copyWith(isPlaying: false);
    } else {
      state = state.copyWith(isPlaying: true);
      _startTimer();
    }
  }
  
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state.position < state.duration) {
        state = state.copyWith(position: state.position + Duration(seconds: 1));
      } else {
        nextTrack();
      }
    });
  }
  
  void nextTrack() {
    _timer?.cancel();
    int nextIndex = (state.currentTrackIndex + 1) % state.playlist.length;
    _loadTrack(nextIndex);
  }
  
  void previousTrack() {
    _timer?.cancel();
    int prevIndex = state.currentTrackIndex - 1;
    if (prevIndex < 0) prevIndex = state.playlist.length - 1;
    _loadTrack(prevIndex);
  }
  
  void _loadTrack(int index) {
    final track = state.playlist[index];
    final durationParts = track['duration']!.split(':');
    final duration = Duration(
      minutes: int.parse(durationParts[0]),
      seconds: int.parse(durationParts[1]),
    );
    
    state = state.copyWith(
      currentTrack: track['title'],
      artist: track['artist'],
      album: track['album'],
      duration: duration,
      position: Duration.zero,
      currentTrackIndex: index,
      isPlaying: false,
    );
  }
  
  void seek(double value) {
    state = state.copyWith(
      position: Duration(seconds: (state.duration.inSeconds * value).round()),
    );
  }
  
  void setVolume(double value) {
    state = state.copyWith(volume: value);
  }
  
  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }
  
  void toggleRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Медиаплеер для автомобиля с неоновым дизайном
/// Оптимизирован для экрана 800x480
class CarMediaPlayer extends ConsumerWidget {
  const CarMediaPlayer({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaPlayerProvider);
    final mediaNotifier = ref.read(mediaPlayerProvider.notifier);
    
    return Scaffold(
      backgroundColor: AutomotiveTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: AutomotiveTheme.dashboardGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Левая панель - обложка и информация
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Обложка альбома
                      Expanded(
                        flex: 3,
                        child: _buildAlbumArt(mediaState.isPlaying),
                      ),
                      const SizedBox(height: 12),
                      // Информация о треке
                      _buildTrackInfo(mediaState),
                      const SizedBox(height: 12),
                      // Прогресс бар
                      _buildProgressBar(mediaState, mediaNotifier),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Правая панель - управление и плейлист
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Панель управления
                      _buildControlPanel(mediaState, mediaNotifier),
                      const SizedBox(height: 12),
                      // Плейлист
                      Expanded(
                        child: _buildPlaylist(mediaState, mediaNotifier),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAlbumArt(bool isPlaying) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AutomotiveTheme.primaryBlue.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AutomotiveTheme.primaryBlue.withOpacity(0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AutomotiveTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        transform: Matrix4.rotationZ(isPlaying ? 0.02 : 0),
        child: Center(
          child: Icon(
            Icons.album,
            size: 80,
            color: AutomotiveTheme.primaryCyan,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrackInfo(MediaPlayerState state) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AutomotiveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AutomotiveTheme.primaryCyan.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            state.currentTrack,
            style: TextStyle(
              color: AutomotiveTheme.primaryCyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AutomotiveTheme.primaryCyan.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            state.artist,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            state.album,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressBar(MediaPlayerState state, MediaPlayerNotifier notifier) {
    final progress = state.duration.inSeconds > 0 
        ? state.position.inSeconds / state.duration.inSeconds 
        : 0.0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AutomotiveTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AutomotiveTheme.primaryBlue,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: AutomotiveTheme.primaryCyan,
              overlayColor: AutomotiveTheme.primaryCyan.withOpacity(0.3),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 4,
            ),
            child: Slider(
              value: progress,
              onChanged: notifier.seek,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(state.position),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
              Text(
                _formatDuration(state.duration),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlPanel(MediaPlayerState state, MediaPlayerNotifier notifier) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AutomotiveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AutomotiveTheme.primaryBlue.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Основные кнопки управления
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                Icons.shuffle,
                state.isShuffle,
                notifier.toggleShuffle,
                size: 24,
              ),
              _buildControlButton(
                Icons.skip_previous,
                false,
                notifier.previousTrack,
                size: 32,
              ),
              _buildMainPlayButton(state.isPlaying, notifier.playPause),
              _buildControlButton(
                Icons.skip_next,
                false,
                notifier.nextTrack,
                size: 32,
              ),
              _buildControlButton(
                Icons.repeat,
                state.isRepeat,
                notifier.toggleRepeat,
                size: 24,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Регулятор громкости
          Row(
            children: [
              Icon(Icons.volume_down, color: Colors.grey[600], size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AutomotiveTheme.accentOrange,
                    inactiveTrackColor: Colors.grey[800],
                    thumbColor: AutomotiveTheme.accentOrange,
                    overlayColor: AutomotiveTheme.accentOrange.withOpacity(0.3),
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: state.volume,
                    onChanged: notifier.setVolume,
                  ),
                ),
              ),
              Icon(Icons.volume_up, color: Colors.grey[600], size: 20),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton(IconData icon, bool isActive, VoidCallback onTap, {double size = 28}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive 
            ? AutomotiveTheme.primaryBlue.withOpacity(0.2)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
              ? AutomotiveTheme.primaryBlue.withOpacity(0.5)
              : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AutomotiveTheme.primaryBlue : Colors.grey[400],
          size: size,
        ),
      ),
    );
  }
  
  Widget _buildMainPlayButton(bool isPlaying, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              AutomotiveTheme.primaryCyan.withOpacity(0.8),
              AutomotiveTheme.primaryCyan.withOpacity(0.3),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AutomotiveTheme.primaryCyan.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
  
  Widget _buildPlaylist(MediaPlayerState state, MediaPlayerNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: AutomotiveTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'ПЛЕЙЛИСТ',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.playlist.length,
              itemBuilder: (context, index) {
                final track = state.playlist[index];
                final isCurrentTrack = index == state.currentTrackIndex;
                
                return GestureDetector(
                  onTap: () => notifier._loadTrack(index),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrentTrack 
                        ? AutomotiveTheme.primaryBlue.withOpacity(0.2)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrentTrack 
                          ? AutomotiveTheme.primaryBlue.withOpacity(0.5)
                          : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrentTrack ? Icons.volume_up : Icons.music_note,
                          color: isCurrentTrack 
                            ? AutomotiveTheme.primaryCyan
                            : Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track['title']!,
                                style: TextStyle(
                                  color: isCurrentTrack 
                                    ? AutomotiveTheme.primaryCyan
                                    : Colors.white,
                                  fontSize: 12,
                                  fontWeight: isCurrentTrack 
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track['artist']!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          track['duration']!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}