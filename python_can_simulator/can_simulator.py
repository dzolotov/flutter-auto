#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Комплексный симулятор CAN шины с поддержкой протокола OBD-II
Генерирует реалистичные данные автомобильной диагностики
Поддерживает различные сценарии вождения и режимы работы двигателя

(C) 2025 Dmitrii Zolotov, dmitrii.zolotov@gmail.com
Версия: 1.0
Лицензия: LGPL
"""

import time
import math
import random
import struct
import logging
import threading
import json
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field
from enum import Enum, IntEnum
import can
from can.interface import Bus
import signal
import sys
from datetime import datetime  # timedelta import removed - unused


# ============================================================================
# Константы OBD-II протокола
# ============================================================================

class OBDMode(IntEnum):
    """
    Режимы OBD-II протокола
    Режим 01: Текущие данные (в реальном времени)
    Режим 02: Сохраненные данные (freeze frame)
    Режим 03: Коды неисправностей (DTC)
    Режим 04: Очистка кодов неисправностей
    Режим 05: Результаты тестов кислородного датчика
    Режим 06: Результаты мониторинга конкретных систем
    Режим 07: Показать ожидающие коды неисправностей
    Режим 08: Управление бортовыми системами
    Режим 09: Информация об автомобиле
    """
    CURRENT_DATA = 0x01
    FREEZE_FRAME = 0x02
    DIAGNOSTIC_CODES = 0x03
    CLEAR_CODES = 0x04
    O2_SENSOR_TEST = 0x05
    SYSTEM_MONITORING = 0x06
    PENDING_CODES = 0x07
    CONTROL_OPERATION = 0x08
    VEHICLE_INFO = 0x09


class OBDResponseMode(IntEnum):
    """Режимы ответов OBD-II (режим запроса + 0x40)"""
    CURRENT_DATA_RESPONSE = 0x41
    FREEZE_FRAME_RESPONSE = 0x42
    DIAGNOSTIC_CODES_RESPONSE = 0x43
    CLEAR_CODES_RESPONSE = 0x44
    O2_SENSOR_RESPONSE = 0x45
    SYSTEM_MONITORING_RESPONSE = 0x46
    PENDING_CODES_RESPONSE = 0x47
    CONTROL_OPERATION_RESPONSE = 0x48
    VEHICLE_INFO_RESPONSE = 0x49


class PID(IntEnum):
    """
    Идентификаторы параметров (PID) для режима 01
    Полный список стандартных PID согласно SAE J1979
    """
    # Поддерживаемые PID (битовые маски)
    SUPPORTED_PIDS_01_20 = 0x00
    SUPPORTED_PIDS_21_40 = 0x20
    SUPPORTED_PIDS_41_60 = 0x40
    SUPPORTED_PIDS_61_80 = 0x60
    SUPPORTED_PIDS_81_A0 = 0x80
    SUPPORTED_PIDS_A1_C0 = 0xA0
    
    # Состояние системы диагностики
    MONITOR_STATUS = 0x01
    FREEZE_DTC = 0x02
    FUEL_SYSTEM_STATUS = 0x03
    ENGINE_LOAD = 0x04
    ENGINE_COOLANT_TEMP = 0x05
    SHORT_FUEL_TRIM_BANK1 = 0x06
    LONG_FUEL_TRIM_BANK1 = 0x07
    SHORT_FUEL_TRIM_BANK2 = 0x08
    LONG_FUEL_TRIM_BANK2 = 0x09
    FUEL_PRESSURE = 0x0A
    INTAKE_MANIFOLD_PRESSURE = 0x0B
    ENGINE_RPM = 0x0C
    VEHICLE_SPEED = 0x0D
    TIMING_ADVANCE = 0x0E
    INTAKE_AIR_TEMP = 0x0F
    MAF_AIR_FLOW = 0x10
    THROTTLE_POSITION = 0x11
    COMMANDED_SECONDARY_AIR = 0x12
    O2_SENSORS_PRESENT = 0x13
    
    # Датчики кислорода (банк 1)
    O2_SENSOR_1_VOLTAGE = 0x14
    O2_SENSOR_2_VOLTAGE = 0x15
    O2_SENSOR_3_VOLTAGE = 0x16
    O2_SENSOR_4_VOLTAGE = 0x17
    
    # Датчики кислорода (банк 2)
    O2_SENSOR_5_VOLTAGE = 0x18
    O2_SENSOR_6_VOLTAGE = 0x19
    O2_SENSOR_7_VOLTAGE = 0x1A
    O2_SENSOR_8_VOLTAGE = 0x1B
    
    OBD_STANDARDS = 0x1C
    O2_SENSORS_PRESENT_4BANKS = 0x1D
    AUX_INPUT_STATUS = 0x1E
    RUN_TIME_SINCE_START = 0x1F
    DISTANCE_WITH_MIL = 0x21
    FUEL_RAIL_PRESSURE = 0x22
    FUEL_RAIL_GAUGE_PRESSURE = 0x23
    
    # Расширенные датчики кислорода
    O2_SENSOR_1_FUEL_AIR_EQUIV = 0x24
    O2_SENSOR_2_FUEL_AIR_EQUIV = 0x25
    O2_SENSOR_3_FUEL_AIR_EQUIV = 0x26
    O2_SENSOR_4_FUEL_AIR_EQUIV = 0x27
    O2_SENSOR_5_FUEL_AIR_EQUIV = 0x28
    O2_SENSOR_6_FUEL_AIR_EQUIV = 0x29
    O2_SENSOR_7_FUEL_AIR_EQUIV = 0x2A
    O2_SENSOR_8_FUEL_AIR_EQUIV = 0x2B
    
    COMMANDED_EGR = 0x2C
    EGR_ERROR = 0x2D
    COMMANDED_EVAP_PURGE = 0x2E
    FUEL_TANK_LEVEL = 0x2F
    WARM_UPS_SINCE_CLEAR = 0x30
    DISTANCE_SINCE_CLEAR = 0x31
    EVAP_SYSTEM_PRESSURE = 0x32
    ABSOLUTE_BAROMETRIC_PRESSURE = 0x33
    
    # Широкополосные датчики кислорода
    O2_SENSOR_1_WIDEBAND = 0x34
    O2_SENSOR_2_WIDEBAND = 0x35
    O2_SENSOR_3_WIDEBAND = 0x36
    O2_SENSOR_4_WIDEBAND = 0x37
    O2_SENSOR_5_WIDEBAND = 0x38
    O2_SENSOR_6_WIDEBAND = 0x39
    O2_SENSOR_7_WIDEBAND = 0x3A
    O2_SENSOR_8_WIDEBAND = 0x3B
    
    CATALYST_TEMP_BANK1_SENSOR1 = 0x3C
    CATALYST_TEMP_BANK2_SENSOR1 = 0x3D
    CATALYST_TEMP_BANK1_SENSOR2 = 0x3E
    CATALYST_TEMP_BANK2_SENSOR2 = 0x3F
    
    # PID 41-60
    CONTROL_MODULE_VOLTAGE = 0x42
    ABSOLUTE_LOAD_VALUE = 0x43
    FUEL_AIR_COMMANDED_EQUIV = 0x44
    RELATIVE_THROTTLE_POSITION = 0x45
    AMBIENT_AIR_TEMPERATURE = 0x46
    ABSOLUTE_THROTTLE_POSITION_B = 0x47
    ABSOLUTE_THROTTLE_POSITION_C = 0x48
    ACCELERATOR_PEDAL_POSITION_D = 0x49
    ACCELERATOR_PEDAL_POSITION_E = 0x4A
    ACCELERATOR_PEDAL_POSITION_F = 0x4B
    COMMANDED_THROTTLE_ACTUATOR = 0x4C
    TIME_WITH_MIL_ON = 0x4D
    TIME_SINCE_CODES_CLEARED = 0x4E
    
    # Дополнительные PID для современных автомобилей
    ETHANOL_FUEL_PERCENT = 0x52
    ABSOLUTE_EVAP_SYSTEM_PRESSURE = 0x53
    # EVAP_SYSTEM_PRESSURE уже определен выше как 0x32
    SHORT_TERM_SECONDARY_O2_TRIM_BANK1 = 0x55
    LONG_TERM_SECONDARY_O2_TRIM_BANK1 = 0x56
    SHORT_TERM_SECONDARY_O2_TRIM_BANK2 = 0x57
    LONG_TERM_SECONDARY_O2_TRIM_BANK2 = 0x58
    FUEL_RAIL_ABSOLUTE_PRESSURE = 0x59
    RELATIVE_ACCELERATOR_PEDAL_POSITION = 0x5A
    HYBRID_BATTERY_PACK_LIFE = 0x5B
    ENGINE_OIL_TEMPERATURE = 0x5C
    FUEL_INJECTION_TIMING = 0x5D
    ENGINE_FUEL_RATE = 0x5E


class DrivingScenario(Enum):
    """Сценарии вождения для реалистичной симуляции"""
    IDLE = "idle"                    # Холостой ход
    CITY_DRIVING = "city"           # Городская езда
    HIGHWAY_DRIVING = "highway"      # Трассовая езда
    AGGRESSIVE_DRIVING = "aggressive" # Агрессивная езда
    ECO_DRIVING = "eco"             # Экономичная езда
    PARKING = "parking"             # Парковка
    TRAFFIC_JAM = "traffic_jam"     # Пробка


# ============================================================================
# Классы данных для моделирования автомобильных систем
# ============================================================================

@dataclass
class EngineState:
    """Состояние двигателя"""
    rpm: float = 800.0              # Обороты в минуту
    coolant_temp: float = 90.0      # Температура охлаждающей жидкости (°C)
    oil_temp: float = 85.0          # Температура масла (°C)
    intake_air_temp: float = 25.0   # Температура воздуха на впуске (°C)
    engine_load: float = 0.0        # Нагрузка двигателя (%)
    throttle_position: float = 0.0  # Положение дроссельной заслонки (%)
    maf_flow: float = 3.5          # Массовый расход воздуха (г/с)
    fuel_pressure: float = 3.5      # Давление топлива (бар)
    timing_advance: float = 15.0    # Угол опережения зажигания (градусы)
    is_running: bool = True         # Двигатель работает
    runtime_since_start: int = 0    # Время работы с момента запуска (сек)


@dataclass
class VehicleState:
    """Состояние автомобиля"""
    speed: float = 0.0              # Скорость (км/ч)
    odometer: float = 125847.5      # Показания одометра (км)
    fuel_level: float = 75.0        # Уровень топлива (%)
    battery_voltage: float = 12.6   # Напряжение аккумулятора (В)
    ambient_temperature: float = 20.0 # Температура окружающей среды (°C)
    barometric_pressure: float = 101.3 # Барометрическое давление (кПа)
    gear: int = 0                   # Текущая передача (0=N, 1-6)
    speed_limit: int = 60            # Ограничение скорости (км/ч)
    
    # Состояние систем
    mil_status: bool = False        # Индикатор неисправности (MIL)
    dtc_count: int = 0             # Количество кодов неисправности
    fuel_system_status: int = 0x02  # Статус топливной системы (замкнутый контур)
    
    # Датчики кислорода
    o2_sensor1_voltage: float = 0.45 # Напряжение 1-го датчика O2 (В)
    o2_sensor2_voltage: float = 0.47 # Напряжение 2-го датчика O2 (В)
    
    # Коррекция топливоподачи
    short_fuel_trim_bank1: float = 0.0  # Кратковременная коррекция (%)
    long_fuel_trim_bank1: float = 0.0   # Долговременная коррекция (%)


@dataclass
class DiagnosticTroubleCode:
    """Диагностический код неисправности (DTC)"""
    code: str                       # Код (например, "P0420")
    description: str                # Описание неисправности
    status: str = "pending"         # Статус: pending, confirmed, permanent
    occurrence_count: int = 1       # Количество появлений
    first_detected: datetime = field(default_factory=datetime.now)
    last_detected: datetime = field(default_factory=datetime.now)


# ============================================================================
# Основной класс симулятора CAN шины
# ============================================================================

class CANBusSimulator:
    """
    Основной класс симулятора CAN шины с поддержкой OBD-II
    Генерирует реалистичные данные и отвечает на OBD-II запросы
    """
    
    def __init__(self, interface: str = 'vcan0', simulate_dtcs: bool = True):
        """
        Инициализация симулятора
        
        Args:
            interface: Имя CAN интерфейса (например, 'vcan0' или 'can0')
            simulate_dtcs: Включить симуляцию кодов неисправности
        """
        # Настройка логирования
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('can_simulator.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Параметры симулятора
        self.interface = interface
        self.simulate_dtcs = simulate_dtcs
        self.running = False
        
        # Состояние автомобиля
        self.engine = EngineState()
        self.vehicle = VehicleState()
        self.current_scenario = DrivingScenario.IDLE
        
        # Диагностические коды неисправности
        self.dtc_codes: List[DiagnosticTroubleCode] = []
        
        # CAN шина
        self.bus: Optional[Bus] = None
        
        # Потоки выполнения
        self.simulation_thread: Optional[threading.Thread] = None
        self.can_listener_thread: Optional[threading.Thread] = None
        
        # Статистика симуляции
        self.simulation_stats = {
            'start_time': None,
            'messages_sent': 0,
            'requests_received': 0,
            'responses_sent': 0,
            'errors': 0
        }
        
        # Конфигурация поддерживаемых PID
        self.supported_pids = self._initialize_supported_pids()
        
        # Счетчики для реалистичности
        self._simulation_tick = 0
        self._last_scenario_change = time.time()
        self._scenario_duration = random.randint(30, 120)  # Секунды
        
        self.logger.info(f"Инициализирован симулятор CAN шины для интерфейса {interface}")
    
    def _initialize_supported_pids(self) -> Dict[int, List[int]]:
        """Инициализация поддерживаемых PID для каждого диапазона"""
        return {
            0x00: [  # PID 01-20
                PID.MONITOR_STATUS, PID.ENGINE_LOAD, PID.ENGINE_COOLANT_TEMP,
                PID.SHORT_FUEL_TRIM_BANK1, PID.LONG_FUEL_TRIM_BANK1,
                PID.FUEL_PRESSURE, PID.INTAKE_MANIFOLD_PRESSURE, PID.ENGINE_RPM,
                PID.VEHICLE_SPEED, PID.TIMING_ADVANCE, PID.INTAKE_AIR_TEMP,
                PID.MAF_AIR_FLOW, PID.THROTTLE_POSITION, PID.O2_SENSORS_PRESENT,
                PID.O2_SENSOR_1_VOLTAGE, PID.O2_SENSOR_2_VOLTAGE, PID.RUN_TIME_SINCE_START
            ],
            0x20: [  # PID 21-40
                PID.DISTANCE_WITH_MIL, PID.FUEL_RAIL_PRESSURE, PID.FUEL_TANK_LEVEL,
                PID.ABSOLUTE_BAROMETRIC_PRESSURE
            ],
            0x40: [  # PID 41-60
                PID.CONTROL_MODULE_VOLTAGE, PID.ABSOLUTE_LOAD_VALUE,
                PID.AMBIENT_AIR_TEMPERATURE, PID.TIME_WITH_MIL_ON,
                PID.TIME_SINCE_CODES_CLEARED
            ]
        }
    
    def start(self):
        """Запуск симулятора"""
        try:
            # Подключение к CAN шине
            self.bus = can.interface.Bus(
                channel=self.interface,
                bustype='socketcan',
                receive_own_messages=False
            )
            self.logger.info(f"Подключение к CAN интерфейсу {self.interface} успешно")
            
            # Инициализация диагностических кодов для демонстрации
            if self.simulate_dtcs:
                self._initialize_demo_dtcs()
            
            # Запуск потоков
            self.running = True
            self.simulation_stats['start_time'] = datetime.now()
            
            self.simulation_thread = threading.Thread(target=self._simulation_loop, daemon=True)
            self.can_listener_thread = threading.Thread(target=self._can_listener_loop, daemon=True)
            
            self.simulation_thread.start()
            self.can_listener_thread.start()
            
            self.logger.info("Симулятор CAN шины запущен")
            
        except Exception as e:
            self.logger.error(f"Ошибка запуска симулятора: {e}")
            raise
    
    def stop(self):
        """Остановка симулятора"""
        self.logger.info("Остановка симулятора CAN шины...")
        self.running = False
        
        # Ожидание завершения потоков
        if self.simulation_thread and self.simulation_thread.is_alive():
            self.simulation_thread.join(timeout=2)
        
        if self.can_listener_thread and self.can_listener_thread.is_alive():
            self.can_listener_thread.join(timeout=2)
        
        # Закрытие CAN шины
        if self.bus:
            self.bus.shutdown()
        
        self.logger.info("Симулятор остановлен")
        self._print_statistics()
    
    def _simulation_loop(self):
        """Основной цикл симуляции"""
        while self.running:
            try:
                start_time = time.time()
                
                # Обновление состояния автомобиля
                self._update_vehicle_state()
                
                # Периодическая отправка данных CAN отключена для отладки
                # if self._simulation_tick % 10 == 0:  # Каждые 100мс
                #     self._send_periodic_can_messages()
                
                self._simulation_tick += 1
                
                # Ограничение частоты обновления до 100 Гц
                elapsed = time.time() - start_time
                sleep_time = max(0, 0.01 - elapsed)  # 10мс цикл
                time.sleep(sleep_time)
                
            except Exception as e:
                self.logger.error(f"Ошибка в цикле симуляции: {e}")
                self.simulation_stats['errors'] += 1
    
    def _can_listener_loop(self):
        """Цикл обработки входящих CAN сообщений"""
        while self.running and self.bus:
            try:
                # Ожидание сообщения с таймаутом
                message = self.bus.recv(timeout=0.1)
                if message is not None:
                    self.simulation_stats['requests_received'] += 1
                    self._process_can_message(message)
                    
            except Exception as e:
                self.logger.error(f"Ошибка обработки CAN сообщения: {e}")
                self.simulation_stats['errors'] += 1
    
    def _update_vehicle_state(self):
        """
        Обновление состояния автомобиля с учетом текущего сценария вождения
        Включает реалистичную физику и взаимосвязи параметров
        """
        current_time = time.time()
        
        # Смена сценария вождения
        if current_time - self._last_scenario_change > self._scenario_duration:
            self._change_driving_scenario()
            self._last_scenario_change = current_time
            self._scenario_duration = random.randint(30, 120)
        
        # Обновление параметров в зависимости от сценария
        if self.current_scenario == DrivingScenario.IDLE:
            self._simulate_idle()
        elif self.current_scenario == DrivingScenario.CITY_DRIVING:
            self._simulate_city_driving()
        elif self.current_scenario == DrivingScenario.HIGHWAY_DRIVING:
            self._simulate_highway_driving()
        elif self.current_scenario == DrivingScenario.AGGRESSIVE_DRIVING:
            self._simulate_aggressive_driving()
        elif self.current_scenario == DrivingScenario.ECO_DRIVING:
            self._simulate_eco_driving()
        elif self.current_scenario == DrivingScenario.TRAFFIC_JAM:
            self._simulate_traffic_jam()
        else:
            self._simulate_parking()
        
        # Обновление взаимосвязанных параметров
        self._update_correlated_parameters()
        
        # Обновление счетчиков времени
        self.engine.runtime_since_start += 1 if self.engine.is_running else 0
        
        # Симуляция случайных неисправностей для демонстрации
        if self.simulate_dtcs and random.random() < 0.0001:  # 0.01% вероятность
            self._add_random_dtc()
    
    def _change_driving_scenario(self):
        """Смена сценария вождения"""
        scenarios = list(DrivingScenario)
        # Убираем текущий сценарий для избежания повторения
        scenarios.remove(self.current_scenario)
        
        # Вероятности различных сценариев (более реалистичное распределение)
        weights = {
            DrivingScenario.IDLE: 20,
            DrivingScenario.CITY_DRIVING: 35,
            DrivingScenario.HIGHWAY_DRIVING: 20,
            DrivingScenario.AGGRESSIVE_DRIVING: 5,
            DrivingScenario.ECO_DRIVING: 10,
            DrivingScenario.PARKING: 5,
            DrivingScenario.TRAFFIC_JAM: 5
        }
        
        self.current_scenario = random.choices(
            scenarios, 
            weights=[weights.get(s, 1) for s in scenarios]
        )[0]
        
        self.logger.info(f"Смена сценария вождения на: {self.current_scenario.value}")
    
    def _simulate_idle(self):
        """Симуляция холостого хода"""
        self.engine.rpm = 800 + random.gauss(0, 30)  # Небольшие колебания
        self.vehicle.speed = 0.0
        self.engine.throttle_position = 0.0
        self.engine.engine_load = random.uniform(15, 25)
        self.engine.maf_flow = random.uniform(2.0, 4.0)
    
    def _simulate_city_driving(self):
        """Симуляция городской езды"""
        # Переменная скорость с остановками на светофорах
        base_speed = 40 + 15 * math.sin(self._simulation_tick * 0.01)
        self.vehicle.speed = max(0, base_speed + random.gauss(0, 5))
        
        # Городские лимиты скорости
        self.vehicle.speed_limit = random.choice([40, 50, 60])
        
        # RPM зависит от скорости и передачи
        self.engine.rpm = self._calculate_rpm_for_speed(self.vehicle.speed)
        self.engine.throttle_position = random.uniform(20, 60)
        self.engine.engine_load = random.uniform(30, 70)
        self.engine.maf_flow = random.uniform(8, 25)
    
    def _simulate_highway_driving(self):
        """Симуляция трассовой езды"""
        # Стабильная высокая скорость с небольшими вариациями
        base_speed = 110 + 10 * math.sin(self._simulation_tick * 0.005)
        self.vehicle.speed = base_speed + random.gauss(0, 3)
        
        # Лимиты на трассе
        self.vehicle.speed_limit = random.choice([90, 110, 130])
        
        self.engine.rpm = self._calculate_rpm_for_speed(self.vehicle.speed, gear=6)
        self.engine.throttle_position = random.uniform(40, 70)
        self.engine.engine_load = random.uniform(40, 80)
        self.engine.maf_flow = random.uniform(15, 35)
    
    def _simulate_aggressive_driving(self):
        """Симуляция агрессивной езды"""
        # Быстрые изменения скорости и высокие обороты
        self.vehicle.speed = random.uniform(60, 140)
        self.engine.rpm = random.uniform(3000, 6500)
        self.engine.throttle_position = random.uniform(70, 100)
        self.engine.engine_load = random.uniform(70, 95)
        self.engine.maf_flow = random.uniform(25, 50)
    
    def _simulate_eco_driving(self):
        """Симуляция экономичной езды"""
        # Плавные изменения, низкие обороты
        self.vehicle.speed = random.uniform(50, 90)
        self.engine.rpm = min(2500, self._calculate_rpm_for_speed(self.vehicle.speed))
        self.engine.throttle_position = random.uniform(10, 40)
        self.engine.engine_load = random.uniform(20, 50)
        self.engine.maf_flow = random.uniform(5, 20)
    
    def _simulate_traffic_jam(self):
        """Симуляция движения в пробке"""
        # Медленное движение с частыми остановками
        if random.random() < 0.3:  # 30% времени стоим
            self.vehicle.speed = 0.0
            self._simulate_idle()
        else:
            self.vehicle.speed = random.uniform(5, 25)
            self.engine.rpm = self._calculate_rpm_for_speed(self.vehicle.speed)
            self.engine.throttle_position = random.uniform(10, 30)
            self.engine.engine_load = random.uniform(25, 45)
            self.engine.maf_flow = random.uniform(5, 15)
    
    def _simulate_parking(self):
        """Симуляция парковки"""
        self.vehicle.speed = 0.0
        if self.engine.is_running:
            self._simulate_idle()
        else:
            self.engine.rpm = 0.0
            self.engine.throttle_position = 0.0
            self.engine.engine_load = 0.0
            self.engine.maf_flow = 0.0
    
    def _calculate_rpm_for_speed(self, speed_kmh: float, gear: int = None) -> float:
        """
        Расчет оборотов двигателя на основе скорости и передачи
        Использует реалистичные передаточные отношения
        """
        if speed_kmh <= 0:
            self.vehicle.gear = 0  # Нейтраль
            return 800.0  # Холостой ход
        
        # Автоматический выбор передачи если не указана
        if gear is None:
            if speed_kmh < 20:
                gear = 1
            elif speed_kmh < 40:
                gear = 2
            elif speed_kmh < 60:
                gear = 3
            elif speed_kmh < 80:
                gear = 4
            elif speed_kmh < 110:
                gear = 5
            else:
                gear = 6
        
        # Сохраняем текущую передачу
        self.vehicle.gear = gear
        
        # Передаточные отношения для 6-ступенчатой коробки передач
        gear_ratios = {
            1: 3.5, 2: 2.1, 3: 1.4, 4: 1.0, 5: 0.8, 6: 0.65
        }
        
        final_drive_ratio = 3.73
        wheel_circumference = 2.07  # метры (для шин 215/60R16)
        
        # Расчет оборотов колеса
        wheel_rpm = (speed_kmh * 1000 / 60) / wheel_circumference
        
        # Расчет оборотов двигателя
        engine_rpm = wheel_rpm * gear_ratios.get(gear, 1.0) * final_drive_ratio
        
        return max(800.0, min(7000.0, engine_rpm))
    
    def _update_correlated_parameters(self):
        """Обновление взаимосвязанных параметров для реалистичности"""
        
        # Температура охлаждающей жидкости зависит от нагрузки двигателя
        target_temp = 85 + (self.engine.engine_load / 100.0) * 20
        if self.vehicle.speed > 50:  # Лучшее охлаждение на скорости
            target_temp -= 5
        self.engine.coolant_temp += (target_temp - self.engine.coolant_temp) * 0.01
        
        # Температура масла следует за температурой охлаждающей жидкости
        self.engine.oil_temp = self.engine.coolant_temp + random.uniform(5, 15)
        
        # Температура воздуха на впуске
        self.engine.intake_air_temp = self.vehicle.ambient_temperature + \
                                     (self.engine.engine_load / 100.0) * 30 + \
                                     random.gauss(0, 3)
        
        # Давление топлива зависит от нагрузки
        self.engine.fuel_pressure = 3.5 + (self.engine.engine_load / 100.0) * 1.5
        
        # Напряжение аккумулятора
        base_voltage = 14.2 if self.engine.is_running else 12.6
        self.vehicle.battery_voltage = base_voltage + random.gauss(0, 0.2)
        
        # Датчики кислорода (лямбда-зонды)
        # Колеблются вокруг стехиометрического значения (0.45В)
        lambda_oscillation = 0.1 * math.sin(self._simulation_tick * 0.2)
        self.vehicle.o2_sensor1_voltage = 0.45 + lambda_oscillation + random.gauss(0, 0.02)
        self.vehicle.o2_sensor2_voltage = 0.47 + lambda_oscillation + random.gauss(0, 0.02)
        
        # Коррекция топливоподачи
        self.vehicle.short_fuel_trim_bank1 = random.gauss(0, 3)  # ±3%
        self.vehicle.long_fuel_trim_bank1 = random.gauss(0, 5)   # ±5%
        
        # Угол опережения зажигания
        self.engine.timing_advance = 15 + (self.engine.rpm / 6000.0) * 25
        
        # Обновление одометра
        if self.vehicle.speed > 0.1:
            # Пройденное расстояние за 10мс в км
            distance = (self.vehicle.speed / 3600.0) * 0.01
            self.vehicle.odometer += distance
        
        # Уменьшение уровня топлива (очень медленно для демонстрации)
        if self.engine.is_running:
            consumption_rate = (self.engine.engine_load / 100.0) * 0.0001
            self.vehicle.fuel_level = max(0, self.vehicle.fuel_level - consumption_rate)
    
    def _send_periodic_can_messages(self):
        """
        Отправка периодических CAN сообщений (имитация штатной работы ЭБУ)
        В реальном автомобиле различные блоки управления периодически отправляют данные
        """
        try:
            # Отправляем основные параметры двигателя (обычно с идентификатором 0x7E8)
            engine_data = struct.pack('>HHB', 
                                    int(self.engine.rpm), 
                                    int(self.vehicle.speed * 10), 
                                    int(self.engine.coolant_temp))
            
            message = can.Message(
                arbitration_id=0x7E8,
                data=engine_data,
                is_extended_id=False
            )
            
            if self.bus:
                self.bus.send(message)
                self.simulation_stats['messages_sent'] += 1
                
        except Exception as e:
            self.logger.error(f"Ошибка отправки периодического сообщения: {e}")
    
    def _process_can_message(self, message: can.Message):
        """
        Обработка входящих CAN сообщений
        Основная логика обработки OBD-II запросов
        """
        try:
            # Проверка, что это OBD-II запрос (0x7DF broadcast или 0x7E0-0x7E7)
            if not (message.arbitration_id == 0x7DF or (0x7E0 <= message.arbitration_id <= 0x7E7)):
                return
            
            # OBD-II запросы имеют минимум 3 байта (длина, режим и PID)
            if len(message.data) < 3:
                return
            
            # Первый байт - длина данных, второй - режим
            data_length = message.data[0]
            mode = message.data[1]
            
            self.logger.info(f"Получен OBD-II запрос: ID={message.arbitration_id:03X}, "
                           f"Length={data_length}, Mode={mode:02X}, Data={message.data.hex()}")
            
            # Обработка различных режимов OBD-II
            if mode == OBDMode.CURRENT_DATA:
                self._handle_current_data_request(message)
            elif mode == OBDMode.DIAGNOSTIC_CODES:
                self._handle_diagnostic_codes_request(message)
            elif mode == OBDMode.CLEAR_CODES:
                self._handle_clear_codes_request(message)
            elif mode == OBDMode.VEHICLE_INFO:
                self._handle_vehicle_info_request(message)
            else:
                # Неподдерживаемый режим - отправляем отрицательный ответ
                self._send_negative_response(message.arbitration_id, mode)
                
        except Exception as e:
            self.logger.error(f"Ошибка обработки CAN сообщения: {e}")
    
    def _handle_current_data_request(self, request: can.Message):
        """
        Обработка запросов текущих данных (режим 01)
        Это основной режим для получения параметров двигателя в реальном времени
        """
        if len(request.data) < 3:
            return
        
        requested_pid = request.data[2]
        
        # Подготовка ответа
        response_data = [OBDResponseMode.CURRENT_DATA_RESPONSE, requested_pid]
        
        try:
            if requested_pid == PID.SUPPORTED_PIDS_01_20:
                # Битовая маска поддерживаемых PID 01-20
                supported_mask = self._get_supported_pids_mask(0x00)
                response_data.extend(struct.pack('>I', supported_mask))
                
            elif requested_pid == PID.ENGINE_RPM:
                # Обороты двигателя: значение / 4 RPM
                rpm_encoded = int(self.engine.rpm * 4)
                response_data.extend(struct.pack('>H', rpm_encoded))
                
            elif requested_pid == PID.VEHICLE_SPEED:
                # Скорость автомобиля в км/ч
                response_data.append(int(self.vehicle.speed))
                
            elif requested_pid == PID.ENGINE_COOLANT_TEMP:
                # Температура охлаждающей жидкости: °C = значение - 40
                temp_encoded = int(self.engine.coolant_temp + 40)
                response_data.append(max(0, min(255, temp_encoded)))
                
            elif requested_pid == PID.ENGINE_LOAD:
                # Нагрузка двигателя: % = значение * 100/255
                load_encoded = int(self.engine.engine_load * 255 / 100)
                response_data.append(max(0, min(255, load_encoded)))
                
            elif requested_pid == PID.THROTTLE_POSITION:
                # Положение дроссельной заслонки: % = значение * 100/255
                throttle_encoded = int(self.engine.throttle_position * 255 / 100)
                response_data.append(max(0, min(255, throttle_encoded)))
                
            elif requested_pid == PID.INTAKE_AIR_TEMP:
                # Температура воздуха на впуске: °C = значение - 40
                temp_encoded = int(self.engine.intake_air_temp + 40)
                response_data.append(max(0, min(255, temp_encoded)))
                
            elif requested_pid == PID.MAF_AIR_FLOW:
                # Массовый расход воздуха: г/с = значение / 100
                maf_encoded = int(self.engine.maf_flow * 100)
                response_data.extend(struct.pack('>H', max(0, min(65535, maf_encoded))))
                
            elif requested_pid == PID.FUEL_TANK_LEVEL:
                # Уровень топлива: % = значение * 100/255
                fuel_encoded = int(self.vehicle.fuel_level * 255 / 100)
                response_data.append(max(0, min(255, fuel_encoded)))
                
            elif requested_pid == PID.CONTROL_MODULE_VOLTAGE:
                # Напряжение системы управления: В = значение / 1000
                voltage_encoded = int(self.vehicle.battery_voltage * 1000)
                response_data.extend(struct.pack('>H', max(0, min(65535, voltage_encoded))))
                
            elif requested_pid == PID.AMBIENT_AIR_TEMPERATURE:
                # Температура окружающего воздуха: °C = значение - 40
                temp_encoded = int(self.vehicle.ambient_temperature + 40)
                response_data.append(max(0, min(255, temp_encoded)))
                
            elif requested_pid == PID.FUEL_PRESSURE:
                # Давление топлива: кПа = значение * 3
                pressure_encoded = int(self.engine.fuel_pressure * 100 / 3)  # бар в кПа и кодирование
                response_data.append(max(0, min(255, pressure_encoded)))
                
            elif requested_pid == PID.TIMING_ADVANCE:
                # Угол опережения зажигания: градусы = (значение / 2) - 64
                timing_encoded = int((self.engine.timing_advance + 64) * 2)
                response_data.append(max(0, min(255, timing_encoded)))
                
            elif requested_pid == PID.O2_SENSOR_1_VOLTAGE:
                # Напряжение датчика кислорода: В = значение / 200
                o2_encoded = int(self.vehicle.o2_sensor1_voltage * 200)
                response_data.extend([max(0, min(255, o2_encoded)), 0xFF])  # + Short term fuel trim
                
            elif requested_pid == PID.SHORT_FUEL_TRIM_BANK1:
                # Кратковременная коррекция топливоподачи: % = (значение - 128) * 100/128
                trim_encoded = int((self.vehicle.short_fuel_trim_bank1 * 128 / 100) + 128)
                response_data.append(max(0, min(255, trim_encoded)))
                
            elif requested_pid == PID.LONG_FUEL_TRIM_BANK1:
                # Долговременная коррекция топливоподачи
                trim_encoded = int((self.vehicle.long_fuel_trim_bank1 * 128 / 100) + 128)
                response_data.append(max(0, min(255, trim_encoded)))
                
            elif requested_pid == PID.RUN_TIME_SINCE_START:
                # Время работы двигателя с момента запуска (секунды)
                runtime_encoded = min(65535, self.engine.runtime_since_start)
                response_data.extend(struct.pack('>H', runtime_encoded))
                
            elif requested_pid == PID.ABSOLUTE_BAROMETRIC_PRESSURE:
                # Абсолютное барометрическое давление: кПа
                pressure_encoded = int(self.vehicle.barometric_pressure)
                response_data.append(max(0, min(255, pressure_encoded)))
                
            elif requested_pid == 0xA5:  # Передача
                # Текущая передача: 0=N, 1-6 = передачи
                response_data.append(self.vehicle.gear)
                
            elif requested_pid == 0xA8:  # Скоростной лимит (кастомный PID)
                # Скоростной лимит в км/ч
                response_data.append(self.vehicle.speed_limit)
                
            else:
                # Неподдерживаемый PID
                self._send_negative_response(request.arbitration_id, OBDMode.CURRENT_DATA, requested_pid)
                return
            
            # Отправка ответа
            self._send_obd_response(request.arbitration_id, response_data)
            
        except Exception as e:
            self.logger.error(f"Ошибка обработки PID {requested_pid:02X}: {e}")
            self._send_negative_response(request.arbitration_id, OBDMode.CURRENT_DATA, requested_pid)
    
    def _handle_diagnostic_codes_request(self, request: can.Message):
        """Обработка запроса диагностических кодов неисправности (режим 03)"""
        response_data = [OBDResponseMode.DIAGNOSTIC_CODES_RESPONSE]
        
        # Количество кодов неисправности
        dtc_count = len([dtc for dtc in self.dtc_codes if dtc.status == "confirmed"])
        response_data.append(dtc_count)
        
        # Добавляем коды неисправности (максимум 3 кода в одном сообщении)
        for i, dtc in enumerate(self.dtc_codes[:3]):
            if dtc.status == "confirmed":
                # Конвертация кода DTC в байты (например, P0420 -> 0x0420)
                dtc_bytes = self._encode_dtc(dtc.code)
                response_data.extend(dtc_bytes)
        
        self._send_obd_response(request.arbitration_id, response_data)
    
    def _handle_clear_codes_request(self, request: can.Message):
        """Обработка запроса очистки кодов неисправности (режим 04)"""
        # Очистка всех диагностических кодов
        self.dtc_codes.clear()
        self.vehicle.mil_status = False
        self.vehicle.dtc_count = 0
        
        self.logger.info("Диагностические коды неисправности очищены")
        
        # Отправка положительного ответа
        response_data = [OBDResponseMode.CLEAR_CODES_RESPONSE]
        self._send_obd_response(request.arbitration_id, response_data)
    
    def _handle_vehicle_info_request(self, request: can.Message):
        """Обработка запроса информации об автомобиле (режим 09)"""
        if len(request.data) < 2:
            return
        
        info_type = request.data[1]
        response_data = [OBDResponseMode.VEHICLE_INFO_RESPONSE, info_type]
        
        if info_type == 0x02:  # VIN (Vehicle Identification Number)
            # Демонстрационный VIN
            vin = "1HGBH41JXMN109186"
            response_data.append(1)  # Количество элементов данных
            response_data.extend([ord(c) for c in vin])
            
        elif info_type == 0x04:  # Calibration ID
            cal_id = "CAL001234567890"
            response_data.append(1)
            response_data.extend([ord(c) for c in cal_id[:16]])
            
        else:
            self._send_negative_response(request.arbitration_id, OBDMode.VEHICLE_INFO, info_type)
            return
        
        self._send_obd_response(request.arbitration_id, response_data)
    
    def _get_supported_pids_mask(self, pid_range: int) -> int:
        """Получение битовой маски поддерживаемых PID для указанного диапазона"""
        supported_pids = self.supported_pids.get(pid_range, [])
        mask = 0
        
        for pid in supported_pids:
            # Вычисление позиции бита (относительно диапазона)
            bit_position = pid - (pid_range + 1)
            if 0 <= bit_position < 32:
                mask |= (1 << (31 - bit_position))
        
        return mask
    
    def _encode_dtc(self, dtc_code: str) -> List[int]:
        """
        Кодирование DTC кода в байты
        Формат: PXXXX -> P = первый символ, XXXX = 4 цифры в hex
        """
        if len(dtc_code) != 5:
            return [0x00, 0x00]
        
        first_char = dtc_code[0].upper()
        number_part = dtc_code[1:]
        
        # Кодирование первого символа
        if first_char == 'P':
            first_byte = 0x00
        elif first_char == 'C':
            first_byte = 0x40
        elif first_char == 'B':
            first_byte = 0x80
        elif first_char == 'U':
            first_byte = 0xC0
        else:
            first_byte = 0x00
        
        try:
            # Кодирование числовой части
            number = int(number_part, 16)
            first_byte |= (number >> 8) & 0x3F
            second_byte = number & 0xFF
            
            return [first_byte, second_byte]
        except ValueError:
            return [0x00, 0x00]
    
    def _send_obd_response(self, request_id: int, response_data: List[int]):
        """Отправка OBD-II ответа"""
        try:
            # Для broadcast запросов (0x7DF) отвечаем от ECU (0x7E8)
            if request_id == 0x7DF:
                response_id = 0x7E8
            else:
                # Иначе ID ответа = ID запроса + 8
                response_id = request_id + 8
            
            # Добавляем длину данных в начало (ISO 15765-2)
            full_response = [len(response_data)] + response_data
            
            # Ограничение длины данных до 8 байт для стандартного CAN
            if len(full_response) > 8:
                full_response = full_response[:8]
            
            # Дополнение до 8 байт при необходимости
            while len(full_response) < 8:
                full_response.append(0x00)
            
            message = can.Message(
                arbitration_id=response_id,
                data=full_response,
                is_extended_id=False
            )
            
            if self.bus:
                self.bus.send(message)
                self.simulation_stats['responses_sent'] += 1
                
                self.logger.info(f"Отправлен OBD-II ответ: ID={response_id:03X}, "
                               f"Data={bytes(full_response).hex()}")
            
        except Exception as e:
            self.logger.error(f"Ошибка отправки OBD-II ответа: {e}")
    
    def _send_negative_response(self, request_id: int, mode: int, pid: int = None):
        """Отправка отрицательного ответа OBD-II"""
        response_id = request_id + 8
        negative_response = [0x7F, mode, 0x12]  # 0x12 = serviceNotSupported
        
        if pid is not None:
            negative_response.append(pid)
        
        # Дополнение до 8 байт
        while len(negative_response) < 8:
            negative_response.append(0x00)
        
        try:
            message = can.Message(
                arbitration_id=response_id,
                data=negative_response,
                is_extended_id=False
            )
            
            if self.bus:
                self.bus.send(message)
                self.logger.debug(f"Отправлен отрицательный ответ: Mode={mode:02X}, PID={pid:02X if pid else 'N/A'}")
                
        except Exception as e:
            self.logger.error(f"Ошибка отправки отрицательного ответа: {e}")
    
    def _initialize_demo_dtcs(self):
        """Инициализация демонстрационных кодов неисправности"""
        demo_codes = [
            DiagnosticTroubleCode(
                code="P0420",
                description="Эффективность катализатора ниже порога (банк 1)",
                status="confirmed"
            ),
            DiagnosticTroubleCode(
                code="P0171",
                description="Слишком бедная смесь (банк 1)",
                status="pending"
            ),
            DiagnosticTroubleCode(
                code="P0301",
                description="Пропуски зажигания в цилиндре 1",
                status="confirmed"
            )
        ]
        
        # Добавляем только некоторые коды для демонстрации
        if random.random() < 0.7:  # 70% вероятность наличия кодов
            self.dtc_codes.extend(random.sample(demo_codes, random.randint(1, 2)))
            self.vehicle.mil_status = True
            self.vehicle.dtc_count = len(self.dtc_codes)
    
    def _add_random_dtc(self):
        """Добавление случайного кода неисправности для демонстрации"""
        possible_codes = [
            ("P0100", "Неисправность датчика массового расхода воздуха"),
            ("P0110", "Неисправность датчика температуры воздуха на впуске"),
            ("P0130", "Неисправность датчика кислорода (банк 1, датчик 1)"),
            ("P0340", "Неисправность датчика положения распредвала"),
            ("P0505", "Неисправность системы управления холостым ходом"),
            ("U0001", "Высокоскоростная CAN шина связи"),
        ]
        
        if len(self.dtc_codes) < 5:  # Ограничение количества кодов
            code, description = random.choice(possible_codes)
            
            # Проверяем, что такого кода еще нет
            if not any(dtc.code == code for dtc in self.dtc_codes):
                new_dtc = DiagnosticTroubleCode(
                    code=code,
                    description=description,
                    status="pending"
                )
                self.dtc_codes.append(new_dtc)
                self.logger.info(f"Добавлен новый DTC: {code} - {description}")
                
                # Через некоторое время код может стать подтвержденным
                if random.random() < 0.3:  # 30% вероятность
                    new_dtc.status = "confirmed"
                    self.vehicle.mil_status = True
    
    def _print_statistics(self):
        """Вывод статистики работы симулятора"""
        if self.simulation_stats['start_time']:
            runtime = datetime.now() - self.simulation_stats['start_time']
            
            print("\n" + "="*60)
            print("СТАТИСТИКА СИМУЛЯТОРА CAN ШИНЫ")
            print("="*60)
            print(f"Время работы: {runtime}")
            print(f"Отправлено сообщений: {self.simulation_stats['messages_sent']}")
            print(f"Получено запросов: {self.simulation_stats['requests_received']}")
            print(f"Отправлено ответов: {self.simulation_stats['responses_sent']}")
            print(f"Ошибок: {self.simulation_stats['errors']}")
            print(f"Текущий сценарий: {self.current_scenario.value}")
            print(f"Активных DTC кодов: {len(self.dtc_codes)}")
            print("="*60)
    
    def get_current_state(self) -> Dict[str, Any]:
        """Получение текущего состояния автомобиля для внешних систем"""
        return {
            'engine': {
                'rpm': self.engine.rpm,
                'coolant_temp': self.engine.coolant_temp,
                'oil_temp': self.engine.oil_temp,
                'intake_air_temp': self.engine.intake_air_temp,
                'engine_load': self.engine.engine_load,
                'throttle_position': self.engine.throttle_position,
                'maf_flow': self.engine.maf_flow,
                'fuel_pressure': self.engine.fuel_pressure,
                'timing_advance': self.engine.timing_advance,
                'is_running': self.engine.is_running,
                'runtime_since_start': self.engine.runtime_since_start
            },
            'vehicle': {
                'speed': self.vehicle.speed,
                'odometer': self.vehicle.odometer,
                'fuel_level': self.vehicle.fuel_level,
                'battery_voltage': self.vehicle.battery_voltage,
                'ambient_temperature': self.vehicle.ambient_temperature,
                'barometric_pressure': self.vehicle.barometric_pressure,
                'mil_status': self.vehicle.mil_status,
                'dtc_count': self.vehicle.dtc_count
            },
            'scenario': self.current_scenario.value,
            'dtc_codes': [
                {
                    'code': dtc.code,
                    'description': dtc.description,
                    'status': dtc.status
                } for dtc in self.dtc_codes
            ]
        }


# ============================================================================
# Главная функция и обработка сигналов
# ============================================================================

def signal_handler(sig, frame):
    """Обработчик сигнала для корректной остановки симулятора"""
    print('\nПолучен сигнал остановки. Завершение работы...')
    if 'simulator' in globals():
        globals()['simulator'].stop()
    sys.exit(0)


def main():
    """Главная функция запуска симулятора"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Симулятор CAN шины с поддержкой OBD-II протокола',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры использования:
  %(prog)s --interface vcan0                    # Использовать виртуальный интерфейс
  %(prog)s --interface can0 --no-dtc           # Реальный интерфейс без DTC
  %(prog)s --interface vcan0 --log-level DEBUG # Подробное логирование
        """
    )
    
    parser.add_argument(
        '--interface', '-i',
        default='vcan0',
        help='Имя CAN интерфейса (по умолчанию: vcan0)'
    )
    
    parser.add_argument(
        '--no-dtc',
        action='store_true',
        help='Отключить симуляцию диагностических кодов'
    )
    
    parser.add_argument(
        '--log-level',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
        default='INFO',
        help='Уровень логирования (по умолчанию: INFO)'
    )
    
    args = parser.parse_args()
    
    # Настройка уровня логирования
    logging.getLogger().setLevel(getattr(logging, args.log_level))
    
    # Регистрация обработчиков сигналов
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        print(f"""
╔══════════════════════════════════════════════════════════════╗
║                    CAN Bus OBD-II Simulator                 ║
║                     Python Version 1.0                     ║
╠══════════════════════════════════════════════════════════════╣
║ Интерфейс: {args.interface:<47} ║
║ DTC симуляция: {('Включена' if not args.no_dtc else 'Отключена'):<42} ║
║ Уровень логирования: {args.log_level:<35} ║
╚══════════════════════════════════════════════════════════════╝
        """)
        
        # Создание и запуск симулятора
        global simulator
        simulator = CANBusSimulator(
            interface=args.interface,
            simulate_dtcs=not args.no_dtc
        )
        
        simulator.start()
        
        print("Симулятор запущен. Нажмите Ctrl+C для остановки.")
        print("Отправляйте OBD-II запросы на адреса 0x7E0-0x7E7")
        print("Ответы будут приходить с адресов 0x7E8-0x7EF")
        print("-" * 60)
        
        # Главный цикл - ожидание до получения сигнала остановки
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            pass
        
    except Exception as e:
        print(f"Критическая ошибка: {e}")
        return 1
    
    finally:
        if 'simulator' in globals():
            simulator.stop()
    
    return 0


if __name__ == "__main__":
    sys.exit(main())