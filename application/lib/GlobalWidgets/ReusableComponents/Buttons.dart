// components/app_button.dart
import 'package:application/GlobalWidgets/AppTheme/Theme.dart';
import 'package:flutter/material.dart';
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';

enum AppButtonVariant { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isFullWidth;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isFullWidth = true,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ButtonStyle style;
    Color textColor;
    Color backgroundColor;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        style = AppTheme.primaryButtonStyle;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.lightGray;
        textColor = AppColors.coal;
        style = AppTheme.primaryButtonStyle.copyWith(
          backgroundColor: MaterialStateProperty.all(backgroundColor),
          foregroundColor: MaterialStateProperty.all(textColor),
        );
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        style = ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary, width: 2),
          ),
          elevation: 0,
          minimumSize: Size(isFullWidth ? double.infinity : 0, height ?? 56),
        );
        break;
      case AppButtonVariant.text:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        style = ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          minimumSize: Size(isFullWidth ? double.infinity : 0, height ?? 56),
        );
        break;
    }

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: buttonChild,
      ),
    );
  }
}