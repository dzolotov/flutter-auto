import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/automotive_theme.dart';

/// Виджет указателя уровня топлива
/// Показывает остаток топлива с предупреждениями о низком уровне
class FuelGaugeWidget extends StatefulWidget {
  final double fuelLevel; // Процент (0-100)
  final double lowFuelWarning;
  final double criticalFuelLevel;

  const FuelGaugeWidget({
    super.key,
    required this.fuelLevel,
    this.lowFuelWarning = 25.0,
    this.criticalFuelLevel = 10.0,
  });

  @override
  State<FuelGaugeWidget> createState() => _FuelGaugeWidgetState();
}

class _FuelGaugeWidgetState extends State<FuelGaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _levelAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _levelAnimation = Tween<double>(
      begin: 0.0,
      end: widget.fuelLevel,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(FuelGaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fuelLevel != widget.fuelLevel) {
      _updateLevel();
    }
  }

  void _updateLevel() {
    _levelAnimation = Tween<double>(
      begin: _levelAnimation.value,
      end: widget.fuelLevel,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Заголовок и значение
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ТОПЛИВО',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _levelAnimation,
                    builder: (context, child) {
                      final color = _getFuelLevelColor(_levelAnimation.value);
                      return Text(
                        '${_levelAnimation.value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DigitalNumbers',
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              // Иконка топливного бака
              AnimatedBuilder(
                animation: _levelAnimation,
                builder: (context, child) {
                  final color = _getFuelLevelColor(_levelAnimation.value);
                  final isLow = _levelAnimation.value <= widget.lowFuelWarning;
                  
                  return Column(
                    children: [
                      Icon(
                        Icons.local_gas_station,
                        color: color,
                        size: 24,
                      ),
                      if (isLow)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'НИЗКИЙ',
                            style: TextStyle(
                              color: color,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Горизонтальный индикатор уровня
          Expanded(
            child: AnimatedBuilder(
              animation: _levelAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: FuelGaugePainter(
                    fuelLevel: _levelAnimation.value,
                    lowFuelWarning: widget.lowFuelWarning,
                    criticalFuelLevel: widget.criticalFuelLevel,
                  ),
                  size: Size(double.infinity, 30),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Определяет цвет в зависимости от уровня топлива
  Color _getFuelLevelColor(double level) {
    if (level <= widget.criticalFuelLevel) {
      return AutomotiveTheme.warningRed;
    } else if (level <= widget.lowFuelWarning) {
      return AutomotiveTheme.fuelLow;
    } else {
      return AutomotiveTheme.successGreen;
    }
  }
}

/// Кастомный рисовальщик для указателя топлива
class FuelGaugePainter extends CustomPainter {
  final double fuelLevel;
  final double lowFuelWarning;
  final double criticalFuelLevel;

  FuelGaugePainter({
    required this.fuelLevel,
    required this.lowFuelWarning,
    required this.criticalFuelLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final borderRadius = Radius.circular(15);
    final rrect = RRect.fromRectAndRadius(rect, borderRadius);

    // Рисуем фон индикатора
    _drawBackground(canvas, rrect);
    
    // Рисуем зоны (критическая, предупреждение, нормальная)
    _drawZones(canvas, size, rrect);
    
    // Рисуем текущий уровень
    _drawCurrentLevel(canvas, size, rrect);
    
    // Рисуем деления
    _drawScaleMarks(canvas, size);
    
    // Рисуем рамку
    _drawBorder(canvas, rrect);
  }

  /// Рисует фон индикатора
  void _drawBackground(Canvas canvas, RRect rrect) {
    final backgroundPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(rrect, backgroundPaint);
  }

  /// Рисует цветовые зоны
  void _drawZones(Canvas canvas, Size size, RRect rrect) {
    // Критическая зона (0-10%)
    final criticalWidth = (criticalFuelLevel / 100.0) * size.width;
    if (criticalWidth > 0) {
      final criticalRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, criticalWidth, size.height),
        Radius.circular(15),
      );
      final criticalPaint = Paint()
        ..color = AutomotiveTheme.warningRed.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(criticalRect, criticalPaint);
    }

    // Зона предупреждения (10-25%)
    final warningStart = criticalWidth;
    final warningWidth = ((lowFuelWarning - criticalFuelLevel) / 100.0) * size.width;
    if (warningWidth > 0) {
      final warningRect = Rect.fromLTWH(warningStart, 0, warningWidth, size.height);
      final warningPaint = Paint()
        ..color = AutomotiveTheme.fuelLow.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(warningRect, warningPaint);
    }

    // Нормальная зона (25-100%)
    final normalStart = warningStart + warningWidth;
    final normalWidth = size.width - normalStart;
    if (normalWidth > 0) {
      final normalRect = Rect.fromLTWH(normalStart, 0, normalWidth, size.height);
      final normalPaint = Paint()
        ..color = AutomotiveTheme.successGreen.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(normalRect, normalPaint);
    }
  }

  /// Рисует текущий уровень топлива
  void _drawCurrentLevel(Canvas canvas, Size size, RRect rrect) {
    final levelWidth = (fuelLevel / 100.0) * size.width;
    if (levelWidth <= 0) return;

    final levelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, levelWidth, size.height),
      Radius.circular(15),
    );

    // Определяем цвет в зависимости от уровня
    Color levelColor;
    if (fuelLevel <= criticalFuelLevel) {
      levelColor = AutomotiveTheme.warningRed;
    } else if (fuelLevel <= lowFuelWarning) {
      levelColor = AutomotiveTheme.fuelLow;
    } else {
      levelColor = AutomotiveTheme.successGreen;
    }

    // Градиент для уровня топлива
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        levelColor,
        levelColor.withOpacity(0.8),
      ],
    );

    final levelPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, levelWidth, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawRRect(levelRect, levelPaint);

    // Анимационный эффект волны для низкого уровня
    if (fuelLevel <= lowFuelWarning) {
      _drawWaveEffect(canvas, size, levelWidth, levelColor);
    }
  }

  /// Рисует эффект волны для низкого уровня топлива
  void _drawWaveEffect(Canvas canvas, Size size, double levelWidth, Color color) {
    final wavePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final waveHeight = size.height * 0.3;
    final path = Path();
    
    path.moveTo(0, size.height - waveHeight);
    
    for (double x = 0; x <= levelWidth; x += 10) {
      final y = size.height - waveHeight + 
                math.sin((x / levelWidth) * 2 * math.pi) * 3;
      path.lineTo(x, y);
    }
    
    path.lineTo(levelWidth, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  /// Рисует деления на шкале
  void _drawScaleMarks(Canvas canvas, Size size) {
    final markPaint = Paint()
      ..color = Colors.grey[500]!
      ..strokeWidth = 1;

    // Деления через каждые 25%
    for (int i = 0; i <= 4; i++) {
      final x = (i * 25 / 100.0) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        markPaint,
      );
    }
  }

  /// Рисует рамку индикатора
  void _drawBorder(Canvas canvas, RRect rrect) {
    final borderPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant FuelGaugePainter oldDelegate) {
    return oldDelegate.fuelLevel != fuelLevel;
  }
}