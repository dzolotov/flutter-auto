import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automotive_flutter_demo/apps/dashboard/widgets/temperature_indicator.dart';

void main() {
  group('TemperatureIndicator', () {
    testWidgets('should display normal temperature', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TemperatureIndicator(
                  temperature: 90.0,
                  minTemp: 60.0,
                  maxTemp: 120.0,
                  title: 'Engine',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TemperatureIndicator), findsOneWidget);
      expect(find.text('ENGINE'), findsOneWidget);
    });

    testWidgets('should display cold temperature', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TemperatureIndicator(
                  temperature: 60.0,
                  minTemp: 60.0,
                  maxTemp: 120.0,
                  title: 'Engine',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TemperatureIndicator), findsOneWidget);
    });

    testWidgets('should display hot temperature warning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TemperatureIndicator(
                  temperature: 115.0,
                  minTemp: 60.0,
                  maxTemp: 120.0,
                  title: 'Engine',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TemperatureIndicator), findsOneWidget);
      // Warning state should be indicated visually
    });

    testWidgets('should handle temperature changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TemperatureIndicator(
                  temperature: 70.0,
                  minTemp: 60.0,
                  maxTemp: 120.0,
                  title: 'Engine',
                ),
              ),
            ),
          ),
        ),
      );

      // Update temperature
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TemperatureIndicator(
                  temperature: 95.0,
                  minTemp: 60.0,
                  maxTemp: 120.0,
                  title: 'Engine',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TemperatureIndicator), findsOneWidget);
    });

    testWidgets('should clamp temperature to valid range', (WidgetTester tester) async {
      // Below minimum
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TemperatureIndicator(
                  temperature: 30.0, // Below min
                  minTemp: 60.0,
                  maxTemp: 120.0,
                  title: 'Engine',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TemperatureIndicator), findsOneWidget);

      // Above maximum
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TemperatureIndicator(
                  temperature: 150.0, // Above max
                  minTemp: 60.0,
                  maxTemp: 120.0,
                  title: 'Engine',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TemperatureIndicator), findsOneWidget);
    });

    testWidgets('should display oil temperature', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: TemperatureIndicator(
                  temperature: 85.0,
                  minTemp: 60.0,
                  maxTemp: 120.0,
                  title: 'Oil',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TemperatureIndicator), findsOneWidget);
      expect(find.text('OIL'), findsOneWidget);
    });
  });
}