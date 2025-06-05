// lib/features/room/screens/add_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/providers/room_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text_field.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class AddRoomScreen extends ConsumerStatefulWidget {
  const AddRoomScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends ConsumerState<AddRoomScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedRoomType;
  bool _isCustomName = false;

  final List<Map<String, dynamic>> _roomTypes = [
    {'id': 'living_room', 'name': 'living_room', 'icon': Icons.weekend},
    {'id': 'bedroom', 'name': 'bedroom', 'icon': Icons.bed},
    {'id': 'bathroom', 'name': 'bathroom', 'icon': Icons.bathtub},
    {'id': 'kitchen', 'name': 'kitchen', 'icon': Icons.kitchen},
    {'id': 'office', 'name': 'office', 'icon': Icons.desk},
    {'id': 'kids_room', 'name': 'kids_room', 'icon': Icons.child_care},
    {'id': 'custom', 'name': 'custom', 'icon': Icons.home},
  ];

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    // Verifica se è richiesto un nome personalizzato
    if (_selectedRoomType == 'custom' && _roomNameController.text.isEmpty) {
      ref.read(overlayAlertProvider.notifier).show(
        message: _getTranslation('room_name_required'),
        type: OverlayAlertType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Se è stato selezionato un tipo predefinito e non è stato immesso un nome personalizzato,
      // utilizziamo il nome del tipo
      final roomName = _isCustomName && _roomNameController.text.isNotEmpty
          ? _roomNameController.text
          : _selectedRoomType != null
          ? _getTranslation(_selectedRoomType!)
          : '';

      if (roomName.isEmpty) {
        ref.read(overlayAlertProvider.notifier).show(
          message: _getTranslation('room_name_required'),
          type: OverlayAlertType.error,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final success = await ref.read(roomsProvider.notifier).addRoom(roomName);

      if (success && mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: _getTranslation('room_added'),
          type: OverlayAlertType.success,
        );
        context.pop();
      } else if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: _getTranslation('error_adding_room'),
          type: OverlayAlertType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore: ${e.toString()}',
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

  void _selectRoomType(String typeId) {
    setState(() {
      _selectedRoomType = typeId;
      _isCustomName = typeId == 'custom';

      // Se è stato selezionato un tipo predefinito diverso da "custom",
      // preimpostiamo il nome ma permettiamo all'utente di modificarlo
      if (typeId != 'custom') {
        _roomNameController.text = _getTranslation(typeId);
      } else {
        _roomNameController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayAlertWrapper(child:
      //Container(color: Colors.orange, child:
      AppScaffold(
        title: _getTranslation('add_room'),
        useDarkBackground: true,

        body:
        Stack(
            children: [
        Padding(
        padding: const EdgeInsets.all(24.0),
        child:
        Form(
          key: _formKey,
          child: ListView(
            children: [
                  Text(
                    _getTranslation('room_type'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid di tipi di stanza
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _roomTypes.length,
                    itemBuilder: (context, index) {
                      final type = _roomTypes[index];
                      final bool isSelected = _selectedRoomType == type['id'];

                      return InkWell(
                        onTap: () => _selectRoomType(type['id']),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF04555C) : const Color(0xFF333232),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type['icon'],
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getTranslation(type['name']),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  AppTextField(
                    controller: _roomNameController,
                    label: _getTranslation('room_name'),
                    hintText: _getTranslation('enter_room_name'),
                    enabled: _selectedRoomType != null, // Abilitato solo se è stato selezionato un tipo
                    validator: (value) {
                      if (_selectedRoomType == 'custom' && (value == null || value.isEmpty)) {
                        return _getTranslation('room_name_required');
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Se l'utente modifica il testo, consideriamo che sta usando un nome personalizzato
                      if (value.isNotEmpty && _selectedRoomType != 'custom') {
                        setState(() {
                          _isCustomName = true;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: _getTranslation('save'),
                      style: AppButtonStyle.reversed,
                      isLoading: _isLoading,
                      onPressed: _selectedRoomType == null ? null : _saveRoom,
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ]),),
    );
  }
}