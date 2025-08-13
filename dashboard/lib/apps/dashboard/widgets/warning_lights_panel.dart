import 'package:flutter/material.dart';
import '../../../core/theme/automotive_theme.dart';

/// Панель индикаторных ламп приборной панели
/// Отображает различные предупреждения и состояния систем автомобиля
class WarningLightsPanel extends StatelessWidget {
  final Map<String, dynamic> canData;

  const WarningLightsPanel({
    super.key,
    required this.canData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Индикатор двигателя
          _buildWarningLight(
            icon: Icons.settings,
            label: 'ENGINE',
            isActive: _isEngineWarning(),
            color: AutomotiveTheme.warningRed,
            tooltip: 'Неисправность двигателя',
          ),
          
          // Индикатор масла
          _buildWarningLight(
            icon: Icons.opacity,
            label: 'OIL',
            isActive: _isOilWarning(),
            color: AutomotiveTheme.warningRed,
            tooltip: 'Низкое давление масла',
          ),
          
          // Индикатор температуры
          _buildWarningLight(
            icon: Icons.thermostat,
            label: 'TEMP',
            isActive: _isTemperatureWarning(),
            color: AutomotiveTheme.temperatureDanger,
            tooltip: 'Перегрев двигателя',
          ),
          
          // Индикатор топлива
          _buildWarningLight(
            icon: Icons.local_gas_station,
            label: 'FUEL',
            isActive: _isFuelWarning(),
            color: AutomotiveTheme.fuelLow,
            tooltip: 'Низкий уровень топлива',
          ),
          
          // Индикатор аккумулятора
          _buildWarningLight(
            icon: Icons.battery_alert,
            label: 'BATT',
            isActive: _isBatteryWarning(),
            color: AutomotiveTheme.warningRed,
            tooltip: 'Проблемы с аккумулятором',
          ),
          
          // Индикатор ABS
          _buildWarningLight(
            icon: Icons.block,
            label: 'ABS',
            isActive: _isAbsWarning(),
            color: AutomotiveTheme.accentOrange,
            tooltip: 'Неисправность системы ABS',
          ),
          
          // Индикатор ремня безопасности
          _buildWarningLight(
            icon: Icons.safety_divider,
            label: 'BELT',
            isActive: _isSeatbeltWarning(),
            color: AutomotiveTheme.warningRed,
            tooltip: 'Непристегнутый ремень безопасности',
          ),
          
          // Индикатор поворотников
          _buildTurnSignalIndicators(),
        ],
      ),
    );
  }

  /// Создает индикаторную лампу
  Widget _buildWarningLight({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive 
              ? Border.all(color: color.withOpacity(0.5))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: Icon(
                icon,
                color: isActive ? color : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.grey[600],
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Создает индикаторы поворотников с мигающим эффектом
  Widget _buildTurnSignalIndicators() {
    final leftTurn = canData['left_turn_signal'] == true;
    final rightTurn = canData['right_turn_signal'] == true;
    
    return Row(
      children: [
        // Левый поворотник
        _buildBlinkingIndicator(
          icon: Icons.keyboard_arrow_left,
          label: 'L',
          isActive: leftTurn,
          color: AutomotiveTheme.successGreen,
        ),
        
        const SizedBox(width: 4),
        
        // Правый поворотник
        _buildBlinkingIndicator(
          icon: Icons.keyboard_arrow_right,
          label: 'R',
          isActive: rightTurn,
          color: AutomotiveTheme.successGreen,
        ),
      ],
    );
  }

  /// Создает мигающий индикатор
  Widget _buildBlinkingIndicator({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return isActive
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Opacity(
                opacity: (value * 2).clamp(0.0, 1.0) > 1.0 
                    ? 2.0 - (value * 2) 
                    : (value * 2),
                child: child,
              );
            },
            onEnd: () {
              // Перезапуск анимации для непрерывного мигания
              if (isActive) {
                // В реальном приложении здесь должен быть setState или rebuild
              }
            },
            child: _buildIndicatorContent(icon, label, color),
          )
        : _buildIndicatorContent(icon, label, Colors.grey[600]!);
  }

  /// Создает содержимое индикатора
  Widget _buildIndicatorContent(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Проверяет предупреждение двигателя
  bool _isEngineWarning() {
    final engineTemp = canData['engine_temp']?.toDouble() ?? 90.0;
    final rpm = canData['rpm']?.toDouble() ?? 0.0;
    return engineTemp > 115.0 || rpm > 7000.0;
  }

  /// Проверяет предупреждение масла
  bool _isOilWarning() {
    final oilPressure = canData['oil_pressure']?.toDouble() ?? 2.0;
    final oilTemp = canData['oil_temp']?.toDouble() ?? 85.0;
    return oilPressure < 1.0 || oilTemp > 125.0;
  }

  /// Проверяет предупреждение температуры
  bool _isTemperatureWarning() {
    final engineTemp = canData['engine_temp']?.toDouble() ?? 90.0;
    return engineTemp > 105.0;
  }

  /// Проверяет предупреждение топлива
  bool _isFuelWarning() {
    final fuelLevel = canData['fuel_level']?.toDouble() ?? 50.0;
    return fuelLevel < 25.0;
  }

  /// Проверяет предупреждение аккумулятора
  bool _isBatteryWarning() {
    final batteryVoltage = canData['battery_voltage']?.toDouble() ?? 12.0;
    return batteryVoltage < 11.5 || batteryVoltage > 14.5;
  }

  /// Проверяет предупреждение ABS
  bool _isAbsWarning() {
    return canData['abs_warning'] == true;
  }

  /// Проверяет предупреждение ремня безопасности
  bool _isSeatbeltWarning() {
    final speed = canData['speed']?.toDouble() ?? 0.0;
    final seatbeltFastened = canData['seatbelt_fastened'] == true;
    return speed > 5.0 && !seatbeltFastened;
  }
}