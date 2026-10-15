import 'package:flutter/material.dart';

/// Paleta de colores oficial de PorciTech para aplicaciones de campo.
/// Diseñada con alto contraste para visibilidad bajo luz solar directa en corrales y galpones.
class AppColors {
  AppColors._();

  // --- Verdes Corporativos (Esmeralda) ---
  static const Color primary = Color(0xFF059669); // Esmeralda base
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color primaryBright = Color(0xFF16A34A);

  // --- Verde Azulado Secundario (Teal) ---
  static const Color secondary = Color(0xFF0F766E);
  static const Color secondaryLight = Color(0xFF14B8A6);

  // --- Verde Menta Suave (Fondos sutiles, tags activos, chips) ---
  static const Color mintSoft = Color(0xFFDCFCE7);
  static const Color mintBorder = Color(0xFF86EFAC);

  // --- Pizarra Oscura (Texto de alta legibilidad y superficies de contraste) ---
  static const Color slateDark = Color(0xFF0F172A);
  static const Color slateHeading = Color(0xFF1E293B);
  static const Color slateBody = Color(0xFF334155);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color slateBorder = Color(0xFFCBD5E1);

  // --- Fondos Limpios de Alto Contraste ---
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // --- Alertas Sanitarias y Retiro Farmacológico (Rojo Crítico) ---
  static const Color alertRed = Color(0xFFDC2626);
  static const Color alertRedDark = Color(0xFFB91C1C);
  static const Color alertRedLight = Color(0xFFFEE2E2);
  static const Color alertRedBorder = Color(0xFFFCA5A5);

  // --- Estados de Advertencia y Proceso (Ámbar / Naranja) ---
  static const Color warningOrange = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);

  // --- Estados de Éxito / Vacunación / Alta ---
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);

  // --- Gráficos y Curvas de Crecimiento ---
  static const Color chartLine = Color(0xFF059669);
  static const Color chartFill = Color(0x3310B981);
  static const Color chartStandardLine = Color(0xFF64748B);
}
