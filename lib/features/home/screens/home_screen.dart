import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/core/providers/room_provider.dart';
import 'package:smart_warmth_2025/core/providers/wifi_provider.dart';
import 'package:smart_warmth_2025/features/home/widgets/wifi_setup_dialog.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showMenu = false;
  bool _isLoading = false;
  bool _hasShownWifiDialog = false;

  @override
  void initState() {
    super.initState();
    // Carica le stanze all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRooms();
      _checkWifiConfiguration();
    });
  }

  Future<void> _fetchRooms() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(roomsProvider.notifier).refreshRooms();
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore nel caricamento delle stanze: ${e.toString()}',
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

  Future<void> _checkWifiConfiguration() async {
    final wifiState = ref.read(wifiProvider);

    // Verifichiamo se è stata configurata una rete WiFi
    if (wifiState.savedSSID.isEmpty && !_hasShownWifiDialog) {
      // Mostriamo un dialogo per configurare la rete WiFi
      if (mounted) {
        setState(() {
          _hasShownWifiDialog = true;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const WifiSetupDialog(),
          );
        }
      }
    }
  }

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  Future<void> _logout() async {
    try {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore durante il logout: ${e.toString()}',
          type: OverlayAlertType.error,
        );
      }
    }
  }

  void _addRoom() {
    context.push('/add-room');
  }

  void _openRoom(String roomId) {
    context.push('/room/$roomId');
  }

  Future<void> _controlAllDevices(bool turnOn, String roomId) async {
    try {
      // Implementare la logica per accendere/spegnere tutti i dispositivi
      // Per ora mostriamo solo un messaggio
      ref.read(overlayAlertProvider.notifier).show(
        message: turnOn
            ? _getTranslation(TranslationKeys.devicesOn)
            : _getTranslation(TranslationKeys.devicesOff),
        type: OverlayAlertType.success,
      );
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore nel controllo dei dispositivi: ${e.toString()}',
          type: OverlayAlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final username = authState.user?.displayName ?? 'Utente';
    final rooms = ref.watch(roomsProvider);

    return OverlayAlertWrapper(
      child: AppScaffold(
        title: '${_getTranslation(TranslationKeys.houseOf)} $username',
        centerTitle: false,
        showBackButton: false,
        useDarkBackground: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _showMenu = !_showMenu;
              });
            },
          ),
        ],
        body: Stack(
          children: [
            SafeArea(
              child: GestureDetector(
                onTap: () {
                  if (_showMenu) {
                    setState(() {
                      _showMenu = false;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      else if (rooms.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTranslation(TranslationKeys.noRooms),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _getTranslation(TranslationKeys.addFirstRoom),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        )
                      else
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _fetchRooms,
                            color: Colors.white,
                            backgroundColor: const Color(0xFF04555C),
                            child:
                            ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: rooms.length,
                              itemBuilder: (context, index) {
                                final room = rooms[index];
                                // Calcola la temperatura media se ci sono dispositivi
                                final avgTemperature = room
                                    .thermostats.isNotEmpty
                                    ? room.thermostats
                                    .map((d) => d.ambientTemperature)
                                    .reduce((a, b) => a + b) /
                                    room.thermostats.length
                                    : 0.0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  color: const Color(0xFF2A2A2A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.white, width: 2.0),
                                  ),
                                  elevation: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start, // per permettere wrap su più righe
                                          children: [
                                            // Nome stanza
                                            Expanded(
                                              child: Text(
                                                room.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis, // Variante 1: taglia con ...
                                                maxLines: 2,                      // Variante 2: massimo 2 righe
                                                softWrap: true,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Row(
                                              children: [
                                                // Temperatura
                                                Row(
                                                  children: [
                                                    Text(
                                                      room.thermostats
                                                          .isNotEmpty
                                                          ? avgTemperature
                                                          .toStringAsFixed(
                                                          0)
                                                          : "0",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 26,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.thermostat,
                                                      color: Colors.white,
                                                      size: 30,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 16),
                                                // Icona stanza
                                                Icon(
                                                  _getRoomIcon(room.name),
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        // Pulsante Apri
                                        SizedBox(
                                          width: double.infinity,
                                          child: AppButton(
                                            text: _getTranslation(TranslationKeys.open),
                                            backgroundColor:
                                            const Color(0xFF95A3A4),
                                            textColor: Colors.white,
                                            onPressed: () => _openRoom(room.id),
                                            height: 50,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (rooms.isEmpty) SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: _getTranslation(TranslationKeys.newRoom),
                          style: AppButtonStyle.reversed,
                          leadingIcon:
                          const Icon(Icons.add_home, color: Colors.white),
                          onPressed: _addRoom,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Menu a tendina con più stile
            if (_showMenu)
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuItem(
                            text: _getTranslation(TranslationKeys.add),
                            backgroundColor: const Color(0xFF04555C),
                            onTap: () {
                              setState(() {
                                _showMenu = false;
                              });
                              context.push('/creation');
                              //_addRoom();
                            },
                            icon: Icons.add,
                          ),
                          _buildMenuItem(
                            text: _getTranslation(TranslationKeys.settings),
                            backgroundColor: Colors.grey.shade600,
                            onTap: () {
                              setState(() {
                                _showMenu = false;
                              });
                              context.push('/settings');
                            },
                            icon: Icons.settings,
                          ),
                          _buildMenuItem(
                            text: _getTranslation(TranslationKeys.contactUs),
                            backgroundColor: Colors.grey.shade600,
                            onTap: () {
                              setState(() {
                                _showMenu = false;
                              });
                              context.push('/authenticated-contact');
                            },
                            icon: Icons.mail,
                          ),
                          _buildMenuItem(
                            text: _getTranslation(TranslationKeys.exit),
                            backgroundColor: Colors.red.shade700,
                            onTap: () {
                              setState(() {
                                _showMenu = false;
                              });
                              _logout();
                            },
                            icon: Icons.exit_to_app,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper per determinare l'icona in base al nome della stanza
  IconData _getRoomIcon(String roomName) {
    final name = roomName.toLowerCase();

    if (name.contains('soggiorno') ||
        name.contains('salotto') ||
        name.contains('living')) {
      return Icons.weekend;
    } else if (name.contains('camera') ||
        name.contains('letto') ||
        name.contains('bedroom')) {
      return Icons.bed;
    } else if (name.contains('bagno') || name.contains('bath')) {
      return Icons.bathtub;
    } else if (name.contains('cucina') || name.contains('kitchen')) {
      return Icons.kitchen;
    } else if (name.contains('studio') || name.contains('office')) {
      return Icons.desk;
    } else if (name.contains('ingresso') || name.contains('entrance')) {
      return Icons.door_front_door;
    } else {
      return Icons.home;
    }
  }

  Widget _buildMenuItem({
    required String text,
    required Color backgroundColor,
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
            if (icon != null) Icon(icon, color: Colors.white, size: 22),
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
