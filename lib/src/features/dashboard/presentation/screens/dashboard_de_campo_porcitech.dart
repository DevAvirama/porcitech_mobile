import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/brand_mark.dart';
import 'package:porcitech_mobile/src/core/widgets/error_banner.dart';
import 'package:porcitech_mobile/src/core/widgets/skeleton_loader.dart';
import 'package:porcitech_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:porcitech_mobile/src/features/dashboard/presentation/controllers/dashboard_controller.dart';

/// Pantalla Principal: Dashboard de Campo (`dashboard_de_campo_porcitech`).
/// Centro de mando táctil alineado con la plataforma Web SENA PorciTech.
class DashboardDeCampoPorcitech extends ConsumerWidget {
  final VoidCallback onScanQr;
  final VoidCallback onOpenPesaje;
  final VoidCallback onOpenSanidad;
  final VoidCallback onOpenPartos;
  final VoidCallback onOpenLotes;
  final VoidCallback? onOpenAlimentacion;
  final VoidCallback onOpenAjustes;

  const DashboardDeCampoPorcitech({
    super.key,
    required this.onScanQr,
    required this.onOpenPesaje,
    required this.onOpenSanidad,
    required this.onOpenPartos,
    required this.onOpenLotes,
    this.onOpenAlimentacion,
    required this.onOpenAjustes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOffline = ref.watch(offlineModeProvider);
    final summary = dashboardState.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const BrandMark(compact: true),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authState.user?.name ?? 'Operación de Campo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.senaBlue,
                    ),
                  ),
                  Text(
                    '${(authState.user?.role ?? 'Operario').toUpperCase()} • ${authState.user?.granja ?? 'Unidad Porcina SENA'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slateMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isOffline ? AppColors.warningLight : AppColors.mintSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOffline ? AppColors.warningOrange : AppColors.mintBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOffline ? Icons.cloud_off : Icons.cloud_done,
                  size: 15,
                  color: isOffline ? AppColors.warningOrange : AppColors.primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  isOffline ? 'Offline' : 'Online',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOffline ? AppColors.warningOrange : AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.slateDark),
            tooltip: 'Ajustes y Sincronización',
            onPressed: onOpenAjustes,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.senaGreen,
        onRefresh: () async {
          await ref.read(dashboardNotifierProvider.notifier).loadSummary();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Banner de Cola Pendiente si hay registros offline ---
              if (summary != null && summary.registrosPendientesSync > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningOrange),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_problem_rounded,
                        color: AppColors.warningOrange,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${summary.registrosPendientesSync} registros pendientes por sincronizar con el servidor.',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onOpenAjustes,
                        child: const Text(
                          'Sincronizar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // --- ACCESO DESTACADO: Escanear QR / RFID ---
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onScanQr,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.senaBlue, Color(0xFF065F46)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.senaBlue.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESCANEAR ARETE QR / RFID',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Identificación inmediata, pesaje y kárdex sanitario',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDCFCE7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // --- MÉTRICAS PRINCIPALES DEL GALPÓN ---
              const Text(
                'Indicadores Operativos del Hato',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.senaBlue,
                ),
              ),
              const SizedBox(height: 12),

              if (dashboardState.isLoading && summary == null) ...[
                const Row(
                  children: [
                    Expanded(child: SkeletonLoader(width: double.infinity, height: 100)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonLoader(width: double.infinity, height: 100)),
                  ],
                ),
              ] else if (dashboardState.errorMessage != null && summary == null) ...[
                ErrorBanner(
                  message: dashboardState.errorMessage!,
                  onRetry: () => ref.read(dashboardNotifierProvider.notifier).loadSummary(),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Porcinos',
                        value: '${summary?.totalPorcinos ?? 0}',
                        subtitle: '${summary?.totalCorralesActivos ?? 0} corrales activos',
                        icon: Icons.pets_rounded,
                        accentColor: AppColors.senaGreen,
                        bgColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Alertas Activas',
                        value: '${summary?.alertasSanitarias ?? 0}',
                        subtitle: 'Retiro / Stock / Parto',
                        icon: Icons.warning_amber_rounded,
                        accentColor: AppColors.alertRedDark,
                        bgColor: (summary?.alertasSanitarias ?? 0) > 0
                            ? AppColors.alertRedLight
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'GDP / Peso Prom.',
                        value:
                            '+${(summary?.gdpPromedioGramoDia ?? 820).toStringAsFixed(0)} g/día',
                        subtitle:
                            'Prom. granja: ${(summary?.pesoPromedioGranjaKg ?? 0).toStringAsFixed(1)} kg',
                        icon: Icons.trending_up_rounded,
                        accentColor: AppColors.secondary,
                        bgColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Ceba / Reproducción',
                        value:
                            '${summary?.porcinosEnCeba ?? 0} / ${summary?.hembrasGestacion ?? 0}',
                        subtitle: 'Engorde vs. Madres',
                        icon: Icons.fence_rounded,
                        accentColor: AppColors.senaBlue,
                        bgColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // --- CUADRÍCULA DE OPERACIONES DE CAMPO ---
              const Text(
                'Operaciones de Galpón y Corral',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.senaBlue,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildQuickAccessCard(
                    title: 'Pesaje y Visión IA',
                    description: 'Báscula digital y estimación cenital con IA',
                    icon: Icons.scale_rounded,
                    color: AppColors.senaGreen,
                    onTap: onOpenPesaje,
                  ),
                  _buildQuickAccessCard(
                    title: 'Sanidad y Bioseguridad',
                    description: 'Vacunas, alertas de retiro y protocolos diarios',
                    icon: Icons.vaccines_rounded,
                    color: AppColors.alertRedDark,
                    onTap: onOpenSanidad,
                  ),
                  _buildQuickAccessCard(
                    title: 'Ciclo Reproductivo',
                    description: 'Servicios, diagnóstico, partos y destetes',
                    icon: Icons.monitor_heart_rounded,
                    color: const Color(0xFF7E22CE),
                    onTap: onOpenPartos,
                  ),
                  _buildQuickAccessCard(
                    title: 'Alimentación y Bodega',
                    description: 'Raciones por corral y stock de insumos',
                    icon: Icons.restaurant_rounded,
                    color: AppColors.warningOrange,
                    onTap: onOpenAlimentacion ?? onOpenLotes,
                  ),
                  _buildQuickAccessCard(
                    title: 'Corrales y Porcinos',
                    description: 'Inventario animal, fases y curva de crecimiento',
                    icon: Icons.fence_rounded,
                    color: AppColors.senaBlue,
                    onTap: onOpenLotes,
                  ),
                  _buildQuickAccessCard(
                    title: 'Sincronización Offline',
                    description: 'Cola local y estado del servidor FastAPI',
                    icon: Icons.cloud_sync_rounded,
                    color: AppColors.secondary,
                    onTap: onOpenAjustes,
                  ),
                ],
              ),

              // --- ALERTAS ACTIVAS DEL SISTEMA (paridad con Web) ---
              if (summary != null && summary.alertas.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Alertas Operativas del Día',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.senaBlue,
                  ),
                ),
                const SizedBox(height: 10),
                ...summary.alertas.take(4).map(
                      (alerta) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: alerta.nivel == 'danger'
                                ? AppColors.alertRedBorder
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              alerta.nivel == 'danger'
                                  ? Icons.report_problem_rounded
                                  : Icons.info_outline_rounded,
                              color: alerta.nivel == 'danger'
                                  ? AppColors.alertRedDark
                                  : AppColors.warningOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alerta.mensaje,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slateDark,
                                    ),
                                  ),
                                  Text(
                                    alerta.accionSugerida,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.slateMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],

              // --- ACTIVIDAD RECIENTE (paridad con Web) ---
              if (summary != null && summary.actividadReciente.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Actividad Reciente en Granja',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.senaBlue,
                  ),
                ),
                const SizedBox(height: 10),
                ...summary.actividadReciente.take(4).map(
                      (act) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history_edu_rounded,
                              color: AppColors.senaBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act.titulo,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slateDark,
                                    ),
                                  ),
                                  Text(
                                    act.descripcion,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slateMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgColor == Colors.white
              ? const Color(0xFFE2E8F0)
              : accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateMuted,
                  ),
                ),
              ),
              Icon(icon, size: 19, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accentColor == AppColors.alertRedDark
                  ? AppColors.alertRedDark
                  : AppColors.slateDark,
              letterSpacing: -0.5,
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
              color: accentColor == AppColors.alertRedDark
                  ? AppColors.alertRedDark
                  : AppColors.slateMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slateDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slateMuted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
