import 'package:flutter/material.dart';

import '../../../core/theme/automotive_theme.dart';
import '../../../services/display_manager.dart';

/// Панель конфигурации дисплеев
/// Позволяет настраивать параметры каждого дисплея в системе
class DisplayConfigurationPanel extends StatefulWidget {
  final List<DisplayInfo> displays;

  const DisplayConfigurationPanel({
    super.key,
    required this.displays,
  });

  @override
  State<DisplayConfigurationPanel> createState() => _DisplayConfigurationPanelState();
}

class _DisplayConfigurationPanelState extends State<DisplayConfigurationPanel> {
  int _selectedDisplayIndex = 0;
  
  // Настройки для каждого дисплея
  Map<String, Map<String, dynamic>> _displaySettings = {};

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  /// Инициализация настроек
  void _initializeSettings() {
    for (final display in widget.displays) {
      _displaySettings[display.id] = {
        'brightness': 0.8,
        'contrast': 0.5,
        'saturation': 0.5,
        'rotation': 0,
        'mirror': false,
        'nightMode': false,
        'autoAdjust': true,
        'resolution': display.resolution,
        'refreshRate': 60,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Заголовок
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                Icons.settings,
                color: AutomotiveTheme.primaryBlue,
                size: 32,
              ),
              const SizedBox(width: 16),
              Text(
                'Конфигурация дисплеев',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close),
              ),
            ],
          ),
        ),
        
        Divider(color: Colors.grey[700]),
        
        // Основное содержимое
        Expanded(
          child: Row(
            children: [
              // Список дисплеев
              Container(
                width: 250,
                child: _buildDisplayList(),
              ),
              
              VerticalDivider(color: Colors.grey[700]),
              
              // Настройки выбранного дисплея
              Expanded(
                child: _buildDisplaySettings(),
              ),
            ],
          ),
        ),
        
        // Кнопки действий
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _resetToDefaults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                ),
                child: Text('Сбросить'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _testConfiguration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AutomotiveTheme.accentOrange,
                ),
                child: Text('Тестировать'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _applySettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AutomotiveTheme.primaryBlue,
                ),
                child: Text('Применить'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Список дисплеев
  Widget _buildDisplayList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Дисплеи',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: widget.displays.length,
            itemBuilder: (context, index) {
              final display = widget.displays[index];
              final isSelected = _selectedDisplayIndex == index;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: ListTile(
                  selected: isSelected,
                  selectedTileColor: AutomotiveTheme.primaryBlue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected 
                          ? AutomotiveTheme.primaryBlue 
                          : Colors.transparent,
                    ),
                  ),
                  leading: Icon(
                    display.icon,
                    color: isSelected 
                        ? AutomotiveTheme.primaryBlue 
                        : Colors.grey[400],
                  ),
                  title: Text(
                    display.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    display.resolution,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AutomotiveTheme.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => setState(() => _selectedDisplayIndex = index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Настройки выбранного дисплея
  Widget _buildDisplaySettings() {
    final selectedDisplay = widget.displays[_selectedDisplayIndex];
    final settings = _displaySettings[selectedDisplay.id]!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок дисплея
          Row(
            children: [
              Icon(
                selectedDisplay.icon,
                color: AutomotiveTheme.primaryBlue,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedDisplay.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    selectedDisplay.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Основные настройки
          _buildSettingsSection(
            'Основные параметры',
            [
              _buildSliderSetting(
                'Яркость',
                settings['brightness'],
                0.0,
                1.0,
                (value) => _updateSetting('brightness', value),
              ),
              _buildSliderSetting(
                'Контрастность',
                settings['contrast'],
                0.0,
                1.0,
                (value) => _updateSetting('contrast', value),
              ),
              _buildSliderSetting(
                'Насыщенность',
                settings['saturation'],
                0.0,
                1.0,
                (value) => _updateSetting('saturation', value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Ориентация и поворот
          _buildSettingsSection(
            'Ориентация',
            [
              _buildRotationSelector(settings['rotation']),
              _buildSwitchSetting(
                'Зеркальное отображение',
                settings['mirror'],
                (value) => _updateSetting('mirror', value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Режимы отображения
          _buildSettingsSection(
            'Режимы',
            [
              _buildSwitchSetting(
                'Ночной режим',
                settings['nightMode'],
                (value) => _updateSetting('nightMode', value),
              ),
              _buildSwitchSetting(
                'Автоматическая настройка',
                settings['autoAdjust'],
                (value) => _updateSetting('autoAdjust', value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Технические параметры
          _buildSettingsSection(
            'Технические параметры',
            [
              _buildDropdownSetting(
                'Разрешение',
                settings['resolution'],
                ['1920x1080', '1920x720', '1280x800', '800x480'],
                (value) => _updateSetting('resolution', value),
              ),
              _buildDropdownSetting(
                'Частота обновления',
                '${settings['refreshRate']} Гц',
                ['60 Гц', '75 Гц', '120 Гц'],
                (value) => _updateSetting('refreshRate', 
                    int.parse(value.split(' ')[0])),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Информация о дисплее
          _buildDisplayInfo(selectedDisplay, settings),
        ],
      ),
    );
  }

  /// Секция настроек
  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AutomotiveTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  /// Настройка со слайдером
  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[300])),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AutomotiveTheme.primaryBlue,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: AutomotiveTheme.primaryBlue,
              overlayColor: AutomotiveTheme.primaryBlue.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Настройка с переключателем
  Widget _buildSwitchSetting(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[300])),
          Switch(
            value: value,
            activeColor: AutomotiveTheme.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Селектор поворота
  Widget _buildRotationSelector(int rotation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Поворот экрана', style: TextStyle(color: Colors.grey[300])),
          const SizedBox(height: 8),
          Row(
            children: [0, 90, 180, 270].map((angle) {
              final isSelected = rotation == angle;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _updateSetting('rotation', angle),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AutomotiveTheme.primaryBlue.withOpacity(0.3)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? AutomotiveTheme.primaryBlue 
                            : Colors.grey[600]!,
                      ),
                    ),
                    child: Text(
                      '${angle}°',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Настройка с выпадающим списком
  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[300])),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
            ),
            dropdownColor: Colors.grey[800],
            style: TextStyle(color: Colors.white),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }

  /// Информация о дисплее
  Widget _buildDisplayInfo(DisplayInfo display, Map<String, dynamic> settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация о дисплее',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Тип', display.type.displayName),
          _buildInfoRow('ID', display.id),
          _buildInfoRow('Текущее разрешение', settings['resolution']),
          _buildInfoRow('Частота обновления', '${settings['refreshRate']} Гц'),
          _buildInfoRow('Статус', 'Активен'),
          _buildInfoRow('Использование памяти', '128 МБ'),
        ],
      ),
    );
  }

  /// Строка информации
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Обновление настройки
  void _updateSetting(String key, dynamic value) {
    setState(() {
      final selectedDisplay = widget.displays[_selectedDisplayIndex];
      _displaySettings[selectedDisplay.id]![key] = value;
    });
  }

  /// Сброс к настройкам по умолчанию
  void _resetToDefaults() {
    setState(() {
      _initializeSettings();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Настройки сброшены к значениям по умолчанию')),
    );
  }

  /// Тестирование конфигурации
  void _testConfiguration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AutomotiveTheme.cardDark,
        title: Text('Тестирование конфигурации'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Конфигурация будет применена на 10 секунд для тестирования.'),
            const SizedBox(height: 16),
            LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
        ],
      ),
    );
    
    // Симуляция тестирования
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Тестирование завершено')),
      );
    });
  }

  /// Применение настроек
  void _applySettings() {
    // В реальном приложении здесь была бы логика применения настроек
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Настройки успешно применены')),
    );
    Navigator.of(context).pop();
  }
}