import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/brand_mark.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/presentation/controllers/animals_controller.dart';
import 'package:porcitech_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:porcitech_mobile/src/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:porcitech_mobile/src/features/feeding/presentation/controllers/feeding_controller.dart';
import 'package:porcitech_mobile/src/features/health_record/presentation/controllers/health_controller.dart';
import 'package:porcitech_mobile/src/features/sync/domain/entities/sync_item_entity.dart';
import 'package:porcitech_mobile/src/features/sync/presentation/controllers/sync_controller.dart';

/// Pantalla: Ajustes de Cuenta, Descarga Offline (HU34) y Monitor de Sincronización (HU33).
class AjustesDeCuentaPorcitech extends ConsumerStatefulWidget {
  final VoidCallback onLogout;

  const AjustesDeCuentaPorcitech({
    super.key,
    required this.onLogout,
  });

  @override
  ConsumerState<AjustesDeCuentaPorcitech> createState() =>
      _AjustesDeCuentaPorcitechState();
}

class _AjustesDeCuentaPorcitechState
    extends ConsumerState<AjustesDeCuentaPorcitech> {
  bool _pushNotifications = true;

  String _resolveProfileName(
    Map<String, dynamic>? profile,
    String? fallbackName,
  ) {
    final fullName =
        '${profile?['nombre']?.toString().trim() ?? ''} ${profile?['apellido']?.toString().trim() ?? ''}'
            .trim();
    if (fullName.isNotEmpty) return fullName;
    final alt = profile?['name']?.toString().trim() ??
        profile?['username']?.toString().trim() ??
        '';
    if (alt.isNotEmpty) return alt;
    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      return fallbackName.trim();
    }
    return 'Operario PorciTech';
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider);
    final isOffline = ref.watch(offlineModeProvider);
    final authState = ref.watch(authNotifierProvider);
    final profile = syncState.userProfile;
    final displayName = _resolveProfileName(profile, authState.user?.name);
    final displayRole = profile?['rol']?.toString() ??
        profile?['role']?.toString() ??
        authState.user?.role ??
        'Operario de Galpón';
    final displayGranja = profile?['granja']?.toString() ??
        authState.user?.granja ??
        'Unidad Porcina SENA';

    final lastSyncText = syncState.lastCatalogSyncAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(syncState.lastCatalogSyncAt!)
        : 'Sin descarga previa';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            BrandMark(compact: true),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ajustes y Sincronización',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Tarjeta de Perfil del Operario / Zootecnista ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.mintSoft,
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayRole,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayGranja,
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
            const SizedBox(height: 20),

            // --- Descarga de Datos para Galpón Sin Conexión (HU34) ---
            const Text(
              'Datos Locales para Trabajo Sin Red',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.download_for_offline_rounded,
                          color: AppColors.senaBlue, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catálogo de Granja en Dispositivo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slateDark,
                              ),
                            ),
                            Text(
                              'Última actualización: $lastSyncText',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slateMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TactileButton(
                    text: 'Descargar Animales, Corrales e Inventario',
                    icon: Icons.cloud_download_rounded,
                    type: TactileButtonType.secondary,
                    isLoading: syncState.isDownloadingCatalog,
                    onPressed: isOffline
                        ? null
                        : () async {
                            final ok = await ref
                                .read(syncNotifierProvider.notifier)
                                .downloadOfflineCatalog();
                            if (ok) {
                              ref.read(animalsNotifierProvider.notifier).fetchPorcinos();
                              ref.read(animalsNotifierProvider.notifier).fetchLotes();
                              ref.read(healthNotifierProvider.notifier).loadSanidadData();
                              ref.read(feedingNotifierProvider.notifier).loadData();
                              ref.read(dashboardNotifierProvider.notifier).loadSummary();
                            }
                          },
                  ),
                  if (isOffline)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Desactive el Modo Offline para descargar la última copia desde Wi-Fi.',
                        style: TextStyle(fontSize: 11, color: AppColors.warningOrange),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Estado de Conexión y Switches ---
            const Text(
              'Conectividad y Operación en Galpón',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOffline ? AppColors.warningOrange : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOffline
                                    ? 'Modo Sin Conexión Activado'
                                    : 'Conectado al Servidor de Granja',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slateDark,
                                ),
                              ),
                              Text(
                                isOffline
                                    ? 'Guardando registros en el dispositivo'
                                    : 'Sincronización en línea activa',
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
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    value: isOffline,
                    activeTrackColor: AppColors.warningOrange,
                    title: const Text(
                      'Modo Offline de Granja',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Forzar trabajo sin internet (evita timeouts en galpón)',
                      style: TextStyle(fontSize: 12, color: AppColors.slateMuted),
                    ),
                    secondary: const Icon(
                      Icons.signal_wifi_off_rounded,
                      color: AppColors.warningOrange,
                    ),
                    onChanged: (val) {
                      ref.read(offlineModeProvider.notifier).toggleOffline(val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    value: _pushNotifications,
                    activeTrackColor: AppColors.primary,
                    title: const Text(
                      'Notificaciones Sanitarias Push',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Alertas de fin de retiro farmacológico y partos próximos',
                      style: TextStyle(fontSize: 12, color: AppColors.slateMuted),
                    ),
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primary,
                    ),
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Monitor de Sincronización Outbox FIFO (HU32 + HU33) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monitor de Sincronización',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slateHeading,
                  ),
                ),
                if (syncState.sentCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(syncNotifierProvider.notifier).clearSentItems();
                    },
                    child: const Text(
                      'Limpiar enviados',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Resumen de estados: Pendientes / Enviados / Errores / Conflictos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusPill(
                  label: 'Pendientes',
                  count: syncState.pendingCount,
                  bg: AppColors.warningLight,
                  fg: AppColors.warningOrange,
                ),
                _buildStatusPill(
                  label: 'Enviados',
                  count: syncState.sentCount,
                  bg: AppColors.mintSoft,
                  fg: AppColors.primaryDark,
                ),
                _buildStatusPill(
                  label: 'Errores',
                  count: syncState.errorCount,
                  bg: const Color(0xFFFEF3C7),
                  fg: const Color(0xFFB45309),
                ),
                _buildStatusPill(
                  label: 'Conflictos',
                  count: syncState.conflictCount,
                  bg: AppColors.alertRedLight,
                  fg: AppColors.alertRedDark,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (syncState.message != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: syncState.isError ? AppColors.alertRedLight : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: syncState.isError ? AppColors.alertRedBorder : AppColors.mintBorder,
                  ),
                ),
                child: Text(
                  syncState.message!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: syncState.isError ? AppColors.alertRedDark : AppColors.primaryDark,
                  ),
                ),
              ),
            ],

            if (syncState.queueItems.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.cloud_done_rounded, color: AppColors.primary, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Todos los registros de campo están sincronizados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.slateMuted),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: syncState.queueItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = syncState.queueItems[index];
                  return _buildQueueItemCard(item, syncState.isSyncing);
                },
              ),
            ],
            const SizedBox(height: 14),

            // Botón Sincronizar Cola FIFO
            TactileButton(
              text: 'Sincronizar Registros Pendientes',
              icon: Icons.sync_rounded,
              isLoading: syncState.isSyncing,
              onPressed: syncState.totalUnsentCount == 0
                  ? null
                  : () {
                      ref.read(syncNotifierProvider.notifier).executeSync();
                    },
            ),
            const SizedBox(height: 24),

            // --- Botón Cerrar Sesión ---
            TactileButton(
              text: 'Cerrar Sesión del Operario',
              icon: Icons.logout_rounded,
              type: TactileButtonType.danger,
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                widget.onLogout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required int count,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildQueueItemCard(SyncItemEntity item, bool isSyncing) {
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;
    final String statusLabel;

    switch (item.status) {
      case SyncItemStatus.enviado:
        statusColor = AppColors.primaryDark;
        statusBg = AppColors.mintSoft;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'ENVIADO';
        break;
      case SyncItemStatus.conflicto:
        statusColor = AppColors.alertRedDark;
        statusBg = AppColors.alertRedLight;
        statusIcon = Icons.error_outline_rounded;
        statusLabel = 'CONFLICTO';
        break;
      case SyncItemStatus.error:
        statusColor = const Color(0xFFB45309);
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = Icons.warning_amber_rounded;
        statusLabel = 'ERROR RED';
        break;
      case SyncItemStatus.pendiente:
        statusColor = AppColors.warningOrange;
        statusBg = AppColors.warningLight;
        statusIcon = Icons.schedule_rounded;
        statusLabel = 'PENDIENTE';
        break;
    }

    final shortUuid = item.idLocal.length >= 8 ? item.idLocal.substring(0, 8) : item.idLocal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.status == SyncItemStatus.conflicto
              ? AppColors.alertRedBorder
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slateDark,
                      ),
                    ),
                    Text(
                      'Ref: #$shortUuid • ${DateFormat('HH:mm:ss').format(item.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.slateMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (item.errorMessage != null && item.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.errorMessage!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
          if (item.status == SyncItemStatus.error ||
              item.status == SyncItemStatus.conflicto) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () {
                          ref.read(syncNotifierProvider.notifier).retryItem(item.id);
                        },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reintentar', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () {
                          ref.read(syncNotifierProvider.notifier).removeItem(item.id);
                        },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.alertRedDark,
                  ),
                  label: const Text(
                    'Descartar',
                    style: TextStyle(fontSize: 12, color: AppColors.alertRedDark),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
