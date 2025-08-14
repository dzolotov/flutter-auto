#!/bin/bash

################################################################################
# Flutter-Pi Deploy Script
# 
# Полный скрипт для развертывания Flutter приложений на Raspberry Pi
# с использованием flutter-pi
#
# Возможности:
# - Автоматическая загрузка Flutter Engine для ARM64
# - Сборка и установка flutter-pi с плагинами
# - Сборка Flutter приложения в debug/release режиме
# - Развертывание и запуск на Raspberry Pi
#
# Использование:
#   ./flutter-pi-deploy.sh [options] <project_path>
#
# Опции:
#   --host <ip>        IP адрес Raspberry Pi (по умолчанию: 192.168.1.199)
#   --user <user>      Пользователь SSH (по умолчанию: pi)
#   --release          Сборка в release режиме
#   --clean            Полная очистка и пересборка
#   --skip-engine      Пропустить загрузку Flutter Engine
#   --skip-flutter-pi  Пропустить сборку flutter-pi
#   --monitor          Показать логи после запуска
#
################################################################################

set -e

# Обработчик ошибок для диагностики
trap 'on_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "%s " "${FUNCNAME[@]}")' ERR

on_error() {
    local exit_code=$1
    local line_no=$2
    local bash_line_no=$3
    local last_command=$4
    local function_stack=$5
    
    echo ""
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║         ОШИБКА ВЫПОЛНЕНИЯ СКРИПТА       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}Код ошибки:${NC} $exit_code"
    echo -e "${RED}Строка:${NC} $line_no"
    echo -e "${RED}Команда:${NC} $last_command"
    echo -e "${RED}Функции:${NC} $function_stack"
    echo ""
    echo -e "${YELLOW}Детальные логи:${NC}"
    echo "tail -20 /tmp/flutter-pi-deploy.log"
    echo ""
    echo -e "${YELLOW}Для диагностики на Pi:${NC}"
    echo "ssh $PI_USER@$PI_HOST 'dmesg | tail -20'"
    echo "ssh $PI_USER@$PI_HOST 'journalctl -u flutter-pi --no-pager -n 20'"
    echo ""
    
    # Записываем в лог
    {
        echo "[$(date)] FATAL ERROR:"
        echo "  Exit code: $exit_code"
        echo "  Line: $line_no"
        echo "  Command: $last_command"
        echo "  Function stack: $function_stack"
    } >> "/tmp/flutter-pi-deploy.log"
}

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Конфигурация по умолчанию
PI_HOST="192.168.1.199"
PI_USER="pi"
BUILD_MODE="debug"  # По умолчанию debug для быстрой разработки
CLEAN_BUILD=false
SKIP_ENGINE=false
SKIP_FLUTTER_PI=false
MONITOR_LOGS=false
PROJECT_PATH=""

# Пути на Pi
PI_HOME="/home/${PI_USER}"
PI_FLUTTER_ENGINE_DIR="${PI_HOME}/flutter-engine"
PI_FLUTTER_PI_DIR="${PI_HOME}/flutter-pi"
PI_FLUTTER_PI_BUILD_DIR="${PI_HOME}/flutter-pi-build"
PI_APPS_DIR="${PI_HOME}/flutter-apps"

# URLs для загрузки
FLUTTER_ENGINE_URL="https://github.com/ardera/flutter-engine-binaries-for-arm/releases/latest/download"
FLUTTER_PI_REPO="https://github.com/ardera/flutter-pi.git"

# Локальные пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_PI_SRC_DIR="${SCRIPT_DIR}/flutter-pi-src"

################################################################################
# Функции вывода
################################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "[$(date)] ERROR: $1" >> "/tmp/flutter-pi-deploy.log"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}==>${NC} $1"
    echo "[$(date)] STEP: $1" >> "/tmp/flutter-pi-deploy.log"
}

log_success() {
    echo -e "${CYAN}✓${NC} $1"
}

################################################################################
# Парсинг аргументов
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --host)
                PI_HOST="$2"
                shift 2
                ;;
            --user)
                PI_USER="$2"
                shift 2
                ;;
            --release)
                BUILD_MODE="release"
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --skip-engine)
                SKIP_ENGINE=true
                shift
                ;;
            --skip-flutter-pi)
                SKIP_FLUTTER_PI=true
                shift
                ;;
            --monitor)
                MONITOR_LOGS=true
                shift
                ;;
            all)
                # Команда "all" - выполнить полное развертывание
                if [ -z "$PROJECT_PATH" ]; then
                    PROJECT_PATH="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                log_error "Неизвестная опция: $1"
                show_help
                exit 1
                ;;
            *)
                PROJECT_PATH="$1"
                shift
                ;;
        esac
    done

    # Проверка обязательных параметров
    if [ -z "$PROJECT_PATH" ]; then
        log_error "Не указан путь к проекту"
        show_help
        exit 1
    fi

    # Проверка существования проекта
    if [ ! -d "$PROJECT_PATH" ]; then
        log_error "Директория проекта не найдена: $PROJECT_PATH"
        exit 1
    fi

    if [ ! -f "$PROJECT_PATH/pubspec.yaml" ]; then
        log_error "Файл pubspec.yaml не найден. Убедитесь, что это Flutter проект."
        exit 1
    fi

    # Если путь это ".", используем имя текущей директории
    if [ "$PROJECT_PATH" = "." ]; then
        PROJECT_PATH="$(pwd)"
    fi
    
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    SSH_HOST="${PI_USER}@${PI_HOST}"

    log_info "Конфигурация:"
    log_info "  Проект: $PROJECT_NAME ($PROJECT_PATH)"
    log_info "  Raspberry Pi: $SSH_HOST"
    log_info "  Режим сборки: $BUILD_MODE"
}

show_help() {
    cat << EOF
Flutter-Pi Deploy Script

Использование:
  $0 [options] <project_path>
  $0 [options] all <project_path>

Команды:
  all                Выполнить полное развертывание (все этапы)

Опции:
  --host <ip>        IP адрес Raspberry Pi (по умолчанию: 192.168.1.199)
  --user <user>      Пользователь SSH (по умолчанию: pi)
  --release          Сборка в release режиме (требует дополнительной настройки)
  --clean            Полная очистка и пересборка
  --skip-engine      Пропустить загрузку Flutter Engine
  --skip-flutter-pi  Пропустить сборку flutter-pi
  --monitor          Показать логи после запуска
  -h, --help         Показать эту справку

Примеры:
  $0 ./my_app                          # Debug сборка (по умолчанию) и запуск
  $0 --release ./my_app                # Release сборка (будет использован debug)
  $0 --host 192.168.1.100 ./my_app    # Другой IP адрес Pi
  $0 --clean --monitor ./my_app        # Полная пересборка с логами
  $0 --skip-engine ./my_app            # Быстрый деплой без загрузки engine

EOF
}

################################################################################
# Проверка SSH соединения
################################################################################

check_ssh_connection() {
    log_step "Проверка SSH соединения с Raspberry Pi"
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_HOST" "echo 'SSH OK'" &>/dev/null; then
        log_success "SSH соединение установлено"
    else
        log_error "Не удается подключиться к $SSH_HOST"
        log_info "Проверьте:"
        log_info "  1. Raspberry Pi включен и подключен к сети"
        log_info "  2. IP адрес правильный (--host <ip>)"
        log_info "  3. SSH настроен для беспарольного входа"
        exit 1
    fi
}

################################################################################
# Установка зависимостей на Pi
################################################################################

install_pi_dependencies() {
    log_step "Установка зависимостей на Raspberry Pi"
    
    ssh "$SSH_HOST" << 'ENDSSH'
        set -e
        
        # Список необходимых пакетов
        PACKAGES="cmake git build-essential pkg-config"
        PACKAGES="$PACKAGES libgl1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev"
        PACKAGES="$PACKAGES libdrm-dev libgbm-dev libsystemd-dev"
        PACKAGES="$PACKAGES libudev-dev libinput-dev libxkbcommon-dev"
        PACKAGES="$PACKAGES fonts-noto-color-emoji fonts-noto-cjk"
        
        # Пакеты для CAN интерфейса
        PACKAGES="$PACKAGES can-utils python3-can"
        
        # Пакеты для GStreamer (аудио/видео)
        PACKAGES="$PACKAGES gstreamer1.0-tools gstreamer1.0-plugins-base"
        PACKAGES="$PACKAGES gstreamer1.0-plugins-good gstreamer1.0-plugins-bad"
        PACKAGES="$PACKAGES gstreamer1.0-plugins-ugly gstreamer1.0-alsa"
        PACKAGES="$PACKAGES gstreamer1.0-pulseaudio libgstreamer1.0-dev"
        PACKAGES="$PACKAGES libgstreamer-plugins-base1.0-dev"
        
        # Проверка и установка пакетов
        NEED_INSTALL=""
        for pkg in $PACKAGES; do
            if ! dpkg -l | grep -q "^ii  $pkg"; then
                NEED_INSTALL="$NEED_INSTALL $pkg"
            fi
        done
        
        if [ -n "$NEED_INSTALL" ]; then
            echo "Установка пакетов:$NEED_INSTALL"
            apt-get update
            apt-get install -y $NEED_INSTALL
        else
            echo "Все зависимости уже установлены"
        fi
        
        # Настройка модулей ядра для CAN
        echo "Настройка CAN интерфейса..."
        
        # Загрузка модулей
        if ! lsmod | grep -q "^vcan"; then
            echo "Загрузка модуля vcan..."
            modprobe vcan
        fi
        
        if ! lsmod | grep -q "^can"; then
            echo "Загрузка модуля can..."
            modprobe can
        fi
        
        if ! lsmod | grep -q "^can_raw"; then
            echo "Загрузка модуля can-raw..."
            modprobe can-raw
        fi
        
        # Добавление модулей в автозагрузку
        if ! grep -q "^vcan" /etc/modules 2>/dev/null; then
            echo "vcan" | tee -a /etc/modules > /dev/null
        fi
        
        if ! grep -q "^can" /etc/modules 2>/dev/null; then
            echo "can" | tee -a /etc/modules > /dev/null
        fi
        
        if ! grep -q "^can-raw" /etc/modules 2>/dev/null; then
            echo "can-raw" | tee -a /etc/modules > /dev/null
        fi
        
        # Создание и настройка vcan0 интерфейса
        if ! ip link show vcan0 &>/dev/null; then
            echo "Создание виртуального CAN интерфейса vcan0..."
            ip link add dev vcan0 type vcan
            ip link set up vcan0
        else
            # Проверяем, что интерфейс поднят
            if ! ip link show vcan0 | grep -q "UP"; then
                echo "Поднимаем интерфейс vcan0..."
                ip link set up vcan0
            fi
        fi
        
        echo "CAN интерфейс настроен"
        
        # Создание systemd сервиса для автоматического поднятия vcan0
        if [ ! -f /etc/systemd/system/setup-vcan.service ]; then
            echo "Создание systemd сервиса для vcan0..."
            tee /etc/systemd/system/setup-vcan.service > /dev/null << 'ENDSERVICE'
[Unit]
Description=Setup Virtual CAN Interface
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ip link add dev vcan0 type vcan
ExecStart=/sbin/ip link set up vcan0
ExecStop=/sbin/ip link set down vcan0
ExecStop=/sbin/ip link delete vcan0

[Install]
WantedBy=multi-user.target
ENDSERVICE
            
            systemctl daemon-reload
            systemctl enable setup-vcan.service
            echo "Systemd сервис для vcan0 создан и включен"
        fi
ENDSSH
    
    log_success "Зависимости установлены"
}

################################################################################
# Загрузка Flutter Engine
################################################################################

download_flutter_engine() {
    if [ "$SKIP_ENGINE" = true ]; then
        log_step "Пропуск загрузки Flutter Engine"
        return
    fi
    
    log_step "Загрузка Flutter Engine для ARM64"
    
    # Получаем версию Flutter
    FLUTTER_VERSION=$(flutter --version | grep '^Flutter' | awk '{print $2}')
    ENGINE_VERSION=$(flutter --version | grep 'Engine' | sed 's/.*revision \([a-f0-9]*\).*/\1/')
    
    log_info "Flutter версия: $FLUTTER_VERSION"
    log_info "Engine версия: $ENGINE_VERSION"
    
    # Проверяем, нужно ли загружать Engine (выносим проверку из SSH)
    ENGINE_CHECK_RESULT=$(ssh "$SSH_HOST" << ENDSSH
        if [ -f "$PI_FLUTTER_ENGINE_DIR/libflutter_engine.so" ] && [ -f "$PI_FLUTTER_ENGINE_DIR/icudtl.dat" ] && [ -f "$PI_FLUTTER_ENGINE_DIR/.version" ]; then
            CURRENT_VERSION=\$(cat "$PI_FLUTTER_ENGINE_DIR/.version")
            if [ "\$CURRENT_VERSION" = "$ENGINE_VERSION" ]; then
                echo "ALREADY_INSTALLED"
            else
                echo "VERSION_MISMATCH"
            fi
        else
            echo "NOT_INSTALLED"
        fi
ENDSSH
)
    
    if [ "$ENGINE_CHECK_RESULT" = "ALREADY_INSTALLED" ]; then
        log_success "Flutter Engine $ENGINE_VERSION уже установлен"
        return
    fi
    
    if ! ssh "$SSH_HOST" << ENDSSH
        set -e
        
        # Создаем директорию для engine
        mkdir -p "$PI_FLUTTER_ENGINE_DIR"
        cd "$PI_FLUTTER_ENGINE_DIR"
        
        echo "Загрузка Flutter Engine..."
        
        # Определяем режим
        if [ "$BUILD_MODE" = "release" ]; then
            ENGINE_MODE="release"
        else
            ENGINE_MODE="debug"
        fi
        
        # Клонируем репозиторий с бинарниками
        echo "Загрузка Flutter Engine из репозитория ardera..."
        if [ ! -d "engine-binaries" ]; then
            git clone --depth 1 https://github.com/ardera/flutter-engine-binaries-for-arm.git engine-binaries
        else
            cd engine-binaries
            git pull
            cd ..
        fi
        
        # Копируем нужные файлы
        echo "Копирование файлов для arm64 (\${ENGINE_MODE})..."
        if [ -f "engine-binaries/arm64/libflutter_engine.so.\${ENGINE_MODE}" ]; then
            cp "engine-binaries/arm64/libflutter_engine.so.\${ENGINE_MODE}" libflutter_engine.so
            cp engine-binaries/arm64/icudtl.dat .
        else
            echo "ERROR: libflutter_engine.so.\${ENGINE_MODE} не найден в репозитории"
            exit 1
        fi
        
        # Копируем в системные директории
        sudo cp libflutter_engine.so /usr/local/lib/
        sudo cp icudtl.dat /usr/local/share/
        sudo ldconfig
        
        # Сохраняем версию
        echo "$ENGINE_VERSION" > .version
        
        # Очистка
        rm -f *.tar.xz
        
        echo "Flutter Engine установлен успешно"
ENDSSH
    then
        log_error "Ошибка установки Flutter Engine"
        exit 1
    fi
    
    log_success "Flutter Engine загружен и установлен"
}

################################################################################
# Сборка flutter-pi
################################################################################

build_flutter_pi() {
    if [ "$SKIP_FLUTTER_PI" = true ]; then
        log_step "Пропуск сборки flutter-pi"
        return
    fi
    
    log_step "Подготовка и сборка flutter-pi"
    
    # Проверяем наличие исходников локально
    if [ ! -d "$FLUTTER_PI_SRC_DIR" ]; then
        log_info "Клонирование flutter-pi репозитория..."
        git clone "$FLUTTER_PI_REPO" "$FLUTTER_PI_SRC_DIR"
    fi
    
    # Добавляем automotive плагин если есть
    if [ -f "$FLUTTER_PI_SRC_DIR/src/plugins/automotive_plugin.c" ]; then
        log_info "Automotive плагин найден"
        # Проверяем, добавлен ли в CMakeLists.txt
        if ! grep -q "automotive_plugin.c" "$FLUTTER_PI_SRC_DIR/CMakeLists.txt"; then
            log_info "Добавляем automotive плагин в сборку..."
            sed -i.bak '/src\/plugins\/services.c/a\
  src/plugins/automotive_plugin.c' "$FLUTTER_PI_SRC_DIR/CMakeLists.txt"
        fi
    fi
    
    # Отправляем исходники на Pi
    log_info "Отправка исходников на Raspberry Pi..."
    rsync -az --delete \
        --exclude '.git' \
        --exclude 'build' \
        "$FLUTTER_PI_SRC_DIR/" "$SSH_HOST:$PI_FLUTTER_PI_DIR/"
    
    # Сборка на Pi
    log_info "Сборка flutter-pi на Raspberry Pi..."
    ssh "$SSH_HOST" << ENDSSH
        set -e
        
        # Создаем директорию для сборки
        mkdir -p "$PI_FLUTTER_PI_BUILD_DIR"
        cd "$PI_FLUTTER_PI_BUILD_DIR"
        
        # Очистка если нужно
        if [ "$CLEAN_BUILD" = true ]; then
            echo "Очистка предыдущей сборки..."
            rm -rf CMakeCache.txt CMakeFiles
        fi
        
        # Конфигурируем CMake
        echo "Конфигурирование CMake..."
        cmake "$PI_FLUTTER_PI_DIR" \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_FLUTTER_PI=ON \
            -DBUILD_PLUGINS=ON
        
        # Компиляция
        echo "Компиляция flutter-pi..."
        make -j\$(nproc)
        
        # Установка
        echo "Установка flutter-pi..."
        sudo make install
        
        # Проверка
        if command -v flutter-pi &> /dev/null; then
            echo "flutter-pi успешно установлен"
            flutter-pi --help | head -5
        else
            echo "Ошибка: flutter-pi не найден после установки"
            exit 1
        fi
ENDSSH
    
    log_success "flutter-pi собран и установлен"
}

################################################################################
# Сборка Flutter приложения
################################################################################

build_flutter_app() {
    log_step "Сборка Flutter приложения ($BUILD_MODE)"
    
    cd "$PROJECT_PATH"
    
    # Получаем зависимости
    log_info "Получение зависимостей..."
    flutter pub get
    
    # Очистка предыдущей сборки если нужно
    if [ "$CLEAN_BUILD" = true ]; then
        log_info "Очистка предыдущей сборки..."
        flutter clean
    fi
    
    # Создаем bundle
    if [ "$BUILD_MODE" = "release" ]; then
        log_warning "Release режим требует предварительной сборки app.so для ARM64"
        log_warning "Используйте debug режим для быстрой разработки"
        log_info "Для полноценного release режима требуется:"
        log_info "  1. Flutter SDK с gen_snapshot для linux-arm64"
        log_info "  2. Кросс-компиляция AOT snapshot"
        log_info ""
        log_info "Продолжаем сборку в режиме JIT (debug)..."
        BUILD_MODE="debug"
    fi
    
    log_info "Сборка debug bundle (JIT режим)..."
    flutter build bundle \
        --debug \
        --target=lib/main.dart \
        --depfile=build/flutter_bundle.d \
        --asset-dir=build/flutter_assets
    
    # Проверяем результат
    if [ ! -d "build/flutter_assets" ]; then
        log_error "Сборка Flutter bundle не удалась"
        exit 1
    fi
    
    if [ "$BUILD_MODE" = "debug" ] && [ ! -f "build/flutter_assets/kernel_blob.bin" ]; then
        log_warning "kernel_blob.bin не найден, создаем..."
        flutter build bundle --debug
    fi
    
    log_success "Flutter приложение собрано"
}

################################################################################
# Развертывание на Pi
################################################################################

deploy_to_pi() {
    log_step "Развертывание приложения на Raspberry Pi"
    
    # Мы уже в директории проекта после build_flutter_app
    # cd "$PROJECT_PATH"
    
    # Создаем директорию для приложения
    ssh "$SSH_HOST" "mkdir -p '$PI_APPS_DIR/$PROJECT_NAME'"
    
    # Копируем bundle
    log_info "Отправка Flutter bundle..."
    rsync -az --delete \
        "build/flutter_assets/" \
        "$SSH_HOST:$PI_APPS_DIR/$PROJECT_NAME/"
    
    # Копируем icudtl.dat ОБЯЗАТЕЛЬНО
    if ! ssh "$SSH_HOST" << ENDSSH
        set -e
        cd "$PI_APPS_DIR/$PROJECT_NAME"
        
        echo "Проверка и копирование icudtl.dat..."
        if [ -f "/usr/local/share/icudtl.dat" ]; then
            cp -f /usr/local/share/icudtl.dat .
        elif [ -f "$PI_FLUTTER_ENGINE_DIR/icudtl.dat" ]; then
            cp -f "$PI_FLUTTER_ENGINE_DIR/icudtl.dat" .
        else
            echo "Загрузка icudtl.dat с GitHub..."
            wget -q -O icudtl.dat \
                "https://github.com/ardera/flutter-engine-binaries-for-arm/raw/main/arm64/icudtl.dat" || {
                echo "ERROR: Не удалось загрузить icudtl.dat!"
                exit 1
            }
        fi
        
        # Для release режима нужен app.so
        if [ "$BUILD_MODE" = "release" ] && [ ! -f "app.so" ]; then
            echo "WARNING: app.so не найден для release режима"
            echo "Приложение будет запущено в debug режиме"
        fi
        
        echo "Файлы приложения:"
        ls -lh
ENDSSH
    then
        log_error "Ошибка при подготовке файлов приложения"
        exit 1
    fi
    
    log_success "Приложение развернуто"
}

################################################################################
# Запуск приложения
################################################################################

copy_obd_simulator() {
    log_step "Копирование физического OBD симулятора"
    
    # Проверяем наличие физического симулятора на Pi
    ssh "$SSH_HOST" "ls -la ~/physics_obd_sim.py 2>/dev/null" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_success "Физический OBD симулятор найден на Pi"
    else
        # Копируем физический симулятор из проекта
        if [ -f "$SCRIPT_DIR/python_can_simulator/physics_obd_sim.py" ]; then
            log_info "Копируем физический OBD симулятор на Pi..."
            scp "$SCRIPT_DIR/python_can_simulator/physics_obd_sim.py" "$SSH_HOST:~/physics_obd_sim.py"
            log_success "Физический OBD симулятор скопирован"
        else
            log_warning "Физический OBD симулятор не найден в проекте"
        fi
    fi
}

run_application() {
    log_step "Запуск Flutter приложения"
    
    # Отладка путей сразу после начала функции
    echo "DEBUG: PI_APPS_DIR = $PI_APPS_DIR"
    echo "DEBUG: PROJECT_NAME = $PROJECT_NAME"
    echo "DEBUG: Полный путь = $PI_APPS_DIR/$PROJECT_NAME"
    echo "DEBUG: SSH_HOST = $SSH_HOST"
    
    # Останавливаем предыдущий экземпляр и симулятор
    ssh "$SSH_HOST" "pkill flutter-pi || true" 2>/dev/null || true
    ssh "$SSH_HOST" "pkill -f obd_sim.py || true" 2>/dev/null || true
    sleep 1
    
    # Запускаем OBD симулятор если есть vcan0
    log_info "Проверка и запуск OBD симулятора..."
    ssh "$SSH_HOST" << 'EOF'
if ip link show vcan0 &>/dev/null; then
    # Останавливаем предыдущий симулятор
    pkill -f obd_sim.py || true
    sleep 1
    
    # Проверяем наличие физического симулятора
    if [ -f ~/physics_obd_sim.py ]; then
        echo "Запуск физического OBD симулятора на vcan0..."
        # Останавливаем старые симуляторы если запущены
        pkill -f 'physics_obd_sim.py' 2>/dev/null || true
        
        # Запускаем физический симулятор в фоне
        nohup python3 ~/physics_obd_sim.py > ~/physics_sim.log 2>&1 &
        SIM_PID=$!
        
        # Даем время на запуск
        sleep 2
        
        # Проверяем что процесс запустился
        if kill -0 $SIM_PID 2>/dev/null; then
            echo "✓ Физический OBD симулятор запущен (PID: $SIM_PID)"
            echo "  Логи: ~/physics_sim.log"
        else
            echo "✗ Ошибка запуска физического симулятора"
            echo "  Проверьте логи: ~/physics_sim.log"
            tail -10 ~/physics_sim.log 2>/dev/null || true
        fi
    else
        echo "Предупреждение: Физический OBD симулятор не найден"
        echo "  Приложение будет работать без CAN данных"
    fi
else
    echo "Предупреждение: Интерфейс vcan0 не найден"
fi
EOF
    
    # Проверяем необходимые файлы перед запуском
    log_info "Проверка необходимых файлов..."
    if ! ssh "$SSH_HOST" "cd $PI_APPS_DIR/$PROJECT_NAME && [ -f icudtl.dat ] && ([ -f kernel_blob.bin ] || [ -f app.so ]) && command -v flutter-pi >/dev/null && [ -f /usr/local/lib/libflutter_engine.so ]"; then
        log_error "Проверка файлов не прошла"
        exit 1
    fi
    log_info "Все необходимые файлы найдены"
    
    # Определяем параметры запуска
    FLUTTER_PI_ARGS=""  # По умолчанию debug режим (без флага)
    
    if [ "$BUILD_MODE" = "release" ] && ssh "$SSH_HOST" "[ -f '$PI_APPS_DIR/$PROJECT_NAME/app.so' ]"; then
        FLUTTER_PI_ARGS="--release"
    fi
    
    # Добавляем параметры для стабильности
    FLUTTER_PI_ARGS="$FLUTTER_PI_ARGS --orientation landscape_right --pixelformat ARGB8888"
    
    # Запускаем flutter-pi
    log_info "Запуск flutter-pi с параметрами: $FLUTTER_PI_ARGS"
    echo "DEBUG: PI_APPS_DIR = $PI_APPS_DIR"
    echo "DEBUG: PROJECT_NAME = $PROJECT_NAME"
    echo "DEBUG: Полный путь = $PI_APPS_DIR/$PROJECT_NAME"
    
    if [ "$MONITOR_LOGS" = true ]; then
        # Запуск с отслеживанием логов
        log_info "Запуск с мониторингом логов (Ctrl+C для выхода)..."
        if ! ssh -t "$SSH_HOST" "cd $PI_APPS_DIR/$PROJECT_NAME && flutter-pi $FLUTTER_PI_ARGS ."; then
            log_error "flutter-pi завершился с ошибкой (код: $?)"
            log_info "Для диагностики используйте: ssh $PI_USER@$PI_HOST 'dmesg | tail -20'"
            exit 1
        fi
    else
        # Запуск в фоне с улучшенной диагностикой
        log_info "Запуск приложения в фоне..."
        
        # Создаем детальный скрипт запуска
        ssh "$SSH_HOST" << ENDSSH
            cd "$PI_APPS_DIR/$PROJECT_NAME"
            
            # Создаем скрипт запуска с детальным логированием
            cat > run_flutter.sh << ENDSCRIPT
#!/bin/bash
set -e
cd "$PI_APPS_DIR/$PROJECT_NAME"

echo "=== Flutter-Pi Launch Log ===" > flutter-app.log
echo "Date: \$(date)" >> flutter-app.log
echo "Working directory: \$(pwd)" >> flutter-app.log
echo "Files in directory:" >> flutter-app.log
ls -la >> flutter-app.log
echo "" >> flutter-app.log

echo "=== System Info ===" >> flutter-app.log
uname -a >> flutter-app.log
echo "Display: \$DISPLAY" >> flutter-app.log
echo "User: \$(whoami)" >> flutter-app.log
echo "" >> flutter-app.log

echo "=== Environment Check ===" >> flutter-app.log
if command -v flutter-pi &> /dev/null; then
    echo "flutter-pi found: \$(which flutter-pi)" >> flutter-app.log
    flutter-pi --help 2>&1 | head -5 >> flutter-app.log
else
    echo "ERROR: flutter-pi not found!" >> flutter-app.log
fi
echo "" >> flutter-app.log

echo "=== Starting Application ===" >> flutter-app.log
echo "Command: flutter-pi $FLUTTER_PI_ARGS ." >> flutter-app.log
echo "" >> flutter-app.log

exec flutter-pi $FLUTTER_PI_ARGS . >> flutter-app.log 2>&1
ENDSCRIPT

            chmod +x run_flutter.sh
            nohup ./run_flutter.sh &
ENDSSH
        
        sleep 5
        
        # Показываем статус и логи
        ssh "$SSH_HOST" << EOF
if pgrep -f flutter-pi > /dev/null; then
    echo "✓ Flutter приложение запущено (PID: \$(pgrep -f flutter-pi))"
    echo ""
    echo "Последние логи:"
    tail -30 "$PI_APPS_DIR/$PROJECT_NAME/flutter-app.log" 2>/dev/null || echo "Логи недоступны"
    echo ""
    echo "Для просмотра логов: ssh $PI_USER@$PI_HOST 'tail -f $PI_APPS_DIR/$PROJECT_NAME/flutter-app.log'"
    echo "Для остановки: ssh $PI_USER@$PI_HOST 'pkill flutter-pi'"
else
    echo "✗ Ошибка: Flutter приложение не запустилось"
    echo ""
    echo "Логи ошибки:"
    cat "$PI_APPS_DIR/$PROJECT_NAME/flutter-app.log" 2>/dev/null || echo "Лог файл недоступен"
    echo ""
    echo "Дополнительная диагностика:"
    dmesg | tail -10
    exit 1
fi
EOF
    fi
    
    log_success "Приложение запущено"
}

################################################################################
# Основная функция
################################################################################

main() {
    # Инициализация лог файла
    echo "[$(date)] Flutter-Pi Deploy Script v2.0 started" > "/tmp/flutter-pi-deploy.log"
    echo "[$(date)] Arguments: $*" >> "/tmp/flutter-pi-deploy.log"
    
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    Flutter-Pi Deploy Script v2.0       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    log_info "Детальные логи записываются в /tmp/flutter-pi-deploy.log"
    
    # Парсинг аргументов
    parse_arguments "$@"
    
    # Проверка SSH
    check_ssh_connection
    
    # Установка зависимостей
    install_pi_dependencies
    
    # Загрузка Flutter Engine
    download_flutter_engine
    
    # Сборка flutter-pi
    build_flutter_pi
    
    # Сборка приложения
    build_flutter_app
    
    # Развертывание
    deploy_to_pi
    
    # Копирование OBD симулятора
    copy_obd_simulator
    
    # Запуск
    run_application
    
    echo ""
    log_success "Развертывание успешно завершено!"
}

# Запуск основной функции с переданными аргументами
main "$@"