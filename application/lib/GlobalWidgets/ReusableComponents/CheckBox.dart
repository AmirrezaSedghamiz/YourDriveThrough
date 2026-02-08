// components/app_checkbox.dart
import 'package:flutter/material.dart';
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';

class AppCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool enabled;

  const AppCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primary,
            checkColor: Colors.white,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: enabled ? AppColors.coal : AppColors.coal.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }
}