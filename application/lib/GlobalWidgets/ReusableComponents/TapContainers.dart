import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:flutter/material.dart';

class AppTapButton extends StatelessWidget {
  const AppTapButton({
    super.key,
    required this.text,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.height = 46,
    this.radius = 12,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final double height;
  final double radius;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: isLoading ? null : onTap,
        child: Ink(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.primary,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    text,
                    style: t.labelLarge?.copyWith(
                      color: textColor ?? AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AppTapRowButton extends StatelessWidget {
  const AppTapRowButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.height = 44,
    this.radius = 12,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Ink(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.black.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                text,
                style: t.labelLarge?.copyWith(
                  color: Colors.black.withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
