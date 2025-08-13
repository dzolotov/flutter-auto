import 'package:flutter/material.dart';

import '../../../core/theme/automotive_theme.dart';

/// Дисплей инфотейнмент системы
/// Объединяет навигацию, мультимедиа, климат-контроль и настройки
class InfotainmentDisplay extends StatefulWidget {
  const InfotainmentDisplay({super.key});

  @override
  State<InfotainmentDisplay> createState() => _InfotainmentDisplayState();
}

class _InfotainmentDisplayState extends State<InfotainmentDisplay>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Верхняя панель статуса
          Container(
            height: 50,
            color: AutomotiveTheme.surfaceDark,
            child: _buildStatusBar(),
          ),
          
          // Главное содержимое с табами
          Expanded(
            child: Column(
              children: [
                // Панель табов
                Container(
                  color: AutomotiveTheme.cardDark,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AutomotiveTheme.primaryBlue,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[400],
                    tabs: [
                      Tab(icon: Icon(Icons.home), text: 'Главная'),
                      Tab(icon: Icon(Icons.navigation), text: 'Навигация'),
                      Tab(icon: Icon(Icons.library_music), text: 'Медиа'),
                      Tab(icon: Icon(Icons.ac_unit), text: 'Климат'),
                      Tab(icon: Icon(Icons.settings), text: 'Настройки'),
                    ],
                  ),
                ),
                
                // Содержимое табов
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHomeTab(),
                      _buildNavigationTab(),
                      _buildMediaTab(),
                      _buildClimateTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Нижняя панель быстрого доступа
          Container(
            height: 80,
            color: AutomotiveTheme.cardDark,
            child: _buildQuickAccessBar(),
          ),
        ],
      ),
    );
  }

  /// Строка статуса
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Время
          StreamBuilder(
            stream: Stream.periodic(Duration(seconds: 1)),
            builder: (context, snapshot) {
              final now = DateTime.now();
              return Text(
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DigitalNumbers',
                ),
              );
            },
          ),
          
          const Spacer(),
          
          // Индикаторы подключения
          _buildConnectionIndicators(),
        ],
      ),
    );
  }

  /// Индикаторы подключения
  Widget _buildConnectionIndicators() {
    return Row(
      children: [
        _buildStatusIndicator(Icons.bluetooth, true, 'Bluetooth'),
        const SizedBox(width: 12),
        _buildStatusIndicator(Icons.wifi, true, 'Wi-Fi'),
        const SizedBox(width: 12),
        _buildStatusIndicator(Icons.signal_cellular_4_bar, true, 'Сотовая связь'),
        const SizedBox(width: 12),
        _buildStatusIndicator(Icons.gps_fixed, false, 'GPS'),
      ],
    );
  }

  /// Индикатор статуса
  Widget _buildStatusIndicator(IconData icon, bool isActive, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 20,
        color: isActive 
            ? AutomotiveTheme.successGreen 
            : Colors.grey[600],
      ),
    );
  }

  /// Главная страница
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточки быстрого доступа
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildQuickCard(Icons.phone, 'Телефон', () {}),
              _buildQuickCard(Icons.message, 'Сообщения', () {}),
              _buildQuickCard(Icons.calendar_today, 'Календарь', () {}),
              _buildQuickCard(Icons.contacts, 'Контакты', () {}),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Последние активности
          _buildRecentActivities(),
          
          const SizedBox(height: 24),
          
          // Погода
          _buildWeatherWidget(),
        ],
      ),
    );
  }

  /// Навигация
  Widget _buildNavigationTab() {
    return Container(
      child: Stack(
        children: [
          // Карта (заглушка)
          Container(
            color: Colors.grey[800],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Карты недоступны',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Интеграция с картографическими сервисами',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Панель поиска
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Куда поедем?',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Медиа
  Widget _buildMediaTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Текущий трек
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: AutomotiveTheme.gaugeGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Обложка
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.music_note, color: Colors.grey[400]),
                ),
                
                const SizedBox(width: 16),
                
                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bohemian Rhapsody',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Queen',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.3,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AutomotiveTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Управление
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.play_arrow, size: 32),
                      color: AutomotiveTheme.primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Источники
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildSourceCard(Icons.bluetooth, 'Bluetooth', true),
                _buildSourceCard(Icons.usb, 'USB', false),
                _buildSourceCard(Icons.radio, 'Радио', false),
                _buildSourceCard(Icons.wifi, 'Spotify', true),
                _buildSourceCard(Icons.album, 'CD', false),
                _buildSourceCard(Icons.cable, 'AUX', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Климат-контроль
  Widget _buildClimateTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Текущая температура
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: AutomotiveTheme.gaugeGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Row(
              children: [
                // Водитель
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ВОДИТЕЛЬ',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '22°',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DigitalNumbers',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Пассажир
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ПАССАЖИР',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '24°',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DigitalNumbers',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Элементы управления климатом
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildClimateControl(Icons.ac_unit, 'A/C', true),
                _buildClimateControl(Icons.air, 'AUTO', false),
                _buildClimateControl(Icons.loop, 'RECIRC', false),
                _buildClimateControl(Icons.toys, 'Обдув', false),
                _buildClimateControl(Icons.whatshot, 'Обогрев', false),
                _buildClimateControl(Icons.snowing, 'Охлаждение', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Настройки
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection('Дисплей', [
          _buildSettingItem('Яркость', '80%'),
          _buildSettingItem('Тема', 'Темная'),
          _buildSettingItem('Автоповорот', 'Вкл'),
        ]),
        
        _buildSettingsSection('Звук', [
          _buildSettingItem('Громкость', '70%'),
          _buildSettingItem('Системные звуки', 'Вкл'),
          _buildSettingItem('Голосовые подсказки', 'Вкл'),
        ]),
        
        _buildSettingsSection('Подключения', [
          _buildSettingItem('Wi-Fi', 'Подключено'),
          _buildSettingItem('Bluetooth', 'Подключено'),
          _buildSettingItem('Мобильный интернет', 'Выкл'),
        ]),
        
        _buildSettingsSection('Система', [
          _buildSettingItem('Версия ПО', '1.0.0'),
          _buildSettingItem('Обновления', 'Проверить'),
          _buildSettingItem('Сброс настроек', 'Выполнить'),
        ]),
      ],
    );
  }

  /// Панель быстрого доступа
  Widget _buildQuickAccessBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickButton(Icons.phone, () {}),
          _buildQuickButton(Icons.message, () {}),
          _buildQuickButton(Icons.home, () {}),
          _buildQuickButton(Icons.navigation, () {}),
          _buildQuickButton(Icons.settings, () {}),
        ],
      ),
    );
  }

  /// Карточка быстрого доступа
  Widget _buildQuickCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AutomotiveTheme.gaugeGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AutomotiveTheme.primaryBlue, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка источника медиа
  Widget _buildSourceCard(IconData icon, String label, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AutomotiveTheme.primaryBlue : Colors.grey[700]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AutomotiveTheme.primaryBlue : Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Элемент управления климатом
  Widget _buildClimateControl(IconData icon, String label, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AutomotiveTheme.primaryBlue : Colors.grey[700]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AutomotiveTheme.primaryBlue : Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка быстрого доступа
  Widget _buildQuickButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 28),
      style: IconButton.styleFrom(
        backgroundColor: AutomotiveTheme.primaryBlue.withOpacity(0.2),
        shape: CircleBorder(),
      ),
    );
  }

  /// Последние активности (заглушка)
  Widget _buildRecentActivities() {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Последняя активность',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Звонок от Анна - 14:30',
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            'Новое сообщение - 13:45',
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            'Напоминание: Встреча - 15:00',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  /// Виджет погоды (заглушка)
  Widget _buildWeatherWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: AutomotiveTheme.gaugeGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.wb_sunny, color: Colors.yellow, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '23°C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Солнечно, Москва',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Секция настроек
  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: AutomotiveTheme.gaugeGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  /// Элемент настройки
  Widget _buildSettingItem(String title, String value) {
    return ListTile(
      title: Text(title, style: TextStyle(color: Colors.white)),
      trailing: Text(value, style: TextStyle(color: Colors.grey[400])),
      onTap: () {},
    );
  }
}