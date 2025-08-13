# Flutter Automotive Demo для Raspberry Pi

## Обзор проекта

Демонстрационный проект Flutter для автомобильных систем, работающий на Raspberry Pi через flutter-pi без X11/Wayland. Включает интеграцию с CAN шиной для чтения реальных данных автомобиля через OBD-II протокол.

## Структура проекта

```
automotive/
├── scripts/
│   └── deploy_to_pi.sh           # Основной скрипт развертывания
├── flutter-pi-src/                # Исходники flutter-pi с плагином
│   └── src/plugins/
│       └── automotive_plugin.c    # Нативный плагин для CAN/OBD-II
├── examples/
│   ├── counter/                  # Простой пример счетчика с CAN
│   │   ├── lib/main.dart
│   │   └── pubspec.yaml
│   └── dashboard/                # Полнофункциональный дэшборд
│       ├── lib/
│       │   ├── main.dart
│       │   ├── apps/
│       │   │   ├── dashboard/    # Приборная панель
│       │   │   └── multimedia/   # Мультимедиа система
│       │   └── services/
│       │       └── can_bus_service.dart
│       └── pubspec.yaml
└── README.md                     # Этот файл
```

## Возможности

### 1. Приборная панель (Dashboard)
- Спидометр и тахометр с неоновой подсветкой
- Индикатор передач (автоматический расчет)
- Температура двигателя
- Уровень топлива
- Положение дроссельной заслонки
- Нагрузка двигателя

### 2. CAN Bus интеграция
- Поддержка реального CAN интерфейса (can0/vcan0)
- Чтение OBD-II данных (PIDs)
- Режим симулятора для разработки
- Переключение между режимами через --dart-define

### 3. Flutter-Pi интеграция
- Прямой рендеринг через DRM/KMS
- Работа без X11/Wayland
- Поддержка Debug (JIT) и Release (AOT) режимов
- Нативные плагины через FLUTTERPI_PLUGIN

## Требования

### Raspberry Pi
- Raspberry Pi 4/5 с 4GB+ RAM
- Raspbian OS (64-bit рекомендуется)
- Экран подключенный через HDMI
- CAN интерфейс (опционально для реальных данных)

### Зависимости
```bash
# На Raspberry Pi
sudo apt-get update
sudo apt-get install -y \
    cmake git wget \
    libgl1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev \
    libdrm-dev libgbm-dev \
    libsystemd-dev libinput-dev libudev-dev libxkbcommon-dev \
    can-utils
```

### Flutter
- Flutter SDK 3.0+
- Настроенная поддержка Linux

## Установка

### 1. Первоначальная настройка Raspberry Pi

```bash
# SSH на Raspberry Pi
ssh pi@192.168.1.199

# Установка flutter-pi из исходников
cd ~/automotive/scripts
./deploy_to_pi.sh setup
```

### 2. Сборка и развертывание приложения

#### Простой счетчик с CAN тестом
```bash
# На хост-машине (macOS/Linux)
cd ~/automotive/scripts
./deploy_to_pi.sh all ../examples/counter
```

#### Полный дэшборд с мультимедиа
```bash
# С симулятором (по умолчанию)
./deploy_to_pi.sh all ../examples/dashboard

# С реальным CAN интерфейсом
cd ~/automotive/examples/dashboard
flutter build bundle --target-platform=linux-arm64 \
    --dart-define=USE_SIMULATOR=false
cd ~/automotive/scripts
./deploy_to_pi.sh -s all ../examples/dashboard
```

#### Debug режим с hot reload
```bash
./deploy_to_pi.sh -d all ../examples/dashboard
```

## Сценарий демонстрации

### Этап 1: Запуск простого примера (5 мин)

1. **Подготовка**
   ```bash
   cd ~/automotive/scripts
   ./deploy_to_pi.sh setup  # Только при первом запуске
   ```

2. **Запуск счетчика**
   ```bash
   ./deploy_to_pi.sh all ../examples/counter
   ```
   - Демонстрация базовой работы Flutter на Pi
   - Показ статуса CAN интерфейса
   - Тест платформенных каналов

### Этап 2: Демонстрация дэшборда (10 мин)

1. **Запуск в режиме симулятора**
   ```bash
   ./deploy_to_pi.sh all ../examples/dashboard
   ```
   - Показ анимированных приборов
   - Демонстрация плавности 60 FPS
   - Объяснение архитектуры приложения

2. **Переключение источников данных**
   - Симулятор: случайные, но реалистичные данные
   - Реальный CAN: чтение через OBD-II адаптер

### Этап 3: Технические детали (10 мин)

1. **Flutter-Pi архитектура**
   - Прямой доступ к GPU через DRM/KMS
   - Отсутствие оверхеда от X11
   - Нативные плагины на C

2. **CAN Bus интеграция**
   ```c
   // automotive_plugin.c
   FLUTTERPI_PLUGIN("automotive", 
                    automotive_plugin_init, 
                    automotive_plugin_deinit);
   ```
   - SocketCAN API
   - OBD-II протокол
   - Обработка CAN фреймов

3. **Dart архитектура**
   ```dart
   // Выбор режима через переменную окружения
   const bool useSimulator = 
       bool.fromEnvironment('USE_SIMULATOR', 
                           defaultValue: true);
   ```

### Этап 4: Расширенные возможности (5 мин)

1. **Мультимедиа интеграция**
   - Управление аудио зонами
   - Радио и медиаплеер
   - Эквалайзер

2. **Мульти-дисплей**
   - Поддержка нескольких экранов
   - HUD проекция
   - Задние пассажирские экраны

## Команды скрипта развертывания

```bash
# Полный цикл развертывания
./deploy_to_pi.sh all [APP_DIR]

# Отдельные этапы
./deploy_to_pi.sh build [APP_DIR]    # Сборка Flutter bundle
./deploy_to_pi.sh copy [APP_DIR]     # Копирование на Pi
./deploy_to_pi.sh compile             # Компиляция flutter-pi
./deploy_to_pi.sh run                 # Запуск приложения

# Опции
-d, --debug         # Debug режим с JIT
-s, --skip-build    # Пропустить сборку bundle
--skip-copy         # Пропустить копирование

# Утилиты
./deploy_to_pi.sh setup    # Установка flutter-pi
./deploy_to_pi.sh clean    # Очистка файлов на Pi
```

## Настройка CAN интерфейса

### Виртуальный CAN (для тестирования)
```bash
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

### Реальный CAN
```bash
sudo ip link set can0 type can bitrate 500000
sudo ip link set up can0
```

### Проверка CAN
```bash
# Мониторинг CAN трафика
candump vcan0

# Отправка тестового фрейма
cansend vcan0 7DF#0201050000000000
```

## Режимы работы

### 1. Симулятор (по умолчанию)
- Не требует CAN оборудования
- Генерирует реалистичные данные
- Идеально для разработки и демонстрации

### 2. Реальный CAN
- Требует CAN интерфейс и OBD-II адаптер
- Чтение реальных данных автомобиля
- Поддержка стандартных OBD-II PIDs

### Переключение режимов
```bash
# Симулятор
flutter build bundle --dart-define=USE_SIMULATOR=true

# Реальный CAN
flutter build bundle --dart-define=USE_SIMULATOR=false
```

## Производительность

- **FPS**: 60 FPS на Raspberry Pi 4
- **RAM**: ~150MB использования
- **CPU**: 15-25% загрузка
- **GPU**: Прямой доступ через DRM
- **Latency**: <16ms отклик на CAN события

## Отладка

### Логи flutter-pi
```bash
# На Raspberry Pi
journalctl -f | grep flutter-pi
```

### CAN отладка
```bash
# Мониторинг CAN
candump -t A vcan0

# Статистика интерфейса
ip -details -statistics link show vcan0
```

### Flutter отладка
```bash
# Debug режим с выводом
./deploy_to_pi.sh -d run
```

## Известные проблемы

1. **"icudtl file not found"**
   - Автоматически загружается скриптом
   - Проверьте подключение к интернету

2. **"Could not load flutter engine"**
   - Запустите `./deploy_to_pi.sh setup`
   - Проверьте архитектуру (arm64)

3. **CAN permission denied**
   - Требуются sudo права для can0
   - vcan0 работает без sudo

## Дополнительные ресурсы

- [Flutter-Pi документация](https://github.com/ardera/flutter-pi)
- [SocketCAN документация](https://www.kernel.org/doc/Documentation/networking/can.txt)
- [OBD-II PIDs](https://en.wikipedia.org/wiki/OBD-II_PIDs)
- [Flutter для embedded систем](https://flutter.dev/multi-platform/embedded)

## Лицензия

MIT License - свободное использование в образовательных и коммерческих целях.

## Контакты

Для вопросов и предложений по проекту обращайтесь в Issues на GitHub.