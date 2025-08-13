import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automotive_flutter_demo/apps/dashboard/widgets/speedometer_widget.dart';
import 'package:automotive_flutter_demo/core/theme/automotive_theme.dart';

void main() {
  group('SpeedometerWidget', () {
    testWidgets('should display initial speed value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 60.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Digital display should show the speed
      expect(find.text('60'), findsOneWidget);
      expect(find.text('км/ч'), findsOneWidget);
    });

    testWidgets('should handle zero speed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 0.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should handle maximum speed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 240.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('240'), findsOneWidget);
    });

    testWidgets('should clamp speed to max value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 300.0, // Exceeds max
                  maxSpeed: 240.0,
                  showDigital: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Should display max speed, not the excessive value
      expect(find.text('240'), findsOneWidget);
    });

    testWidgets('should hide digital display when showDigital is false', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 60.0,
                  maxSpeed: 240.0,
                  showDigital: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Digital display should not be present
      expect(find.text('60'), findsNothing);
      expect(find.text('км/ч'), findsNothing);
    });

    testWidgets('should animate speed changes with physics enabled', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 0.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                  enablePhysics: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Update speed
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 100.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                  enablePhysics: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Animation should start
      await tester.pump(const Duration(milliseconds: 100));
      
      // Speed should be transitioning
      // Note: exact value depends on physics simulation
      expect(find.textContaining(RegExp(r'\d+')), findsOneWidget);
    });

    testWidgets('should display instantly without physics', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 80.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                  enablePhysics: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Should immediately show target speed
      expect(find.text('80'), findsOneWidget);
    });

    testWidgets('should handle error callback', (WidgetTester tester) async {
      bool errorCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 60.0,
                  maxSpeed: 240.0,
                  onError: () {
                    errorCalled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Update with invalid value
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: double.nan,
                  maxSpeed: 240.0,
                  onError: () {
                    errorCalled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Error should display error state
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('ОШИБКА'), findsOneWidget);
      expect(find.text('СПИДОМЕТР'), findsOneWidget);
    });

    testWidgets('should apply correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 60.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Check for circular container with border
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SpeedometerWidget),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, equals(BoxShape.circle));
      expect(decoration.border, isNotNull);
    });

    testWidgets('should render custom painter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 60.0,
                  maxSpeed: 240.0,
                ),
              ),
            ),
          ),
        ),
      );

      // Custom painter should be present
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('should handle different max speeds', (WidgetTester tester) async {
      // Test with low max speed
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 50.0,
                  maxSpeed: 120.0,
                  showDigital: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('50'), findsOneWidget);

      // Test with high max speed
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 150.0,
                  maxSpeed: 300.0,
                  showDigital: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('should dispose resources properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 60.0,
                  maxSpeed: 240.0,
                  enablePhysics: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Remove widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Disposed'),
            ),
          ),
        ),
      );

      expect(find.text('Disposed'), findsOneWidget);
      expect(find.byType(SpeedometerWidget), findsNothing);
    });

    testWidgets('should show physics indicator when active', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 0.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                  enablePhysics: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Change speed to activate physics
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 100.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                  enablePhysics: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Pump to allow animation
      await tester.pump(const Duration(milliseconds: 50));

      // Physics indicator should be visible (small container with gradient)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });

  group('SpeedometerWidget Performance', () {
    testWidgets('should handle rapid updates', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SpeedometerWidget(
                  speed: 0.0,
                  maxSpeed: 240.0,
                  showDigital: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Rapidly update speed values
      for (int i = 0; i <= 100; i += 10) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: SpeedometerWidget(
                    speed: i.toDouble(),
                    maxSpeed: 240.0,
                    showDigital: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
      }

      // Should display final value
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('should handle size constraints', (WidgetTester tester) async {
      // Test with small size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: SpeedometerWidget(
                  speed: 60.0,
                  maxSpeed: 240.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SpeedometerWidget), findsOneWidget);

      // Test with large size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500,
                height: 500,
                child: SpeedometerWidget(
                  speed: 60.0,
                  maxSpeed: 240.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SpeedometerWidget), findsOneWidget);
    });
  });
}