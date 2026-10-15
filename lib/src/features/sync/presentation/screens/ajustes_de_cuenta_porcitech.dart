import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:porcitech_mobile/src/features/sync/presentation/controllers/sync_controller.dart';

/// Pantalla: Ajustes de Cuenta y Sincronización (`ajustes_de_cuenta_porcitech`).
/// Perfil del operario, interruptores de Modo Offline y Notificaciones,
/// estado del servidor FastAPI y gestión visual de la cola offline.
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

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider);
    final isOffline = ref.watch(offlineModeProvider);
    final authState = ref.watch(authNotifierProvider);
    final profile = syncState.userProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ajustes y Sincronización',
          style: TextStyle(fontWeight: FontWeight.w800),
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
                      (authState.user?.name.isNotEmpty == true)
                          ? authState.user!.name.substring(0, 1).toUpperCase()
                          : 'S',
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
                          profile?['name']?.toString() ??
                              authState.user?.name ??
                              'Santiago Avirama',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?['role']?.toString() ??
                              authState.user?.role ??
                              'Zootecnista / Mobile Tech Lead',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?['granja']?.toString() ??
                              authState.user?.granja ??
                              'Granja San Jerónimo • Galpón 4',
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

            // --- Estado de Conexión con el Servidor FastAPI ---
            const Text(
              'Estado de Conectividad con Servidor',
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOffline ? AppColors.warningOrange : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOffline
                              ? 'Modo Offline Forzado Activado'
                              : 'Conectado a FastAPI REST (HTTP/HTTPS)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slateDark,
                          ),
                        ),
                        Text(
                          isOffline
                              ? 'Las transacciones se guardan en la cola local'
                              : 'Latencia nominal: ~45ms • BaseUrl: api.porcitech.agro.co',
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
            const SizedBox(height: 20),

            // --- Switches de Configuración de Campo ---
            const Text(
              'Configuración de Operación',
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
                    secondary: const Icon(Icons.signal_wifi_off_rounded, color: AppColors.warningOrange),
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
                      'Alertas de fin de retiro farmacológico y pesajes atrasados',
                      style: TextStyle(fontSize: 12, color: AppColors.slateMuted),
                    ),
                    secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Cola de Sincronización Offline (`offline-queue`) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cola de Sincronización Offline',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slateHeading,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: syncState.queueItems.isNotEmpty ? AppColors.warningLight : AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${syncState.queueItems.length} pendientes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: syncState.queueItems.isNotEmpty ? AppColors.warningOrange : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (syncState.message != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mintBorder),
                ),
                child: Text(
                  syncState.message!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
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
                child: Column(
                  children: const [
                    Icon(Icons.cloud_done_rounded, color: AppColors.primary, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Todas las transacciones de campo están al día con FastAPI.',
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
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: AppColors.warningOrange),
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
                                '${item.method} ${item.endpoint} • ${DateFormat('HH:mm:ss').format(item.createdAt)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.slateMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 14),

            // Botón Sincronizar Cola
            TactileButton(
              text: 'Sincronizar Cola Ahora (/api/sync/offline-queue/)',
              icon: Icons.sync_rounded,
              isLoading: syncState.isSyncing,
              onPressed: syncState.queueItems.isEmpty
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
}
