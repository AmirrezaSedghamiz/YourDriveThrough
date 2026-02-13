// RestaurantMenu.dart
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/ReusableComponents/AppBar.dart';
import 'package:application/MainProgram/Customer/RestaurantMenu/OrderViewModel.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManager.dart';
import 'package:application/SourceDesign/Models/Item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'RestaurantMenuViewModel.dart';

class RestaurantMenu extends ConsumerStatefulWidget {
  const RestaurantMenu({super.key, required this.restaurantId});
  final int restaurantId;

  @override
  ConsumerState<RestaurantMenu> createState() => _RestaurantMenuState();
}

class _RestaurantMenuState extends ConsumerState<RestaurantMenu> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(restaurantMenuViewModelProvider.notifier)
          .init(widget.restaurantId);
    });
  }

  @override
  void didUpdateWidget(covariant RestaurantMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) {
      ref
          .read(restaurantMenuViewModelProvider.notifier)
          .init(widget.restaurantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantMenuViewModelProvider);
    final vm = ref.read(restaurantMenuViewModelProvider.notifier);
    final order = ref.watch(orderViewModelProvider);
    final orderVm = ref.read(orderViewModelProvider.notifier);

    // Show loading instead of returning a blank box
    if (state.restaurantId == null || state.isLoading) {
      return const _MenuShimmer();
    }

    if (state.error != null) {
      return _ErrorState(message: state.error!, onRetry: vm.refresh);
    }

    return Scaffold(
      appBar: AppAppBar(
        leading: GestureDetector(
          onTap: () {
            NavigationService.pop();
          },
          child: Icon(Icons.chevron_left),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: vm.refresh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: _Header(
                      title: state.restaurantName,
                      rating: state.rating,
                      waitText: state.waitRangeText,
                    ),
                  ),
                ),

                // category chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: state.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = state.categories[i];
                          final selected = i == state.selectedCategoryIndex;
                          return _Chip(
                            label: c.name,
                            selected: selected,
                            onTap: () => vm.selectCategory(i),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList.separated(
                    itemCount: state.selectedCategory?.item.length ?? 0,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = state.selectedCategory!.item[index];
                      return _MenuRow(
                        item: item,
                        onAdd: () => vm.openItem(item),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // detail sheet overlay
          if (state.selectedItem != null)
            _ItemDetailSheet(
              item: state.selectedItem!,
              qty: state.selectedQty,
              onClose: vm.closeItem,
              onMinus: vm.decQty,
              onPlus: vm.incQty,
              onAdd: () {
                final item = state.selectedItem!;
                final qty = state.selectedQty;
                orderVm.addItem(item, qty);
                vm.closeItem();
              },
            ),
          if (state.selectedItem == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openOrdersSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                order.draftLines.isEmpty
                                    ? "View Orders"
                                    : "Cart: ${order.draftLines.length} items • \$${order.draftTotal}",
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openOrdersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _OrdersSheet(),
    );
  }
}

class _OrdersSheet extends ConsumerWidget {
  const _OrdersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderViewModelProvider);
    final orderVm = ref.read(orderViewModelProvider.notifier);

    final menu = ref.watch(
      restaurantMenuViewModelProvider,
    ); // for restaurantName/id

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Draft Cart",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              if (order.draftLines.isEmpty)
                Text(
                  "No items yet.",
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...order.draftLines.map(
                  (l) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.item.name),
                    subtitle: Text("Qty: ${l.qty}"),
                    trailing: Text("\$${l.lineTotal}"),
                    onLongPress: () => orderVm.removeItem(l.item.id),
                  ),
                ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: order.isSubmitting
                          ? null
                          : () async {
                              await orderVm.submitDraft(
                                restaurantId: menu.restaurantId ?? 0,
                                restaurantName: menu.restaurantName,
                              );
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: order.draftLines.isEmpty
                              ? Colors.black.withOpacity(0.08)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            order.isSubmitting
                                ? "Submitting..."
                                : "Submit Order",
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: order.draftLines.isEmpty
                                      ? Colors.black.withOpacity(0.45)
                                      : AppColors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.black.withOpacity(0.08),
              ),
              const SizedBox(height: 14),

              Text(
                "Submitted Orders",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              if (order.submittedOrders.isEmpty)
                Text(
                  "No submitted orders yet.",
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...order.submittedOrders.map(
                  (o) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${o.restaurantName} • ${o.createdAt}",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        ...o.lines.map(
                          (l) => Row(
                            children: [
                              Expanded(child: Text("${l.qty}× ${l.item.name}")),
                              Text("\$${l.lineTotal}"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Total: \$${o.total}",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // FINALIZE button + confirmation dialog
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: order.isSubmitting || order.submittedOrders.isEmpty
                          ? null
                          : () async {
                              final ok = await _confirmFinalize(context);
                              if (ok == true) {
                                await orderVm.finalizeOrder();
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: order.submittedOrders.isEmpty ? Colors.grey : Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            order.isSubmitting
                                ? "Finalizing..."
                                : "Finalize Order",
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (order.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  order.error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmFinalize(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Finalize order?"),
        content: const Text(
          "This will confirm your submitted orders. You won’t be able to change them after this.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, finalize"),
          ),
        ],
      ),
    );
  }
}

/// ---------------- UI ----------------

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.rating,
    required this.waitText,
  });

  final String title;
  final num rating;
  final String waitText;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.star_rounded,
              size: 16,
              color: Colors.black.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: t.bodySmall?.copyWith(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Available",
              style: t.bodySmall?.copyWith(
                color: Colors.black.withOpacity(0.55),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.schedule_rounded,
              size: 16,
              color: Colors.black.withOpacity(0.55),
            ),
            const SizedBox(width: 4),
            Text(
              waitText,
              style: t.bodySmall?.copyWith(
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(
                Icons.restaurant_menu_rounded,
                size: 16,
                color: AppColors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: t.labelLarge?.copyWith(
                color: selected
                    ? AppColors.white
                    : Colors.black.withOpacity(0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onAdd});
  final Item item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  (item.description?.trim().isNotEmpty ?? false)
                      ? item.description!
                      : "—",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "\$${item.price}",
                      style: t.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.black.withOpacity(0.45),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${item.expectedDuration} min",
                      style: t.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // image placeholder (use your URL later)
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: item.image == null
                ? Icon(
                    Icons.fastfood_rounded,
                    color: Colors.black.withOpacity(0.35),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(item.image!, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(width: 10),

          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: AppColors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDetailSheet extends StatelessWidget {
  const _ItemDetailSheet({
    required this.item,
    required this.qty,
    required this.onClose,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  final Item item;
  final int qty;
  final VoidCallback onClose;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final total = (item.price * qty);

    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.35),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.black.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),

                  if ((item.description?.trim().isNotEmpty ?? false)) ...[
                    Text(
                      item.description!,
                      style: t.bodyMedium?.copyWith(
                        color: Colors.black.withOpacity(0.7),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Text(
                        "\$${item.price}",
                        style: t.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: Colors.black.withOpacity(0.45),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Ready in ${item.expectedDuration} min",
                        style: t.bodyMedium?.copyWith(
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withOpacity(0.08),
                  ),
                  const SizedBox(height: 14),

                  // qty row + add
                  Row(
                    children: [
                      _QtyButton(icon: Icons.remove, onTap: onMinus),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          "$qty",
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _QtyButton(icon: Icons.add, onTap: onPlus),
                      const Spacer(),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Add to Order (\$${total})",
                            style: t.labelLarge?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.black.withOpacity(0.75)),
      ),
    );
  }
}

/// ---------------- Loading + Error ----------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn’t load menu", style: t.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Retry",
                  style: t.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
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

class _MenuShimmer extends StatelessWidget {
  const _MenuShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: 6,
        itemBuilder: (_, i) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _MenuRowShimmer(),
        ),
      ),
    );
  }
}

class _MenuRowShimmer extends StatefulWidget {
  const _MenuRowShimmer();

  @override
  State<_MenuRowShimmer> createState() => _MenuRowShimmerState();
}

class _MenuRowShimmerState extends State<_MenuRowShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBlock(width: 140, height: 14, radius: 6),
                SizedBox(height: 8),
                ShimmerBlock(width: double.infinity, height: 10, radius: 6),
                SizedBox(height: 6),
                ShimmerBlock(width: 200, height: 10, radius: 6),
                SizedBox(height: 10),
                ShimmerBlock(width: 90, height: 12, radius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const ShimmerBlock(width: 62, height: 62, radius: 12),
          const SizedBox(width: 10),
          const ShimmerBlock(width: 34, height: 34, radius: 999),
        ],
      ),
    );
  }
}
