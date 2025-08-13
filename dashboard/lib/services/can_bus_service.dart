import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Флаг для определения режима работы (симулятор или реальный CAN)
/// Используется через --dart-define=USE_SIMULATOR=true при запуске
const bool useSimulator = bool.fromEnvironment('USE_SIMULATOR', defaultValue: false);

/// Интерфейс для работы с CAN шиной
abstract class CanBusInterface {
  Stream<Map<String, dynamic>> get dataStream;
  Future<bool> initialize(String interface);
  Future<void> requestOBD2Data(int pid);
  Future<Map<String, dynamic>> getStats();
  void dispose();
}

/// Реальная реализация CAN через платформенный канал
class RealCanBusService implements CanBusInterface {
  static const platform = MethodChannel('com.automotive/can_bus');
  static const eventChannel = EventChannel('com.automotive/can_data');
  
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _eventSubscription;
  
  // Кэш последних значений
  final Map<String, dynamic> _lastValues = {
    'speed': 0.0,
    'rpm': 0.0,
    'engineTemp': 0.0,
    'throttle': 0.0,
    'fuelLevel': 0.0,
    'engineLoad': 0.0,
    'gear': 1.0,
    'acceleratorPedal': 0.0,
  };
  
  Timer? _pollingTimer;
  
  @override
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  @override
  Future<bool> initialize(String interface) async {
    try {
      // Попытка инициализации CAN интерфейса
      final result = await platform.invokeMethod('initialize', interface);
      
      if (result == true) {
        // Подписка на поток данных CAN
        _eventSubscription = eventChannel
            .receiveBroadcastStream()
            .cast<Map<dynamic, dynamic>>()
            .listen((data) {
          _processCanFrame(Map<String, dynamic>.from(data));
        });
        
        // Запуск периодического опроса OBD-II данных
        _startOBD2Polling();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to initialize CAN: $e');
      
      // Попытка использовать альтернативный интерфейс
      if (interface == 'vcan0') {
        return initialize('can0');
      }
      return false;
    }
  }
  
  void _startOBD2Polling() {
    // Список OBD-II PID для опроса
    const pids = [
      0x0C, // RPM
      0x0D, // Speed
      0x05, // Engine coolant temp
      0x11, // Throttle position
      0x2F, // Fuel level
      0x04, // Engine load
      0xA5, // Current gear (proprietary)
      0xA6, // Odometer (proprietary)
      0xA7, // Accelerator pedal position (proprietary)
    ];
    
    int pidIndex = 0;
    
    // Опрашиваем каждые 100мс разные PID
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      requestOBD2Data(pids[pidIndex]);
      pidIndex = (pidIndex + 1) % pids.length;
    });
  }
  
  void _processCanFrame(Map<String, dynamic> frame) {
    final int canId = frame['id'] ?? 0;
    final List<dynamic> data = frame['data'] ?? [];
    
    // Обработка OBD-II ответов (0x7E8 - 0x7EF)
    if (canId >= 0x7E8 && canId <= 0x7EF) {
      _processOBD2Response(data);
    }
    
    // Можно добавить обработку других CAN сообщений
    // например, проприетарных сообщений автомобиля
  }
  
  void _processOBD2Response(List<dynamic> data) {
    if (data.length < 3) return;
    
    final int responseMode = data[1];
    if (responseMode != 0x41) return; // Не ответ на Mode 01
    
    final int pid = data[2];
    
    switch (pid) {
      case 0x0C: // RPM
        if (data.length >= 5) {
          final rpm = ((data[3] * 256) + data[4]) / 4.0;
          _lastValues['rpm'] = rpm;
        }
        break;
      case 0x0D: // Speed
        if (data.length >= 4) {
          _lastValues['speed'] = data[3].toDouble();
        }
        break;
      case 0x05: // Engine temp
        if (data.length >= 4) {
          _lastValues['engineTemp'] = data[3] - 40.0;
        }
        break;
      case 0x11: // Throttle
        if (data.length >= 4) {
          _lastValues['throttle'] = (data[3] * 100.0) / 255.0;
        }
        break;
      case 0x2F: // Fuel level
        if (data.length >= 4) {
          _lastValues['fuelLevel'] = (data[3] * 100.0) / 255.0;
        }
        break;
      case 0x04: // Engine load
        if (data.length >= 4) {
          _lastValues['engineLoad'] = (data[3] * 100.0) / 255.0;
        }
        break;
    }
    
    // Отправляем обновленные данные
    _dataController.add(Map<String, dynamic>.from(_lastValues));
  }
  
  @override
  Future<void> requestOBD2Data(int pid) async {
    try {
      final result = await platform.invokeMethod('readOBD2', pid);
      if (result != null && result is Map) {
        final name = result['name'] as String?;
        final value = (result['value'] as num?)?.toDouble();
        
        if (name != null && value != null) {
          // Update cached values based on response
          _lastValues[name] = value;
          
          // Send updated data through stream
          _dataController.add(Map<String, dynamic>.from(_lastValues));
          
          print('OBD2 response: $name = $value');
        }
      }
    } catch (e) {
      print('Failed to request OBD2 data: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final result = await platform.invokeMethod('getStats');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Failed to get stats: $e');
      return {};
    }
  }
  
  @override
  void dispose() {
    _pollingTimer?.cancel();
    _eventSubscription?.cancel();
    _dataController.close();
  }
}

/// Симулятор CAN для тестирования
class SimulatedCanBusService implements CanBusInterface {
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _simulationTimer;
  
  double _speed = 0;
  double _rpm = 800;
  double _engineTemp = 20;
  double _throttle = 0;
  double _fuelLevel = 75;
  double _engineLoad = 15;
  
  @override
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  @override
  Future<bool> initialize(String interface) async {
    // Имитация задержки инициализации
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Запуск симуляции
    _startSimulation();
    
    return true;
  }
  
  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Симуляция изменения значений
      _speed = (_speed + (DateTime.now().second % 3 - 1) * 2).clamp(0, 200);
      _rpm = (_rpm + (DateTime.now().millisecond % 100 - 50)).clamp(800, 7000);
      _engineTemp = (_engineTemp + 0.1).clamp(20, 95);
      _throttle = (math.sin(DateTime.now().millisecondsSinceEpoch / 1000) * 50 + 50).clamp(0, 100);
      _engineLoad = (_throttle * 0.8 + 10).clamp(10, 90);
      
      if (DateTime.now().second % 10 == 0) {
        _fuelLevel = (_fuelLevel - 0.1).clamp(0, 100);
      }
      
      // Отправка данных
      _dataController.add({
        'speed': _speed,
        'rpm': _rpm,
        'engineTemp': _engineTemp,
        'throttle': _throttle,
        'fuelLevel': _fuelLevel,
        'engineLoad': _engineLoad,
      });
    });
  }
  
  @override
  Future<void> requestOBD2Data(int pid) async {
    // В симуляторе ничего не делаем
  }
  
  @override
  Future<Map<String, dynamic>> getStats() async {
    return {
      'connected': true,
      'interface': 'simulator',
      'frames_sent': 0,
      'frames_received': DateTime.now().millisecondsSinceEpoch ~/ 100,
      'errors': 0,
    };
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    _dataController.close();
  }
}

/// Provider для CAN Bus сервиса
final canBusServiceProvider = Provider<CanBusInterface>((ref) {
  // Выбор реализации на основе флага
  final service = useSimulator 
      ? SimulatedCanBusService() 
      : RealCanBusService();
  
  // Автоматическая инициализация
  service.initialize('vcan0');
  
  // Очистка при удалении
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider для потока данных CAN
final canDataStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(canBusServiceProvider);
  return service.dataStream;
});

/// Provider для текущих данных CAN
final currentCanDataProvider = Provider<Map<String, dynamic>>((ref) {
  final asyncData = ref.watch(canDataStreamProvider);
  return asyncData.when(
    data: (data) => data,
    loading: () => {
      'speed': 0.0,
      'rpm': 0.0,
      'engineTemp': 0.0,
      'throttle': 0.0,
      'fuelLevel': 0.0,
      'engineLoad': 0.0,
      'gear': 1.0,
      'acceleratorPedal': 0.0,
    },
    error: (_, __) => {
      'speed': 0.0,
      'rpm': 0.0,
      'engineTemp': 0.0,
      'throttle': 0.0,
      'fuelLevel': 0.0,
      'engineLoad': 0.0,
      'gear': 1.0,
      'acceleratorPedal': 0.0,
    },
  );
});