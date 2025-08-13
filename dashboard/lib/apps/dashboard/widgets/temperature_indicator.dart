import 'package:flutter/material.dart';
import '../../../core/theme/automotive_theme.dart';

/// Виджет индикатора температуры с линейной шкалой и цветовой индикацией
/// Используется для отображения температуры двигателя, масла и других систем
class TemperatureIndicator extends StatefulWidget {
  final String title;
  final double temperature;
  final double minTemp;
  final double maxTemp;
  final double warningTemp;
  final double dangerTemp;
  final String unit;

  const TemperatureIndicator({
    super.key,
    required this.title,
    required this.temperature,
    this.minTemp = 0.0,
    this.maxTemp = 150.0,
    this.warningTemp = 100.0,
    this.dangerTemp = 120.0,
    this.unit = '°C',
  });

  @override
  State<TemperatureIndicator> createState() => _TemperatureIndicatorState();
}

class _TemperatureIndicatorState extends State<TemperatureIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _temperatureAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _temperatureAnimation = Tween<double>(
      begin: widget.minTemp,
      end: widget.temperature,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(TemperatureIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.temperature != widget.temperature) {
      _updateTemperature();
    }
  }

  void _updateTemperature() {
    _temperatureAnimation = Tween<double>(
      begin: _temperatureAnimation.value,
      end: widget.temperature,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Заголовок
          Text(
            widget.title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Основной индикатор
          Expanded(
            child: AnimatedBuilder(
              animation: _temperatureAnimation,
              builder: (context, child) {
                final currentTemp = _temperatureAnimation.value;
                return _buildTemperatureGauge(currentTemp);
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Цифровое значение
          AnimatedBuilder(
            animation: _temperatureAnimation,
            builder: (context, child) {
              final currentTemp = _temperatureAnimation.value;
              final tempColor = _getTemperatureColor(currentTemp);
              
              return Text(
                '${currentTemp.toStringAsFixed(0)}${widget.unit}',
                style: TextStyle(
                  color: tempColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DigitalNumbers',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Создает вертикальный термометр
  Widget _buildTemperatureGauge(double temperature) {
    final normalizedTemp = (temperature - widget.minTemp) / 
                          (widget.maxTemp - widget.minTemp);
    final clampedTemp = normalizedTemp.clamp(0.0, 1.0);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Шкала с делениями
        Container(
          width: 30,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildScaleMarks(),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Основной термометр
        Container(
          width: 20,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[600]!, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              children: [
                // Фон термометра
                Container(
                  color: Colors.grey[800],
                ),
                
                // Заполнение термометра
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: clampedTemp,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: _getGradientColors(temperature),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Индикатор опасной зоны
                if (widget.dangerTemp < widget.maxTemp)
                  _buildDangerZoneIndicator(),
                
                // Индикатор предупреждающей зоны
                if (widget.warningTemp < widget.maxTemp)
                  _buildWarningZoneIndicator(),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Статус индикаторы
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildStatusIndicators(temperature),
        ),
      ],
    );
  }

  /// Создает деления шкалы
  List<Widget> _buildScaleMarks() {
    final marks = <Widget>[];
    final step = (widget.maxTemp - widget.minTemp) / 4;
    
    for (int i = 4; i >= 0; i--) {
      final temp = widget.minTemp + (step * i);
      marks.add(
        Text(
          temp.toStringAsFixed(0),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
        ),
      );
    }
    
    return marks;
  }

  /// Создает индикатор опасной зоны
  Widget _buildDangerZoneIndicator() {
    final dangerPosition = 1.0 - ((widget.dangerTemp - widget.minTemp) / 
                                 (widget.maxTemp - widget.minTemp));
    
    return Positioned(
      top: dangerPosition * 100,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: AutomotiveTheme.temperatureDanger,
      ),
    );
  }

  /// Создает индикатор предупреждающей зоны
  Widget _buildWarningZoneIndicator() {
    final warningPosition = 1.0 - ((widget.warningTemp - widget.minTemp) / 
                                   (widget.maxTemp - widget.minTemp));
    
    return Positioned(
      top: warningPosition * 100,
      left: 0,
      right: 0,
      child: Container(
        height: 1,
        color: AutomotiveTheme.temperatureWarning,
      ),
    );
  }

  /// Создает статусные индикаторы
  List<Widget> _buildStatusIndicators(double temperature) {
    final indicators = <Widget>[];
    
    if (temperature >= widget.dangerTemp) {
      indicators.add(
        Icon(
          Icons.warning,
          color: AutomotiveTheme.temperatureDanger,
          size: 16,
        ),
      );
    } else if (temperature >= widget.warningTemp) {
      indicators.add(
        Icon(
          Icons.warning_outlined,
          color: AutomotiveTheme.temperatureWarning,
          size: 16,
        ),
      );
    } else {
      indicators.add(
        Icon(
          Icons.check_circle_outline,
          color: AutomotiveTheme.successGreen,
          size: 16,
        ),
      );
    }
    
    return indicators;
  }

  /// Определяет цвет температуры
  Color _getTemperatureColor(double temperature) {
    if (temperature >= widget.dangerTemp) {
      return AutomotiveTheme.temperatureDanger;
    } else if (temperature >= widget.warningTemp) {
      return AutomotiveTheme.temperatureWarning;
    } else {
      return AutomotiveTheme.successGreen;
    }
  }

  /// Определяет градиентные цвета для термометра
  List<Color> _getGradientColors(double temperature) {
    if (temperature >= widget.dangerTemp) {
      return [
        AutomotiveTheme.temperatureDanger,
        AutomotiveTheme.temperatureWarning,
        AutomotiveTheme.successGreen,
      ];
    } else if (temperature >= widget.warningTemp) {
      return [
        AutomotiveTheme.temperatureWarning,
        AutomotiveTheme.successGreen,
      ];
    } else {
      return [
        AutomotiveTheme.successGreen,
        AutomotiveTheme.successGreen.withOpacity(0.7),
      ];
    }
  }
}