#\!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Физический симулятор CAN шины с реалистичной моделью автомобиля
Использует настоящую физику для симуляции движения
"""

import time
import math
import struct
import logging
import threading
import can
from can.interface import Bus
import signal
import sys
from dataclasses import dataclass
from enum import IntEnum, Enum


# OBD-II константы
class PID(IntEnum):
    ENGINE_LOAD = 0x04
    ENGINE_COOLANT_TEMP = 0x05
    ENGINE_RPM = 0x0C
    VEHICLE_SPEED = 0x0D
    THROTTLE_POSITION = 0x11
    FUEL_LEVEL = 0x2F
    ODOMETER = 0x31  # Distance since codes cleared (можно использовать как одометр)


class DrivingPhase(Enum):
    CITY_1 = "city_1"           # 3 минуты город
    TRAFFIC_LIGHT_1 = "light_1"  # 30 сек светофор
    CITY_2 = "city_2"           # 3 минуты город  
    TRAFFIC_LIGHT_2 = "light_2"  # 30 сек светофор
    HIGHWAY = "highway"         # 5 минут трасса
    PARKING = "parking"         # 1 минута стоянка


@dataclass
class PhysicsState:
    """Физическое состояние автомобиля"""
    # Основные параметры
    speed: float = 0.0           # км/ч
    acceleration: float = 0.0    # м/с²
    rpm: float = 800.0           # об/мин
    throttle: float = 0.0        # 0-100%
    brake: float = 0.0           # 0-100%
    gear: int = 1                # 1-6
    
    # Температуры
    engine_temp: float = 20.0    # °C (холодный старт)
    
    # Топливо
    fuel_level: float = 75.0     # %
    odometer: float = 12345.6    # км - пробег автомобиля
    
    # Физические константы автомобиля
    mass: float = 1500.0         # кг
    drag_coefficient: float = 0.3
    frontal_area: float = 2.2    # м²
    max_power: float = 150.0     # кВт
    max_torque: float = 350.0    # Нм


class PhysicsSimulator:
    def __init__(self, interface='vcan0'):
        self.state = PhysicsState()
        self.running = False
        self.bus = None
        self.interface = interface
        
        # Время для физики
        self.last_update = time.time()
        self.target_throttle = 0.0
        self.target_speed = 0.0  # Целевая скорость для круиз-контроля
        
        # Логирование
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        # Сценарий движения
        self.phase = DrivingPhase.CITY_1
        self.phase_start_time = time.time()
        self.phase_durations = {
            DrivingPhase.CITY_1: 180,          # 3 минуты
            DrivingPhase.TRAFFIC_LIGHT_1: 30,  # 30 секунд
            DrivingPhase.CITY_2: 180,          # 3 минуты
            DrivingPhase.TRAFFIC_LIGHT_2: 30,  # 30 секунд
            DrivingPhase.HIGHWAY: 300,         # 5 минут
            DrivingPhase.PARKING: 60           # 1 минута
        }
        
    def start(self):
        """Запуск симулятора"""
        try:
            self.bus = can.interface.Bus(channel=self.interface, bustype='socketcan')
            self.logger.info(f"Подключен к {self.interface}")
        except Exception as e:
            self.logger.error(f"Ошибка подключения к CAN: {e}")
            return False
            
        self.running = True
        
        # Поток физики
        self.physics_thread = threading.Thread(target=self._physics_loop)
        self.physics_thread.start()
        
        # Поток обработки CAN
        self.can_thread = threading.Thread(target=self._can_loop)
        self.can_thread.start()
        
        return True
        
    def stop(self):
        """Остановка симулятора"""
        self.running = False
        if self.physics_thread:
            self.physics_thread.join()
        if self.can_thread:
            self.can_thread.join()
        if self.bus:
            self.bus.shutdown()
            
    def _physics_loop(self):
        """Основной цикл физической симуляции"""
        while self.running:
            current_time = time.time()
            dt = current_time - self.last_update
            self.last_update = current_time
            
            # Обновляем фазу движения
            self._update_phase()
            
            # Обновляем сценарий
            self._update_scenario(dt)
            
            # Обновляем физику
            self._update_physics(dt)
            
            # Обновляем температуру
            self._update_temperature(dt)
            
            # Спим для 100 Hz обновления
            time.sleep(0.01)
            
    def _update_phase(self):
        """Обновление фазы движения"""
        current_time = time.time()
        phase_elapsed = current_time - self.phase_start_time
        
        if phase_elapsed > self.phase_durations[self.phase]:
            # Переход к следующей фазе
            phases = list(DrivingPhase)
            current_index = phases.index(self.phase)
            next_index = (current_index + 1) % len(phases)
            self.phase = phases[next_index]
            self.phase_start_time = current_time
            self.logger.info(f"Переход к фазе: {self.phase.value}")
            
    def _update_scenario(self, dt):
        """Сценарий движения в зависимости от фазы"""
        phase_time = time.time() - self.phase_start_time
        
        if self.phase == DrivingPhase.CITY_1 or self.phase == DrivingPhase.CITY_2:
            # Городское движение - 50 км/ч с вариациями
            self.target_speed = 50 + 10 * math.sin(phase_time * 0.1)  # 40-60 км/ч
            
            # Имитация светофоров и поворотов
            if int(phase_time) % 30 < 5:  # Каждые 30 сек притормаживаем на 5 сек
                self.target_speed = 20
                
        elif self.phase == DrivingPhase.TRAFFIC_LIGHT_1 or self.phase == DrivingPhase.TRAFFIC_LIGHT_2:
            # Светофор - остановка и разгон
            if phase_time < 10:
                # Торможение до остановки
                self.target_speed = max(0, 50 - phase_time * 5)
            elif phase_time < 20:
                # Стоим
                self.target_speed = 0
            else:
                # Разгон
                self.target_speed = min(50, (phase_time - 20) * 5)
                
        elif self.phase == DrivingPhase.HIGHWAY:
            # Трасса - разгон до 115 км/ч
            if phase_time < 30:
                # Разгон с выезда на трассу
                self.target_speed = 50 + (phase_time / 30) * 65  # От 50 до 115
            elif phase_time < 270:  # 4.5 минуты
                # Движение по трассе с небольшими вариациями
                self.target_speed = 115 + 5 * math.sin(phase_time * 0.05)  # 110-120 км/ч
            else:
                # Замедление перед съездом
                self.target_speed = 115 - ((phase_time - 270) / 30) * 65  # От 115 до 50
                
        elif self.phase == DrivingPhase.PARKING:
            # Парковка
            if phase_time < 10:
                # Замедление до остановки
                self.target_speed = max(0, 50 - phase_time * 5)
            else:
                # Стоим на парковке
                self.target_speed = 0
                
        # Управление дросселем и тормозом для достижения целевой скорости
        speed_diff = self.target_speed - self.state.speed
        
        if speed_diff > 2:
            # Нужно ускориться
            self.target_throttle = min(80, speed_diff * 5)  # Пропорциональное управление
            self.state.brake = 0
        elif speed_diff < -2:
            # Нужно замедлиться
            self.target_throttle = 0
            self.state.brake = min(80, -speed_diff * 5)
        else:
            # Поддержание скорости
            if self.state.speed > 1:
                self.target_throttle = 20 + self.state.speed * 0.3  # Примерная нагрузка для поддержания
            else:
                self.target_throttle = 0
            self.state.brake = 0
            
        # Плавное изменение дросселя
        throttle_diff = self.target_throttle - self.state.throttle
        self.state.throttle += throttle_diff * dt * 3.0  # Скорость отклика дросселя
        self.state.throttle = max(0, min(100, self.state.throttle))
        
    def _update_physics(self, dt):
        """Обновление физической модели"""
        # Конвертируем скорость в м/с
        speed_ms = self.state.speed / 3.6
        
        # Расчет силы двигателя
        if self.state.throttle > 0:
            # Мощность зависит от оборотов
            rpm_normalized = self.state.rpm / 6000.0
            power_factor = rpm_normalized * (2 - rpm_normalized)  # Кривая мощности
            engine_force = (self.state.max_power * 1000 * power_factor * 
                          self.state.throttle / 100.0) / max(speed_ms, 1.0)
            engine_force = min(engine_force, self.state.max_torque * 10)  # Ограничение по моменту
        else:
            engine_force = 0
            
        # Сила торможения
        brake_force = self.state.brake * 150.0  # Н на процент торможения
        
        # Сопротивление воздуха
        air_resistance = 0.5 * 1.225 * self.state.drag_coefficient *                         self.state.frontal_area * speed_ms * speed_ms
                        
        # Сопротивление качению
        rolling_resistance = 0.015 * self.state.mass * 9.81
        
        # Результирующая сила
        total_force = engine_force - brake_force - air_resistance - rolling_resistance
        
        # Ускорение
        self.state.acceleration = total_force / self.state.mass
        
        # Обновление скорости
        speed_ms += self.state.acceleration * dt
        speed_ms = max(0, speed_ms)  # Не едем назад
        self.state.speed = speed_ms * 3.6  # Обратно в км/ч
        
        # Обновление одометра (пройденное расстояние)
        if self.state.speed > 0:
            distance_km = (self.state.speed / 3600) * dt  # км за dt секунд
            self.state.odometer += distance_km
        
        # Обновление оборотов двигателя
        self._update_rpm(dt)
        
        # Выбор передачи
        self._update_gear()
        
    def _update_rpm(self, dt):
        """Обновление оборотов двигателя"""
        if self.state.speed < 0.1:
            # Холостой ход
            target_rpm = 800 + self.state.throttle * 20
        else:
            # Обороты зависят от скорости и передачи
            gear_ratios = {1: 3.5, 2: 2.1, 3: 1.4, 4: 1.0, 5: 0.8, 6: 0.65}
            ratio = gear_ratios.get(self.state.gear, 1.0)
            
            # Основные обороты от скорости
            wheel_rpm = (self.state.speed * 1000 / 60) / (0.65 * math.pi)  # диаметр колеса 0.65м
            target_rpm = wheel_rpm * ratio * 4.1  # главная передача
            
            # Добавляем влияние дросселя
            target_rpm += self.state.throttle * 10
            
            # Ограничения
            target_rpm = max(800, min(6500, target_rpm))
            
        # Плавное изменение оборотов с небольшими флуктуациями
        rpm_diff = target_rpm - self.state.rpm
        self.state.rpm += rpm_diff * dt * 3.0  # Скорость изменения оборотов
        
        # Небольшие флуктуации (±50 об/мин)
        self.state.rpm += math.sin(time.time() * 10) * 5
        
    def _update_gear(self):
        """Автоматическое переключение передач"""
        speed = self.state.speed
        
        if speed < 20:
            self.state.gear = 1
        elif speed < 40:
            self.state.gear = 2
        elif speed < 60:
            self.state.gear = 3
        elif speed < 80:
            self.state.gear = 4
        elif speed < 100:
            self.state.gear = 5
        else:
            self.state.gear = 6
            
    def _update_temperature(self, dt):
        """Обновление температуры двигателя"""
        # Целевая температура зависит от нагрузки и времени работы
        if self.state.rpm > 800:
            # Прогрев двигателя
            target_temp = 85 + (self.state.throttle / 100) * 10
        else:
            target_temp = 20  # Остывание при выключенном двигателе
            
        # Плавное изменение температуры
        temp_diff = target_temp - self.state.engine_temp
        self.state.engine_temp += temp_diff * dt * 0.02  # Очень медленное изменение
        self.state.engine_temp = min(95, self.state.engine_temp)  # Не перегреваем
        
    def _can_loop(self):
        """Обработка CAN сообщений"""
        while self.running:
            if not self.bus:
                time.sleep(0.1)
                continue
                
            try:
                message = self.bus.recv(timeout=0.1)
                if message:
                    self._process_can_message(message)
            except Exception as e:
                self.logger.error(f"Ошибка CAN: {e}")
                
    def _process_can_message(self, message):
        """Обработка OBD-II запросов"""
        if not (message.arbitration_id == 0x7DF or 
                (0x7E0 <= message.arbitration_id <= 0x7E7)):
            return
            
        if len(message.data) < 3:
            return
            
        length = message.data[0]
        mode = message.data[1]
        
        if mode == 0x01 and length >= 2:  # Текущие данные
            pid = message.data[2]
            response = self._get_obd2_response(pid)
            
            if response:
                self._send_obd2_response(pid, response)
                
    def _get_obd2_response(self, pid):
        """Получение данных для OBD-II PID"""
        if pid == PID.ENGINE_RPM:
            rpm_value = int(self.state.rpm * 4)
            return [(rpm_value >> 8) & 0xFF, rpm_value & 0xFF]
            
        elif pid == PID.VEHICLE_SPEED:
            return [int(self.state.speed)]
            
        elif pid == PID.ENGINE_COOLANT_TEMP:
            return [int(self.state.engine_temp + 40)]
            
        elif pid == PID.THROTTLE_POSITION:
            return [int(self.state.throttle * 2.55)]
            
        elif pid == PID.ENGINE_LOAD:
            # Нагрузка зависит от дросселя и оборотов
            load = (self.state.throttle * 0.7 + 
                   (self.state.rpm / 6000) * 30)
            return [int(load * 2.55)]
            
        elif pid == PID.FUEL_LEVEL:
            return [int(self.state.fuel_level * 2.55)]
            
        elif pid == 0x31:  # ODOMETER
            # Возвращаем пробег в км (OBD возвращает в единицах 0.1 км)
            odometer_value = int(self.state.odometer * 10)
            return [(odometer_value >> 8) & 0xFF, odometer_value & 0xFF]
            
        return None
        
    def _send_obd2_response(self, pid, data):
        """Отправка OBD-II ответа"""
        response_data = [len(data) + 2, 0x41, pid] + data
        response_data += [0] * (8 - len(response_data))  # Дополнение до 8 байт
        
        message = can.Message(
            arbitration_id=0x7E8,
            data=response_data[:8],
            is_extended_id=False
        )
        
        try:
            self.bus.send(message)
        except Exception as e:
            self.logger.error(f"Ошибка отправки: {e}")


def signal_handler(sig, frame):
    print("\nОстановка симулятора...")
    simulator.stop()
    sys.exit(0)


if __name__ == "__main__":
    simulator = PhysicsSimulator('vcan0')
    signal.signal(signal.SIGINT, signal_handler)
    
    if simulator.start():
        print("Физический симулятор запущен. Нажмите Ctrl+C для остановки.")
        print("Цикл движения:")
        print("  1. Город (3 мин) - 50 км/ч")
        print("  2. Светофор (30 сек)") 
        print("  3. Город (3 мин) - 50 км/ч")
        print("  4. Светофор (30 сек)")
        print("  5. Трасса (5 мин) - 115 км/ч")
        print("  6. Парковка (1 мин)")
        print("-" * 60)
        
        while True:
            time.sleep(1)
            # Вывод текущего состояния
            s = simulator.state
            phase_name = simulator.phase.value.replace('_', ' ').title()
            print(f"[{phase_name:15}] "
                  f"Скорость: {s.speed:5.1f} км/ч | "
                  f"Обороты: {s.rpm:4.0f} | "
                  f"Дроссель: {s.throttle:3.0f}% | "
                  f"Передача: {s.gear} | "
                  f"Темп: {s.engine_temp:3.0f}°C", end='\r')
    else:
        print("Не удалось запустить симулятор")
