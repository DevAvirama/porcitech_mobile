import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/constants/zootechnical_constants.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/giant_numeric_keypad.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/presentation/controllers/weight_controller.dart';

/// Pantalla: Registro de Pesaje Rápido (`registrar_pesaje_porcitech`).
/// Teclado numérico gigante para guantes, cálculo automático de GDP (+820 g/día)
/// frente a estándares de Porkcolombia y confirmación veloz en corral.
class RegistrarPesajePorcitech extends ConsumerStatefulWidget {
  final PorcinoEntity porcino;
  final VoidCallback onOpenCapturaIa;
  final VoidCallback onPesajeGuardado;

  const RegistrarPesajePorcitech({
    super.key,
    required this.porcino,
    required this.onOpenCapturaIa,
    required this.onPesajeGuardado,
  });

  @override
  ConsumerState<RegistrarPesajePorcitech> createState() =>
      _RegistrarPesajePorcitechState();
}

class _RegistrarPesajePorcitechState
    extends ConsumerState<RegistrarPesajePorcitech> {
  String _inputWeight = '82.5';
  late final double _pesoAnterior;
  late final DateTime _fechaAnterior;

  @override
  void initState() {
    super.initState();
    _pesoAnterior = widget.porcino.pesoActual > 10.0
        ? widget.porcino.pesoActual - 8.2
        : widget.porcino.pesoActual;
    _fechaAnterior = DateTime.now().subtract(const Duration(days: 10));
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
    if (w <= 0) return 0.0;
    return ZootechnicalConstants.calcularGdpGramosDia(
      pesoAnteriorKg: _pesoAnterior,
      pesoActualKg: w,
      fechaAnterior: _fechaAnterior,
      fechaActual: DateTime.now(),
    );
  }

  Future<void> _handleConfirmarPesaje() async {
    final pesoFinal = _currentParsedWeight;
    if (pesoFinal <= 2.0 || pesoFinal > 450.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un peso válido entre 2.0 kg y 450.0 kg'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    final success = await ref.read(weightNotifierProvider.notifier).registrarPesaje(
          porcinoId: widget.porcino.id,
          peso: pesoFinal,
          fecha: DateTime.now(),
          tipo: 'manual',
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesaje de ${pesoFinal.toStringAsFixed(1)} kg guardado para ${widget.porcino.codigo}'),
          backgroundColor: AppColors.primary,
        ),
      );
      widget.onPesajeGuardado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightState = ref.watch(weightNotifierProvider);
    final gdp = _gdpCalculada;
    final clasificacion = ZootechnicalConstants.clasificarDesempenoGdp(gdp, widget.porcino.fase);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pesaje ${widget.porcino.codigo}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
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
            // --- Ficha Rápida del Animal ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pets, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.porcino.codigo} • ${widget.porcino.raza}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Peso Anterior: ${_pesoAnterior.toStringAsFixed(1)} kg hace 10 días (${widget.porcino.fase})',
                          style: const TextStyle(fontSize: 12, color: AppColors.slateMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Pantalla Digital de Visualización de Peso Grande ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'PESO EN BÁSCULA',
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
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // --- Cálculo Automático de GDP en Vivo ---
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
                        const Icon(Icons.speed_rounded, size: 18, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text(
                          'GDP: ${gdp > 0 ? "+" : ""}${gdp.toInt()} g/día • $clasificacion',
                          style: const TextStyle(
                            fontSize: 13,
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
              icon: Icons.check_circle_outline_rounded,
              isLoading: weightState.isLoading,
              onPressed: _handleConfirmarPesaje,
            ),
            const SizedBox(height: 10),

            // Acceso Alternativo a Visión IA
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome, color: AppColors.secondary),
              label: const Text(
                'Usar Estimación por Visión Artificial (YOLO)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: widget.onOpenCapturaIa,
            ),
          ],
        ),
      ),
    );
  }
}
