import 'dart:convert';
import 'package:application/GlobalWidgets/ReusableComponents/PaginatedListContract.dart';
import 'package:application/GlobalWidgets/Services/Tapsell.dart';
import 'package:application/SourceDesign/Models/ItemOrder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/SourceDesign/Models/Order.dart';
import 'package:application/SourceDesign/Enums/OrderStatus.dart';

class PendingOrdersPagedList extends StatefulWidget {
  const PendingOrdersPagedList({
    super.key,
    required this.fetchPage,
    this.onAccept,
    this.onDecline,
    this.pageSize = 20,
    this.firstPageKey = 1,
  });

  final Future<dynamic> Function({
    required int pageKey,
    required int pageSize,
    required List<String>? statuses,
  })
  fetchPage;
  final Future<void> Function(Order order)? onAccept;
  final Future<void> Function(Order order)? onDecline;

  final int pageSize;
  final int firstPageKey;

  @override
  State<PendingOrdersPagedList> createState() => _PendingOrdersPagedListState();
}

class _PendingOrdersPagedListState extends State<PendingOrdersPagedList>
    with AutomaticKeepAliveClientMixin<PendingOrdersPagedList> {
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
        statuses: ["pending"],);

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

  Future<void> _confirmAndAct({
    required Order order,
    required String title,
    required String message,
    required Color confirmColor,
    required String confirmText,
    required Future<void> Function()? onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return AlertDialog(
          title: Text(title, style: t.titleLarge),
          content: Text(message, style: t.bodyMedium),
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
                confirmText,
                style: t.labelLarge!.copyWith(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    // Optimistic remove (so UX is snappy)
    _removeOrder(order.id);

    // Call API later (optional). If it fails, we rollback.
    final before = List<Order>.of(_pagingController.itemList ?? const []);
    try {
      await (onConfirm?.call() ?? Future.value());
    } catch (_) {
      // rollback
      _pagingController.itemList = before;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action failed. Please try again.")),
      );
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
        shrinkWrap: true,
        pagingController: _pagingController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        builderDelegate: PagedChildBuilderDelegate<Order>(
          firstPageProgressIndicatorBuilder: (_) => const OrdersShimmerList(),
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
          noItemsFoundIndicatorBuilder: (_) => Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text("No orders found.", style: t.bodyMedium),
                ),
              ),
              NativeAdWidget(zoneId: dotenv.env['TAPSELL_ZONE_ID'] ?? "", factoryId: "MY_FACTORY"),
              SizedBox(height: 100,)
            ],
          ),
          itemBuilder: (context, order, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PendingOrdersCard(
                order: order,
                onAccept: () => _confirmAndAct(
                  order: order,
                  title: "Accept order?",
                  message: "This will move the order forward. Continue?",
                  confirmColor: AppColors.primary,
                  confirmText: "Accept",
                  onConfirm: widget.onAccept == null
                      ? null
                      : () => widget.onAccept!(order),
                ),
                onDecline: () => _confirmAndAct(
                  order: order,
                  title: "Decline order?",
                  message:
                      "This will move the order to the accepted orders. Continue?",
                  confirmColor: Colors.red,
                  confirmText: "Decline",
                  onConfirm: widget.onDecline == null
                      ? null
                      : () => widget.onDecline!(order),
                ),
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


class _PendingOrdersCard extends StatelessWidget {
  const _PendingOrdersCard({
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final code = displayOrderCode(order); 
    final timeAgo = _timeAgo(order.createdAt);
    final eta = "${order.expectedDuration} min";

    final note = _customerNoteFromItems(order.items);

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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(code, style: t.titleMedium),
              // const SizedBox(width: 8),
              // _PriorityChip(status: order.status),
              const Spacer(),
              // Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black.withOpacity(0.55)),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            "ETA: $eta • Placed: $timeAgo",
            style: t.bodySmall?.copyWith(color: Colors.black.withOpacity(0.6)),
          ),

          const SizedBox(height: 10),

          Text(
            "Order Summary:",
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),

          ...order.items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: t.bodyMedium),
                  Expanded(
                    child: Text(
                      "${it.quantity}x ${it.itemName}",
                      style: t.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Customer Notes:",
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            note.isEmpty ? "—" : note,
            style: t.bodyMedium?.copyWith(
              color: Colors.black.withOpacity(0.75),
              height: 1.25,
            ),
          ),

          const SizedBox(height: 12),

          // Contact (not wired yet)
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: TextButton.icon(
          //     onPressed: null, // intentionally disabled for now
          //     icon: Icon(Icons.phone_outlined, color: AppColors.primary.withOpacity(0.6), size: 18),
          //     label: Text(
          //       "Contact Customer",
          //       style: t.labelLarge?.copyWith(color: AppColors.primary.withOpacity(0.6)),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 8),
          Divider(thickness: 2, color: AppColors.coal.withOpacity(0.2)),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text("Decline", style: t.labelLarge),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Accept",
                        style: t.labelLarge!.copyWith(color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final label = switch (status) {
      OrderStatus.pending => "HIGH1",
      OrderStatus.accepted => "ACPT",
      OrderStatus.canceled => "CANC",
      OrderStatus.done => "DONE",
      OrderStatus.recieved => "RCVD",
      OrderStatus.failed => "FAIL",
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: t.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

String _orderHash(Order o) {
  final raw = "${o.restaurantId}:${o.customerId}:${o.id}";
  return base64UrlEncode(utf8.encode(raw));
}

String displayOrderCode(Order o) {
  final h = _orderHash(o);

  final short = h.replaceAll("-", "").replaceAll("_", "");
  final show = short.length > 6
      ? short.substring(0, 6).toUpperCase()
      : short.toUpperCase();
  return "#$show";
}

String _customerNoteFromItems(List<ItemOrder> items) {
  final lines = <String>[];
  for (final it in items) {
    final s = it.special.trim();
    if (s.isEmpty) continue;
    lines.add("${it.itemName.toLowerCase()} : $s");
  }
  return lines.join("\n");
}

String _timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  return "${diff.inDays}d ago";
}


class OrdersShimmerList extends StatelessWidget {
  const OrdersShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        shrinkWrap: true,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 28),
          child: PendingOrdersCardShimmer(),
        ),
      ),
    );
  }
}

class PendingOrdersCardShimmer extends StatelessWidget {
  const PendingOrdersCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  ShimmerBlock(width: 90, height: 16, radius: 6),
                  SizedBox(width: 8),
                  ShimmerBlock(width: 44, height: 18, radius: 999),
                  Spacer(),
                  ShimmerBlock(width: 22, height: 22, radius: 6),
                ],
              ),
              SizedBox(height: 10),

              ShimmerBlock(width: 180, height: 12, radius: 6),
              SizedBox(height: 14),

              ShimmerBlock(width: 130, height: 14, radius: 6),
              SizedBox(height: 10),

              ShimmerBlock(width: double.infinity, height: 12, radius: 6),
              SizedBox(height: 8),
              ShimmerBlock(width: 260, height: 12, radius: 6),
              SizedBox(height: 8),
              ShimmerBlock(width: 220, height: 12, radius: 6),

              SizedBox(height: 14),

              ShimmerBlock(width: 140, height: 14, radius: 6),
              SizedBox(height: 10),

              ShimmerBlock(width: double.infinity, height: 36, radius: 10),

              SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: ShimmerBlock(width: 140, height: 16, radius: 8),
              ),

              SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ShimmerBlock(
                      width: double.infinity,
                      height: 44,
                      radius: 10,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ShimmerBlock(
                      width: double.infinity,
                      height: 44,
                      radius: 10,
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
class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 10,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
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
                final v = _c.value; // 0..1
                final dx = (v * 2) - 1; 

                return Transform.translate(
                  offset: Offset(dx * 200, 0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0x00FFFFFF),
                          Color(0x55FFFFFF),
                          Color(0x00FFFFFF),
                        ],
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

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = _c.value;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.0 - 0.3 + v * 2, 0),
              end: Alignment(1.0 + 0.3 + v * 2, 0),
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF7F7F7),
                Color(0xFFEEEEEE),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}


class ErrorState extends StatelessWidget {
  const ErrorState({
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError({required this.onRetry});
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
