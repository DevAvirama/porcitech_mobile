import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/domain/entities/weight_record_entity.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/presentation/controllers/weight_controller.dart';

/// Pantalla: Captura Fotográfica Cenital Top-Down (`captura_cenital_screen`).
/// Guías visuales en pantalla para operarios, compresión y envío al endpoint `/pesajes/ia`.
class CapturaCenitalScreen extends ConsumerStatefulWidget {
  final PorcinoEntity porcino;
  final void Function(double pesoEstimado) onPesoAplicado;

  const CapturaCenitalScreen({
    super.key,
    required this.porcino,
    required this.onPesoAplicado,
  });

  @override
  ConsumerState<CapturaCenitalScreen> createState() => _CapturaCenitalScreenState();
}

class _CapturaCenitalScreenState extends ConsumerState<CapturaCenitalScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  bool _isProcessing = false;
  IaWeightEstimationResult? _iaResult;

  Future<void> _captureOrPickPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        setState(() {
          _capturedImage = File(photo.path);
          _isProcessing = true;
          _iaResult = null;
        });

        final result = await ref.read(weightNotifierProvider.notifier).estimarConIa(
              porcinoId: widget.porcino.id,
              animalUuid: widget.porcino.uuid,
              corralUuid: widget.porcino.corralUuid,
              imageFile: _capturedImage!,
            );

        if (mounted) {
          setState(() {
            _isProcessing = false;
            _iaResult = result;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar fotografía: $e'),
            backgroundColor: AppColors.alertRedDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Captura Cenital IA • ${widget.porcino.codigo}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          if (_capturedImage != null) ...[
            Positioned.fill(
              child: Image.file(_capturedImage!, fit: BoxFit.cover),
            ),
          ] else ...[
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ],

          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CenitalGuidePainter(),
              ),
            ),
          ),

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.senaGreen),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.senaGreen, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ubíquese sobre el corral. Mantenga la cámara paralela al dorso del animal (~1.2 m de altura).',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_iaResult != null) ...[
            Positioned(
              left: 20,
              right: 20,
              bottom: 120,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            Icons.center_focus_strong_rounded,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PESO ESTIMADO POR VISIÓN IA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slateMuted,
                                ),
                              ),
                              Text(
                                '${_iaResult!.pesoEstimado.toStringAsFixed(1)} ${_iaResult!.unidad}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.slateDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Confianza: ${((_iaResult!.confianzaIa ?? 0.92) * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_iaResult!.largoCm != null || _iaResult!.anchoCm != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Biometría dorsal: Largo ${_iaResult!.largoCm?.toStringAsFixed(1) ?? "-"} cm • Ancho ${_iaResult!.anchoCm?.toStringAsFixed(1) ?? "-"} cm • Área ${_iaResult!.areaCm2?.toStringAsFixed(0) ?? "-"} cm²',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slateMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TactileButton(
                      text: 'Aplicar Peso Estimado al Registro',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        widget.onPesoAplicado(_iaResult!.pesoEstimado);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_isProcessing) ...[
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.senaGreen),
                    SizedBox(height: 16),
                    Text(
                      'Analizando contorno dorsal con Visión IA...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: Colors.black.withValues(alpha: 0.85),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Subir desde Galería',
                    onPressed: () => _captureOrPickPhoto(ImageSource.gallery),
                  ),
                  GestureDetector(
                    onTap: () => _captureOrPickPhoto(ImageSource.camera),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: AppColors.senaGreen,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Limpiar Captura',
                    onPressed: () {
                      setState(() {
                        _capturedImage = null;
                        _iaResult = null;
                      });
                    },
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

class _CenitalGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.senaGreen.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2 - 40);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.65,
      height: size.height * 0.52,
    );

    canvas.drawOval(rect, paint);

    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
