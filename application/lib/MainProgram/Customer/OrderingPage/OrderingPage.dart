// UserOrderHistory.dart
// Requires: infinite_scroll_pagination
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/SourceDesign/Models/Order.dart';
import 'package:application/SourceDesign/Models/ItemOrder.dart';
import 'package:application/SourceDesign/Enums/OrderStatus.dart';

class UserOrderHistory extends StatefulWidget {
  const UserOrderHistory({
    super.key,
    required this.fetchPage,
    this.pageSize = 20,
    this.firstPageKey = 1,
    this.onReorder,
    this.onOpenActive, // tap on active card
  });

  /// Should return:
  /// {
  ///   "isLastPage": bool,
  ///   "orders": List<Order>
  /// }
  final Future<dynamic> Function({
    required int pageKey,
    required int pageSize,
    required List<String>? statuses,
  }) fetchPage;

  final int pageSize;
  final int firstPageKey;

  final Future<void> Function(Order order)? onReorder;
  final VoidCallback? onOpenActive;

  @override
  State<UserOrderHistory> createState() => _UserOrderHistoryState();
}

class _UserOrderHistoryState extends State<UserOrderHistory>
    with AutomaticKeepAliveClientMixin<UserOrderHistory> {
  @override
  bool get wantKeepAlive => true;

  late final PagingController<int, Order> _pagingController;

  Order? _activeOrder;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: widget.firstPageKey)
      ..addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final res = await widget.fetchPage(
        pageKey: pageKey,
        pageSize: widget.pageSize,
        statuses: null,
      );

      final incoming = List<Order>.from(res["orders"] as List);

      // Active: pending / accepted / done
      final active = incoming.where((o) => _isActiveStatus(o.status)).toList();
      // Past: everything else
      final past = incoming.where((o) => !_isActiveStatus(o.status)).toList();

      // Keep one active pinned
      if (_activeOrder == null && active.isNotEmpty) {
        _activeOrder = active.first;
      }

      if (res["isLastPage"] == true) {
        _pagingController.appendLastPage(past);
      } else {
        _pagingController.appendPage(past, pageKey + 1);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.6,
        centerTitle: true,
        title: Text("Orders", style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _activeOrder = null;
          _pagingController.refresh();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Active Order
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              sliver: SliverToBoxAdapter(
                child: _activeOrder == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Active Order",
                            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          _ActiveOrderCard(
                            order: _activeOrder!,
                            onTap: widget.onOpenActive ??
                                () {
                                  // default: do nothing (you choose logic)
                                },
                          ),
                        ],
                      ),
              ),
            ),

            // Past Orders title
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, _activeOrder == null ? 16 : 8, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Past Orders",
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),

            // Past Orders list (paged)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: PagedSliverList<int, Order>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Order>(
                  firstPageProgressIndicatorBuilder: (_) => const _UserHistoryShimmerList(),
                  newPageProgressIndicatorBuilder: (_) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  firstPageErrorIndicatorBuilder: (_) => _ErrorState(
                    title: "Couldn’t load orders",
                    message: "${_pagingController.error}",
                    onRetry: _pagingController.refresh,
                  ),
                  newPageErrorIndicatorBuilder: (_) => _InlineError(
                    onRetry: _pagingController.retryLastFailedRequest,
                  ),
                  noItemsFoundIndicatorBuilder: (_) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text("No past orders.", style: t.bodyMedium),
                    ),
                  ),
                  itemBuilder: (context, order, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PastOrderCard(
                        order: order,
                        onReorder: () async {
                          try {
                            await (widget.onReorder?.call(order) ?? Future.value());
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text("Reorder failed: $e")));
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- Active Order UI ----------------

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final title = order.restaurantName ?? "Active Order";
    final status = _activeLabel(order.status);
    final step = _activeStepIndex(order.status);

    final estArrival = order.createdAt.add(Duration(minutes: (order.expectedDuration / 2).round()));
    final readyBy = order.createdAt.add(Duration(minutes: order.expectedDuration));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.30), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    status,
                    style: t.bodySmall?.copyWith(
                      color: Colors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _StepLine(step: step),

              const SizedBox(height: 12),

              // times
              Row(
                children: [
                  Expanded(
                    child: _KeyVal(
                      k: "Estimated arrival:",
                      v: _formatHm(context, estArrival),
                    ),
                  ),
                  Expanded(
                    child: _KeyVal(
                      k: "Ready by:",
                      v: _formatHm(context, readyBy),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({
    required this.k,
    required this.v,
    this.alignEnd = false,
  });

  final String k;
  final String v;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(k, style: t.bodySmall?.copyWith(color: Colors.black.withOpacity(0.55))),
        const SizedBox(height: 2),
        Text(v, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget dot(IconData icon, bool active) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFFF1F1F1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.white : Colors.black.withOpacity(0.35),
        ),
      );
    }

    Widget line(bool active) {
      return Expanded(
        child: Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.black.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            dot(Icons.check_circle_outline_rounded, step >= 0),
            line(step >= 1),
            dot(Icons.restaurant_rounded, step >= 1),
            line(step >= 2),
            dot(Icons.verified_rounded, step >= 2),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text("Ordered",
                  textAlign: TextAlign.center,
                  style: t.labelSmall?.copyWith(color: Colors.black.withOpacity(0.6))),
            ),
            Expanded(
              child: Text("Preparing",
                  textAlign: TextAlign.center,
                  style: t.labelSmall?.copyWith(color: Colors.black.withOpacity(0.6))),
            ),
            Expanded(
              child: Text("Ready",
                  textAlign: TextAlign.center,
                  style: t.labelSmall?.copyWith(color: Colors.black.withOpacity(0.6))),
            ),
          ],
        ),
      ],
    );
  }
}

/// ---------------- Past Orders UI ----------------

class _PastOrderCard extends StatelessWidget {
  const _PastOrderCard({
    required this.order,
    required this.onReorder,
  });

  final Order order;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final title = order.restaurantName ?? "Restaurant";
    final st = _pastStatus(order);
    final dateLine = _formatDateTimeLine(context, order.createdAt);
    final itemsLine = _compactItemsLine(order.items);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                _Chip(label: st.label, color: st.color),
              ],
            ),
            const SizedBox(height: 8),
            Text(dateLine, style: t.bodySmall?.copyWith(color: Colors.black.withOpacity(0.55))),
            const SizedBox(height: 8),
            Text(itemsLine, style: t.bodySmall?.copyWith(color: Colors.black.withOpacity(0.70))),
            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  _formatMoney(order.total),
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                _TapPill(
                  text: "Reorder",
                  onTap: onReorder,
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.07)),
            const SizedBox(height: 8),

            // rating (lightweight placeholder)
            Row(
              children: [
                Text("Eligible to rate", style: t.bodySmall?.copyWith(color: Colors.black.withOpacity(0.55))),
                const Spacer(),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(Icons.star_border_rounded, size: 18, color: AppColors.primary.withOpacity(0.9)),
                  ),
                ),
                const SizedBox(width: 8),
                Text("Rate", style: t.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TapPill extends StatelessWidget {
  const _TapPill({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.replay_rounded, size: 18, color: AppColors.white),
            const SizedBox(width: 8),
            Text(text, style: t.labelLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: t.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// ---------------- Status mapping ----------------

class _PastStatus {
  final String label;
  final Color color;
  const _PastStatus(this.label, this.color);
}

_PastStatus _pastStatus(Order o) {
  if (o.status == OrderStatus.canceled || o.status == OrderStatus.failed) {
    return _PastStatus("Cancelled", AppColors.primary);
  }
  return const _PastStatus("Completed", Color(0xFF3B3B3B));
}

bool _isActiveStatus(OrderStatus s) {
  return s == OrderStatus.pending || s == OrderStatus.accepted || s == OrderStatus.done;
}

int _activeStepIndex(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
      return 0;
    case OrderStatus.accepted:
      return 1;
    case OrderStatus.done:
      return 2;
    default:
      return 0;
  }
}

String _activeLabel(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
      return "In Progress";
    case OrderStatus.accepted:
      return "In Progress";
    case OrderStatus.done:
      return "In Progress";
    default:
      return "In Progress";
  }
}

/// ---------------- Formatting helpers ----------------

String _compactItemsLine(List<ItemOrder> items) {
  if (items.isEmpty) return "—";
  final totalQty = items.fold<int>(0, (s, it) => s + it.quantity);
  final names = items.take(3).map((e) => "${e.itemName} x${e.quantity}").join(", ");
  final more = items.length > 3 ? " +" : "";
  return "$totalQty items: $names$more";
}

String _formatHm(BuildContext context, DateTime dt) {
  return MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay.fromDateTime(dt));
}

String _formatDateTimeLine(BuildContext context, DateTime dt) {
  // "2023-10-26, 13:45"
  final d = "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  final tm = MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay.fromDateTime(dt), alwaysUse24HourFormat: true);
  return "$d, $tm";
}

String _formatMoney(num n) {
  // keep it simple: "$25.50"
  final v = n.toDouble();
  return "\$${v.toStringAsFixed(2)}";
}

/// ---------------- Shimmer (same method, lightweight) ----------------

class _UserHistoryShimmerList extends StatelessWidget {
  const _UserHistoryShimmerList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: _PastCardShimmer(),
        ),
      ),
    );
  }
}

class _PastCardShimmer extends StatelessWidget {
  const _PastCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              _ShimmerBlock(width: 140, height: 16, radius: 6),
              Spacer(),
              _ShimmerBlock(width: 90, height: 22, radius: 999),
            ],
          ),
          SizedBox(height: 10),
          _ShimmerBlock(width: 160, height: 12, radius: 6),
          SizedBox(height: 10),
          _ShimmerBlock(width: double.infinity, height: 12, radius: 6),
          SizedBox(height: 8),
          _ShimmerBlock(width: 220, height: 12, radius: 6),
          SizedBox(height: 12),
          Row(
            children: [
              _ShimmerBlock(width: 70, height: 14, radius: 6),
              Spacer(),
              _ShimmerBlock(width: 110, height: 38, radius: 10),
            ],
          ),
          SizedBox(height: 12),
          _ShimmerBlock(width: double.infinity, height: 12, radius: 6),
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
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFE7E7E7);

    return SizedBox(
      width: widget.width == double.infinity ? null : widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: base),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final dx = (_c.value * 2) - 1; // -1..+1
                return Transform.translate(
                  offset: Offset(dx * 220, 0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0x00FFFFFF), Color(0x55FFFFFF), Color(0x00FFFFFF)],
                        stops: [0.25, 0.5, 0.75],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- Errors ----------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
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
            Text(title, style: t.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Column(
          children: [
            Text("Failed to load more.", style: t.bodyMedium),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text("Try again")),
          ],
        ),
      ),
    );
  }
}
