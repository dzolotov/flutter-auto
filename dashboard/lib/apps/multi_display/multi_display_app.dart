import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme/automotive_theme.dart';
import '../../services/display_manager.dart';
import 'widgets/instrument_cluster_display.dart';
import 'widgets/infotainment_display.dart';
import 'widgets/heads_up_display.dart';
import 'widgets/rear_passenger_display.dart';
import 'widgets/display_configuration_panel.dart';
import '../dashboard/medium_dashboard.dart';

/// Основное приложение мульти-дисплейной системы
/// Управляет несколькими экранами: приборная панель, инфотейнмент, HUD, задние экраны
class MultiDisplayApp extends ConsumerStatefulWidget {
  const MultiDisplayApp({super.key});

  @override
  ConsumerState<MultiDisplayApp> createState() => _MultiDisplayAppState();
}

class _MultiDisplayAppState extends ConsumerState<MultiDisplayApp> {
  int _selectedDisplay = 0;
  bool _isFullscreenMode = false;

  // Список доступных дисплеев
  final List<DisplayInfo> _displays = [
    DisplayInfo(
      id: 'medium_dashboard',
      name: 'Премиум панель',
      description: 'Красивая анимированная панель',
      icon: Icons.dashboard_customize,
      resolution: '1920x1080',
      type: DisplayType.mediumDashboard,
    ),
    DisplayInfo(
      id: 'instrument_cluster',
      name: 'Приборная панель',
      description: 'Основные показатели автомобиля',
      icon: Icons.speed,
      resolution: '1920x720',
      type: DisplayType.instrumentCluster,
    ),
    DisplayInfo(
      id: 'infotainment',
      name: 'Инфотейнмент',
      description: 'Мультимедиа и навигация',
      icon: Icons.dashboard,
      resolution: '1920x1080',
      type: DisplayType.infotainment,
    ),
    DisplayInfo(
      id: 'heads_up',
      name: 'Проекционный дисплей',
      description: 'Критически важная информация',
      icon: Icons.visibility,
      resolution: '800x480',
      type: DisplayType.headsUp,
    ),
    DisplayInfo(
      id: 'rear_left',
      name: 'Задний левый',
      description: 'Развлечения для пассажиров',
      icon: Icons.tablet,
      resolution: '1280x800',
      type: DisplayType.rearPassenger,
    ),
    DisplayInfo(
      id: 'rear_right',
      name: 'Задний правый',
      description: 'Развлечения для пассажиров',
      icon: Icons.tablet,
      resolution: '1280x800',
      type: DisplayType.rearPassenger,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Инициализация дисплейного менеджера
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(displayManagerProvider.notifier).initialize(_displays);
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayState = ref.watch(displayManagerProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreenMode ? null : AppBar(
        title: Text('Мульти-дисплейная система'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleFullscreen,
            icon: Icon(Icons.fullscreen),
            tooltip: 'Полноэкранный режим',
          ),
          IconButton(
            onPressed: _showDisplayConfiguration,
            icon: Icon(Icons.settings),
            tooltip: 'Настройки дисплеев',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AutomotiveTheme.dashboardGradient,
        ),
        child: _isFullscreenMode
            ? _buildFullscreenDisplay()
            : _buildMultiDisplayView(displayState),
      ),
    );
  }

  /// Создает мульти-дисплейный вид
  Widget _buildMultiDisplayView(DisplaySystemState displayState) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width <= 800 || screenSize.height <= 480;
    
    if (isSmallScreen) {
      // Упрощенный вид для маленьких экранов
      return Column(
        children: [
          // Компактный селектор дисплеев
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _displays.length,
              itemBuilder: (context, index) {
                return _buildCompactDisplayTab(index, _displays[index]);
              },
            ),
          ),
          // Содержимое дисплея
          Expanded(
            child: Container(
              color: Colors.black,
              child: _buildDisplayContent(),
            ),
          ),
        ],
      );
    }
    
    return Row(
      children: [
        // Боковая панель с выбором дисплея
        if (!_isFullscreenMode)
          Container(
            width: 200,
            child: _buildDisplaySelector(),
          ),
        
        // Основная область отображения
        Expanded(
          child: Column(
            children: [
              // Заголовок выбранного дисплея
              Container(
                height: 60,
                padding: const EdgeInsets.all(8),
                child: _buildDisplayHeader(),
              ),
              
              // Содержимое дисплея
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildDisplayContent(),
                  ),
                ),
              ),
              
              // Информация о дисплее
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _buildDisplayInfo(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Создает селектор дисплеев
  Widget _buildDisplaySelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        border: Border(
          right: BorderSide(color: Colors.grey[700]!),
        ),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            height: 50,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Дисплеи',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_displays.length} подключено',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Список дисплеев
          Expanded(
            child: ListView.builder(
              itemCount: _displays.length,
              itemBuilder: (context, index) {
                return _buildDisplayCard(index, _displays[index]);
              },
            ),
          ),
          
          // Кнопки управления
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _syncAllDisplays,
                  icon: Icon(Icons.sync, size: 16),
                  label: Text('Синхр.', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 32),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: _mirrorDisplays,
                  icon: Icon(Icons.flip_to_front, size: 16),
                  label: Text('Зеркало', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    minimumSize: Size(double.infinity, 32),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Создает карточку дисплея
  Widget _buildDisplayCard(int index, DisplayInfo display) {
    final isSelected = _selectedDisplay == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: GestureDetector(
        onTap: () => setState(() => _selectedDisplay = index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected 
                ? AutomotiveTheme.primaryBlue.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? AutomotiveTheme.primaryBlue 
                  : Colors.grey[600]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      display.icon,
                      color: isSelected 
                          ? AutomotiveTheme.primaryBlue 
                          : Colors.grey[400],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        display.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildDisplayStatus(display),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  display.description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 2),
                
                Text(
                  display.resolution,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 8,
                    fontFamily: 'DigitalNumbers',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Создает компактную вкладку дисплея для маленьких экранов
  Widget _buildCompactDisplayTab(int index, DisplayInfo display) {
    final isSelected = _selectedDisplay == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDisplay = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AutomotiveTheme.primaryBlue.withOpacity(0.3)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AutomotiveTheme.primaryBlue 
                : Colors.grey[600]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              display.icon,
              color: isSelected 
                  ? AutomotiveTheme.primaryBlue 
                  : Colors.grey[400],
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              display.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Создает индикатор статуса дисплея
  Widget _buildDisplayStatus(DisplayInfo display) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AutomotiveTheme.successGreen, // Все дисплеи активны
        shape: BoxShape.circle,
      ),
    );
  }

  /// Создает заголовок дисплея
  Widget _buildDisplayHeader() {
    final selectedDisplay = _displays[_selectedDisplay];
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width <= 800 || screenSize.height <= 480;
    
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(
            selectedDisplay.icon,
            color: AutomotiveTheme.primaryBlue,
            size: isSmallScreen ? 20 : 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  selectedDisplay.name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isSmallScreen)
                  Text(
                    selectedDisplay.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (!isSmallScreen)
            _buildDisplayControls(selectedDisplay),
        ],
      ),
    );
  }

  /// Создает элементы управления дисплеем
  Widget _buildDisplayControls(DisplayInfo display) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _adjustBrightness(display),
          icon: Icon(Icons.brightness_6, color: Colors.grey[400]),
          tooltip: 'Яркость',
        ),
        IconButton(
          onPressed: () => _rotateDisplay(display),
          icon: Icon(Icons.rotate_90_degrees_ccw, color: Colors.grey[400]),
          tooltip: 'Поворот',
        ),
        IconButton(
          onPressed: _toggleFullscreen,
          icon: Icon(Icons.fullscreen, color: Colors.grey[400]),
          tooltip: 'Полный экран',
        ),
      ],
    );
  }

  /// Создает содержимое дисплея
  Widget _buildDisplayContent() {
    final selectedDisplay = _displays[_selectedDisplay];
    
    switch (selectedDisplay.type) {
      case DisplayType.mediumDashboard:
        return MediumDashboard();
      case DisplayType.instrumentCluster:
        return InstrumentClusterDisplay();
      case DisplayType.infotainment:
        return InfotainmentDisplay();
      case DisplayType.headsUp:
        return HeadsUpDisplay();
      case DisplayType.rearPassenger:
        return RearPassengerDisplay(displayId: selectedDisplay.id);
    }
  }

  /// Создает информационную панель дисплея
  Widget _buildDisplayInfo() {
    final selectedDisplay = _displays[_selectedDisplay];
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width <= 800 || screenSize.height <= 480;
    
    if (isSmallScreen) {
      return Container();
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _buildInfoItem('Разрешение', selectedDisplay.resolution),
          const SizedBox(width: 16),
          _buildInfoItem('FPS', '60'),
          const SizedBox(width: 16),
          _buildInfoItem('Яркость', '80%'),
          const SizedBox(width: 16),
          _buildInfoItem('Статус', 'Активен'),
        ],
      ),
    );
  }

  /// Создает элемент информации
  Widget _buildInfoItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Создает полноэкранный режим
  Widget _buildFullscreenDisplay() {
    return _buildDisplayContent();
  }

  /// Переключение полноэкранного режима
  void _toggleFullscreen() {
    setState(() {
      _isFullscreenMode = !_isFullscreenMode;
    });
    
    if (_isFullscreenMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  /// Показать конфигурацию дисплеев
  void _showDisplayConfiguration() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AutomotiveTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: DisplayConfigurationPanel(displays: _displays),
        ),
      ),
    );
  }

  /// Синхронизация всех дисплеев
  void _syncAllDisplays() {
    ref.read(displayManagerProvider.notifier).syncAllDisplays();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Все дисплеи синхронизированы')),
    );
  }

  /// Зеркалирование дисплеев
  void _mirrorDisplays() {
    ref.read(displayManagerProvider.notifier).enableMirroring();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Режим зеркалирования включен')),
    );
  }

  /// Настройка яркости дисплея
  void _adjustBrightness(DisplayInfo display) {
    showDialog(
      context: context,
      builder: (context) => _BrightnessDialog(display: display),
    );
  }

  /// Поворот дисплея
  void _rotateDisplay(DisplayInfo display) {
    ref.read(displayManagerProvider.notifier).rotateDisplay(display.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Дисплей ${display.name} повернут')),
    );
  }
}

/// Диалог настройки яркости
class _BrightnessDialog extends StatefulWidget {
  final DisplayInfo display;

  const _BrightnessDialog({required this.display});

  @override
  State<_BrightnessDialog> createState() => _BrightnessDialogState();
}

class _BrightnessDialogState extends State<_BrightnessDialog> {
  double _brightness = 0.8;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AutomotiveTheme.cardDark,
      title: Text('Яркость: ${widget.display.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Яркость: ${(_brightness * 100).toInt()}%'),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AutomotiveTheme.primaryBlue,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: AutomotiveTheme.primaryBlue,
            ),
            child: Slider(
              value: _brightness,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _brightness = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setBrightness(0.3),
                  child: Text('Ночь'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setBrightness(0.8),
                  child: Text('День'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AutomotiveTheme.primaryBlue,
                  ),
                ),
              ),
            ],
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

  void _setBrightness(double value) {
    setState(() {
      _brightness = value;
    });
  }
}