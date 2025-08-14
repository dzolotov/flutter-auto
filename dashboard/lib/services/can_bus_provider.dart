import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'automotive_can_service.dart';
import '../models/vehicle_data.dart';

// Provider для CAN Bus - использует платформенные каналы flutter-pi
final canBusProvider = Provider<Map<String, dynamic>>((ref) {
  final vehicleData = ref.watch(automotiveCanServiceProvider);
  
  // Рассчитываем дополнительные параметры на основе реальных данных
  final gear = _calculateGear(vehicleData.speed, vehicleData.rpm);
  final speedLimit = _calculateSpeedLimit(vehicleData.speed);
  
  // Преобразование VehicleData в Map<String, dynamic> для совместимости
  // Добавляем все параметры, которые симулирует Python-скрипт
  return {
    // === Основные параметры двигателя ===
    'speed': vehicleData.speed,
    'rpm': vehicleData.rpm,
    'engine_temp': vehicleData.engineTemp,
    'engine_load': vehicleData.engineLoad,
    'throttle_position': vehicleData.throttlePosition,
    'throttle': vehicleData.throttlePosition, // Для совместимости
    'fuel_level': vehicleData.fuelLevel,
    
    // === Трансмиссия ===
    'gear': gear,
    'speed_limit': speedLimit, // Симулируем ограничения скорости
    
    // === Температуры (как в Python симуляторе) ===
    'oil_temp': vehicleData.engineTemp + 5, // Масло горячее охлаждающей жидкости
    'intake_air_temp': 25.0 + (vehicleData.engineLoad * 0.3), // Зависит от нагрузки
    'outside_temp': 20.0, // Окружающая температура
    'ambient_temperature': 20.0,
    
    // === Топливная система ===
    'fuel_pressure': 3.5 + (vehicleData.engineLoad * 0.015), // Зависит от нагрузки
    'instant_fuel_consumption': _calculateFuelConsumption(vehicleData.speed, vehicleData.engineLoad),
    'average_fuel_consumption': 8.5,
    'fuel_warning': vehicleData.fuelLevel < 15,
    
    // === Давления ===
    'oil_pressure': _calculateOilPressure(vehicleData.rpm),
    'boost_pressure': vehicleData.engineLoad > 80 ? (vehicleData.engineLoad - 80) * 0.1 : 0.0,
    'brake_pressure': 0.0,
    'barometric_pressure': 101.3,
    
    // === Электрическая система ===
    'battery_voltage': vehicleData.isConnected ? 14.2 : 12.6,
    'control_module_voltage': vehicleData.isConnected ? 14.2 : 12.6,
    
    // === Воздушная система ===
    'mass_air_flow': _calculateMAF(vehicleData.rpm, vehicleData.engineLoad),
    'intake_manifold_pressure': 100 - (vehicleData.throttlePosition * 0.8), // кПа
    
    // === Пробег и счетчики ===
    'odometer': vehicleData.odometer,  // Берем реальный пробег из CAN
    'trip_meter': 123.4,
    'runtime_since_start': DateTime.now().millisecondsSinceEpoch ~/ 1000, // секунды
    
    // === Рассчитанные параметры ===
    'torque': _calculateTorque(vehicleData.rpm, vehicleData.engineLoad),
    'power': _calculatePower(vehicleData.rpm, vehicleData.engineLoad),
    'eco_score': _calculateEcoScore(vehicleData.throttlePosition, vehicleData.engineLoad),
    
    // === Скорости колес (все одинаковые для простоты) ===
    'wheel_speed_fl': vehicleData.speed,
    'wheel_speed_fr': vehicleData.speed,
    'wheel_speed_rl': vehicleData.speed,
    'wheel_speed_rr': vehicleData.speed,
    
    // === Системы предупреждения ===
    'engine_warning': vehicleData.engineTemp > 105,
    'oil_warning': _calculateOilPressure(vehicleData.rpm) < 1.0,
    'abs_warning': false,
    'mil_status': false, // Индикатор неисправности двигателя
    
    // === Системы комфорта ===
    'seatbelt_fastened': true,
    'left_turn_signal': false,
    'right_turn_signal': false,
    'hvac_on': false,
    'target_temp': 22.0,
    'cabin_temp': 21.0,
    'fan_speed': 2,
    
    // === Топливные корректировки ===
    'short_fuel_trim_bank1': 0.0, // ±3%
    'long_fuel_trim_bank1': 0.0,  // ±5%
    
    // === Датчики кислорода ===
    'o2_sensor1_voltage': 0.45, // Лямбда = 1.0
    'o2_sensor2_voltage': 0.47,
    
    // === Системная информация ===
    'is_connected': vehicleData.isConnected,
    'last_update': vehicleData.lastUpdate,
    'diagnostic_codes_count': 0,
    
    // === Угол опережения зажигания ===
    'timing_advance': 15.0 + (vehicleData.rpm / 6000.0) * 25.0,
  };
});

String _calculateGear(double speed, double rpm) {
  if (speed < 0.5) return 'P';
  if (speed < 20) return '1';
  if (speed < 40) return '2';
  if (speed < 60) return '3';
  if (speed < 80) return '4';
  if (speed < 110) return '5';
  return '6';
}

int _calculateSpeedLimit(double currentSpeed) {
  // Имитируем различные ограничения скорости
  if (currentSpeed < 30) return 50;  // Город
  if (currentSpeed < 70) return 60;  // Городские магистрали
  if (currentSpeed < 100) return 90; // Трасса
  return 130; // Автобан
}


double _calculateMAF(double rpm, double load) {
  // Массовый расход воздуха зависит от оборотов и нагрузки
  final baseMAF = (rpm / 1000.0) * 2.0; // Базовый расход
  final loadFactor = 1.0 + (load / 100.0) * 2.0; // Коэффициент нагрузки
  return baseMAF * loadFactor;
}

double _calculateOilPressure(double rpm) {
  return 0.5 + (rpm / 7000) * 4.0;
}

double _calculateFuelConsumption(double speed, double load) {
  if (speed < 0.1) return 999.0;
  return (load * 0.3 + 5.0).clamp(3.0, 30.0);
}

double _calculateTorque(double rpm, double load) {
  final normalizedRpm = rpm / 7000;
  final baseTorque = 150 + (normalizedRpm < 0.6 
      ? normalizedRpm * 333 
      : (350 - (normalizedRpm - 0.6) * 250));
  return baseTorque * (load / 100);
}

double _calculatePower(double rpm, double load) {
  final torque = _calculateTorque(rpm, load);
  return (torque * rpm) / 9549; // kW
}

double _calculateEcoScore(double throttle, double load) {
  final efficiency = 100 - (throttle * 0.5 + load * 0.5);
  return efficiency.clamp(0, 100);
}

// Инициализация CAN сервиса
final canServiceInitializerProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(automotiveCanServiceProvider.notifier);
  return await service.initialize('vcan0');
});