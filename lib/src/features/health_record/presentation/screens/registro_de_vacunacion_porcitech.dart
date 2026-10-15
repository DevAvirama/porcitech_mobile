import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/constants/zootechnical_constants.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/core/widgets/withdrawal_alert_banner.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/health_record/presentation/controllers/health_controller.dart';

/// Pantalla: Registro de Sanidad y Vacunación (`registro_de_vacunacion_porcitech`).
/// Cumple estrictamente con normatividad ICA / INVIMA: exige Lote Biológico,
/// pastillas de medicamentos, dosis exacta y control automático del Tiempo de Retiro.
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
    extends ConsumerState<RegistroDeVacunacionPorcitech> {
  final _formKey = GlobalKey<FormState>();
  final _loteBiologicoController = TextEditingController(text: 'BIO-PPC-2026-08');
  final _observacionesController = TextEditingController(text: 'Sin reacción adversa post-aplicación.');

  String _tipoEvento = 'vacunacion';
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
  void dispose() {
    _loteBiologicoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  int get _diasRetiro {
    return ZootechnicalConstants.tiemposRetiroDias[_medicamentoSeleccionado] ?? 0;
  }

  Future<void> _handleGuardarSanidad() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(healthNotifierProvider.notifier).registrarEvento(
          porcinoId: widget.porcino.id,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aplicación de $_medicamentoSeleccionado registrada. Tiempo de retiro: $_diasRetiro días.'),
          backgroundColor: AppColors.primary,
        ),
      );
      widget.onEventoGuardado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthNotifierProvider);
    final diasRetiroActual = _diasRetiro;
    final fechaFinRetiro = DateTime.now().add(Duration(days: diasRetiroActual));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Sanidad • ${widget.porcino.codigo}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Cabecera del Porcino ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vaccines, color: AppColors.alertRedDark, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.porcino.codigo} • ${widget.porcino.loteNombre}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Peso: ${widget.porcino.pesoActual} kg • Fase: ${widget.porcino.fase}',
                            style: const TextStyle(fontSize: 12, color: AppColors.slateMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Pastillas de Selección Rápida de Medicamentos ---
              const Text(
                'Medicamento o Biológico ICA',
                style: TextStyle(
                  fontSize: 15,
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
                    selectedColor: retiro > 0 ? AppColors.alertRedDark : AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? (retiro > 0 ? AppColors.alertRedDark : AppColors.primary)
                          : AppColors.slateBorder,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _medicamentoSeleccionado = med;
                        _tipoEvento = med.contains('Vacuna') ? 'vacunacion' : 'tratamiento';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // --- Aviso Destacado de Tiempo de Retiro Sanitario ---
              WithdrawalAlertBanner(
                medicamento: _medicamentoSeleccionado,
                diasRestantes: diasRetiroActual,
                fechaFinRetiro: fechaFinRetiro,
              ),
              const SizedBox(height: 18),

              // --- Campo Obligatorio: Lote Biológico del Laboratorio ---
              const Text(
                'Lote Biológico / Registro Farmacéutico',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slateHeading,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _loteBiologicoController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'ej. BIO-PPC-2026-08',
                  prefixIcon: Icon(Icons.qr_code_scanner, color: AppColors.slateMuted),
                  helperText: 'Requerido para trazabilidad sanitaria oficial ante el ICA.',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El Lote Biológico es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Dosis (ml) con Selector Rápido ---
              const Text(
                'Dosis Administrada',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slateHeading,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.primary),
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
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slateDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ml',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
                      onPressed: () {
                        if (_dosisMl < 20.0) {
                          setState(() => _dosisMl = (_dosisMl + 0.5));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Vía de Aplicación ---
              const Text(
                'Vía de Aplicación',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slateHeading,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _viaAplicacion,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.healing_outlined, color: AppColors.slateMuted),
                ),
                items: _viasAplicacion
                    .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _viaAplicacion = val);
                },
              ),
              const SizedBox(height: 16),

              // --- Observaciones Clínicas ---
              const Text(
                'Observaciones Clínicas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slateHeading,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _observacionesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Reacción del porcino o condición física...',
                  prefixIcon: Icon(Icons.notes_rounded, color: AppColors.slateMuted),
                ),
              ),
              const SizedBox(height: 24),

              // --- Botón de 52px para Guardar ---
              TactileButton(
                text: 'Registrar en Kárdex y Descontar Insumo',
                icon: Icons.check_circle_outline,
                isLoading: healthState.isLoading,
                onPressed: _handleGuardarSanidad,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
