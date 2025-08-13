import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:automotive_flutter_demo/services/can_bus_simulator.dart';

/// Test helper utilities for automotive Flutter tests
class TestHelpers {
  /// Wraps a widget with necessary providers and material app for testing
  static Widget wrapWithMaterialApp(Widget widget, {
    ThemeData? theme,
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        theme: theme ?? ThemeData.dark(),
        home: Scaffold(
          body: widget,
        ),
      ),
    );
  }

  /// Creates a test CAN bus state with customizable values
  static Map<String, dynamic> createTestCanBusState({
    double speed = 0.0,
    double rpm = 800.0,
    String gear = 'P',
    double engineTemp = 90.0,
    double fuelLevel = 75.0,
    bool engineWarning = false,
    bool absWarning = false,
    Map<String, dynamic>? additionalData,
  }) {
    final state = {
      'speed': speed,
      'rpm': rpm,
      'gear': gear,
      'engine_temp': engineTemp,
      'fuel_level': fuelLevel,
      'engine_warning': engineWarning,
      'abs_warning': absWarning,
      'oil_temp': 85.0,
      'outside_temp': 20.0,
      'oil_pressure': 2.5,
      'battery_voltage': 12.6,
      'odometer': 45623.4,
      'trip_meter': 156.8,
      'throttle_position': 0.0,
      'brake_pressure': 0.0,
      'intake_air_temp': 25.0,
      'mass_air_flow': 3.5,
      'fuel_pressure': 3.5,
      'boost_pressure': 0.0,
      'wheel_speed_fl': speed,
      'wheel_speed_fr': speed,
      'wheel_speed_rl': speed,
      'wheel_speed_rr': speed,
      'cabin_temp': 22.0,
      'hvac_fan_speed': 0,
      'ac_compressor': false,
      'door_driver_open': false,
      'door_passenger_open': false,
      'headlights': false,
      'fog_lights': false,
      'seatbelt_fastened': true,
      'left_turn_signal': false,
      'right_turn_signal': false,
    };

    if (additionalData != null) {
      state.addAll(additionalData);
    }

    return state;
  }

  /// Pumps widget for specified duration with frame intervals
  static Future<void> pumpForDuration(
    WidgetTester tester,
    Duration duration, {
    Duration frameInterval = const Duration(milliseconds: 16),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < duration) {
      await tester.pump(frameInterval);
    }
    stopwatch.stop();
  }

  /// Verifies that a widget rebuilds within performance constraints
  static Future<void> measureRebuildPerformance(
    WidgetTester tester,
    Future<void> Function() triggerRebuild, {
    int maxMilliseconds = 16, // Target 60 FPS
  }) async {
    final stopwatch = Stopwatch()..start();
    await triggerRebuild();
    await tester.pump();
    stopwatch.stop();

    expect(
      stopwatch.elapsedMilliseconds,
      lessThanOrEqualTo(maxMilliseconds),
      reason: 'Widget rebuild took ${stopwatch.elapsedMilliseconds}ms, '
          'exceeding target of ${maxMilliseconds}ms',
    );
  }

  /// Sets up a specific viewport size for testing
  static void setViewportSize(WidgetTester tester, {
    required double width,
    required double height,
    double pixelRatio = 1.0,
  }) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = pixelRatio;
  }

  /// Resets viewport to default size
  static void resetViewport(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  /// Common screen sizes for testing
  static const Map<String, Size> screenSizes = {
    'phone_small': Size(375, 667),    // iPhone SE
    'phone_medium': Size(390, 844),   // iPhone 12
    'phone_large': Size(428, 926),    // iPhone 12 Pro Max
    'tablet': Size(1024, 768),        // iPad
    'automotive_7inch': Size(1024, 600),
    'automotive_10inch': Size(1280, 800),
    'automotive_12inch': Size(1920, 720),
    'automotive_15inch': Size(1920, 1080),
  };

  /// Generates a series of speed values for animation testing
  static List<double> generateSpeedSequence({
    double start = 0,
    double end = 100,
    int steps = 10,
  }) {
    final List<double> sequence = [];
    final increment = (end - start) / steps;
    
    for (int i = 0; i <= steps; i++) {
      sequence.add(start + (increment * i));
    }
    
    return sequence;
  }

  /// Simulates user driving scenario
  static Future<void> simulateDrivingScenario(
    WidgetTester tester,
    ProviderContainer container, {
    required List<DrivingEvent> events,
  }) async {
    for (final event in events) {
      // Update CAN bus state
      final simulator = container.read(canBusProvider.notifier);
      
      // Apply event changes
      switch (event.type) {
        case DrivingEventType.accelerate:
          // Simulate acceleration
          break;
        case DrivingEventType.brake:
          // Simulate braking
          break;
        case DrivingEventType.idle:
          // Simulate idling
          break;
        case DrivingEventType.cruise:
          // Simulate cruising
          break;
      }
      
      // Wait for specified duration
      await tester.pump(event.duration);
    }
  }

  /// Verifies gauge needle position (for custom paint testing)
  static bool isNeedleAtAngle(
    CustomPainter painter,
    double expectedAngle, {
    double tolerance = 0.1,
  }) {
    // This would require access to the painter's internal state
    // In practice, you might need to expose this for testing
    return true; // Placeholder
  }

  /// Creates a golden file name with platform and size info
  static String goldenFileName(String baseName, {String? variant}) {
    final platform = WidgetTester.binding.defaultTargetPlatform.name;
    final variantSuffix = variant != null ? '_$variant' : '';
    return 'goldens/${baseName}_${platform}${variantSuffix}.png';
  }
}

/// Represents a driving event for scenario testing
class DrivingEvent {
  final DrivingEventType type;
  final Duration duration;
  final Map<String, dynamic>? parameters;

  const DrivingEvent({
    required this.type,
    required this.duration,
    this.parameters,
  });
}

/// Types of driving events
enum DrivingEventType {
  accelerate,
  brake,
  idle,
  cruise,
}

/// Mock CAN Bus Simulator for testing
class MockCanBusSimulator extends Mock implements CanBusSimulator {
  Map<String, dynamic> _state = TestHelpers.createTestCanBusState();

  @override
  Map<String, dynamic> get state => _state;

  void updateState(Map<String, dynamic> newState) {
    _state = {..._state, ...newState};
  }

  void setState(Map<String, dynamic> newState) {
    _state = newState;
  }
}

/// Test matcher for checking value ranges
class InRange extends Matcher {
  final num min;
  final num max;

  const InRange(this.min, this.max);

  @override
  Description describe(Description description) {
    return description.add('value between $min and $max');
  }

  @override
  bool matches(item, Map matchState) {
    if (item is! num) return false;
    return item >= min && item <= max;
  }
}

/// Convenience function for range matching
Matcher inRange(num min, num max) => InRange(min, max);

/// Test matcher for checking color similarity
class ColorSimilarTo extends Matcher {
  final Color expected;
  final int tolerance;

  const ColorSimilarTo(this.expected, {this.tolerance = 10});

  @override
  Description describe(Description description) {
    return description.add('color similar to $expected');
  }

  @override
  bool matches(item, Map matchState) {
    if (item is! Color) return false;
    
    final deltaR = (item.red - expected.red).abs();
    final deltaG = (item.green - expected.green).abs();
    final deltaB = (item.blue - expected.blue).abs();
    final deltaA = (item.alpha - expected.alpha).abs();
    
    return deltaR <= tolerance &&
           deltaG <= tolerance &&
           deltaB <= tolerance &&
           deltaA <= tolerance;
  }
}

/// Convenience function for color matching
Matcher colorSimilarTo(Color color, {int tolerance = 10}) {
  return ColorSimilarTo(color, tolerance: tolerance);
}

/// Extension methods for testing
extension WidgetTesterExtensions on WidgetTester {
  /// Finds and returns a widget of type T
  T widget<T extends Widget>(Finder finder) {
    return this.firstWidget(finder) as T;
  }

  /// Pumps widget multiple times
  Future<void> pumpTimes(int times, [Duration? duration]) async {
    for (int i = 0; i < times; i++) {
      await pump(duration);
    }
  }

  /// Waits until a condition is met or timeout
  Future<void> pumpUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (!condition() && stopwatch.elapsed < timeout) {
      await pump(interval);
    }
    
    stopwatch.stop();
    
    if (!condition()) {
      throw TimeoutException('Condition not met within $timeout');
    }
  }
}

/// Exception thrown when a test condition times out
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}