// Flutter-Pi Automotive Dashboard
// Copyright (C) 2025 Dmitrii Zolotov, dmitrii.zolotov@gmail.com
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle_data.dart';

class AutomotiveCanService extends StateNotifier<VehicleData> {
  AutomotiveCanService() : super(const VehicleData());

  static const _canBusChannel = MethodChannel('com.automotive/can_bus');
  static const _sensorsChannel = MethodChannel('com.automotive/sensors');
  
  Timer? _obd2Timer;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Инициализация CAN интерфейса
  Future<bool> initialize(String canInterface) async {
    try {
      final result = await _canBusChannel.invokeMethod<bool>(
        'initialize',
        canInterface,
      );
      
      _isConnected = result ?? false;
      
      if (_isConnected) {
        print('[CAN] Successfully initialized on $canInterface');
        _startObd2Polling();
        _updateConnectionStatus();
        return true;
      } else {
        print('[CAN] Failed to initialize on $canInterface');
        return false;
      }
    } catch (e) {
      print('[CAN] Initialize error: $e');
      _isConnected = false;
      _updateConnectionStatus();
      return false;
    }
  }

  /// Запуск периодического опроса OBD-II параметров
  void _startObd2Polling() {
    _obd2Timer?.cancel();
    _obd2Timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _requestObd2Data();
      // Дополнительно запрашиваем данные напрямую от симулятора
      fetchAllSensorData();
    });
  }

  /// Запрос основных OBD-II параметров
  void _requestObd2Data() async {
    try {
      // Запрашиваем основные параметры
      final requests = [
        0x0C, // Engine RPM
        0x0D, // Vehicle Speed
        0x05, // Engine Coolant Temperature
        0x2F, // Fuel Level
        0x11, // Throttle Position
        0x04, // Engine Load
        0x31, // Odometer (пробег в км)
      ];

      for (final pid in requests) {
        try {
          // Отправляем OBD2 запрос и ждем небольшую паузу для обновления кеша
          await _canBusChannel.invokeMethod('readOBD2', pid);
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Теперь запрашиваем еще раз чтобы получить кешированное значение
          final response = await _canBusChannel.invokeMethod('readOBD2', pid);
          
          if (response != null && response is Map) {
            final value = response['value'];
            if (value != null && value is double) {
              _processDirectObd2Response(pid, value);
            }
          }
        } catch (e) {
          print('[CAN] Error reading PID 0x${pid.toRadixString(16)}: $e');
        }
      }
    } catch (e) {
      print('[CAN] OBD2 request error: $e');
    }
  }

  /// Обработка входящих CAN данных
  void _handleCanData(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final canId = data['id'] as int?;
        final canData = data['data'] as List<dynamic>?;
        final dlc = data['dlc'] as int?;
        final isExtended = data['extended'] as bool? ?? false;

        print('[CAN] Raw frame: ID=0x${canId?.toRadixString(16)}, Data=$canData, DLC=$dlc');

        if (canId != null && canData != null && dlc != null) {
          _processCanFrame(canId, canData.cast<int>(), dlc, isExtended);
        }
      }
    } catch (e) {
      print('[CAN] Data processing error: $e');
    }
  }

  /// Обработка CAN фрейма
  void _processCanFrame(int canId, List<int> data, int dlc, bool isExtended) {
    // OBD-II responses are typically in range 0x7E8-0x7EF
    if (canId >= 0x7E8 && canId <= 0x7EF && dlc >= 3) {
      final length = data[0];
      final mode = data[1];
      final pid = data[2];
      
      print('[CAN] OBD2 Frame: Length=$length, Mode=0x${mode.toRadixString(16)}, PID=0x${pid.toRadixString(16)}');
      
      // Проверяем что это ответ на Mode 01 (Current Data)
      if (mode == 0x41 && length >= 2) {
        final payloadLength = length - 2; // Вычитаем байты mode и pid
        if (payloadLength > 0 && data.length >= 3 + payloadLength) {
          final payload = data.sublist(3, 3 + payloadLength);
          print('[CAN] Payload for PID 0x${pid.toRadixString(16)}: $payload');
          _processObd2Response(pid, payload);
        }
      }
    }
  }

  /// Обработка прямых OBD-II ответов от плагина
  void _processDirectObd2Response(int pid, double value) {
    switch (pid) {
      case 0x0C: // Engine RPM
        _updateVehicleData(rpm: value);
        print('[CAN] ✓ RPM: ${value.toStringAsFixed(1)} (direct)');
        break;
        
      case 0x0D: // Vehicle Speed
        _updateVehicleData(speed: value);
        print('[CAN] ✓ Speed: ${value.toStringAsFixed(1)} km/h (direct)');
        break;
        
      case 0x05: // Engine Temperature
        _updateVehicleData(engineTemp: value);
        print('[CAN] ✓ Engine Temp: ${value.toStringAsFixed(1)}°C (direct)');
        break;
        
      case 0x2F: // Fuel Level
        if (value >= 0 && value <= 100) {
          _updateVehicleData(fuelLevel: value);
          print('[CAN] ✓ Fuel Level: ${value.toStringAsFixed(1)}% (direct)');
        }
        break;
        
      case 0x11: // Throttle Position
        if (value >= 0 && value <= 100) {
          _updateVehicleData(throttlePosition: value);
          print('[CAN] ✓ Throttle: ${value.toStringAsFixed(1)}% (direct)');
        }
        break;
        
      case 0x04: // Engine Load
        if (value >= 0 && value <= 100) {
          _updateVehicleData(engineLoad: value);
          print('[CAN] ✓ Engine Load: ${value.toStringAsFixed(1)}% (direct)');
        }
        break;
        
      case 0x31: // Odometer
        // Значение уже в километрах от симулятора
        _updateVehicleData(odometer: value);
        print('[CAN] ✓ Odometer: ${value.toStringAsFixed(1)} km (direct)');
        break;
      
      default:
        print('[CAN] Unknown PID 0x${pid.toRadixString(16).toUpperCase()}: $value (direct)');
        break;
    }
  }

  /// Обработка OBD-II ответов
  void _processObd2Response(int pid, List<int> data) {
    double? value;
    
    switch (pid) {
      case 0x0C: // Engine RPM
        if (data.length >= 2) {
          value = ((data[0] * 256) + data[1]) / 4.0;
          // Фильтрация неразумных значений RPM
          if (value >= 0 && value <= 8000) {
            _updateVehicleData(rpm: value);
            print('[CAN] ✓ RPM: ${value.toStringAsFixed(0)}');
          } else {
            print('[CAN] ✗ Invalid RPM: $value (raw: ${data[0]}, ${data[1]})');
          }
        }
        break;
        
      case 0x0D: // Vehicle Speed
        if (data.length >= 1) {
          value = data[0].toDouble();
          // Фильтрация неразумных значений скорости
          if (value >= 0 && value <= 255) {
            _updateVehicleData(speed: value);
            print('[CAN] ✓ Speed: ${value.toStringAsFixed(1)} km/h');
          } else {
            print('[CAN] ✗ Invalid speed: $value (raw: ${data[0]})');
          }
        }
        break;
        
      case 0x05: // Engine Temperature
        if (data.length >= 1) {
          value = data[0] - 40.0;
          // Фильтрация неразумных значений температуры
          if (value >= -40 && value <= 200) {
            _updateVehicleData(engineTemp: value);
            print('[CAN] ✓ Engine Temp: ${value.toStringAsFixed(1)}°C');
          } else {
            print('[CAN] ✗ Invalid temp: $value°C (raw: ${data[0]})');
          }
        }
        break;
        
      case 0x2F: // Fuel Level
        if (data.length >= 1) {
          value = (data[0] * 100.0) / 255.0;
          // Фильтрация неразумных значений уровня топлива
          if (value >= 0 && value <= 100) {
            _updateVehicleData(fuelLevel: value);
            print('[CAN] ✓ Fuel Level: ${value.toStringAsFixed(1)}%');
          } else {
            print('[CAN] ✗ Invalid fuel level: $value% (raw: ${data[0]})');
          }
        }
        break;
        
      case 0x11: // Throttle Position
        if (data.length >= 1) {
          value = (data[0] * 100.0) / 255.0;
          // Фильтрация неразумных значений дросселя
          if (value >= 0 && value <= 100) {
            _updateVehicleData(throttlePosition: value);
            print('[CAN] ✓ Throttle: ${value.toStringAsFixed(1)}%');
          } else {
            print('[CAN] ✗ Invalid throttle: $value% (raw: ${data[0]})');
          }
        }
        break;
        
      case 0x04: // Engine Load
        if (data.length >= 1) {
          value = (data[0] * 100.0) / 255.0;
          // Фильтрация неразумных значений нагрузки
          if (value >= 0 && value <= 100) {
            _updateVehicleData(engineLoad: value);
            print('[CAN] ✓ Engine Load: ${value.toStringAsFixed(1)}%');
          } else {
            print('[CAN] ✗ Invalid engine load: $value% (raw: ${data[0]})');
          }
        }
        break;
        
      case 0x31: // Odometer
        if (data.length >= 4) {
          // Одометр передается как 4-байтовое целое в км
          value = ((data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3]).toDouble();
          _updateVehicleData(odometer: value);
          print('[CAN] ✓ Odometer: ${value.toStringAsFixed(1)} km');
        }
        break;
      
      default:
        print('[CAN] Unknown PID 0x${pid.toRadixString(16).toUpperCase()}: $data');
        break;
    }
  }

  /// Обновление данных автомобиля
  void _updateVehicleData({
    double? speed,
    double? rpm,
    double? engineTemp,
    double? fuelLevel,
    double? throttlePosition,
    double? engineLoad,
    double? odometer,
  }) {
    print('[CAN] Updating vehicle data:');
    if (engineTemp != null) print('  - Engine Temp: ${engineTemp.toStringAsFixed(1)}°C (was: ${state.engineTemp.toStringAsFixed(1)}°C)');
    if (fuelLevel != null) print('  - Fuel Level: ${fuelLevel.toStringAsFixed(1)}% (was: ${state.fuelLevel.toStringAsFixed(1)}%)');
    if (speed != null) print('  - Speed: ${speed.toStringAsFixed(1)} km/h');
    if (rpm != null) print('  - RPM: ${rpm.toStringAsFixed(0)}');
    
    state = state.copyWith(
      speed: speed ?? state.speed,
      rpm: rpm ?? state.rpm,
      engineTemp: engineTemp ?? state.engineTemp,
      fuelLevel: fuelLevel ?? state.fuelLevel,
      throttlePosition: throttlePosition ?? state.throttlePosition,
      engineLoad: engineLoad ?? state.engineLoad,
      odometer: odometer ?? state.odometer,
      lastUpdate: DateTime.now(),
    );
  }

  void _updateConnectionStatus() {
    state = state.copyWith(
      isConnected: _isConnected,
      lastUpdate: DateTime.now(),
    );
  }

  /// Отправка CAN фрейма
  Future<bool> sendCanFrame(int canId, List<int> data) async {
    try {
      final result = await _canBusChannel.invokeMethod<bool>(
        'sendCANFrame',
        [canId, data],
      );
      return result ?? false;
    } catch (e) {
      print('[CAN] Send frame error: $e');
      return false;
    }
  }

  /// Получение статистики CAN интерфейса
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final result = await _canBusChannel.invokeMethod<Map<String, dynamic>>(
        'getStats',
      );
      return result;
    } catch (e) {
      print('[CAN] Get stats error: $e');
      return null;
    }
  }
  
  /// Прямое получение всех параметров от симулятора
  Future<void> fetchAllSensorData() async {
    try {
      // Получаем температуру двигателя
      final engineTemp = await getEngineTemp();
      if (engineTemp != null) {
        _updateVehicleData(engineTemp: engineTemp);
        print('[CAN] ✓ Direct Engine Temp: ${engineTemp.toStringAsFixed(1)}°C');
      }
      
      // Получаем уровень топлива через sensors channel
      try {
        final fuelLevel = await _sensorsChannel.invokeMethod<double>('getFuelLevel');
        if (fuelLevel != null && fuelLevel >= 0 && fuelLevel <= 100) {
          _updateVehicleData(fuelLevel: fuelLevel);
          print('[CAN] ✓ Direct Fuel Level: ${fuelLevel.toStringAsFixed(1)}%');
        }
      } catch (e) {
        // Попробуем через OBD2
      }
      
      // Получаем одометр через sensors channel
      try {
        final odometer = await _sensorsChannel.invokeMethod<double>('getOdometer');
        if (odometer != null && odometer >= 0) {
          _updateVehicleData(odometer: odometer);
          print('[CAN] ✓ Direct Odometer: ${odometer.toStringAsFixed(1)} km');
        }
      } catch (e) {
        // Попробуем через OBD2
      }
    } catch (e) {
      print('[CAN] Direct sensor fetch error: $e');
    }
  }

  /// Упрощенные методы для получения данных
  Future<double> getSpeed() async {
    try {
      final result = await _sensorsChannel.invokeMethod<double>('getSpeed');
      return result ?? 0.0;
    } catch (e) {
      return state.speed;
    }
  }

  Future<double> getRpm() async {
    try {
      final result = await _sensorsChannel.invokeMethod<double>('getRPM');
      return result ?? 0.0;
    } catch (e) {
      return state.rpm;
    }
  }

  Future<double> getEngineTemp() async {
    try {
      final result = await _sensorsChannel.invokeMethod<double>('getEngineTemp');
      return result ?? 0.0;
    } catch (e) {
      return state.engineTemp;
    }
  }

  @override
  void dispose() {
    _obd2Timer?.cancel();
    super.dispose();
  }
}

// Provider для automotive CAN service
final automotiveCanServiceProvider = StateNotifierProvider<AutomotiveCanService, VehicleData>(
  (ref) => AutomotiveCanService(),
);