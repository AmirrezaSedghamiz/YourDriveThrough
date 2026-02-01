// components/app_tab_switch.dart
import 'package:flutter/material.dart';
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';

class AppTabSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String leftLabel;
  final String rightLabel;

  const AppTabSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.leftLabel = 'Sign In',
    this.rightLabel = 'Sign Up',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 64 / 412,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: Stack(
          children: [
            // Animated indicator background
            AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: 1.0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(
                  left: value
                      ? 0
                      : (MediaQuery.of(context).size.width - 64 / 412) / 2 - 28,
                ),
                width: (MediaQuery.of(context).size.width - 64 / 412) / 2 - 32,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Tab buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                color: value
                                    ? AppColors.primary
                                    : Colors.black45,
                                fontWeight: value
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                shadows: value
                                    ? [
                                        Shadow(
                                          color: AppColors.primary.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : [],
                              ),
                          child: Text(leftLabel),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                color: !value
                                    ? AppColors.primary
                                    : Colors.black45,
                                fontWeight: !value
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                shadows: !value
                                    ? [
                                        Shadow(
                                          color: AppColors.primary.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : [],
                              ),
                          child: Text(rightLabel),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}