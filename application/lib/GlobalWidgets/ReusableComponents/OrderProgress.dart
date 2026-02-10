import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:flutter/material.dart';

enum ActiveOrderStep { ordered, preparing, ready }

class ActiveOrderCard extends StatelessWidget {
  const ActiveOrderCard({
    super.key,
    required this.restaurantName,
    required this.readyBy,
    required this.arrival,
    required this.currentStep,
  });

  final String restaurantName;
  final TimeOfDay readyBy;
  final TimeOfDay arrival;
  final ActiveOrderStep currentStep;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Active Order",
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          Text(
            restaurantName,
            style: t.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _TimePair(
                  label: "Ready by:",
                  time: readyBy,
                  alignEnd: false,
                ),
              ),
              Expanded(
                child: _TimePair(
                  label: "Arrival:",
                  time: arrival,
                  alignEnd: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StepRow(currentStep: currentStep),
        ],
      ),
    );
  }
}

class _TimePair extends StatelessWidget {
  const _TimePair({
    required this.label,
    required this.time,
    required this.alignEnd,
  });

  final String label;
  final TimeOfDay time;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final timeStr = MaterialLocalizations.of(context).formatTimeOfDay(time);

    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.bodySmall?.copyWith(color: Colors.black.withOpacity(0.45)),
        ),
        const SizedBox(height: 4),
        Text(
          timeStr,
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.currentStep});
  final ActiveOrderStep currentStep;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final orderedActive = currentStep.index >= ActiveOrderStep.ordered.index;
    final preparingActive = currentStep.index >= ActiveOrderStep.preparing.index;
    final readyActive = currentStep.index >= ActiveOrderStep.ready.index;

    return Row(
      children: [
        Expanded(
          child: _Step(
            label: "Ordered",
            icon: Icons.receipt_long_rounded,
            active: orderedActive,
            // first has no left connector
            leftConnector: false,
            rightConnectorActive: preparingActive,
          ),
        ),
        Expanded(
          child: _Step(
            label: "Preparing",
            icon: Icons.restaurant_rounded,
            active: preparingActive,
            leftConnector: true,
            rightConnectorActive: readyActive,
          ),
        ),
        Expanded(
          child: _Step(
            label: "Ready",
            icon: Icons.check_circle_rounded,
            active: readyActive,
            leftConnector: true,
            // last has no right connector
            rightConnectorActive: false,
            hideRightConnector: true,
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.icon,
    required this.active,
    required this.leftConnector,
    required this.rightConnectorActive,
    this.hideRightConnector = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool leftConnector;
  final bool rightConnectorActive;
  final bool hideRightConnector;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final circleColor = active ? AppColors.primary : const Color(0xFFF1F1F1);
    final iconColor = active ? AppColors.white : Colors.black.withOpacity(0.35);

    final leftLineColor =
        active ? AppColors.primary : const Color(0xFFE8E8E8);
    final rightLineColor =
        rightConnectorActive ? AppColors.primary : const Color(0xFFE8E8E8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 42,
          child: Row(
            children: [
              // left connector
              if (leftConnector)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: leftLineColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )
              else
                const Spacer(),

              // circle
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),

              // right connector
              if (!hideRightConnector)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: rightLineColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: t.bodySmall?.copyWith(
            color: Colors.black.withOpacity(active ? 0.75 : 0.45),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
