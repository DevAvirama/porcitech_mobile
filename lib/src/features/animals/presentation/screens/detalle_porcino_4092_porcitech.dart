import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:porcitech_mobile/src/core/constants/zootechnical_constants.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/status_badge.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/core/widgets/withdrawal_alert_banner.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';

/// Pantalla: Detalle Individual del Porcino (`detalle_porcino_4092_porcitech`).
/// Expediente clínico y zootécnico con 4 métricas maestras y curva de crecimiento con fl_chart.
class DetallePorcino4092Porcitech extends StatelessWidget {
  final PorcinoEntity porcino;
  final VoidCallback onRegistrarPesaje;
  final VoidCallback onRegistrarSanidad;
  final VoidCallback? onRegistrarParto;

  const DetallePorcino4092Porcitech({
    super.key,
    required this.porcino,
    required this.onRegistrarPesaje,
    required this.onRegistrarSanidad,
    this.onRegistrarParto,
  });

  @override
  Widget build(BuildContext context) {
    final gdpClasificacion = ZootechnicalConstants.clasificarDesempenoGdp(
      porcino.gdpActualGramoDia,
      porcino.fase,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Expediente ${porcino.codigo}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Cabecera con Arete e Identidad Zootécnica ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mintBorder, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.tag_rounded,
                      size: 32,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              porcino.codigo,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.slateDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            StatusBadge.fromStatus(porcino.estadoSanitario),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${porcino.raza} • ${porcino.sexo}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slateHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${porcino.loteNombre} • Nacimiento: ${DateFormat('dd/MM/yyyy').format(porcino.fechaNacimiento)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slateMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Aviso Crítico de Tiempo de Retiro Sanitario si aplica ---
            if (porcino.tieneRetiroFarmacologicoActivo && porcino.medicacionActiva != null) ...[
              WithdrawalAlertBanner(
                medicamento: porcino.medicacionActiva!,
                diasRestantes: porcino.diasRetiroRestantes,
                fechaFinRetiro: porcino.fechaFinRetiro ??
                    DateTime.now().add(Duration(days: porcino.diasRetiroRestantes)),
              ),
              const SizedBox(height: 16),
            ],

            // --- 4 MÉTRICAS CLAVE (PESO, EDAD, GDP, DÍAS EN FASE) ---
            const Text(
              'Indicadores Biométricos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Peso Actual',
                    value: '${porcino.pesoActual} kg',
                    subtitle: 'Último control',
                    icon: Icons.scale_rounded,
                    accentColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Edad Total',
                    value: '${porcino.edadEnDias} d',
                    subtitle: '${(porcino.edadEnDias / 30.4).toStringAsFixed(1)} meses',
                    icon: Icons.calendar_today_rounded,
                    accentColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'GDP Actual',
                    value: '+${porcino.gdpActualGramoDia.toInt()} g/d',
                    subtitle: gdpClasificacion,
                    icon: Icons.trending_up_rounded,
                    accentColor: AppColors.primaryBright,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Días en ${porcino.fase}',
                    value: '${porcino.diasEnFase} días',
                    subtitle: 'Lote actual',
                    icon: Icons.timelapse_rounded,
                    accentColor: AppColors.slateHeading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- CURVA DE CRECIMIENTO FL_CHART (60/120 FPS) ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Curva de Crecimiento (kg)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slateDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Porkcolombia Ref.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildGrowthChart(porcino.curvaCrecimiento),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChartLegend(AppColors.primary, 'Peso Real del Porcino'),
                      const SizedBox(width: 16),
                      _buildChartLegend(AppColors.slateMuted, 'Meta Estándar Ceba'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- BOTONES DE ACCIÓN RÁPIDA EN CORRAL ---
            const Text(
              'Acciones Rápidas en Corral',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 12),
            TactileButton(
              text: 'Registrar Pesaje (Manual / IA)',
              icon: Icons.scale_rounded,
              onPressed: onRegistrarPesaje,
            ),
            const SizedBox(height: 12),
            TactileButton(
              text: 'Kárdex Sanitario / Medicación',
              icon: Icons.vaccines_rounded,
              type: TactileButtonType.secondary,
              onPressed: onRegistrarSanidad,
            ),
            if (porcino.esHembraReproductora && onRegistrarParto != null) ...[
              const SizedBox(height: 12),
              TactileButton(
                text: 'Registrar Parto de la Cerda',
                icon: Icons.child_care_rounded,
                type: TactileButtonType.outline,
                onPressed: onRegistrarParto,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slateMuted,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.slateDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(List<PesoHistoricoItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Sin datos históricos'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < items.length; i++) {
      spots.add(FlSpot(i.toDouble(), items[i].pesoKg));
    }

    final double minY = (items.map((e) => e.pesoKg).reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, 500.0);
    final double maxY = items.map((e) => e.pesoKg).reduce((a, b) => a > b ? a : b) + 10;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: (items.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 15,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      DateFormat('dd/MM').format(items[index].fecha),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateMuted,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}kg',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateMuted,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.slateMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
