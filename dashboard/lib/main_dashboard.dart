import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'apps/dashboard/simple_dashboard.dart';
import 'core/theme/automotive_theme.dart';
import 'widgets/error_boundary.dart';

/// Точка входа только для Dashboard приложения
/// Запускается с flutter-pi для автомобильных дисплеев
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      child: DashboardOnlyApp(),
    ),
  );
}

/// Приложение только с Dashboard (без навигации)
class DashboardOnlyApp extends StatelessWidget {
  const DashboardOnlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automotive Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AutomotiveTheme.darkTheme,
      home: const DashboardErrorBoundary(
        child: SimpleDashboard(),
      ),
    );
  }
}