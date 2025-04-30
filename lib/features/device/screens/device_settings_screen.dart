// lib/features/device/screens/device_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/device/models/device_model.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class DeviceSettingsScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceSettingsScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  ConsumerState<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends ConsumerState<DeviceSettingsScreen> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final devices = ref.read(devicesProvider);
    final device = devices.firstWhere((d) => d.id == widget.deviceId);
    _nameController = TextEditingController(text: device.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateDeviceName() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final devices = ref.read(devicesProvider);
      final device = devices.firstWhere((d) => d.id == widget.deviceId);

      final updatedDevice = device.copyWith(name: _nameController.text.trim());
      await ref.read(devicesProvider.notifier).updateDevice(updatedDevice);

      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: AppLocalizations.of(context).translate('device_updated'),
          type: OverlayAlertType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: AppLocalizations.of(context).translate('update_failed'),
          type: OverlayAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDevice() async {
    try {
      await ref.read(devicesProvider.notifier).removeDevice(widget.deviceId);

      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: AppLocalizations.of(context).translate('device_deleted'),
          type: OverlayAlertType.success,
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: AppLocalizations.of(context).translate('delete_failed'),
          type: OverlayAlertType.error,
        );
      }
    }
  }

  void _toggleFunction(device, String function) async {
    try {
      final functions = List<String>.from(device.functions);

      if (functions.contains(function)) {
        functions.remove(function);
      } else {
        functions.add(function);
      }

      final updatedDevice = device.copyWith(functions: functions);
      await ref.read(devicesProvider.notifier).updateDevice(updatedDevice);
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: AppLocalizations.of(context).translate('update_failed'),
          type: OverlayAlertType.error,
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('delete_device')),
          content: Text(
            AppLocalizations.of(context).translate('delete_device_confirmation'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteDevice();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(AppLocalizations.of(context).translate('delete')),
            ),
          ],
        );
      },
    );
  }

  void _pingDevice(device) async {
    try {
      // In un'app reale, qui chiameremmo un metodo per identificare il dispositivo
      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('device_ping_sent'),
        type: OverlayAlertType.info,
      );
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: AppLocalizations.of(context).translate('device_ping_failed'),
          type: OverlayAlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final device = devices.firstWhere((d) => d.id == widget.deviceId);

    return AppScaffold(
      title: AppLocalizations.of(context).translate('device_settings'),
      useDarkBackground: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('general'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextFieldWithLabel(
                AppLocalizations.of(context).translate('device_name'),
                _nameController,
              ),
              const SizedBox(height: 24),
              _buildSaveButton(),
              const SizedBox(height: 32),
              _buildFunctionsList(device),
              const SizedBox(height: 32),
              _buildAdvancedOptions(device),
              const SizedBox(height: 32),
              _buildDeleteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithLabel(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateDeviceName,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(AppLocalizations.of(context).translate('save')),
      ),
    );
  }

  Widget _buildFunctionsList(device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('functions'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFunctionItem(
          'window_detection',
          Icons.window,
          device.functions.contains('WINDOW'),
              () => _toggleFunction(device, 'WINDOW'),
        ),
        _buildFunctionItem(
          'child_protection',
          Icons.child_care,
          device.functions.contains('CHILD'),
              () => _toggleFunction(device, 'CHILD'),
        ),
        _buildFunctionItem(
          'eco_mode',
          Icons.eco,
          device.functions.contains('ECO'),
              () => _toggleFunction(device, 'ECO'),
        ),
        _buildFunctionItem(
          'adaptive_start',
          Icons.access_time_filled,
          device.functions.contains('ASC'),
              () => _toggleFunction(device, 'ASC'),
        ),
      ],
    );
  }

  Widget _buildFunctionItem(
      String translationKey,
      IconData icon,
      bool value,
      VoidCallback onToggle,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? AppTheme.primaryColor: Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate(translationKey),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeColor: AppTheme.primaryColor,
            activeTrackColor: Colors.teal.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptions(device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('advanced'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (device.type == DeviceType.wifi) ...[
          _buildAdvancedOption(
            'temperature_chart',
            Icons.show_chart,
                () => context.push('/device/${device.id}/temperature-chart'),
          ),
        ],
        _buildAdvancedOption(
          'ping_device',
          Icons.settings_remote,
              () => _pingDevice(device),
        ),
        if (device.type == DeviceType.wifi) ...[
          _buildAdvancedOption(
            'device_info',
            Icons.info_outline,
                () => _showDeviceInfo(device),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedOption(
      String translationKey,
      IconData icon,
      VoidCallback onTap,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate(translationKey),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceInfo(device) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('device_info')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('id', device.id),
              _infoRow('type', device.type == DeviceType.wifi ? 'WiFi' : 'Bluetooth'),
              _infoRow('version', device.version),
              _infoRow('status', device.online ? 'Online' : 'Offline'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).translate('close')),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context).translate(label),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showDeleteConfirmation,
        icon: const Icon(Icons.delete),
        label: Text(AppLocalizations.of(context).translate('delete_device')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}