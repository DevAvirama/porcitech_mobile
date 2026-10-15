import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Teclado numérico gigante optimizado para operarios de campo con guantes de bioseguridad.
/// Permite ingresar valores de pesaje (kg) y dosis farmacológicas (ml) de forma veloz y precisa.
class GiantNumericKeypad extends StatelessWidget {
  final void Function(String digit) onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onClearPressed;
  final bool allowDecimal;

  const GiantNumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    required this.onClearPressed,
    this.allowDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: allowDecimal
                  ? _buildKey(
                      label: '.',
                      isSpecial: true,
                      onTap: () => onDigitPressed('.'),
                    )
                  : _buildKey(
                      label: 'C',
                      isSpecial: true,
                      onTap: onClearPressed,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKey(
                label: '0',
                isSpecial: false,
                onTap: () => onDigitPressed('0'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKey(
                icon: Icons.backspace_outlined,
                isSpecial: true,
                onTap: onDeletePressed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _buildKey(
              label: digits[i],
              isSpecial: false,
              onTap: () => onDigitPressed(digits[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKey({
    String? label,
    IconData? icon,
    required bool isSpecial,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSpecial ? AppColors.surfaceVariant : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSpecial ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 28, color: AppColors.slateDark)
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isSpecial ? AppColors.slateHeading : AppColors.slateDark,
                  ),
                ),
        ),
      ),
    );
  }
}
