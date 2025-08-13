import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;

import '../../../core/theme/automotive_theme.dart';

/// Виджет бортового компьютера для отображения расширенной информации о поездке
/// Показывает расход топлива, среднюю скорость, расстояние и другие параметры
/// Реализует реалистичные расчеты на основе OBD-II данных автомобиля
class TripComputerWidget extends StatefulWidget {
  final Map<String, dynamic> canData;        // Данные с CAN шины
  final bool showDetailedInfo;               // Показывать детализированную информацию
  final VoidCallback? onReset;               // Колл бэк для сброса показаний
  final VoidCallback? onError;               // Обработка ошибок

  const TripComputerWidget({
    super.key,
    required this.canData,
    this.showDetailedInfo = true,
    this.onReset,
    this.onError,
  });

  @override
  State<TripComputerWidget> createState() => _TripComputerWidgetState();
}

class _TripComputerWidgetState extends State<TripComputerWidget>
    with TickerProviderStateMixin {
  
  // Калькулятор поездки для расчета средних значений и потребления
  late TripCalculator _tripCalculator;
  
  // Анимации для переходов между экранами
  late AnimationController _screenTransitionController;
  late Animation<double> _screenTransitionAnimation;
  
  // Анимация для цифровых значений
  late AnimationController _valueAnimationController;
  late Animation<double> _valueAnimation;
  
  // Тикер для периодических обновлений
  late Ticker _updateTicker;
  
  // Текущий индекс экрана (для переключения между разными видами)
  int _currentScreenIndex = 0;
  
  // Время последнего обновления для расчета deltaTime
  Duration _lastUpdateTime = Duration.zero;
  
  // Флаг ошибки
  bool _hasError = false;
  
  // Доступные экраны бортового компьютера
  static const List<String> _screenTitles = [
    'ПОЕЗДКА A',
    'ПОЕЗДКА B', 
    'СРЕДНИЕ',
    'МГНОВЕННЫЕ',
    'РАСХОД',
  ];

  @override
  void initState() {
    super.initState();
    
    try {
      // Инициализация калькулятора поездки
      _tripCalculator = TripCalculator();
      
      // Настройка анимаций переходов между экранами
      _screenTransitionController = AnimationController(
        duration: Duration(milliseconds: 800),
        vsync: this,
      );
      _screenTransitionAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _screenTransitionController,
        curve: Curves.easeInOutCubic,
      ));
      
      // Анимация значений для плавного изменения цифр
      _valueAnimationController = AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: this,
      );
      _valueAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _valueAnimationController,
        curve: Curves.easeOutQuart,
      ));
      
      // Настройка тикера для обновлений каждые 500мс (экономия ресурсов)
      _updateTicker = createTicker(_onUpdateTick);
      _updateTicker.start();
      
    } catch (e) {
      _handleError('Ошибка инициализации бортового компьютера: $e');
    }
  }

  /// Обработчик периодических обновлений
  void _onUpdateTick(Duration elapsed) {
    if (!mounted) return;
    
    try {
      final deltaTime = _lastUpdateTime == Duration.zero 
          ? 0.5  // Первое обновление
          : (elapsed - _lastUpdateTime).inMicroseconds / 1000000.0;
      
      _lastUpdateTime = elapsed;
      
      // Обновляем калькулятор поездки с новыми данными
      final wasUpdated = _tripCalculator.update(widget.canData, deltaTime);
      
      if (wasUpdated && mounted) {
        setState(() {
          // Запуск анимации обновления значений
          _valueAnimationController.forward(from: 0.0);
        });
      }
      
    } catch (e) {
      _handleError('Ошибка обновления данных: $e');
    }
  }

  /// Переключение на следующий экран бортового компьютера
  void _nextScreen() {
    setState(() {
      _currentScreenIndex = (_currentScreenIndex + 1) % _screenTitles.length;
      _screenTransitionController.forward(from: 0.0);
    });
  }

  /// Сброс текущих показаний поездки
  void _resetCurrentTrip() {
    try {
      _tripCalculator.resetTrip(_currentScreenIndex < 2 ? _currentScreenIndex : 0);
      
      // Анимация сброса
      _valueAnimationController.reverse().then((_) {
        if (mounted) {
          _valueAnimationController.forward();
        }
      });
      
      // Уведомление родительского виджета
      widget.onReset?.call();
      
    } catch (e) {
      _handleError('Ошибка сброса показаний: $e');
    }
  }

  /// Обработка ошибок
  void _handleError(String message) {
    _hasError = true;
    
    if (mounted) {
      setState(() {});
    }
    
    widget.onError?.call();
    debugPrint('TripComputerWidget Error: $message');
  }

  @override
  void dispose() {
    _updateTicker.dispose();
    _screenTransitionController.dispose();
    _valueAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с переключателем экранов
          _buildHeader(),
          
          // Основной контент с анимацией
          Expanded(
            child: AnimatedBuilder(
              animation: _screenTransitionAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + 0.2 * _screenTransitionAnimation.value,
                  child: Opacity(
                    opacity: _screenTransitionAnimation.value,
                    child: _buildCurrentScreen(),
                  ),
                );
              },
            ),
          ),
          
          // Нижняя панель управления
          if (widget.showDetailedInfo)
            _buildControlPanel(),
        ],
      ),
    );
  }

  /// Создает заголовок с названием текущего экрана
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[600]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _screenTitles[_currentScreenIndex],
            style: TextStyle(
              color: AutomotiveTheme.primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          
          // Индикаторы экранов
          Row(
            children: List.generate(_screenTitles.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentScreenIndex
                      ? AutomotiveTheme.primaryBlue
                      : Colors.grey[600],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Создает текущий экран в зависимости от выбранного индекса
  Widget _buildCurrentScreen() {
    switch (_currentScreenIndex) {
      case 0:
        return _buildTripScreen(0);
      case 1:
        return _buildTripScreen(1);
      case 2:
        return _buildAverageScreen();
      case 3:
        return _buildInstantScreen();
      case 4:
        return _buildFuelConsumptionScreen();
      default:
        return _buildTripScreen(0);
    }
  }

  /// Создает экран конкретной поездки (A или B)
  Widget _buildTripScreen(int tripIndex) {
    final tripData = _tripCalculator.getTripData(tripIndex);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Расстояние поездки
          _buildDataRow(
            'РАССТОЯНИЕ',
            '${tripData.distance.toStringAsFixed(1)} км',
            AutomotiveTheme.primaryBlue,
          ),
          
          const SizedBox(height: 16),
          
          // Время в пути
          _buildDataRow(
            'ВРЕМЯ В ПУТИ',
            _formatDuration(tripData.drivingTime),
            Colors.white,
          ),
          
          const SizedBox(height: 16),
          
          // Средняя скорость
          _buildDataRow(
            'СРЕДНЯЯ СКОРОСТЬ',
            '${tripData.averageSpeed.toStringAsFixed(1)} км/ч',
            AutomotiveTheme.successGreen,
          ),
          
          const SizedBox(height: 16),
          
          // Расход топлива
          _buildDataRow(
            'РАСХОД ТОПЛИВА',
            '${tripData.averageFuelConsumption.toStringAsFixed(1)} л/100км',
            tripData.averageFuelConsumption > 10.0 
                ? AutomotiveTheme.warningRed
                : AutomotiveTheme.accentOrange,
          ),
        ],
      ),
    );
  }

  /// Создает экран средних значений
  Widget _buildAverageScreen() {
    final averageData = _tripCalculator.getAverageData();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDataRow(
            'ОБЩИЙ ПРОБЕГ',
            '${averageData.totalDistance.toStringAsFixed(0)} км',
            Colors.white,
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'СРЕДНИЙ РАСХОД',
            '${averageData.overallAverageFuelConsumption.toStringAsFixed(1)} л/100км',
            AutomotiveTheme.accentOrange,
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'СРЕДНЯЯ СКОРОСТЬ',
            '${averageData.overallAverageSpeed.toStringAsFixed(1)} км/ч',
            AutomotiveTheme.successGreen,
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'ВРЕМЯ РАБОТЫ',
            _formatDuration(averageData.totalEngineTime),
            Colors.grey[300]!,
          ),
        ],
      ),
    );
  }

  /// Создает экран мгновенных значений
  Widget _buildInstantScreen() {
    final instantData = _tripCalculator.getInstantData();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDataRow(
            'МГНОВ. РАСХОД',
            instantData.instantFuelConsumption > 0 
                ? '${instantData.instantFuelConsumption.toStringAsFixed(1)} л/100км'
                : '--- л/100км',
            _getFuelConsumptionColor(instantData.instantFuelConsumption),
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'РАСХОД Л/Ч',
            '${instantData.fuelFlowRate.toStringAsFixed(1)} л/ч',
            Colors.white,
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'ЭФФЕКТИВНОСТЬ',
            '${instantData.efficiency.toStringAsFixed(0)}%',
            _getEfficiencyColor(instantData.efficiency),
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'КПД ДВИГАТЕЛЯ',
            '${instantData.engineEfficiency.toStringAsFixed(0)}%',
            _getEfficiencyColor(instantData.engineEfficiency),
          ),
        ],
      ),
    );
  }

  /// Создает экран детального расхода топлива
  Widget _buildFuelConsumptionScreen() {
    final fuelData = _tripCalculator.getFuelData();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDataRow(
            'ОСТАТОК ТОПЛИВА',
            '${fuelData.remainingFuel.toStringAsFixed(1)} л',
            fuelData.remainingFuel < 10.0 
                ? AutomotiveTheme.warningRed
                : Colors.white,
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'ЗАПАС ХОДА',
            '${fuelData.rangeRemaining.toStringAsFixed(0)} км',
            fuelData.rangeRemaining < 50.0 
                ? AutomotiveTheme.warningRed
                : AutomotiveTheme.successGreen,
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'ПОТРАЧЕНО',
            '${fuelData.fuelUsed.toStringAsFixed(1)} л',
            Colors.grey[300]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildDataRow(
            'СТОИМОСТЬ ПОЕЗДКИ',
            '${fuelData.tripCost.toStringAsFixed(0)} ₽',
            AutomotiveTheme.accentOrange,
          ),
        ],
      ),
    );
  }

  /// Создает строку данных с анимацией
  Widget _buildDataRow(String label, String value, Color valueColor) {
    return AnimatedBuilder(
      animation: _valueAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - _valueAnimation.value)),
          child: Opacity(
            opacity: _valueAnimation.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DigitalNumbers',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Создает панель управления внизу экрана
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[600]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Кнопка переключения экранов
          TextButton.icon(
            onPressed: _nextScreen,
            icon: Icon(Icons.skip_next, color: AutomotiveTheme.primaryBlue),
            label: Text(
              'ДАЛЕЕ',
              style: TextStyle(
                color: AutomotiveTheme.primaryBlue,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Кнопка сброса
          TextButton.icon(
            onPressed: _resetCurrentTrip,
            icon: Icon(Icons.refresh, color: AutomotiveTheme.accentOrange),
            label: Text(
              'СБРОС',
              style: TextStyle(
                color: AutomotiveTheme.accentOrange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Создает состояние ошибки
  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AutomotiveTheme.warningRed, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AutomotiveTheme.warningRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'ОШИБКА БОРТОВОГО\nКОМПЬЮТЕРА',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AutomotiveTheme.warningRed,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Форматирует продолжительность времени
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}ч ${minutes}мин';
    } else {
      return '${minutes}мин';
    }
  }

  /// Определяет цвет для расхода топлива
  Color _getFuelConsumptionColor(double consumption) {
    if (consumption <= 0) return Colors.grey[400]!;
    if (consumption < 6.0) return AutomotiveTheme.successGreen;
    if (consumption < 10.0) return AutomotiveTheme.accentOrange;
    return AutomotiveTheme.warningRed;
  }

  /// Определяет цвет для эффективности
  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return AutomotiveTheme.successGreen;
    if (efficiency >= 60) return AutomotiveTheme.accentOrange;
    return AutomotiveTheme.warningRed;
  }
}

/// Класс для расчета параметров поездки на основе реальных автомобильных данных
/// Реализует алгоритмы расчета расхода топлива, средних скоростей и других параметров
class TripCalculator {
  // Данные поездок A и B
  final List<TripData> _tripData = [TripData(), TripData()];
  
  // Общие статистические данные
  AverageData _averageData = AverageData();
  
  // Мгновенные значения
  InstantData _instantData = InstantData();
  
  // Данные по топливу
  FuelData _fuelData = FuelData();
  
  // Предыдущие значения для расчета приращений
  double _previousDistance = 0.0;
  double _previousFuelUsed = 0.0;
  DateTime _lastUpdateTime = DateTime.now();
  
  // Константы для расчетов
  static const double _fuelPricePerLiter = 55.0; // ₽ за литр
  static const double _tankCapacity = 60.0;      // литров

  /// Обновляет все расчеты на основе новых данных CAN шины
  bool update(Map<String, dynamic> canData, double deltaTime) {
    try {
      final currentTime = DateTime.now();
      final realDeltaTime = currentTime.difference(_lastUpdateTime).inMicroseconds / 1000000.0;
      _lastUpdateTime = currentTime;
      
      // Извлечение основных параметров из CAN данных
      final speed = (canData['speed']?.toDouble() ?? 0.0).clamp(0.0, 300.0);
      final rpm = (canData['rpm']?.toDouble() ?? 800.0).clamp(600.0, 8000.0);
      final throttlePosition = (canData['throttle_position']?.toDouble() ?? 0.0).clamp(0.0, 100.0);
      final fuelLevel = (canData['fuel_level']?.toDouble() ?? 50.0).clamp(0.0, 100.0);
      final odometer = canData['odometer']?.toDouble() ?? 0.0;
      final engineTemp = (canData['engine_temp']?.toDouble() ?? 90.0).clamp(60.0, 120.0);
      final massAirFlow = (canData['mass_air_flow']?.toDouble() ?? 3.5).clamp(1.0, 50.0);
      
      // Расчет приращения расстояния
      final distanceIncrement = realDeltaTime > 0 ? (speed * realDeltaTime / 3600.0) : 0.0;
      
      // Расчет мгновенного расхода топлива на основе MAF (Mass Air Flow)
      // Упрощенная формула: расход = MAF * 0.0844 * (1 + throttle_correction)
      final throttleCorrection = throttlePosition / 100.0 * 0.3;
      final instantConsumptionLH = massAirFlow * 0.0844 * (1.0 + throttleCorrection);
      final instantConsumption100km = speed > 1.0 ? (instantConsumptionLH / speed * 100.0) : 0.0;
      
      // Обновление данных поездок
      for (int i = 0; i < _tripData.length; i++) {
        _updateTripData(_tripData[i], distanceIncrement, realDeltaTime, 
                       speed, instantConsumptionLH, rpm, engineTemp);
      }
      
      // Обновление средних данных
      _updateAverageData(distanceIncrement, realDeltaTime, speed, instantConsumptionLH);
      
      // Обновление мгновенных данных
      _updateInstantData(speed, rpm, throttlePosition, instantConsumption100km, 
                        instantConsumptionLH, massAirFlow, engineTemp);
      
      // Обновление данных по топливу
      _updateFuelData(fuelLevel, instantConsumptionLH, realDeltaTime);
      
      return true;
      
    } catch (e) {
      debugPrint('TripCalculator Error: $e');
      return false;
    }
  }

  /// Обновляет данные конкретной поездки
  void _updateTripData(TripData tripData, double distanceIncrement, double deltaTime,
                      double speed, double fuelConsumptionLH, double rpm, double engineTemp) {
    
    tripData.distance += distanceIncrement;
    
    if (speed > 1.0) { // Учитываем время только при движении
      tripData.drivingTime = tripData.drivingTime + Duration(microseconds: (deltaTime * 1000000).round());
      
      // Обновление средней скорости (с учетом только времени в движении)
      final totalMinutes = tripData.drivingTime.inMinutes;
      if (totalMinutes > 0) {
        tripData.averageSpeed = (tripData.distance / totalMinutes) * 60.0;
      }
    }
    
    // Расчет расхода топлива
    final fuelUsedIncrement = fuelConsumptionLH * (deltaTime / 3600.0); // литры
    tripData.fuelUsed += fuelUsedIncrement;
    
    // Средний расход на 100 км
    if (tripData.distance > 0.1) {
      tripData.averageFuelConsumption = (tripData.fuelUsed / tripData.distance) * 100.0;
    }
    
    // Максимальная скорость
    tripData.maxSpeed = math.max(tripData.maxSpeed, speed);
    
    // Максимальные обороты
    tripData.maxRpm = math.max(tripData.maxRpm, rpm);
  }

  /// Обновляет средние данные за весь период использования
  void _updateAverageData(double distanceIncrement, double deltaTime, 
                         double speed, double fuelConsumptionLH) {
    
    _averageData.totalDistance += distanceIncrement;
    _averageData.totalEngineTime = _averageData.totalEngineTime + 
        Duration(microseconds: (deltaTime * 1000000).round());
    
    _averageData.totalFuelUsed += fuelConsumptionLH * (deltaTime / 3600.0);
    
    // Общий средний расход
    if (_averageData.totalDistance > 0.1) {
      _averageData.overallAverageFuelConsumption = 
          (_averageData.totalFuelUsed / _averageData.totalDistance) * 100.0;
    }
    
    // Общая средняя скорость
    final totalHours = _averageData.totalEngineTime.inMinutes / 60.0;
    if (totalHours > 0) {
      _averageData.overallAverageSpeed = _averageData.totalDistance / totalHours;
    }
  }

  /// Обновляет мгновенные данные
  void _updateInstantData(double speed, double rpm, double throttlePosition,
                         double instantConsumption, double fuelFlowRate,
                         double massAirFlow, double engineTemp) {
    
    _instantData.instantFuelConsumption = instantConsumption;
    _instantData.fuelFlowRate = fuelFlowRate;
    
    // Расчет эффективности на основе нагрузки двигателя
    // Упрощенная формула: эффективность зависит от RPM, throttle и температуры
    final rpmEfficiency = _calculateRpmEfficiency(rpm);
    final throttleEfficiency = _calculateThrottleEfficiency(throttlePosition);
    final tempEfficiency = _calculateTempEfficiency(engineTemp);
    
    _instantData.efficiency = (rpmEfficiency + throttleEfficiency + tempEfficiency) / 3.0;
    _instantData.engineEfficiency = _calculateEngineEfficiency(rpm, throttlePosition, massAirFlow);
  }

  /// Обновляет данные по топливу
  void _updateFuelData(double fuelLevel, double fuelConsumptionLH, double deltaTime) {
    // Остаток топлива в литрах
    _fuelData.remainingFuel = (fuelLevel / 100.0) * _tankCapacity;
    
    // Инкремент потраченного топлива
    final fuelUsedIncrement = fuelConsumptionLH * (deltaTime / 3600.0);
    _fuelData.fuelUsed += fuelUsedIncrement;
    
    // Стоимость поездки
    _fuelData.tripCost = _fuelData.fuelUsed * _fuelPricePerLiter;
    
    // Запас хода на основе текущего расхода
    double avgConsumption = 0.0;
    for (final trip in _tripData) {
      if (trip.averageFuelConsumption > 0) {
        avgConsumption += trip.averageFuelConsumption;
      }
    }
    avgConsumption = avgConsumption > 0 ? avgConsumption / _tripData.length : 8.0;
    
    _fuelData.rangeRemaining = (_fuelData.remainingFuel / avgConsumption) * 100.0;
  }

  /// Расчет эффективности RPM (оптимальные обороты 1500-3000)
  double _calculateRpmEfficiency(double rpm) {
    if (rpm < 1000) return 60.0;
    if (rpm >= 1500 && rpm <= 3000) return 90.0;
    if (rpm <= 4000) return 75.0;
    return math.max(30.0, 90.0 - (rpm - 4000) * 0.01);
  }

  /// Расчет эффективности throttle (оптимальная нагрузка 20-60%)
  double _calculateThrottleEfficiency(double throttle) {
    if (throttle < 10) return 95.0;
    if (throttle >= 20 && throttle <= 60) return 85.0;
    if (throttle <= 80) return 70.0;
    return 50.0;
  }

  /// Расчет эффективности по температуре (оптимальная 85-95°C)
  double _calculateTempEfficiency(double temp) {
    if (temp >= 85 && temp <= 95) return 95.0;
    if (temp >= 80 && temp <= 100) return 85.0;
    if (temp < 70) return 70.0; // Холодный двигатель
    return 60.0; // Перегрев
  }

  /// Расчет КПД двигателя на основе комплексных параметров
  double _calculateEngineEfficiency(double rpm, double throttle, double maf) {
    // Упрощенная модель КПД: учитывает соотношение воздух/топливо
    final theoreticalMAF = (rpm / 1000.0) * (throttle / 100.0) * 2.5;
    final efficiency = (theoreticalMAF / maf).clamp(0.3, 1.0) * 85.0;
    return efficiency;
  }

  /// Сбрасывает данные указанной поездки
  void resetTrip(int tripIndex) {
    if (tripIndex >= 0 && tripIndex < _tripData.length) {
      _tripData[tripIndex] = TripData();
    }
  }

  /// Получение данных поездки
  TripData getTripData(int tripIndex) {
    return tripIndex >= 0 && tripIndex < _tripData.length 
        ? _tripData[tripIndex] 
        : TripData();
  }

  /// Получение средних данных
  AverageData getAverageData() => _averageData;

  /// Получение мгновенных данных
  InstantData getInstantData() => _instantData;

  /// Получение данных по топливу
  FuelData getFuelData() => _fuelData;
}

/// Данные конкретной поездки
class TripData {
  double distance = 0.0;                    // Расстояние в км
  Duration drivingTime = Duration.zero;     // Время в движении
  double averageSpeed = 0.0;               // Средняя скорость км/ч
  double maxSpeed = 0.0;                   // Максимальная скорость
  double fuelUsed = 0.0;                   // Потрачено топлива в литрах
  double averageFuelConsumption = 0.0;     // Средний расход л/100км
  double maxRpm = 0.0;                     // Максимальные обороты
}

/// Общие средние данные
class AverageData {
  double totalDistance = 0.0;                    // Общий пробег
  Duration totalEngineTime = Duration.zero;      // Общее время работы
  double totalFuelUsed = 0.0;                   // Общий расход топлива
  double overallAverageSpeed = 0.0;             // Общая средняя скорость
  double overallAverageFuelConsumption = 0.0;   // Общий средний расход
}

/// Мгновенные данные
class InstantData {
  double instantFuelConsumption = 0.0;    // Мгновенный расход л/100км
  double fuelFlowRate = 0.0;             // Расход л/ч
  double efficiency = 0.0;               // Эффективность вождения %
  double engineEfficiency = 0.0;         // КПД двигателя %
}

/// Данные по топливу
class FuelData {
  double remainingFuel = 0.0;      // Остаток топлива в литрах
  double rangeRemaining = 0.0;     // Запас хода в км
  double fuelUsed = 0.0;          // Потрачено топлива
  double tripCost = 0.0;          // Стоимость поездки в рублях
}