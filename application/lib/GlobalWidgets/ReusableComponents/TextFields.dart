// components/app_text_field.dart (updated)
import 'package:application/GlobalWidgets/AppTheme/Theme.dart';
import 'package:flutter/material.dart';
import 'package:application/GlobalWidgets/AppTheme/Colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String hintText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int? maxLines;
  final bool isRequired;
  final String? errorText;

  const AppTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText = '',
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.isRequired = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText.isNotEmpty)
          Row(
            children: [
              Text(
                labelText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isRequired)
                Text(
                  '*',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        if (labelText.isNotEmpty) const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          enabled: enabled,
          maxLines: maxLines,
          decoration: AppTheme.textFieldDecoration.copyWith(
                hintText: hintText,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                errorText: errorText
              ),
        ),
      ],
    );
  }
}

// AppPasswordField remains similar but uses AppTheme for decoration
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final String? errorText;

  const AppPasswordField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText = 'Enter your password',
    this.onChanged,
    this.validator,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      errorText: widget.errorText,
      obscureText: _obscureText,
      prefixIcon: const Icon(Icons.lock, color: AppColors.coal),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.coal,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      onChanged: widget.onChanged,
      validator: widget.validator,
      enabled: widget.enabled,
    );
  }
}