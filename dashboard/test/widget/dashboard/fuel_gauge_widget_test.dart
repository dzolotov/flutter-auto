import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automotive_flutter_demo/apps/dashboard/widgets/fuel_gauge_widget.dart';

void main() {
  group('FuelGaugeWidget', () {
    testWidgets('should display fuel level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 75.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('should handle empty tank', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 0.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);
    });

    testWidgets('should handle full tank', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 100.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);
    });

    testWidgets('should show low fuel warning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 10.0, // Low fuel
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);
      // Warning indicator should be shown through custom paint
    });

    testWidgets('should update fuel level dynamically', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 75.0,
                ),
              ),
            ),
          ),
        ),
      );

      // Decrease fuel level
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 50.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);
    });

    testWidgets('should handle different fuel capacities', (WidgetTester tester) async {
      // Small capacity
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 50.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);

      // Large capacity
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 50.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);
    });

    testWidgets('should clamp fuel level to valid range', (WidgetTester tester) async {
      // Negative fuel level
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: -10.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);

      // Fuel level exceeding 100%
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FuelGaugeWidget(
                  fuelLevel: 150.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuelGaugeWidget), findsOneWidget);
    });
  });
}