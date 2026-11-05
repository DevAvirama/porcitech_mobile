import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/animals/presentation/controllers/animals_controller.dart';

/// Pantalla: Escaneo QR / RFID y Ficha Rápida (`escaneo_qr_detalle_rapido`).
class EscaneoQrDetalleRapido extends ConsumerStatefulWidget {
  final void Function(PorcinoEntity porcino) onOpenDetalleCompleto;
  final void Function(PorcinoEntity porcino) onOpenPesaje;
  final void Function(PorcinoEntity porcino) onOpenSanidad;

  const EscaneoQrDetalleRapido({
    super.key,
    required this.onOpenDetalleCompleto,
    required this.onOpenPesaje,
    required this.onOpenSanidad,
  });

  @override
  ConsumerState<EscaneoQrDetalleRapido> createState() =>
      _EscaneoQrDetalleRapidoState();
}

class _EscaneoQrDetalleRapidoState extends ConsumerState<EscaneoQrDetalleRapido>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _laserController;
  bool _isProcessingCode = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    if (_isProcessingCode) return;
    setState(() => _isProcessingCode = true);

    final repository = ref.read(animalsRepositoryProvider);
    final result = await repository.getPorcinoByQr(rawCode);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.alertRedDark,
            ),
          );
          setState(() => _isProcessingCode = false);
        }
      },
      (porcino) async {
        if (mounted) {
          await _showSlideUpSheet(porcino);
          if (mounted) {
            setState(() => _isProcessingCode = false);
          }
        }
      },
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController(text: 'POR-4092');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ingreso Manual de Arete',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ej. POR-4092 o CERDA-H-104',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleBarcodeDetected(controller.text.trim());
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSlideUpSheet(PorcinoEntity porcino) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle superior
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Encabezado e Insignia del Lote
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.loyalty,
                          color: AppColors.primaryDark,
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
                                  'Porcino #${porcino.id}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slateDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const CircleAvatar(
                                  radius: 4,
                                  backgroundColor: AppColors.primary,
                                ),
                              ],
                            ),
                            Text(
                              'ID Electrónico: ${porcino.codigo}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slateMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAEAD6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    porcino.loteNombre.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF042014),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjetas de Métricas Rápidas (Peso Actual y Edad)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'PESO ACTUAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slateMuted,
                              ),
                            ),
                            Icon(Icons.scale,
                                size: 16, color: AppColors.slateMuted),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${porcino.pesoActual}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slateDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'kg',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slateMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.trending_up,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '+${porcino.gdpActualGramoDia.toInt()} g/día',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'EDAD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slateMuted,
                              ),
                            ),
                            Icon(Icons.calendar_today,
                                size: 16, color: AppColors.slateMuted),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${(porcino.edadEnDias / 7).round()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slateDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'sem',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slateMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.event_repeat,
                                size: 14, color: AppColors.slateMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Fase ${porcino.fase}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slateMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Botón 1: Registrar Peso
            TactileButton(
              text: 'Registrar Peso',
              icon: Icons.scale_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                widget.onOpenPesaje(porcino);
              },
            ),
            const SizedBox(height: 10),

            // Botón 2: Aplicar Vacuna
            TactileButton(
              text: 'Aplicar Vacuna',
              icon: Icons.vaccines_rounded,
              type: TactileButtonType.secondary,
              onPressed: () {
                Navigator.pop(ctx);
                widget.onOpenSanidad(porcino);
              },
            ),
            const SizedBox(height: 8),

            // Botón 3: Expediente Completo
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onOpenDetalleCompleto(porcino);
              },
              icon: const Icon(Icons.folder_open_rounded,
                  size: 18, color: AppColors.slateMuted),
              label: const Text(
                'Ver Expediente Completo',
                style: TextStyle(
                  color: AppColors.slateMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Ubicación del galpón
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.domain, size: 14, color: AppColors.slateMuted),
                const SizedBox(width: 6),
                Text(
                  '${porcino.loteNombre} • Densidad Óptima',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slateMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Identificación QR / Arete',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            tooltip: 'Linterna',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon:
                const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'Cambiar Cámara',
            onPressed: () => _scannerController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white),
            tooltip: 'Entrada Manual',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final val = barcode.rawValue;
                if (val != null && val.isNotEmpty) {
                  _handleBarcodeDetected(val);
                  break;
                }
              }
            },
          ),
          Center(
            child: SizedBox(
              width: 270,
              height: 270,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, child) {
                      return Positioned(
                        top: 270 * _laserController.value,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.slateMuted.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'Enfoque el código QR del arete del porcino o use el teclado superior si el arete está sucio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TactileButton(
                  text: 'Simular Detección Arete POR-4092',
                  icon: Icons.qr_code,
                  type: TactileButtonType.secondary,
                  onPressed: () => _handleBarcodeDetected('POR-4092'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}