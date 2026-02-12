import 'dart:math';
import 'package:application/GlobalWidgets/Services/Tapsell.dart';
import 'package:application/MainProgram/Manager/PendingOrders/PendingOrders.dart';
import 'package:application/SourceDesign/Enums/OrderStatus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/ReusableComponents/PaginatedListContract.dart';
import 'package:application/SourceDesign/Models/Order.dart';
import 'package:application/SourceDesign/Models/ItemOrder.dart';

class OrdersHistoryPagedList extends StatefulWidget {
  const OrdersHistoryPagedList({
    super.key,
    required this.fetchPage,
    this.onReopen,
    this.pageSize = 20,
    this.firstPageKey = 1,
  });

  final Future<dynamic> Function({
    required int pageKey,
    required int pageSize,
    required List<String>? statuses,
  })
  fetchPage;

  /// If null, we just remove from UI (optimistic only).
  final Future<void> Function(Order order)? onReopen;

  final int pageSize;
  final int firstPageKey;

  @override
  State<OrdersHistoryPagedList> createState() => _OrdersHistoryPagedListState();
}

class _OrdersHistoryPagedListState extends State<OrdersHistoryPagedList>
    with AutomaticKeepAliveClientMixin<OrdersHistoryPagedList> {
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
      final res = await widget.fetchPage(
        pageKey: pageKey,
        pageSize: widget.pageSize,
        statuses: [],
      );
      if (res["isLastPage"]) {
        _pagingController.appendLastPage(res["orders"]);
      } else {
        _pagingController.appendPage(res["orders"], pageKey + 1);
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

  Future<void> _confirmReopen(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return AlertDialog(
          title: Text("Reopen this order?", style: t.titleLarge),
          content: Text(
            "This will reopen the order and remove it from history.",
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
                "Reopen",
                style: t.labelLarge?.copyWith(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    // optimistic remove (ONLY for reopen, as requested)
    final before = List<Order>.of(_pagingController.itemList ?? const []);
    _removeOrder(order.id);

    try {
      await (widget.onReopen?.call(order) ?? Future.value());
    } catch (e) {
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        shrinkWrap: true,
        builderDelegate: PagedChildBuilderDelegate<Order>(
          firstPageProgressIndicatorBuilder: (_) =>
              const OrdersHistoryShimmerList(),
          newPageProgressIndicatorBuilder: (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          firstPageErrorIndicatorBuilder: (_) => ErrorState(
            title: "Couldn’t load history",
            message: "${_pagingController.error}",
            onRetry: _pagingController.refresh,
          ),
          newPageErrorIndicatorBuilder: (_) =>
              InlineError(onRetry: _pagingController.retryLastFailedRequest),
          noItemsFoundIndicatorBuilder: (_) => Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text("No history orders.", style: t.bodyMedium),
                ),
              ),
              NativeAdWidget(
                zoneId: dotenv.env['TAPSELL_ZONE_ID'] ?? "",
                factoryId: "MY_FACTORY",
              ),
              SizedBox(height: 100),
            ],
          ),
          itemBuilder: (context, order, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _HistoryOrderCard(
                order: order,
                onReopen: () => _confirmReopen(order),
                onViewReceipt: () => _showReceiptSheet(context, order),
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

class _HistoryOrderCard extends StatefulWidget {
  const _HistoryOrderCard({
    required this.order,
    required this.onReopen,
    required this.onViewReceipt,
  });

  final Order order;
  final VoidCallback onReopen;
  final VoidCallback onViewReceipt;

  @override
  State<_HistoryOrderCard> createState() => _HistoryOrderCardState();
}

class _HistoryOrderCardState extends State<_HistoryOrderCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = widget.order;

    final code = "Order ${displayOrderCode(o)}";
    final status = _historyStatusFromOrder(o);
    final statusLabel = status.label;
    final statusColor = status.color;

    final dateLine = _formatDateLine(context, o.createdAt);
    final duration = "${o.expectedDuration} min";

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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _StatusChip(label: statusLabel, color: statusColor),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      dateLine,
                      style: t.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      duration,
                      style: t.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...o.items
                    .take(2)
                    .map(
                      (it) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text("• ", style: t.bodySmall),
                            Expanded(
                              child: Text(
                                "${it.itemName} x${it.quantity}",
                                style: t.bodySmall?.copyWith(
                                  color: Colors.black.withOpacity(0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                const SizedBox(height: 10),

                InkWell(
                  onTap: () => setState(() => expanded = !expanded),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: !expanded
                    ? []
                    : [
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.black.withOpacity(0.08),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          "Order Details:",
                          style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...o.items.map((it) {
                          final price = it.price ?? 0; // placeholder pricing
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• ", style: t.bodySmall),
                                Expanded(
                                  child: Text(
                                    "${it.itemName}  -  \$${price.toStringAsFixed(2)}",
                                    style: t.bodySmall?.copyWith(
                                      color: Colors.black.withOpacity(0.75),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 12),

                        // Customer Feedback section (placeholder like screenshot)
                        // Text(
                        //   "Customer Feedback:",
                        //   style: t.bodyMedium?.copyWith(
                        //     fontWeight: FontWeight.w700,
                        //   ),
                        // ),
                        // const SizedBox(height: 8),
                        // Row(
                        //   children: List.generate(
                        //     5,
                        //     (i) => Icon(
                        //       i < _mockStars(o)
                        //           ? Icons.star_rounded
                        //           : Icons.star_border_rounded,
                        //       size: 18,
                        //       color: Colors.black.withOpacity(0.65),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 6),
                        // Text(
                        //   _mockFeedbackText(o),
                        //   style: t.bodySmall?.copyWith(
                        //     color: Colors.black.withOpacity(0.65),
                        //     height: 1.25,
                        //   ),
                        // ),

                        // const SizedBox(height: 14),
                      

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: widget.onViewReceipt,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black.withOpacity(0.8),
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.35),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text("View Receipt", style: t.labelLarge),
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
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
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

Future<void> _showReceiptSheet(BuildContext context, Order order) {
  final t = Theme.of(context).textTheme;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final maxH = media.size.height * 0.82;

      double subtotal = 0;
      for (final it in order.items) {
        subtotal += (it.price ?? 0) * it.quantity;
      }

      final tax = subtotal * 0.12;
      final total = subtotal + tax;

      return Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Receipt",
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.black.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withOpacity(0.08),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReceiptRow(left: "Order", right: _displayHistoryCode(order)),
                  const SizedBox(height: 6),
                  _ReceiptRow(
                    left: "Placed",
                    right: _formatDateLine(ctx, order.createdAt),
                  ),
                  const SizedBox(height: 6),
                  _ReceiptRow(
                    left: "Duration",
                    right: "${order.expectedDuration} min",
                  ),

                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withOpacity(0.08),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    "Items",
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  ...order.items.map((it) {
                    final price = it.price ?? 0;
                    final line = price * it.quantity;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "${it.itemName}  x${it.quantity}",
                              style: t.bodyMedium?.copyWith(
                                color: Colors.black.withOpacity(0.78),
                              ),
                            ),
                          ),
                          Text(
                            "\$${line.toStringAsFixed(2)}",
                            style: t.bodyMedium?.copyWith(
                              color: Colors.black.withOpacity(0.78),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withOpacity(0.08),
                  ),
                  const SizedBox(height: 12),

                  _ReceiptRow(
                    left: "Subtotal",
                    right: "\$${subtotal.toStringAsFixed(2)}",
                  ),
                  const SizedBox(height: 6),
                  _ReceiptRow(
                    left: "Tax (12%)",
                    right: "\$${tax.toStringAsFixed(2)}",
                  ),
                  const SizedBox(height: 6),
                  _ReceiptRow(
                    left: "Total",
                    right: "\$${total.toStringAsFixed(2)}",
                    strong: true,
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Close",
                        style: t.labelLarge?.copyWith(color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.left,
    required this.right,
    this.strong = false,
  });

  final String left;
  final String right;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = strong
        ? t.bodyMedium?.copyWith(fontWeight: FontWeight.w800)
        : t.bodyMedium?.copyWith(color: Colors.black.withOpacity(0.75));

    return Row(
      children: [
        Text(left, style: s),
        const Spacer(),
        Text(right, style: s),
      ],
    );
  }
}

class _HistoryStatus {
  final String label;
  final Color color;
  final Color? bg;

  _HistoryStatus(this.label, this.color, {this.bg});
}

_HistoryStatus _historyStatusFromOrder(Order o) {
  switch (o.status) {
    case OrderStatus.canceled:
    case OrderStatus.failed:
      return _HistoryStatus(
        "Cancelled",
        AppColors.primary,
        bg: AppColors.primary.withOpacity(0.12),
      );

    case OrderStatus.recieved:
      return _HistoryStatus(
        "Completed",
        const Color(0xFF3B3B3B),
        bg: const Color(0xFF3B3B3B).withOpacity(0.10),
      );

    // These are NOT history-final, but in case they show up:
    case OrderStatus.pending:
    case OrderStatus.accepted:
    case OrderStatus.done:
      return _HistoryStatus(
        "In progress",
        const Color(0xFF3B3B3B),
        bg: const Color(0xFF3B3B3B).withOpacity(0.08),
      );
  }
}

/// ---------------- Code + formatting helpers ----------------

String _displayHistoryCode(Order o) {
  // "A1001" style
  // stable-ish short code based on ids, without crypto.
  final n =
      ((o.restaurantId ?? 0) * 100000) + ((o.customerId ?? 0) * 1000) + o.id;
  final s = (n % 9000) + 1000; // 1000..9999
  return "A$s";
}

String _formatDateLine(BuildContext context, DateTime dt) {
  // "10:30 AM, Oct 26"
  final time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(dt));
  final months = const [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  final m = months[dt.month - 1];
  return "$time, $m ${dt.day}";
}

/// ---------------- Mock pricing + feedback (UI-only placeholders) ----------------

// double _mockPriceFor(ItemOrder it) {
//   // simple deterministic pseudo-price based on name
//   final base = 2.5 + (it.itemName.length % 8) * 1.25;
//   return (base * 100).roundToDouble() / 100;
// }

// double _mockSubtotal(List<ItemOrder> items) {
//   double s = 0;
//   for (final it in items) {
//     s += _mockPriceFor(it) * it.quantity;
//   }
//   return s;
// }

int _mockStars(Order o) {
  return 3 + (o.id % 3); // 3..5
}

String _mockFeedbackText(Order o) {
  const texts = [
    "Great food, fast service!",
    "Tasty and on time. Thanks!",
    "Everything was perfect.",
    "Good quality. Would order again.",
  ];
  return texts[o.id % texts.length];
}

class OrdersHistoryShimmerList extends StatelessWidget {
  const OrdersHistoryShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        shrinkWrap: true,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: _HistoryCardShimmer(),
        ),
      ),
    );
  }
}

class _HistoryCardShimmer extends StatelessWidget {
  const _HistoryCardShimmer();

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
          Row(
            children: [
              ShimmerBlock(width: 120, height: 16, radius: 6),
              Spacer(),
              ShimmerBlock(width: 84, height: 22, radius: 999),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              ShimmerBlock(width: 140, height: 12, radius: 6),
              Spacer(),
              ShimmerBlock(width: 44, height: 12, radius: 6),
            ],
          ),
          SizedBox(height: 10),
          ShimmerBlock(width: 220, height: 12, radius: 6),
          SizedBox(height: 8),
          ShimmerBlock(width: 150, height: 12, radius: 6),
          SizedBox(height: 10),
          ShimmerBlock(width: 18, height: 18, radius: 6),
        ],
      ),
    );
  }
}
