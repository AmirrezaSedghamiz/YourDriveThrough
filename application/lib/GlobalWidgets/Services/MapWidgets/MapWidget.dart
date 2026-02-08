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

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: const LatLng(35.715298, 51.404343),
        initialZoom: 18,
        onTap: (tapPosition, point) => onTapPoint(point),
      ),
      children: [
        TileLayer(
          urlTemplate:
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          // retinaMode: false,
          userAgentPackageName: 'com.example.driveThru',
        ),
        MarkerLayer(
          markers: [
            if (userLocation != null)
              Marker(
                point: LatLng(userLocation!.latitude!, userLocation!.longitude!),
                child: Icon(
                  CupertinoIcons.location_fill,
                  size: 40,
                  color: cs.primary,
                ),
              ),
            if (selectedLocation != null)
              Marker(
                point: selectedLocation!,
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: cs.error,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
