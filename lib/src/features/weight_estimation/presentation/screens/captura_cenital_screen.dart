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
/// Guías visuales en pantalla para operarios, compresión y preprocesamiento
/// antes del envío al microservicio YOLO / OpenCV.
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
        maxWidth: 1280, // Preprocesamiento: Reducción a resolución óptima YOLO
        maxHeight: 1280,
        imageQuality: 85, // Compresión de imagen para redes con latencia en campo
      );

      if (photo != null && mounted) {
        setState(() {
          _capturedImage = File(photo.path);
          _isProcessing = true;
          _iaResult = null;
        });

        final result = await ref.read(weightNotifierProvider.notifier).estimarConIa(
              porcinoId: widget.porcino.id,
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

  void _simularCapturaCenital() {
    setState(() {
      _isProcessing = true;
      _iaResult = null;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _iaResult = IaWeightEstimationResult(
          porcinoId: widget.porcino.id,
          pesoEstimado: 84.7,
          unidad: 'kg',
          metodo: 'ia_yolo_v8',
          fecha: DateTime.now(),
          confianzaIa: 0.95,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Captura Cenital • ${widget.porcino.codigo}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          // Vista previa o Guía Cenital
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
                    Icons.camera_indoor_outlined,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ],

          // Guías Visuales Cenitales (Silueta de lomo porcino)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CenitalGuidePainter(),
              ),
            ),
          ),

          // Banner de Instrucción Operativa para el Operario
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ubíquese sobre el corral. Mantenga el móvil paralelo al lomo del animal (altura ~1.2m).',
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

          // Modal de Resultado de la IA si ya se procesó
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
                          child: const Icon(Icons.auto_awesome, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PESO ESTIMADO (YOLO / OpenCV)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slateMuted,
                                ),
                              ),
                              Text(
                                '${_iaResult!.pesoEstimado} ${_iaResult!.unidad}',
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
                            'Confianza: ${((_iaResult!.confianzaIa ?? 0.94) * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TactileButton(
                      text: 'Aplicar Peso al Registro',
                      icon: Icons.check,
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

          // Indicador de Procesamiento
          if (_isProcessing) ...[
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Segmentando lomo porcino con IA...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Barra Inferior de Disparo
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
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                    tooltip: 'Galería',
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
                        color: AppColors.primary,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.model_training, color: Colors.white, size: 28),
                    tooltip: 'Simular IA YOLO',
                    onPressed: _simularCapturaCenital,
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
      ..color = AppColors.primaryLight.withValues(alpha: 0.8)
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
