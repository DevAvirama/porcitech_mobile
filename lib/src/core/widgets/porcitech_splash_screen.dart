import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Pantalla animada de entrada (`PorciTechSplashScreen`).
/// Presenta el logotipo oficial de PorciTech en el centro con una transición
/// suave hacia la aplicación sin pantalla blanca previa.
class PorciTechSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration displayDuration;

  const PorciTechSplashScreen({
    super.key,
    required this.onComplete,
    this.displayDuration = const Duration(milliseconds: 1900),
  });

  @override
  State<PorciTechSplashScreen> createState() => _PorciTechSplashScreenState();
}

class _PorciTechSplashScreenState extends State<PorciTechSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _progressValue;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: widget.displayDuration,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_entranceController);

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.28, 0.65, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    _progressValue = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.96, curve: Curves.easeInOutCubic),
    );

    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed && mounted) {
        _completed = true;
        widget.onComplete();
      }
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF020617),
              Color(0xFF002235),
              Color(0xFF00324D),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Resplandor ambiental esmeralda superior izquierdo
            Positioned(
              top: -90,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.senaGreen.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Resplandor ambiental dorado SENA inferior derecho
            Positioned(
              bottom: -100,
              right: -70,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.senaYellow.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Contenido central con logotipo PorciTech
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _entranceController,
                        _pulseController,
                      ]),
                      builder: (context, child) {
                        final pulse = _pulseController.value;
                        final ringScale = 1.0 + (pulse * 0.34);
                        final ringOpacity = (1.0 - pulse) * 0.45 * _logoFade.value;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: ringScale,
                              child: Opacity(
                                opacity: ringOpacity.clamp(0.0, 1.0),
                                child: Container(
                                  width: 158,
                                  height: 158,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(42),
                                    border: Border.all(
                                      color: AppColors.senaGreen,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: child,
                              ),
                            ),
                          ],
                        );
                      },
                      child: Container(
                        width: 144,
                        height: 144,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.senaGreen.withValues(alpha: 0.28),
                              blurRadius: 34,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Image.asset(
                            'assets/images/porcitech_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.senaBlue,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.pets_rounded,
                                size: 64,
                                color: AppColors.senaGreen,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              'GESTIÓN PORCINA INTELIGENTE',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                                color: const Color(0xFF6EE7B7),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Terminal de Campo SENA',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _textFade,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: AnimatedBuilder(
                                  animation: _progressValue,
                                  builder: (context, _) {
                                    return LinearProgressIndicator(
                                      value: _progressValue.value,
                                      minHeight: 4,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.14),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.senaGreen,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/SENA.png',
                                  height: 18,
                                  errorBuilder: (_, _, _) => const SizedBox(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'INNOVACIÓN AGROPECUARIA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                    color: Colors.white.withValues(alpha: 0.55),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
