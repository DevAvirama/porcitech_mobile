import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';
import '../../features/animals/domain/entities/porcino_entity.dart';
import '../../features/animals/presentation/controllers/animals_controller.dart';

/// Hoja modal reutilizable para seleccionar un porcino real del hato
/// (o filtrar solo hembras reproductoras) antes de abrir formularios de Pesaje, Sanidad o Parto.
class PorcinoPickerSheet extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final bool soloHembrasReproductoras;
  final VoidCallback? onScanQr;

  const PorcinoPickerSheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.soloHembrasReproductoras = false,
    this.onScanQr,
  });

  static Future<PorcinoEntity?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    bool soloHembrasReproductoras = false,
    VoidCallback? onScanQr,
  }) {
    return showModalBottomSheet<PorcinoEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PorcinoPickerSheet(
        title: title,
        subtitle: subtitle,
        soloHembrasReproductoras: soloHembrasReproductoras,
        onScanQr: onScanQr,
      ),
    );
  }

  @override
  ConsumerState<PorcinoPickerSheet> createState() => _PorcinoPickerSheetState();
}

class _PorcinoPickerSheetState extends ConsumerState<PorcinoPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final animalsState = ref.watch(animalsNotifierProvider);
    final allAnimals = animalsState.porcinos;

    final filtered = allAnimals.where((p) {
      if (widget.soloHembrasReproductoras && !p.esHembra) return false;
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return p.codigo.toLowerCase().contains(q) ||
          (p.nombreAlias?.toLowerCase().contains(q) ?? false) ||
          p.loteNombre.toLowerCase().contains(q) ||
          p.raza.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.76,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.slateBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: AppColors.senaGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.senaBlue,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slateMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onScanQr != null)
                IconButton(
                  tooltip: 'Escanear chapeta QR',
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.senaGreen,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onScanQr!();
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (val) => setState(() => _query = val),
            decoration: const InputDecoration(
              hintText: 'Filtrar por arete (ej. POR-4092), corral o raza...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron ejemplares con ese criterio.',
                      style: TextStyle(color: AppColors.slateMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final p = filtered[idx];
                      return Material(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, p),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.mintBorder),
                                  ),
                                  child: const Icon(
                                    Icons.sell_outlined,
                                    color: AppColors.senaGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            p.codigo,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.slateDark,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge.fromStatus(p.estadoSanitario),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${p.loteNombre} • ${p.raza} (${p.sexo}) • ${p.pesoActual} kg',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.slateMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.slateMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
