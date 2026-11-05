import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/empty_state_view.dart';
import 'package:porcitech_mobile/src/core/widgets/error_banner.dart';
import 'package:porcitech_mobile/src/core/widgets/skeleton_loader.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/animals/presentation/controllers/animals_controller.dart';

/// Pantalla: Listado de Lotes y Porcinos (`listado_de_lotes_y_porcinos_porcitech`).
/// Integra los notifiers reales de Riverpod con la interfaz limpia de Stitch.
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
  int _currentBottomNavIndex = 1; // Pestaña activa 'Pens' por defecto

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAnimalDialog() {
    final formKey = GlobalKey<FormState>();
    final codigoController =
        TextEditingController(text: 'POR-${DateTime.now().millisecond + 100}');
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
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: razaSelected,
                        decoration: const InputDecoration(
                          labelText: 'Raza Zootécnica',
                          prefixIcon: Icon(Icons.pets),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Landrace', child: Text('Landrace')),
                          DropdownMenuItem(
                              value: 'Large White', child: Text('Large White')),
                          DropdownMenuItem(
                              value: 'Duroc', child: Text('Duroc')),
                          DropdownMenuItem(
                              value: 'Pietrain', child: Text('Pietrain')),
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
                          DropdownMenuItem(
                              value: 'Hembra', child: Text('Hembra')),
                          DropdownMenuItem(
                              value: 'Macho', child: Text('Macho')),
                          DropdownMenuItem(
                              value: 'Macho Castrado',
                              child: Text('Macho Castrado')),
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
                          DropdownMenuItem(
                              value: 1, child: Text('Lote Reproductoras A')),
                          DropdownMenuItem(
                              value: 2, child: Text('Lote Levante Norte')),
                          DropdownMenuItem(
                              value: 3, child: Text('Lote Ceba 03')),
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
                          final messenger =
                              ScaffoldMessenger.of(sheetContext);

                          final success = await ref
                              .read(animalsNotifierProvider.notifier)
                              .registerPorcino(
                                codigo: codigoController.text.trim(),
                                raza: razaSelected,
                                sexo: sexoSelected,
                                fechaNacimiento: DateTime.now()
                                    .subtract(const Duration(days: 30)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slateDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PORCITECH',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Field Overview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAnimalDialog,
        backgroundColor: AppColors.primary,
        elevation: 3,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // --- Buscador Superior Estilo Stitch ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                ref.read(animalsNotifierProvider.notifier).setSearchQuery(query);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por arete o lote...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.slateMuted,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.slateMuted),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(animalsNotifierProvider.notifier)
                              .setSearchQuery('');
                        },
                      ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.primaryDark,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // --- Filtros Zootécnicos Horizontales (Píldoras) ---
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filtros.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filtro = _filtros[index];
                final isSelected = state.selectedFilter == filtro;
                final isEnfermo = filtro == 'Enfermos';

                return _FilterPill(
                  label: filtro,
                  isSelected: isSelected,
                  isAlert: isEnfermo,
                  onTap: () {
                    ref.read(animalsNotifierProvider.notifier).setFilter(filtro);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // --- Estado de Conexión y Registros Activos ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.porcinos.length} REGISTROS ACTIVOS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slateMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.sensors, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // --- Listado con Refresh, Skeletons y Estados Vacíos ---
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref
                    .read(animalsNotifierProvider.notifier)
                    .fetchPorcinos();
              },
              child: Builder(
                builder: (context) {
                  if (state.isLoading && state.porcinos.isEmpty) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, _) => const SkeletonLoader(
                          width: double.infinity, height: 72),
                    );
                  }

                  if (state.errorMessage != null && state.porcinos.isEmpty) {
                    return ErrorBanner(
                      message: state.errorMessage!,
                      onRetry: () => ref
                          .read(animalsNotifierProvider.notifier)
                          .fetchPorcinos(),
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

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: state.porcinos.length,
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

    // --- BARRA DE NAVEGACIÓN INFERIOR DE MAQUETA ---
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            setState(() => _currentBottomNavIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.slateMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_on_rounded), // Puedes cambiarlo por Icons.grid_view_outlined o Icons.apps_rounded
              label: 'Pens',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hourglass_empty_rounded),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(PorcinoEntity porcino) {
    final bool enRetiro = porcino.tieneRetiroFarmacologicoActivo;
    final bool isEnfermo =
        porcino.estadoSanitario != 'Sano' || porcino.fase == 'TRATAMIENTO';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enRetiro
              ? AppColors.alertRedBorder
              : const Color(0xFFE2E8F0),
          width: enRetiro ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => widget.onSelectPorcino(porcino),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: isEnfermo
                                      ? AppColors.alertRedDark
                                      : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Porcino #${porcino.id}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slateDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isEnfermo
                                    ? Icons.add_box_outlined
                                    : Icons.grid_view_rounded,
                                size: 14,
                                color: isEnfermo
                                    ? AppColors.alertRedDark
                                    : AppColors.slateMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${porcino.loteNombre} • ${porcino.raza}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isEnfermo
                                        ? AppColors.alertRedDark
                                        : AppColors.slateMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${porcino.pesoActual} ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.slateDark,
                              ),
                            ),
                            const Text(
                              'kg',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slateMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          porcino.fase.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isEnfermo
                                ? AppColors.alertRedDark
                                : AppColors.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.slateMuted,
                      size: 20,
                    ),
                  ],
                ),
                if (enRetiro) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.alertRedLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppColors.alertRedDark),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Retiro: ${porcino.diasRetiroRestantes} días restantes (${porcino.medicacionActiva})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.alertRedDark,
                            ),
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
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAlert;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? AppColors.primary
        : (isAlert ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9));

    final textColor = isSelected
        ? Colors.white
        : (isAlert ? AppColors.alertRedDark : AppColors.slateDark);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAlert && !isSelected) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.alertRedDark,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}