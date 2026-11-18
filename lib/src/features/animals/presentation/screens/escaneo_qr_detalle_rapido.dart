import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/utils/camera_permission_helper.dart';
import 'package:porcitech_mobile/src/core/widgets/status_badge.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/animals/presentation/controllers/animals_controller.dart';

/// Pantalla: Escaneo QR / RFID y Ficha Rápida (`escaneo_qr_detalle_rapido`).
/// Visor de cámara con marco verde esmeralda y Slide-Up Sheet con expediente emergente.
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
  bool _hasCameraPermission = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAndStartCamera();
    });
  }

  Future<void> _requestAndStartCamera() async {
    if (!mounted) return;
    setState(() => _checkingPermission = true);
    final granted = await ensureCameraPermission(context);
    if (!mounted) return;
    setState(() {
      _hasCameraPermission = granted;
      _checkingPermission = false;
    });
    if (granted) {
      await _scannerController.start();
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  /// Las chapetas impresas codifican la URL del pasaporte público
  /// (ej. http://host:3000/trace/QR-2024-002). Se extrae solo el código final.
  static String _extractQrCode(String raw) {
    var code = raw.trim();
    final traceIdx = code.indexOf('/trace/');
    if (traceIdx >= 0) {
      code = code.substring(traceIdx + '/trace/'.length);
    } else if (code.startsWith('http://') || code.startsWith('https://')) {
      final uri = Uri.tryParse(code);
      final segments = uri?.pathSegments.where((s) => s.isNotEmpty).toList() ?? [];
      if (segments.isNotEmpty) code = segments.last;
    }
    code = code.split('?').first.split('#').first.replaceAll('/', '').trim();
    try {
      return Uri.decodeComponent(code);
    } catch (_) {
      return code;
    }
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    if (_isProcessingCode) return;
    setState(() => _isProcessingCode = true);

    final repository = ref.read(animalsRepositoryProvider);
    final result = await repository.getPorcinoByQr(_extractQrCode(rawCode));

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
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ingreso Manual de Arete', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej. POR-4092 o CERDA-H-104',
            prefixIcon: Icon(Icons.qr_code_2_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              _handleBarcodeDetected(text);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _showSlideUpSheet(PorcinoEntity porcino) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.slateBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryDark, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            porcino.codigo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slateDark,
                            ),
                          ),
                          StatusBadge.fromStatus(porcino.estadoSanitario),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${porcino.raza} • ${porcino.sexo} • ${porcino.loteNombre}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.slateMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSheetMetric('Peso Actual', '${porcino.pesoActual} kg'),
                _buildSheetMetric('GDP', '+${porcino.gdpActualGramoDia.toInt()} g/d'),
                _buildSheetMetric('Fase', porcino.fase),
                _buildSheetMetric('Edad', '${porcino.edadEnDias} d'),
              ],
            ),
            const SizedBox(height: 20),
            TactileButton(
              text: 'Ver Expediente Completo',
              icon: Icons.folder_open_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                widget.onOpenDetalleCompleto(porcino);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TactileButton(
                    text: 'Pesaje',
                    icon: Icons.scale_rounded,
                    type: TactileButtonType.secondary,
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onOpenPesaje(porcino);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TactileButton(
                    text: 'Sanidad',
                    icon: Icons.vaccines_rounded,
                    type: TactileButtonType.outline,
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onOpenSanidad(porcino);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.slateMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slateDark),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        title: const Text('Identificación QR / Arete'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            tooltip: 'Linterna',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
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
          if (_hasCameraPermission)
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
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _checkingPermission
                          ? Icons.camera_alt_outlined
                          : Icons.no_photography_outlined,
                      color: AppColors.senaGreen,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _checkingPermission
                          ? 'Solicitando acceso a la cámara...'
                          : 'Se requiere permiso de cámara para escanear códigos QR.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!_checkingPermission) ...[
                      const SizedBox(height: 16),
                      TactileButton(
                        text: 'Permitir Cámara',
                        icon: Icons.camera_alt_rounded,
                        onPressed: _requestAndStartCamera,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (_hasCameraPermission)
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
                                  color: AppColors.primaryLight.withValues(alpha: 0.8),
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
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slateMuted.withValues(alpha: 0.5)),
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
                    text: 'Ingresar Código de Arete Manualmente',
                    icon: Icons.keyboard_alt_outlined,
                    type: TactileButtonType.secondary,
                    onPressed: _showManualEntryDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
