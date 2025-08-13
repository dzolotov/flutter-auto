import 'package:flutter/material.dart';

import '../../../core/theme/automotive_theme.dart';

/// Дисплей для задних пассажиров
/// Развлекательный контент и управление климатом
class RearPassengerDisplay extends StatefulWidget {
  final String displayId;
  
  const RearPassengerDisplay({
    super.key,
    required this.displayId,
  });

  @override
  State<RearPassengerDisplay> createState() => _RearPassengerDisplayState();
}

class _RearPassengerDisplayState extends State<RearPassengerDisplay> {
  int _selectedTab = 0;
  
  final List<String> _tabs = ['Видео', 'Игры', 'Музыка', 'Климат', 'Настройки'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Верхняя панель с табами
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: AutomotiveTheme.gaugeGradient,
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Row(
              children: [
                // Логотип/идентификатор дисплея
                Container(
                  width: 100,
                  child: Center(
                    child: Text(
                      widget.displayId == 'rear_left' ? 'Левый' : 'Правый',
                      style: TextStyle(
                        color: AutomotiveTheme.primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Табы
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final title = entry.value;
                      final isSelected = _selectedTab == index;
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTab = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AutomotiveTheme.primaryBlue.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                                ? Border.all(color: AutomotiveTheme.primaryBlue)
                                : null,
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[400],
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Основное содержимое
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  /// Содержимое активного таба
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: return _buildVideoTab();
      case 1: return _buildGamesTab();
      case 2: return _buildMusicTab();
      case 3: return _buildClimateTab();
      case 4: return _buildSettingsTab();
      default: return _buildVideoTab();
    }
  }

  /// Видео контент
  Widget _buildVideoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Видеоплеер (заглушка)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Видеоплеер',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Подключите USB или выберите онлайн контент',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Элементы управления
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVideoControl(Icons.skip_previous),
                        _buildVideoControl(Icons.play_arrow, isMain: true),
                        _buildVideoControl(Icons.skip_next),
                        _buildVideoControl(Icons.volume_up),
                        _buildVideoControl(Icons.fullscreen),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Список доступного контента
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: AutomotiveTheme.gaugeGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Доступный контент',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildContentItem('Фильм 1', 'Боевик • 2ч 15мин', Icons.movie),
                        _buildContentItem('Мультфильм', 'Семейный • 1ч 30мин', Icons.animation),
                        _buildContentItem('Сериал 1x01', 'Драма • 45мин', Icons.tv),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Игры
  Widget _buildGamesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildGameCard('Судоку', Icons.grid_on),
          _buildGameCard('Шахматы', Icons.sports_esports),
          _buildGameCard('Пазлы', Icons.extension),
          _buildGameCard('Карточные игры', Icons.style),
          _buildGameCard('Викторина', Icons.quiz),
          _buildGameCard('Аркада', Icons.videogame_asset),
        ],
      ),
    );
  }

  /// Музыка
  Widget _buildMusicTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Текущий трек
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: AutomotiveTheme.gaugeGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.music_note, color: Colors.grey[400]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hotel California',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Eagles',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.4,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AutomotiveTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.pause, size: 28),
                      color: AutomotiveTheme.primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Плейлисты
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AutomotiveTheme.gaugeGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Плейлисты',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildPlaylistItem('Рок хиты', '25 треков'),
                        _buildPlaylistItem('Джаз классика', '18 треков'),
                        _buildPlaylistItem('Релакс', '32 трека'),
                        _buildPlaylistItem('Детские песни', '15 треков'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Климат-контроль
  Widget _buildClimateTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Температура для этой зоны
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: AutomotiveTheme.gaugeGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ТЕМПЕРАТУРА',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '22°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DigitalNumbers',
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.remove, color: Colors.blue),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.add, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Элементы управления
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildClimateControl(Icons.air, 'Обдув', false),
                _buildClimateControl(Icons.whatshot, 'Обогрев сидения', true),
                _buildClimateControl(Icons.ac_unit, 'Охлаждение', false),
                _buildClimateControl(Icons.visibility, 'Обогрев стекла', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Настройки
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingCard('Яркость экрана', '75%'),
        _buildSettingCard('Громкость', '60%'),
        _buildSettingCard('Язык', 'Русский'),
        _buildSettingCard('Время блокировки', '30 мин'),
        _buildSettingCard('Родительский контроль', 'Выкл'),
        _buildSettingCard('Уведомления', 'Вкл'),
      ],
    );
  }

  /// Кнопка управления видео
  Widget _buildVideoControl(IconData icon, {bool isMain = false}) {
    return IconButton(
      onPressed: () {},
      icon: Icon(
        icon,
        size: isMain ? 32 : 24,
        color: Colors.white,
      ),
      style: IconButton.styleFrom(
        backgroundColor: isMain 
            ? AutomotiveTheme.primaryBlue
            : Colors.grey[800],
        shape: CircleBorder(),
      ),
    );
  }

  /// Элемент контента
  Widget _buildContentItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AutomotiveTheme.primaryBlue),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      onTap: () {},
      dense: true,
    );
  }

  /// Карточка игры
  Widget _buildGameCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AutomotiveTheme.primaryBlue, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Элемент плейлиста
  Widget _buildPlaylistItem(String name, String count) {
    return ListTile(
      leading: Icon(Icons.queue_music, color: AutomotiveTheme.primaryBlue),
      title: Text(name, style: TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(count, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      onTap: () {},
      dense: true,
    );
  }

  /// Элемент управления климатом
  Widget _buildClimateControl(IconData icon, String label, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AutomotiveTheme.primaryBlue : Colors.grey[700]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AutomotiveTheme.primaryBlue : Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Карточка настройки
  Widget _buildSettingCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white)),
        trailing: Text(value, style: TextStyle(color: Colors.grey[400])),
        onTap: () {},
      ),
    );
  }
}