import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;

import '../../../core/theme/automotive_theme.dart';
import '../../../services/physics_simulation.dart';

/// Улучшенный виджет индикатора передач с анимациями и автомобильной логикой
/// Поддерживает автоматические и механические трансмиссии с реалистичной анимацией переключений
/// Оптимизирован для автомобильных дисплеев с высокой читаемостью и быстрым откликом
class GearIndicatorWidget extends StatefulWidget {
  final String currentGear;          // Текущая передача (P, R, N, D, 1, 2, 3, 4, 5, 6)
  final String transmissionType;     // Тип трансмиссии (auto, manual, cvt, dual_clutch)
  final double rpm;                  // Текущие обороты двигателя
  final double speed;                // Текущая скорость
  final bool isShifting;             // Флаг процесса переключения
  final bool showRecommendations;    // Показывать рекомендации по переключению
  final VoidCallback? onError;       // Обработчик ошибок

  const GearIndicatorWidget({
    super.key,
    required this.currentGear,
    this.transmissionType = 'auto',
    this.rpm = 0.0,
    this.speed = 0.0,
    this.isShifting = false,
    this.showRecommendations = true,
    this.onError,
  });

  @override
  State<GearIndicatorWidget> createState() => _GearIndicatorWidgetState();
}

class _GearIndicatorWidgetState extends State<GearIndicatorWidget>
    with TickerProviderStateMixin {
  
  // Анимация переключения передач
  late AnimationController _gearShiftController;
  late Animation<double> _gearShiftAnimation;
  late Animation<Color?> _gearColorAnimation;
  
  // Анимация рекомендаций переключения
  late AnimationController _recommendationController;
  late Animation<double> _recommendationAnimation;
  
  // Анимация индикатора состояния трансмиссии
  late AnimationController _statusAnimationController;
  late Animation<double> _statusAnimation;
  
  // Физическая симуляция для плавности движения индикатора
  late LinearGaugePhysics _physics;
  late Ticker _physicsTicker;
  
  // Состояние виджета
  String _displayGear = 'P';
  String _previousGear = 'P';
  bool _hasError = false;
  
  // Рекомендации по переключению для МКПП
  GearRecommendation _currentRecommendation = GearRecommendation.none;
  
  // Временные метки для анимаций
  Duration _lastUpdateTime = Duration.zero;
  
  // Константы для логики переключений
  static const Map<String, int> _gearOrder = {
    'P': 0, 'R': -1, 'N': 0, 'D': 1, '1': 1, '2': 2, 
    '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8
  };

  @override
  void initState() {
    super.initState();
    
    try {
      _initializeAnimations();
      _initializePhysics();
      _displayGear = widget.currentGear;
      _previousGear = widget.currentGear;
      
    } catch (e) {
      _handleError('Ошибка инициализации индикатора передач: $e');
    }
  }

  /// Инициализация всех анимационных контроллеров
  void _initializeAnimations() {
    // Анимация переключения передач
    _gearShiftController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _gearShiftAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gearShiftController,
      curve: Curves.elasticOut,
    ));
    
    _gearColorAnimation = ColorTween(
      begin: Colors.white,
      end: AutomotiveTheme.primaryBlue,
    ).animate(CurvedAnimation(
      parent: _gearShiftController,
      curve: Curves.easeInOut,
    ));
    
    // Анимация рекомендаций
    _recommendationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _recommendationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _recommendationController,
      curve: Curves.easeInOut,
    ));
    
    // Анимация состояния
    _statusAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _statusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusAnimationController,
      curve: Curves.easeOutQuart,
    ));
  }

  /// Инициализация физической симуляции
  void _initializePhysics() {
    _physics = LinearGaugePhysics(
      initialPosition: _getGearNumericValue(_displayGear),
    );
    
    _physicsTicker = createTicker(_onPhysicsTick);
    _physicsTicker.start();
  }

  /// Обработчик тика физической симуляции
  void _onPhysicsTick(Duration elapsed) {
    if (!mounted) return;
    
    try {
      final deltaTime = _lastUpdateTime == Duration.zero 
          ? 1.0 / 60.0
          : (elapsed - _lastUpdateTime).inMicroseconds / 1000000.0;
      
      _lastUpdateTime = elapsed;
      
      // Обновление физики только если есть изменения
      if (_physics.update(deltaTime.clamp(1/120, 1/30))) {
        if (mounted) {
          setState(() {});
        }
      } else if (_physics.isAtRest) {
        // Остановка тикера для экономии ресурсов
        _physicsTicker.stop();
      }
      
    } catch (e) {
      _handleError('Ошибка обновления физики: $e');
    }
  }

  @override
  void didUpdateWidget(GearIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    try {
      // Обработка изменения передачи
      if (oldWidget.currentGear != widget.currentGear) {
        _onGearChanged(widget.currentGear);
      }
      
      // Обработка состояния переключения
      if (oldWidget.isShifting != widget.isShifting) {
        _onShiftingStateChanged(widget.isShifting);
      }
      
      // Обновление рекомендаций для МКПП
      if (widget.transmissionType == 'manual' && widget.showRecommendations) {
        _updateGearRecommendations();
      }
      
    } catch (e) {
      _handleError('Ошибка обновления виджета: $e');
    }
  }

  /// Обработка изменения передачи
  void _onGearChanged(String newGear) {
    if (_displayGear == newGear) return;
    
    _previousGear = _displayGear;
    _displayGear = newGear;
    
    // Запуск анимации переключения
    _gearShiftController.forward(from: 0.0);
    
    // Обновление физической симуляции
    final targetValue = _getGearNumericValue(newGear);
    _physics.setTarget(targetValue);
    
    if (!_physicsTicker.isActive) {
      _physicsTicker.start();
    }
    
    // Анимация статуса
    _statusAnimationController.forward(from: 0.0);
  }

  /// Обработка изменения состояния переключения
  void _onShiftingStateChanged(bool isShifting) {
    if (isShifting) {
      // Начало переключения - показать индикацию процесса
      _statusAnimationController.repeat(reverse: true);
    } else {
      // Конец переключения - остановить анимацию
      _statusAnimationController.forward();
    }
  }

  /// Обновление рекомендаций по переключению передач для МКПП
  void _updateGearRecommendations() {
    final currentGearNum = _getGearNumericValue(_displayGear);
    final recommendation = _calculateGearRecommendation(
      currentGearNum.round(), widget.rpm, widget.speed);
    
    if (_currentRecommendation != recommendation) {
      _currentRecommendation = recommendation;
      
      if (_currentRecommendation != GearRecommendation.none) {
        _recommendationController.repeat(reverse: true);
      } else {
        _recommendationController.stop();
      }
    }
  }

  /// Расчет рекомендации по переключению передач
  GearRecommendation _calculateGearRecommendation(int currentGear, double rpm, double speed) {
    // Логика для механической коробки передач
    if (currentGear < 1) return GearRecommendation.none;
    
    // Рекомендация повышения передачи
    if (rpm > 3000 && currentGear < 6) {
      // Проверка соответствия скорости для следующей передачи
      final nextGearMinSpeed = _getMinSpeedForGear(currentGear + 1);
      if (speed >= nextGearMinSpeed) {
        return GearRecommendation.shiftUp;
      }
    }
    
    // Рекомендация понижения передачи
    if (rpm < 1200 && currentGear > 1) {
      final prevGearMaxSpeed = _getMaxSpeedForGear(currentGear - 1);
      if (speed <= prevGearMaxSpeed) {
        return GearRecommendation.shiftDown;
      }
    }
    
    return GearRecommendation.none;
  }

  /// Получение минимальной скорости для передачи
  double _getMinSpeedForGear(int gear) {
    const Map<int, double> minSpeeds = {
      1: 0.0, 2: 15.0, 3: 30.0, 4: 50.0, 5: 70.0, 6: 90.0
    };
    return minSpeeds[gear] ?? 0.0;
  }

  /// Получение максимальной скорости для передачи
  double _getMaxSpeedForGear(int gear) {
    const Map<int, double> maxSpeeds = {
      1: 25.0, 2: 40.0, 3: 65.0, 4: 90.0, 5: 120.0, 6: 200.0
    };
    return maxSpeeds[gear] ?? 200.0;
  }

  /// Конвертация передачи в числовое значение для физики
  double _getGearNumericValue(String gear) {
    return (_gearOrder[gear] ?? 0).toDouble();
  }

  /// Обработка ошибок
  void _handleError(String message) {
    _hasError = true;
    
    if (mounted) {
      setState(() {});
    }
    
    widget.onError?.call();
    debugPrint('GearIndicatorWidget Error: $message');
  }

  @override
  void dispose() {
    _physicsTicker.dispose();
    _gearShiftController.dispose();
    _recommendationController.dispose();
    _statusAnimationController.dispose();
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
        border: Border.all(
          color: widget.isShifting 
              ? AutomotiveTheme.accentOrange 
              : Colors.grey[700]!,
          width: widget.isShifting ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isShifting 
                ? AutomotiveTheme.accentOrange.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            spreadRadius: widget.isShifting ? 3 : 2,
            blurRadius: widget.isShifting ? 8 : 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с типом трансмиссии
          _buildHeader(),
          
          // Основной индикатор передачи
          Expanded(
            child: _buildGearDisplay(),
          ),
          
          // Дополнительная информация и рекомендации
          if (widget.showRecommendations)
            _buildRecommendationsPanel(),
        ],
      ),
    );
  }

  /// Создает заголовок виджета
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[600]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTransmissionDisplayName(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          
          // Индикатор состояния переключения
          AnimatedBuilder(
            animation: _statusAnimation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isShifting
                      ? AutomotiveTheme.accentOrange.withOpacity(_statusAnimation.value)
                      : AutomotiveTheme.successGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Создает основной дисплей передачи
  Widget _buildGearDisplay() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_gearShiftAnimation, _gearColorAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + 0.2 * _gearShiftAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Основная передача
                Text(
                  _displayGear,
                  style: TextStyle(
                    color: _gearColorAnimation.value,
                    fontSize: _getGearFontSize(),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DigitalNumbers',
                    shadows: [
                      Shadow(
                        color: (_gearColorAnimation.value ?? Colors.white)
                            .withOpacity(0.5),
                        blurRadius: 8 * _gearShiftAnimation.value,
                      ),
                    ],
                  ),
                ),
                
                // Дополнительная информация о передаче
                const SizedBox(height: 8),
                Text(
                  _getGearDescription(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Индикатор направления движения (для автоматических КПП)
                if (_shouldShowDirectionIndicator())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildDirectionIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Создает панель рекомендаций
  Widget _buildRecommendationsPanel() {
    return AnimatedBuilder(
      animation: _recommendationAnimation,
      builder: (context, child) {
        if (_currentRecommendation == GearRecommendation.none) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[600]!, width: 1),
            ),
          ),
          child: Opacity(
            opacity: 0.7 + 0.3 * _recommendationAnimation.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getRecommendationIcon(),
                  color: _getRecommendationColor(),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getRecommendationText(),
                  style: TextStyle(
                    color: _getRecommendationColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Создает индикатор направления движения
  Widget _buildDirectionIndicator() {
    IconData icon;
    Color color;
    
    switch (_displayGear) {
      case 'R':
        icon = Icons.arrow_back;
        color = AutomotiveTheme.warningRed;
        break;
      case 'D':
      case '1': case '2': case '3': case '4': case '5': case '6':
        icon = Icons.arrow_forward;
        color = AutomotiveTheme.successGreen;
        break;
      default:
        icon = Icons.pause;
        color = Colors.grey[400]!;
    }
    
    return Icon(
      icon,
      color: color,
      size: 20,
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
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'ОШИБКА\nПЕРЕДАЧ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AutomotiveTheme.warningRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Получение отображаемого названия типа трансмиссии
  String _getTransmissionDisplayName() {
    switch (widget.transmissionType) {
      case 'manual':
        return 'МКПП';
      case 'auto':
        return 'АКПП';
      case 'cvt':
        return 'CVT';
      case 'dual_clutch':
        return 'DSG';
      default:
        return 'КПП';
    }
  }

  /// Получение размера шрифта в зависимости от передачи
  double _getGearFontSize() {
    switch (_displayGear) {
      case 'P': case 'R': case 'N': case 'D':
        return 48.0;
      default:
        return 52.0;
    }
  }

  /// Получение описания текущей передачи
  String _getGearDescription() {
    switch (_displayGear) {
      case 'P':
        return 'ПАРКОВКА';
      case 'R':
        return 'ЗАДНИЙ ХОД';
      case 'N':
        return 'НЕЙТРАЛЬ';
      case 'D':
        return 'ДРАЙВ';
      case '1':
        return '1-я ПЕРЕДАЧА';
      case '2':
        return '2-я ПЕРЕДАЧА';
      case '3':
        return '3-я ПЕРЕДАЧА';
      case '4':
        return '4-я ПЕРЕДАЧА';
      case '5':
        return '5-я ПЕРЕДАЧА';
      case '6':
        return '6-я ПЕРЕДАЧА';
      default:
        return _displayGear;
    }
  }

  /// Проверка необходимости показа индикатора направления
  bool _shouldShowDirectionIndicator() {
    return widget.transmissionType == 'auto' || 
           ['P', 'R', 'N', 'D'].contains(_displayGear);
  }

  /// Получение иконки для рекомендации
  IconData _getRecommendationIcon() {
    switch (_currentRecommendation) {
      case GearRecommendation.shiftUp:
        return Icons.keyboard_arrow_up;
      case GearRecommendation.shiftDown:
        return Icons.keyboard_arrow_down;
      default:
        return Icons.info;
    }
  }

  /// Получение цвета для рекомендации
  Color _getRecommendationColor() {
    switch (_currentRecommendation) {
      case GearRecommendation.shiftUp:
        return AutomotiveTheme.successGreen;
      case GearRecommendation.shiftDown:
        return AutomotiveTheme.accentOrange;
      default:
        return Colors.grey[400]!;
    }
  }

  /// Получение текста рекомендации
  String _getRecommendationText() {
    switch (_currentRecommendation) {
      case GearRecommendation.shiftUp:
        return 'ПОВЫСИТЬ ПЕРЕДАЧУ';
      case GearRecommendation.shiftDown:
        return 'ПОНИЗИТЬ ПЕРЕДАЧУ';
      default:
        return '';
    }
  }
}

/// Enum для типов рекомендаций переключения передач
enum GearRecommendation {
  none,       // Нет рекомендаций
  shiftUp,    // Рекомендация повышения передачи
  shiftDown,  // Рекомендация понижения передачи
}