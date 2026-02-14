// ClosestRestaurantsPage.dart
import 'dart:math';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/MainProgram/Customer/MapPage/MapState.dart';
import 'package:application/MainProgram/Customer/MapPage/MapViewModel.dart';
import 'package:application/MainProgram/Customer/RestaurantMenu/RestaurantMenu.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:latlong2/latlong.dart';


class ClosestRestaurantsPage extends ConsumerStatefulWidget {
  const ClosestRestaurantsPage({super.key});

  @override
  ConsumerState<ClosestRestaurantsPage> createState() => _ClosestRestaurantsPageState();
}

class _ClosestRestaurantsPageState extends ConsumerState<ClosestRestaurantsPage> {
  final MapController _mapController = MapController();

  ProviderSubscription<ClosestRestaurantsState>? _sub;

  @override
  void initState() {
    super.initState();

    // init AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(closestRestaurantsProvider.notifier).init();
    });

    // listen to state changes and move map safely (post-frame)
    _sub = ref.listenManual<ClosestRestaurantsState>(
      closestRestaurantsProvider,
      (prev, next) {
        // when user location appears first time -> center map
        if (prev?.userLatLng == null && next.userLatLng != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(next.userLatLng!, 15);
          });
        }

        // when destination changes -> center between points
        if (prev?.destinationLatLng != next.destinationLatLng &&
            next.userLatLng != null &&
            next.destinationLatLng != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final center = _midPoint(next.userLatLng!, next.destinationLatLng!);
            _mapController.move(center, 13);
          });
        }

        // when restaurant highlighted -> move to it (but don’t fight user)
        if (prev?.highlightedRestaurant?.id != next.highlightedRestaurant?.id &&
            next.highlightedRestaurant != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final r = next.highlightedRestaurant!;
            _mapController.move(LatLng(r.latitude.toDouble(), r.longitude.toDouble()), 15);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = ref.watch(closestRestaurantsProvider);
    final vm = ref.read(closestRestaurantsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        title: Text("Closest Restaurants", style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              _MiniMapCard(
                mapController: _mapController,
                userLatLng: state.userLatLng,
                destinationLatLng: state.destinationLatLng,
                highlightedRestaurant: state.highlightedRestaurant,
                onTapMap: (point) => vm.setDestination(point),
                onCenterUser: () {
                  final u = state.userLatLng;
                  if (u == null) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController.move(u, 16);
                  });
                },
              ),

              const SizedBox(height: 12),

              // Instruction / empty hint (no destination yet)
              if (state.userLatLng == null) ...[
                _HintBox(
                  text: "Getting your location…\nIf it fails, allow location permission and pull to refresh.",
                ),
                const SizedBox(height: 12),
              ] else if (state.destinationLatLng == null) ...[
                _HintBox(
                  text: "Tap on the map to mark your destination.\nThen we’ll show the closest restaurants.",
                ),
                // IMPORTANT: show nothing else (no big empty list)
                const SizedBox(height: 2),
              ] else ...[
                Text(
                  "Restaurants",
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),

                // Vertical paginated list (fits your design)
                PagedListView<int, RestaurantInfo>.separated(
                  pagingController: vm.pagingController,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  builderDelegate: PagedChildBuilderDelegate<RestaurantInfo>(
                    itemBuilder: (_, r, __) => _RestaurantRowCard(
                      r: r,
                      onTap: () => vm.highlightRestaurant(r), // mark on map
                      onSelect: () {
                        final route = AppRoutes.fade(
                          RestaurantMenu(
                            restaurantId: r.id ?? -1,
                            restaurantName: r.name,
                          ),
                        );
                        NavigationService.push(route);
                      },
                    ),
                    firstPageProgressIndicatorBuilder: (_) =>
                        const _RestaurantRowSkeleton(),
                    newPageProgressIndicatorBuilder: (_) =>
                        const _RestaurantRowSkeleton(),
                    noItemsFoundIndicatorBuilder: (_) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "No restaurants found for this route.",
                        style: t.bodyMedium?.copyWith(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                if (vm.pagingController.error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    "${vm.pagingController.error}",
                    style: t.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  LatLng _midPoint(LatLng a, LatLng b) {
    return LatLng((a.latitude + b.latitude) / 2.0, (a.longitude + b.longitude) / 2.0);
  }
}

/// ---------- Mini Map Card ----------

class _MiniMapCard extends StatelessWidget {
  const _MiniMapCard({
    required this.mapController,
    required this.userLatLng,
    required this.destinationLatLng,
    required this.highlightedRestaurant,
    required this.onTapMap,
    required this.onCenterUser,
  });

  final MapController mapController;
  final LatLng? userLatLng;
  final LatLng? destinationLatLng;
  final RestaurantInfo? highlightedRestaurant;

  final ValueChanged<LatLng> onTapMap;
  final VoidCallback onCenterUser;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final markers = <Marker>[];

    if (userLatLng != null) {
      markers.add(
        Marker(
          width: 50,
          height: 50,
          point: userLatLng!,
          child: _PinDot(
            label: "You",
            dotColor: AppColors.primary,
          ),
        ),
      );
    }

    if (destinationLatLng != null) {
      markers.add(
        Marker(
          width: 55,
          height: 55,
          point: destinationLatLng!,
          child: const _PinDot(
            label: "Dest",
            dotColor: Colors.black,
          ),
        ),
      );
    }

    if (highlightedRestaurant != null) {
      markers.add(
        Marker(
          width: 54,
          height: 54,
          point: LatLng(
            highlightedRestaurant!.latitude.toDouble(),
            highlightedRestaurant!.longitude.toDouble(),
          ),
          child: _PinRestaurant(
            name: highlightedRestaurant!.name,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: userLatLng ?? const LatLng(35.6892, 51.3890),
                  initialZoom: 13,
                  onTap: (tapPos, point) => onTapMap(point),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.application',
                  ),
                  if (destinationLatLng != null && userLatLng != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [userLatLng!, destinationLatLng!],
                          strokeWidth: 4,
                          color: Colors.black.withOpacity(0.45),
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      destinationLatLng == null
                          ? "Tap map to set destination"
                          : "Destination set • pull to refresh",
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.75),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onCenterUser,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.my_location, size: 16, color: Colors.black.withOpacity(0.65)),
                          const SizedBox(width: 6),
                          Text(
                            "Center",
                            style: t.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({required this.label, required this.dotColor});

  final String label;
  final Color dotColor;

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
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            style: t.labelSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: dotColor,
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

class _PinRestaurant extends StatelessWidget {
  const _PinRestaurant({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ],
    );
  }
}

/// ---------- Restaurant Row Card (Vertical) ----------

class _RestaurantRowCard extends StatelessWidget {
  const _RestaurantRowCard({
    required this.r,
    required this.onTap,
    required this.onSelect,
  });

  final RestaurantInfo r;
  final VoidCallback onTap; // mark on map
  final VoidCallback onSelect; // go to menu

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final durationMin = ((r.duration ?? 0) / 60).floor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 74,
                height: 74,
                color: const Color(0xFFEFEFEF),
                child: r.image == null
                    ? Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: Colors.black.withOpacity(0.35),
                        ),
                      )
                    : Image.network(
                        HttpClient.instanceImage + r.image!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((r.rating ?? 0) != 0) ...[
                        Icon(Icons.star_rounded, size: 16, color: Colors.black.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          (r.rating ?? 0).toStringAsFixed(1),
                          style: t.bodySmall?.copyWith(
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.schedule_rounded, size: 16, color: Colors.black.withOpacity(0.45)),
                      const SizedBox(width: 4),
                      Text(
                        durationMin <= 0 ? "—" : "$durationMin min",
                        style: t.bodySmall?.copyWith(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        r.isOpen ? "Available" : "Closed",
                        style: t.bodySmall?.copyWith(
                          color: r.isOpen
                              ? Colors.black.withOpacity(0.55)
                              : Colors.red.shade700.withOpacity(0.9),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // select button
            GestureDetector(
              onTap: r.isOpen ? onSelect : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: r.isOpen ? AppColors.primary : Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Select",
                  style: t.labelLarge?.copyWith(
                    color: r.isOpen ? AppColors.white : Colors.black.withOpacity(0.45),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Skeleton ----------

class _RestaurantRowSkeleton extends StatelessWidget {
  const _RestaurantRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: const [
          _ShimmerBlock(width: 74, height: 74, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(width: 180, height: 12, radius: 6),
                SizedBox(height: 10),
                _ShimmerBlock(width: 220, height: 10, radius: 6),
                SizedBox(height: 12),
                _ShimmerBlock(width: 160, height: 10, radius: 6),
              ],
            ),
          ),
          SizedBox(width: 10),
          _ShimmerBlock(width: 76, height: 42, radius: 14),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = _c.value; // 0..1
        final a = 0.10 + (0.10 * sin(v * 2 * pi)).abs();

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFFEFEFEF), const Color(0xFFDCDCDC), a),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(
        text,
        style: t.bodyMedium?.copyWith(
          color: Colors.black.withOpacity(0.65),
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
