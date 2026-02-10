import 'package:flutter/material.dart';

class FlexSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color thumbColor;
  final Color activeThumbColor;
  final Color inactiveThumbColor;
  final Color trackColor;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final double thumbSize;
  final double trackHeight;
  final double trackWidth;
  final Duration animationDuration;
  final double borderRadius;
  final double splashRadius;
  final bool enabled;

  const FlexSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.thumbColor,
    required this.activeThumbColor,
    required this.inactiveThumbColor,
    required this.trackColor,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    this.thumbSize = 24.0,
    this.trackHeight = 30.0,
    this.trackWidth = 50.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.borderRadius = 20.0,
    this.splashRadius = 50.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: trackWidth,
        height: thumbSize, // Container height matches thumb size
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Stack(
          children: [
            // Track (positioned behind the thumb)
            Center(
              child: AnimatedContainer(
                duration: animationDuration,
                width: trackWidth,
                height: trackHeight,
                decoration: BoxDecoration(
                  color: value ? activeTrackColor : inactiveTrackColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
            // Thumb
            AnimatedContainer(
              duration: animationDuration,
              margin: EdgeInsets.only(
                left: value ? trackWidth - thumbSize : 0,
                right: value ? 0 : trackWidth - thumbSize,
              ),
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                color: value ? activeThumbColor : inactiveThumbColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2.0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
