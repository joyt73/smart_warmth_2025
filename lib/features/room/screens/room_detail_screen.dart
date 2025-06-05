import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/room_provider.dart';
import 'package:smart_warmth_2025/core/graphql/models/room_model.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text_field.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailScreen({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _showOptionsMenu = false;
  RoomModel? _room;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRoom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final room =
          await ref.read(roomsProvider.notifier).findRoomById(widget.roomId);
      if (mounted) {
        setState(() {
          _room = room;
          _nameController.text = room!.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
              message: 'Errore nel caricamento della stanza: ${e.toString()}',
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

  Future<void> _saveRoom() async {
    if (_nameController.text.isEmpty) {
      ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation(TranslationKeys.nameRequired),
            type: OverlayAlertType.warning,
          );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_room != null) {
        // Creiamo una copia aggiornata della stanza con il nuovo nome
        final updatedRoom = _room!.copyWith(name: _nameController.text);

        // Chiamiamo il metodo corretto con il parametro giusto
        final success =
            await ref.read(roomsProvider.notifier).updateRoomName(updatedRoom);

        if (mounted) {
          if (success) {
            ref.read(overlayAlertProvider.notifier).show(
                  message: _getTranslation(TranslationKeys.roomUpdated),
                  type: OverlayAlertType.success,
                );
            setState(() {
              _room = updatedRoom; // Aggiorniamo anche lo stato locale
              _isEditing = false;
            });
          } else {
            ref.read(overlayAlertProvider.notifier).show(
                  message: _getTranslation(TranslationKeys.errorUpdatingRoom),
                  type: OverlayAlertType.error,
                );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
              message: 'Errore nel salvataggio della stanza: ${e.toString()}',
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

  Future<void> _deleteRoom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mostra un dialogo di conferma
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF333232),
          title: Text(
            _getTranslation(TranslationKeys.deleteRoom),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            _getTranslation(TranslationKeys.deleteRoomConfirmation),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                _getTranslation(TranslationKeys.cancel),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                _getTranslation(TranslationKeys.delete),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Procedi con l'eliminazione della stanza
      if (_room != null) {
        await ref.read(roomsProvider.notifier).deleteRoom(_room!.id);

        if (mounted) {
          ref.read(overlayAlertProvider.notifier).show(
                message: _getTranslation(TranslationKeys.roomDeleted),
                type: OverlayAlertType.success,
              );
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ref.read(overlayAlertProvider.notifier).show(
              message:
                  'Errore nell\'eliminazione della stanza: ${e.toString()}',
              type: OverlayAlertType.error,
            );
      }
    }
  }

  Future<void> _powerAllDevices(bool turnOn) async {
    if (_room == null || _room!.thermostats.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showOptionsMenu = false;
    });

    try {
      // Qui usiamo il metodo corretto dal provider
      final success = await ref
          .read(roomsProvider.notifier)
          .controlAllDevicesInRoom(_room!.id, turnOn);

      if (mounted) {
        if (success) {
          ref.read(overlayAlertProvider.notifier).show(
                message: turnOn
                    ? _getTranslation(TranslationKeys.devicesOn)
                    : _getTranslation(TranslationKeys.devicesOff),
                type: OverlayAlertType.success,
              );
        } else {
          ref.read(overlayAlertProvider.notifier).show(
                message:
                    _getTranslation(TranslationKeys.errorControllingDevices),
                type: OverlayAlertType.error,
              );
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
              message: 'Errore nel controllo dei dispositivi: ${e.toString()}',
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

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayAlertWrapper(
        child: AppScaffold(
      title: _room?.name ?? '',
      showBackButton: true,
      useDarkBackground: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            setState(() {
              _showOptionsMenu = !_showOptionsMenu;
            });
            print("_showOptionsMenu - appBar: $_showOptionsMenu");
          },
        ),
      ],
      body: Stack(
        children: [
          SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                print("_showOptionsMenu - SafeArea: $_showOptionsMenu");
                if (_showOptionsMenu) {
                  setState(() {
                    _showOptionsMenu = false;
                  });
                }
              },
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _room == null
                      ? Center(
                          child: Text(
                            _getTranslation(TranslationKeys.roomNotFound),
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTranslation(TranslationKeys.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _isEditing
                                  ? AppTextField(
                                      controller: _nameController,
                                      hintText: _getTranslation(
                                          TranslationKeys.enterRoomName),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF95A3A4),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        _room!.name,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _isEditing
                                      ? Expanded(
                                          child: AppButton(
                                            text: _getTranslation(
                                                TranslationKeys.save),
                                            style: AppButtonStyle.reversed,
                                            height: 40,
                                            onPressed: _saveRoom,
                                          ),
                                        )
                                      : Expanded(
                                          child: AppButton(
                                            text: _getTranslation(
                                                TranslationKeys.edit),
                                            style: AppButtonStyle.secondary,
                                            height: 40,
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            },
                                          ),
                                        ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getTranslation(TranslationKeys.devices),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      context.push(
                                          '/room/${_room!.id}/add-device');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _room!.thermostats.isEmpty
                                    ? Center(
                                        child: Text(
                                          _getTranslation(
                                              TranslationKeys.noDevices),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _room!.thermostats.length,
                                        itemBuilder: (context, index) {
                                          final device =
                                              _room!.thermostats[index];
                                          return Card(
                                            margin: const EdgeInsets.only(
                                                bottom: 16),
                                            color: const Color(0xFF2A2A2A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: device.online
                                                    ? Colors.white
                                                    : Colors.grey,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                context.push(
                                                    '/device/${device.id}');
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          device.name,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Icon(
                                                          device.online
                                                              ? Icons.wifi
                                                              : Icons.wifi_off,
                                                          color: device.online
                                                              ? Colors.white
                                                              : Colors.grey,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          '${_getTranslation(TranslationKeys.mode)}: ${_getDeviceModeName(device.mode)}',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '${device.ambientTemperature.toStringAsFixed(1)}°C',
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            const Icon(
                                                              Icons.thermostat,
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: AppButton(
                                                            text: _getTranslation(
                                                                TranslationKeys
                                                                    .open),
                                                            style:
                                                                AppButtonStyle
                                                                    .primary,
                                                            height: 40,
                                                            onPressed: () {
                                                              context.push(
                                                                  '/device/${device.id}');
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          // Menu a tendina con opzioni
          if (_showOptionsMenu && _room != null)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Card(
                  margin: const EdgeInsets.only(top: 8, right: 16),
                  color: const Color(0xFF333232),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuItem(
                          text: _getTranslation(TranslationKeys.save),
                          backgroundColor: const Color(0xFF04555C),
                          onTap: () {
                            setState(() {
                              _showOptionsMenu = false;
                            });
                            _saveRoom();
                          },
                          icon: Icons.save,
                        ),
                        _buildMenuItem(
                          text: _getTranslation(TranslationKeys.turnAllOn),
                          backgroundColor: Colors.grey.shade600,
                          onTap: () => _powerAllDevices(true),
                          icon: Icons.power_settings_new,
                          iconColor: Colors.greenAccent.shade700,
                        ),
                        _buildMenuItem(
                          text: _getTranslation(TranslationKeys.turnAllOff),
                          backgroundColor: Colors.grey.shade600,
                          onTap: () => _powerAllDevices(false),
                          icon: Icons.power_settings_new,
                          iconColor: Colors.redAccent.shade700,
                        ),
                        _buildMenuItem(
                          text: _getTranslation(TranslationKeys.delete),
                          backgroundColor: Colors.red.shade700,
                          onTap: () {
                            setState(() {
                              _showOptionsMenu = false;
                            });
                            _deleteRoom();
                          },
                          icon: Icons.delete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ));
  }

  String _getDeviceModeName(String mode) {
    switch (mode) {
      case 'COMFORT':
        return _getTranslation(TranslationKeys.comfort);
      case 'ECONOMY':
        return _getTranslation(TranslationKeys.economy);
      case 'STANDBY':
        return _getTranslation(TranslationKeys.standby);
      case 'SCHEDULE':
        return _getTranslation(TranslationKeys.schedule);
      case 'BOOST':
        return _getTranslation(TranslationKeys.boost);
      case 'ANT_ICE':
        return _getTranslation(TranslationKeys.antiFrost);
      default:
        return mode;
    }
  }

  Widget _buildMenuItem({
    required String text,
    required Color backgroundColor,
    Color? iconColor,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 250,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, color: iconColor ?? Colors.white, size: 22),
            if (icon != null) const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
