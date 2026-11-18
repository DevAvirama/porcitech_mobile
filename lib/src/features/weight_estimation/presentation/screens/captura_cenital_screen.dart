import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/utils/camera_permission_helper.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/animals/domain/entities/porcino_entity.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/domain/entities/weight_record_entity.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/presentation/controllers/weight_controller.dart';

/// Pantalla integrada de cálculo de peso por fotografía en tiempo real (`captura_cenital_screen`).
/// Abre la cámara directamente dentro de la aplicación y admite tomas desde cualquier ángulo
/// (automático, superior, lateral u oblicuo 3/4).
class CapturaCenitalScreen extends ConsumerStatefulWidget {
  final PorcinoEntity porcino;
  final void Function(double pesoEstimado) onPesoAplicado;

  const CapturaCenitalScreen({
    super.key,
    required this.porcino,
    required this.onPesoAplicado,
  });

  @override
  ConsumerState<CapturaCenitalScreen> createState() =>
      _CapturaCenitalScreenState();
}

class _CapturaCenitalScreenState extends ConsumerState<CapturaCenitalScreen>
    with WidgetsBindingObserver {
  final ImagePicker _galleryPicker = ImagePicker();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  bool _isInitializingCamera = true;
  String? _cameraError;
  bool _isCapturing = false;
  bool _isProcessing = false;

  File? _capturedImage;
  IaWeightEstimationResult? _estimationResult;
  String _selectedAngle = 'auto';

  static const List<({String id, String label})> _angleOptions = [
    (id: 'auto', label: 'Libre (Auto)'),
    (id: 'lateral', label: 'Lateral'),
    (id: 'oblicuo', label: '3/4 Oblicuo'),
    (id: 'cenital', label: 'Superior'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEmbeddedCamera();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCameraController();
    } else if (state == AppLifecycleState.resumed && _capturedImage == null) {
      _initializeEmbeddedCamera();
    }
  }

  Future<void> _disposeCameraController() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _initializeEmbeddedCamera({int? cameraIndex}) async {
    if (!mounted) return;
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    final granted = await ensureCameraPermission(context);
    if (!granted) {
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
          _cameraError =
              'Se requiere permiso de cámara para tomar la fotografía en galpón.';
        });
      }
      return;
    }

    try {
      final available = _cameras.isNotEmpty
          ? _cameras
          : await availableCameras();
      if (available.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializingCamera = false;
            _cameraError = 'No se detectó ninguna cámara disponible en este equipo.';
          });
        }
        return;
      }

      _cameras = available;
      if (cameraIndex != null &&
          cameraIndex >= 0 &&
          cameraIndex < _cameras.length) {
        _selectedCameraIndex = cameraIndex;
      } else {
        final backIdx = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backIdx >= 0 ? backIdx : 0;
      }

      await _disposeCameraController();

      final controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializingCamera = false;
        _cameraError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
          _cameraError = 'No fue posible iniciar la cámara integrada: $e';
        });
      }
    }
  }

  Future<void> _captureLivePhoto() async {
    final controller = _cameraController;
    if (_isCapturing ||
        _isProcessing ||
        controller == null ||
        !controller.value.isInitialized) {
      if (controller == null && !_isInitializingCamera) {
        await _initializeEmbeddedCamera();
      }
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final XFile photo = await controller.takePicture();
      if (!mounted) return;
      await _analyzeImageFile(File(photo.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar fotografía: $e'),
            backgroundColor: AppColors.alertRedDark,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isProcessing) return;
    try {
      final XFile? photo = await _galleryPicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (photo != null && mounted) {
        await _analyzeImageFile(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.alertRedDark,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImageFile(File imageFile) async {
    setState(() {
      _capturedImage = imageFile;
      _isProcessing = true;
      _estimationResult = null;
    });

    final result = await ref.read(weightNotifierProvider.notifier).estimarConIa(
          porcinoId: widget.porcino.id,
          animalUuid: widget.porcino.uuid,
          corralUuid: widget.porcino.corralUuid,
          imageFile: imageFile,
          persistir: false,
          anguloVista: _selectedAngle,
        );

    if (!mounted) return;

    if (result == null) {
      final errMsg = ref.read(weightNotifierProvider).errorMessage ??
          'No se pudo detectar el ejemplar en la fotografía. Intente nuevamente.';
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.alertRedDark,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = false;
      _estimationResult = result;
    });
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.torch,
      _ => FlashMode.off,
    };
    try {
      await controller.setFlashMode(nextMode);
      if (mounted) setState(() => _flashMode = nextMode);
    } catch (_) {
      // Algunas cámaras frontales no soportan flash
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializingCamera) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeEmbeddedCamera(cameraIndex: nextIndex);
  }

  Future<void> _onTapFocus(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final offset = Offset(
      (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
      (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
    );
    try {
      await controller.setFocusPoint(offset);
      await controller.setExposurePoint(offset);
    } catch (_) {}
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _estimationResult = null;
      _isProcessing = false;
    });
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _initializeEmbeddedCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  String _angleDisplayName(String? raw) {
    return switch ((raw ?? _selectedAngle).toLowerCase()) {
      'cenital' => 'Vista superior',
      'lateral' => 'Vista lateral',
      'oblicuo' => 'Vista 3/4 oblicua',
      _ => 'Detección automática',
    };
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
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        title: Text('Pesaje por Cámara • ${widget.porcino.codigo}'),
        actions: [
          if (_capturedImage == null &&
              _cameraController != null &&
              _cameraController!.value.isInitialized) ...[
            IconButton(
              icon: Icon(
                switch (_flashMode) {
                  FlashMode.torch => Icons.flash_on_rounded,
                  FlashMode.auto => Icons.flash_auto_rounded,
                  _ => Icons.flash_off_rounded,
                },
                color: _flashMode == FlashMode.torch
                    ? AppColors.senaYellow
                    : Colors.white,
              ),
              tooltip: 'Flash',
              onPressed: _toggleFlash,
            ),
            if (_cameras.length > 1)
              IconButton(
                icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                tooltip: 'Cambiar cámara',
                onPressed: _switchCamera,
              ),
          ],
        ],
      ),
      bottomNavigationBar: _buildCaptureControls(),
      body: Stack(
        children: [
          // 1. Vista principal: foto capturada/anotada o cámara en vivo integrada
          Positioned.fill(
            child: _buildCameraOrPhotoLayer(),
          ),

          // 2. Guías de encuadre universal (válidas para cualquier ángulo)
          if (_capturedImage == null &&
              _cameraController != null &&
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AnyAngleFramePainter(),
                ),
              ),
            ),

          // 3. Selector rápido de ángulo + instrucción clara sin jerga técnica
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.senaGreen.withValues(alpha: 0.8),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.photo_camera_rounded,
                        color: AppColors.senaGreen,
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Enfoca al cerdo completo desde cualquier ángulo (superior, lateral o 3/4). Sin señal, la foto queda guardada para sincronizar.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _angleOptions.map((opt) {
                      final selected = _selectedAngle == opt.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : Colors.white70,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppColors.senaGreen,
                          backgroundColor: Colors.black.withValues(alpha: 0.65),
                          side: BorderSide(
                            color: selected
                                ? AppColors.senaGreen
                                : Colors.white24,
                          ),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          onSelected: _isProcessing
                              ? null
                              : (_) => setState(() => _selectedAngle = opt.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 4. Tarjeta de resultado
          if (_estimationResult != null) _buildResultCard(_estimationResult!),

          // 5. Indicador de procesamiento
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.62),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.senaGreen),
                    SizedBox(height: 16),
                    Text(
                      'Calculando peso estimado del ejemplar...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

  Widget _buildCameraOrPhotoLayer() {
    if (_capturedImage != null) {
      final annotatedB64 = _estimationResult?.imagenAnotadaBase64;
      if (annotatedB64 != null && annotatedB64.contains(',')) {
        try {
          final bytes = base64Decode(annotatedB64.split(',').last);
          return Image.memory(bytes, fit: BoxFit.contain);
        } catch (_) {}
      }
      return Image.file(_capturedImage!, fit: BoxFit.contain);
    }

    if (_isInitializingCamera) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.senaGreen),
            SizedBox(height: 14),
            Text(
              'Iniciando cámara en vivo...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                size: 56,
                color: Colors.white54,
              ),
              const SizedBox(height: 12),
              Text(
                _cameraError ?? 'La cámara no está activa.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _initializeEmbeddedCamera(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.senaGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Activar cámara'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _onTapFocus(details, constraints),
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth * controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(IaWeightEstimationResult result) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: result.metodo == 'cola_offline'
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.warningOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FOTOGRAFÍA GUARDADA EN DISPOSITIVO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warningOrange,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Encolada para calcular al reconectar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slateDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TactileButton(
                    text: 'Aceptar y Continuar en Galpón',
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icons.monitor_weight_rounded,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PESO ESTIMADO • ${_angleDisplayName(result.anguloVista).toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slateMuted,
                              ),
                            ),
                            Text(
                              '${result.pesoEstimado.toStringAsFixed(1)} ${result.unidad}',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Confianza: ${((result.confianzaIa ?? 0.92) * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (result.largoCm != null || result.anchoCm != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Dimensiones: Largo ${result.largoCm?.toStringAsFixed(1) ?? "-"} cm • Ancho ${result.anchoCm?.toStringAsFixed(1) ?? "-"} cm',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TactileButton(
                    text: 'Aplicar Peso Estimado al Registro',
                    icon: Icons.check_rounded,
                    onPressed: () =>
                        widget.onPesoAplicado(result.pesoEstimado),
                  ),
                ],
              ),
      ),
    );
  }

  /// Barra de captura ubicada debajo del visor y protegida por SafeArea.
  Widget _buildCaptureControls() {
    final canCapture = !_isCapturing && !_isProcessing;
    return Container(
      color: Colors.black,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 10, 24, 12),
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
              onPressed: canCapture ? _pickFromGallery : null,
            ),
            GestureDetector(
              onTap: !canCapture
                  ? null
                  : (_capturedImage != null ? _retakePhoto : _captureLivePhoto),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: _capturedImage != null
                      ? AppColors.senaBlue
                      : AppColors.senaGreen,
                ),
                child: _isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        _capturedImage != null
                            ? Icons.replay_rounded
                            : Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 28,
              ),
              tooltip: 'Reiniciar Cámara',
              onPressed: canCapture ? _retakePhoto : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Marco esquineras neutro válido para captura cenital, lateral o 3/4.
class _AnyAngleFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.senaGreen.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final left = size.width * 0.10;
    final right = size.width * 0.90;
    final top = size.height * 0.24;
    final bottom = size.height * 0.84;
    const corner = 26.0;

    // Esquina superior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(left, top + corner)
        ..lineTo(left, top)
        ..lineTo(left + corner, top),
      paint,
    );
    // Esquina superior derecha
    canvas.drawPath(
      Path()
        ..moveTo(right - corner, top)
        ..lineTo(right, top)
        ..lineTo(right, top + corner),
      paint,
    );
    // Esquina inferior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - corner)
        ..lineTo(left, bottom)
        ..lineTo(left + corner, bottom),
      paint,
    );
    // Esquina inferior derecha
    canvas.drawPath(
      Path()
        ..moveTo(right - corner, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
