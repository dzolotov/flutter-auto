import 'package:flutter/material.dart';
import '../../../core/theme/automotive_theme.dart';
import '../../../services/audio_manager.dart';

/// Виджет управления параметрами аудиозоны
/// Включает регулировку громкости, баланса и fade
class AudioZoneControl extends StatelessWidget {
  final AudioZone zone;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onBalanceChanged;

  const AudioZoneControl({
    super.key,
    required this.zone,
    required this.onVolumeChanged,
    required this.onBalanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AutomotiveTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: AutomotiveTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Настройки зоны: ${zone.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                // Кнопка mute зоны
                IconButton(
                  onPressed: () {
                    // TODO: Реализовать mute зоны
                  },
                  icon: Icon(
                    zone.muted ? Icons.volume_off : Icons.volume_up,
                    color: zone.muted ? AutomotiveTheme.warningRed : Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Регулировка громкости
            _buildVolumeControl(context),
            
            const SizedBox(height: 24),
            
            // Регулировка баланса и fade
            Row(
              children: [
                Expanded(child: _buildBalanceControl(context)),
                const SizedBox(width: 24),
                Expanded(child: _buildFadeControl(context)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Визуализатор уровня сигнала
            _buildLevelIndicator(context),
          ],
        ),
      ),
    );
  }

  /// Создает регулятор громкости
  Widget _buildVolumeControl(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Громкость',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${(zone.volume * 100).toInt()}%',
              style: TextStyle(
                color: AutomotiveTheme.primaryBlue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'DigitalNumbers',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Container(
          height: 60,
          child: Row(
            children: [
              // Иконка минимальной громкости
              Icon(
                Icons.volume_mute,
                color: Colors.grey[400],
                size: 20,
              ),
              
              const SizedBox(width: 12),
              
              // Слайдер громкости
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AutomotiveTheme.primaryBlue,
                    inactiveTrackColor: Colors.grey[600],
                    thumbColor: AutomotiveTheme.primaryBlue,
                    overlayColor: AutomotiveTheme.primaryBlue.withOpacity(0.2),
                    trackHeight: 6,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                  ),
                  child: Slider(
                    value: zone.volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Иконка максимальной громкости
              Icon(
                Icons.volume_up,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
        
        // Визуальный индикатор громкости
        Container(
          height: 8,
          margin: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: zone.volume,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getVolumeColor(zone.volume),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Создает регулятор баланса (лево-право)
  Widget _buildBalanceControl(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Баланс',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        const SizedBox(height: 12),
        
        // Круговой индикатор баланса
        Container(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: BalancePainter(
              balance: zone.balance,
              color: AutomotiveTheme.primaryBlue,
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                final center = Offset(60, 60);
                final offset = details.localPosition - center;
                final balance = (offset.dx / 50).clamp(-1.0, 1.0);
                onBalanceChanged(balance);
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      zone.balance < -0.1 ? 'Л' : zone.balance > 0.1 ? 'П' : 'Ц',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(zone.balance.abs() * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Л', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Text('П', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  /// Создает регулятор fade (перед-зад)
  Widget _buildFadeControl(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Fade',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        const SizedBox(height: 12),
        
        // Круговой индикатор fade
        Container(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: FadePainter(
              fade: zone.fade,
              color: AutomotiveTheme.accentOrange,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    zone.fade < -0.1 ? 'З' : zone.fade > 0.1 ? 'П' : 'Ц',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(zone.fade.abs() * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Column(
          children: [
            Text('П', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 50),
            Text('З', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  /// Создает индикатор уровня сигнала
  Widget _buildLevelIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Уровень сигнала',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(child: _buildChannelLevel('Левый', zone.volume * 0.8)),
            const SizedBox(width: 16),
            Expanded(child: _buildChannelLevel('Правый', zone.volume * 0.9)),
          ],
        ),
      ],
    );
  }

  /// Создает индикатор уровня канала
  Widget _buildChannelLevel(String label, double level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Container(
          height: 20,
          child: Row(
            children: List.generate(10, (index) {
              final segmentValue = (index + 1) / 10.0;
              final isActive = level >= segmentValue;
              
              Color segmentColor;
              if (segmentValue < 0.7) {
                segmentColor = AutomotiveTheme.successGreen;
              } else if (segmentValue < 0.9) {
                segmentColor = AutomotiveTheme.accentOrange;
              } else {
                segmentColor = AutomotiveTheme.warningRed;
              }
              
              return Expanded(
                child: Container(
                  height: 20,
                  margin: EdgeInsets.only(right: index < 9 ? 2 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? segmentColor : Colors.grey[800],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Определяет цвет в зависимости от уровня громкости
  Color _getVolumeColor(double volume) {
    if (volume < 0.3) {
      return AutomotiveTheme.successGreen;
    } else if (volume < 0.7) {
      return AutomotiveTheme.accentOrange;
    } else {
      return AutomotiveTheme.primaryBlue;
    }
  }
}

/// Кастомный рисовальщик для баланса
class BalancePainter extends CustomPainter {
  final double balance;
  final Color color;

  BalancePainter({required this.balance, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Рисуем окружность
    final circlePaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, circlePaint);

    // Рисуем индикатор позиции
    final indicatorOffset = Offset(
      center.dx + balance * (radius - 10),
      center.dy,
    );

    final indicatorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(indicatorOffset, 8, indicatorPaint);

    // Рисуем центральную линию
    final centerLinePaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      centerLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant BalancePainter oldDelegate) {
    return oldDelegate.balance != balance;
  }
}

/// Кастомный рисовальщик для fade
class FadePainter extends CustomPainter {
  final double fade;
  final Color color;

  FadePainter({required this.fade, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Рисуем окружность
    final circlePaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, circlePaint);

    // Рисуем индикатор позиции
    final indicatorOffset = Offset(
      center.dx,
      center.dy - fade * (radius - 10),
    );

    final indicatorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(indicatorOffset, 8, indicatorPaint);

    // Рисуем горизонтальную линию
    final centerLinePaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      centerLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant FadePainter oldDelegate) {
    return oldDelegate.fade != fade;
  }
}