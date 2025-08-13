import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/can_bus_provider.dart';
import '../../dashboard/widgets/speedometer_widget.dart';
import '../../dashboard/widgets/rpm_gauge_widget.dart';
import '../../dashboard/widgets/fuel_gauge_widget.dart';
import '../../../core/theme/automotive_theme.dart';

/// Дисплей приборной панели (кластер) - оптимизирован для горизонтального формата
/// Показывает критически важную информацию о состоянии автомобиля
class InstrumentClusterDisplay extends ConsumerWidget {
  const InstrumentClusterDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canData = ref.watch(canBusProvider);
    
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Левая секция - спидометр и дополнительная информация
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Спидометр
                    Expanded(
                      flex: 3,
                      child: SpeedometerWidget(
                        speed: canData['speed']?.toDouble() ?? 0.0,
                        maxSpeed: 220.0,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Дополнительная информация
                    Expanded(
                      flex: 1,
                      child: _buildAdditionalInfo(canData),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Центральная секция - цифровая информация
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Передача и время
                    Expanded(
                      child: _buildCenterInfo(canData),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Температуры и давления
                    Expanded(
                      child: _buildSystemStatus(canData),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Предупреждающие индикаторы
                    Container(
                      height: 40,
                      child: _buildWarningIndicators(canData),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Правая секция - тахометр и топливо
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Тахометр
                    Expanded(
                      flex: 3,
                      child: RpmGaugeWidget(
                        rpm: canData['rpm']?.toDouble() ?? 0.0,
                        maxRpm: 8000.0,
                        redlineRpm: 6500.0,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Топливо
                    Expanded(
                      flex: 1,
                      child: FuelGaugeWidget(
                        fuelLevel: canData['fuel_level']?.toDouble() ?? 50.0,
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

  /// Дополнительная информация (одометр, поездка)
  Widget _buildAdditionalInfo(Map<String, dynamic> canData) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildInfoRow('ОДОМЕТР', '${(canData['odometer']?.toDouble() ?? 0.0).toStringAsFixed(1)} км'),
          const SizedBox(height: 4),
          _buildInfoRow('ПОЕЗДКА', '${(canData['trip_meter']?.toDouble() ?? 0.0).toStringAsFixed(1)} км'),
          const SizedBox(height: 4),
          _buildInfoRow('СРЕДНИЙ', '6.8 л/100км'),
        ],
      ),
    );
  }

  /// Центральная информация
  Widget _buildCenterInfo(Map<String, dynamic> canData) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Текущая передача
          Text(
            canData['gear']?.toString() ?? 'P',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'DigitalNumbers',
            ),
          ),
          
          Text(
            'ПЕРЕДАЧА',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Время
          StreamBuilder(
            stream: Stream.periodic(Duration(seconds: 1)),
            builder: (context, snapshot) {
              final now = DateTime.now();
              return Column(
                children: [
                  Text(
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: AutomotiveTheme.primaryBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DigitalNumbers',
                    ),
                  ),
                  Text(
                    '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Статус систем
  Widget _buildSystemStatus(Map<String, dynamic> canData) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildStatusRow(
            'ТЕМП. ДВС',
            '${canData['engine_temp']?.toStringAsFixed(0) ?? '90'}°C',
            _getTemperatureColor(canData['engine_temp']?.toDouble() ?? 90.0),
          ),
          const SizedBox(height: 6),
          _buildStatusRow(
            'ДАВЛ. МАСЛА',
            '${canData['oil_pressure']?.toStringAsFixed(1) ?? '2.5'} бар',
            _getPressureColor(canData['oil_pressure']?.toDouble() ?? 2.5),
          ),
          const SizedBox(height: 6),
          _buildStatusRow(
            'НАПРЯЖЕНИЕ',
            '${canData['battery_voltage']?.toStringAsFixed(1) ?? '12.6'} В',
            _getVoltageColor(canData['battery_voltage']?.toDouble() ?? 12.6),
          ),
        ],
      ),
    );
  }

  /// Предупреждающие индикаторы
  Widget _buildWarningIndicators(Map<String, dynamic> canData) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildWarningIcon(
            Icons.warning,
            'ENGINE',
            _isEngineWarning(canData),
          ),
          _buildWarningIcon(
            Icons.oil_barrel,
            'OIL',
            _isOilWarning(canData),
          ),
          _buildWarningIcon(
            Icons.thermostat,
            'TEMP',
            _isTempWarning(canData),
          ),
          _buildWarningIcon(
            Icons.battery_alert,
            'BATT',
            _isBatteryWarning(canData),
          ),
          _buildWarningIcon(
            Icons.local_gas_station,
            'FUEL',
            _isFuelWarning(canData),
          ),
        ],
      ),
    );
  }

  /// Строка информации
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'DigitalNumbers',
          ),
        ),
      ],
    );
  }

  /// Строка статуса с цветовой индикацией
  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 9,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'DigitalNumbers',
          ),
        ),
      ],
    );
  }

  /// Иконка предупреждения
  Widget _buildWarningIcon(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isActive 
              ? AutomotiveTheme.warningRed 
              : Colors.grey[600],
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive 
                ? AutomotiveTheme.warningRed 
                : Colors.grey[600],
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Цвет температуры
  Color _getTemperatureColor(double temp) {
    if (temp > 110) return AutomotiveTheme.warningRed;
    if (temp > 100) return AutomotiveTheme.accentOrange;
    return AutomotiveTheme.successGreen;
  }

  /// Цвет давления
  Color _getPressureColor(double pressure) {
    if (pressure < 1.0) return AutomotiveTheme.warningRed;
    if (pressure < 2.0) return AutomotiveTheme.accentOrange;
    return AutomotiveTheme.successGreen;
  }

  /// Цвет напряжения
  Color _getVoltageColor(double voltage) {
    if (voltage < 11.5 || voltage > 14.5) return AutomotiveTheme.warningRed;
    if (voltage < 12.0) return AutomotiveTheme.accentOrange;
    return AutomotiveTheme.successGreen;
  }

  /// Проверки предупреждений
  bool _isEngineWarning(Map<String, dynamic> data) {
    final temp = data['engine_temp']?.toDouble() ?? 90.0;
    return temp > 110.0;
  }

  bool _isOilWarning(Map<String, dynamic> data) {
    final pressure = data['oil_pressure']?.toDouble() ?? 2.5;
    return pressure < 1.0;
  }

  bool _isTempWarning(Map<String, dynamic> data) {
    final temp = data['engine_temp']?.toDouble() ?? 90.0;
    return temp > 105.0;
  }

  bool _isBatteryWarning(Map<String, dynamic> data) {
    final voltage = data['battery_voltage']?.toDouble() ?? 12.6;
    return voltage < 11.5 || voltage > 14.5;
  }

  bool _isFuelWarning(Map<String, dynamic> data) {
    final fuel = data['fuel_level']?.toDouble() ?? 50.0;
    return fuel < 15.0;
  }
}