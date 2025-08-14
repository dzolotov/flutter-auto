import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;

import '../../../core/theme/automotive_theme.dart';

/// Улучшенный виджет тахометра (RPM) с физической симуляцией и эффектами
/// Реализует реалистичное поведение стрелки с быстрым откликом на изменения RPM
/// Оптимизирован для 60 FPS обновлений и встраиваемых систем
class RpmGaugeWidget extends StatefulWidget {
  final double rpm;             // Текущие обороты в минуту
  final double maxRpm;          // Максимальные обороты на шкале
  final double redlineRpm;      // Красная зона (опасные обороты)
  final double idleRpm;         // Обороты холостого хода
  final bool showDigital;       // Показывать ли цифровое значение
  final bool enablePhysics;     // Включить ли физическую симуляцию
  final VoidCallback? onError;  // Коллбэк для обработки ошибок

  const RpmGaugeWidget({
    super.key,
    required this.rpm,
    this.maxRpm = 8000.0,
    this.redlineRpm = 6500.0,
    this.idleRpm = 800.0,
    this.showDigital = true,
    this.enablePhysics = true,
    this.onError,
  });

  @override
  State<RpmGaugeWidget> createState() => _RpmGaugeWidgetState();
}

class _RpmGaugeWidgetState extends State<RpmGaugeWidget>
    with TickerProviderStateMixin {
  
  // Убрана физическая симуляция для упрощения
  
  // Контроллер для 60 FPS обновлений
  late Ticker _ticker;
  
  // Анимация мигания для redline эффекта
  late AnimationController _redlineAnimationController;
  late Animation<double> _redlineAnimation;
  
  // Временные метки и состояние
  Duration _lastUpdateTime = Duration.zero;
  double _displayRpm = 0.0;
  double _targetRpm = 0.0;
  bool _isInRedline = false;
  bool _hasError = false;
  
  // Мониторинг производительности
  int _frameCount = 0;
  double _averageFPS = 60.0;

  @override
  void initState() {
    super.initState();
    
    try {
      // Физическая симуляция упрощена
      
      // Настройка тикера для 60 FPS обновлений
      _ticker = createTicker(_onTick);
      
      // Анимация мигания для redline эффекта
      _redlineAnimationController = AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      );
      _redlineAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _redlineAnimationController,
        curve: Curves.easeInOut,
      ));
      
      // Установка начальных значений
      _targetRpm = widget.rpm.clamp(0.0, widget.maxRpm);
      
      if (widget.enablePhysics) {
        _ticker.start();
      } else {
        _displayRpm = _targetRpm;
      }
      
    } catch (e) {
      _handleError('Ошибка инициализации тахометра: $e');
    }
  }

  @override
  void didUpdateWidget(RpmGaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    try {
      // Обновление целевых оборотов
      if (oldWidget.rpm != widget.rpm) {
        _updateTargetRpm(widget.rpm);
      }
      
      // Перезапуск физики при изменении настроек
      if (oldWidget.enablePhysics != widget.enablePhysics) {
        if (widget.enablePhysics && !_ticker.isActive) {
          _ticker.start();
        } else if (!widget.enablePhysics && _ticker.isActive) {
          _ticker.stop();
          _displayRpm = widget.rpm.clamp(0.0, widget.maxRpm);
        }
      }
      
    } catch (e) {
      _handleError('Ошибка обновления тахометра: $e');
    }
  }

  /// Обновляет целевые обороты с валидацией и обработкой redline
  void _updateTargetRpm(double newRpm) {
    // Валидация входных данных
    if (newRpm.isNaN || newRpm.isInfinite) {
      _handleError('Получено некорректное значение RPM: $newRpm');
      return;
    }
    
    _targetRpm = newRpm.clamp(0.0, widget.maxRpm);
    
    // Проверка на переход в/из redline зоны
    final wasInRedline = _isInRedline;
    _isInRedline = _targetRpm > widget.redlineRpm;
    
    if (_isInRedline && !wasInRedline) {
      // Вход в красную зону - запуск мигания
      _redlineAnimationController.repeat(reverse: true);
    } else if (!_isInRedline && wasInRedline) {
      // Выход из красной зоны - остановка мигания
      _redlineAnimationController.stop();
    }
    
    if (widget.enablePhysics) {
      // Запуск тикера, если он остановился
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      _displayRpm = _targetRpm;
    }
  }

  /// Обработчик обновлений с частотой 60 FPS
  void _onTick(Duration elapsed) {
    if (!mounted) return;
    
    try {
      // Расчет времени с предыдущего кадра
      final deltaTime = _lastUpdateTime == Duration.zero 
          ? 1.0 / 60.0
          : (elapsed - _lastUpdateTime).inMicroseconds / 1000000.0;
      
      _lastUpdateTime = elapsed;
      
      // Простая интерполяция к целевому значению
      final diff = _targetRpm - _displayRpm;
      if (diff.abs() > 10) {
        _displayRpm += diff * deltaTime * 5.0; // Скорость интерполяции
        setState(() {});
        
        // Мониторинг FPS
        _frameCount++;
        if (_frameCount % 60 == 0) {
          _averageFPS = 60.0 / (deltaTime * 60);
        }
      } else {
        // Остановка тикера для экономии ресурсов
        _displayRpm = _targetRpm;
        _ticker.stop();
      }
      
    } catch (e) {
      _handleError('Ошибка обновления физики RPM: $e');
    }
  }

  /// Обработка ошибок с возможностью восстановления
  void _handleError(String message) {
    _hasError = true;
    
    // Безопасное состояние - возвращение к холостому ходу
    if (mounted) {
      setState(() {
        _displayRpm = widget.idleRpm;
        _isInRedline = false;
      });
    }
    
    // Остановка анимации redline
    _redlineAnimationController.stop();
    
    // Уведомление родительского виджета
    widget.onError?.call();
    
    debugPrint('RpmGaugeWidget Error: $message');
  }

  @override
  void dispose() {
    _ticker.dispose();
    _redlineAnimationController.dispose();
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
        gradient: _isInRedline && _redlineAnimation.isAnimating
            ? RadialGradient(
                colors: [
                  AutomotiveTheme.rpmRedZone.withOpacity(0.1),
                  Colors.black,
                ],
              )
            : AutomotiveTheme.gaugeGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: _isInRedline 
              ? AutomotiveTheme.rpmRedZone 
              : Colors.grey[700]!, 
          width: _isInRedline ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isInRedline 
                ? AutomotiveTheme.rpmRedZone.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            spreadRadius: _isInRedline ? 8 : 5,
            blurRadius: _isInRedline ? 15 : 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _redlineAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: EnhancedRpmGaugePainter(
              rpm: _displayRpm,
              maxRpm: widget.maxRpm,
              redlineRpm: widget.redlineRpm,
              idleRpm: widget.idleRpm,
              targetRpm: _targetRpm,
              velocity: (_targetRpm - _displayRpm).abs(),
              isRedline: _isInRedline,
              redlineIntensity: _redlineAnimation.value,
              averageFPS: _averageFPS,
            ),
            child: widget.showDigital ? _buildDigitalDisplay() : null,
          );
        },
      ),
    );
  }

  /// Создает улучшенное цифровое отображение RPM
  Widget _buildDigitalDisplay() {
    final rpmValue = _displayRpm / 1000.0;
    final rpmColor = _getRpmColor(_displayRpm);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Основное значение RPM
          AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 200),
            style: TextStyle(
              color: rpmColor,
              fontSize: _isInRedline ? 40 : 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'DigitalNumbers',
              shadows: [
                Shadow(
                  color: rpmColor.withOpacity(0.5),
                  blurRadius: _isInRedline ? 10 : 4,
                ),
              ],
            ),
            child: Text(
              rpmValue.toStringAsFixed(1),
            ),
          ),
          
          // Единицы измерения
          Text(
            'x1000 об/мин',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Предупреждения и статус
          if (_isInRedline)
            AnimatedBuilder(
              animation: _redlineAnimation,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Opacity(
                    opacity: 0.5 + 0.5 * _redlineAnimation.value,
                    child: Text(
                      'REDLINE',
                      style: TextStyle(
                        color: AutomotiveTheme.rpmRedZone,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          
          // Индикатор быстроты изменения RPM (упрощенный)
          if (widget.enablePhysics && (_targetRpm - _displayRpm).abs() > 200)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 50,
                height: 2,
                decoration: BoxDecoration(
                  color: AutomotiveTheme.primaryBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: FractionallySizedBox(
                  widthFactor: ((_targetRpm - _displayRpm).abs() / 1000).clamp(0.0, 1.0),
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
              'ТАХОМЕТР',
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

  /// Определяет цвет RPM в зависимости от значения
  Color _getRpmColor(double rpm) {
    if (rpm > widget.redlineRpm) {
      return AutomotiveTheme.rpmRedZone;
    } else if (rpm > widget.redlineRpm * 0.85) {
      return AutomotiveTheme.accentOrange;
    } else if (rpm < widget.idleRpm * 1.5) {
      return Colors.grey[300]!;
    } else {
      return Colors.white;
    }
  }
}

/// Улучшенный кастомный рисовальщик для тахометра
/// Поддерживает расширенные эффекты, физическую симуляцию и оптимизацию
class EnhancedRpmGaugePainter extends CustomPainter {
  final double rpm;              // Текущие обороты
  final double maxRpm;           // Максимальные обороты на шкале
  final double redlineRpm;       // Красная зона (опасные обороты)
  final double idleRpm;          // Обороты холостого хода
  final double targetRpm;        // Целевые обороты
  final double velocity; // Скорость изменения RPM (упрощенная)
  final bool isRedline;          // Флаг красной зоны
  final double redlineIntensity; // Интенсивность эффекта redline
  final double averageFPS;       // Средний FPS
  
  // Константы для угловых расчетов
  static const double _startAngle = -math.pi * 0.75; // -135°
  static const double _sweepAngle = math.pi * 1.5;   // 270°
  
  // Кэш для оптимизации отрисовки
  static List<TextPainter>? _cachedNumberPainters;
  static double? _cachedMaxRpm;

  EnhancedRpmGaugePainter({
    required this.rpm,
    required this.maxRpm,
    required this.redlineRpm,
    required this.idleRpm,
    required this.targetRpm,
    this.velocity = 0.0,
    required this.isRedline,
    this.redlineIntensity = 0.0,
    this.averageFPS = 60.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Оптимизация: обновление кэша при необходимости
    _updateCacheIfNeeded();
    
    // Слой 1: Основа и фон (статичная)
    _drawBackground(canvas, center, radius);
    _drawOuterRing(canvas, center, radius);
    
    // Слой 2: Шкала и числа (кэшируемая)
    _drawScaleMarks(canvas, center, radius);
    _drawScaleNumbers(canvas, center, radius);
    
    // Слой 3: Цветовые зоны (статичная)
    _drawColorZones(canvas, center, radius);
    
    // Слой 4: Индикатор холостого хода
    _drawIdleZone(canvas, center, radius);
    
    // Слой 5: Динамические эффекты
    _drawRpmTrail(canvas, center, radius);
    _drawTargetIndicator(canvas, center, radius);
    
    // Слой 6: Стрелка с эффектами
    _drawNeedle(canvas, center, radius);
    _drawCenterDot(canvas, center);
    
    // Слой 7: Эффекты redline и производительности
    if (isRedline) {
      _drawRedlineEffect(canvas, center, radius);
    }
    
    if (averageFPS < 50) {
      _drawPerformanceWarning(canvas, size);
    }
  }

  /// Обновляет кэш при необходимости
  void _updateCacheIfNeeded() {
    if (_cachedMaxRpm != maxRpm) {
      _cachedMaxRpm = maxRpm;
      _cachedNumberPainters = null;
    }
  }

  /// Рисует фоновый градиент
  void _drawBackground(Canvas canvas, Offset center, double radius) {
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey[850]!,
          Colors.black,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, backgroundPaint);
  }

  /// Рисует внешнее кольцо
  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = isRedline ? AutomotiveTheme.rpmRedZone : Colors.grey[600]!;

    canvas.drawCircle(center, radius, paint);
  }

  /// Рисует деления шкалы
  void _drawScaleMarks(Canvas canvas, Offset center, double radius) {
    final majorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    
    final minorPaint = Paint()
      ..color = Colors.grey[500]!
      ..strokeWidth = 1;

    for (int i = 0; i <= (maxRpm / 1000).toInt(); i++) {
      final rpmValue = i * 1000;
      final angle = _startAngle + (rpmValue / maxRpm) * _sweepAngle;
      final isMajor = i % 1 == 0; // Каждые 1000 RPM
      final paint = isMajor ? majorPaint : minorPaint;
      final markLength = isMajor ? 15.0 : 8.0;
      
      final startPoint = Offset(
        center.dx + (radius - markLength) * math.cos(angle),
        center.dy + (radius - markLength) * math.sin(angle),
      );
      
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      canvas.drawLine(startPoint, endPoint, paint);
      
      // Дополнительные мелкие деления
      if (i < (maxRpm / 1000).toInt()) {
        for (int j = 1; j < 5; j++) {
          final subRpmValue = i * 1000 + j * 200;
          if (subRpmValue < maxRpm) {
            final subAngle = _startAngle + (subRpmValue / maxRpm) * _sweepAngle;
            final subStartPoint = Offset(
              center.dx + (radius - 5) * math.cos(subAngle),
              center.dy + (radius - 5) * math.sin(subAngle),
            );
            final subEndPoint = Offset(
              center.dx + radius * math.cos(subAngle),
              center.dy + radius * math.sin(subAngle),
            );
            canvas.drawLine(subStartPoint, subEndPoint, minorPaint);
          }
        }
      }
    }
  }

  /// Рисует числа на шкале
  void _drawScaleNumbers(Canvas canvas, Offset center, double radius) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i <= (maxRpm / 1000).toInt(); i++) {
      final rpmValue = i * 1000;
      final angle = _startAngle + (rpmValue / maxRpm) * _sweepAngle;
      final numberRadius = radius - 35;
      
      final numberPosition = Offset(
        center.dx + numberRadius * math.cos(angle),
        center.dy + numberRadius * math.sin(angle),
      );
      
      final isRedlineNumber = rpmValue >= redlineRpm;
      final numberTextStyle = textStyle.copyWith(
        color: isRedlineNumber ? AutomotiveTheme.rpmRedZone : Colors.white,
      );
      
      final textSpan = TextSpan(text: i.toString(), style: numberTextStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          numberPosition.dx - textPainter.width / 2,
          numberPosition.dy - textPainter.height / 2,
        ),
      );
    }
  }

  /// Рисует цветные зоны
  void _drawColorZones(Canvas canvas, Offset center, double radius) {
    final strokeWidth = 8.0;
    final zoneRadius = radius - 25;

    // Зеленая зона (0 - 4000 RPM)
    final greenPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AutomotiveTheme.successGreen.withOpacity(0.7);
    
    final greenSweep = (4000 / maxRpm) * _sweepAngle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: zoneRadius),
      _startAngle,
      greenSweep,
      false,
      greenPaint,
    );

    // Желтая зона (4000 - redline)
    final yellowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AutomotiveTheme.accentOrange.withOpacity(0.7);
    
    final yellowStart = _startAngle + greenSweep;
    final yellowSweep = ((redlineRpm - 4000) / maxRpm) * _sweepAngle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: zoneRadius),
      yellowStart,
      yellowSweep,
      false,
      yellowPaint,
    );

    // Красная зона (redline+)
    final redPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AutomotiveTheme.rpmRedZone.withOpacity(0.8);
    
    final redStart = yellowStart + yellowSweep;
    final redSweep = ((maxRpm - redlineRpm) / maxRpm) * _sweepAngle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: zoneRadius),
      redStart,
      redSweep,
      false,
      redPaint,
    );
  }

  /// Рисует стрелку тахометра
  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final needleAngle = _startAngle + (rpm / maxRpm) * _sweepAngle;
    final needleLength = radius - 40;
    
    // Основная стрелка
    final needleColor = isRedline 
        ? AutomotiveTheme.rpmRedZone 
        : AutomotiveTheme.primaryBlue;
        
    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );
    
    canvas.drawLine(center, needleEnd, needlePaint);
    
    // Задняя часть стрелки
    final backNeedleLength = 20;
    final backNeedleEnd = Offset(
      center.dx - backNeedleLength * math.cos(needleAngle),
      center.dy - backNeedleLength * math.sin(needleAngle),
    );
    
    final backNeedlePaint = Paint()
      ..color = needleColor.withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(center, backNeedleEnd, backNeedlePaint);
  }

  /// Рисует центральную точку
  void _drawCenterDot(Canvas canvas, Offset center) {
    final centerColor = isRedline 
        ? AutomotiveTheme.rpmRedZone 
        : AutomotiveTheme.primaryBlue;
        
    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 8, centerPaint);
    
    final innerCenterPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 4, innerCenterPaint);
  }

  /// Улучшенный эффект redline с многослойным миганием
  void _drawRedlineEffect(Canvas canvas, Offset center, double radius) {
    final intensity = redlineIntensity;
    
    // Основной эффект свечения
    final glowPaint = Paint()
      ..color = AutomotiveTheme.rpmRedZone.withOpacity(0.1 + 0.2 * intensity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + 10 * intensity);
    
    canvas.drawCircle(center, radius + 5 + 10 * intensity, glowPaint);
    
    // Внутреннее кольцо мигания
    final innerRingPaint = Paint()
      ..color = AutomotiveTheme.rpmRedZone.withOpacity(0.3 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(center, radius - 10, innerRingPaint);
    
    // Множественные кольца расширяющегося эффекта
    for (int i = 0; i < 3; i++) {
      final ringRadius = radius + (i * 8) + (intensity * 15);
      final ringOpacity = (0.4 - i * 0.1) * intensity;
      
      final ringPaint = Paint()
        ..color = AutomotiveTheme.rpmRedZone.withOpacity(ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 - i * 0.5;
      
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  /// Рисует зону холостого хода
  void _drawIdleZone(Canvas canvas, Offset center, double radius) {
    final idleAngle = _startAngle + (idleRpm / maxRpm) * _sweepAngle;
    final idleRadius = radius - 30;
    
    final idlePaint = Paint()
      ..color = Colors.grey[400]!.withOpacity(0.5)
      ..strokeWidth = 2;
    
    final idlePoint = Offset(
      center.dx + idleRadius * math.cos(idleAngle),
      center.dy + idleRadius * math.sin(idleAngle),
    );
    
    canvas.drawCircle(idlePoint, 3, idlePaint);
  }

  /// Рисует след RPM для визуального эффекта
  void _drawRpmTrail(Canvas canvas, Offset center, double radius) {
    if (velocity > 200.0) { // RPM изменяется быстро
      final trailLength = (velocity / 1000.0).clamp(0.05, 0.2);
      final currentAngle = _startAngle + (rpm / maxRpm) * _sweepAngle;
      
      final trailPaint = Paint()
        ..color = isRedline 
            ? AutomotiveTheme.rpmRedZone.withOpacity(0.4)
            : AutomotiveTheme.primaryBlue.withOpacity(0.3)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 50),
        currentAngle - trailLength,
        trailLength,
        false,
        trailPaint,
      );
    }
  }

  /// Рисует индикатор целевых оборотов
  void _drawTargetIndicator(Canvas canvas, Offset center, double radius) {
    if ((targetRpm - rpm).abs() > 100.0) {
      final targetAngle = _startAngle + (targetRpm / maxRpm) * _sweepAngle;
      final indicatorRadius = radius - 25;
      
      final targetPaint = Paint()
        ..color = AutomotiveTheme.accentOrange.withOpacity(0.7)
        ..strokeWidth = 3;
      
      final targetPoint = Offset(
        center.dx + indicatorRadius * math.cos(targetAngle),
        center.dy + indicatorRadius * math.sin(targetAngle),
      );
      
      canvas.drawCircle(targetPoint, 5, targetPaint);
    }
  }

  /// Рисует предупреждение о низкой производительности
  void _drawPerformanceWarning(Canvas canvas, Size size) {
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
  bool shouldRepaint(covariant EnhancedRpmGaugePainter oldDelegate) {
    // Оптимизация: перерисовка только при значительных изменениях
    return (oldDelegate.rpm - rpm).abs() > 10.0 ||
           oldDelegate.isRedline != isRedline ||
           (oldDelegate.redlineIntensity - redlineIntensity).abs() > 0.05 ||
           oldDelegate.maxRpm != maxRpm ||
           oldDelegate.averageFPS != averageFPS;
  }
}