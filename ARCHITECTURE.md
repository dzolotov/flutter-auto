# Архитектура проекта Flutter для автомобильных систем

## 📐 Архитектурный обзор

Проект построен с использованием **многослойной архитектуры** с четким разделением ответственности между компонентами. Архитектура оптимизирована для automotive grade требований: надежность, производительность, и безопасность.

## 🏗️ Общая структура

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
├─────────────────────────────────────────┤
│             Business Logic              │
├─────────────────────────────────────────┤
│              Data Layer                 │
├─────────────────────────────────────────┤
│            Platform Layer               │
└─────────────────────────────────────────┘
```

### 1. Presentation Layer (UI/UX)
**Расположение**: `/lib/apps/`

Содержит все UI компоненты, разделенные по функциональным модулям:

#### Dashboard Module
```
dashboard/
├── dashboard_app.dart              # Главный экран приборной панели
└── widgets/
    ├── speedometer_widget.dart     # Спидометр с CustomPainter
    ├── rpm_gauge_widget.dart       # Тахометр с анимациями
    ├── temperature_indicator.dart  # Температурные индикаторы
    ├── fuel_gauge_widget.dart      # Указатель топлива
    └── warning_lights_panel.dart   # Панель предупреждений
```

**Особенности**:
- **CustomPainter** для сложных графических элементов (стрелки, шкалы)
- **AnimationController** для плавных переходов стрелок приборов
- **StreamBuilder** для реактивного обновления данных
- **Responsive design** с использованием MediaQuery

#### Multimedia Module
```
multimedia/
├── multimedia_app.dart             # Мультимедийная система
└── widgets/
    ├── audio_zone_control.dart     # Управление аудиозонами
    ├── source_selector.dart        # Переключатель источников
    ├── media_player_widget.dart    # Медиаплеер
    ├── radio_tuner.dart           # FM радио тюнер
    └── equalizer_panel.dart        # 10-полосный эквалайзер
```

**Особенности**:
- **TabController** для навигации между функциями
- **Sliders** с кастомными темами для аудио управления
- **GridView** для отображения источников и настроек
- **Real-time updates** для радио частот и плейлистов

#### Multi-Display Module
```
multi_display/
├── multi_display_app.dart          # Управление мульти-дисплеем
└── widgets/
    ├── instrument_cluster_display.dart  # Приборная панель
    ├── infotainment_display.dart       # Инфотейнмент экран
    ├── heads_up_display.dart           # Проекционный дисплей
    ├── rear_passenger_display.dart     # Задние дисплеи
    └── display_configuration_panel.dart # Конфигурация дисплеев
```

**Особенности**:
- **Адаптивные макеты** для разных разрешений экранов
- **Конфигурируемые параметры** (яркость, поворот, режимы)
- **Синхронизация** между дисплеями
- **Fullscreen modes** для embedded систем

### 2. Business Logic Layer
**Расположение**: `/lib/services/`

Содержит всю бизнес-логику приложения, управляемую через Riverpod providers:

#### CAN Bus Simulator
```dart
class CanBusSimulator extends StateNotifier<Map<String, dynamic>> {
  Timer? _timer;
  double _baseSpeed = 0.0;
  double _baseRpm = 800.0;
  
  // Симуляция различных сценариев вождения
  void _simulateDrivingScenarios(Map<String, dynamic> data) {
    switch (scenario) {
      case 0: _simulateParking(data); break;
      case 1: _simulateAcceleration(data); break;
      case 2: _simulateCityDriving(data); break;
      // ...
    }
  }
  
  // Взаимосвязанные параметры
  double _calculateRpmForSpeed(double speed, int gear) {
    final gearRatios = [0, 3.5, 2.1, 1.4, 1.0, 0.8, 0.65];
    final finalDriveRatio = 3.73;
    // Реалистичный расчет RPM
  }
}
```

**Особенности**:
- **Реалистичная симуляция** с физически корректными данными
- **Temporal consistency** - данные изменяются логично во времени
- **Error injection** для тестирования обработки сбоев
- **Configurable scenarios** для различных условий

#### Audio Manager
```dart
class AudioManager extends StateNotifier<AudioSystemState> {
  // Управление аудиозонами
  void setZoneVolume(int zoneIndex, double volume);
  void setZoneBalance(int zoneIndex, double balance);
  
  // Синхронизация источников
  void setZoneSource(int zoneIndex, AudioSource source);
  
  // Эквалайзер с предустановками
  void setZoneEqualizer(int zoneIndex, EqualizerSettings eq);
}

class AudioSystemState {
  final List<AudioZone> zones;        // Независимые аудиозоны
  final double globalVolume;          // Общая громкость
  final bool mirroringEnabled;        // Зеркалирование
}
```

**Особенности**:
- **Independent zones** для разных областей автомобиля
- **Real-time synchronization** между зонами
- **Preset management** для эквалайзера
- **Adaptive volume** в зависимости от скорости

#### Display Manager
```dart
class DisplayManager extends StateNotifier<DisplaySystemState> {
  // Конфигурация дисплеев
  void setDisplayBrightness(String displayId, double brightness);
  void rotateDisplay(String displayId);
  void setDisplayMode(String displayId, DisplayMode mode);
  
  // Синхронизация дисплеев
  void syncAllDisplays();
  void enableMirroring();
}

enum DisplayType {
  instrumentCluster,    // 1920x720
  infotainment,        // 1920x1080  
  headsUp,             // 800x480
  rearPassenger,       // 1280x800
}
```

**Особенности**:
- **Multi-display coordination** с независимым управлением
- **Adaptive brightness** в зависимости от времени суток
- **Hot-swappable** конфигурации без перезапуска
- **Failover mechanisms** при отказе дисплеев

### 3. Data Layer
**Расположение**: `/lib/models/` и состояние в сервисах

Модели данных и их управление:

#### Vehicle Data Models
```dart
class VehicleState {
  final double speed;           // км/ч
  final double rpm;            // об/мин
  final String gear;           // P/R/N/D/1-6
  final double engineTemp;     // °C
  final double fuelLevel;      // %
  final Map<String, bool> warnings; // Системные предупреждения
}

class AudioZone {
  final String name;           // "Водитель", "Пассажир", etc
  final double volume;         // 0.0 - 1.0
  final double balance;        // -1.0 (L) to 1.0 (R)
  final double fade;           // -1.0 (Rear) to 1.0 (Front)
  final AudioSource currentSource;
  final EqualizerSettings equalizer;
}
```

#### Persistence Layer
```dart
// Использование Hive для локального хранения
@HiveType(typeId: 0)
class UserPreferences extends HiveObject {
  @HiveField(0)
  Map<String, double> volumeSettings;
  
  @HiveField(1)
  Map<String, EqualizerSettings> equalizerPresets;
  
  @HiveField(2)
  DisplayConfiguration displayConfig;
}
```

### 4. Platform Layer
**Расположение**: `/lib/platforms/`

Интеграция с нативными платформами и embedded системами:

#### Flutter-pi Integration
```dart
class FlutterPiIntegration {
  static const MethodChannel _platformChannel = 
      MethodChannel('automotive/platform');
  
  // GPIO управление
  static Future<void> _setupGpioIntegration() async {
    await _platformChannel.invokeMethod('setupGPIO', {
      'pins': {
        'button_home': 18,
        'button_back': 19,
        'rotary_encoder_a': 20,
        'rotary_encoder_b': 21,
        'brightness_control': 12,
        'status_led': 13,
      }
    });
  }
  
  // Системный мониторинг
  static Future<double> getCpuTemperature() async {
    final result = await _platformChannel.invokeMethod('getCpuTemperature');
    return (result as num).toDouble();
  }
}
```

## 🔄 Паттерны и принципы

### 1. State Management Architecture

Использует **Riverpod** с четкой иерархией providers:

```dart
// Global CAN data provider
final canBusProvider = StateNotifierProvider<CanBusSimulator, Map<String, dynamic>>(
  (ref) => CanBusSimulator(),
);

// Audio system provider
final audioManagerProvider = StateNotifierProvider<AudioManager, AudioSystemState>(
  (ref) => AudioManager(),
);

// Display system provider  
final displayManagerProvider = StateNotifierProvider<DisplayManager, DisplaySystemState>(
  (ref) => DisplayManager(),
);
```

**Преимущества**:
- **Reactive updates** - UI автоматически обновляется при изменении данных
- **Provider composition** - сложная логика составляется из простых providers
- **Testability** - легко мокать providers для тестирования
- **Performance** - только нужные виджеты перестраиваются

### 2. Widget Composition Pattern

Сложные UI компоненты построены из переиспользуемых виджетов:

```dart
// Композиция спидометра
class SpeedometerWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SpeedometerPainter(
        speed: _speedAnimation.value,
        maxSpeed: widget.maxSpeed,
      ),
      child: Center(
        child: _buildDigitalDisplay(), // Переиспользуемый компонент
      ),
    );
  }
}
```

### 3. Animation Architecture

Оптимизированные анимации для automotive grade производительности:

```dart
class _SpeedometerWidgetState extends State<SpeedometerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _speedAnimation;

  void _updateSpeed() {
    _speedAnimation = Tween<double>(
      begin: _previousSpeed,
      end: widget.speed,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Физически корректная кривая
    ));
    _animationController.forward(from: 0.0);
  }
}
```

**Особенности**:
- **60 FPS** с константным потреблением памяти
- **Физически корректные** кривые анимации
- **Graceful degradation** на медленных устройствах
- **Batch updates** для множественных анимаций

### 4. Error Handling Strategy

Многоуровневая система обработки ошибок:

```dart
// Service level error handling
class CanBusSimulator extends StateNotifier<Map<String, dynamic>> {
  @override
  void dispose() {
    _timer?.cancel(); // Cleanup resources
    super.dispose();
  }
  
  void _handleError(dynamic error) {
    _logger.e('CAN Bus error: $error');
    // Fallback to safe default values
    state = _createSafeDefaults();
  }
}

// UI level error handling  
class DashboardApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(canBusProvider).when(
      data: (data) => _buildDashboard(data),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }
}
```

## 🎯 Performance Optimizations

### 1. Efficient Rendering

```dart
class SpeedometerPainter extends CustomPainter {
  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    // Только перерисовка при значимых изменениях
    return oldDelegate.speed != speed || 
           (oldDelegate.speed - speed).abs() > 0.5;
  }
}
```

### 2. Memory Management

```dart
// Пулинг объектов для часто используемых компонентов
class WidgetPool<T extends Widget> {
  final Queue<T> _pool = Queue();
  
  T acquire() => _pool.isNotEmpty ? _pool.removeFirst() : _create();
  void release(T widget) => _pool.add(widget);
}
```

### 3. Lazy Loading

```dart
// Ленивая инициализация тяжелых компонентов
late final _equalizerPanel = EqualizerPanel();
late final _radioTuner = RadioTuner();

Widget _buildCurrentTab() {
  switch (_selectedTab) {
    case 2: return _equalizerPanel; // Создается только при первом обращении
    case 3: return _radioTuner;
    default: return _buildDefaultTab();
  }
}
```

## 🔧 Configuration Management

### 1. Environment-based Configuration

```dart
class AppConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION');
  static const String canBusInterface = String.fromEnvironment(
    'CAN_INTERFACE', 
    defaultValue: 'can0'
  );
  static const int updateFrequencyMs = int.fromEnvironment(
    'UPDATE_FREQUENCY',
    defaultValue: 100
  );
}
```

### 2. Feature Flags

```dart
class FeatureFlags {
  static const bool enableRealCanBus = bool.fromEnvironment('REAL_CAN_BUS');
  static const bool enableVoiceControl = bool.fromEnvironment('VOICE_CONTROL');
  static const bool enableCloudSync = bool.fromEnvironment('CLOUD_SYNC');
}
```

## 🧪 Testing Architecture

### 1. Unit Testing Strategy

```dart
// Тестирование бизнес-логики
void main() {
  group('CanBusSimulator', () {
    late CanBusSimulator simulator;
    
    setUp(() {
      simulator = CanBusSimulator();
    });
    
    test('should generate realistic RPM for speed', () {
      final rpm = simulator.calculateRpmForSpeed(60.0, 4);
      expect(rpm, inRange(1500.0, 2500.0)); // Реалистичный диапазон
    });
  });
}
```

### 2. Widget Testing

```dart
void main() {
  testWidgets('Speedometer displays correct speed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canBusProvider.overrideWith((ref) => MockCanBusSimulator()),
        ],
        child: MaterialApp(home: SpeedometerWidget(speed: 80.0)),
      ),
    );
    
    expect(find.text('80'), findsOneWidget);
    expect(find.text('км/ч'), findsOneWidget);
  });
}
```

### 3. Integration Testing

```dart
void main() {
  group('Dashboard Integration', () {
    testWidgets('should update all gauges when CAN data changes', (tester) async {
      // Полный интеграционный тест приборной панели
    });
  });
}
```

## 🔐 Security Considerations

### 1. Input Validation

```dart
class CanDataValidator {
  static bool isValidSpeed(double speed) => speed >= 0 && speed <= 300;
  static bool isValidRpm(double rpm) => rpm >= 0 && rpm <= 10000;
  static bool isValidTemperature(double temp) => temp >= -40 && temp <= 150;
}
```

### 2. Secure Storage

```dart
// Шифрование чувствительных настроек
class SecurePreferences {
  static Future<void> setEncryptedValue(String key, String value) async {
    final encrypted = await _encrypt(value);
    await Hive.box('secure').put(key, encrypted);
  }
}
```

## 📊 Monitoring and Observability

### 1. Performance Monitoring

```dart
class PerformanceMonitor {
  static void trackFrameRate() {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameTime = timing.totalSpan.inMicroseconds / 1000.0;
        if (frameTime > 16.67) { // > 60 FPS
          _logger.w('Slow frame detected: ${frameTime}ms');
        }
      }
    });
  }
}
```

### 2. Error Tracking

```dart
class ErrorTracker {
  static void reportError(dynamic error, StackTrace stackTrace) {
    _logger.e('Error occurred', error, stackTrace);
    
    // В production можно интегрировать с Crashlytics/Sentry
    if (AppConfig.isProduction) {
      // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }
}
```

## 🚀 Deployment Strategy

### 1. Build Configurations

```bash
# Debug сборка для разработки
flutter build linux --debug --dart-define=ENVIRONMENT=debug

# Production сборка для автомобилей  
flutter build linux --release --dart-define=ENVIRONMENT=production --dart-define=REAL_CAN_BUS=true

# Embedded сборка для Raspberry Pi
flutter build linux --release --target-platform=linux-arm64 --dart-define=FLUTTER_PI=true
```

### 2. Continuous Integration

```yaml
# .github/workflows/automotive.yml
name: Automotive CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter build linux --release
```

## 📈 Scalability Considerations

Архитектура спроектирована для масштабирования:

1. **Модульная структура** - новые функции добавляются как отдельные модули
2. **Plugin architecture** - сторонние интеграции через plugins
3. **Microservices ready** - сервисы могут быть выделены в отдельные процессы
4. **Cloud integration** - готовность к интеграции с облачными сервисами
5. **Multi-platform** - код переиспользуется на разных платформах

Эта архитектура обеспечивает надежность, производительность и возможность развития проекта в соответствии с требованиями автомобильной индустрии.