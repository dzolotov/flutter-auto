# 🚗 Automotive Dashboard Deployment Guide

## Flutter-Pi Native CAN Integration

Данное приложение поддерживает работу с реальным CAN bus через SocketCAN на Linux и специально оптимизировано для работы с flutter-pi.

## 🛠 Prerequisites

### Raspberry Pi Setup
```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Flutter-Pi
git clone https://github.com/ardera/flutter-pi
cd flutter-pi
mkdir build && cd build
cmake ..
make -j4
sudo make install

# Установка CAN utilities
sudo apt install -y can-utils

# Установка cross-compiler (если собираете с x64)
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
```

### Hardware CAN Interface
Поддерживаются различные CAN интерфейсы:
- **MCP2515 SPI-CAN** (рекомендуется)
- **USB CAN адаптеры**
- **Встроенные CAN контроллеры**

## 🚀 Build & Deploy

### Автоматический Deploy
```bash
# Сборка и развертывание на Pi
./scripts/build-for-pi.sh pi@raspberrypi.local

# Только сборка (без развертывания)
./scripts/build-for-pi.sh skip
```

### Ручная установка
```bash
# 1. Сборка на хосте
flutter clean
flutter build linux --release --dart-define=USE_REAL_CAN=true

# 2. Сборка нативной библиотеки CAN
cd native/can_interface
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j4

# 3. Копирование на Pi
scp -r build/linux/*/release/bundle/* pi@raspberrypi.local:~/automotive_dashboard/
scp native/can_interface/build/libcan_interface.so pi@raspberrypi.local:~/automotive_dashboard/lib/

# 4. Установка на Pi
ssh pi@raspberrypi.local
cd automotive_dashboard
./install-on-pi.sh
```

## ⚙️ Configuration

### Environment Variables
```bash
# CAN интерфейс (default: can0)
export CAN_INTERFACE=can0

# Включить реальный CAN (vs симуляция)
export USE_REAL_CAN=true

# Скорость CAN (bps)
export CAN_BITRATE=500000

# Debug режим
export DEBUG_CAN=true
```

### Flutter-Pi Configuration
Основная конфигурация в `flutter-pi.json`:
```json
{
  "app_id": "automotive_dashboard",
  "width": 1024,
  "height": 600,
  "fullscreen": true,
  "environment": {
    "CAN_INTERFACE": "can0",
    "USE_REAL_CAN": "true"
  }
}
```

## 🔧 CAN Interface Setup

### MCP2515 (SPI)
```bash
# Добавить в /boot/config.txt
dtoverlay=mcp251xfd,spi0-0,interrupt=25

# Перезагрузка
sudo reboot
```

### Virtual CAN (для тестирования)
```bash
# Создать виртуальный CAN
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Использовать в приложении
export CAN_INTERFACE=vcan0
```

## 🧪 Testing

### CAN Traffic Simulation
```bash
# Генерация OBD-II трафика
cansend can0 7E0#0201050000000000  # Engine temp request
cansend can0 7E8#04410590000000    # Engine temp response (90°C)

cansend can0 7E0#02010C0000000000  # RPM request  
cansend can0 7E8#04410C0FA0000000  # RPM response (4000 RPM)
```

### System Testing
```bash
# Проверка CAN интерфейса
ip link show can0

# Мониторинг CAN трафика
candump can0

# Проверка приложения
sudo systemctl status automotive_dashboard
journalctl -u automotive_dashboard -f
```

## 🔍 Troubleshooting

### CAN Interface Issues
```bash
# Перезапуск CAN интерфейса
sudo ip link set can0 down
sudo ip link set can0 up

# Проверка ошибок
ip -details link show can0

# Проверка модулей ядра
lsmod | grep can
```

### Application Issues
```bash
# Проверка логов
journalctl -u automotive_dashboard -n 100

# Проверка библиотеки
ldconfig -p | grep can_interface

# Ручной запуск для отладки
cd /home/pi/automotive_dashboard
/usr/local/bin/flutter-pi .
```

### Performance Issues
```bash
# Проверка производительности
top -p $(pgrep flutter-pi)

# GPU статистика
cat /sys/kernel/debug/dri/0/clients

# Температура процессора
vcgencmd measure_temp
```

## 🎛 Supported OBD-II PIDs

| PID | Parameter | Unit | Update Rate |
|-----|-----------|------|-------------|
| 0x05 | Engine Temperature | °C | 1 Hz |
| 0x0C | Engine RPM | RPM | 10 Hz |
| 0x0D | Vehicle Speed | km/h | 10 Hz |
| 0x04 | Engine Load | % | 5 Hz |
| 0x10 | MAF Rate | g/s | 5 Hz |
| 0x11 | Throttle Position | % | 10 Hz |
| 0x2F | Fuel Level | % | 1 Hz |

## 🛡 Security Considerations

### CAN Bus Security
- Используйте фильтры CAN для блокировки нежелательных сообщений
- Реализуйте аутентификацию для критических команд
- Мониторьте аномальный трафик

```bash
# Настройка базовых фильтров CAN
# Только OBD-II трафик (7E0-7E7, 7E8-7EF)
sudo ip link set can0 down
echo "can0 7E0:7F0" > /etc/can_filters
sudo ip link set can0 up
```

### System Security
```bash
# Ограничения пользователя pi
sudo usermod -a -G dialout pi
sudo usermod -r -G sudo pi  # Убрать sudo права

# Запрет SSH root
echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart ssh
```

## 📊 Monitoring & Logging

### System Monitoring
```bash
# Установка monitoring
sudo apt install -y prometheus-node-exporter

# Custom CAN metrics
echo "can_messages_total $(cat /sys/class/net/can0/statistics/tx_packets)" > /var/lib/node_exporter/textfile_collector/can.prom
```

### Log Rotation
```bash
# CAN логи
sudo tee /etc/logrotate.d/can << EOF
/tmp/can-logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```

## 🔄 Auto-Update System
```bash
# Создать update script
cat > ~/update-dashboard.sh << 'EOF'
#!/bin/bash
cd ~/automotive_dashboard
git pull
./build-for-pi.sh $(hostname -I | awk '{print $1}')
sudo systemctl restart automotive_dashboard
EOF

chmod +x ~/update-dashboard.sh

# Cron job для автообновления (опционально)
# echo "0 2 * * * /home/pi/update-dashboard.sh" | crontab -
```

## 📱 Remote Access

### VNC для удаленного доступа
```bash
sudo apt install -y realvnc-vnc-server
sudo systemctl enable vncserver-x11-serviced
sudo raspi-config  # Enable VNC in Interface Options
```

### SSH Tunneling
```bash
# Туннель для отладки
ssh -L 5900:localhost:5900 pi@raspberrypi.local
```

## 🎯 Production Checklist

- [ ] CAN интерфейс настроен и работает
- [ ] Приложение собрано с правильными параметрами
- [ ] Systemd сервис создан и активен
- [ ] Логирование настроено
- [ ] Мониторинг производительности включен
- [ ] Security настройки применены
- [ ] Auto-start на загрузке работает
- [ ] Fallback на симуляцию при ошибках CAN
- [ ] Watchdog для автоперезапуска настроен

---

🎉 **Ready for Production Automotive Dashboard!**

Для поддержки: создайте issue в репозитории или обратитесь к документации Flutter-Pi.