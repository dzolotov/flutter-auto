import 'dart:math' as math;

/// Сервис физической симуляции для реалистичного поведения приборных стрелок
/// Реализует инерцию, демпфирование и эластичность движения стрелок
/// Оптимизирован для работы на встраиваемых системах с частотой 60 FPS
class PhysicsSimulation {
  // Физические константы для автомобильных приборов
  static const double _defaultStiffness = 150.0;     // Жесткость пружины
  static const double _defaultDamping = 12.0;        // Коэффициент затухания
  static const double _defaultMass = 1.0;            // Масса стрелки
  static const double _tolerance = 0.001;            // Допуск для остановки симуляции
  static const double _maxVelocity = 500.0;          // Максимальная скорость движения

  double _position = 0.0;      // Текущее положение стрелки
  double _velocity = 0.0;      // Текущая скорость
  double _target = 0.0;        // Целевое положение
  
  final double stiffness;      // Жесткость пружины (влияет на скорость достижения цели)
  final double damping;        // Затухание (влияет на колебания)
  final double mass;           // Масса (влияет на инерцию)

  PhysicsSimulation({
    this.stiffness = _defaultStiffness,
    this.damping = _defaultDamping, 
    this.mass = _defaultMass,
    double initialPosition = 0.0,
  }) : _position = initialPosition;

  /// Текущее положение стрелки
  double get position => _position;
  
  /// Текущая скорость движения
  double get velocity => _velocity;
  
  /// Целевое положение
  double get target => _target;
  
  /// Проверяет, достигла ли стрелка покоя (остановилась)
  bool get isAtRest {
    return _velocity.abs() < _tolerance && 
           (_target - _position).abs() < _tolerance;
  }

  /// Устанавливает новую цель для движения стрелки
  /// [newTarget] - новое целевое значение
  /// [immediate] - если true, стрелка мгновенно перемещается к цели
  void setTarget(double newTarget, {bool immediate = false}) {
    _target = newTarget;
    
    if (immediate) {
      _position = newTarget;
      _velocity = 0.0;
    }
  }

  /// Обновляет симуляцию на один шаг
  /// [deltaTime] - время с предыдущего обновления в секундах (обычно 1/60 для 60 FPS)
  /// Возвращает true, если положение изменилось
  bool update(double deltaTime) {
    if (isAtRest) return false;

    // Расчет силы упругости (закон Гука: F = -k * x)
    final displacement = _target - _position;
    final springForce = stiffness * displacement;
    
    // Расчет силы трения/демпфирования (F = -b * v)
    final dampingForce = -damping * _velocity;
    
    // Общая сила, действующая на стрелку
    final totalForce = springForce + dampingForce;
    
    // Ускорение (F = m * a => a = F / m)
    final acceleration = totalForce / mass;
    
    // Интегрирование методом Эйлера для обновления скорости и положения
    _velocity += acceleration * deltaTime;
    
    // Ограничение максимальной скорости для предотвращения нестабильности
    _velocity = _velocity.clamp(-_maxVelocity, _maxVelocity);
    
    _position += _velocity * deltaTime;
    
    // Проверка на остановку для оптимизации производительности
    if (_velocity.abs() < _tolerance && displacement.abs() < _tolerance) {
      _position = _target;
      _velocity = 0.0;
    }
    
    return true;
  }

  /// Мгновенно устанавливает положение без анимации
  void setPosition(double position) {
    _position = position;
    _target = position;
    _velocity = 0.0;
  }

  /// Сброс симуляции в исходное состояние
  void reset() {
    _position = 0.0;
    _velocity = 0.0;
    _target = 0.0;
  }
}

/// Специализированная физическая симуляция для спидометра
/// Учитывает особенности автомобильных спидометров - более плавное движение
class SpeedometerPhysics extends PhysicsSimulation {
  SpeedometerPhysics({double initialPosition = 0.0})
      : super(
          stiffness: 120.0,     // Менее жесткая пружина для плавности
          damping: 15.0,        // Больше затухания для стабильности
          mass: 1.2,            // Немного больше инерции
          initialPosition: initialPosition,
        );
}

/// Специализированная физическая симуляция для тахометра
/// Более быстрая реакция для отражения изменений оборотов двигателя
class TachometerPhysics extends PhysicsSimulation {
  TachometerPhysics({double initialPosition = 0.0})
      : super(
          stiffness: 200.0,     // Более жесткая пружина для быстрой реакции
          damping: 10.0,        // Меньше затухания для быстрого отклика
          mass: 0.8,            // Меньше инерции для моментального отклика
          initialPosition: initialPosition,
        );
}

/// Физическая симуляция для индикаторов температуры и уровня топлива
/// Более медленная и плавная для отражения инерционности этих систем
class LinearGaugePhysics extends PhysicsSimulation {
  LinearGaugePhysics({double initialPosition = 0.0})
      : super(
          stiffness: 80.0,      // Низкая жесткость для медленного движения
          damping: 20.0,        // Высокое затухание для плавности
          mass: 1.5,            // Большая инерция для медленных изменений
          initialPosition: initialPosition,
        );
}

/// Менеджер физических симуляций для оптимизации производительности
/// Управляет обновлением всех симуляций и отключает неактивные
class PhysicsManager {
  final Map<String, PhysicsSimulation> _simulations = {};
  bool _isRunning = false;
  
  /// Регистрирует новую симуляцию
  void registerSimulation(String id, PhysicsSimulation simulation) {
    _simulations[id] = simulation;
  }
  
  /// Удаляет симуляцию
  void unregisterSimulation(String id) {
    _simulations.remove(id);
  }
  
  /// Получает симуляцию по ID
  PhysicsSimulation? getSimulation(String id) {
    return _simulations[id];
  }
  
  /// Обновляет все активные симуляции
  /// Возвращает количество обновленных симуляций для мониторинга производительности
  int updateAll(double deltaTime) {
    if (!_isRunning) return 0;
    
    int updatedCount = 0;
    _simulations.forEach((id, simulation) {
      if (simulation.update(deltaTime)) {
        updatedCount++;
      }
    });
    
    return updatedCount;
  }
  
  /// Запуск менеджера симуляций
  void start() {
    _isRunning = true;
  }
  
  /// Остановка менеджера симуляций для экономии ресурсов
  void stop() {
    _isRunning = false;
  }
  
  /// Проверяет, активны ли какие-либо симуляции
  bool get hasActiveSimulations {
    return _simulations.values.any((sim) => !sim.isAtRest);
  }
  
  /// Сброс всех симуляций
  void resetAll() {
    _simulations.forEach((id, simulation) {
      simulation.reset();
    });
  }
}