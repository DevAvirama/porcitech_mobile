import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Banner de alerta zootécnica crítica para Tiempos de Retiro Farmacológico.
/// Prohíbe el envío a beneficio/faenado si el animal o lote tiene medicación activa.
class WithdrawalAlertBanner extends StatelessWidget {
  final String medicamento;
  final int diasRestantes;
  final DateTime fechaFinRetiro;

  const WithdrawalAlertBanner({
    super.key,
    required this.medicamento,
    required this.diasRestantes,
    required this.fechaFinRetiro,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnRetiro = diasRestantes > 0;
    final colorBase = isEnRetiro ? AppColors.alertRedDark : AppColors.primaryDark;
    final colorFondo = isEnRetiro ? AppColors.alertRedLight : AppColors.mintSoft;
    final colorBorde = isEnRetiro ? AppColors.alertRedBorder : AppColors.mintBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorde, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorBase.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnRetiro ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
              color: colorBase,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnRetiro
                      ? 'BLOQUEO: TIEMPO DE RETIRO ACTIVO'
                      : 'APTO PARA BENEFICIO / VENTA',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colorBase,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnRetiro
                      ? 'Medicación: $medicamento. Restan $diasRestantes días (Hasta: ${_formatDate(fechaFinRetiro)}). Prohibido su despacho.'
                      : 'Cumplió los días de retiro de $medicamento. Inocuidad alimentaria garantizada.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slateHeading,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
