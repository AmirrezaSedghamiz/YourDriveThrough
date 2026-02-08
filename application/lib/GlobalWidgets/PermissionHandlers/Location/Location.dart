import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/PermissionHandlers/Location/LocationState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;

class LocationService {
  Future<LocationState> getUserLocation() async {
    final location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return const LocationState.failure(LocationIssue.serviceDisabled);
      }
    }

    permissionGranted = await location.hasPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();

      if (permissionGranted != PermissionStatus.granted) {
        return const LocationState.failure(LocationIssue.permissionDenied);
      }
    }

    if (permissionGranted == PermissionStatus.deniedForever) {
      return const LocationState.failure(
        LocationIssue.permissionPermanentlyDenied,
      );
    }

    final userLocation = await location.getLocation();
    return LocationState.success(userLocation);
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Controller provider (Notifier).
final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState.idle();

  Future<void> requestLocation() async {
    state = const LocationState.loading();

    try {
      final svc = ref.read(locationServiceProvider);
      final result = await svc.getUserLocation();
      state = result;
    } catch (e) {
      state = const LocationState.error("Failed to get location.");
    }
  }

  void reset() => state = const LocationState.idle();
}

Future<void> showLocationFailSafeDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onRetry,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () async {
              await openAppSettings();
            },
            child: Text(
              "Open Settings",
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onRetry();
            },
            child: const Text("Retry"),
          ),
        ],
      );
    },
  );
}
