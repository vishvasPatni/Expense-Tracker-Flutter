import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Large centered amount field (Add Transaction).
class AmountInput extends StatelessWidget {
  const AmountInput({
    super.key,
    required this.controller,
    required this.currencySymbol,
    this.validator,
  });

  final TextEditingController controller;
  final String currencySymbol;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: theme.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: '0.00',
        prefix: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            currencySymbol,
            style: theme.textTheme.headlineMedium,
          ),
        ),
      ),
      validator: validator,
    );
  }
}
