import 'package:flutter/material.dart';  // Added missing import for IconData
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Провайдер для управления системой дисплеев
final displayManagerProvider = StateNotifierProvider<DisplayManager, DisplaySystemState>((ref) {
  return DisplayManager();
});

/// Состояние системы дисплеев
class DisplaySystemState {
  final List<DisplayInfo> displays;
  final Map<String, DisplayConfiguration> configurations;
  final bool mirroringEnabled;
  final String? primaryDisplayId;

  const DisplaySystemState({
    required this.displays,
    required this.configurations,
    this.mirroringEnabled = false,
    this.primaryDisplayId,
  });

  DisplaySystemState copyWith({
    List<DisplayInfo>? displays,
    Map<String, DisplayConfiguration>? configurations,
    bool? mirroringEnabled,
    String? primaryDisplayId,
  }) {
    return DisplaySystemState(
      displays: displays ?? this.displays,
      configurations: configurations ?? this.configurations,
      mirroringEnabled: mirroringEnabled ?? this.mirroringEnabled,
      primaryDisplayId: primaryDisplayId ?? this.primaryDisplayId,
    );
  }
}

/// Информация о дисплее
class DisplayInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String resolution;
  final DisplayType type;

  const DisplayInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.resolution,
    required this.type,
  });
}

/// Конфигурация дисплея
class DisplayConfiguration {
  final String displayId;
  final double brightness;
  final int rotation; // 0, 90, 180, 270 degrees
  final bool isActive;
  final DisplayMode mode;
  final Map<String, dynamic> customSettings;

  const DisplayConfiguration({
    required this.displayId,
    this.brightness = 0.8,
    this.rotation = 0,
    this.isActive = true,
    this.mode = DisplayMode.normal,
    this.customSettings = const {},
  });

  DisplayConfiguration copyWith({
    String? displayId,
    double? brightness,
    int? rotation,
    bool? isActive,
    DisplayMode? mode,
    Map<String, dynamic>? customSettings,
  }) {
    return DisplayConfiguration(
      displayId: displayId ?? this.displayId,
      brightness: brightness ?? this.brightness,
      rotation: rotation ?? this.rotation,
      isActive: isActive ?? this.isActive,
      mode: mode ?? this.mode,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Типы дисплеев
enum DisplayType {
  mediumDashboard,  // Красивая анимированная панель
  instrumentCluster,
  infotainment,
  headsUp,
  rearPassenger,
}

/// Режимы отображения
enum DisplayMode {
  normal,
  mirrored,
  extended,
  disabled,
}

/// Менеджер системы дисплеев
class DisplayManager extends StateNotifier<DisplaySystemState> {
  static final Logger _logger = Logger();

  DisplayManager() : super(const DisplaySystemState(
    displays: [],
    configurations: {},
  ));

  /// Инициализация системы дисплеев
  Future<void> initialize(List<DisplayInfo> displays) async {
    try {
      _logger.i('Инициализация системы дисплеев...');
      
      // Создание конфигураций по умолчанию
      final configurations = <String, DisplayConfiguration>{};
      for (final display in displays) {
        configurations[display.id] = DisplayConfiguration(
          displayId: display.id,
          brightness: _getDefaultBrightness(display.type),
          rotation: _getDefaultRotation(display.type),
          isActive: true,
          mode: DisplayMode.normal,
        );
      }
      
      state = state.copyWith(
        displays: displays,
        configurations: configurations,
        primaryDisplayId: displays.isNotEmpty ? displays.first.id : null,
      );
      
      _logger.i('Инициализировано ${displays.length} дисплеев');
    } catch (e) {
      _logger.e('Ошибка инициализации дисплеев: $e');
    }
  }

  /// Установка яркости дисплея
  void setDisplayBrightness(String displayId, double brightness) {
    final config = state.configurations[displayId];
    if (config == null) return;

    final updatedConfig = config.copyWith(brightness: brightness);
    final updatedConfigurations = Map<String, DisplayConfiguration>.from(state.configurations);
    updatedConfigurations[displayId] = updatedConfig;

    state = state.copyWith(configurations: updatedConfigurations);
    _logger.d('Яркость дисплея $displayId: ${(brightness * 100).toInt()}%');
  }

  /// Поворот дисплея
  void rotateDisplay(String displayId) {
    final config = state.configurations[displayId];
    if (config == null) return;

    final newRotation = (config.rotation + 90) % 360;
    final updatedConfig = config.copyWith(rotation: newRotation);
    final updatedConfigurations = Map<String, DisplayConfiguration>.from(state.configurations);
    updatedConfigurations[displayId] = updatedConfig;

    state = state.copyWith(configurations: updatedConfigurations);
    _logger.i('Дисплей $displayId повернут на ${newRotation}°');
  }

  /// Включение/выключение дисплея
  void toggleDisplay(String displayId) {
    final config = state.configurations[displayId];
    if (config == null) return;

    final updatedConfig = config.copyWith(isActive: !config.isActive);
    final updatedConfigurations = Map<String, DisplayConfiguration>.from(state.configurations);
    updatedConfigurations[displayId] = updatedConfig;

    state = state.copyWith(configurations: updatedConfigurations);
    _logger.i('Дисплей $displayId ${updatedConfig.isActive ? "включен" : "выключен"}');
  }

  /// Установка режима дисплея
  void setDisplayMode(String displayId, DisplayMode mode) {
    final config = state.configurations[displayId];
    if (config == null) return;

    final updatedConfig = config.copyWith(mode: mode);
    final updatedConfigurations = Map<String, DisplayConfiguration>.from(state.configurations);
    updatedConfigurations[displayId] = updatedConfig;

    state = state.copyWith(configurations: updatedConfigurations);
    _logger.i('Режим дисплея $displayId: ${mode.name}');
  }

  /// Синхронизация всех дисплеев
  void syncAllDisplays() {
    final primaryConfig = state.primaryDisplayId != null 
        ? state.configurations[state.primaryDisplayId!]
        : null;
    
    if (primaryConfig == null) return;

    final updatedConfigurations = <String, DisplayConfiguration>{};
    for (final display in state.displays) {
      if (display.id != state.primaryDisplayId) {
        updatedConfigurations[display.id] = state.configurations[display.id]!.copyWith(
          brightness: primaryConfig.brightness,
          mode: DisplayMode.mirrored,
        );
      } else {
        updatedConfigurations[display.id] = primaryConfig;
      }
    }

    state = state.copyWith(configurations: updatedConfigurations);
    _logger.i('Все дисплеи синхронизированы с основным');
  }

  /// Включение режима зеркалирования
  void enableMirroring() {
    final updatedConfigurations = <String, DisplayConfiguration>{};
    for (final entry in state.configurations.entries) {
      updatedConfigurations[entry.key] = entry.value.copyWith(
        mode: DisplayMode.mirrored,
      );
    }

    state = state.copyWith(
      configurations: updatedConfigurations,
      mirroringEnabled: true,
    );
    _logger.i('Режим зеркалирования включен');
  }

  /// Отключение режима зеркалирования
  void disableMirroring() {
    final updatedConfigurations = <String, DisplayConfiguration>{};
    for (final entry in state.configurations.entries) {
      updatedConfigurations[entry.key] = entry.value.copyWith(
        mode: DisplayMode.normal,
      );
    }

    state = state.copyWith(
      configurations: updatedConfigurations,
      mirroringEnabled: false,
    );
    _logger.i('Режим зеркалирования отключен');
  }

  /// Установка основного дисплея
  void setPrimaryDisplay(String displayId) {
    if (!state.displays.any((d) => d.id == displayId)) return;

    state = state.copyWith(primaryDisplayId: displayId);
    _logger.i('Основной дисплей установлен: $displayId');
  }

  /// Применение пользовательских настроек дисплея
  void applyCustomSettings(String displayId, Map<String, dynamic> settings) {
    final config = state.configurations[displayId];
    if (config == null) return;

    final updatedConfig = config.copyWith(customSettings: settings);
    final updatedConfigurations = Map<String, DisplayConfiguration>.from(state.configurations);
    updatedConfigurations[displayId] = updatedConfig;

    state = state.copyWith(configurations: updatedConfigurations);
    _logger.i('Применены пользовательские настройки для дисплея $displayId');
  }

  /// Сброс настроек дисплея
  void resetDisplaySettings(String displayId) {
    final display = state.displays.firstWhere(
      (d) => d.id == displayId,
      orElse: () => throw ArgumentError('Display not found: $displayId'),
    );

    final defaultConfig = DisplayConfiguration(
      displayId: displayId,
      brightness: _getDefaultBrightness(display.type),
      rotation: _getDefaultRotation(display.type),
      isActive: true,
      mode: DisplayMode.normal,
    );

    final updatedConfigurations = Map<String, DisplayConfiguration>.from(state.configurations);
    updatedConfigurations[displayId] = defaultConfig;

    state = state.copyWith(configurations: updatedConfigurations);
    _logger.i('Настройки дисплея $displayId сброшены');
  }

  /// Получение конфигурации дисплея
  DisplayConfiguration? getDisplayConfiguration(String displayId) {
    return state.configurations[displayId];
  }

  /// Получение активных дисплеев
  List<DisplayInfo> getActiveDisplays() {
    return state.displays.where((display) {
      final config = state.configurations[display.id];
      return config?.isActive == true;
    }).toList();
  }

  /// Получение яркости по умолчанию для типа дисплея
  double _getDefaultBrightness(DisplayType type) {
    switch (type) {
      case DisplayType.mediumDashboard:
        return 0.85; // Средне-высокая яркость для анимированной панели
      case DisplayType.instrumentCluster:
        return 0.9; // Высокая яркость для приборов
      case DisplayType.infotainment:
        return 0.8; // Средняя яркость
      case DisplayType.headsUp:
        return 0.7; // Пониженная яркость для HUD
      case DisplayType.rearPassenger:
        return 0.6; // Комфортная яркость для пассажиров
    }
  }

  /// Получение поворота по умолчанию для типа дисплея
  int _getDefaultRotation(DisplayType type) {
    switch (type) {
      case DisplayType.mediumDashboard:
        return 0; // Альбомная ориентация
      case DisplayType.instrumentCluster:
        return 0; // Альбомная ориентация
      case DisplayType.infotainment:
        return 0; // Альбомная ориентация
      case DisplayType.headsUp:
        return 0; // Альбомная ориентация
      case DisplayType.rearPassenger:
        return 0; // Альбомная ориентация
    }
  }
}

/// Расширения для enum
extension DisplayTypeExtension on DisplayType {
  String get displayName {
    switch (this) {
      case DisplayType.mediumDashboard:
        return 'Анимированная панель';
      case DisplayType.instrumentCluster:
        return 'Приборная панель';
      case DisplayType.infotainment:
        return 'Инфотейнмент';
      case DisplayType.headsUp:
        return 'Проекционный дисплей';
      case DisplayType.rearPassenger:
        return 'Задний дисплей';
    }
  }
}

extension DisplayModeExtension on DisplayMode {
  String get displayName {
    switch (this) {
      case DisplayMode.normal:
        return 'Обычный';
      case DisplayMode.mirrored:
        return 'Зеркалированный';
      case DisplayMode.extended:
        return 'Расширенный';
      case DisplayMode.disabled:
        return 'Отключен';
    }
  }
}