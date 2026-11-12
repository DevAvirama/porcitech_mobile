import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/brand_mark.dart';
import 'package:porcitech_mobile/src/core/widgets/empty_state_view.dart';
import 'package:porcitech_mobile/src/core/widgets/error_banner.dart';
import 'package:porcitech_mobile/src/core/widgets/skeleton_loader.dart';
import 'package:porcitech_mobile/src/core/widgets/status_badge.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/animals/presentation/controllers/animals_controller.dart';

/// Pantalla: Listado de Corrales y Porcinos (`listado_de_lotes_y_porcinos_porcitech`).
/// Paridad con `/animales` y `/corrales` de la plataforma Web SENA PorciTech.
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
    extends ConsumerState<ListadoDeLotesYPorcinosPorcitech>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final List<String> _filtros = ['Todos', 'Gestación', 'Ceba', 'Enfermos'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAnimalDialog() {
    final state = ref.read(animalsNotifierProvider);
    final lotes = state.lotes;
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController();
    final pesoController = TextEditingController();
    String razaSelected = 'Landrace';
    String sexoSelected = 'Hembra';
    String estadoSelected = 'engorde';
    LoteEntity? selectedLote = lotes.isNotEmpty ? lotes.first : null;

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
                              color: AppColors.senaBlue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código / Arete Oficial',
                          hintText: 'Ej. POR-501',
                          prefixIcon: Icon(Icons.qr_code_2_rounded),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Ingrese el código de arete' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: razaSelected,
                              decoration: const InputDecoration(
                                labelText: 'Raza',
                                prefixIcon: Icon(Icons.pets_rounded),
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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: sexoSelected,
                              decoration: const InputDecoration(
                                labelText: 'Sexo',
                                prefixIcon: Icon(Icons.wc_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
                                DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => sexoSelected = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: estadoSelected,
                              decoration: const InputDecoration(
                                labelText: 'Estado Productivo',
                                prefixIcon: Icon(Icons.insights_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'engorde', child: Text('Engorde / Ceba')),
                                DropdownMenuItem(value: 'lactancia', child: Text('Lactancia')),
                                DropdownMenuItem(value: 'reproduccion', child: Text('Reproducción')),
                                DropdownMenuItem(value: 'cuarentena', child: Text('Cuarentena')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => estadoSelected = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: pesoController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Peso Inicial (kg)',
                                hintText: 'Ej. 25.0',
                                prefixIcon: Icon(Icons.scale_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LoteEntity>(
                        initialValue: selectedLote,
                        decoration: const InputDecoration(
                          labelText: 'Asignar a Corral Activo',
                          prefixIcon: Icon(Icons.fence_rounded),
                        ),
                        items: lotes
                            .map(
                              (l) => DropdownMenuItem<LoteEntity>(
                                value: l,
                                child: Text('${l.codigo} • ${l.nombre} (${l.fase})'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setModalState(() => selectedLote = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      TactileButton(
                        text: 'Guardar Porcino en Hato',
                        icon: Icons.save_rounded,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final navigator = Navigator.of(sheetContext);
                          final messenger = ScaffoldMessenger.of(sheetContext);
                          final peso =
                              double.tryParse(pesoController.text.replaceAll(',', '.'));

                          final success = await ref
                              .read(animalsNotifierProvider.notifier)
                              .registerPorcino(
                                codigo: codigoController.text.trim(),
                                raza: razaSelected,
                                sexo: sexoSelected,
                                fechaNacimiento:
                                    DateTime.now().subtract(const Duration(days: 45)),
                                loteId: selectedLote?.id ?? 1,
                                corralUuid: selectedLote?.uuid,
                                estado: estadoSelected,
                                pesoInicialKg: peso ?? 0.0,
                              );
                          if (success && mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Porcino registrado exitosamente.'),
                                backgroundColor: AppColors.senaGreen,
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

  void _showAddCorralDialog() {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController();
    final nombreController = TextEditingController();
    final capacidadController = TextEditingController(text: '30');
    String faseSelected = 'ceba';

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
                            'Crear Nuevo Corral',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.senaBlue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código del Corral',
                          hintText: 'Ej. COR-04',
                          prefixIcon: Icon(Icons.qr_code_rounded),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Ingrese el código' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción / Galpón',
                          hintText: 'Ej. Corral Ceba Galpón Norte',
                          prefixIcon: Icon(Icons.fence_rounded),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Ingrese la descripción' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: faseSelected,
                              decoration: const InputDecoration(
                                labelText: 'Fase Productiva',
                                prefixIcon: Icon(Icons.layers_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'maternidad', child: Text('Maternidad')),
                                DropdownMenuItem(value: 'precebo', child: Text('Precebo')),
                                DropdownMenuItem(value: 'levante', child: Text('Levante')),
                                DropdownMenuItem(value: 'ceba', child: Text('Ceba')),
                                DropdownMenuItem(value: 'gestacion', child: Text('Gestación')),
                                DropdownMenuItem(value: 'cuarentena', child: Text('Cuarentena')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => faseSelected = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: capacidadController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Capacidad Máx.',
                                prefixIcon: Icon(Icons.groups_rounded),
                              ),
                              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                                  ? 'Capacidad > 0'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TactileButton(
                        text: 'Registrar Corral',
                        icon: Icons.save_rounded,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final navigator = Navigator.of(sheetContext);
                          final messenger = ScaffoldMessenger.of(sheetContext);

                          final success = await ref
                              .read(animalsNotifierProvider.notifier)
                              .registerLote(
                                codigo: codigoController.text.trim(),
                                nombre: nombreController.text.trim(),
                                fase: faseSelected,
                                galpon: nombreController.text.trim(),
                                capacidadMaxima:
                                    int.tryParse(capacidadController.text.trim()) ?? 30,
                              );
                          if (success && mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Corral registrado exitosamente.'),
                                backgroundColor: AppColors.senaGreen,
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
        title: const Row(
          children: [
            BrandMark(compact: true),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Corrales y Porcinos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.senaGreen,
          unselectedLabelColor: AppColors.slateMuted,
          indicatorColor: AppColors.senaGreen,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.pets_rounded, size: 18),
              text: 'Porcinos (${state.porcinos.length})',
            ),
            Tab(
              icon: const Icon(Icons.fence_rounded, size: 18),
              text: 'Corrales (${state.lotes.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.senaGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? 'Nuevo Porcino' : 'Nuevo Corral',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: _tabController.index == 0 ? _showAddAnimalDialog : _showAddCorralDialog,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPorcinosTab(state),
          _buildCorralesTab(state),
        ],
      ),
    );
  }

  Widget _buildPorcinosTab(AnimalsListState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (query) {
              ref.read(animalsNotifierProvider.notifier).setSearchQuery(query);
            },
            decoration: InputDecoration(
              hintText: 'Buscar por arete, raza o corral...',
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
                selectedColor: AppColors.senaGreen,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.slateHeading,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.senaGreen : AppColors.slateBorder,
                ),
                onSelected: (_) {
                  ref.read(animalsNotifierProvider.notifier).setFilter(filtro);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.senaGreen,
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
                    itemBuilder: (_, _) =>
                        const SkeletonLoader(width: double.infinity, height: 96),
                  );
                }

                if (state.errorMessage != null && state.porcinos.isEmpty) {
                  return ErrorBanner(
                    message: state.errorMessage!,
                    onRetry: () =>
                        ref.read(animalsNotifierProvider.notifier).fetchPorcinos(),
                  );
                }

                if (state.porcinos.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.pets_rounded,
                    title: 'No se encontraron porcinos',
                    description:
                        'No hay animales registrados que coincidan con la búsqueda o filtro seleccionado.',
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
    );
  }

  Widget _buildCorralesTab(AnimalsListState state) {
    if (state.lotes.isEmpty) {
      return EmptyStateView(
        icon: Icons.fence_rounded,
        title: 'Sin corrales registrados',
        description: 'Crea el primer corral productivo para organizar el hato.',
        actionText: 'Crear Corral',
        onAction: _showAddCorralDialog,
      );
    }

    return RefreshIndicator(
      color: AppColors.senaGreen,
      onRefresh: () => ref.read(animalsNotifierProvider.notifier).fetchPorcinos(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: state.lotes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lote = state.lotes[index];
          final ocupacionRatio = lote.capacidadMaxima > 0
              ? (lote.cantidadPorcinos / lote.capacidadMaxima).clamp(0.0, 1.0)
              : 0.0;
          return Container(
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fence_rounded,
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
                            '${lote.codigo} • ${lote.nombre}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slateDark,
                            ),
                          ),
                          Text(
                            'Fase: ${lote.fase.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slateMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ocupacionRatio >= 0.9
                            ? AppColors.warningLight
                            : AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${lote.cantidadPorcinos}/${lote.capacidadMaxima} cerdos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: ocupacionRatio >= 0.9
                              ? AppColors.warningOrange
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ocupacionRatio,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: ocupacionRatio >= 0.9
                        ? AppColors.warningOrange
                        : AppColors.senaGreen,
                  ),
                ),
              ],
            ),
          );
        },
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
                      Icons.pets_rounded,
                      color: enRetiro ? AppColors.alertRedDark : AppColors.senaGreen,
                      size: 24,
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
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: AppColors.alertRedDark,
                      ),
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
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.slateMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.slateHeading,
          ),
        ),
      ],
    );
  }
}
