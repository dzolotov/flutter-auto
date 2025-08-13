import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/automotive_theme.dart';
import '../../../services/audio_manager.dart';

/// Виджет радиотюнера с поиском станций и управлением частотой
class RadioTuner extends StatefulWidget {
  final AudioZone zone;
  final ValueChanged<double> onFrequencyChanged;
  final ValueChanged<int> onStationChanged;

  const RadioTuner({
    super.key,
    required this.zone,
    required this.onFrequencyChanged,
    required this.onStationChanged,
  });

  @override
  State<RadioTuner> createState() => _RadioTunerState();
}

class _RadioTunerState extends State<RadioTuner>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio = widget.zone.radio;
    
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
                  Icons.radio,
                  color: AutomotiveTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'FM Радио',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                _buildSignalStrengthIndicator(radio.signalStrength),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Основной дисплей частоты
            _buildFrequencyDisplay(radio),
            
            const SizedBox(height: 24),
            
            // Слайдер настройки частоты
            _buildFrequencySlider(radio),
            
            const SizedBox(height: 24),
            
            // Кнопки управления
            _buildControlButtons(radio),
            
            const SizedBox(height: 24),
            
            // Предустановленные станции
            _buildPresetStations(radio),
          ],
        ),
      ),
    );
  }

  /// Создает дисплей частоты
  Widget _buildFrequencyDisplay(RadioState radio) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(
        children: [
          // Фон тюнера
          CustomPaint(
            painter: RadioTunerPainter(
              frequency: radio.frequency,
              scanning: _isScanning,
              animation: _scanAnimationController,
            ),
            size: Size(double.infinity, 120),
          ),
          
          // Информация о станции
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Частота
                Text(
                  '${radio.frequency.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DigitalNumbers',
                  ),
                ),
                
                Text(
                  'МГц',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Название станции
                if (radio.currentStation != null)
                  Column(
                    children: [
                      Text(
                        radio.currentStation!.name,
                        style: TextStyle(
                          color: AutomotiveTheme.primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (radio.currentStation!.genre.isNotEmpty)
                        Text(
                          radio.currentStation!.genre,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Индикатор сканирования
          if (_isScanning)
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedBuilder(
                animation: _scanAnimationController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AutomotiveTheme.accentOrange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ПОИСК',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Создает слайдер настройки частоты
  Widget _buildFrequencySlider(RadioState radio) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('87.5', style: TextStyle(color: Colors.grey[400])),
            Text('Настройка частоты', style: TextStyle(color: Colors.grey[300])),
            Text('108.0', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AutomotiveTheme.primaryBlue,
            inactiveTrackColor: Colors.grey[700],
            thumbColor: AutomotiveTheme.primaryBlue,
            overlayColor: AutomotiveTheme.primaryBlue.withOpacity(0.2),
            trackHeight: 6,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: radio.frequency,
            min: 87.5,
            max: 108.0,
            divisions: 205, // Шаг 0.1 МГц
            onChanged: _isScanning ? null : widget.onFrequencyChanged,
          ),
        ),
      ],
    );
  }

  /// Создает кнопки управления
  Widget _buildControlButtons(RadioState radio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Поиск назад
        ElevatedButton.icon(
          onPressed: _isScanning ? null : _seekBackward,
          icon: Icon(Icons.fast_rewind),
          label: Text('ПОИСК ←'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
          ),
        ),
        
        // Автопоиск
        ElevatedButton.icon(
          onPressed: _toggleScan,
          icon: Icon(_isScanning ? Icons.stop : Icons.search),
          label: Text(_isScanning ? 'СТОП' : 'АВТО'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isScanning 
                ? AutomotiveTheme.warningRed 
                : AutomotiveTheme.primaryBlue,
            foregroundColor: Colors.white,
          ),
        ),
        
        // Поиск вперед
        ElevatedButton.icon(
          onPressed: _isScanning ? null : _seekForward,
          icon: Icon(Icons.fast_forward),
          label: Text('ПОИСК →'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Создает индикатор силы сигнала
  Widget _buildSignalStrengthIndicator(double strength) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Сигнал',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final barHeight = 4.0 + (index * 3.0);
          final isActive = strength >= (index + 1) / 5.0;
          
          return Container(
            width: 3,
            height: barHeight,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: isActive 
                  ? (strength > 0.7 
                      ? AutomotiveTheme.successGreen 
                      : AutomotiveTheme.accentOrange)
                  : Colors.grey[700],
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ],
    );
  }

  /// Создает предустановленные станции
  Widget _buildPresetStations(RadioState radio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Предустановки',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        const SizedBox(height: 12),
        
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: radio.stations.length,
            itemBuilder: (context, index) {
              final station = radio.stations[index];
              final isSelected = index == radio.currentStationIndex;
              
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => widget.onStationChanged(index),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AutomotiveTheme.primaryBlue.withOpacity(0.2)
                          : Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? AutomotiveTheme.primaryBlue 
                            : Colors.grey[700]!,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${(index + 1)}',
                              style: TextStyle(
                                color: isSelected 
                                    ? AutomotiveTheme.primaryBlue 
                                    : Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            _buildSignalStrengthMini(station.signalStrength),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          '${station.frequency.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DigitalNumbers',
                          ),
                        ),
                        
                        Text(
                          station.name,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  /// Создает мини индикатор силы сигнала
  Widget _buildSignalStrengthMini(double strength) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = strength >= (index + 1) / 3.0;
        return Container(
          width: 2,
          height: 3.0 + (index * 1.5),
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: isActive ? AutomotiveTheme.successGreen : Colors.grey[700],
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  /// Поиск назад
  void _seekBackward() {
    final currentFreq = widget.zone.radio.frequency;
    final newFreq = math.max(87.5, currentFreq - 0.2);
    widget.onFrequencyChanged(newFreq);
  }

  /// Поиск вперед
  void _seekForward() {
    final currentFreq = widget.zone.radio.frequency;
    final newFreq = math.min(108.0, currentFreq + 0.2);
    widget.onFrequencyChanged(newFreq);
  }

  /// Переключение автопоиска
  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
    });
    
    if (_isScanning) {
      _scanAnimationController.repeat();
      _startAutoScan();
    } else {
      _scanAnimationController.stop();
    }
  }

  /// Запуск автопоиска станций
  void _startAutoScan() async {
    if (!_isScanning) return;
    
    const scanStep = 0.1;
    var currentFreq = widget.zone.radio.frequency;
    
    while (_isScanning && currentFreq <= 108.0) {
      await Future.delayed(Duration(milliseconds: 100));
      
      if (!_isScanning) break;
      
      currentFreq += scanStep;
      widget.onFrequencyChanged(currentFreq);
      
      // Симуляция обнаружения станции
      final random = math.Random();
      if (random.nextDouble() > 0.95) {
        // Найдена станция
        setState(() {
          _isScanning = false;
        });
        _scanAnimationController.stop();
        break;
      }
    }
    
    // Если дошли до конца диапазона
    if (currentFreq > 108.0 && _isScanning) {
      setState(() {
        _isScanning = false;
      });
      _scanAnimationController.stop();
      widget.onFrequencyChanged(87.5); // Возврат к началу
    }
  }
}

/// Кастомный рисовальщик для тюнера
class RadioTunerPainter extends CustomPainter {
  final double frequency;
  final bool scanning;
  final AnimationController animation;

  RadioTunerPainter({
    required this.frequency,
    required this.scanning,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Рисуем шкалу частот
    _drawFrequencyScale(canvas, size);
    
    // Рисуем указатель текущей частоты
    _drawFrequencyIndicator(canvas, size);
    
    // Рисуем эффект сканирования
    if (scanning) {
      _drawScanEffect(canvas, size);
    }
  }

  void _drawFrequencyScale(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;

    final step = size.width / 21; // 87.5 - 108.0 = 20.5, делим на 21 деление
    
    for (int i = 0; i <= 20; i++) {
      final x = i * step;
      final freq = 87.5 + (i * 1.0);
      
      // Большие деления каждые 5 МГц
      final isMainMark = freq % 5 == 0;
      final markHeight = isMainMark ? 15.0 : 8.0;
      
      canvas.drawLine(
        Offset(x, size.height - markHeight),
        Offset(x, size.height),
        paint,
      );
      
      // Подписи частот
      if (isMainMark) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: freq.toStringAsFixed(0),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - 25),
        );
      }
    }
  }

  void _drawFrequencyIndicator(Canvas canvas, Size size) {
    final position = ((frequency - 87.5) / 20.5) * size.width;
    
    final paint = Paint()
      ..color = AutomotiveTheme.primaryBlue
      ..strokeWidth = 3;

    // Вертикальная линия указателя
    canvas.drawLine(
      Offset(position, 0),
      Offset(position, size.height - 30),
      paint,
    );
    
    // Треугольный указатель
    final path = Path();
    path.moveTo(position - 8, 0);
    path.lineTo(position + 8, 0);
    path.lineTo(position, 12);
    path.close();
    
    canvas.drawPath(path, Paint()..color = AutomotiveTheme.primaryBlue);
  }

  void _drawScanEffect(Canvas canvas, Size size) {
    final scanPosition = animation.value * size.width;
    
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        AutomotiveTheme.accentOrange.withOpacity(0.5),
        Colors.transparent,
      ],
      stops: [0.0, 0.5, 1.0],
    );
    
    final rect = Rect.fromLTWH(scanPosition - 20, 0, 40, size.height);
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant RadioTunerPainter oldDelegate) {
    return oldDelegate.frequency != frequency ||
           oldDelegate.scanning != scanning;
  }
}