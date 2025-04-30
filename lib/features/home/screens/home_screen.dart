// lib/features/home/screens/home_screen.dart (aggiornato)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/features/room/providers/room_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showMenu = false;

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  void _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  void _addRoom() {
    context.push('/add-room');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final rooms = ref.watch(roomsProvider);
    final username =  'Utente'; //authState.user?.displayName ?? 'Utente';

    return AppScaffold(
      title: '${_getTranslation('house_of')} $username',
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rooms.isEmpty) ...[
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
                    ] else ...[
                      Expanded(
                        child: ListView.builder(
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return
                              GestureDetector(
                                child: Card(child: Text(room.name),),
                                onTap: () => context.push('/room/${room.id}'),
                              );
                            // return RoomListItem(
                            //   room: room,
                            //   onTap: () => context.push('/room/${room.id}'),
                            // );
                          },
                        ),
                      ),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addRoom,
                        icon: const Icon(Icons.add_home),
                        label: Text(_getTranslation('new_room')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_showMenu)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, right: 16),
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
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
                          context.push('/add-device');
                        },
                        icon: Icons.add,
                      ),
                      _buildMenuItem(
                        text: _getTranslation('settings'),
                        backgroundColor: Colors.grey.shade400,
                        onTap: () {
                          setState(() {
                            _showMenu = false;
                          });
                          context.push('/settings');
                        },
                        icon: null,
                      ),
                      _buildMenuItem(
                        text: _getTranslation('contact_us'),
                        backgroundColor: Colors.grey.shade400,
                        onTap: () {
                          setState(() {
                            _showMenu = false;
                          });
                          context.push('/contact');
                        },
                        icon: null,
                      ),
                      _buildMenuItem(
                        text: _getTranslation('exit'),
                        backgroundColor: AppTheme.primaryColor,
                        onTap: () {
                          setState(() {
                            _showMenu = false;
                          });
                          _logout();
                        },
                        icon: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String text,
    required Color backgroundColor,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: Colors.white),
              if (icon != null) const SizedBox(width: 8),
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
      ),
    );
  }
}