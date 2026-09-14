import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/phone.dart';
import '../theme/app_theme.dart';

class RuPhoneInputFormatter extends TextInputFormatter {
  const RuPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatRuPhoneLocal(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RuPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const RuPhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      inputFormatters: const [RuPhoneInputFormatter()],
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.navy,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: 'Телефон',
        hintText: '(999) 123-45-67',
        hintStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AppColors.muted.withValues(alpha: 0.45),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        prefixIcon: const SizedBox(
          width: 56,
          child: Center(
            child: Text(
              '+7',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
