import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio_manager.dart';
import '../../core/theme/automotive_theme.dart';
import 'widgets/audio_zone_control.dart';
import 'widgets/source_selector.dart';
import 'widgets/equalizer_panel.dart';
import 'widgets/media_player_widget.dart';
import 'widgets/radio_tuner.dart';

/// Основное приложение мультимедийной системы
/// Управляет аудиозонами, источниками звука и настройками эквалайзера
class MultimediaApp extends ConsumerStatefulWidget {
  const MultimediaApp({super.key});

  @override
  ConsumerState<MultimediaApp> createState() => _MultimediaAppState();
}

class _MultimediaAppState extends ConsumerState<MultimediaApp>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedZone = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Инициализация аудиосистемы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioManagerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioManagerProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Мультимедийная система'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AutomotiveTheme.primaryBlue,
          tabs: [
            Tab(icon: Icon(Icons.library_music), text: 'Медиа'),
            Tab(icon: Icon(Icons.radio), text: 'Радио'),
            Tab(icon: Icon(Icons.equalizer), text: 'Эквалайзер'),
            Tab(icon: Icon(Icons.settings), text: 'Настройки'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AutomotiveTheme.dashboardGradient,
        ),
        child: Column(
          children: [
            // Верхняя панель с выбором аудиозоны
            Container(
              height: 80,
              padding: const EdgeInsets.all(16),
              child: _buildZoneSelector(audioState),
            ),
            
            // Основное содержимое
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMediaTab(audioState),
                  _buildRadioTab(audioState),
                  _buildEqualizerTab(audioState),
                  _buildSettingsTab(audioState),
                ],
              ),
            ),
            
            // Нижняя панель с быстрым управлением
            Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              child: _buildQuickControls(audioState),
            ),
          ],
        ),
      ),
    );
  }

  /// Создает селектор аудиозон
  Widget _buildZoneSelector(AudioSystemState audioState) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: audioState.zones.length,
              itemBuilder: (context, index) {
                final zone = audioState.zones[index];
                final isSelected = _selectedZone == index;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildZoneCard(zone, isSelected, () {
                    setState(() {
                      _selectedZone = index;
                    });
                  }),
                );
              },
            ),
          ),
          
          // Общие элементы управления
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Общий',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => _toggleMuteAll(audioState),
                      icon: Icon(
                        audioState.globalMute ? Icons.volume_off : Icons.volume_up,
                        color: audioState.globalMute ? Colors.red : Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _showGlobalVolumeDialog,
                      icon: Icon(Icons.tune, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Создает карточку аудиозоны
  Widget _buildZoneCard(AudioZone zone, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 100,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected 
              ? AutomotiveTheme.primaryBlue.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AutomotiveTheme.primaryBlue 
                : Colors.grey[600]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getZoneIcon(zone.name),
              color: isSelected ? AutomotiveTheme.primaryBlue : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              zone.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Возвращает иконку для зоны
  IconData _getZoneIcon(String zoneName) {
    switch (zoneName.toLowerCase()) {
      case 'водитель': return Icons.airline_seat_recline_normal;
      case 'пассажир': return Icons.airline_seat_recline_extra;
      case 'задние': return Icons.airline_seat_recline_normal;
      case 'общий': return Icons.volume_up;
      default: return Icons.speaker;
    }
  }

  /// Создает вкладку медиаплеера
  Widget _buildMediaTab(AudioSystemState audioState) {
    final currentZone = audioState.zones[_selectedZone];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Управление источником
          SourceSelector(
            zone: currentZone,
            onSourceChanged: (source) {
              ref.read(audioManagerProvider.notifier)
                 .setZoneSource(_selectedZone, source);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Медиаплеер
          MediaPlayerWidget(zone: currentZone),
          
          const SizedBox(height: 16),
          
          // Управление зоной
          AudioZoneControl(
            zone: currentZone,
            onVolumeChanged: (volume) {
              ref.read(audioManagerProvider.notifier)
                 .setZoneVolume(_selectedZone, volume);
            },
            onBalanceChanged: (balance) {
              ref.read(audioManagerProvider.notifier)
                 .setZoneBalance(_selectedZone, balance);
            },
          ),
        ],
      ),
    );
  }

  /// Создает вкладку радио
  Widget _buildRadioTab(AudioSystemState audioState) {
    final currentZone = audioState.zones[_selectedZone];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Тюнер радио
          RadioTuner(
            zone: currentZone,
            onFrequencyChanged: (frequency) {
              ref.read(audioManagerProvider.notifier)
                 .setRadioFrequency(_selectedZone, frequency);
            },
            onStationChanged: (station) {
              ref.read(audioManagerProvider.notifier)
                 .setRadioStation(_selectedZone, station);
            },
          ),
        ],
      ),
    );
  }

  /// Создает вкладку эквалайзера
  Widget _buildEqualizerTab(AudioSystemState audioState) {
    final currentZone = audioState.zones[_selectedZone];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          EqualizerPanel(
            zone: currentZone,
            onEqualizerChanged: (eq) {
              ref.read(audioManagerProvider.notifier)
                 .setZoneEqualizer(_selectedZone, eq);
            },
          ),
        ],
      ),
    );
  }

  /// Создает вкладку настроек
  Widget _buildSettingsTab(AudioSystemState audioState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(
            title: 'Автоматическое включение',
            subtitle: 'Включать звук при запуске двигателя',
            value: audioState.autoStart,
            onChanged: (value) {
              ref.read(audioManagerProvider.notifier).setAutoStart(value);
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard(
            title: 'Адаптивная громкость',
            subtitle: 'Автоматически регулировать громкость по скорости',
            value: audioState.speedVolumeAdaptation,
            onChanged: (value) {
              ref.read(audioManagerProvider.notifier).setSpeedVolumeAdaptation(value);
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard(
            title: 'Приоритет навигации',
            subtitle: 'Автоматически снижать громкость для голосовых подсказок',
            value: audioState.navigationPriority,
            onChanged: (value) {
              ref.read(audioManagerProvider.notifier).setNavigationPriority(value);
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard(
            title: 'Звуки системы',
            subtitle: 'Воспроизводить звуки уведомлений и предупреждений',
            value: audioState.systemSounds,
            onChanged: (value) {
              ref.read(audioManagerProvider.notifier).setSystemSounds(value);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Кнопки сброса настроек
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _resetZoneSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                  child: Text('Сбросить зону'),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _resetAllSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AutomotiveTheme.warningRed,
                  ),
                  child: Text('Сбросить всё'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Создает карточку настройки
  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title, style: TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
        value: value,
        onChanged: onChanged,
        activeColor: AutomotiveTheme.primaryBlue,
      ),
    );
  }

  /// Создает панель быстрого управления
  Widget _buildQuickControls(AudioSystemState audioState) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Предыдущий трек
          _buildControlButton(
            Icons.skip_previous,
            'Предыдущий',
            () => _previousTrack(),
          ),
          
          // Воспроизведение/пауза
          _buildControlButton(
            audioState.isPlaying ? Icons.pause : Icons.play_arrow,
            audioState.isPlaying ? 'Пауза' : 'Играть',
            () => _togglePlayPause(),
            isMain: true,
          ),
          
          // Следующий трек
          _buildControlButton(
            Icons.skip_next,
            'Следующий',
            () => _nextTrack(),
          ),
          
          const SizedBox(width: 24),
          
          // Общая громкость
          Expanded(
            child: Column(
              children: [
                Text(
                  'Громкость: ${(audioState.globalVolume * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Slider(
                  value: audioState.globalVolume,
                  onChanged: (value) {
                    ref.read(audioManagerProvider.notifier).setGlobalVolume(value);
                  },
                  activeColor: AutomotiveTheme.primaryBlue,
                  inactiveColor: Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Создает кнопку управления
  Widget _buildControlButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool isMain = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: isMain ? 36 : 24,
            ),
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: isMain 
                  ? AutomotiveTheme.primaryBlue.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          Text(
            tooltip,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Переключение воспроизведения/паузы
  void _togglePlayPause() {
    ref.read(audioManagerProvider.notifier).togglePlayPause(_selectedZone);
  }

  /// Предыдущий трек
  void _previousTrack() {
    ref.read(audioManagerProvider.notifier).previousTrack(_selectedZone);
  }

  /// Следующий трек
  void _nextTrack() {
    ref.read(audioManagerProvider.notifier).nextTrack(_selectedZone);
  }

  /// Переключение общего mute
  void _toggleMuteAll(AudioSystemState audioState) {
    ref.read(audioManagerProvider.notifier).setGlobalMute(!audioState.globalMute);
  }

  /// Показать диалог общей громкости
  void _showGlobalVolumeDialog() {
    showDialog(
      context: context,
      builder: (context) => _GlobalVolumeDialog(),
    );
  }

  /// Сброс настроек зоны
  void _resetZoneSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сброс настроек зоны'),
        content: Text('Сбросить все настройки текущей аудиозоны?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(audioManagerProvider.notifier).resetZone(_selectedZone);
              Navigator.of(context).pop();
            },
            child: Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  /// Сброс всех настроек
  void _resetAllSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сброс всех настроек'),
        content: Text('Сбросить все настройки аудиосистемы к заводским?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(audioManagerProvider.notifier).resetAll();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AutomotiveTheme.warningRed,
            ),
            child: Text('Сбросить всё'),
          ),
        ],
      ),
    );
  }
}

/// Диалог управления общей громкостью
class _GlobalVolumeDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioManagerProvider);
    
    return AlertDialog(
      title: Text('Общая громкость'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Громкость: ${(audioState.globalVolume * 100).toInt()}%'),
          Slider(
            value: audioState.globalVolume,
            onChanged: (value) {
              ref.read(audioManagerProvider.notifier).setGlobalVolume(value);
            },
          ),
          
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: Text('Отключить звук'),
            value: audioState.globalMute,
            onChanged: (value) {
              ref.read(audioManagerProvider.notifier).setGlobalMute(value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Закрыть'),
        ),
      ],
    );
  }
}