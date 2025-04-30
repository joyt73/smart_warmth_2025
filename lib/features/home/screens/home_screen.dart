// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/core/providers/room_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Carica le stanze all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRooms();
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
                ? _getTranslation('devices_powered_on')
                : _getTranslation('devices_powered_off'),
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
        title: '${_getTranslation('house_of')} $username',
        centerTitle: false,
        showBackButton: false,
        useDarkBackground: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRooms,
          ),
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
                              _getTranslation('no_rooms'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _getTranslation('add_first_room'),
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
                            child: ListView.builder(
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Nome stanza
                                            Text(
                                              room.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            // Icone a destra
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
                                                // Icona letto/dispositivo
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
                                            text: _getTranslation('open'),
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
                          text: _getTranslation('new_room'),
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
                            text: _getTranslation('add'),
                            backgroundColor: AppTheme.primaryColor,
                            onTap: () {
                              setState(() {
                                _showMenu = false;
                              });
                              _addRoom();
                            },
                            icon: Icons.add,
                          ),
                          _buildMenuItem(
                            text: _getTranslation('settings'),
                            backgroundColor: Colors.grey.shade600,
                            onTap: () {
                              setState(() {
                                _showMenu = false;
                              });
                              context.push('/settings/wifi');
                            },
                            icon: Icons.settings,
                          ),
                          _buildMenuItem(
                            text: _getTranslation('contact_us'),
                            backgroundColor: Colors.grey.shade600,
                            onTap: () {
                              setState(() {
                                _showMenu = false;
                              });
                              context.push('/contact');
                            },
                            icon: Icons.mail,
                          ),
                          _buildMenuItem(
                            text: _getTranslation('exit'),
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
