import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Componente oficial de identidad visual (`BrandMark`) homologado con `porcitech-nextjs`.
/// Muestra el escudo oficial del SENA y el logotipo tipográfico `PorciTech` con los colores
/// institucionales (`senaBlue: #00324D` / blanco en fondo oscuro y `senaGreen: #39A900`).
class BrandMark extends StatelessWidget {
  final bool light;
  final bool compact;
  final double? logoHeight;
  final double? fontSize;

  const BrandMark({
    super.key,
    this.light = false,
    this.compact = false,
    this.logoHeight,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final Color porciColor = light ? Colors.white : AppColors.senaBlue;
    const Color techColor = AppColors.senaGreen;

    if (compact) {
      final double effectiveLogoSize = logoHeight ?? 32.0;
      final double effectiveFontSize = fontSize ?? 20.0;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/SENA.png',
            height: effectiveLogoSize,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.verified_rounded,
              color: techColor,
              size: effectiveLogoSize,
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: effectiveFontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Porci',
                  style: TextStyle(color: porciColor),
                ),
                const TextSpan(
                  text: 'Tech',
                  style: TextStyle(color: techColor),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final double effectiveLogoHeight = logoHeight ?? 56.0;
    final double effectiveFontSize = fontSize ?? 30.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/SENA.png',
          height: effectiveLogoHeight,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.verified_rounded,
            color: techColor,
            size: effectiveLogoHeight,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
            children: [
              TextSpan(
                text: 'Porci',
                style: TextStyle(color: porciColor),
              ),
              const TextSpan(
                text: 'Tech',
                style: TextStyle(color: techColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
