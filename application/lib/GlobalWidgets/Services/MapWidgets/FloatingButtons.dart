// FloatingButtons.dart (UI polish only; props and behavior unchanged)
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MapSearchFab extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;
  const MapSearchFab({super.key, required this.expanded, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Positioned(
      top: 14,
      right: 14,
      child: _PrettyFab(
        heroTag: 'search',
        onPressed: onPressed,
        icon: expanded ? Icons.close_rounded : Icons.search_rounded,
        label: expanded ? "Close" : "Search",
        tooltip: expanded ? "Close search" : "Search address",
        t: t,
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
    final t = Theme.of(context).textTheme;

    return Positioned(
      bottom: 68,
      left: 14,
      child: _PrettyFab(
        heroTag: 'submit',
        onPressed: enabled ? onPressed : null,
        icon: Icons.check_rounded,
        label: "Confirm",
        tooltip: "Confirm destination",
        t: t,
        isLoading: isLoading,
        prominent: true,
        disabled: !enabled,
      ),
    );
  }
}

class MapCenterFab extends StatelessWidget {
  final VoidCallback onPressed;
  const MapCenterFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return _PrettyFab(
      heroTag: 'center',
      onPressed: onPressed,
      icon: Icons.my_location_rounded,
      label: "Center",
      tooltip: "Center on your location",
      t: t,
      asFloatingActionButton: true,
    );
  }
}

class _PrettyFab extends StatelessWidget {
  const _PrettyFab({
    required this.heroTag,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.t,
    this.isLoading = false,
    this.prominent = false,
    this.disabled = false,
    this.asFloatingActionButton = false,
  });

  final String heroTag;
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final String tooltip;
  final TextTheme t;
  final bool isLoading;
  final bool prominent;
  final bool disabled;
  final bool asFloatingActionButton;

  @override
  Widget build(BuildContext context) {
    final bg = prominent ? AppColors.primary : Colors.white.withOpacity(0.92);
    final fg = prominent ? AppColors.white : Colors.black.withOpacity(0.78);

    final child = Container(
      decoration: BoxDecoration(
        color: disabled ? Colors.black.withOpacity(0.10) : bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            LoadingAnimationWidget.fourRotatingDots(color: fg, size: 18)
          else
            Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    if (asFloatingActionButton) {
      // Keep it as a FAB entry point, but visually consistent
      return FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: prominent ? AppColors.primary : Colors.white,
        foregroundColor: prominent ? AppColors.white : Colors.black,
        elevation: 3,
        icon: Icon(icon),
        label: Text(label, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
      );
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}
