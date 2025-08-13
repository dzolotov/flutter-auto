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
  AutomotiveCanService() : super(const VehicleData()) {
    _setupEventChannels();
  }

  static const _canBusChannel = MethodChannel('com.automotive/can_bus');
  static const _sensorsChannel = MethodChannel('com.automotive/sensors');
  static const _canDataStream = EventChannel('com.automotive/can_data');
  
  StreamSubscription<dynamic>? _canDataSubscription;
  Timer? _obd2Timer;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void _setupEventChannels() {
    // Подписка на поток CAN данных
    _canDataSubscription = _canDataStream.receiveBroadcastStream().listen(
      _handleCanData,
      onError: (error) {
        print('[CAN] Stream error: $error');
        _isConnected = false;
        _updateConnectionStatus();
      },
    );
  }

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
      ];

      for (final pid in requests) {
        await _canBusChannel.invokeMethod('readOBD2', pid);
        // Небольшая задержка между запросами
        await Future.delayed(const Duration(milliseconds: 20));
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
      final mode = data[1] - 0x40; // Response mode
      final pid = data[2];
      final payloadLength = data[0] - 2;
      
      if (mode == 0x01 && payloadLength > 0) { // Current data mode
        final payload = data.sublist(3, 3 + payloadLength);
        _processObd2Response(pid, payload);
      }
    }
  }

  /// Обработка OBD-II ответов
  void _processObd2Response(int pid, List<int> data) {
    double? value;
    
    switch (pid) {
      case 0x0C: // Engine RPM
        if (data.length >= 2) {
          value = ((data[0] * 256) + data[1]) / 4.0;
          _updateVehicleData(rpm: value);
        }
        break;
        
      case 0x0D: // Vehicle Speed
        if (data.length >= 1) {
          value = data[0].toDouble();
          _updateVehicleData(speed: value);
        }
        break;
        
      case 0x05: // Engine Temperature
        if (data.length >= 1) {
          value = data[0] - 40.0;
          _updateVehicleData(engineTemp: value);
        }
        break;
        
      case 0x2F: // Fuel Level
        if (data.length >= 1) {
          value = (data[0] * 100.0) / 255.0;
          _updateVehicleData(fuelLevel: value);
        }
        break;
        
      case 0x11: // Throttle Position
        if (data.length >= 1) {
          value = (data[0] * 100.0) / 255.0;
          _updateVehicleData(throttlePosition: value);
        }
        break;
        
      case 0x04: // Engine Load
        if (data.length >= 1) {
          value = (data[0] * 100.0) / 255.0;
          _updateVehicleData(engineLoad: value);
        }
        break;
    }
    
    if (value != null) {
      print('[CAN] OBD-II PID 0x${pid.toRadixString(16).toUpperCase()}: $value');
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
  }) {
    state = state.copyWith(
      speed: speed ?? state.speed,
      rpm: rpm ?? state.rpm,
      engineTemp: engineTemp ?? state.engineTemp,
      fuelLevel: fuelLevel ?? state.fuelLevel,
      throttlePosition: throttlePosition ?? state.throttlePosition,
      engineLoad: engineLoad ?? state.engineLoad,
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
    _canDataSubscription?.cancel();
    _obd2Timer?.cancel();
    super.dispose();
  }
}

// Provider для automotive CAN service
final automotiveCanServiceProvider = StateNotifierProvider<AutomotiveCanService, VehicleData>(
  (ref) => AutomotiveCanService(),
);