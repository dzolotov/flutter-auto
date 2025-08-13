import 'package:flutter/material.dart';
import '../../../core/theme/automotive_theme.dart';
import '../../../services/audio_manager.dart';

/// Виджет выбора источника аудио
/// Позволяет переключаться между Bluetooth, USB, AUX, радио и другими источниками
class SourceSelector extends StatelessWidget {
  final AudioZone zone;
  final ValueChanged<AudioSource> onSourceChanged;

  const SourceSelector({
    super.key,
    required this.zone,
    required this.onSourceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AutomotiveTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  Icons.input,
                  color: AutomotiveTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Источник звука',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  zone.currentSource.displayName,
                  style: TextStyle(
                    color: AutomotiveTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Сетка источников
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: AudioSource.values.map((source) {
                return _buildSourceCard(context, source);
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Информация об активном источнике
            _buildSourceInfo(context),
          ],
        ),
      ),
    );
  }

  /// Создает карточку источника
  Widget _buildSourceCard(BuildContext context, AudioSource source) {
    final isSelected = zone.currentSource == source;
    
    return GestureDetector(
      onTap: () => onSourceChanged(source),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
              ? AutomotiveTheme.primaryBlue.withOpacity(0.2)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AutomotiveTheme.primaryBlue 
                : Colors.grey[600]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSourceIcon(source),
              color: isSelected 
                  ? AutomotiveTheme.primaryBlue 
                  : Colors.grey[400],
              size: 32,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              source.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Индикатор состояния
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AutomotiveTheme.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Создает информационную панель активного источника
  Widget _buildSourceInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSourceIcon(zone.currentSource),
                color: AutomotiveTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getSourceStatusText(zone.currentSource),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildConnectionIndicator(),
            ],
          ),
          
          const SizedBox(height: 8),
          
          _buildSourceDetails(),
        ],
      ),
    );
  }

  /// Создает индикатор подключения
  Widget _buildConnectionIndicator() {
    final isConnected = _isSourceConnected(zone.currentSource);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected 
                ? AutomotiveTheme.successGreen 
                : AutomotiveTheme.warningRed,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isConnected ? 'Подключено' : 'Не подключено',
          style: TextStyle(
            color: isConnected 
                ? AutomotiveTheme.successGreen 
                : AutomotiveTheme.warningRed,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Создает детальную информацию об источнике
  Widget _buildSourceDetails() {
    switch (zone.currentSource) {
      case AudioSource.bluetooth:
        return _buildBluetoothDetails();
      case AudioSource.usb:
        return _buildUsbDetails();
      case AudioSource.aux:
        return _buildAuxDetails();
      case AudioSource.radio:
        return _buildRadioDetails();
      case AudioSource.cd:
        return _buildCdDetails();
      case AudioSource.streaming:
        return _buildStreamingDetails();
    }
  }

  /// Детали Bluetooth подключения
  Widget _buildBluetoothDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Устройство', 'iPhone Владимир'),
        _buildDetailRow('Кодек', 'aptX HD'),
        _buildDetailRow('Качество', '48 кГц / 24 бит'),
      ],
    );
  }

  /// Детали USB подключения
  Widget _buildUsbDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Накопитель', 'USB Flash 32GB'),
        _buildDetailRow('Файлов', '247 треков'),
        _buildDetailRow('Формат', 'MP3, FLAC'),
      ],
    );
  }

  /// Детали AUX подключения
  Widget _buildAuxDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Кабель', 'Аналоговый вход'),
        _buildDetailRow('Качество', '16 бит / 44.1 кГц'),
        _buildDetailRow('Уровень', 'Номинальный'),
      ],
    );
  }

  /// Детали радио
  Widget _buildRadioDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Частота', '${zone.radio.frequency.toStringAsFixed(1)} МГц'),
        _buildDetailRow('Станция', zone.radio.currentStation?.name ?? 'Неизвестно'),
        _buildDetailRow('Сигнал', '${(zone.radio.signalStrength * 100).toInt()}%'),
      ],
    );
  }

  /// Детали CD
  Widget _buildCdDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Диск', 'Audio CD'),
        _buildDetailRow('Треков', '12'),
        _buildDetailRow('Время', '47:32'),
      ],
    );
  }

  /// Детали стриминга
  Widget _buildStreamingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Сервис', 'Spotify Premium'),
        _buildDetailRow('Качество', 'Очень высокое'),
        _buildDetailRow('Подключение', 'Wi-Fi'),
      ],
    );
  }

  /// Создает строку с деталью
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Возвращает иконку источника
  IconData _getSourceIcon(AudioSource source) {
    switch (source) {
      case AudioSource.bluetooth:
        return Icons.bluetooth;
      case AudioSource.usb:
        return Icons.usb;
      case AudioSource.aux:
        return Icons.cable;
      case AudioSource.radio:
        return Icons.radio;
      case AudioSource.cd:
        return Icons.album;
      case AudioSource.streaming:
        return Icons.wifi;
    }
  }

  /// Возвращает текст статуса источника
  String _getSourceStatusText(AudioSource source) {
    switch (source) {
      case AudioSource.bluetooth:
        return 'Беспроводное аудио';
      case AudioSource.usb:
        return 'USB накопитель';
      case AudioSource.aux:
        return 'Аналоговый вход';
      case AudioSource.radio:
        return 'FM радиоприемник';
      case AudioSource.cd:
        return 'Компакт-диск';
      case AudioSource.streaming:
        return 'Потоковое аудио';
    }
  }

  /// Проверяет подключение источника
  bool _isSourceConnected(AudioSource source) {
    switch (source) {
      case AudioSource.bluetooth:
        return true; // Симуляция подключенного Bluetooth
      case AudioSource.usb:
        return true; // Симуляция подключенного USB
      case AudioSource.aux:
        return false; // Симуляция отключенного AUX
      case AudioSource.radio:
        return true; // Радио всегда доступно
      case AudioSource.cd:
        return false; // Симуляция отсутствия CD
      case AudioSource.streaming:
        return true; // Симуляция доступного стриминга
    }
  }
}