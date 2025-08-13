import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Простой провайдер для демонстрации с рандомными значениями
final randomDataProvider = StateNotifierProvider<RandomDataSimulator, Map<String, dynamic>>((ref) {
  return RandomDataSimulator();
});

/// Простой симулятор с рандомными значениями для демонстрации
/// Генерирует реалистичные автомобильные данные без подключения к CAN шине
class RandomDataSimulator extends StateNotifier<Map<String, dynamic>> {
  Timer? _timer;
  final math.Random _random = math.Random();
  
  // Базовые значения для плавных изменений
  double _baseSpeed = 0.0;
  double _baseRpm = 800.0;
  double _baseFuelLevel = 65.0;
  double _baseEngineTemp = 20.0; // Начинаем с холодного двигателя
  double _baseOilTemp = 20.0;
  double _throttle = 0.0;
  double _brake = 0.0;
  bool _engineStarted = false;
  int _currentScenario = 0;
  int _scenarioTimer = 0;
  String _currentGear = 'P'; // Начинаем с паркинга

  RandomDataSimulator() : super({}) {
    _initializeValues();
    _startSimulation();
  }

  /// Инициализация начальных значений
  void _initializeValues() {
    state = {
      // Основные параметры движения
      'speed': 0.0,
      'rpm': 800.0,
      'gear': 'P',
      
      // Температуры
      'engine_temp': 90.0,
      'oil_temp': 85.0,
      'outside_temp': 22.0,
      
      // Уровни и давления
      'fuel_level': 65.0,
      'oil_pressure': 2.5,
      'battery_voltage': 12.6,
      
      // Индикаторы
      'abs_warning': false,
      'engine_warning': false,
      'oil_warning': false,
      'fuel_warning': false,
      'seatbelt_fastened': true,
      'left_turn_signal': false,
      'right_turn_signal': false,
      'headlights': false,
      'fog_lights': false,
      
      // Дополнительные параметры
      'throttle_position': 0.0,
      'brake_pressure': 0.0,
      'intake_air_temp': 25.0,
      'mass_air_flow': 3.5,
      'fuel_pressure': 3.5,
      'boost_pressure': 0.0,
      
      // Система климат-контроля
      'cabin_temp': 22.0,
      'hvac_fan_speed': 0,
      'ac_compressor': false,
      
      // Максимальные значения для калибровки
      'max_speed': 240.0,
      'max_rpm': 8000.0,
      'redline_rpm': 6500.0,
      'idle_rpm': 800.0,
      
      // Передача и тип трансмиссии
      'transmission_type': 'auto',
      'is_shifting': false,
      
      // Одометры
      'odometer': 45623.4,
      'trip_meter': 156.8,
    };
  }

  /// Запуск симуляции
  void _startSimulation() {
    // Запускаем двигатель через 2 секунды
    Future.delayed(Duration(seconds: 2), () {
      _engineStarted = true;
    });
    
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      try {
        _updateSimulation();
        _scenarioTimer++;
        
        // Смена сценария каждые 10 секунд
        if (_scenarioTimer >= 100) {
          _currentScenario = (_currentScenario + 1) % 5;
          _scenarioTimer = 0;
        }
      } catch (e) {
        debugPrint('Random simulation error: $e');
      }
    });
  }

  /// Обновление симуляции
  void _updateSimulation() {
    final newState = Map<String, dynamic>.from(state);
    
    // Выбираем сценарий
    switch (_currentScenario) {
      case 0: // Стоянка
        _simulateParking(newState);
        break;
      case 1: // Медленная езда
        _simulateSlowDriving(newState);
        break;
      case 2: // Городская езда
        _simulateCityDriving(newState);
        break;
      case 3: // Динамичная езда
        _simulateDynamicDriving(newState);
        break;
      case 4: // Трасса
        _simulateHighwayDriving(newState);
        break;
    }
    
    // Обновляем дополнительные параметры
    _updateAdditionalParameters(newState);
    _updateIndicators(newState);
    _updateOdometers(newState);
    
    state = newState;
  }

  /// Сценарий: стоянка
  void _simulateParking(Map<String, dynamic> data) {
    // На парковке скорость всегда 0
    _baseSpeed = 0.0;
    _currentGear = 'P';
    _throttle = 0.0;
    _brake = 100.0; // Ручник затянут
    
    // Двигатель работает на холостых если запущен
    if (_engineStarted) {
      _baseRpm = 800.0 + _random.nextDouble() * 50.0;
    } else {
      _baseRpm = 0.0;
    }
    
    data['speed'] = _baseSpeed;
    data['rpm'] = _baseRpm;
    data['gear'] = _currentGear;
    data['throttle_position'] = _throttle;
    data['brake_pressure'] = _brake;
  }

  /// Сценарий: медленная езда
  void _simulateSlowDriving(Map<String, dynamic> data) {
    if (!_engineStarted) {
      _simulateParking(data);
      return;
    }
    
    // Переключаемся на D если были на P
    if (_currentGear == 'P') {
      _currentGear = 'D';
    }
    
    final targetSpeed = 10.0 + _random.nextDouble() * 20.0;
    _throttle = 15.0 + _random.nextDouble() * 20.0;
    _brake = _random.nextDouble() * 5.0;
    
    // Физика ускорения/торможения
    if (_throttle > _brake) {
      _baseSpeed = _smoothTransition(_baseSpeed, targetSpeed, 0.3);
    } else {
      _baseSpeed = _smoothTransition(_baseSpeed, 0.0, 0.5);
    }
    
    // Автоматическая коробка передач
    _currentGear = _getAutomaticGear(_baseSpeed);
    
    // RPM зависят от скорости и передачи
    _baseRpm = _calculateRpm(_baseSpeed, _currentGear);
    
    data['speed'] = _baseSpeed;
    data['rpm'] = _baseRpm;
    data['gear'] = _currentGear;
    data['throttle_position'] = _throttle;
    data['brake_pressure'] = _brake;
  }

  /// Сценарий: городская езда
  void _simulateCityDriving(Map<String, dynamic> data) {
    if (!_engineStarted) {
      _simulateParking(data);
      return;
    }
    
    if (_currentGear == 'P') {
      _currentGear = 'D';
    }
    
    final targetSpeed = 30.0 + _random.nextDouble() * 30.0;
    _throttle = 25.0 + _random.nextDouble() * 35.0;
    
    // Периодическое торможение в городе
    if (_random.nextInt(20) == 0) {
      _brake = 20.0 + _random.nextDouble() * 30.0;
    } else {
      _brake = _random.nextDouble() * 5.0;
    }
    
    // Физика
    if (_throttle > _brake * 2) {
      _baseSpeed = _smoothTransition(_baseSpeed, targetSpeed, 0.5);
    } else if (_brake > 10) {
      _baseSpeed = _smoothTransition(_baseSpeed, _baseSpeed * 0.7, 0.8);
    }
    
    _currentGear = _getAutomaticGear(_baseSpeed);
    _baseRpm = _calculateRpm(_baseSpeed, _currentGear);
    
    data['speed'] = _baseSpeed;
    data['rpm'] = _baseRpm;
    data['gear'] = _currentGear;
    data['throttle_position'] = _throttle;
    data['brake_pressure'] = _brake;
  }

  /// Сценарий: динамичная езда
  void _simulateDynamicDriving(Map<String, dynamic> data) {
    if (!_engineStarted) {
      _simulateParking(data);
      return;
    }
    
    if (_currentGear == 'P') {
      _currentGear = 'D';
    }
    
    final targetSpeed = 60.0 + _random.nextDouble() * 40.0;
    _throttle = 50.0 + _random.nextDouble() * 40.0;
    
    // Агрессивное ускорение
    if (_random.nextInt(10) < 7) {
      _brake = 0.0;
      _baseSpeed = _smoothTransition(_baseSpeed, targetSpeed, 0.8);
    } else {
      // Периодическое торможение
      _brake = 10.0 + _random.nextDouble() * 20.0;
      _baseSpeed = _smoothTransition(_baseSpeed, _baseSpeed * 0.8, 0.6);
    }
    
    _currentGear = _getAutomaticGear(_baseSpeed);
    _baseRpm = _calculateRpm(_baseSpeed, _currentGear);
    
    // При динамичной езде обороты выше
    if (_throttle > 70) {
      _baseRpm = math.min(_baseRpm + 500, 5500.0);
    }
    
    data['speed'] = _baseSpeed;
    data['rpm'] = _baseRpm;
    data['gear'] = _currentGear;
    data['throttle_position'] = _throttle;
    data['brake_pressure'] = _brake;
    data['is_shifting'] = _random.nextInt(30) == 0;
  }

  /// Сценарий: трасса
  void _simulateHighwayDriving(Map<String, dynamic> data) {
    if (!_engineStarted) {
      _simulateParking(data);
      return;
    }
    
    if (_currentGear == 'P') {
      _currentGear = 'D';
    }
    
    final targetSpeed = 90.0 + _random.nextDouble() * 40.0;
    _throttle = 40.0 + _random.nextDouble() * 25.0;
    _brake = _random.nextDouble() * 3.0; // Минимальное торможение на трассе
    
    // Плавное движение на крейсерской скорости
    _baseSpeed = _smoothTransition(_baseSpeed, targetSpeed, 0.3);
    
    // На трассе обычно высшие передачи
    _currentGear = _getAutomaticGear(_baseSpeed);
    _baseRpm = _calculateRpm(_baseSpeed, _currentGear);
    
    // На трассе обороты экономичные
    if (_baseSpeed > 90 && _currentGear == '6') {
      _baseRpm = math.min(_baseRpm, 2500.0);
    }
    
    data['speed'] = _baseSpeed;
    data['rpm'] = _baseRpm;
    data['gear'] = _currentGear;
    data['throttle_position'] = _throttle;
    data['brake_pressure'] = _brake;
  }

  /// Обновление дополнительных параметров
  void _updateAdditionalParameters(Map<String, dynamic> data) {
    // Температуры - прогреваются постепенно если двигатель работает
    if (_engineStarted) {
      final targetEngineTemp = 88.0 + (data['rpm'] > 3000 ? 8.0 : 0.0);
      _baseEngineTemp = _smoothTransition(_baseEngineTemp, targetEngineTemp, 0.005); // Медленный прогрев
      data['engine_temp'] = _baseEngineTemp + _random.nextDouble() * 2.0 - 1.0;
      
      _baseOilTemp = _smoothTransition(_baseOilTemp, _baseEngineTemp - 5.0, 0.003);
      data['oil_temp'] = _baseOilTemp + _random.nextDouble() * 2.0 - 1.0;
    } else {
      // Двигатель остывает если выключен
      _baseEngineTemp = _smoothTransition(_baseEngineTemp, 20.0, 0.001);
      _baseOilTemp = _smoothTransition(_baseOilTemp, 20.0, 0.001);
      data['engine_temp'] = _baseEngineTemp;
      data['oil_temp'] = _baseOilTemp;
    }
    
    data['outside_temp'] = 18.0 + _random.nextDouble() * 12.0;
    
    // Уровни и давления
    final fuelConsumption = (data['rpm'] / 10000.0 + data['throttle_position'] / 5000.0) * 0.01;
    _baseFuelLevel = math.max(0.0, _baseFuelLevel - fuelConsumption);
    data['fuel_level'] = _baseFuelLevel;
    
    data['oil_pressure'] = 2.0 + (data['rpm'] / 1000.0) * 0.8 + _random.nextDouble() * 0.4;
    data['battery_voltage'] = 12.4 + _random.nextDouble() * 0.6;
    
    // Воздух и топливо
    data['intake_air_temp'] = 20.0 + (data['rpm'] / 200.0) + _random.nextDouble() * 10.0;
    data['mass_air_flow'] = 2.0 + (data['rpm'] / 500.0) + (data['throttle_position'] / 20.0);
    data['fuel_pressure'] = 3.0 + (data['rpm'] / 2000.0) + _random.nextDouble() * 0.8;
    
    // Климат
    data['cabin_temp'] = 20.0 + _random.nextDouble() * 6.0;
  }

  /// Обновление индикаторов
  void _updateIndicators(Map<String, dynamic> data) {
    // Предупреждения
    data['fuel_warning'] = data['fuel_level'] < 15.0;
    data['engine_warning'] = data['engine_temp'] > 110.0;
    data['oil_warning'] = data['oil_pressure'] < 1.5;
    
    // Случайные индикаторы
    if (_random.nextInt(200) == 0) {
      data['left_turn_signal'] = !data['left_turn_signal'];
      data['right_turn_signal'] = false;
    } else if (_random.nextInt(200) == 0) {
      data['right_turn_signal'] = !data['right_turn_signal'];
      data['left_turn_signal'] = false;
    } else if (_random.nextInt(100) == 0) {
      data['left_turn_signal'] = false;
      data['right_turn_signal'] = false;
    }
    
    // Фары
    if (_random.nextInt(300) == 0) {
      data['headlights'] = !data['headlights'];
    }
    
    // Кондиционер
    if (_random.nextInt(400) == 0) {
      data['ac_compressor'] = !data['ac_compressor'];
    }
    
    // Скорость вентилятора
    if (_random.nextInt(500) == 0) {
      data['hvac_fan_speed'] = _random.nextInt(8);
    }
  }

  /// Обновление одометров
  void _updateOdometers(Map<String, dynamic> data) {
    final speed = data['speed']?.toDouble() ?? 0.0;
    final deltaKm = (speed / 3600.0) * 0.1; // 100мс в часах
    
    data['odometer'] = (data['odometer'] ?? 0.0) + deltaKm;
    data['trip_meter'] = (data['trip_meter'] ?? 0.0) + deltaKm;
  }

  /// Получение автоматической передачи для скорости
  String _getAutomaticGear(double speed) {
    if (speed < 0.1) return 'D'; // Стоим на месте в D
    if (speed < 15) return '1';
    if (speed < 30) return '2';
    if (speed < 50) return '3';
    if (speed < 75) return '4';
    if (speed < 100) return '5';
    return '6';
  }
  
  /// Расчет RPM на основе скорости и передачи
  double _calculateRpm(double speed, String gear) {
    if (!_engineStarted) return 0.0;
    
    // Базовые обороты холостого хода
    double baseIdle = 800.0;
    
    // Коэффициенты для каждой передачи
    double ratio;
    switch (gear) {
      case 'P':
      case 'N':
        return baseIdle + _random.nextDouble() * 50.0;
      case 'D':
        if (speed < 0.1) return baseIdle + _random.nextDouble() * 100.0;
        ratio = 60.0;
        break;
      case '1':
        ratio = 60.0;
        break;
      case '2':
        ratio = 45.0;
        break;
      case '3':
        ratio = 35.0;
        break;
      case '4':
        ratio = 28.0;
        break;
      case '5':
        ratio = 23.0;
        break;
      case '6':
        ratio = 20.0;
        break;
      default:
        ratio = 30.0;
    }
    
    // RPM = базовые обороты + (скорость * коэффициент передачи) + немного случайности
    double rpm = baseIdle + (speed * ratio) + _random.nextDouble() * 200.0;
    
    // Ограничиваем максимальные обороты
    return math.min(rpm, 6500.0);
  }

  /// Плавный переход значений
  double _smoothTransition(double current, double target, double rate) {
    final difference = target - current;
    final maxChange = rate * 0.1;
    
    if (difference.abs() <= maxChange) {
      return target;
    } else {
      return current + (difference > 0 ? maxChange : -maxChange);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}