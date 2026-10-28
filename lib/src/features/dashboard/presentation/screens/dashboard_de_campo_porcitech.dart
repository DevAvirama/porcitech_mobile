import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/error_banner.dart';
import 'package:porcitech_mobile/src/core/widgets/skeleton_loader.dart';
import 'package:porcitech_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:porcitech_mobile/src/features/dashboard/presentation/controllers/dashboard_controller.dart';

/// Pantalla Principal: Dashboard de Campo (`dashboard_de_campo_porcitech`).
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
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PORCITECH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Field Overview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: onOpenAjustes,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOffline) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warningOrange),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.cloud_off,
                        color: AppColors.warningOrange,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Modo Offline activo • Los cambios se guardarán localmente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hola, ${authState.user?.email.split('@').first ?? "Operador"}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slateDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botón Principal Gigante
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onScanQr,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Escanear QR / RFID',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'LECTURA RÁPIDA • LECTOR ACTIVO',
                                style: TextStyle(
                                  color: AppColors.mintSoft,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Métricas
              if (dashboardState.isLoading && summary == null) ...[
                Row(
                  children: const [
                    Expanded(
                      child: SkeletonLoader(width: double.infinity, height: 95),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: SkeletonLoader(width: double.infinity, height: 95),
                    ),
                  ],
                ),
              ] else if (dashboardState.errorMessage != null &&
                  summary == null) ...[
                ErrorBanner(
                  message: dashboardState.errorMessage!,
                  onRetry: () => ref
                      .read(dashboardNotifierProvider.notifier)
                      .loadSummary(),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'ANIMALES\nTOTAL',
                        value: '${summary?.totalPorcinos ?? 1420}',
                        subtitle: 'Pabellones A-D',
                        icon: Icons.pets_outlined,
                        iconBgColor: const Color(0xFFEFF6FF),
                        iconColor: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'ALERTAS HOY',
                        value: '${summary?.alertasSanitarias ?? 3}',
                        statusBadge: 'PENDIENTE',
                        subtitle: '2 Cuarentena • 1 Dosis',
                        icon: Icons.notifications_active_outlined,
                        iconBgColor: AppColors.alertRedLight,
                        iconColor: AppColors.alertRedDark,
                        isAlert: true,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Operaciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'OPERACIONES DE NAVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slateMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Modo Guantes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slateMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _ActionButton(
                    title: 'Pesaje',
                    subtitle: 'Báscula y ganancia',
                    icon: Icons.hourglass_empty_rounded,
                    iconBgColor: const Color(0xFFEFF6FF),
                    iconColor: AppColors.secondary,
                    onTap: onOpenPesaje,
                  ),
                  _ActionButton(
                    title: 'Sanidad',
                    subtitle: 'Dosis y tratamientos',
                    icon: Icons.vaccines_outlined,
                    iconBgColor: const Color(0xFFCCFBF1),
                    iconColor: const Color(0xFF0D9488),
                    onTap: onOpenSanidad,
                  ),
                  _ActionButton(
                    title: 'Partos',
                    subtitle: 'Maternidad y lechigadas',
                    icon: Icons.face_outlined,
                    iconBgColor: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF7E22CE),
                    onTap: onOpenPartos,
                  ),
                  _ActionButton(
                    title: 'Lotes',
                    subtitle: 'Corrales y traslados',
                    icon: Icons.grid_view_outlined,
                    iconBgColor: AppColors.mintSoft,
                    iconColor: AppColors.primary,
                    onTap: onOpenLotes,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.slateMuted,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart_outlined),
            label: 'Pens',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty_rounded),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined),
            label: 'Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? statusBadge;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final bool isAlert;

  const _MetricCard({
    required this.title,
    required this.value,
    this.statusBadge,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.isAlert = false,
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
                  fontWeight: FontWeight.w800,
                  color: AppColors.slateMuted,
                  height: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
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
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slateDark,
                ),
              ),
              if (statusBadge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.alertRedLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusBadge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.alertRedDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isAlert ? AppColors.alertRedDark : AppColors.slateMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slateDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.slateMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
