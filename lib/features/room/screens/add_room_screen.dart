// lib/features/room/screens/add_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/room/models/room_model.dart';
import 'package:smart_warmth_2025/features/room/providers/room_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class AddRoomScreen extends ConsumerStatefulWidget {
  const AddRoomScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends ConsumerState<AddRoomScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _selectedRoomType = 0;

  // Elenco di tipi di stanza predefiniti
  final List<Map<String, dynamic>> _roomTypes = [
    {'name': 'living_room', 'icon': Icons.weekend},
    {'name': 'bedroom', 'icon': Icons.bed},
    {'name': 'kitchen', 'icon': Icons.kitchen},
    {'name': 'bathroom', 'icon': Icons.bathtub},
    {'name': 'office', 'icon': Icons.computer},
    {'name': 'kids_room', 'icon': Icons.child_care},
    {'name': 'custom', 'icon': Icons.add},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addRoom() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final name = _nameController.text.trim();
        final room = RoomModel(
          id: '', // Il repository genererà un ID
          name: name,
        );

        await ref.read(roomsProvider.notifier).addRoom(room);

        if (mounted) {
          ref.read(overlayAlertProvider.notifier).show(
            message: AppLocalizations.of(context).translate('room_added'),
            type: OverlayAlertType.success,
          );
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ref.read(overlayAlertProvider.notifier).show(
            message: AppLocalizations.of(context).translate('error_adding_room'),
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
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppLocalizations.of(context).translate('add_room'),
      useDarkBackground: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('room_type'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRoomTypeGrid(),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).translate('room_name'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).translate('enter_room_name'),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context).translate('room_name_required');
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _addRoom(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
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
                        : Text(AppLocalizations.of(context).translate('add_room')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _roomTypes.length,
      itemBuilder: (context, index) {
        final roomType = _roomTypes[index];
        final isSelected = _selectedRoomType == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRoomType = index;
              if (index != _roomTypes.length - 1) { // Se non è "personalizzato"
                _nameController.text = AppLocalizations.of(context).translate(roomType['name']);
              } else {
                _nameController.text = '';
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  roomType['icon'] as IconData,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).translate(roomType['name']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}