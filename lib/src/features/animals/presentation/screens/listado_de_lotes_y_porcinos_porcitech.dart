import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/empty_state_view.dart';
import 'package:porcitech_mobile/src/core/widgets/error_banner.dart';
import 'package:porcitech_mobile/src/core/widgets/skeleton_loader.dart';
import 'package:porcitech_mobile/src/core/widgets/status_badge.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/animals/presentation/controllers/animals_controller.dart';

/// Pantalla: Listado de Lotes y Porcinos (`listado_de_lotes_y_porcinos_porcitech`).
/// Buscador en tiempo real, filtros zootécnicos ("Todos", "Gestación", "Ceba", "Enfermos")
/// y FAB para alta de nuevos animales en galpón.
class ListadoDeLotesYPorcinosPorcitech extends ConsumerStatefulWidget {
  final void Function(PorcinoEntity porcino) onSelectPorcino;

  const ListadoDeLotesYPorcinosPorcitech({
    super.key,
    required this.onSelectPorcino,
  });

  @override
  ConsumerState<ListadoDeLotesYPorcinosPorcitech> createState() =>
      _ListadoDeLotesYPorcinosPorcitechState();
}

class _ListadoDeLotesYPorcinosPorcitechState
    extends ConsumerState<ListadoDeLotesYPorcinosPorcitech> {
  final _searchController = TextEditingController();
  final List<String> _filtros = ['Todos', 'Gestación', 'Ceba', 'Enfermos'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAnimalDialog() {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController(text: 'POR-${DateTime.now().millisecond + 100}');
    String razaSelected = 'Landrace';
    String sexoSelected = 'Hembra';
    int loteSelected = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Registrar Nuevo Porcino',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slateDark,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código / Arete Visual',
                          hintText: 'ej. POR-501',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: razaSelected,
                        decoration: const InputDecoration(
                          labelText: 'Raza Zootécnica',
                          prefixIcon: Icon(Icons.pets),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Landrace', child: Text('Landrace')),
                          DropdownMenuItem(value: 'Large White', child: Text('Large White')),
                          DropdownMenuItem(value: 'Duroc', child: Text('Duroc')),
                          DropdownMenuItem(value: 'Pietrain', child: Text('Pietrain')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => razaSelected = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: sexoSelected,
                        decoration: const InputDecoration(
                          labelText: 'Sexo Biológico',
                          prefixIcon: Icon(Icons.male_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
                          DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                          DropdownMenuItem(value: 'Macho Castrado', child: Text('Macho Castrado')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => sexoSelected = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        initialValue: loteSelected,
                        decoration: const InputDecoration(
                          labelText: 'Asignar a Lote',
                          prefixIcon: Icon(Icons.grid_view_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Lote Reproductoras A')),
                          DropdownMenuItem(value: 2, child: Text('Lote Levante Norte')),
                          DropdownMenuItem(value: 3, child: Text('Lote Ceba 03')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => loteSelected = val);
                        },
                      ),
                      const SizedBox(height: 24),
                      TactileButton(
                        text: 'Guardar Porcino en Hato',
                        icon: Icons.save_rounded,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final navigator = Navigator.of(sheetContext);
                          final messenger = ScaffoldMessenger.of(sheetContext);

                          final success = await ref
                              .read(animalsNotifierProvider.notifier)
                              .registerPorcino(
                                codigo: codigoController.text.trim(),
                                raza: razaSelected,
                                sexo: sexoSelected,
                                fechaNacimiento: DateTime.now().subtract(const Duration(days: 30)),
                                loteId: loteSelected,
                              );
                          if (success && mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Porcino registrado exitosamente.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(animalsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Lotes y Porcinos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Porcino', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _showAddAnimalDialog,
      ),
      body: Column(
        children: [
          // --- Buscador Superior ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                ref.read(animalsNotifierProvider.notifier).setSearchQuery(query);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por arete (ej. 4092, H-104) o raza...',
                prefixIcon: const Icon(Icons.search, color: AppColors.slateMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(animalsNotifierProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // --- Filtros Zootécnicos Horizontales ---
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filtros.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filtro = _filtros[index];
                final isSelected = state.selectedFilter == filtro;

                return ChoiceChip(
                  label: Text(filtro),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.slateHeading,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.slateBorder,
                  ),
                  onSelected: (_) {
                    ref.read(animalsNotifierProvider.notifier).setFilter(filtro);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // --- Listado de Animales ---
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref.read(animalsNotifierProvider.notifier).fetchPorcinos();
              },
              child: Builder(
                builder: (context) {
                  if (state.isLoading && state.porcinos.isEmpty) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, _) => const SkeletonLoader(width: double.infinity, height: 96),
                    );
                  }

                  if (state.errorMessage != null && state.porcinos.isEmpty) {
                    return ErrorBanner(
                      message: state.errorMessage!,
                      onRetry: () => ref.read(animalsNotifierProvider.notifier).fetchPorcinos(),
                    );
                  }

                  if (state.porcinos.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.pets_rounded,
                      title: 'No se encontraron porcinos',
                      description: 'No hay animales registrados que coincidan con la búsqueda o filtro seleccionado.',
                      actionText: 'Agregar Porcino',
                      onAction: _showAddAnimalDialog,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: state.porcinos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final porcino = state.porcinos[index];
                      return _buildAnimalCard(porcino);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(PorcinoEntity porcino) {
    final bool enRetiro = porcino.tieneRetiroFarmacologicoActivo;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => widget.onSelectPorcino(porcino),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enRetiro ? AppColors.alertRedBorder : const Color(0xFFE2E8F0),
              width: enRetiro ? 1.5 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: enRetiro ? AppColors.alertRedLight : AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.tag_rounded,
                      color: enRetiro ? AppColors.alertRedDark : AppColors.primaryDark,
                      size: 26,
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
                              porcino.codigo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slateDark,
                              ),
                            ),
                            const Spacer(),
                            StatusBadge.fromStatus(porcino.estadoSanitario),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${porcino.raza} • ${porcino.sexo} • ${porcino.loteNombre}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slateMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSubMetric('Peso Actual', '${porcino.pesoActual} kg'),
                  _buildSubMetric('Edad', '${porcino.edadEnDias} días'),
                  _buildSubMetric('GDP Actual', '+${porcino.gdpActualGramoDia.toInt()} g/d'),
                  _buildSubMetric('Fase', porcino.fase),
                ],
              ),
              if (enRetiro) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.alertRedLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.alertRedDark),
                      const SizedBox(width: 4),
                      Text(
                        'Retiro Farmacológico: restan ${porcino.diasRetiroRestantes} días (${porcino.medicacionActiva})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.alertRedDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.slateMuted, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slateHeading),
        ),
      ],
    );
  }
}
