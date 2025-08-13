import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'apps/dashboard/medium_dashboard.dart';
import 'apps/multimedia/multimedia_app.dart';
import 'apps/multi_display/multi_display_app.dart';
import 'services/can_bus_provider.dart';
import 'services/automotive_can_service.dart';
import 'core/theme/automotive_theme.dart';
import 'widgets/error_boundary.dart';

/// Главная точка входа в приложение
/// Демонстрирует различные автомобильные интерфейсы на Flutter
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Hive для локального хранения данных
  await Hive.initFlutter();
  
  // Настройка полноэкранного режима для автомобильных дисплеев
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  
  // Принудительная портретная ориентация для повернутой панели
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    const ProviderScope(
      child: AutomotiveApp(),
    ),
  );
}

/// Основное приложение с навигацией между различными автомобильными интерфейсами
class AutomotiveApp extends StatelessWidget {
  const AutomotiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automotive Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: AutomotiveTheme.darkTheme,
      home: const DashboardErrorBoundary(
        child: MultiDisplayApp(),  // Используем мульти-дисплей вместо простой панели
      ),
    );
  }
}

/// Основной навигатор между различными демо-приложениями
class MainNavigator extends ConsumerWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок презентации
                Text(
                  'Flutter для автомобильных систем',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Демонстрация возможностей Flutter в автомобильной индустрии',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Сетка с демо-приложениями
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.5,
                    children: [
                      _buildDemoCard(
                        context,
                        title: 'Приборная панель',
                        subtitle: 'Реальные данные автомобиля',
                        icon: Icons.dashboard,
                        onTap: () => _navigateTo(context, const MediumDashboard()),
                      ),
                      _buildDemoCard(
                        context,
                        title: 'CAN Bus симулятор',
                        subtitle: 'Генерация OBD-II данных',
                        icon: Icons.settings_input_component,
                        onTap: () => _showCanBusDemo(context),
                      ),
                      _buildDemoCard(
                        context,
                        title: 'Мультимедиа',
                        subtitle: 'Аудио зоны и источники',
                        icon: Icons.library_music,
                        onTap: () => _navigateTo(context, const MultimediaApp()),
                      ),
                      _buildDemoCard(
                        context,
                        title: 'Мульти-дисплей',
                        subtitle: 'Кластер и инфотейнмент',
                        icon: Icons.view_quilt,
                        onTap: () => _navigateTo(context, const MultiDisplayApp()),
                      ),
                    ],
                  ),
                ),
                
                // Информация о Flutter-Pi
                Container(
                  margin: const EdgeInsets.only(top: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.memory,
                        color: Colors.blue,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Flutter-Pi интеграция',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Запуск Flutter приложений на Raspberry Pi без X11',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[300],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Создает карточку для демо-приложения
  Widget _buildDemoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.blue[400],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Навигация к демо-приложению
  void _navigateTo(BuildContext context, Widget destination) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  /// Показывает демо CAN Bus симулятора
  void _showCanBusDemo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: const CanBusSimulatorWidget(),
        ),
      ),
    );
  }
}

/// Виджет для демонстрации CAN Bus симулятора
class CanBusSimulatorWidget extends ConsumerWidget {
  const CanBusSimulatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canData = ref.watch(canBusProvider);
    
    return Column(
      children: [
        Text(
          'CAN Bus симулятор',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: canData.entries.map((entry) {
                return Card(
                  color: Colors.grey[800],
                  child: ListTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      entry.value.toString(),
                      style: TextStyle(color: Colors.green[400]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}