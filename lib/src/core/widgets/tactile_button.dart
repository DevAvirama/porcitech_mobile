import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum TactileButtonType { primary, secondary, danger, outline }

/// Botón táctil ergonómico diseñado para operarios en galpón y corral.
/// Garantiza un área táctil mínima de 52px de altura, estados visuales claros
/// y retroalimentación háptica (vibración leve) al pulsarlo con guantes.
class TactileButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final TactileButtonType type;
  final double height;
  final double? width;

  const TactileButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.type = TactileButtonType.primary,
    this.height = 52.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (type) {
      case TactileButtonType.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        break;
      case TactileButtonType.secondary:
        backgroundColor = AppColors.secondary;
        foregroundColor = Colors.white;
        break;
      case TactileButtonType.danger:
        backgroundColor = AppColors.alertRed;
        foregroundColor = Colors.white;
        break;
      case TactileButtonType.outline:
        backgroundColor = Colors.white;
        foregroundColor = AppColors.slateDark;
        borderSide = const BorderSide(color: AppColors.slateBorder, width: 1.5);
        break;
    }

    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height < 52.0 ? 52.0 : height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.7),
          elevation: 0,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: foregroundColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
