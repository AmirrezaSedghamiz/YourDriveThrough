import 'package:application/MainProgram/Manager/PendingOrders/PendingOrders.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/ReusableComponents/PaginatedListContract.dart';
import 'package:application/SourceDesign/Models/Order.dart';
import 'package:application/SourceDesign/Models/ItemOrder.dart';

class OnGoingOrdersPagedList extends StatefulWidget {
  const OnGoingOrdersPagedList({
    super.key,
    required this.fetchPage,
    this.onMarkReady,
    this.pageSize = 20,
    this.firstPageKey = 1,
  });

  final Future<dynamic> Function({
    required int pageKey,
    required int pageSize,
    required List<String>? statuses,
  })
  fetchPage;

  final Future<void> Function(Order order)? onMarkReady;

  final int pageSize;
  final int firstPageKey;

  @override
  State<OnGoingOrdersPagedList> createState() => _OnGoingOrdersPagedListState();
}

class _OnGoingOrdersPagedListState extends State<OnGoingOrdersPagedList>
    with AutomaticKeepAliveClientMixin<OnGoingOrdersPagedList> {
  @override
  bool get wantKeepAlive => true;

  late final PagingController<int, Order> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: widget.firstPageKey)
      ..addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final res = await widget.fetchPage(pageKey: pageKey,
        pageSize: widget.pageSize,
        statuses: ["accepted"],);

      if (res.isLastPage) {
        _pagingController.appendLastPage(res.items);
      } else {
        _pagingController.appendPage(res.items, pageKey + 1);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  void _removeOrder(int orderId) {
    final list = _pagingController.itemList;
    if (list == null) return;
    _pagingController.itemList = List.of(list)
      ..removeWhere((o) => o.id == orderId);
  }

  Future<void> _confirmMarkReady(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return AlertDialog(
          title: Text("Mark Ready?", style: t.titleLarge),
          content: Text(
            "This will mark the order as ready. You may . Continue?",
            style: t.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text("Cancel", style: t.labelLarge),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                "Mark Ready",
                style: t.labelLarge!.copyWith(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    // optimistic remove
    final before = List<Order>.of(_pagingController.itemList ?? const []);
    _removeOrder(order.id);

    try {
      await (widget.onMarkReady?.call(order) ?? Future.value());
    } catch (e) {
      // rollback
      _pagingController.itemList = before;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async => _pagingController.refresh(),
      child: PagedListView<int, Order>(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        pagingController: _pagingController,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        builderDelegate: PagedChildBuilderDelegate<Order>(
          firstPageProgressIndicatorBuilder: (_) =>
              const OnGoingOrdersCardShimmerList(),
          newPageProgressIndicatorBuilder: (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          firstPageErrorIndicatorBuilder: (_) => ErrorState(
            title: "Couldn’t load orders",
            message: "${_pagingController.error}",
            onRetry: _pagingController.refresh,
          ),
          newPageErrorIndicatorBuilder: (_) =>
              InlineError(onRetry: _pagingController.retryLastFailedRequest),
          noItemsFoundIndicatorBuilder: (_) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text("No orders found.", style: t.bodyMedium),
            ),
          ),
          itemBuilder: (context, order, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ExpandableOrderCard(
                order: order,
                onMarkReady: () => _confirmMarkReady(order),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class _ExpandableOrderCard extends StatefulWidget {
  const _ExpandableOrderCard({required this.order, required this.onMarkReady});

  final Order order;
  final VoidCallback onMarkReady;

  @override
  State<_ExpandableOrderCard> createState() => _ExpandableOrderCardState();
}

class _ExpandableOrderCardState extends State<_ExpandableOrderCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = widget.order;

    final etaText = "${o.expectedDuration} min";
    final customerEta = _formatTime(
      context,
      o.createdAt.add(Duration(minutes: o.expectedDuration)),
    );
    final acceptedAgo = _timeAgo(o.createdAt);

    final summaryInline = _summaryInline(o.items);
    final specialInstructions = _specialInstructions(o.items);
    final readyTime = _formatTime(
      context,
      o.createdAt.add(Duration(minutes: o.expectedDuration)),
    );

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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Order ${displayOrderCode(o)}",
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            height: 3,
            width: 70,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          const SizedBox(height: 10),

          _InfoRow(
            icon: Icons.access_time,
            text: "ETA: $etaText (Customer ETA: $customerEta)",
          ),
          const SizedBox(height: 6),

          _InfoRow(
            icon: Icons.list_alt,
            text: summaryInline.isEmpty ? "—" : summaryInline,
          ),
          const SizedBox(height: 6),

          _InfoRow(
            icon: Icons.check_circle_outline,
            text: "Ordered $acceptedAgo",
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withOpacity(0.08),
          ),
          const SizedBox(height: 12),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: !expanded ? [] : [
                Text(
                  "Special Instructions:",
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  specialInstructions.isEmpty ? "—" : specialInstructions,
                  style: t.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.7),
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Estimated Ready:",
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  readyTime,
                  style: t.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onMarkReady,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Mark Ready",
                style: t.labelLarge?.copyWith(color: AppColors.white),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => expanded = !expanded),
              icon: Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.black.withOpacity(0.6),
              ),
              label: Text(
                expanded ? "View Less Details" : "View Full Details",
                style: t.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: t.bodySmall?.copyWith(
              color: Colors.black.withOpacity(0.75),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

String _summaryInline(List<ItemOrder> items) {
  if (items.isEmpty) return "";
  return items.map((it) => "${it.quantity}x ${it.itemName}").join(", ");
}

String _specialInstructions(List<ItemOrder> items) {
  final lines = <String>[];
  for (final it in items) {
    final s = it.special.trim();
    if (s.isEmpty) continue;
    lines.add("${it.itemName}: $s");
  }
  return lines.join("\n");
}

String _formatTime(BuildContext context, DateTime dt) {
  final tod = TimeOfDay.fromDateTime(dt);
  return MaterialLocalizations.of(context).formatTimeOfDay(tod);
}

String _timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  return "${diff.inDays}d ago";
}

class OnGoingOrdersCardShimmerList extends StatelessWidget {
  const OnGoingOrdersCardShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: _OrderCardShimmer(),
        ),
      ),
    );
  }
}

class _OrderCardShimmer extends StatelessWidget {
  const _OrderCardShimmer();

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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBlock(width: 120, height: 16, radius: 6),
          SizedBox(height: 10),
          ShimmerBlock(width: 70, height: 3, radius: 999),
          SizedBox(height: 12),

          ShimmerLine(),
          SizedBox(height: 8),
          ShimmerLine(w: 260),
          SizedBox(height: 8),
          ShimmerLine(w: 180),

          SizedBox(height: 12),
          ShimmerBlock(width: double.infinity, height: 1, radius: 0),
          SizedBox(height: 12),

          ShimmerBlock(width: double.infinity, height: 46, radius: 10),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: ShimmerBlock(width: 140, height: 14, radius: 8),
          ),
        ],
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  const ShimmerLine({super.key, this.w});
  final double? w;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerBlock(width: 16, height: 16, radius: 4),
        const SizedBox(width: 8),
        ShimmerBlock(width: w ?? 220, height: 12, radius: 6),
      ],
    );
  }
}
