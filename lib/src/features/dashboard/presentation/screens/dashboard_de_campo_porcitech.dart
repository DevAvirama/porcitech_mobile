import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dashboard_controller.dart';

class DashboardDeCampoPorcitech extends ConsumerWidget {
  final VoidCallback? onScanQr;
  final VoidCallback? onOpenPesaje;
  final VoidCallback? onOpenSanidad;
  final VoidCallback? onOpenPartos;
  final VoidCallback? onOpenLotes;
  final VoidCallback? onOpenAjustes;

  const DashboardDeCampoPorcitech({
    super.key,
    this.onScanQr,
    this.onOpenPesaje,
    this.onOpenSanidad,
    this.onOpenPartos,
    this.onOpenLotes,
    this.onOpenAjustes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF007A33))),
      );
    }

    final summary = state.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF007A33),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PORCITECH',
                  style: TextStyle(
                    color: Color(0xFF007A33),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Field Overview',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: onOpenAjustes,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardNotifierProvider.notifier).loadSummary(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola, Operador',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: onScanQr,
                borderRadius: BorderRadius.circular(16),
                child: _buildScanButton(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ANIMALES\nTOTAL',
                      value: summary != null ? '${summary.totalPorcinos}' : '0',
                      subtitle: 'Pabellones A-D',
                      icon: Icons.pets,
                      badgeColor: const Color(0xFFE8F0FE),
                      iconColor: const Color(0xFF1967D2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ALERTAS HOY',
                      value: summary != null ? '${summary.alertasSanitarias}' : '0',
                      subtitle: 'Pendientes',
                      subtitleColor: Colors.red.shade700,
                      icon: Icons.notifications_active_outlined,
                      badgeColor: const Color(0xFFFCE8E6),
                      iconColor: const Color(0xFFD93025),
                      statusTag: 'PENDIENTE',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildOperationsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF007A33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'LECTURA RÁPIDA • LECTOR ACTIVO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
    Color? subtitleColor,
    String? statusTag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: subtitleColor ?? Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildOperationsGrid() {
    final List<Map<String, dynamic>> operations = [
      {'title': 'Pesaje', 'subtitle': 'Báscula y ganancia', 'icon': Icons.hourglass_bottom, 'onTap': onOpenPesaje},
      {'title': 'Sanidad', 'subtitle': 'Dosis y tratamientos', 'icon': Icons.medical_services_outlined, 'onTap': onOpenSanidad},
      {'title': 'Partos', 'subtitle': 'Maternidad y lechigadas', 'icon': Icons.sentiment_satisfied_alt_outlined, 'onTap': onOpenPartos},
      {'title': 'Lotes', 'subtitle': 'Corrales y traslados', 'icon': Icons.grid_view_outlined, 'onTap': onOpenLotes},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: operations.length,
      itemBuilder: (context, index) {
        final item = operations[index];
        return InkWell(
          onTap: item['onTap'] as VoidCallback?,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item['icon'] as IconData, color: const Color(0xFF1967D2), size: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(item['subtitle'] as String, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}