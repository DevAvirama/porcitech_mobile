import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Insignia visual de estado fisiológico o sanitario con alto contraste cromático.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  factory StatusBadge.fromStatus(String status) {
    Color bg = AppColors.mintSoft;
    Color fg = AppColors.primaryDark;
    IconData ic = Icons.check_circle_outline;

    switch (status.toLowerCase()) {
      case 'sano':
      case 'activo':
      case 'óptimo':
        bg = AppColors.mintSoft;
        fg = AppColors.primaryDark;
        ic = Icons.check_circle_outline;
        break;
      case 'enfermo':
      case 'crítico':
        bg = AppColors.alertRedLight;
        fg = AppColors.alertRedDark;
        ic = Icons.error_outline;
        break;
      case 'en tratamiento':
      case 'retiro farmacológico':
      case 'cuarentena':
        bg = AppColors.warningLight;
        fg = AppColors.warningOrange;
        ic = Icons.warning_amber_rounded;
        break;
      case 'gestación':
      case 'maternidad':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        ic = Icons.pregnant_woman;
        break;
      case 'ceba':
      case 'levante':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        ic = Icons.trending_up;
        break;
    }

    return StatusBadge(
      label: status,
      backgroundColor: bg,
      textColor: fg,
      icon: ic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.mintSoft;
    final fg = textColor ?? AppColors.primaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
