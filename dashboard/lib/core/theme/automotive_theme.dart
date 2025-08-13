import 'package:flutter/material.dart';

/// Тема для автомобильных приложений
/// Оптимизирована для темных условий освещения и больших экранов
class AutomotiveTheme {
  // Основная цветовая палитра для автомобильных интерфейсов
  static const Color primaryBlue = Color(0xFF00D4FF);      // Яркий киберпанк синий
  static const Color primaryCyan = Color(0xFF00FFC7);      // Неоновый циан
  static const Color accentOrange = Color(0xFFFF6B35);     // Яркий оранжевый
  static const Color accentPurple = Color(0xFF9B59B6);     // Фиолетовый акцент
  static const Color warningRed = Color(0xFFFF073A);       // Ярко-красный
  static const Color successGreen = Color(0xFF39FF14);     // Неоновый зеленый
  static const Color backgroundDark = Color(0xFF0A0A0F);   // Глубокий темно-синий
  static const Color surfaceDark = Color(0xFF1A1A2E);      // Темно-синяя поверхность
  static const Color cardDark = Color(0xFF16213E);         // Карточки с синим оттенком

  /// Темная тема для автомобильных приложений
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: createMaterialColor(primaryBlue),
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundDark,
      
      // Настройка AppBar для автомобильных интерфейсов
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // Настройка карточек
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Настройка кнопок
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Настройка текстовых полей
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      
      // Настройка типографики
      textTheme: _buildTextTheme(),
      
      // Цветовая схема
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentOrange,
        surface: surfaceDark,
        background: backgroundDark,
        error: warningRed,
      ),
    );
  }

  /// Создает типографику для автомобильных интерфейсов
  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Заголовки
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      
      // Заголовки секций
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFBDBDBD),
      ),
      
      // Основной текст
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFFBDBDBD),
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xFF9E9E9E),
        height: 1.4,
      ),
      
      // Подписи и метки
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFFBDBDBD),
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: Color(0xFF9E9E9E),
        letterSpacing: 0.5,
      ),
    );
  }

  /// Создает MaterialColor из Color
  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    
    return MaterialColor(color.value, swatch);
  }

  // Специальные цвета для автомобильных индикаторов
  static const Color speedometerNeedle = Color(0xFF00FFC7);    // Неоновая стрелка
  static const Color rpmRedZone = Color(0xFFFF073A);           // Красная зона
  static const Color temperatureWarning = Color(0xFFFF6B35);   // Предупреждение
  static const Color temperatureDanger = Color(0xFFFF073A);    // Опасность
  static const Color fuelLow = Color(0xFFFF6B35);              // Низкий уровень топлива
  static const Color oilPressureWarning = Color(0xFFFF073A);   // Давление масла
  
  // Цвета для мультимедиа интерфейса
  static const Color playButtonGreen = Color(0xFF4CAF50);
  static const Color pauseButtonOrange = Color(0xFFFF9800);
  static const Color stopButtonRed = Color(0xFFF44336);
  
  // Градиенты для различных элементов
  static const LinearGradient dashboardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F0F23),  // Темно-синий верх
      Color(0xFF000000),  // Черный низ
    ],
  );
  
  static const LinearGradient gaugeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF16213E),  // Синеватый
      Color(0xFF0F0F23),  // Темно-синий
    ],
  );
  
  static const RadialGradient speedometerGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [
      Color(0xFF1A1A2E),  // Центр
      Color(0xFF16213E),  // Середина
      Color(0xFF0F0F23),  // Край
    ],
  );
  
  static const LinearGradient neonGlow = LinearGradient(
    colors: [
      Color(0xFF00D4FF),
      Color(0xFF00FFC7),
    ],
  );
}