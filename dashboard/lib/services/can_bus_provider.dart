import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'automotive_can_service.dart';

// Provider для CAN Bus - использует платформенные каналы flutter-pi
final canBusProvider = Provider<Map<String, dynamic>>((ref) {
  final vehicleData = ref.watch(automotiveCanServiceProvider);
  
  // Преобразование VehicleData в Map<String, dynamic> для совместимости
  return {
    'speed': vehicleData.speed,
    'rpm': vehicleData.rpm,
    'gear': _calculateGear(vehicleData.speed, vehicleData.rpm),
    'engine_temp': vehicleData.engineTemp,
    'oil_temp': vehicleData.engineTemp * 0.95, // Oil temp follows engine temp
    'outside_temp': 20.0, // Default value
    'fuel_level': vehicleData.fuelLevel,
    'oil_pressure': _calculateOilPressure(vehicleData.rpm),
    'battery_voltage': 13.8,
    'odometer': 12345.6,
    'trip_meter': 123.4,
    'throttle_position': vehicleData.throttlePosition,
    'brake_pressure': 0.0,
    'abs_warning': false,
    'engine_warning': vehicleData.engineTemp > 105,
    'oil_warning': false,
    'fuel_warning': vehicleData.fuelLevel < 15,
    'seatbelt_fastened': true,
    'left_turn_signal': false,
    'right_turn_signal': false,
    'wheel_speed_fl': vehicleData.speed,
    'wheel_speed_fr': vehicleData.speed,
    'wheel_speed_rl': vehicleData.speed,
    'wheel_speed_rr': vehicleData.speed,
    'hvac_on': false,
    'target_temp': 22.0,
    'cabin_temp': 21.0,
    'fan_speed': 2,
    'instant_fuel_consumption': _calculateFuelConsumption(vehicleData.speed, vehicleData.engineLoad),
    'average_fuel_consumption': 8.5,
    'torque': _calculateTorque(vehicleData.rpm, vehicleData.engineLoad),
    'power': _calculatePower(vehicleData.rpm, vehicleData.engineLoad),
    'boost_pressure': 0.0,
    'intake_air_temp': 25.0,
    'mass_air_flow': 3.5,
    'fuel_pressure': 3.5,
    'engine_load': vehicleData.engineLoad,
    'eco_score': _calculateEcoScore(vehicleData.throttlePosition, vehicleData.engineLoad),
    'is_connected': vehicleData.isConnected,
    'last_update': vehicleData.lastUpdate,
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