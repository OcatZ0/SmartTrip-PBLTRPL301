import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/osm_tile_layers.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';

/// Result of [MapPinPickerScreen].
class PickedLocation {
  const PickedLocation({required this.name, required this.lat, required this.lng});

  final String name;
  final double lat;
  final double lng;
}

/// C2a. Pilih Lokasi di Peta (MapPinPicker): tap the map to drop a pin and
/// name the spot. Coordinates come from the tap itself, so no Geocoding API
/// call is needed (design spec Section 13 step 3).
class MapPinPickerScreen extends StatefulWidget {
  const MapPinPickerScreen({super.key});

  @override
  State<MapPinPickerScreen> createState() => _MapPinPickerScreenState();
}

class _MapPinPickerScreenState extends State<MapPinPickerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  LatLng? _pin;
  bool _showPinError = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final pin = _pin;
    setState(() => _showPinError = pin == null);
    if (!_formKey.currentState!.validate() || pin == null) return;

    Navigator.of(context).pop(
      PickedLocation(name: _nameController.text.trim(), lat: pin.latitude, lng: pin.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final pin = _pin;

    return Scaffold(
      backgroundColor: tokens.screenBackground,
      appBar: ScreenHeader(subtitle: l10n.mapPickerTitle),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: batamCenter,
                    initialZoom: 11,
                    onTap: (_, position) => setState(() {
                      _pin = position;
                      _showPinError = false;
                    }),
                  ),
                  children: [
                    osmTileLayer(),
                    MarkerLayer(
                      markers: [
                        if (pin != null)
                          Marker(
                            point: pin,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: Icon(Icons.location_on, size: 40, color: tokens.link),
                          ),
                      ],
                    ),
                    osmAttribution(),
                  ],
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: AppTokens.softShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_outlined, size: 18, color: tokens.link),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _showPinError ? l10n.mapPickerPinRequired : l10n.mapPickerHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _showPinError ? theme.colorScheme.error : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          BottomActionBar(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: l10n.mapPickerNameLabel,
                    hintText: l10n.mapPickerNameHint,
                    controller: _nameController,
                    prefixIcon: Icons.place_outlined,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    validator: (value) =>
                        (value?.trim() ?? '').isEmpty ? l10n.validationPlaceNameRequired : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTokens.radius),
                            ),
                          ),
                          child: Text(l10n.actionCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(label: l10n.actionSave, onPressed: _save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
