// Flutter-Pi Automotive Dashboard
// Copyright (C) 2025 Dmitrii Zolotov, dmitrii.zolotov@gmail.com
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_data.freezed.dart';
part 'vehicle_data.g.dart';

@freezed
class VehicleData with _$VehicleData {
  const factory VehicleData({
    @Default(0.0) double speed, // km/h
    @Default(800.0) double rpm, // RPM
    @Default(90.0) double engineTemp, // °C
    @Default(75.0) double fuelLevel, // %
    @Default(0.0) double throttlePosition, // %
    @Default(0.0) double engineLoad, // %
    @Default(12.6) double batteryVoltage, // V
    @Default(85.0) double oilTemp, // °C
    @Default(2.5) double oilPressure, // bar
    @Default('P') String gear, // P, R, N, D, 1, 2, 3, 4, 5, 6
    @Default(false) bool isConnected,
    DateTime? lastUpdate,
    
    // Warning flags
    @Default(false) bool lowFuel,
    @Default(false) bool engineOverheat,
    @Default(false) bool lowOilPressure,
    @Default(false) bool checkEngine,
    @Default(false) bool batteryWarning,
  }) = _VehicleData;

  factory VehicleData.fromJson(Map<String, dynamic> json) => _$VehicleDataFromJson(json);
}

extension VehicleDataExtensions on VehicleData {
  /// Проверка критических предупреждений
  bool get hasCriticalWarnings =>
      engineOverheat || lowOilPressure || batteryWarning;

  /// Проверка любых предупреждений
  bool get hasWarnings =>
      lowFuel || engineOverheat || lowOilPressure || checkEngine || batteryWarning;

  /// Цвет для RPM индикатора
  bool get isRpmInRedline => rpm > 6500;
  
  /// Цвет для температуры
  bool get isEngineTempHot => engineTemp > 105;
  bool get isEngineTempCritical => engineTemp > 115;
  
  /// Статус топлива
  bool get isFuelLow => fuelLevel < 15;
  bool get isFuelCritical => fuelLevel < 5;
}