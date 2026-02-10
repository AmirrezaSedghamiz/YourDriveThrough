import 'package:flutter/material.dart';
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.height = kToolbarHeight,
    this.backgroundColor,
    this.elevation = 2,
    this.shadowColor,
    this.onBack,
    this.showBack = false,
    this.bottom,
  });

  /// Slots
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  /// Behavior
  final bool showBack;
  final VoidCallback? onBack;

  /// Style
  final double height;
  final Color? backgroundColor;
  final double elevation;
  final Color? shadowColor;

  /// Optional extra content under the bar
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.white,
      elevation: elevation,
      shadowColor: shadowColor ?? Colors.black.withOpacity(0.2),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16,),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Leading
                    if (showBack)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      )
                    else
                      (leading ?? const SizedBox(width: 40)),

                    const SizedBox(width: 8),

                    // Title + subtitle
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null) DefaultTextStyle(
                            style: Theme.of(context).textTheme.titleMedium ??
                                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: title!,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            DefaultTextStyle(
                              style: Theme.of(context).textTheme.bodySmall ??
                                  const TextStyle(fontSize: 12, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: subtitle!,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Trailing
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),

            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}
