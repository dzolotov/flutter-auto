import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'apps/media/car_media_player.dart';
import 'core/theme/automotive_theme.dart';
import 'widgets/error_boundary.dart';

/// Точка входа для медиаплеера
/// Запуск: flutter run -t lib/main_media.dart
/// Или для flutter-pi: flutterpi_tool build -t lib/main_media.dart && flutterpi_tool run
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Hive для локального хранения данных
  await Hive.initFlutter();
  
  // Настройка полноэкранного режима для автомобильных дисплеев
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  
  // Принудительная альбомная ориентация для автомобильных экранов
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(
    const ProviderScope(
      child: MediaPlayerApp(),
    ),
  );
}

/// Приложение медиаплеера
class MediaPlayerApp extends StatelessWidget {
  const MediaPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automotive Media Player',
      debugShowCheckedModeBanner: false,
      theme: AutomotiveTheme.darkTheme,
      home: const DashboardErrorBoundary(
        child: CarMediaPlayer(),
      ),
    );
  }
}