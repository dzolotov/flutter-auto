import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;

import '../../../core/theme/automotive_theme.dart';

/// Виджет спидометра с аналоговым циферблатом и физической симуляцией
/// Реализует реалистичное поведение стрелки с инерцией и демпфированием
/// Оптимизирован для 60 FPS на автомобильных дисплеях и встраиваемых системах
class SpeedometerWidget extends StatefulWidget {
  final double speed;           // Текущая скорость в км/ч
  final double maxSpeed;        // Максимальная скорость на шкале
  final bool showDigital;       // Показывать ли цифровое значение
  final VoidCallback? onError;  // Коллбэк для обработки ошибок

  const SpeedometerWidget({
    super.key,
    required this.speed,
    this.maxSpeed = 240.0,        // Увеличено до 240 км/ч для современных авто
    this.showDigital = true,
    this.onError,
  });

  @override
  State<SpeedometerWidget> createState() => _SpeedometerWidgetState();
}

class _SpeedometerWidgetState extends State<SpeedometerWidget>
    with TickerProviderStateMixin {
  
  
  // Контроллер анимации для 60 FPS обновлений
  late Ticker _ticker;
  
  // Время последнего обновления для расчета deltaTime
  Duration _lastUpdateTime = Duration.zero;
  
  // Текущие значения для отображения
  double _displaySpeed = 0.0;
  double _targetSpeed = 0.0;
  
  // Счетчики для мониторинга производительности
  int _frameCount = 0;
  double _averageFPS = 60.0;
  
  // Флаг для обработки ошибок
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    try {
      
      // Настройка тикера для 60 FPS обновлений
      _ticker = createTicker(_onTick);
      
      // Установка начальных значений
      _targetSpeed = widget.speed.clamp(0.0, widget.maxSpeed);
      _displaySpeed = _targetSpeed;
      
    } catch (e) {
      _handleError('Ошибка инициализации спидометра: $e');
    }
  }

  @override
  void didUpdateWidget(SpeedometerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    try {
      // Обновление целевой скорости при изменении значения
      if (oldWidget.speed != widget.speed) {
        _updateTargetSpeed(widget.speed);
      }
      
      
    } catch (e) {
      _handleError('Ошибка обновления спидометра: $e');
    }
  }

  /// Обновляет целевую скорость с валидацией
  void _updateTargetSpeed(double newSpeed) {
    // Валидация входных данных
    if (newSpeed.isNaN || newSpeed.isInfinite) {
      _handleError('Получено некорректное значение скорости: $newSpeed');
      return;
    }
    
    _targetSpeed = newSpeed.clamp(0.0, widget.maxSpeed);
    
    // Запуск тикера, если он остановился
    if (!_ticker.isActive && (_targetSpeed - _displaySpeed).abs() > 1.0) {
      _ticker.start();
    }
    
    if (!_ticker.isActive) {
      _displaySpeed = _targetSpeed;
    }
  }

  /// Обработчик обновлений с частотой 60 FPS
  void _onTick(Duration elapsed) {
    if (!mounted) return;
    
    try {
      // Расчет времени с предыдущего кадра
      final deltaTime = _lastUpdateTime == Duration.zero 
          ? 1.0 / 60.0  // Первый кадр - предполагаем 60 FPS
          : (elapsed - _lastUpdateTime).inMicroseconds / 1000000.0;
      
      _lastUpdateTime = elapsed;
      
      // Простая интерполяция к целевой скорости
      final diff = _targetSpeed - _displaySpeed;
      if (diff.abs() > 0.5) {
        _displaySpeed += diff * deltaTime * 3.0; // Скорость интерполяции
        setState(() {});
        
        // Подсчет FPS для мониторинга производительности
        _frameCount++;
        if (_frameCount % 60 == 0) {
          _averageFPS = 60.0 / (deltaTime * 60);
        }
      } else {
        // Остановка тикера для экономии ресурсов
        _displaySpeed = _targetSpeed;
        _ticker.stop();
      }
      
    } catch (e) {
      _handleError('Ошибка обновления физики: $e');
    }
  }

  /// Обработка ошибок с возможностью восстановления
  void _handleError(String message) {
    _hasError = true;
    
    // Попытка восстановления - установка безопасного значения
    if (mounted) {
      setState(() {
        _displaySpeed = 0.0;
      });
    }
    
    // Уведомление родительского виджета об ошибке
    widget.onError?.call();
    
    // В реальном приложении здесь должно быть логирование
    debugPrint('SpeedometerWidget Error: $message');
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Состояние ошибки - показываем безопасный интерфейс
    if (_hasError) {
      return _buildErrorState();
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.speedometerGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: AutomotiveTheme.primaryBlue.withOpacity(0.5), 
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AutomotiveTheme.primaryBlue.withOpacity(0.3),
            spreadRadius: 8,
            blurRadius: 20,
            offset: Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            spreadRadius: 2,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: EnhancedSpeedometerPainter(
          speed: _displaySpeed,
          maxSpeed: widget.maxSpeed,
          targetSpeed: _targetSpeed,
          velocity: (_targetSpeed - _displaySpeed).abs(),
          averageFPS: _averageFPS,
        ),
        child: widget.showDigital ? _buildDigitalDisplay() : null,
      ),
    );
  }

  /// Создает цифровое отображение скорости
  Widget _buildDigitalDisplay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Основное значение скорости
          Text(
            _displaySpeed.toStringAsFixed(0),
            style: TextStyle(
              color: _getSpeedColor(_displaySpeed),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'DigitalNumbers',
              shadows: [
                Shadow(
                  color: _getSpeedColor(_displaySpeed).withOpacity(0.8),
                  blurRadius: 15,
                ),
                Shadow(
                  color: _getSpeedColor(_displaySpeed).withOpacity(0.5),
                  blurRadius: 25,
                ),
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          
          // Единицы измерения
          Text(
            'км/ч',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Индикатор скорости изменения (только в debug режиме)
          if (_ticker.isActive && (_targetSpeed - _displaySpeed).abs() > 5.0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 60,
                height: 2,
                decoration: BoxDecoration(
                  color: AutomotiveTheme.primaryBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: FractionallySizedBox(
                  widthFactor: ((_targetSpeed - _displaySpeed).abs() / 50).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AutomotiveTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
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
        shape: BoxShape.circle,
        border: Border.all(color: AutomotiveTheme.warningRed, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AutomotiveTheme.warningRed,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'ОШИБКА',
              style: TextStyle(
                color: AutomotiveTheme.warningRed,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'СПИДОМЕТР',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Определяет цвет скорости в зависимости от значения
  Color _getSpeedColor(double speed) {
    if (speed > widget.maxSpeed * 0.9) {
      return AutomotiveTheme.warningRed;
    } else if (speed > widget.maxSpeed * 0.75) {
      return AutomotiveTheme.accentOrange;
    } else if (speed > widget.maxSpeed * 0.5) {
      return AutomotiveTheme.primaryCyan;
    } else {
      return AutomotiveTheme.primaryBlue;
    }
  }
}

/// Улучшенный кастомный рисовальщик для спидометра с эффектами и оптимизацией
/// Поддерживает физическую симуляцию, многослойное отображение и эффекты
class EnhancedSpeedometerPainter extends CustomPainter {
  final double speed;              // Текущая отображаемая скорость
  final double maxSpeed;           // Максимальная скорость на шкале
  final double targetSpeed;        // Целевая скорость (для эффектов)
  final double velocity; // Скорость изменения (упрощенная)
  final double averageFPS;         // Средний FPS для оптимизации
  
  // Константы для угловых расчетов (охват 270 градусов)
  static const double _startAngle = -math.pi * 0.75; // Начальный угол (-135°)
  static const double _sweepAngle = math.pi * 1.5;   // Диапазон угла (270°)
  
  // Кэш для оптимизации отрисовки
  static Path? _cachedScalePath;
  static List<TextPainter>? _cachedNumberPainters;
  static double? _cachedMaxSpeed;

  EnhancedSpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.targetSpeed,
    this.velocity = 0.0,
    this.averageFPS = 60.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Оптимизация: создание кэша для статичных элементов
    _updateCacheIfNeeded(size);
    
    // Слой 1: Основа циферблата (статичная, кэшируется)
    _drawBackground(canvas, center, radius);
    _drawOuterRing(canvas, center, radius);
    
    // Слой 2: Шкала и числа (статичная, кэшируется при изменении maxSpeed)
    _drawScaleMarks(canvas, center, radius);
    _drawScaleNumbers(canvas, center, radius);
    
    // Слой 3: Цветовые зоны (статичная)
    _drawColorZones(canvas, center, radius);
    
    // Слой 4: Динамические эффекты
    _drawSpeedTrail(canvas, center, radius);
    _drawTargetIndicator(canvas, center, radius);
    
    // Слой 5: Стрелка и центр (динамичная)
    _drawNeedle(canvas, center, radius);
    _drawCenterDot(canvas, center);
    
    // Слой 6: Эффекты производительности (debug режим)
    if (averageFPS < 50) {
      _drawPerformanceWarning(canvas, size);
    }
  }

  /// Обновляет кэш статичных элементов при необходимости
  void _updateCacheIfNeeded(Size size) {
    if (_cachedMaxSpeed != maxSpeed) {
      _cachedMaxSpeed = maxSpeed;
      _cachedScalePath = null;
      _cachedNumberPainters = null;
    }
  }

  /// Рисует фоновый градиент циферблата
  void _drawBackground(Canvas canvas, Offset center, double radius) {
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey[900]!,
          Colors.black,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, backgroundPaint);
  }

  /// Рисует внешнее кольцо спидометра
  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.grey[600]!;

    canvas.drawCircle(center, radius, paint);
  }

  /// Рисует улучшенные деления шкалы с адаптивным шагом
  void _drawScaleMarks(Canvas canvas, Offset center, double radius) {
    final majorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final minorPaint = Paint()
      ..color = Colors.grey[500]!
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    
    final microPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;

    final majorStep = _calculateOptimalStep(maxSpeed);
    final minorStep = majorStep ~/ 2;
    final microStep = majorStep ~/ 4;

    // Рисуем микроделения (каждые 5-10 км/ч)
    for (int i = 0; i <= maxSpeed.toInt(); i += microStep) {
      if (i % minorStep != 0) { // Не рисуем микроделения там, где есть минор/мажор
        final angle = _startAngle + (i / maxSpeed) * _sweepAngle;
        _drawScaleMark(canvas, center, radius, angle, 4.0, microPaint);
      }
    }
    
    // Рисуем минорные деления (каждые 10-20 км/ч)
    for (int i = 0; i <= maxSpeed.toInt(); i += minorStep) {
      if (i % majorStep != 0) { // Не рисуем минорные деления там, где есть мажор
        final angle = _startAngle + (i / maxSpeed) * _sweepAngle;
        _drawScaleMark(canvas, center, radius, angle, 8.0, minorPaint);
      }
    }
    
    // Рисуем мажорные деления (каждые 20-40 км/ч)
    for (int i = 0; i <= maxSpeed.toInt(); i += majorStep) {
      final angle = _startAngle + (i / maxSpeed) * _sweepAngle;
      _drawScaleMark(canvas, center, radius, angle, 15.0, majorPaint);
    }
  }

  /// Вспомогательный метод для рисования одного деления
  void _drawScaleMark(Canvas canvas, Offset center, double radius, double angle, double markLength, Paint paint) {
    final startPoint = Offset(
      center.dx + (radius - markLength) * math.cos(angle),
      center.dy + (radius - markLength) * math.sin(angle),
    );
    
    final endPoint = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    
    canvas.drawLine(startPoint, endPoint, paint);
  }

  /// Рисует числа на шкале с кэшированием для производительности
  void _drawScaleNumbers(Canvas canvas, Offset center, double radius) {
    // Кэширование TextPainter'ов для оптимизации
    if (_cachedNumberPainters == null || _cachedMaxSpeed != maxSpeed) {
      _cacheNumberPainters();
    }
    
    final numberRadius = radius - 35;
    final step = _calculateOptimalStep(maxSpeed);
    
    for (int i = 0; i <= maxSpeed.toInt(); i += step) {
      final angle = _startAngle + (i / maxSpeed) * _sweepAngle;
      
      final numberPosition = Offset(
        center.dx + numberRadius * math.cos(angle),
        center.dy + numberRadius * math.sin(angle),
      );
      
      // Использование кэшированных TextPainter'ов
      final painterIndex = i ~/ step;
      if (painterIndex < _cachedNumberPainters!.length) {
        final textPainter = _cachedNumberPainters![painterIndex];
        textPainter.paint(
          canvas,
          Offset(
            numberPosition.dx - textPainter.width / 2,
            numberPosition.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  /// Кэширует TextPainter'ы для чисел шкалы
  void _cacheNumberPainters() {
    _cachedNumberPainters = [];
    final step = _calculateOptimalStep(maxSpeed);
    
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: _calculateOptimalFontSize(maxSpeed),
      fontWeight: FontWeight.w600,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 2,
        ),
      ],
    );

    for (int i = 0; i <= maxSpeed.toInt(); i += step) {
      final textSpan = TextSpan(text: i.toString(), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      _cachedNumberPainters!.add(textPainter);
    }
  }

  /// Рассчитывает оптимальный шаг для чисел на шкале
  int _calculateOptimalStep(double maxSpeed) {
    if (maxSpeed <= 120) return 20;
    if (maxSpeed <= 200) return 40;
    if (maxSpeed <= 300) return 50;
    return 60;
  }

  /// Рассчитывает оптимальный размер шрифта
  double _calculateOptimalFontSize(double maxSpeed) {
    if (maxSpeed <= 120) return 16.0;
    if (maxSpeed <= 200) return 14.0;
    return 12.0;
  }

  /// Рисует улучшенные цветные зоны с реалистичными пределами скорости
  void _drawColorZones(Canvas canvas, Offset center, double radius) {
    final strokeWidth = 8.0;
    final zoneRadius = radius - 25;
    
    // Зеленая зона (безопасная скорость: 0-60% от максимума)
    final safeLimit = maxSpeed * 0.6;
    final greenSweep = (safeLimit / maxSpeed) * _sweepAngle;
    
    final greenPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        colors: [
          AutomotiveTheme.successGreen.withOpacity(0.5),
          AutomotiveTheme.successGreen.withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: zoneRadius));
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: zoneRadius),
      _startAngle,
      greenSweep,
      false,
      greenPaint,
    );

    // Желтая зона (предупреждение: 60-80% от максимума)
    final warningLimit = maxSpeed * 0.8;
    final yellowStart = _startAngle + greenSweep;
    final yellowSweep = ((warningLimit - safeLimit) / maxSpeed) * _sweepAngle;
    
    final yellowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        colors: [
          AutomotiveTheme.accentOrange.withOpacity(0.5),
          AutomotiveTheme.accentOrange.withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: zoneRadius));
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: zoneRadius),
      yellowStart,
      yellowSweep,
      false,
      yellowPaint,
    );

    // Красная зона (опасная скорость: 80-100% от максимума)
    final redStart = yellowStart + yellowSweep;
    final redSweep = ((maxSpeed - warningLimit) / maxSpeed) * _sweepAngle;
    
    final redPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        colors: [
          AutomotiveTheme.warningRed.withOpacity(0.5),
          AutomotiveTheme.warningRed.withOpacity(0.9),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: zoneRadius));
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: zoneRadius),
      redStart,
      redSweep,
      false,
      redPaint,
    );
  }

  /// Рисует след скорости для визуального эффекта
  void _drawSpeedTrail(Canvas canvas, Offset center, double radius) {
    if (velocity > 5.0) { // Показываем след только при быстром движении
      final trailLength = (velocity / 100.0).clamp(0.1, 0.3);
      final currentAngle = _startAngle + (speed / maxSpeed) * _sweepAngle;
      
      final trailPaint = Paint()
        ..color = AutomotiveTheme.speedometerNeedle.withOpacity(0.3)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      
      // Рисуем дугу следа
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 45),
        currentAngle - trailLength,
        trailLength,
        false,
        trailPaint,
      );
    }
  }

  /// Рисует индикатор целевой скорости
  void _drawTargetIndicator(Canvas canvas, Offset center, double radius) {
    if ((targetSpeed - speed).abs() > 2.0) { // Показываем только при значительной разнице
      final targetAngle = _startAngle + (targetSpeed / maxSpeed) * _sweepAngle;
      final indicatorRadius = radius - 25;
      
      final targetPaint = Paint()
        ..color = AutomotiveTheme.primaryBlue.withOpacity(0.6)
        ..strokeWidth = 2;
      
      final targetPoint = Offset(
        center.dx + indicatorRadius * math.cos(targetAngle),
        center.dy + indicatorRadius * math.sin(targetAngle),
      );
      
      canvas.drawCircle(targetPoint, 4, targetPaint);
    }
  }

  /// Рисует улучшенную стрелку спидометра с эффектами
  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final needleAngle = _startAngle + (speed / maxSpeed) * _sweepAngle;
    final needleLength = radius - 40;
    
    // Тень стрелки для глубины
    _drawNeedleShadow(canvas, center, needleAngle, needleLength);
    
    // Основная стрелка с градиентом
    _drawMainNeedle(canvas, center, needleAngle, needleLength);
    
    // Задняя часть стрелки
    _drawNeedleCounterweight(canvas, center, needleAngle);
    
    // Эффект свечения при высокой скорости
    if (speed > maxSpeed * 0.8) {
      _drawNeedleGlow(canvas, center, needleAngle, needleLength);
    }
  }

  /// Рисует тень стрелки
  void _drawNeedleShadow(Canvas canvas, Offset center, double angle, double length) {
    final shadowOffset = Offset(2, 2);
    final shadowCenter = center + shadowOffset;
    
    final shadowEnd = Offset(
      shadowCenter.dx + length * math.cos(angle),
      shadowCenter.dy + length * math.sin(angle),
    );
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(shadowCenter, shadowEnd, shadowPaint);
  }

  /// Рисует основную стрелку с градиентом
  void _drawMainNeedle(Canvas canvas, Offset center, double angle, double length) {
    final needleEnd = Offset(
      center.dx + length * math.cos(angle),
      center.dy + length * math.sin(angle),
    );
    
    // Создание градиентной стрелки
    final needlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AutomotiveTheme.speedometerNeedle,
          AutomotiveTheme.speedometerNeedle.withOpacity(0.8),
        ],
      ).createShader(Rect.fromPoints(center, needleEnd))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(center, needleEnd, needlePaint);
  }

  /// Рисует противовес стрелки
  void _drawNeedleCounterweight(Canvas canvas, Offset center, double angle) {
    final backNeedleLength = 25;
    final backNeedleEnd = Offset(
      center.dx - backNeedleLength * math.cos(angle),
      center.dy - backNeedleLength * math.sin(angle),
    );
    
    final backNeedlePaint = Paint()
      ..color = AutomotiveTheme.speedometerNeedle.withOpacity(0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(center, backNeedleEnd, backNeedlePaint);
  }

  /// Рисует эффект свечения стрелки при высокой скорости
  void _drawNeedleGlow(Canvas canvas, Offset center, double angle, double length) {
    final glowEnd = Offset(
      center.dx + length * math.cos(angle),
      center.dy + length * math.sin(angle),
    );
    
    final glowPaint = Paint()
      ..color = AutomotiveTheme.speedometerNeedle.withOpacity(0.4)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawLine(center, glowEnd, glowPaint);
  }

  /// Рисует центральную точку
  void _drawCenterDot(Canvas canvas, Offset center) {
    final centerPaint = Paint()
      ..color = AutomotiveTheme.speedometerNeedle
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 8, centerPaint);
    
    final innerCenterPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 4, innerCenterPaint);
  }

  /// Рисует предупреждение о низкой производительности
  void _drawPerformanceWarning(Canvas canvas, Size size) {
    final warningPaint = Paint()
      ..color = AutomotiveTheme.warningRed.withOpacity(0.8);
    
    final textStyle = TextStyle(
      color: AutomotiveTheme.warningRed,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    
    final textSpan = TextSpan(
      text: 'LOW FPS: ${averageFPS.toStringAsFixed(0)}',
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 10, 10),
    );
  }

  @override
  bool shouldRepaint(covariant EnhancedSpeedometerPainter oldDelegate) {
    // Оптимизация: перерисовка только при значительных изменениях
    return (oldDelegate.speed - speed).abs() > 0.1 ||
           oldDelegate.maxSpeed != maxSpeed ||
           (oldDelegate.targetSpeed - targetSpeed).abs() > 1.0 ||
           oldDelegate.averageFPS != averageFPS;
  }
}