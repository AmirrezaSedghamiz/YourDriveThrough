import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/MainProgram/Customer/MainPage/MainPageViewModel.dart';
import 'package:application/MainProgram/Customer/RestaurantMenu/RestaurantMenu.dart';
import 'package:application/SourceDesign/Enums/OrderStatus.dart';
import 'package:application/SourceDesign/Models/Order.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  final _searchTextC = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerHomeProvider.notifier).initIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchTextC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final state = ref.watch(customerHomeProvider);
    final vm = ref.read(customerHomeProvider.notifier);

    // keep controller text aligned with state (no rebuild bugs)
    if (_searchTextC.text != state.searchQuery) {
      _searchTextC.value = _searchTextC.value.copyWith(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
        composing: TextRange.empty,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _SearchBar(
                controller: _searchTextC,
                showClear: state.searchQuery.trim().isNotEmpty,
                onChanged: vm.setSearchQuery,
                onClear: () {
                  _searchTextC.clear();
                  vm.clearSearch();
                },
              ),

              if (state.showSearchResults) ...[
                const SizedBox(height: 14),
                Text(
                  "Search Results",
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 300,
                  child: PagedListView<int, RestaurantInfo>.separated(
                    pagingController: vm.searchPagingController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    builderDelegate: PagedChildBuilderDelegate<RestaurantInfo>(
                      itemBuilder: (ctx, r, i) => _RestaurantCard(
                        r: r,
                        onSelect: () {
                          var route = AppRoutes.fade(
                            RestaurantMenu(restaurantId: r.id ?? -1,
                            restaurantName: r.name,),
                          );
                          NavigationService.push(route);
                        },
                      ),
                      firstPageProgressIndicatorBuilder: (_) =>
                          _RestaurantCardSkeleton(),
                      newPageProgressIndicatorBuilder: (_) =>
                          _RestaurantCardSkeleton(),
                      noItemsFoundIndicatorBuilder: (_) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "No restaurants found.",
                          style: t.bodyMedium?.copyWith(
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (vm.searchPagingController.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "${vm.searchPagingController.error}",
                    style: t.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              Text(
                "Recommended Restaurants",
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 300,
                child: PagedListView<int, RestaurantInfo>.separated(
                  pagingController: vm.recommendedPagingController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  builderDelegate: PagedChildBuilderDelegate<RestaurantInfo>(
                    itemBuilder: (ctx, r, i) => _RestaurantCard(
                      r: r,
                      onSelect: () {
                        var route = AppRoutes.fade(
                          RestaurantMenu(restaurantId: r.id ?? -1 , 
                          restaurantName: r.name,),
                        );
                        NavigationService.push(route);
                      },
                    ),
                    firstPageProgressIndicatorBuilder: (_) =>
                        _RestaurantCardSkeleton(),
                    newPageProgressIndicatorBuilder: (_) =>
                        _RestaurantCardSkeleton(),
                    noItemsFoundIndicatorBuilder: (_) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "No recommendations right now.",
                        style: t.bodyMedium?.copyWith(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (vm.recommendedPagingController.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  "${vm.recommendedPagingController.error}",
                  style: t.bodySmall?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Text(
                "My Orders",
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),

              if (state.ordersLoading && state.orders.isEmpty)
                _OrdersLoading(t: t)
              else if (state.orders.isEmpty)
                Text(
                  "No orders yet.",
                  style: t.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ...state.orders.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OrderCard(
                      order: o,
                      isWorking: state.workingOrderId == o.id,
                      onReceive: o.status == OrderStatus.done
                          ? () async {
                              final ok = await _confirmReceive(context);
                              if (ok == true) await vm.markReceived(o.id);
                            }
                          : null,
                    ),
                  ),
                ),

              if (state.ordersError != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.ordersError!,
                  style: t.bodySmall?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmReceive(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Receive order?", style: t.titleMedium),
        content: Text(
          "Are you sure you want to mark this order as received?",
          style: t.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: t.labelLarge),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Yes, receive",
              style: t.labelLarge?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.black.withOpacity(0.55)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "Search restaurants",
                hintStyle: t.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
            ),
          ),
          if (showClear)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RestaurantsHorizontalList extends StatelessWidget {
  const _RestaurantsHorizontalList({
    required this.controller,
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.emptyText,
    required this.onSelect,
  });

  final ScrollController controller;
  final List<RestaurantInfo> items;
  final bool isLoading;
  final bool hasMore;
  final String emptyText;
  final ValueChanged<RestaurantInfo> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    if (items.isEmpty && !isLoading) {
      return Text(
        emptyText,
        style: t.bodyMedium?.copyWith(
          color: Colors.black.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length + (isLoading || hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          if (i >= items.length) {
            return _RestaurantCardSkeleton();
          }
          final r = items[i];
          return _RestaurantCard(r: r, onSelect: () => onSelect(r));
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.r, required this.onSelect});

  final RestaurantInfo r;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: 190,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              height: 120,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                if ((r.rating ?? 0) != 0)
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (r.rating ?? 0).toStringAsFixed(1),
                        style: t.bodySmall?.copyWith(
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),
                Text(
                  "• Detour +${(r.duration! / 60).toInt()} min",
                  style: t.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  r.isOpen ? "Available" : "Closed",
                  style: t.bodySmall?.copyWith(
                    color: r.isOpen
                        ? Colors.black.withOpacity(0.55)
                        : Colors.red.shade700.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GestureDetector(
              onTap: r.isOpen ? onSelect : () {},
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: r.isOpen ? AppColors.primary : AppColors.coal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Select",
                    style: t.labelLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: double.infinity,
            color: const Color(0xFFEFEFEF),
          ),
          const SizedBox(height: 8),
          Container(height: 10, width: 120, color: const Color(0xFFEFEFEF)),
          const Spacer(),
          Container(
            height: 40,
            width: double.infinity,
            color: const Color(0xFFEFEFEF),
          ),
        ],
      ),
    );
  }
}

class _OrdersLoading extends StatelessWidget {
  const _OrdersLoading({required this.t});
  final TextTheme t;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isWorking,
    required this.onReceive,
  });

  final Order order;
  final bool isWorking;
  final VoidCallback? onReceive;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (order.restaurantName ?? "Restaurant") +
                " • " +
                order.status.name.toUpperCase(),
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            "Total: \$${order.total} • ETA: ${order.expectedDuration} min",
            style: t.bodySmall?.copyWith(
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...order.items
              .take(3)
              .map(
                (it) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    "${it.quantity}× ${it.itemName}",
                    style: t.bodySmall?.copyWith(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          if (order.items.length > 3)
            Text(
              "+ ${order.items.length - 3} more",
              style: t.bodySmall?.copyWith(
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          if (onReceive != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isWorking ? null : onReceive,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isWorking
                      ? Colors.black.withOpacity(0.08)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isWorking ? "Updating..." : "Mark as received",
                    style: t.labelLarge?.copyWith(
                      color: isWorking
                          ? Colors.black.withOpacity(0.45)
                          : AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
