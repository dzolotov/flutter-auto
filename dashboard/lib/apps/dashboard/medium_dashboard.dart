import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../core/theme/automotive_theme.dart';
import '../../services/can_bus_provider.dart';
import '../../services/audio_service.dart';

/// Основной дэшборд автомобиля с неоновым дизайном
/// Оптимизирован для экрана 800x480 и работы на Raspberry Pi через flutter-pi
class MediumDashboard extends ConsumerWidget {
  const MediumDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canData = ref.watch(canBusProvider);
    
    return Scaffold(
      backgroundColor: AutomotiveTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: AutomotiveTheme.dashboardGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Верхний ряд - основные приборы
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      // Спидометр
                      Expanded(
                        child: _buildEnhancedGauge(
                          title: 'СКОРОСТЬ',
                          value: (canData['speed'] ?? 0.0).toDouble(),
                          maxValue: 240,
                          unit: 'км/ч',
                          primaryColor: AutomotiveTheme.primaryBlue,
                          dangerZone: 180,
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Центральная информация
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildGearIndicator(_getGearFromCAN(canData)),
                            const SizedBox(height: 16),
                            _buildInfoPanel(canData),
                            const SizedBox(height: 12),
                            _buildMusicButton(ref),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Тахометр
                      Expanded(
                        child: _buildEnhancedGauge(
                          title: 'ОБОРОТЫ',
                          value: (canData['rpm'] ?? 0.0).toDouble(),
                          maxValue: 8000,
                          unit: 'RPM',
                          primaryColor: AutomotiveTheme.primaryCyan,
                          dangerZone: 6500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Нижняя панель с индикаторами
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      _buildBottomIndicator(
                        Icons.local_gas_station,
                        '${(canData['fuel_level'] ?? 65.0).toInt()}%',
                        'ТОПЛИВО',
                        AutomotiveTheme.successGreen,
                        (canData['fuel_level'] ?? 100) < 15,
                      ),
                      _buildBottomIndicator(
                        Icons.thermostat,
                        '${(canData['engine_temp'] ?? 90.0).toInt()}°C',
                        'ТЕМП.',
                        AutomotiveTheme.accentOrange,
                        (canData['engine_temp'] ?? 90) > 100,
                      ),
                      _buildBottomIndicator(
                        Icons.speed,
                        '${canData['odometer']?.toInt() ?? 45623} км',
                        'ПРОБЕГ',
                        AutomotiveTheme.accentPurple,
                        false,
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

  Widget _buildEnhancedGauge({
    required String title,
    required double value,
    required double maxValue,
    required String unit,
    required Color primaryColor,
    required double dangerZone,
  }) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    final isDanger = value >= dangerZone;
    final displayColor = isDanger ? AutomotiveTheme.warningRed : primaryColor;
    
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            displayColor.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: displayColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: displayColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          
          // Круговой индикатор
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: SimpleGaugePainter(
                value: percentage,
                color: displayColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unit == 'x1000' 
                        ? (value / 1000).toStringAsFixed(1)
                        : value.toInt().toString(),
                      style: TextStyle(
                        color: displayColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: displayColor.withOpacity(0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGearIndicator(String gear) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AutomotiveTheme.surfaceDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AutomotiveTheme.accentPurple.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AutomotiveTheme.accentPurple.withOpacity(0.3),
            blurRadius: 15,
          ),
        ],
      ),
      child: Center(
        child: Text(
          gear,
          style: TextStyle(
            color: AutomotiveTheme.accentPurple,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AutomotiveTheme.accentPurple.withOpacity(0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(Map<String, dynamic> canData) {
    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AutomotiveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[700]!.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _buildMiniInfo('ГАЗ', '${(canData['throttle'] ?? 0.0).toInt()}%')),
              Expanded(child: _buildMiniInfo('LOAD', '${(canData['engine_load'] ?? 0.0).toInt()}%')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildMiniInfo('MODE', canData['is_connected'] == true ? 'CAN' : 'SIM')),
              Expanded(child: _buildMiniInfo('LINK', canData['is_connected'] == true ? 'VCAN0' : 'OK')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 6,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: TextStyle(
            color: AutomotiveTheme.primaryCyan,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomIndicator(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isWarning,
  ) {
    final displayColor = isWarning ? AutomotiveTheme.warningRed : color;
    
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AutomotiveTheme.surfaceDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: displayColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: displayColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Создает кнопку управления музыкой
  Widget _buildMusicButton(WidgetRef ref) {
    final audioState = ref.watch(audioServiceProvider);
    final audioService = ref.read(audioServiceProvider.notifier);
    
    IconData icon;
    String label;
    Color color;
    
    switch (audioState.runtimeType) {
      case AudioStateStopped:
        icon = Icons.music_note;
        label = 'МУЗЫКА';
        color = AutomotiveTheme.successGreen;
        break;
      case AudioStateLoading:
        icon = Icons.hourglass_empty;
        label = 'ЗАГРУЗКА';
        color = AutomotiveTheme.accentOrange;
        break;
      case AudioStatePlaying:
        icon = Icons.music_off;
        label = 'СТОП';
        color = AutomotiveTheme.warningRed;
        break;
      default:
        icon = Icons.music_note;
        label = 'МУЗЫКА';
        color = AutomotiveTheme.successGreen;
        break;
    }
    
    return Expanded(
      child: GestureDetector(
        onTap: audioState is AudioStateLoading ? null : () {
          audioService.toggleMusic();
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audioState is AudioStatePlaying ? '♪ ON' : 'OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Простой painter для круговых индикаторов
class SimpleGaugePainter extends CustomPainter {
  final double value;
  final Color color;
  
  SimpleGaugePainter({required this.value, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Фоновая дуга
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.grey[800]!.withOpacity(0.5);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi * 1.25,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );
    
    // Цветная дуга
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi * 1.25,
      math.pi * 1.5 * value,
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(SimpleGaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

/// Расширение для MediumDashboard с вспомогательными методами
extension _MediumDashboardHelpers on MediumDashboard {
  /// Получает передачу напрямую из CAN-шины (без расчетов)
  String _getGearFromCAN(Map<String, dynamic> canData) {
    final gearValue = canData['gear'] ?? 1.0;
    
    // Если это уже строка, возвращаем как есть
    if (gearValue is String) {
      return gearValue;
    }
    
    // Если это число, преобразуем в строку
    if (gearValue is num) {
      final gear = gearValue.toDouble();
      if (gear <= 0) return 'N';
      if (gear >= 1 && gear <= 6) return gear.round().toString();
      return '1'; // Fallback на первую передачу
    }
    
    // Fallback для любых других типов
    return 'P';
  }
}