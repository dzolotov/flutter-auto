import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/automotive_theme.dart';
import '../../services/random_data_simulator.dart';

/// Упрощенная версия дэшборда - минималистичный дизайн
/// Резервный вариант для тестирования базового функционала
class SimpleDashboard extends ConsumerWidget {
  const SimpleDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canData = ref.watch(randomDataProvider);
    
    return Scaffold(
      backgroundColor: AutomotiveTheme.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a1a),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Верхняя панель с основными показателями
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      // Спидометр
                      Expanded(
                        child: _buildSpeedometer(canData),
                      ),
                      const SizedBox(width: 16),
                      // Тахометр
                      Expanded(
                        child: _buildTachometer(canData),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Нижняя панель с дополнительной информацией
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Передача',
                          canData['gear']?.toString() ?? 'P',
                          Icons.settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Температура',
                          '${canData['engine_temp']?.toInt() ?? 90}°C',
                          Icons.thermostat,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Топливо',
                          '${canData['fuel_level']?.toInt() ?? 75}%',
                          Icons.local_gas_station,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Батарея',
                          '${canData['battery_voltage']?.toStringAsFixed(1) ?? '12.6'}V',
                          Icons.battery_full,
                        ),
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

  Widget _buildSpeedometer(Map<String, dynamic> canData) {
    final speed = (canData['speed'] ?? 0.0).toDouble();
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AutomotiveTheme.primaryBlue.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: AutomotiveTheme.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            speed.toInt().toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            'км/ч',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTachometer(Map<String, dynamic> canData) {
    final rpm = (canData['rpm'] ?? 800.0).toDouble();
    final rpmThousands = rpm / 1000;
    final isRedline = rpm > 6500;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            (isRedline ? Colors.red : AutomotiveTheme.accentOrange).withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: (isRedline ? Colors.red : AutomotiveTheme.accentOrange).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rpmThousands.toStringAsFixed(1),
            style: TextStyle(
              color: isRedline ? Colors.red : Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'x1000 об/мин',
            style: TextStyle(
              color: isRedline ? Colors.red.withOpacity(0.7) : Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AutomotiveTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}