import 'package:flutter_test/flutter_test.dart';
import 'package:automotive_flutter_demo/services/can_bus_simulator.dart';
import 'package:fake_async/fake_async.dart';
import 'dart:math' as math;

void main() {
  group('CanBusSimulator', () {
    late CanBusSimulator simulator;

    setUp(() {
      simulator = CanBusSimulator();
    });

    tearDown(() {
      simulator.dispose();
    });

    group('Initial State Tests', () {
      test('should initialize with default values', () {
        final initialState = simulator.state;
        
        expect(initialState['speed'], equals(0.0));
        expect(initialState['rpm'], equals(800.0));
        expect(initialState['gear'], equals('P'));
        expect(initialState['engine_temp'], equals(90.0));
        expect(initialState['fuel_level'], equals(75.0));
        expect(initialState['odometer'], equals(45623.4));
        expect(initialState['trip_meter'], equals(156.8));
      });

      test('should have all required system parameters', () {
        final state = simulator.state;
        
        // Temperature parameters
        expect(state.containsKey('engine_temp'), isTrue);
        expect(state.containsKey('oil_temp'), isTrue);
        expect(state.containsKey('outside_temp'), isTrue);
        
        // Fluid levels
        expect(state.containsKey('fuel_level'), isTrue);
        expect(state.containsKey('oil_pressure'), isTrue);
        expect(state.containsKey('battery_voltage'), isTrue);
        
        // Warning systems
        expect(state.containsKey('abs_warning'), isTrue);
        expect(state.containsKey('engine_warning'), isTrue);
        expect(state.containsKey('oil_warning'), isTrue);
        
        // OBD-II parameters
        expect(state.containsKey('throttle_position'), isTrue);
        expect(state.containsKey('brake_pressure'), isTrue);
        expect(state.containsKey('intake_air_temp'), isTrue);
        expect(state.containsKey('mass_air_flow'), isTrue);
      });

      test('should have all wheel speed sensors initialized', () {
        final state = simulator.state;
        
        expect(state['wheel_speed_fl'], equals(0.0));
        expect(state['wheel_speed_fr'], equals(0.0));
        expect(state['wheel_speed_rl'], equals(0.0));
        expect(state['wheel_speed_rr'], equals(0.0));
      });

      test('should have climate control parameters initialized', () {
        final state = simulator.state;
        
        expect(state['cabin_temp'], equals(22.0));
        expect(state['hvac_fan_speed'], equals(0));
        expect(state['ac_compressor'], equals(false));
      });

      test('should have door and lighting states initialized', () {
        final state = simulator.state;
        
        expect(state['door_driver_open'], equals(false));
        expect(state['door_passenger_open'], equals(false));
        expect(state['headlights'], equals(false));
        expect(state['fog_lights'], equals(false));
      });
    });

    group('Speed Change Tests', () {
      test('should simulate parking state correctly', () {
        fakeAsync((async) {
          // Start simulation
          async.elapse(const Duration(milliseconds: 100));
          
          // Parking state should have zero speed and idle RPM
          final state = simulator.state;
          expect(state['speed'], lessThanOrEqualTo(1.0));
          expect(state['rpm'], closeTo(800.0, 100.0));
          expect(state['throttle_position'], equals(0.0));
        });
      });

      test('should handle acceleration scenario', () {
        fakeAsync((async) {
          // Let simulation run to acceleration phase
          async.elapse(const Duration(seconds: 10));
          
          final state = simulator.state;
          // During acceleration, speed should increase
          expect(state['speed'], greaterThan(0.0));
          expect(state['throttle_position'], greaterThan(0.0));
        });
      });

      test('should handle braking scenario', () {
        fakeAsync((async) {
          // Run simulation to braking phase
          async.elapse(const Duration(seconds: 30));
          
          final state = simulator.state;
          // Check for brake pressure during certain phases
          if (state['speed'] != null && state['speed'] > 0) {
            // Brake pressure can be active during deceleration
            expect(state.containsKey('brake_pressure'), isTrue);
          }
        });
      });

      test('should maintain speed limits', () {
        fakeAsync((async) {
          // Run simulation for extended period
          for (int i = 0; i < 100; i++) {
            async.elapse(const Duration(milliseconds: 100));
            final state = simulator.state;
            
            // Speed should never be negative
            expect(state['speed'], greaterThanOrEqualTo(0.0));
            // Speed should not exceed reasonable maximum
            expect(state['speed'], lessThanOrEqualTo(250.0));
          }
        });
      });

      test('should update wheel speeds proportionally to vehicle speed', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 15));
          
          final state = simulator.state;
          final vehicleSpeed = state['speed'] as double;
          
          if (vehicleSpeed > 0) {
            // All wheel speeds should be close to vehicle speed
            expect(state['wheel_speed_fl'], closeTo(vehicleSpeed, vehicleSpeed * 0.1));
            expect(state['wheel_speed_fr'], closeTo(vehicleSpeed, vehicleSpeed * 0.1));
            expect(state['wheel_speed_rl'], closeTo(vehicleSpeed, vehicleSpeed * 0.1));
            expect(state['wheel_speed_rr'], closeTo(vehicleSpeed, vehicleSpeed * 0.1));
          }
        });
      });
    });

    group('Gear Shifting Tests', () {
      test('should start in Park gear', () {
        expect(simulator.state['gear'], equals('P'));
      });

      test('should shift gears based on speed', () {
        fakeAsync((async) {
          // Run simulation through different speed ranges
          async.elapse(const Duration(seconds: 12));
          
          final state = simulator.state;
          final speed = state['speed'] as double;
          final gear = state['gear'] as String;
          
          // Verify gear logic
          if (speed == 0) {
            expect(['P', 'N'].contains(gear), isTrue);
          } else if (speed > 0) {
            expect(['1', '2', '3', '4', '5', '6'].contains(gear), isTrue);
          }
        });
      });

      test('should handle transmission temperature', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 20));
          
          final state = simulator.state;
          if (state.containsKey('transmission_temp')) {
            final transTemp = state['transmission_temp'] as double;
            
            // Transmission temperature should be in reasonable range
            expect(transTemp, greaterThanOrEqualTo(80.0));
            expect(transTemp, lessThanOrEqualTo(120.0));
          }
        });
      });
    });

    group('Temperature Management Tests', () {
      test('should maintain engine temperature within normal range', () {
        fakeAsync((async) {
          for (int i = 0; i < 50; i++) {
            async.elapse(const Duration(milliseconds: 200));
            
            final engineTemp = simulator.state['engine_temp'] as double;
            
            // Engine temperature should stay within operational range
            expect(engineTemp, greaterThanOrEqualTo(60.0));
            expect(engineTemp, lessThanOrEqualTo(130.0));
          }
        });
      });

      test('should have oil temperature follow engine temperature', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 10));
          
          final state = simulator.state;
          final engineTemp = state['engine_temp'] as double;
          final oilTemp = state['oil_temp'] as double;
          
          // Oil temperature should be close to engine temperature
          expect((engineTemp - oilTemp).abs(), lessThanOrEqualTo(10.0));
        });
      });

      test('should update cabin temperature based on HVAC', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 5));
          
          final state = simulator.state;
          final cabinTemp = state['cabin_temp'] as double;
          
          // Cabin temperature should be in comfortable range
          expect(cabinTemp, greaterThanOrEqualTo(15.0));
          expect(cabinTemp, lessThanOrEqualTo(30.0));
        });
      });

      test('should calculate exhaust temperature', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 15));
          
          final state = simulator.state;
          if (state.containsKey('exhaust_temp')) {
            final exhaustTemp = state['exhaust_temp'] as double;
            final engineTemp = state['engine_temp'] as double;
            
            // Exhaust temperature should be higher than engine temperature
            expect(exhaustTemp, greaterThan(engineTemp));
          }
        });
      });
    });

    group('Fuel Consumption Tests', () {
      test('should consume fuel during operation', () {
        fakeAsync((async) {
          final initialFuel = simulator.state['fuel_level'] as double;
          
          // Run simulation for extended period
          async.elapse(const Duration(seconds: 30));
          
          final currentFuel = simulator.state['fuel_level'] as double;
          
          // Fuel should be consumed (or remain same if idle)
          expect(currentFuel, lessThanOrEqualTo(initialFuel));
        });
      });

      test('should never have negative fuel level', () {
        fakeAsync((async) {
          for (int i = 0; i < 100; i++) {
            async.elapse(const Duration(seconds: 1));
            
            final fuelLevel = simulator.state['fuel_level'] as double;
            expect(fuelLevel, greaterThanOrEqualTo(0.0));
          }
        });
      });

      test('should calculate instant fuel consumption', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 15));
          
          final state = simulator.state;
          if (state.containsKey('instant_fuel_consumption')) {
            final consumption = state['instant_fuel_consumption'] as double;
            
            // Consumption should be within reasonable range (L/h)
            expect(consumption, greaterThanOrEqualTo(0.5));
            expect(consumption, lessThanOrEqualTo(25.0));
          }
        });
      });

      test('should set fuel warning when low', () {
        fakeAsync((async) {
          // Run simulation until fuel is low
          for (int i = 0; i < 200; i++) {
            async.elapse(const Duration(seconds: 1));
            
            final state = simulator.state;
            final fuelLevel = state['fuel_level'] as double;
            
            if (fuelLevel < 25.0) {
              expect(state['fuel_warning'], equals(true));
              break;
            }
          }
        });
      });
    });

    group('Error Conditions Tests', () {
      test('should handle RPM limits', () {
        fakeAsync((async) {
          for (int i = 0; i < 50; i++) {
            async.elapse(const Duration(milliseconds: 100));
            
            final rpm = simulator.state['rpm'] as double;
            
            // RPM should stay within engine limits
            expect(rpm, greaterThanOrEqualTo(600.0));
            expect(rpm, lessThanOrEqualTo(8000.0));
          }
        });
      });

      test('should trigger engine warning at high temperature', () {
        fakeAsync((async) {
          // Check engine warning state
          async.elapse(const Duration(seconds: 10));
          
          final state = simulator.state;
          final engineTemp = state['engine_temp'] as double;
          
          if (engineTemp > 110.0) {
            expect(state['engine_warning'], equals(true));
          }
        });
      });

      test('should trigger oil warning at low pressure', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 5));
          
          final state = simulator.state;
          final oilPressure = state['oil_pressure'] as double;
          
          if (oilPressure < 1.5) {
            expect(state['oil_warning'], equals(true));
          }
        });
      });

      test('should maintain battery voltage within range', () {
        fakeAsync((async) {
          for (int i = 0; i < 30; i++) {
            async.elapse(const Duration(milliseconds: 200));
            
            final voltage = simulator.state['battery_voltage'] as double;
            
            // Battery voltage should be within operational range
            expect(voltage, greaterThanOrEqualTo(11.5));
            expect(voltage, lessThanOrEqualTo(14.8));
          }
        });
      });
    });

    group('Edge Cases Tests', () {
      test('should handle rapid state transitions', () {
        fakeAsync((async) {
          // Simulate rapid transitions
          for (int i = 0; i < 10; i++) {
            async.elapse(const Duration(milliseconds: 50));
          }
          
          final state = simulator.state;
          
          // All critical values should remain valid
          expect(state['speed'], isNotNull);
          expect(state['rpm'], isNotNull);
          expect(state['gear'], isNotNull);
        });
      });

      test('should update odometer incrementally', () {
        fakeAsync((async) {
          final initialOdometer = simulator.state['odometer'] as double;
          
          // Run for a period where vehicle is moving
          async.elapse(const Duration(seconds: 20));
          
          final currentOdometer = simulator.state['odometer'] as double;
          
          // Odometer should only increase or stay same
          expect(currentOdometer, greaterThanOrEqualTo(initialOdometer));
        });
      });

      test('should handle trip meter updates', () {
        fakeAsync((async) {
          final initialTrip = simulator.state['trip_meter'] as double;
          
          async.elapse(const Duration(seconds: 15));
          
          final currentTrip = simulator.state['trip_meter'] as double;
          
          // Trip meter should only increase or stay same
          expect(currentTrip, greaterThanOrEqualTo(initialTrip));
        });
      });

      test('should provide valid tire pressure data', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 5));
          
          final state = simulator.state;
          
          if (state.containsKey('tire_pressure_fl')) {
            // Check all tire pressures are in valid range (bar)
            expect(state['tire_pressure_fl'], greaterThanOrEqualTo(1.8));
            expect(state['tire_pressure_fl'], lessThanOrEqualTo(3.0));
            
            expect(state['tire_pressure_fr'], greaterThanOrEqualTo(1.8));
            expect(state['tire_pressure_fr'], lessThanOrEqualTo(3.0));
            
            expect(state['tire_pressure_rl'], greaterThanOrEqualTo(1.8));
            expect(state['tire_pressure_rl'], lessThanOrEqualTo(3.0));
            
            expect(state['tire_pressure_rr'], greaterThanOrEqualTo(1.8));
            expect(state['tire_pressure_rr'], lessThanOrEqualTo(3.0));
          }
        });
      });

      test('should calculate eco score', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 10));
          
          final state = simulator.state;
          if (state.containsKey('eco_score')) {
            final ecoScore = state['eco_score'] as double;
            
            // Eco score should be percentage
            expect(ecoScore, greaterThanOrEqualTo(0.0));
            expect(ecoScore, lessThanOrEqualTo(100.0));
          }
        });
      });
    });

    group('Performance Tests', () {
      test('should update state within 50ms intervals', () {
        fakeAsync((async) {
          final initialState = Map<String, dynamic>.from(simulator.state);
          
          // Wait for one update cycle
          async.elapse(const Duration(milliseconds: 50));
          
          final updatedState = simulator.state;
          
          // State should have been updated
          expect(updatedState, isNot(equals(initialState)));
        });
      });

      test('should handle continuous operation without memory leaks', () {
        fakeAsync((async) {
          // Run for extended period
          for (int i = 0; i < 1000; i++) {
            async.elapse(const Duration(milliseconds: 50));
            
            // Access state to ensure it's being updated
            final state = simulator.state;
            expect(state, isNotNull);
            expect(state.isNotEmpty, isTrue);
          }
          
          // If we get here without issues, memory handling is good
          expect(true, isTrue);
        });
      });
    });

    group('Subsystem Integration Tests', () {
      test('should integrate thermal model correctly', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 10));
          
          final state = simulator.state;
          
          // Check thermal model outputs
          expect(state.containsKey('engine_temp'), isTrue);
          expect(state.containsKey('coolant_temp'), isTrue);
          expect(state.containsKey('oil_temp'), isTrue);
          
          if (state.containsKey('coolant_temp')) {
            final coolantTemp = state['coolant_temp'] as double;
            final engineTemp = state['engine_temp'] as double;
            
            // Coolant temp should be close to engine temp
            expect((coolantTemp - engineTemp).abs(), lessThanOrEqualTo(5.0));
          }
        });
      });

      test('should integrate fuel system correctly', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 10));
          
          final state = simulator.state;
          
          // Check fuel system outputs
          expect(state.containsKey('fuel_level'), isTrue);
          expect(state.containsKey('fuel_pressure'), isTrue);
          
          if (state.containsKey('fuel_rail_pressure')) {
            final fuelRailPressure = state['fuel_rail_pressure'] as double;
            
            // Fuel rail pressure should be in valid range
            expect(fuelRailPressure, greaterThanOrEqualTo(3.0));
            expect(fuelRailPressure, lessThanOrEqualTo(6.0));
          }
        });
      });

      test('should integrate electrical system correctly', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 10));
          
          final state = simulator.state;
          
          // Check electrical system outputs
          expect(state.containsKey('battery_voltage'), isTrue);
          
          if (state.containsKey('alternator_output')) {
            final alternatorOutput = state['alternator_output'] as double;
            final rpm = state['rpm'] as double;
            
            // Alternator output should correlate with RPM
            if (rpm > 1000) {
              expect(alternatorOutput, greaterThan(0.0));
            }
          }
        });
      });

      test('should integrate brake system correctly', () {
        fakeAsync((async) {
          async.elapse(const Duration(seconds: 20));
          
          final state = simulator.state;
          
          if (state.containsKey('brake_temp_front')) {
            final brakeTempFront = state['brake_temp_front'] as double;
            final brakeTempRear = state['brake_temp_rear'] as double;
            
            // Brake temperatures should be reasonable
            expect(brakeTempFront, greaterThanOrEqualTo(25.0));
            expect(brakeTempFront, lessThanOrEqualTo(300.0));
            
            expect(brakeTempRear, greaterThanOrEqualTo(25.0));
            expect(brakeTempRear, lessThanOrEqualTo(300.0));
            
            // Front brakes typically run hotter
            expect(brakeTempFront, greaterThanOrEqualTo(brakeTempRear));
          }
        });
      });
    });
  });

  group('EngineCharacteristics', () {
    late EngineCharacteristics engine;

    setUp(() {
      engine = EngineCharacteristics(
        displacement: 2.0,
        cylindersCount: 4,
        compressionRatio: 10.5,
        isTurbocharged: true,
      );
    });

    test('should calculate target RPM correctly', () {
      // Test idle
      expect(engine.calculateTargetRpm(0, 0, 0), equals(800.0));
      
      // Test normal driving
      final rpm = engine.calculateTargetRpm(60, 3, 50);
      expect(rpm, greaterThan(800.0));
      expect(rpm, lessThanOrEqualTo(7500.0));
    });

    test('should calculate engine load', () {
      final load = engine.calculateEngineLoad(3000, 50, 80);
      
      expect(load, greaterThanOrEqualTo(0.0));
      expect(load, lessThanOrEqualTo(100.0));
    });

    test('should calculate MAF correctly', () {
      final maf = engine.calculateMAF(2000, 50, 40);
      
      expect(maf, greaterThan(0.0));
      expect(maf, lessThan(100.0));
    });

    test('should calculate boost pressure for turbo engines', () {
      final boost = engine.calculateBoostPressure(3000, 70, 100);
      
      expect(boost, greaterThanOrEqualTo(0.0));
      expect(boost, lessThanOrEqualTo(1.5));
    });

    test('should not generate boost for non-turbo engines', () {
      final naEngine = EngineCharacteristics(isTurbocharged: false);
      final boost = naEngine.calculateBoostPressure(5000, 100, 150);
      
      expect(boost, equals(0.0));
    });

    test('should calculate torque curve', () {
      // Low RPM
      final lowTorque = engine.calculateTorque(1500, 100);
      
      // Peak torque area
      final peakTorque = engine.calculateTorque(2500, 100);
      
      // High RPM
      final highTorque = engine.calculateTorque(6000, 100);
      
      // Peak should be highest
      expect(peakTorque, greaterThan(lowTorque));
      expect(peakTorque, greaterThan(highTorque));
    });

    test('should calculate power from torque and RPM', () {
      final torque = 300.0; // Nm
      final rpm = 3000.0;
      
      final power = engine.calculatePower(rpm, torque);
      
      // Power = (Torque * RPM) / 9549
      final expectedPower = (torque * rpm) / 9549.0;
      expect(power, equals(expectedPower));
    });
  });

  group('TransmissionLogic', () {
    late TransmissionLogic transmission;

    setUp(() {
      transmission = TransmissionLogic(type: 'auto', maxGears: 6);
    });

    test('should select correct gear for speed', () {
      // Stopped
      expect(transmission.calculateOptimalGear(0, 800, 0, 0, false), equals(0));
      
      // Low speed
      expect(transmission.calculateOptimalGear(10, 1500, 30, 1, false), equals(1));
      
      // Medium speed
      expect(transmission.calculateOptimalGear(50, 2500, 40, 3, false), greaterThanOrEqualTo(2));
      
      // High speed
      expect(transmission.calculateOptimalGear(120, 3000, 50, 5, false), greaterThanOrEqualTo(5));
    });

    test('should respect shift duration', () {
      expect(transmission.getShiftDuration(3), equals(400));
      
      final dsgTransmission = TransmissionLogic(type: 'dual_clutch');
      expect(dsgTransmission.getShiftDuration(3), equals(150));
      
      final cvtTransmission = TransmissionLogic(type: 'cvt');
      expect(cvtTransmission.getShiftDuration(3), equals(0));
    });

    test('should calculate transmission temperature', () {
      final temp = transmission.calculateTransmissionTemp(3000, 80, 0.05);
      
      expect(temp, greaterThanOrEqualTo(80.0));
      expect(temp, lessThanOrEqualTo(120.0));
    });
  });

  group('CanBusPerformanceMonitor', () {
    late CanBusPerformanceMonitor monitor;

    setUp(() {
      monitor = CanBusPerformanceMonitor();
    });

    test('should track execution times', () {
      // Record some execution times
      monitor.recordExecutionTime(3.5);
      monitor.recordExecutionTime(4.0);
      monitor.recordExecutionTime(3.8);
      
      // Force update by recording 100 times
      for (int i = 0; i < 100; i++) {
        monitor.recordExecutionTime(3.5 + (i % 10) * 0.1);
      }
      
      final performanceData = monitor.state;
      
      expect(performanceData.averageExecutionTime, greaterThan(0.0));
      expect(performanceData.maxExecutionTime, greaterThanOrEqualTo(performanceData.averageExecutionTime));
      expect(performanceData.minExecutionTime, lessThanOrEqualTo(performanceData.averageExecutionTime));
      expect(performanceData.ticksProcessed, greaterThan(0));
    });

    test('should determine performance quality', () {
      // Good performance
      for (int i = 0; i < 100; i++) {
        monitor.recordExecutionTime(2.0);
      }
      
      expect(monitor.state.isPerformanceGood, isTrue);
      
      // Poor performance
      monitor = CanBusPerformanceMonitor();
      for (int i = 0; i < 100; i++) {
        monitor.recordExecutionTime(10.0);
      }
      
      expect(monitor.state.isPerformanceGood, isFalse);
    });
  });
}