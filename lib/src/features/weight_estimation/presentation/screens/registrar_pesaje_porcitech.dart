import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/constants/zootechnical_constants.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/brand_mark.dart';
import 'package:porcitech_mobile/src/core/widgets/giant_numeric_keypad.dart';
import 'package:porcitech_mobile/src/core/widgets/porcino_picker_sheet.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/presentation/controllers/weight_controller.dart';

/// Pantalla: Registro de Pesaje Rápido (`registrar_pesaje_porcitech`).
/// Teclado numérico gigante para guantes, selector dinámico de ejemplar,
/// cálculo automático de GDP y sincronización con `/pesajes/manual`.
class RegistrarPesajePorcitech extends ConsumerStatefulWidget {
  final PorcinoEntity porcino;
  final double? initialWeight;
  final VoidCallback onOpenCapturaIa;
  final VoidCallback onPesajeGuardado;

  const RegistrarPesajePorcitech({
    super.key,
    required this.porcino,
    this.initialWeight,
    required this.onOpenCapturaIa,
    required this.onPesajeGuardado,
  });

  @override
  ConsumerState<RegistrarPesajePorcitech> createState() =>
      _RegistrarPesajePorcitechState();
}

class _RegistrarPesajePorcitechState
    extends ConsumerState<RegistrarPesajePorcitech> {
  late PorcinoEntity _porcino;
  late String _inputWeight;
  late double _pesoAnterior;
  late final DateTime _fechaAnterior;

  @override
  void initState() {
    super.initState();
    _porcino = widget.porcino;
    _inputWeight = widget.initialWeight != null
        ? widget.initialWeight!.toStringAsFixed(1)
        : '0';
    _pesoAnterior = _porcino.pesoActual;
    _fechaAnterior = DateTime.now().subtract(const Duration(days: 7));
  }

  Future<void> _cambiarPorcino() async {
    final picked = await PorcinoPickerSheet.show(
      context,
      title: 'Seleccionar Porcino para Pesaje',
      subtitle: 'Elija el ejemplar a pesar en báscula o cámara cenital IA',
    );
    if (picked != null && mounted) {
      setState(() {
        _porcino = picked;
        _pesoAnterior = picked.pesoActual;
      });
    }
  }

  void _onDigit(String d) {
    if (_inputWeight.length >= 6) return;
    if (d == '.' && _inputWeight.contains('.')) return;
    setState(() {
      if (_inputWeight == '0' && d != '.') {
        _inputWeight = d;
      } else {
        _inputWeight += d;
      }
    });
  }

  void _onDelete() {
    if (_inputWeight.isEmpty) return;
    setState(() {
      _inputWeight = _inputWeight.substring(0, _inputWeight.length - 1);
      if (_inputWeight.isEmpty) _inputWeight = '0';
    });
  }

  void _onClear() {
    setState(() => _inputWeight = '0');
  }

  double get _currentParsedWeight => double.tryParse(_inputWeight) ?? 0.0;

  double get _gdpCalculada {
    final w = _currentParsedWeight;
    if (w <= 0 || _pesoAnterior <= 0) return 0.0;
    return ZootechnicalConstants.calcularGdpGramosDia(
      pesoAnteriorKg: _pesoAnterior,
      pesoActualKg: w,
      fechaAnterior: _fechaAnterior,
      fechaActual: DateTime.now(),
    );
  }

  Future<void> _handleConfirmarPesaje() async {
    final pesoFinal = _currentParsedWeight;
    if (pesoFinal <= 1.0 || pesoFinal > 450.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un peso válido entre 1.0 kg y 450.0 kg'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    final success = await ref.read(weightNotifierProvider.notifier).registrarPesaje(
          porcinoId: _porcino.id,
          animalUuid: _porcino.uuid,
          corralUuid: _porcino.corralUuid,
          peso: pesoFinal,
          fecha: DateTime.now(),
          tipo: 'manual',
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pesaje de ${pesoFinal.toStringAsFixed(1)} kg guardado para ${_porcino.codigo}',
          ),
          backgroundColor: AppColors.senaGreen,
        ),
      );
      widget.onPesajeGuardado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightState = ref.watch(weightNotifierProvider);
    final gdp = _gdpCalculada;
    final clasificacion =
        ZootechnicalConstants.clasificarDesempenoGdp(gdp, _porcino.fase);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(compact: true),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pesaje • ${_porcino.codigo}',
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
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.senaGreen),
            tooltip: 'Estimar con Cámara IA',
            onPressed: widget.onOpenCapturaIa,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Ficha Rápida del Animal (táctil para cambiar animal) ---
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
                    const Icon(Icons.pets_rounded, color: AppColors.senaGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_porcino.codigo} • ${_porcino.raza} (${_porcino.loteNombre})',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slateDark,
                            ),
                          ),
                          Text(
                            'Último peso registrado: ${_pesoAnterior.toStringAsFixed(1)} kg • Fase ${_porcino.fase}',
                            style: const TextStyle(
                              fontSize: 12,
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
            ),
            const SizedBox(height: 16),

            // --- Pantalla Digital de Visualización de Peso Grande ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.senaGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.senaGreen.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'LECTURA DE BÁSCULA DIGITAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slateMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _inputWeight,
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slateDark,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.senaGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.mintBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.speed_rounded,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentParsedWeight > 0
                              ? 'GDP estimada: ${gdp >= 0 ? "+" : ""}${gdp.toInt()} g/día • $clasificacion'
                              : 'Digite el peso en kg o use la cámara cenital IA',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- TECLADO NUMÉRICO GIGANTE PARA GUANTES ---
            GiantNumericKeypad(
              allowDecimal: true,
              onDigitPressed: _onDigit,
              onDeletePressed: _onDelete,
              onClearPressed: _onClear,
            ),
            const SizedBox(height: 20),

            // --- BOTÓN CONFIRMAR PESAJE ---
            TactileButton(
              text: 'Confirmar y Guardar Pesaje',
              icon: Icons.save_rounded,
              isLoading: weightState.isLoading,
              onPressed: _handleConfirmarPesaje,
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              icon: const Icon(Icons.center_focus_strong_rounded, color: AppColors.senaBlue),
              label: const Text(
                'Estimar Peso con Cámara Cenital (Visión IA)',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.senaBlue),
              ),
              onPressed: widget.onOpenCapturaIa,
            ),
          ],
        ),
      ),
    );
  }
}
