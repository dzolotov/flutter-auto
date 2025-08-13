import 'package:flutter/material.dart';
import '../../../core/theme/automotive_theme.dart';
import '../../../services/audio_manager.dart';

/// Виджет медиаплеера с управлением воспроизведением
/// Показывает информацию о треке и элементы управления
class MediaPlayerWidget extends StatelessWidget {
  final AudioZone zone;

  const MediaPlayerWidget({
    super.key,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    final media = zone.media;
    
    return Card(
      color: AutomotiveTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: AutomotiveTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Медиаплеер',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                _buildShuffleButton(media.shuffle),
                const SizedBox(width: 8),
                _buildRepeatButton(media.repeat),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Обложка альбома и информация о треке
            Row(
              children: [
                // Обложка альбома
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: media.currentTrackObject?.coverUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            media.currentTrackObject!.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultCover();
                            },
                          ),
                        )
                      : _buildDefaultCover(),
                ),
                
                const SizedBox(width: 16),
                
                // Информация о треке
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.currentTrack ?? 'Нет трека',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        media.artist ?? 'Неизвестный исполнитель',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        media.album ?? 'Неизвестный альбом',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Прогресс-бар
            _buildProgressBar(context, media),
            
            const SizedBox(height: 16),
            
            // Элементы управления
            _buildControlButtons(context, media),
            
            const SizedBox(height: 16),
            
            // Плейлист (если есть место)
            if (media.playlist.isNotEmpty)
              _buildPlaylistPreview(context, media),
          ],
        ),
      ),
    );
  }

  /// Создает обложку по умолчанию
  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AutomotiveTheme.primaryBlue.withOpacity(0.3),
            Colors.grey[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        color: Colors.grey[400],
        size: 32,
      ),
    );
  }

  /// Создает кнопку shuffle
  Widget _buildShuffleButton(bool isShuffled) {
    return IconButton(
      onPressed: () {
        // TODO: Реализовать toggle shuffle
      },
      icon: Icon(
        Icons.shuffle,
        color: isShuffled 
            ? AutomotiveTheme.primaryBlue 
            : Colors.grey[400],
      ),
      tooltip: 'Перемешать',
    );
  }

  /// Создает кнопку repeat
  Widget _buildRepeatButton(RepeatMode repeat) {
    IconData icon;
    Color color;
    
    switch (repeat) {
      case RepeatMode.none:
        icon = Icons.repeat;
        color = Colors.grey[400]!;
        break;
      case RepeatMode.all:
        icon = Icons.repeat;
        color = AutomotiveTheme.primaryBlue;
        break;
      case RepeatMode.one:
        icon = Icons.repeat_one;
        color = AutomotiveTheme.primaryBlue;
        break;
    }
    
    return IconButton(
      onPressed: () {
        // TODO: Реализовать toggle repeat
      },
      icon: Icon(icon, color: color),
      tooltip: 'Повтор: ${repeat.displayName}',
    );
  }

  /// Создает прогресс-бар воспроизведения
  Widget _buildProgressBar(BuildContext context, MediaState media) {
    final progress = media.duration.inMilliseconds > 0
        ? media.position.inMilliseconds / media.duration.inMilliseconds
        : 0.0;
    
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AutomotiveTheme.primaryBlue,
            inactiveTrackColor: Colors.grey[700],
            thumbColor: AutomotiveTheme.primaryBlue,
            overlayColor: AutomotiveTheme.primaryBlue.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              // TODO: Реализовать seek
            },
          ),
        ),
        
        const SizedBox(height: 4),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(media.position),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontFamily: 'DigitalNumbers',
              ),
            ),
            Text(
              _formatDuration(media.duration),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontFamily: 'DigitalNumbers',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Создает кнопки управления воспроизведением
  Widget _buildControlButtons(BuildContext context, MediaState media) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Предыдущий трек
        IconButton(
          onPressed: () {
            // TODO: Реализовать previous track
          },
          icon: Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 32,
          ),
          tooltip: 'Предыдущий трек',
        ),
        
        const SizedBox(width: 16),
        
        // Перемотка назад
        IconButton(
          onPressed: () {
            // TODO: Реализовать rewind
          },
          icon: Icon(
            Icons.fast_rewind,
            color: Colors.grey[400],
            size: 28,
          ),
          tooltip: 'Назад 10 сек',
        ),
        
        const SizedBox(width: 24),
        
        // Воспроизведение/пауза
        Container(
          decoration: BoxDecoration(
            color: AutomotiveTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              // TODO: Реализовать play/pause
            },
            icon: Icon(
              media.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
            tooltip: media.isPlaying ? 'Пауза' : 'Воспроизведение',
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Перемотка вперед
        IconButton(
          onPressed: () {
            // TODO: Реализовать fast forward
          },
          icon: Icon(
            Icons.fast_forward,
            color: Colors.grey[400],
            size: 28,
          ),
          tooltip: 'Вперед 10 сек',
        ),
        
        const SizedBox(width: 16),
        
        // Следующий трек
        IconButton(
          onPressed: () {
            // TODO: Реализовать next track
          },
          icon: Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 32,
          ),
          tooltip: 'Следующий трек',
        ),
      ],
    );
  }

  /// Создает превью плейлиста
  Widget _buildPlaylistPreview(BuildContext context, MediaState media) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Плейлист',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${media.currentTrackIndex + 1} из ${media.playlist.length}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: media.playlist.length,
            itemBuilder: (context, index) {
              final track = media.playlist[index];
              final isCurrentTrack = index == media.currentTrackIndex;
              
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isCurrentTrack 
                      ? AutomotiveTheme.primaryBlue.withOpacity(0.2)
                      : Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentTrack 
                        ? AutomotiveTheme.primaryBlue 
                        : Colors.grey[700]!,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    track.title,
                    style: TextStyle(
                      color: isCurrentTrack ? Colors.white : Colors.grey[300],
                      fontSize: 12,
                      fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatDuration(track.duration),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontFamily: 'DigitalNumbers',
                    ),
                  ),
                  onTap: () {
                    // TODO: Реализовать select track
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Форматирует длительность в строку MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}