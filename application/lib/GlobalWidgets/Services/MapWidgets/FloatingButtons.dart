import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MapSearchFab extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;
  const MapSearchFab({super.key, required this.expanded, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: FloatingActionButton(
        heroTag: 'search',
        onPressed: onPressed,
        child: Icon(expanded ? Icons.close : Icons.search),
      ),
    );
  }
}

class MapSubmitFab extends StatelessWidget {
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  const MapSubmitFab({
    super.key,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    return Positioned(
      bottom: 20,
      left: 20,
      child: FloatingActionButton(
        heroTag: 'submit',
        onPressed: enabled ? onPressed : null,
        child: isLoading
            ? Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: AppColors.white,
                  size: 20,
                ),
              )
            : Icon(Icons.check, color: AppColors.white),
      ),
    );
  }
}

class MapCenterFab extends StatelessWidget {
  final VoidCallback onPressed;
  const MapCenterFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.location_searching_rounded),
    );
  }
}
