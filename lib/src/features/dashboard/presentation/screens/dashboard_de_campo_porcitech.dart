import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/error_banner.dart';
import 'package:porcitech_mobile/src/core/widgets/skeleton_loader.dart';
import 'package:porcitech_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:porcitech_mobile/src/features/dashboard/presentation/controllers/dashboard_controller.dart';

/// Pantalla Principal: Dashboard de Campo (`dashboard_de_campo_porcitech`).
/// Centro de mando táctil para operarios y zootecnistas en corrales.
class DashboardDeCampoPorcitech extends ConsumerWidget {
  final VoidCallback onScanQr;
  final VoidCallback onOpenPesaje;
  final VoidCallback onOpenSanidad;
  final VoidCallback onOpenPartos;
  final VoidCallback onOpenLotes;
  final VoidCallback onOpenAjustes;

  const DashboardDeCampoPorcitech({
    super.key,
    required this.onScanQr,
    required this.onOpenPesaje,
    required this.onOpenSanidad,
    required this.onOpenPartos,
    required this.onOpenLotes,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PorciTech • Campo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.slateDark,
              ),
            ),
            Text(
              authState.user?.granja ?? 'Granja San Jerónimo • Galpón 4',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slateMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Indicador de Estado de Conexión / Modo Offline
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
                  size: 16,
                  color: isOffline ? AppColors.warningOrange : AppColors.primaryDark,
                ),
                const SizedBox(width: 5),
                Text(
                  isOffline ? 'Offline' : 'Online',
                  style: TextStyle(
                    fontSize: 12,
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
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
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
                      const Icon(Icons.sync_problem_rounded, color: AppColors.warningOrange, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${summary.registrosPendientesSync} registros guardados en local listos para sincronizar.',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onOpenAjustes,
                        child: const Text('Ver Cola', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.warningOrange)),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF047857), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESCANEAR QR / RFID',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Identificación y Ficha Rápida del Porcino',
                                style: TextStyle(
                                  fontSize: 13,
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
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- MÉTRICAS PRINCIPALES DEL GALPÓN ---
              const Text(
                'Estado Operativo del Hato',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slateHeading,
                ),
              ),
              const SizedBox(height: 12),

              if (dashboardState.isLoading && summary == null) ...[
                Row(
                  children: const [
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
                    // Métrica 1: Total Porcinos
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Porcinos',
                        value: '${summary?.totalPorcinos ?? 1420}',
                        subtitle: 'Población activa',
                        icon: Icons.pets_rounded,
                        accentColor: AppColors.primary,
                        bgColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Métrica 2: Alertas Sanitarias
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Alertas Sanitarias',
                        value: '${summary?.alertasSanitarias ?? 3}',
                        subtitle: 'Retiro / Tratamiento',
                        icon: Icons.medical_services_outlined,
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
                        title: 'GDP Promedio',
                        value: '+${(summary?.gdpPromedioGramoDia ?? 835).toStringAsFixed(0)} g',
                        subtitle: 'Meta Porkcolombia',
                        icon: Icons.trending_up_rounded,
                        accentColor: AppColors.secondary,
                        bgColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'En Ceba / Gestación',
                        value: '${summary?.porcinosEnCeba ?? 860} / ${summary?.hembrasGestacion ?? 310}',
                        subtitle: 'Lotes en curso',
                        icon: Icons.grid_view_rounded,
                        accentColor: AppColors.slateHeading,
                        bgColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // --- CUADRÍCULA DE 4 ACCESOS RÁPIDOS DE CAMPO ---
              const Text(
                'Módulos y Operaciones en Corral',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slateHeading,
                ),
              ),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _buildQuickAccessCard(
                    title: 'Pesaje y Visión IA',
                    description: 'Teclado gigante y captura cenital',
                    icon: Icons.scale_rounded,
                    color: AppColors.primary,
                    onTap: onOpenPesaje,
                  ),
                  _buildQuickAccessCard(
                    title: 'Kárdex Sanitario',
                    description: 'Vacunación y tiempos de retiro',
                    icon: Icons.vaccines_rounded,
                    color: AppColors.alertRedDark,
                    onTap: onOpenSanidad,
                  ),
                  _buildQuickAccessCard(
                    title: 'Partos y Cerda',
                    description: 'Vivos, muertos, momias y camada',
                    icon: Icons.child_care_rounded,
                    color: const Color(0xFF7E22CE), // Púrpura reproducción
                    onTap: onOpenPartos,
                  ),
                  _buildQuickAccessCard(
                    title: 'Lotes y Porcinos',
                    description: 'Expediente, aretes y filtros',
                    icon: Icons.folder_shared_rounded,
                    color: AppColors.secondary,
                    onTap: onOpenLotes,
                  ),
                ],
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgColor == Colors.white ? const Color(0xFFE2E8F0) : accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slateMuted,
                ),
              ),
              Icon(icon, size: 20, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accentColor == AppColors.alertRedDark ? AppColors.alertRedDark : AppColors.slateDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: accentColor == AppColors.alertRedDark ? AppColors.alertRedDark : AppColors.slateMuted,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
