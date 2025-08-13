import 'package:flutter/material.dart';
import '../../../core/theme/automotive_theme.dart';
import '../../../services/audio_manager.dart';

/// Виджет панели эквалайзера с регулировкой частотных полос
class EqualizerPanel extends StatefulWidget {
  final AudioZone zone;
  final ValueChanged<EqualizerSettings> onEqualizerChanged;

  const EqualizerPanel({
    super.key,
    required this.zone,
    required this.onEqualizerChanged,
  });

  @override
  State<EqualizerPanel> createState() => _EqualizerPanelState();
}

class _EqualizerPanelState extends State<EqualizerPanel> {
  String _selectedPreset = 'Пользовательский';
  Map<String, double> _currentBands = {};

  // Предустановки эквалайзера
  static const Map<String, Map<String, double>> _presets = {
    'Выкл': {
      '60Hz': 0.0, '170Hz': 0.0, '310Hz': 0.0, '600Hz': 0.0, '1kHz': 0.0,
      '3kHz': 0.0, '6kHz': 0.0, '12kHz': 0.0, '14kHz': 0.0, '16kHz': 0.0,
    },
    'Рок': {
      '60Hz': 4.0, '170Hz': 3.0, '310Hz': -1.0, '600Hz': -2.0, '1kHz': 1.0,
      '3kHz': 3.0, '6kHz': 4.0, '12kHz': 5.0, '14kHz': 5.0, '16kHz': 5.0,
    },
    'Поп': {
      '60Hz': 1.0, '170Hz': 2.0, '310Hz': 3.0, '600Hz': 2.0, '1kHz': 0.0,
      '3kHz': -1.0, '6kHz': -1.0, '12kHz': 1.0, '14kHz': 2.0, '16kHz': 2.0,
    },
    'Джаз': {
      '60Hz': 2.0, '170Hz': 1.0, '310Hz': 1.0, '600Hz': 2.0, '1kHz': -1.0,
      '3kHz': -1.0, '6kHz': 0.0, '12kHz': 1.0, '14kHz': 2.0, '16kHz': 2.0,
    },
    'Классика': {
      '60Hz': 3.0, '170Hz': 2.0, '310Hz': -1.0, '600Hz': -1.0, '1kHz': 0.0,
      '3kHz': 1.0, '6kHz': 2.0, '12kHz': 3.0, '14kHz': 4.0, '16kHz': 4.0,
    },
    'Вокал': {
      '60Hz': -2.0, '170Hz': -1.0, '310Hz': 1.0, '600Hz': 2.0, '1kHz': 3.0,
      '3kHz': 3.0, '6kHz': 2.0, '12kHz': 1.0, '14kHz': 0.0, '16kHz': -1.0,
    },
    'Электронная': {
      '60Hz': 5.0, '170Hz': 4.0, '310Hz': 1.0, '600Hz': 0.0, '1kHz': -1.0,
      '3kHz': 1.0, '6kHz': 2.0, '12kHz': 4.0, '14kHz': 5.0, '16kHz': 6.0,
    },
  };

  @override
  void initState() {
    super.initState();
    _currentBands = Map.from(widget.zone.equalizer.bands);
    _selectedPreset = widget.zone.equalizer.preset;
  }

  @override
  Widget build(BuildContext context) {
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
                  Icons.equalizer,
                  color: AutomotiveTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Эквалайзер',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  _selectedPreset,
                  style: TextStyle(
                    color: AutomotiveTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Предустановки
            _buildPresetSelector(),
            
            const SizedBox(height: 24),
            
            // Эквалайзер
            _buildEqualizerBands(),
            
            const SizedBox(height: 24),
            
            // Дополнительные настройки
            _buildAudioEffects(),
          ],
        ),
      ),
    );
  }

  /// Создает селектор предустановок
  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Предустановки',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        const SizedBox(height: 12),
        
        Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.keys.length,
            itemBuilder: (context, index) {
              final presetName = _presets.keys.elementAt(index);
              final isSelected = _selectedPreset == presetName;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _selectPreset(presetName),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AutomotiveTheme.primaryBlue.withOpacity(0.3)
                          : Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? AutomotiveTheme.primaryBlue 
                            : Colors.grey[700]!,
                      ),
                    ),
                    child: Text(
                      presetName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Создает полосы эквалайзера
  Widget _buildEqualizerBands() {
    final frequencies = _currentBands.keys.toList();
    
    return Column(
      children: [
        Text(
          'Частотные полосы',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        const SizedBox(height: 16),
        
        Container(
          height: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: frequencies.map((freq) {
              return _buildFrequencySlider(freq, _currentBands[freq]!);
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Подписи частот
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: frequencies.map((freq) {
            return Text(
              freq,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Создает слайдер для частотной полосы
  Widget _buildFrequencySlider(String frequency, double value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Значение в дБ
        Container(
          width: 24,
          height: 20,
          child: Text(
            value >= 0 ? '+${value.toStringAsFixed(0)}' : value.toStringAsFixed(0),
            style: TextStyle(
              color: value == 0 
                  ? Colors.grey[400] 
                  : (value > 0 
                      ? AutomotiveTheme.successGreen 
                      : AutomotiveTheme.warningRed),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Вертикальный слайдер
        Container(
          height: 200,
          width: 30,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getSliderColor(value),
                inactiveTrackColor: Colors.grey[700],
                thumbColor: _getSliderColor(value),
                overlayColor: _getSliderColor(value).withOpacity(0.2),
                trackHeight: 4,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                min: -12.0,
                max: 12.0,
                divisions: 48, // Шаг 0.5 дБ
                onChanged: (newValue) {
                  _updateBand(frequency, newValue);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Создает дополнительные аудиоэффекты
  Widget _buildAudioEffects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Звуковые эффекты',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(child: _buildBassBoostControl()),
            const SizedBox(width: 16),
            Expanded(child: _buildVirtualSurroundControl()),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(child: _buildLoudnessControl()),
            const SizedBox(width: 16),
            Expanded(child: _buildDialogEnhancerControl()),
          ],
        ),
      ],
    );
  }

  /// Создает регулятор усиления басов
  Widget _buildBassBoostControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Бас',
                style: TextStyle(color: Colors.grey[300]),
              ),
              Text(
                '+3дБ',
                style: TextStyle(
                  color: AutomotiveTheme.primaryBlue,
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
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: 0.3,
              onChanged: (value) {
                // TODO: Реализовать bass boost
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Создает регулятор виртуального окружения
  Widget _buildVirtualSurroundControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Окружение',
                style: TextStyle(color: Colors.grey[300]),
              ),
              Text(
                '50%',
                style: TextStyle(
                  color: AutomotiveTheme.accentOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AutomotiveTheme.accentOrange,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: AutomotiveTheme.accentOrange,
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: 0.5,
              onChanged: (value) {
                // TODO: Реализовать virtual surround
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Создает переключатель Loudness
  Widget _buildLoudnessControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Loudness',
            style: TextStyle(color: Colors.grey[300]),
          ),
          Switch(
            value: true,
            activeColor: AutomotiveTheme.successGreen,
            onChanged: (value) {
              // TODO: Реализовать loudness
            },
          ),
        ],
      ),
    );
  }

  /// Создает усилитель диалога
  Widget _buildDialogEnhancerControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Диалог',
            style: TextStyle(color: Colors.grey[300]),
          ),
          Switch(
            value: false,
            activeColor: AutomotiveTheme.successGreen,
            onChanged: (value) {
              // TODO: Реализовать dialog enhancer
            },
          ),
        ],
      ),
    );
  }

  /// Выбор предустановки
  void _selectPreset(String presetName) {
    setState(() {
      _selectedPreset = presetName;
      _currentBands = Map.from(_presets[presetName]!);
    });
    
    _notifyEqualizerChanged();
  }

  /// Обновление полосы частот
  void _updateBand(String frequency, double value) {
    setState(() {
      _currentBands[frequency] = value;
      _selectedPreset = 'Пользовательский';
    });
    
    _notifyEqualizerChanged();
  }

  /// Уведомление об изменении эквалайзера
  void _notifyEqualizerChanged() {
    final settings = EqualizerSettings(
      bands: _currentBands,
      preset: _selectedPreset,
    );
    
    widget.onEqualizerChanged(settings);
  }

  /// Определяет цвет слайдера в зависимости от значения
  Color _getSliderColor(double value) {
    if (value == 0) {
      return Colors.grey[500]!;
    } else if (value > 0) {
      return AutomotiveTheme.successGreen;
    } else {
      return AutomotiveTheme.warningRed;
    }
  }
}