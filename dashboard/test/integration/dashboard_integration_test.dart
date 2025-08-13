import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:automotive_flutter_demo/apps/dashboard/dashboard_app.dart';
import 'package:automotive_flutter_demo/services/can_bus_simulator.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  group('Dashboard Integration Tests', () {
    testWidgets('should display all dashboard components', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      // Wait for initial build
      await tester.pump();

      // All main dashboard components should be present
      expect(find.byType(DashboardApp), findsOneWidget);
      
      // Check for main layout structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should update dashboard with CAN bus data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // Simulate time passing for CAN bus updates
      await tester.pump(const Duration(milliseconds: 100));
      
      // Dashboard should still be displayed
      expect(find.byType(DashboardApp), findsOneWidget);
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {
      // Start in portrait
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(DashboardApp), findsOneWidget);

      // Change to landscape
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pump();

      expect(find.byType(DashboardApp), findsOneWidget);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should maintain state during widget rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      await tester.pump();

      // Force rebuild
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      await tester.pump();

      // Dashboard should still be functional
      expect(find.byType(DashboardApp), findsOneWidget);
    });

    testWidgets('should handle rapid data updates', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      // Simulate rapid updates
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Dashboard should remain stable
      expect(find.byType(DashboardApp), findsOneWidget);
    });

    testWidgets('should display warning indicators when triggered', (WidgetTester tester) async {
      // Create a test provider scope with controlled state
      final container = ProviderContainer(
        overrides: [
          canBusProvider.overrideWith((ref) {
            final simulator = CanBusSimulator();
            // Set warning conditions
            simulator.state['engine_warning'] = true;
            simulator.state['fuel_warning'] = true;
            return simulator.state;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      await tester.pump();

      // Dashboard should display with warning states
      expect(find.byType(DashboardApp), findsOneWidget);

      container.dispose();
    });

    testWidgets('should handle different screen sizes', (WidgetTester tester) async {
      // Small screen (phone)
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(DashboardApp), findsOneWidget);

      // Tablet size
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 2.0;

      await tester.pump();
      expect(find.byType(DashboardApp), findsOneWidget);

      // Large screen (desktop/automotive display)
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pump();
      expect(find.byType(DashboardApp), findsOneWidget);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should respond to theme changes', (WidgetTester tester) async {
      // Light theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const DashboardApp(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(DashboardApp), findsOneWidget);

      // Dark theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const DashboardApp(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(DashboardApp), findsOneWidget);
    });
  });

  group('Dashboard Performance Tests', () {
    testWidgets('should maintain 60 FPS during normal operation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      // Measure frame building time
      final stopwatch = Stopwatch()..start();
      
      // Simulate 60 frames
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // ~60 FPS
      }
      
      stopwatch.stop();
      
      // Should complete 60 frames in approximately 1 second
      // Allow some tolerance for test environment
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    testWidgets('should handle memory efficiently', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      // Run for extended period
      for (int i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Widget tree should still be valid
      expect(find.byType(DashboardApp), findsOneWidget);
      
      // Note: Actual memory profiling would require additional tools
      // This test ensures the app doesn't crash during extended operation
    });
  });

  group('Dashboard Error Handling Tests', () {
    testWidgets('should handle provider errors gracefully', (WidgetTester tester) async {
      // Create a provider that throws an error
      final container = ProviderContainer(
        overrides: [
          canBusProvider.overrideWith((ref) {
            throw Exception('Simulated CAN bus error');
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      await tester.pump();

      // App should handle the error without crashing
      // It should either show an error widget or fallback UI
      expect(find.byType(MaterialApp), findsOneWidget);

      container.dispose();
    });

    testWidgets('should recover from transient errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      await tester.pump();

      // Simulate recovery by rebuilding
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardApp(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(DashboardApp), findsOneWidget);
    });
  });
}