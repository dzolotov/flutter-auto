# Руководство по разработке

## 🛠️ Среда разработки

### Требования к системе

#### Минимальные требования
- **OS**: Windows 10/macOS 10.14/Ubuntu 18.04 или новее
- **RAM**: 8GB (рекомендуется 16GB)
- **Storage**: 10GB свободного места
- **Flutter**: 3.10.0 или новее
- **Dart**: 3.0.0 или новее

#### Дополнительные инструменты
- **VS Code** с Flutter/Dart расширениями
- **Android Studio** для Android разработки
- **Git** для версионирования
- **Docker** для тестирования embedded окружения

### Настройка окружения

```bash
# Проверка Flutter установки
flutter doctor

# Включение поддержки платформ
flutter config --enable-linux-desktop
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop

# Установка дополнительных инструментов
dart pub global activate flutter_gen
dart pub global activate coverage
```

## 📋 Code Style и Guidelines

### Dart Style Guide

Проект следует [Official Dart Style Guide](https://dart.dev/guides/language/effective-dart) с дополнениями:

#### Именование
```dart
// Классы - PascalCase
class SpeedometerWidget extends StatefulWidget {}

// Методы и переменные - camelCase  
void updateSpeedValue() {}
double currentSpeed = 0.0;

// Константы - lowerCamelCase
static const double maxSpeedLimit = 220.0;

// Перечисления - PascalCase
enum DisplayType { instrumentCluster, infotainment }

// Файлы - snake_case
speedometer_widget.dart
can_bus_simulator.dart
```

#### Комментарии на русском языке
```dart
/// Виджет спидометра с аналоговым циферблатом
/// Оптимизирован для автомобильных дисплеев с высокой читаемостью
class SpeedometerWidget extends StatefulWidget {
  /// Текущая скорость в км/ч
  final double speed;
  
  /// Максимальная скорость на шкале
  final double maxSpeed;
  
  /// Показывать ли цифровой дисплей в центре
  final bool showDigital;
}
```

### Структура файлов

```dart
// 1. Импорты Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 2. Импорты сторонних пакетов
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// 3. Импорты локальных файлов
import '../../../core/theme/automotive_theme.dart';
import '../../../services/can_bus_simulator.dart';

// 4. Пустая строка перед основным кодом

/// Документация класса
class MyWidget extends ConsumerWidget {
  // Константы класса
  static const double _defaultValue = 0.0;
  
  // Поля класса
  final String title;
  final VoidCallback onPressed;
  
  // Конструктор
  const MyWidget({
    super.key,
    required this.title,
    required this.onPressed,
  });
  
  // Методы
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Реализация
  }
  
  // Приватные методы в конце
  void _handleTap() {
    // Реализация
  }
}
```

### Архитектурные правила

1. **Separation of Concerns** - каждый класс имеет одну ответственность
2. **Dependency Injection** через Riverpod providers
3. **Immutable State** - состояние изменяется только через copyWith
4. **Error Handling** - всегда обрабатывать ошибки gracefully
5. **Performance First** - оптимизация с самого начала

## 🏗️ Паттерны разработки

### 1. State Management с Riverpod

#### Provider Definition
```dart
// services/my_service.dart
final myServiceProvider = StateNotifierProvider<MyService, MyState>((ref) {
  return MyService(ref.read(otherServiceProvider));
});

class MyService extends StateNotifier<MyState> {
  MyService(this._otherService) : super(MyState.initial());
  
  final OtherService _otherService;
  
  void updateData(String newData) {
    state = state.copyWith(data: newData);
  }
}
```

#### State Consumption
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myServiceProvider);
    
    return state.when(
      data: (data) => _buildContent(data),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => _buildError(error),
    );
  }
}
```

### 2. Custom Painter для автомобильных приборов

```dart
class GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color needleColor;
  
  const GaugePainter({
    required this.value,
    required this.maxValue,
    this.needleColor = Colors.red,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    // 1. Рисуем фон шкалы
    _drawBackground(canvas, center, radius);
    
    // 2. Рисуем деления
    _drawScaleMarks(canvas, center, radius);
    
    // 3. Рисуем числовые значения
    _drawScaleNumbers(canvas, center, radius);
    
    // 4. Рисуем стрелку
    _drawNeedle(canvas, center, radius);
  }
  
  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.value != value || 
           oldDelegate.needleColor != needleColor;
  }
  
  // Приватные методы рисования
  void _drawBackground(Canvas canvas, Offset center, double radius) {
    // Реализация рисования фона
  }
}
```

### 3. Анимации для автомобильных интерфейсов

```dart
class AnimatedGauge extends StatefulWidget {
  final double value;
  final Duration animationDuration;
  
  const AnimatedGauge({
    super.key,
    required this.value,
    this.animationDuration = const Duration(milliseconds: 500),
  });
  
  @override
  State<AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Плавная кривая для автомобильных приборов
    ));
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(AnimatedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateAnimation();
    }
  }
  
  void _updateAnimation() {
    _animation = Tween<double>(
      begin: _previousValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _previousValue = widget.value;
    _controller.forward(from: 0.0);
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: GaugePainter(
            value: _animation.value,
            maxValue: 100.0,
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## 🧪 Тестирование

### Unit Tests

```dart
// test/services/can_bus_simulator_test.dart
void main() {
  group('CanBusSimulator', () {
    late CanBusSimulator simulator;
    
    setUp(() {
      simulator = CanBusSimulator();
    });
    
    tearDown(() {
      simulator.dispose();
    });
    
    test('should initialize with default values', () {
      expect(simulator.state['speed'], equals(0.0));
      expect(simulator.state['rpm'], equals(800.0));
      expect(simulator.state['gear'], equals('P'));
    });
    
    test('should calculate realistic RPM for given speed and gear', () {
      final rpm = simulator.calculateRpmForSpeed(60.0, 4);
      expect(rpm, inRange(1500.0, 2500.0));
    });
    
    test('should handle invalid input gracefully', () {
      final rpm = simulator.calculateRpmForSpeed(-10.0, 0);
      expect(rpm, equals(800.0)); // Fallback to idle RPM
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/speedometer_widget_test.dart
void main() {
  testWidgets('SpeedometerWidget displays correct speed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpeedometerWidget(
            speed: 80.0,
            maxSpeed: 220.0,
          ),
        ),
      ),
    );
    
    // Проверяем наличие цифрового дисплея
    expect(find.text('80'), findsOneWidget);
    expect(find.text('км/ч'), findsOneWidget);
    
    // Проверяем CustomPaint
    expect(find.byType(CustomPaint), findsOneWidget);
  });
  
  testWidgets('SpeedometerWidget animates speed changes', (tester) async {
    double currentSpeed = 0.0;
    
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SpeedometerWidget(speed: currentSpeed),
                  ElevatedButton(
                    onPressed: () => setState(() => currentSpeed = 100.0),
                    child: Text('Увеличить скорость'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    
    // Проверяем начальное значение
    expect(find.text('0'), findsOneWidget);
    
    // Нажимаем кнопку
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Начало анимации
    await tester.pump(Duration(milliseconds: 250)); // Середина анимации
    
    // Проверяем, что значение изменяется во время анимации
    expect(find.text('0'), findsNothing);
    expect(find.text('100'), findsNothing);
    
    // Ждем окончания анимации
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// integration_test/dashboard_test.dart
void main() {
  group('Dashboard Integration', () {
    testWidgets('full dashboard interaction flow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MyApp()),
      );
      
      // Ждем загрузки приложения
      await tester.pumpAndSettle();
      
      // Переходим к приборной панели
      await tester.tap(find.text('Приборная панель'));
      await tester.pumpAndSettle();
      
      // Проверяем основные элементы
      expect(find.byType(SpeedometerWidget), findsOneWidget);
      expect(find.byType(RpmGaugeWidget), findsOneWidget);
      expect(find.byType(TemperatureIndicator), findsWidgets);
      
      // Симулируем изменение данных CAN
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MyApp)),
      );
      
      final canSimulator = container.read(canBusProvider.notifier);
      // Имитируем разгон
      for (double speed = 0; speed <= 100; speed += 10) {
        canSimulator.updateSpeed(speed);
        await tester.pump(Duration(milliseconds: 100));
      }
      
      await tester.pumpAndSettle();
      
      // Проверяем финальные значения
      expect(find.text('100'), findsOneWidget);
    });
  });
}
```

## 🔧 Debugging

### Logging Strategy

```dart
// core/logging/app_logger.dart
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
  );
  
  // Структурированное логирование для автомобильных систем
  static void logCanData(String parameter, dynamic value) {
    _logger.d('CAN[$parameter]: $value');
  }
  
  static void logPerformance(String operation, Duration duration) {
    _logger.i('PERF[$operation]: ${duration.inMilliseconds}ms');
  }
  
  static void logUserAction(String action, Map<String, dynamic> context) {
    _logger.i('USER[$action]: $context');
  }
  
  static void logSystemError(String system, dynamic error, StackTrace? stack) {
    _logger.e('ERROR[$system]: $error', error, stack);
  }
}
```

### Debug Panels

```dart
// debug/debug_panel.dart
class DebugPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return SizedBox.shrink();
    
    return Positioned(
      top: 50,
      right: 16,
      child: Container(
        width: 200,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug Panel', style: TextStyle(color: Colors.white)),
            Divider(color: Colors.white),
            _buildPerformanceInfo(),
            _buildCanDataInfo(),
            _buildSystemInfo(),
          ],
        ),
      ),
    );
  }
}
```

### Performance Monitoring

```dart
// core/performance/performance_monitor.dart
class PerformanceMonitor {
  static final Map<String, Stopwatch> _stopwatches = {};
  static final Map<String, List<Duration>> _measurements = {};
  
  static void startMeasurement(String name) {
    _stopwatches[name] = Stopwatch()..start();
  }
  
  static void endMeasurement(String name) {
    final stopwatch = _stopwatches[name];
    if (stopwatch != null) {
      stopwatch.stop();
      _measurements.putIfAbsent(name, () => []).add(stopwatch.elapsed);
      
      AppLogger.logPerformance(name, stopwatch.elapsed);
      
      // Предупреждение о медленных операциях
      if (stopwatch.elapsedMilliseconds > 16) { // > 1 frame at 60fps
        AppLogger._logger.w('Slow operation detected: $name (${stopwatch.elapsedMilliseconds}ms)');
      }
    }
  }
  
  static Map<String, Duration> getAverages() {
    return _measurements.map((name, durations) {
      final total = durations.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
      return MapEntry(name, Duration(microseconds: total ~/ durations.length));
    });
  }
}

// Использование в виджетах
Widget _buildExpensiveWidget() {
  PerformanceMonitor.startMeasurement('build_expensive_widget');
  
  final result = ExpensiveWidget();
  
  PerformanceMonitor.endMeasurement('build_expensive_widget');
  return result;
}
```

## 🚀 Deployment

### Build Scripts

```bash
#!/bin/bash
# scripts/build.sh

set -e

echo "🏗️ Building Automotive Flutter App"

# Проверка окружения
flutter doctor

# Очистка предыдущих сборок
flutter clean
flutter pub get

# Генерация кода
dart run build_runner build --delete-conflicting-outputs

# Запуск тестов
echo "🧪 Running tests..."
flutter test --coverage

# Проверка качества кода
echo "🔍 Analyzing code..."
flutter analyze

# Сборка для различных платформ
echo "📱 Building for mobile platforms..."
flutter build apk --release
flutter build ios --release --no-codesign

echo "🖥️ Building for desktop platforms..."
flutter build linux --release
flutter build windows --release
flutter build macos --release

# Сборка для Raspberry Pi
echo "🥧 Building for Raspberry Pi..."
flutter build linux --release --target-platform=linux-arm64

echo "✅ Build completed successfully!"
```

### Docker для тестирования

```dockerfile
# Dockerfile.test
FROM ubuntu:20.04

# Установка Flutter
RUN apt-get update && apt-get install -y \
    curl git wget unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# Подготовка для тестирования embedded систем
RUN apt-get update && apt-get install -y \
    can-utils iproute2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter test
RUN flutter build linux --release

CMD ["flutter", "run", "-d", "linux"]
```

### CI/CD Pipeline

```yaml
# .github/workflows/automotive.yml
name: Automotive Flutter CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    name: Test Suite
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Verify formatting
      run: flutter format --output=none --set-exit-if-changed .
    
    - name: Analyze project source
      run: flutter analyze
    
    - name: Run tests
      run: flutter test --coverage --test-randomize-ordering-seed=random
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info

  build:
    name: Build Applications
    runs-on: ubuntu-latest
    needs: test
    
    strategy:
      matrix:
        platform: [linux, android]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
    
    - name: Build ${{ matrix.platform }}
      run: |
        flutter config --enable-linux-desktop
        flutter build ${{ matrix.platform }} --release
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: automotive-${{ matrix.platform }}
        path: build/${{ matrix.platform }}/

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    
    steps:
    - name: Download artifacts
      uses: actions/download-artifact@v3
    
    - name: Deploy to staging server
      run: |
        # Деплой на staging сервер
        echo "Deploying to staging..."
```

## 📊 Monitoring в Production

### Crash Reporting

```dart
// core/crash_reporting/crash_reporter.dart
class CrashReporter {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      reportCrash(details.exception, details.stack);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      reportCrash(error, stack);
      return true;
    };
  }
  
  static void reportCrash(dynamic exception, StackTrace? stackTrace) {
    // В production интегрируется с Crashlytics или Sentry
    if (kDebugMode) {
      print('CRASH: $exception\n$stackTrace');
    } else {
      // FirebaseCrashlytics.instance.recordError(exception, stackTrace);
    }
  }
}
```

### Analytics

```dart
// core/analytics/analytics_service.dart
class AnalyticsService {
  static void trackEvent(String name, Map<String, dynamic> parameters) {
    // Трекинг использования функций
    AppLogger._logger.i('ANALYTICS: $name - $parameters');
    
    // В production интегрируется с Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }
  
  static void trackScreenView(String screenName) {
    trackEvent('screen_view', {'screen_name': screenName});
  }
  
  static void trackUserAction(String action, String context) {
    trackEvent('user_action', {
      'action': action,
      'context': context,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
```

Это руководство обеспечивает структурированный подход к разработке и поддержанию качества кода в автомобильном Flutter проекте.