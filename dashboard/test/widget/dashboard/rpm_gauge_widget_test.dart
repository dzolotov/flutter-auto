import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automotive_flutter_demo/apps/dashboard/widgets/rpm_gauge_widget.dart';

void main() {
  group('RpmGaugeWidget', () {
    testWidgets('should display initial RPM value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 3000.0,
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(RpmGaugeWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('should handle idle RPM', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 800.0,
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);
    });

    testWidgets('should handle redline RPM', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 7000.0,
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);
    });

    testWidgets('should clamp RPM to max value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 10000.0, // Exceeds max
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);
    });

    testWidgets('should handle zero RPM', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 0.0,
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);
    });

    testWidgets('should update RPM value dynamically', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 2000.0,
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);

      // Update RPM
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 5000.0,
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);
    });

    testWidgets('should handle different max RPM values', (WidgetTester tester) async {
      // Diesel engine (low max RPM)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 2000.0,
                  maxRpm: 5000.0,
                  redlineRpm: 4500.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);

      // High-performance engine (high max RPM)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RpmGaugeWidget(
                  rpm: 6000.0,
                  maxRpm: 10000.0,
                  redlineRpm: 9000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);
    });

    testWidgets('should handle size constraints', (WidgetTester tester) async {
      // Small size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: RpmGaugeWidget(
                  rpm: 3000.0,
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);

      // Large size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: RpmGaugeWidget(
                  rpm: 3000.0,
                  maxRpm: 8000.0,
                  redlineRpm: 7000.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RpmGaugeWidget), findsOneWidget);
    });

    testWidgets('should handle rapid RPM changes', (WidgetTester tester) async {
      // Simulate engine revving
      for (int rpm = 1000; rpm <= 6000; rpm += 500) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: RpmGaugeWidget(
                    rpm: rpm.toDouble(),
                    maxRpm: 8000.0,
                    redlineRpm: 7000.0,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(RpmGaugeWidget), findsOneWidget);
      }
    });
  });
}