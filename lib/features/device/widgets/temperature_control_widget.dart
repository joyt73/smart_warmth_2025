// lib/features/device/widgets/temperature_control_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/device/models/device_model.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class TemperatureControlWidget extends ConsumerStatefulWidget {
  final String deviceId;

  const TemperatureControlWidget({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  ConsumerState<TemperatureControlWidget> createState() => _TemperatureControlWidgetState();
}

class _TemperatureControlWidgetState extends ConsumerState<TemperatureControlWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late double _currentTemperature;
  late DeviceMode _currentMode;
  bool _isAdjusting = false;
  bool _isUpdating = false;

  // Configurazione
  final double _minTemperature = 7.0;
  final double _maxTemperature = 30.0;
  final double _temperatureStep = 0.5;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initTemperature();
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initTemperature();
  }

  @override
  void didUpdateWidget(TemperatureControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.deviceId != widget.deviceId) {
      _initTemperature();
      _animationController.reset();
      _animationController.forward();
    } else {
      final device = _getDevice();
      if (device.mode != _currentMode ||
          (_currentMode == DeviceMode.comfort && device.comfortTemperature != _currentTemperature) ||
          (_currentMode == DeviceMode.economy && device.economyTemperature != _currentTemperature)) {
        _initTemperature();
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  void _initTemperature() {
    final device = _getDevice();
    _currentMode = device.mode;

    // Imposta la temperatura corrente in base alla modalità
    switch (_currentMode) {
      case DeviceMode.comfort:
        _currentTemperature = device.comfortTemperature;
        break;
      case DeviceMode.economy:
        _currentTemperature = device.economyTemperature;
        break;
      case DeviceMode.antIce:
        _currentTemperature = 7.0; // Temperatura fissa per antigelo
        break;
      case DeviceMode.boost:
        _currentTemperature = 30.0; // Temperatura massima per boost
        break;
      default:
        _currentTemperature = device.ambientTemperature;
        break;
    }
  }

  DeviceModel _getDevice() {
    final devices = ref.read(devicesProvider);
    return devices.firstWhere((d) => d.id == widget.deviceId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = _getDevice();
    final canAdjust = device.online &&
        (device.mode == DeviceMode.comfort ||
            device.mode == DeviceMode.economy);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo di temperatura e indicazione
              _buildTemperatureHeader(context, canAdjust),

              const SizedBox(height: 24),

              // Display principale della temperatura
              _buildTemperatureDisplay(context, canAdjust),

              const SizedBox(height: 24),

              // Controlli della temperatura (se può essere regolata)
              if (canAdjust)
                _buildTemperatureControls(),

              // Indicatore temperatura ambiente
              if (device.mode != DeviceMode.standby && device.online)
                _buildAmbientTemperature(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemperatureHeader(BuildContext context, bool canAdjust) {
    final device = _getDevice();
    String temperatureType;

    switch (device.mode) {
      case DeviceMode.comfort:
        temperatureType = AppLocalizations.of(context).translate('comfort_temperature');
        break;
      case DeviceMode.economy:
        temperatureType = AppLocalizations.of(context).translate('economy_temperature');
        break;
      case DeviceMode.antIce:
        temperatureType = AppLocalizations.of(context).translate('antifreeze_temperature');
        break;
      case DeviceMode.boost:
        temperatureType = AppLocalizations.of(context).translate('boost_temperature');
        break;
      default:
        temperatureType = AppLocalizations.of(context).translate('ambient_temperature');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        temperatureType,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(_animation.value),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTemperatureDisplay(BuildContext context, bool canAdjust) {
    return GestureDetector(
      onVerticalDragStart: canAdjust
          ? (_) => setState(() => _isAdjusting = true)
          : null,
      onVerticalDragEnd: canAdjust
          ? (_) {
        setState(() => _isAdjusting = false);
        _updateTemperature();
      }
          : null,
      onVerticalDragUpdate: canAdjust
          ? (details) {
        if (details.primaryDelta != null) {
          // Aggiusta la temperatura in base al movimento (verso l'alto aumenta)
          setState(() {
            // Invertiamo il segno perché trascinare verso l'alto aumenta la temperatura
            final change = -details.primaryDelta! * 0.05;
            _currentTemperature = (_currentTemperature + change)
                .clamp(_minTemperature, _maxTemperature);

            // Arrotondiamo al passo configurato
            _currentTemperature = ((_currentTemperature / _temperatureStep).round() *
                _temperatureStep);
          });
        }
      }
          : null,
      child: Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black26,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isAdjusting)
                const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                  size: 24,
                ),

              // Temperatura principale
              Text(
                '${_currentTemperature.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(_animation.value),
                ),
              ),

              if (_isAdjusting)
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pulsante per diminuire la temperatura
          _buildControlButton(
            icon: Icons.remove,
            onPressed: () {
              if (_currentTemperature > _minTemperature) {
                setState(() {
                  _currentTemperature -= _temperatureStep;
                });
                _updateTemperature();
              }
            },
          ),

          // Pulsante per aumentare la temperatura
          _buildControlButton(
            icon: Icons.add,
            onPressed: () {
              if (_currentTemperature < _maxTemperature) {
                setState(() {
                  _currentTemperature += _temperatureStep;
                });
                _updateTemperature();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isUpdating ? null : onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.white.withOpacity(0.3),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildAmbientTemperature(BuildContext context) {
    final device = _getDevice();

    // Mostra la temperatura ambiente solo se diversa dalla corrente
    final bool showAmbientTemperature =
        device.mode != DeviceMode.standby &&
            ((device.mode == DeviceMode.comfort && _currentTemperature != device.ambientTemperature) ||
                (device.mode == DeviceMode.economy && _currentTemperature != device.ambientTemperature));

    if (!showAmbientTemperature) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.thermostat,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).translate('current_ambient_temperature'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${device.ambientTemperature.toStringAsFixed(1)}°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTemperature() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final device = _getDevice();
      final isComfort = device.mode == DeviceMode.comfort;

      await ref.read(devicesProvider.notifier).setTemperature(
        widget.deviceId,
        _currentTemperature,
        isComfort,
      );

      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('temperature_updated'),
        type: OverlayAlertType.success,
      );
    } catch (e) {
      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('temperature_update_failed'),
        type: OverlayAlertType.error,
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }
}