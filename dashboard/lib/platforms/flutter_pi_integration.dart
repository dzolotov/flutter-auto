import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Интеграция с Flutter-pi для запуска на Raspberry Pi без X11
/// Обеспечивает оптимизацию производительности и управление ресурсами
class FlutterPiIntegration {
  static final Logger _logger = Logger();
  static const MethodChannel _platformChannel = MethodChannel('automotive/platform');
  
  static bool _isRaspberryPi = false;
  static Map<String, dynamic> _systemInfo = {};

  /// Инициализация интеграции с Flutter-pi
  static Future<void> initialize() async {
    try {
      _logger.i('Инициализация Flutter-pi интеграции...');
      
      // Определение платформы
      await _detectPlatform();
      
      if (_isRaspberryPi) {
        await _optimizeForRaspberryPi();
        await _setupGpioIntegration();
        await _configureDisplaySettings();
      }
      
      _logger.i('Flutter-pi интеграция завершена успешно');
    } catch (e) {
      _logger.e('Ошибка инициализации Flutter-pi: $e');
    }
  }

  /// Определение платформы выполнения
  static Future<void> _detectPlatform() async {
    try {
      // Проверка наличия Flutter-pi через файловую систему
      final result = await _platformChannel.invokeMethod('getPlatformInfo');
      _systemInfo = Map<String, dynamic>.from(result);
      
      _isRaspberryPi = _systemInfo['isRaspberryPi'] == true ||
                      _systemInfo['platform']?.toString().contains('linux') == true;
      
      _logger.i('Платформа: ${_isRaspberryPi ? "Raspberry Pi" : "Другая"}');
      _logger.d('Информация о системе: $_systemInfo');
    } catch (e) {
      _logger.w('Не удалось определить платформу: $e');
      // Fallback: предполагаем, что это обычная платформа
      _isRaspberryPi = false;
    }
  }

  /// Оптимизация для Raspberry Pi
  static Future<void> _optimizeForRaspberryPi() async {
    try {
      await _platformChannel.invokeMethod('optimizeForRaspberryPi', {
        'enableGPUAcceleration': true,
        'memoryOptimization': true,
        'reducedAnimations': true,
      });
      
      _logger.i('Оптимизация для Raspberry Pi применена');
    } catch (e) {
      _logger.w('Не удалось применить оптимизацию: $e');
    }
  }

  /// Настройка GPIO для интеграции с аппаратными кнопками и датчиками
  static Future<void> _setupGpioIntegration() async {
    try {
      await _platformChannel.invokeMethod('setupGPIO', {
        'pins': {
          'button_home': 18,      // Кнопка домой
          'button_back': 19,      // Кнопка назад
          'rotary_encoder_a': 20, // Энкодер поворота A
          'rotary_encoder_b': 21, // Энкодер поворота B
          'brightness_control': 12, // PWM для яркости
          'status_led': 13,       // Светодиод состояния
        }
      });
      
      _logger.i('GPIO настройка завершена');
    } catch (e) {
      _logger.w('Не удалось настроить GPIO: $e');
    }
  }

  /// Конфигурация настроек дисплея
  static Future<void> _configureDisplaySettings() async {
    try {
      await _platformChannel.invokeMethod('configureDisplay', {
        'resolution': '1920x1080',
        'refreshRate': 60,
        'colorDepth': 24,
        'rotation': 0,
        'touchscreen': true,
      });
      
      _logger.i('Настройки дисплея применены');
    } catch (e) {
      _logger.w('Не удалось настроить дисплей: $e');
    }
  }

  /// Проверка, выполняется ли приложение на Raspberry Pi
  static bool get isRaspberryPi => _isRaspberryPi;

  /// Получение информации о системе
  static Map<String, dynamic> get systemInfo => _systemInfo;

  /// Управление яркостью дисплея
  static Future<void> setBrightness(double brightness) async {
    if (!_isRaspberryPi) return;
    
    try {
      await _platformChannel.invokeMethod('setBrightness', {
        'value': brightness.clamp(0.0, 1.0),
      });
    } catch (e) {
      _logger.w('Не удалось установить яркость: $e');
    }
  }

  /// Управление состоянием светодиода
  static Future<void> setStatusLed(bool enabled) async {
    if (!_isRaspberryPi) return;
    
    try {
      await _platformChannel.invokeMethod('setStatusLed', {
        'enabled': enabled,
      });
    } catch (e) {
      _logger.w('Не удалось управлять светодиодом: $e');
    }
  }

  /// Получение температуры процессора
  static Future<double> getCpuTemperature() async {
    if (!_isRaspberryPi) return 0.0;
    
    try {
      final result = await _platformChannel.invokeMethod('getCpuTemperature');
      return (result as num).toDouble();
    } catch (e) {
      _logger.w('Не удалось получить температуру CPU: $e');
      return 0.0;
    }
  }

  /// Получение загрузки системы
  static Future<Map<String, double>> getSystemLoad() async {
    if (!_isRaspberryPi) return {'cpu': 0.0, 'memory': 0.0};
    
    try {
      final result = await _platformChannel.invokeMethod('getSystemLoad');
      return {
        'cpu': (result['cpu'] as num).toDouble(),
        'memory': (result['memory'] as num).toDouble(),
      };
    } catch (e) {
      _logger.w('Не удалось получить загрузку системы: $e');
      return {'cpu': 0.0, 'memory': 0.0};
    }
  }
}

/// Виджет для отображения системной информации Raspberry Pi
class FlutterPiSystemInfo extends StatefulWidget {
  const FlutterPiSystemInfo({super.key});

  @override
  State<FlutterPiSystemInfo> createState() => _FlutterPiSystemInfoState();
}

class _FlutterPiSystemInfoState extends State<FlutterPiSystemInfo> {
  double _cpuTemp = 0.0;
  double _cpuLoad = 0.0;
  double _memoryLoad = 0.0;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    if (FlutterPiIntegration.isRaspberryPi) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _isMonitoring = true;
    _updateSystemInfo();
  }

  Future<void> _updateSystemInfo() async {
    if (!_isMonitoring || !mounted) return;

    try {
      final temp = await FlutterPiIntegration.getCpuTemperature();
      final load = await FlutterPiIntegration.getSystemLoad();

      if (mounted) {
        setState(() {
          _cpuTemp = temp;
          _cpuLoad = load['cpu'] ?? 0.0;
          _memoryLoad = load['memory'] ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('Ошибка обновления системной информации: $e');
    }

    // Обновление каждые 2 секунды
    if (_isMonitoring) {
      Future.delayed(Duration(seconds: 2), _updateSystemInfo);
    }
  }

  @override
  void dispose() {
    _isMonitoring = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FlutterPiIntegration.isRaspberryPi) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Flutter-pi не обнаружен',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Приложение работает в обычном режиме Flutter',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Системная информация Raspberry Pi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Платформа', FlutterPiIntegration.systemInfo['platform'] ?? 'Неизвестно'),
            _buildInfoRow('Архитектура', FlutterPiIntegration.systemInfo['architecture'] ?? 'Неизвестно'),
            _buildInfoRow('Версия ядра', FlutterPiIntegration.systemInfo['kernelVersion'] ?? 'Неизвестно'),
            
            const SizedBox(height: 16),
            Divider(),
            const SizedBox(height: 16),
            
            _buildProgressInfo('Температура CPU', _cpuTemp, '°C', 0, 85, Colors.orange),
            const SizedBox(height: 12),
            _buildProgressInfo('Загрузка CPU', _cpuLoad, '%', 0, 100, Colors.blue),
            const SizedBox(height: 12),
            _buildProgressInfo('Использование памяти', _memoryLoad, '%', 0, 100, Colors.purple),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testGpio,
                    icon: Icon(Icons.flash_on),
                    label: Text('Тест GPIO'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _adjustBrightness,
                    icon: Icon(Icons.brightness_6),
                    label: Text('Яркость'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(String label, double value, String unit, double min, double max, Color color) {
    final progress = (value - min) / (max - min);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[400])),
            Text('${value.toStringAsFixed(1)}$unit', 
                 style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Future<void> _testGpio() async {
    try {
      // Мигание светодиодом состояния
      for (int i = 0; i < 5; i++) {
        await FlutterPiIntegration.setStatusLed(true);
        await Future.delayed(Duration(milliseconds: 200));
        await FlutterPiIntegration.setStatusLed(false);
        await Future.delayed(Duration(milliseconds: 200));
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPIO тест завершен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка GPIO теста: $e')),
      );
    }
  }

  Future<void> _adjustBrightness() async {
    showDialog(
      context: context,
      builder: (context) => _BrightnessDialog(),
    );
  }
}

/// Диалог настройки яркости
class _BrightnessDialog extends StatefulWidget {
  @override
  State<_BrightnessDialog> createState() => _BrightnessDialogState();
}

class _BrightnessDialogState extends State<_BrightnessDialog> {
  double _brightness = 0.8;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Настройка яркости'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Яркость: ${(_brightness * 100).toInt()}%'),
          const SizedBox(height: 16),
          Slider(
            value: _brightness,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _brightness = value;
              });
              FlutterPiIntegration.setBrightness(value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Закрыть'),
        ),
      ],
    );
  }
}