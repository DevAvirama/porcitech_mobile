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
/// Expediente clínico y zootécnico con métricas maestras y curva de crecimiento (fl_chart).
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slateDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Rfid Scanner',
          style: TextStyle(
            color: AppColors.slateDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Cabecera con Arete, RFID e Identidad Zootécnica ---
            Container(
              padding: const EdgeInsets.all(16),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Porcino #${porcino.id}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slateDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'RFID: ${porcino.codigo} · ${porcino.loteNombre}',
                              style: const TextStyle(
                                color: AppColors.slateMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.rss_feed_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCAEAD6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 3.5,
                              backgroundColor: Color(0xFF042014),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${porcino.loteNombre.toUpperCase()} | ESTADO: ${porcino.estadoSanitario.toUpperCase()}',
                              style: const TextStyle(
                                color: Color(0xFF042014),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge.fromStatus(porcino.estadoSanitario),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Raza: ${porcino.raza} · Sexo: ${porcino.sexo} · Nacimiento: ${DateFormat('dd/MM/yyyy').format(porcino.fechaNacimiento)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slateMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Aviso Crítico de Tiempo de Retiro Sanitario si aplica ---
            if (porcino.tieneRetiroFarmacologicoActivo &&
                porcino.medicacionActiva != null) ...[
              WithdrawalAlertBanner(
                medicamento: porcino.medicacionActiva!,
                diasRestantes: porcino.diasRetiroRestantes,
                fechaFinRetiro: porcino.fechaFinRetiro ??
                    DateTime.now().add(
                        Duration(days: porcino.diasRetiroRestantes)),
              ),
              const SizedBox(height: 16),
            ],

            // --- 4 MÉTRICAS BIOMÉTRICAS CLAVE (PESO, EDAD, GDP, DÍAS EN CEBA) ---
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'PESO ACTUAL',
                    value: '${porcino.pesoActual}',
                    unit: 'kg',
                    subtext: '🕒 Hoy, 08:30 AM',
                    icon: Icons.scale_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'EDAD',
                    value: '${(porcino.edadEnDias / 7).round()}',
                    unit: 'sem',
                    subtext: 'Fase ${porcino.fase}',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'GDP PROMEDIO',
                    value: '+${porcino.gdpActualGramoDia.toInt()}',
                    unit: 'g/d',
                    subtext: '✔ $gdpClasificacion',
                    icon: Icons.trending_up_rounded,
                    isGreenValue: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'EN CEBA',
                    value: '${porcino.diasEnFase}',
                    unit: 'días',
                    subtext: 'Ingreso: 04 Feb',
                    icon: Icons.timer_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- TARJETA DE UBICACIÓN Y ALIMENTACIÓN ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.slateMuted,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'UBICACIÓN Y ALIMENTACIÓN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Instalación',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slateMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            porcino.loteNombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.slateDark,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Dieta Activa',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slateMuted,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ceba II (Grano Fino)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.slateDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- CURVA DE CRECIMIENTO CON FL_CHART ---
            if (porcino.curvaCrecimiento.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slateDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Porkcolombia Ref.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 180,
                      child: _buildGrowthChart(porcino.curvaCrecimiento),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- BOTONES DE ACCIÓN RÁPIDA (MODO GUANTES) ---
            TactileButton(
              text: 'Registrar Nuevo Pesaje',
              icon: Icons.scale_rounded,
              onPressed: onRegistrarPesaje,
            ),
            const SizedBox(height: 10),

            TactileButton(
              text: 'Aplicar Vacuna / Tratamiento',
              icon: Icons.vaccines_rounded,
              type: TactileButtonType.secondary,
              onPressed: onRegistrarSanidad,
            ),

            if (porcino.esHembraReproductora && onRegistrarParto != null) ...[
              const SizedBox(height: 10),
              TactileButton(
                text: 'Registrar Parto / Camada',
                icon: Icons.child_care_rounded,
                type: TactileButtonType.outline,
                onPressed: onRegistrarParto!,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthChart(List<PesoHistoricoItem> items) {
    final spots = <FlSpot>[];
    for (int i = 0; i < items.length; i++) {
      spots.add(FlSpot(i.toDouble(), items[i].pesoKg));
    }

    final double minY = (items.map((e) => e.pesoKg).reduce((a, b) => a < b ? a : b) - 5)
        .clamp(0.0, 500.0);
    final double maxY =
        items.map((e) => e.pesoKg).reduce((a, b) => a > b ? a : b) + 10;

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
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('dd/MM').format(items[index].fecha),
                      style: const TextStyle(
                        fontSize: 9,
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
              reservedSize: 32,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}kg',
                  style: const TextStyle(
                    fontSize: 9,
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
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String subtext;
  final IconData icon;
  final bool isGreenValue;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtext,
    required this.icon,
    this.isGreenValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slateMuted,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: isGreenValue ? AppColors.primary : AppColors.slateMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isGreenValue ? AppColors.primary : AppColors.slateDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGreenValue ? AppColors.primary : AppColors.slateMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isGreenValue ? AppColors.primary : AppColors.slateMuted,
            ),
          ),
        ],
      ),
    );
  }
}