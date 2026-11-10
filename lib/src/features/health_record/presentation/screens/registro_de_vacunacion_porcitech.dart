import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:porcitech_mobile/src/core/constants/zootechnical_constants.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/brand_mark.dart';
import 'package:porcitech_mobile/src/core/widgets/porcino_picker_sheet.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/core/widgets/withdrawal_alert_banner.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/health_record/presentation/controllers/health_controller.dart';

/// Pantalla: Sanidad, Kárdex de Retiro y Bioseguridad (`registro_de_vacunacion_porcitech`).
/// Paridad completa con `/sanidad` de la plataforma Web SENA PorciTech.
class RegistroDeVacunacionPorcitech extends ConsumerStatefulWidget {
  final PorcinoEntity porcino;
  final VoidCallback onEventoGuardado;

  const RegistroDeVacunacionPorcitech({
    super.key,
    required this.porcino,
    required this.onEventoGuardado,
  });

  @override
  ConsumerState<RegistroDeVacunacionPorcitech> createState() =>
      _RegistroDeVacunacionPorcitechState();
}

class _RegistroDeVacunacionPorcitechState
    extends ConsumerState<RegistroDeVacunacionPorcitech>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late PorcinoEntity _porcino;

  final _formKey = GlobalKey<FormState>();
  final _loteBiologicoController = TextEditingController();
  final _observacionesController = TextEditingController();

  String _tipoEvento = 'vacuna';
  String _medicamentoSeleccionado = 'Vacuna Peste Porcina Clásica (PPC)';
  double _dosisMl = 2.0;
  String _viaAplicacion = 'Intramuscular en tabla del cuello';

  final List<String> _medicamentosComunes = [
    'Vacuna Peste Porcina Clásica (PPC)',
    'Vacuna Circovirus Porcino (PCV2)',
    'Hierro Dextrano',
    'Oxitetraciclina L.A.',
    'Tilmicosina',
    'Amoxicilina Trihidrato',
  ];

  final List<String> _viasAplicacion = [
    'Intramuscular en tabla del cuello',
    'Subcutánea detrás de la oreja',
    'Oral en bebedero',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _porcino = widget.porcino;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loteBiologicoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  int get _diasRetiro {
    return ZootechnicalConstants.tiemposRetiroDias[_medicamentoSeleccionado] ?? 0;
  }

  Future<void> _cambiarPorcino() async {
    final picked = await PorcinoPickerSheet.show(
      context,
      title: 'Seleccionar Porcino para Sanidad',
      subtitle: 'Elija el ejemplar para aplicar vacuna o tratamiento médico',
    );
    if (picked != null && mounted) {
      setState(() => _porcino = picked);
    }
  }

  Future<void> _handleGuardarSanidad() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(healthNotifierProvider.notifier).registrarEvento(
          porcinoId: _porcino.id,
          animalUuid: _porcino.uuid,
          corralUuid: _porcino.corralUuid,
          tipo: _tipoEvento,
          medicamento: _medicamentoSeleccionado,
          loteBiologico: _loteBiologicoController.text.trim(),
          dosisMl: _dosisMl,
          viaAplicacion: _viaAplicacion,
          fecha: DateTime.now(),
          diasRetiro: _diasRetiro,
          observaciones: _observacionesController.text.trim(),
        );

    if (success && mounted) {
      _loteBiologicoController.clear();
      _observacionesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aplicación de $_medicamentoSeleccionado registrada para ${_porcino.codigo}. Retiro: $_diasRetiro días.',
          ),
          backgroundColor: AppColors.senaGreen,
        ),
      );
      widget.onEventoGuardado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(compact: true),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sanidad • ${_porcino.codigo}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.senaBlue),
            tooltip: 'Cambiar Porcino',
            onPressed: _cambiarPorcino,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.senaGreen,
          unselectedLabelColor: AppColors.slateMuted,
          indicatorColor: AppColors.senaGreen,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          tabs: [
            const Tab(icon: Icon(Icons.vaccines_rounded, size: 18), text: 'Aplicar'),
            Tab(
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              text: 'Retiros (${healthState.alertasRetiro.length})',
            ),
            const Tab(
              icon: Icon(Icons.shield_outlined, size: 18),
              text: 'Bioseguridad',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAplicarTab(healthState),
          _buildKardexYRetirosTab(healthState),
          _buildBioseguridadTab(healthState),
        ],
      ),
    );
  }

  Widget _buildAplicarTab(HealthState healthState) {
    final diasRetiroActual = _diasRetiro;
    final fechaFinRetiro = DateTime.now().add(Duration(days: diasRetiroActual));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _cambiarPorcino,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vaccines_rounded, color: AppColors.alertRedDark, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_porcino.codigo} • ${_porcino.loteNombre}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Peso: ${_porcino.pesoActual} kg • Fase: ${_porcino.fase}',
                            style: const TextStyle(fontSize: 12, color: AppColors.slateMuted),
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
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _tipoEvento,
              decoration: const InputDecoration(
                labelText: 'Tipo de Evento Sanitario',
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'vacuna', child: Text('Vacunación Preventiva')),
                DropdownMenuItem(
                  value: 'tratamiento',
                  child: Text('Tratamiento Farmacológico'),
                ),
                DropdownMenuItem(
                  value: 'desparasitacion',
                  child: Text('Desparasitación / Vermífugo'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _tipoEvento = val);
              },
            ),
            const SizedBox(height: 14),

            const Text(
              'Medicamento o Biológico ICA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _medicamentosComunes.map((med) {
                final isSelected = _medicamentoSeleccionado == med;
                final retiro = ZootechnicalConstants.tiemposRetiroDias[med] ?? 0;

                return ChoiceChip(
                  label: Text(
                    retiro > 0 ? '$med ($retiro d)' : med,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.slateHeading,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: retiro > 0 ? AppColors.alertRedDark : AppColors.senaGreen,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? (retiro > 0 ? AppColors.alertRedDark : AppColors.senaGreen)
                        : AppColors.slateBorder,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _medicamentoSeleccionado = med;
                      _tipoEvento = med.contains('Vacuna') ? 'vacuna' : 'tratamiento';
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            WithdrawalAlertBanner(
              medicamento: _medicamentoSeleccionado,
              diasRestantes: diasRetiroActual,
              fechaFinRetiro: fechaFinRetiro,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _loteBiologicoController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Lote Biológico / Registro ICA',
                hintText: 'Ej. BIO-PPC-2026-08',
                prefixIcon: Icon(Icons.qr_code_2_rounded, color: AppColors.slateMuted),
                helperText: 'Requerido para trazabilidad sanitaria oficial ante el ICA.',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Ingrese el lote biológico del medicamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Dosis Administrada (ml)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 32,
                      color: AppColors.senaGreen,
                    ),
                    onPressed: () {
                      if (_dosisMl > 0.5) {
                        setState(() => _dosisMl = (_dosisMl - 0.5));
                      }
                    },
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _dosisMl.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slateDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ml',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.senaGreen,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 32,
                      color: AppColors.senaGreen,
                    ),
                    onPressed: () {
                      if (_dosisMl < 30.0) {
                        setState(() => _dosisMl = (_dosisMl + 0.5));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _viaAplicacion,
              decoration: const InputDecoration(
                labelText: 'Vía de Administración',
                prefixIcon: Icon(Icons.healing_outlined, color: AppColors.slateMuted),
              ),
              items: _viasAplicacion
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _viaAplicacion = val);
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _observacionesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observaciones Clínicas (Opcional)',
                hintText: 'Reacción del porcino o evolución clínica...',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.slateMuted),
              ),
            ),
            const SizedBox(height: 22),

            TactileButton(
              text: 'Registrar en Kárdex Sanitario',
              icon: Icons.save_rounded,
              isLoading: healthState.isLoading,
              onPressed: _handleGuardarSanidad,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKardexYRetirosTab(HealthState healthState) {
    return RefreshIndicator(
      color: AppColors.senaGreen,
      onRefresh: () => ref.read(healthNotifierProvider.notifier).loadSanidadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Alertas de Retiro Farmacológico Activas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.senaBlue,
            ),
          ),
          const SizedBox(height: 10),
          if (healthState.alertasRetiro.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No hay porcinos ni corrales con bloqueo sanitario por retiro activo.',
                style: TextStyle(fontSize: 13, color: AppColors.slateMuted),
              ),
            )
          else
            ...healthState.alertasRetiro.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.alertRedLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.alertRedBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.block_rounded,
                      color: AppColors.alertRedDark,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a.animalArete} • ${a.productoNombre}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.alertRedDark,
                            ),
                          ),
                          Text(
                            'Liberación sanitaria: ${DateFormat('dd/MM/yyyy').format(a.fechaFinRetiro)} (${a.diasRestantes} días restantes)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slateDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Historial Reciente de Tratamientos y Vacunas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.senaBlue,
            ),
          ),
          const SizedBox(height: 10),
          if (healthState.tratamientos.isEmpty)
            const Text(
              'Sin tratamientos registrados.',
              style: TextStyle(color: AppColors.slateMuted),
            )
          else
            ...healthState.tratamientos.take(15).map(
                  (t) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          t.tipo == 'vacuna'
                              ? Icons.vaccines_rounded
                              : Icons.medication_rounded,
                          color: AppColors.senaBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.medicamento,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slateDark,
                                ),
                              ),
                              Text(
                                '${t.tipo.toUpperCase()} • Dosis: ${t.dosisMl} ml • ${DateFormat('dd/MM/yyyy').format(t.fecha)}',
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
      ),
    );
  }

  Widget _buildBioseguridadTab(HealthState healthState) {
    return RefreshIndicator(
      color: AppColors.senaGreen,
      onRefresh: () => ref.read(healthNotifierProvider.notifier).loadSanidadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Checklist Diario de Bioseguridad ICA',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.senaBlue,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Marque los protocolos de desinfección, pediluvios y control de ingreso cumplidos durante la jornada.',
            style: TextStyle(fontSize: 12, color: AppColors.slateMuted),
          ),
          const SizedBox(height: 14),
          ...healthState.protocolos.map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: p.cumplidoHoy ? AppColors.mintBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: CheckboxListTile(
                activeColor: AppColors.senaGreen,
                value: p.cumplidoHoy,
                title: Text(
                  '${p.codigo} • ${p.tarea}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slateDark,
                  ),
                ),
                subtitle: Text(
                  '${p.descripcion} (${p.frecuencia})',
                  style: const TextStyle(fontSize: 12, color: AppColors.slateMuted),
                ),
                onChanged: (val) {
                  ref
                      .read(healthNotifierProvider.notifier)
                      .toggleProtocolo(p.id, val ?? false);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
