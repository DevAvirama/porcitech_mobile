import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/constants/zootechnical_constants.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/reproduction/presentation/controllers/reproduction_controller.dart';

/// Pantalla: Registro de Partos (`registro_de_parto_cerda_h_104`).
/// Exclusivo para hembras reproductoras. Contadores táctiles gigantes para guantes
/// ("Nacidos Vivos", "Nacidos Muertos", "Momias") y cálculo de peso promedio de camada.
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
    extends ConsumerState<RegistroDePartoCerdaH104> {
  int _nacidosVivos = 12;
  int _nacidosMuertos = 0;
  int _momias = 0;
  double _pesoCamadaKg = 16.2;
  final int _numeroParto = 3;
  final _observacionesController =
      TextEditingController(text: 'Parto normal, lechones vigorosos con reflejo de succión.');

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  int get _totalNacidos => _nacidosVivos + _nacidosMuertos + _momias;
  double get _pesoPromedioLechon =>
      _nacidosVivos > 0 ? (_pesoCamadaKg / _nacidosVivos) : 0.0;

  Future<void> _handleGuardarParto() async {
    if (!widget.cerda.esHembraReproductora && widget.cerda.sexo != 'Hembra') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error Zootécnico: Solo se puede registrar parto en hembras reproductoras.'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    if (_nacidosVivos <= 0 && _totalNacidos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El total de lechones no puede ser 0.'),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    final success = await ref.read(reproductionNotifierProvider.notifier).registrarParto(
          porcinoId: widget.cerda.id,
          fecha: DateTime.now(),
          nacidosVivos: _nacidosVivos,
          nacidosMuertos: _nacidosMuertos,
          momias: _momias,
          pesoTotalCamadaKg: _pesoCamadaKg,
          numeroParto: _numeroParto,
          observaciones: _observacionesController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Parto de ${widget.cerda.codigo} registrado exitosamente: $_nacidosVivos vivos (${_pesoCamadaKg}kg).',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      widget.onPartoGuardado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reproductionNotifierProvider);
    final bool cumpleMetaPorkcolombia = _nacidosVivos >= ZootechnicalConstants.metaNacidosVivos;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Registro Parto • ${widget.cerda.codigo}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Cabecera de la Cerda Reproductora ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.pregnant_woman,
                      color: Color(0xFF7E22CE),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.cerda.codigo} • ${widget.cerda.raza}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Parto #$_numeroParto • Galpón de Maternidad • ${widget.cerda.loteNombre}',
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
            ),
            const SizedBox(height: 16),

            // --- Panel de Resumen de Camada ---
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
                  _buildSummaryItem('Promedio/Lechón', '${_pesoPromedioLechon.toStringAsFixed(2)} kg'),
                  _buildSummaryItem('Meta Porkcolombia', '≥12 vivos'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- CONTADORES TÁCTILES GIGANTES (+ y -) ---
            const Text(
              'Conteo Biológico de Lechones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 12),

            // Contador 1: Nacidos Vivos
            _buildTactileCounter(
              title: 'Nacidos Vivos',
              subtitle: 'Lechones viables y activos',
              count: _nacidosVivos,
              color: AppColors.primary,
              bgColor: AppColors.mintSoft,
              onDecrement: () {
                if (_nacidosVivos > 0) setState(() => _nacidosVivos--);
              },
              onIncrement: () => setState(() => _nacidosVivos++),
            ),
            const SizedBox(height: 12),

            // Contador 2: Nacidos Muertos
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
            const SizedBox(height: 12),

            // Contador 3: Momias
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
            const SizedBox(height: 20),

            // --- Peso Total de la Camada ---
            const Text(
              'Biometría de la Camada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 8),
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slateHeading),
                      ),
                      Text(
                        '${_pesoCamadaKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      value: _pesoCamadaKg,
                      min: 3.0,
                      max: 30.0,
                      divisions: 54,
                      label: '${_pesoCamadaKg.toStringAsFixed(1)} kg',
                      onChanged: (val) => setState(() => _pesoCamadaKg = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Observaciones de Parto ---
            const Text(
              'Observaciones del Zootecnista / Operario',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slateHeading,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _observacionesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'ej. Lechones vigorosos, encalostramiento completado...',
                prefixIcon: Icon(Icons.notes, color: AppColors.slateMuted),
              ),
            ),
            const SizedBox(height: 24),

            // --- Botón Guardar Parto ---
            TactileButton(
              text: 'Confirmar y Guardar Registro de Parto',
              icon: Icons.check_circle_outline,
              isLoading: state.isLoading,
              onPressed: _handleGuardarParto,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.slateMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slateDark),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slateDark),
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
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 26,
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
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
