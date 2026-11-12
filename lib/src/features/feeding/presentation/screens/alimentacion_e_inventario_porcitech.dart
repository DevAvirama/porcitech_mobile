import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/animals/presentation/controllers/animals_controller.dart';
import 'package:porcitech_mobile/src/features/feeding/domain/entities/feeding_entity.dart';
import 'package:porcitech_mobile/src/features/feeding/presentation/controllers/feeding_controller.dart';

/// Pantalla: Alimentación y Bodega de Insumos (`alimentacion_e_inventario_porcitech`).
/// Homologada con los módulos Web de `/dashboard/feeding` y `/dashboard/inventory`.
class AlimentacionEInventarioPorcitech extends ConsumerStatefulWidget {
  const AlimentacionEInventarioPorcitech({super.key});

  @override
  ConsumerState<AlimentacionEInventarioPorcitech> createState() =>
      _AlimentacionEInventarioPorcitechState();
}

class _AlimentacionEInventarioPorcitechState
    extends ConsumerState<AlimentacionEInventarioPorcitech>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _observacionesController = TextEditingController();

  LoteEntity? _corralSeleccionado;
  InventoryItemEntity? _alimentoSeleccionado;
  String _faseNutricional = 'Ceba';

  final List<String> _fasesNutricionales = const [
    'Pre-iniciador',
    'Iniciador',
    'Levante',
    'Ceba',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cantidadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistrarRacion(
    List<LoteEntity> lotes,
    List<InventoryItemEntity> alimentos,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final corral = _corralSeleccionado ?? (lotes.isNotEmpty ? lotes.first : null);
    final alimento =
        _alimentoSeleccionado ?? (alimentos.isNotEmpty ? alimentos.first : null);

    if (corral == null || alimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un corral y un alimento disponible en bodega.'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    final cantidad =
        double.tryParse(_cantidadController.text.replaceAll(',', '.')) ?? 0.0;
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese una cantidad válida en kilogramos (> 0 kg).'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    final ok = await ref.read(feedingNotifierProvider.notifier).registrarRacion(
          corralUuid: corral.uuid ?? corral.id.toString(),
          corralCodigo: corral.codigo,
          alimentoItemId: alimento.id,
          alimentoNombre: alimento.nombre,
          faseAlimentacion: _faseNutricional,
          cantidadKg: cantidad,
          observaciones: _observacionesController.text.trim(),
        );

    if (ok && mounted) {
      _cantidadController.clear();
      _observacionesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ración de ${cantidad.toStringAsFixed(1)} kg registrada en ${corral.codigo}.',
          ),
          backgroundColor: AppColors.senaGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedingState = ref.watch(feedingNotifierProvider);
    final animalsState = ref.watch(animalsNotifierProvider);
    final lotes = animalsState.lotes;
    final alimentos = feedingState.alimentos;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Alimentación y Bodega',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.senaGreen,
          unselectedLabelColor: AppColors.slateMuted,
          indicatorColor: AppColors.senaGreen,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.restaurant_rounded, size: 20),
              text: 'Suministro Raciones',
            ),
            Tab(
              icon: Icon(Icons.inventory_2_outlined, size: 20),
              text: 'Stock en Bodega',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRacionesTab(feedingState, lotes, alimentos),
          _buildInventarioTab(feedingState),
        ],
      ),
    );
  }

  Widget _buildRacionesTab(
    FeedingState feedingState,
    List<LoteEntity> lotes,
    List<InventoryItemEntity> alimentos,
  ) {
    final corralActivo =
        _corralSeleccionado ?? (lotes.isNotEmpty ? lotes.first : null);
    final alimentoActivo =
        _alimentoSeleccionado ?? (alimentos.isNotEmpty ? alimentos.first : null);

    return RefreshIndicator(
      color: AppColors.senaGreen,
      onRefresh: () => ref.read(feedingNotifierProvider.notifier).loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.scale_outlined,
                            color: AppColors.senaGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar Suministro en Corral',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.senaBlue,
                                ),
                              ),
                              Text(
                                'Descuenta automáticamente las existencias de bodega',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slateMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (lotes.isNotEmpty)
                      DropdownButtonFormField<LoteEntity>(
                        initialValue: corralActivo,
                        decoration: const InputDecoration(
                          labelText: 'Corral de Destino',
                          prefixIcon: Icon(Icons.fence_rounded),
                        ),
                        items: lotes
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text('${l.codigo} • ${l.nombre}'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _corralSeleccionado = val),
                      ),
                    const SizedBox(height: 14),
                    if (alimentos.isNotEmpty)
                      DropdownButtonFormField<InventoryItemEntity>(
                        initialValue: alimentoActivo,
                        decoration: const InputDecoration(
                          labelText: 'Alimento / Insumo de Bodega',
                          prefixIcon: Icon(Icons.grain_rounded),
                        ),
                        items: alimentos
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(
                                  '${a.nombre} (${a.stockActual.toStringAsFixed(0)} ${a.unidadMedida})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _alimentoSeleccionado = val),
                      ),
                    const SizedBox(height: 14),
                    const Text(
                      'Fase Nutricional',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slateHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _fasesNutricionales.map((fase) {
                        final selected = _faseNutricional == fase;
                        return ChoiceChip(
                          label: Text(fase),
                          selected: selected,
                          selectedColor: AppColors.senaGreen,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.slateHeading,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (_) =>
                              setState(() => _faseNutricional = fase),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cantidadController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad Servida (kg)',
                        hintText: 'ej. 45.0',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                        suffixText: 'kg',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingrese los kg servidos' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones de consumo (opcional)',
                        hintText: 'ej. Comederos limpios, apetito normal',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TactileButton(
                      text: 'Registrar Ración y Descontar Stock',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: feedingState.isLoading,
                      onPressed: () => _handleRegistrarRacion(lotes, alimentos),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Historial Reciente de Raciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slateHeading,
                ),
              ),
              const SizedBox(height: 10),
              if (feedingState.raciones.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Aún no hay suministros de ración registrados hoy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slateMuted),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: feedingState.raciones.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final r = feedingState.raciones[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.mintSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.senaGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.corralCodigo} • ${r.alimentoNombre}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slateDark,
                                  ),
                                ),
                                Text(
                                  'Fase: ${r.faseAlimentacion} • ${DateFormat('dd/MM HH:mm').format(r.fechaSuministro)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slateMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${r.cantidadKg.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.senaGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventarioTab(FeedingState feedingState) {
    final items = feedingState.insumos;

    return RefreshIndicator(
      color: AppColors.senaGreen,
      onRefresh: () => ref.read(feedingNotifierProvider.notifier).loadData(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final item = items[idx];
          final bajo = item.esBajoStock;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: bajo ? AppColors.alertRedBorder : const Color(0xFFE2E8F0),
                width: bajo ? 1.5 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bajo ? AppColors.alertRedLight : AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.esAlimento
                        ? Icons.grain_rounded
                        : Icons.medication_outlined,
                    color: bajo ? AppColors.alertRedDark : AppColors.senaGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slateDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${item.codigoSku} • ${item.ubicacionBodega}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slateMuted,
                        ),
                      ),
                      if (bajo) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Stock Crítico (Mínimo: ${item.stockMinimo.toStringAsFixed(0)} ${item.unidadMedida})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.alertRedDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.stockActual.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color:
                            bajo ? AppColors.alertRedDark : AppColors.senaBlue,
                      ),
                    ),
                    Text(
                      item.unidadMedida,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
