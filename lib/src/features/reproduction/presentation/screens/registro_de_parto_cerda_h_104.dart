import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:porcitech_mobile/src/core/constants/zootechnical_constants.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/brand_mark.dart';
import 'package:porcitech_mobile/src/core/widgets/porcino_picker_sheet.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/animals/presentation/controllers/animals_controller.dart';
import 'package:porcitech_mobile/src/features/reproduction/presentation/controllers/reproduction_controller.dart';

/// Pantalla: Ciclo Reproductivo Integral (`registro_de_parto_cerda_h_104`).
/// Paridad con `/reproduccion` de la Web SENA PorciTech:
/// 1. Partos y Camadas
/// 2. Servicios / Inseminación y Diagnóstico de Gestación
/// 3. Destetes y Traslado a Precebo
class RegistroDePartoCerdaH104 extends ConsumerStatefulWidget {
  final PorcinoEntity cerda;
  final VoidCallback onPartoGuardado;

  const RegistroDePartoCerdaH104({
    super.key,
    required this.cerda,
    required this.onPartoGuardado,
  });

  @override
  ConsumerState<RegistroDePartoCerdaH104> createState() =>
      _RegistroDePartoCerdaH104State();
}

class _RegistroDePartoCerdaH104State
    extends ConsumerState<RegistroDePartoCerdaH104>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late PorcinoEntity _cerda;

  // Contadores de Parto (inician en 0, sin datos pre-quemados)
  int _nacidosVivos = 0;
  int _nacidosMuertos = 0;
  int _momias = 0;
  double _pesoCamadaKg = 14.0;
  final _observacionesPartoController = TextEditingController();

  // Controles de Servicio / Inseminación
  String _tipoServicio = 'inseminacion_artificial';
  final _verracoController = TextEditingController();
  final _notasServicioController = TextEditingController();

  // Controles de Destete
  int _lechonesDestetados = 10;
  final _pesoDesteteController = TextEditingController(text: '6.8');
  String? _corralPreceboDestinoUuid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cerda = widget.cerda;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _observacionesPartoController.dispose();
    _verracoController.dispose();
    _notasServicioController.dispose();
    _pesoDesteteController.dispose();
    super.dispose();
  }

  int get _totalNacidos => _nacidosVivos + _nacidosMuertos + _momias;
  double get _pesoPromedioLechon =>
      _nacidosVivos > 0 ? (_pesoCamadaKg / _nacidosVivos) : 0.0;

  Future<void> _cambiarCerda() async {
    final picked = await PorcinoPickerSheet.show(
      context,
      title: 'Seleccionar Hembra Reproductora',
      subtitle: 'Elija la cerda para parto, servicio o destete',
      soloHembrasReproductoras: true,
    );
    if (picked != null && mounted) {
      setState(() => _cerda = picked);
    }
  }

  Future<void> _handleGuardarParto() async {
    if (_cerda.sexo.toLowerCase() != 'hembra') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se puede registrar parto en hembras reproductoras.'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    if (_totalNacidos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el conteo de lechones nacidos antes de guardar.'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    final success = await ref.read(reproductionNotifierProvider.notifier).registrarParto(
          porcinoId: _cerda.id,
          hembraUuid: _cerda.uuid,
          corralMaternidadUuid: _cerda.corralUuid,
          fecha: DateTime.now(),
          nacidosVivos: _nacidosVivos,
          nacidosMuertos: _nacidosMuertos,
          momias: _momias,
          pesoTotalCamadaKg: _pesoCamadaKg,
          numeroParto: 1,
          observaciones: _observacionesPartoController.text.trim(),
        );

    if (success && mounted) {
      setState(() {
        _nacidosVivos = 0;
        _nacidosMuertos = 0;
        _momias = 0;
      });
      _observacionesPartoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parto de ${_cerda.codigo} registrado exitosamente.'),
          backgroundColor: AppColors.senaGreen,
        ),
      );
      widget.onPartoGuardado();
    }
  }

  Future<void> _handleGuardarServicio() async {
    if (_verracoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el código del verraco o lote seminal.'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    final ok = await ref.read(reproductionNotifierProvider.notifier).registrarServicio(
          porcinoId: _cerda.id,
          hembraUuid: _cerda.uuid,
          hembraArete: _cerda.codigo,
          fechaServicio: DateTime.now(),
          tipoServicio: _tipoServicio,
          codigoPajilla: _verracoController.text.trim(),
          observaciones: _notasServicioController.text.trim(),
        );

    if (ok && mounted) {
      _verracoController.clear();
      _notasServicioController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Servicio reproductivo registrado para ${_cerda.codigo}.'),
          backgroundColor: AppColors.senaGreen,
        ),
      );
    }
  }

  Future<void> _handleGuardarDestete() async {
    final pesoProm =
        double.tryParse(_pesoDesteteController.text.replaceAll(',', '.')) ?? 6.5;

    final ok = await ref.read(reproductionNotifierProvider.notifier).registrarDestete(
          porcinoId: _cerda.id,
          hembraUuid: _cerda.uuid,
          hembraArete: _cerda.codigo,
          corralDestinoUuid: _corralPreceboDestinoUuid,
          fechaDestete: DateTime.now(),
          lechonesDestetados: _lechonesDestetados,
          pesoTotalKg: pesoProm * _lechonesDestetados,
        );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destete registrado exitosamente.'),
          backgroundColor: AppColors.senaGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reproState = ref.watch(reproductionNotifierProvider);
    final animalsState = ref.watch(animalsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(compact: true),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reproducción • ${_cerda.codigo}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.senaBlue),
            tooltip: 'Cambiar Hembra Reproductora',
            onPressed: _cambiarCerda,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.senaGreen,
          unselectedLabelColor: AppColors.slateMuted,
          indicatorColor: AppColors.senaGreen,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          tabs: const [
            Tab(icon: Icon(Icons.pets_rounded, size: 18), text: 'Partos'),
            Tab(icon: Icon(Icons.favorite_border_rounded, size: 18), text: 'Servicios'),
            Tab(icon: Icon(Icons.move_up_rounded, size: 18), text: 'Destetes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPartosTab(reproState),
          _buildServiciosTab(reproState),
          _buildDestetesTab(reproState, animalsState),
        ],
      ),
    );
  }

  Widget _buildSowHeader() {
    return InkWell(
      onTap: _cambiarCerda,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Color(0xFF7E22CE),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_cerda.codigo} • ${_cerda.raza}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slateDark,
                    ),
                  ),
                  Text(
                    'Corral: ${_cerda.loteNombre} • Fase: ${_cerda.fase}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slateMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Chip(
              label: Text(
                'Cambiar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.senaBlue,
                ),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartosTab(ReproductionState state) {
    final bool cumpleMetaPorkcolombia =
        _nacidosVivos >= ZootechnicalConstants.metaNacidosVivos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSowHeader(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cumpleMetaPorkcolombia ? AppColors.mintSoft : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cumpleMetaPorkcolombia ? AppColors.mintBorder : AppColors.slateBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Nacidos', '$_totalNacidos'),
                _buildSummaryItem(
                  'Promedio/Lechón',
                  '${_pesoPromedioLechon.toStringAsFixed(2)} kg',
                ),
                _buildSummaryItem('Meta Estándar', '≥12 vivos'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Conteo Biológico de Lechones',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.senaBlue,
            ),
          ),
          const SizedBox(height: 10),
          _buildTactileCounter(
            title: 'Nacidos Vivos',
            subtitle: 'Lechones viables y activos',
            count: _nacidosVivos,
            color: AppColors.senaGreen,
            bgColor: AppColors.mintSoft,
            onDecrement: () {
              if (_nacidosVivos > 0) setState(() => _nacidosVivos--);
            },
            onIncrement: () => setState(() => _nacidosVivos++),
          ),
          const SizedBox(height: 10),
          _buildTactileCounter(
            title: 'Nacidos Muertos (Mortinatos)',
            subtitle: 'Muertes pre o intra-parto',
            count: _nacidosMuertos,
            color: AppColors.alertRedDark,
            bgColor: AppColors.alertRedLight,
            onDecrement: () {
              if (_nacidosMuertos > 0) setState(() => _nacidosMuertos--);
            },
            onIncrement: () => setState(() => _nacidosMuertos++),
          ),
          const SizedBox(height: 10),
          _buildTactileCounter(
            title: 'Momias / Fetos Momificados',
            subtitle: 'Reabsorción o falla embrionaria',
            count: _momias,
            color: AppColors.slateHeading,
            bgColor: AppColors.surfaceVariant,
            onDecrement: () {
              if (_momias > 0) setState(() => _momias--);
            },
            onIncrement: () => setState(() => _momias++),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Peso Total de Camada (kg)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slateHeading,
                      ),
                    ),
                    Text(
                      '${_pesoCamadaKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.senaGreen,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _pesoCamadaKg,
                  min: 1.0,
                  max: 30.0,
                  divisions: 58,
                  activeColor: AppColors.senaGreen,
                  label: '${_pesoCamadaKg.toStringAsFixed(1)} kg',
                  onChanged: (val) => setState(() => _pesoCamadaKg = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _observacionesPartoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observaciones del Parto (Opcional)',
              hintText: 'Ej. Encalostramiento asistido, temperatura normal...',
              prefixIcon: Icon(Icons.notes_rounded, color: AppColors.slateMuted),
            ),
          ),
          const SizedBox(height: 20),
          TactileButton(
            text: 'Confirmar y Guardar Parto',
            icon: Icons.save_rounded,
            isLoading: state.isLoading,
            onPressed: _handleGuardarParto,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServiciosTab(ReproductionState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSowHeader(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Registrar Servicio / Inseminación (Proyección +114 días)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.senaBlue,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _tipoServicio,
                decoration: const InputDecoration(
                  labelText: 'Método Reproductivo',
                  prefixIcon: Icon(Icons.biotech_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'inseminacion_artificial',
                    child: Text('Inseminación Artificial'),
                  ),
                  DropdownMenuItem(
                    value: 'monta_natural',
                    child: Text('Monta Natural'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _tipoServicio = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _verracoController,
                decoration: const InputDecoration(
                  labelText: 'Verraco / Código de Dosis Seminal',
                  hintText: 'Ej. DUROC-SEM-204',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notasServicioController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones de Celo / Servicio',
                  hintText: 'Ej. Reflejo de quietud positivo',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TactileButton(
                text: 'Registrar Servicio Reproductivo',
                icon: Icons.favorite_rounded,
                isLoading: state.isLoading,
                onPressed: _handleGuardarServicio,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Servicios y Diagnósticos de Gestación',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.senaBlue,
          ),
        ),
        const SizedBox(height: 10),
        if (state.servicios.isEmpty)
          const Text(
            'No hay servicios reproductivos registrados.',
            style: TextStyle(color: AppColors.slateMuted),
          )
        else
          ...state.servicios.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${s.hembraArete} • ${s.tipoServicio} (${s.codigoPajillaMacho ?? "-"})',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateDark,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          s.estadoConfirmacion.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Text(
                    'Servicio: ${DateFormat('dd/MM/yyyy').format(s.fechaServicio)} • Parto probable: ${DateFormat('dd/MM/yyyy').format(s.fechaProbableParto)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.slateMuted),
                  ),
                  if (s.estadoConfirmacion.toLowerCase() == 'pendiente') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.senaGreen,
                            ),
                            label: const Text('Confirmar Preñez'),
                            onPressed: () {
                              ref
                                  .read(reproductionNotifierProvider.notifier)
                                  .actualizarDiagnostico(
                                    servicioId: s.id,
                                    estadoConfirmacion: 'positiva',
                                  );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.cancel_outlined,
                              size: 16,
                              color: AppColors.alertRedDark,
                            ),
                            label: const Text('Repetidora'),
                            onPressed: () {
                              ref
                                  .read(reproductionNotifierProvider.notifier)
                                  .actualizarDiagnostico(
                                    servicioId: s.id,
                                    estadoConfirmacion: 'negativa',
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDestetesTab(
    ReproductionState state,
    AnimalsListState animalsState,
  ) {
    final corralesPrecebo = animalsState.lotes;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSowHeader(),
        const SizedBox(height: 14),
        const Text(
          'Registrar Destete y Traslado a Precebo',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.senaBlue,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
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
                  Expanded(
                    child: TextField(
                      controller: _pesoDesteteController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Peso Prom. Lechón (kg)',
                        prefixIcon: Icon(Icons.scale_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _corralPreceboDestinoUuid,
                      decoration: const InputDecoration(
                        labelText: 'Corral Destino',
                        prefixIcon: Icon(Icons.fence_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin traslado'),
                        ),
                        ...corralesPrecebo.map(
                          (l) => DropdownMenuItem<String?>(
                            value: l.uuid,
                            child: Text('${l.codigo} (${l.fase})'),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _corralPreceboDestinoUuid = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTactileCounter(
                title: 'Lechones Destetados',
                subtitle: 'Cantidad trasladada a precebo',
                count: _lechonesDestetados,
                color: AppColors.senaGreen,
                bgColor: AppColors.mintSoft,
                onDecrement: () {
                  if (_lechonesDestetados > 1) {
                    setState(() => _lechonesDestetados--);
                  }
                },
                onIncrement: () => setState(() => _lechonesDestetados++),
              ),
              const SizedBox(height: 14),
              TactileButton(
                text: 'Registrar Destete de Camada',
                icon: Icons.move_up_rounded,
                isLoading: state.isLoading,
                onPressed: _handleGuardarDestete,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Historial de Destetes',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.senaBlue,
          ),
        ),
        const SizedBox(height: 10),
        if (state.destetes.isEmpty)
          const Text(
            'Sin destetes registrados.',
            style: TextStyle(color: AppColors.slateMuted),
          )
        else
          ...state.destetes.map(
            (d) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.move_up_rounded, color: AppColors.senaGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d.hembraArete} • ${d.lechonesDestetados} lechones • Prom. ${d.pesoPromedioLechon.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateDark,
                          ),
                        ),
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(d.fechaDestete)} • Total: ${d.pesoTotalKg.toStringAsFixed(1)} kg',
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
          ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.slateMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.slateDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTactileCounter({
    required String title,
    required String subtitle,
    required int count,
    required Color color,
    required Color bgColor,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slateDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.slateMuted),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildStepButton(
                icon: Icons.remove,
                color: color,
                onTap: onDecrement,
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              _buildStepButton(
                icon: Icons.add,
                color: color,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
