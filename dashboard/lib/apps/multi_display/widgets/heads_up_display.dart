import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/can_bus_provider.dart';
import '../../../core/theme/automotive_theme.dart';

/// Проекционный дисплей (HUD - Heads Up Display)
/// Отображает критически важную информацию непосредственно в поле зрения водителя
class HeadsUpDisplay extends ConsumerWidget {
  const HeadsUpDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canData = ref.watch(canBusProvider);
    
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Верхняя строка - скорость и лимит
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Текущая скорость
                    Expanded(
                      flex: 2,
                      child: _buildSpeedDisplay(canData['speed']?.toDouble() ?? 0.0),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Лимит скорости и навигация
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(child: _buildSpeedLimit(60)),
                          const SizedBox(height: 8),
                          Expanded(child: _buildNavigationArrow()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Средняя строка - предупреждения
              Container(
                height: 60,
                child: _buildWarningsRow(canData),
              ),
              
              const SizedBox(height: 16),
              
              // Нижняя строка - дополнительная информация
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoBlock('КРУИЗ', canData['cruise_control']?.toString() ?? 'ВЫКЛ'),
                    _buildInfoBlock('ПЕРЕДАЧА', canData['gear']?.toString() ?? 'P'),
                    _buildInfoBlock('РЕЖИМ', 'КОМФОРТ'),
                    _buildInfoBlock('ТОПЛИВО', '${canData['fuel_level']?.toInt() ?? 50}%'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Дисплей скорости (основной элемент HUD)
  Widget _buildSpeedDisplay(double speed) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AutomotiveTheme.primaryBlue, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            speed.toInt().toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.bold,
              fontFamily: 'DigitalNumbers',
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
          Text(
            'км/ч',
            style: TextStyle(
              color: AutomotiveTheme.primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Лимит скорости
  Widget _buildSpeedLimit(int limit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red, width: 3),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              limit.toString(),
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'км/ч',
              style: TextStyle(
                color: Colors.black,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Стрелка навигации
  Widget _buildNavigationArrow() {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(
        children: [
          Center(
            child: Transform.rotate(
              angle: 0.5, // Поворот стрелки
              child: Icon(
                Icons.navigation,
                color: AutomotiveTheme.successGreen,
                size: 32,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Text(
              '500м',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Строка предупреждений
  Widget _buildWarningsRow(Map<String, dynamic> canData) {
    final warnings = <Widget>[];
    
    // Проверка различных предупреждений
    if (_isSpeedWarning(canData['speed']?.toDouble() ?? 0.0)) {
      warnings.add(_buildWarningItem(Icons.speed, 'ПРЕВЫШЕНИЕ СКОРОСТИ', AutomotiveTheme.warningRed));
    }
    
    if (_isFuelWarning(canData['fuel_level']?.toDouble() ?? 50.0)) {
      warnings.add(_buildWarningItem(Icons.local_gas_station, 'НИЗКИЙ УРОВЕНЬ ТОПЛИВА', AutomotiveTheme.accentOrange));
    }
    
    if (_isEngineWarning(canData)) {
      warnings.add(_buildWarningItem(Icons.warning, 'ПРОВЕРЬТЕ ДВИГАТЕЛЬ', AutomotiveTheme.warningRed));
    }

    // Если нет предупреждений, показываем статус
    if (warnings.isEmpty) {
      warnings.add(_buildStatusItem(Icons.check_circle, 'ВСЕ СИСТЕМЫ В НОРМЕ', AutomotiveTheme.successGreen));
    }
    
    return Container(
      child: warnings.isNotEmpty 
          ? warnings.first // Показываем только одно предупреждение
          : SizedBox.shrink(),
    );
  }

  /// Элемент предупреждения
  Widget _buildWarningItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Элемент статуса
  Widget _buildStatusItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Информационный блок
  Widget _buildInfoBlock(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'DigitalNumbers',
            ),
          ),
        ],
      ),
    );
  }

  /// Проверка превышения скорости
  bool _isSpeedWarning(double speed) {
    return speed > 65; // Превышение на 5 км/ч от лимита 60
  }

  /// Проверка низкого уровня топлива
  bool _isFuelWarning(double fuelLevel) {
    return fuelLevel < 20.0;
  }

  /// Проверка предупреждений двигателя
  bool _isEngineWarning(Map<String, dynamic> canData) {
    final engineTemp = canData['engine_temp']?.toDouble() ?? 90.0;
    final oilPressure = canData['oil_pressure']?.toDouble() ?? 2.5;
    
    return engineTemp > 110.0 || oilPressure < 1.0;
  }
}