// MapWidget.dart (UI polish only – logic unchanged)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LocationData? userLocation;
  final LatLng? selectedLocation;
  final void Function(LatLng point) onTapPoint;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.userLocation,
    required this.selectedLocation,
    required this.onTapPoint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: const LatLng(35.715298, 51.404343),
            initialZoom: 18,
            onTap: (tapPosition, point) => onTapPoint(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.driveThru',
            ),
            MarkerLayer(
              markers: [
                if (userLocation != null)
                  Marker(
                    point: LatLng(userLocation!.latitude!, userLocation!.longitude!),
                    width: 70,
                    height: 60,
                    child: _PillMarker(
                      label: "You",
                      icon: CupertinoIcons.location_fill,
                      color: cs.primary,
                    ),
                  ),
                if (selectedLocation != null)
                  Marker(
                    point: selectedLocation!,
                    width: 90,
                    height: 64,
                    child: _PillMarker(
                      label: "Address",
                      icon: Icons.location_on_rounded,
                      color: cs.error,
                    ),
                  ),
              ],
            ),
          ],
        ),

        // tiny bottom-left helper (no logic change)
        Positioned(
          left: 14,
          bottom: 12,
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, size: 18, color: Colors.black.withOpacity(0.65)),
                  const SizedBox(width: 8),
                  Text(
                    "Tap map to pin destination",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.black.withOpacity(0.70),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PillMarker extends StatelessWidget {
  const _PillMarker({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: t.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
