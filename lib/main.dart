import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/di/core_providers.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/widgets/porcino_picker_sheet.dart';
import 'src/features/animals/domain/entities/porcino_entity.dart';
import 'src/features/animals/presentation/controllers/animals_controller.dart';
import 'src/features/animals/presentation/screens/detalle_porcino_4092_porcitech.dart';
import 'src/features/animals/presentation/screens/escaneo_qr_detalle_rapido.dart';
import 'src/features/animals/presentation/screens/listado_de_lotes_y_porcinos_porcitech.dart';
import 'src/features/auth/presentation/controllers/auth_controller.dart';
import 'src/features/auth/presentation/screens/inicio_de_sesion_porcitech.dart';
import 'src/features/dashboard/presentation/screens/dashboard_de_campo_porcitech.dart';
import 'src/features/feeding/presentation/screens/alimentacion_e_inventario_porcitech.dart';
import 'src/features/health_record/presentation/screens/registro_de_vacunacion_porcitech.dart';
import 'src/features/reproduction/presentation/screens/registro_de_parto_cerda_h_104.dart';
import 'src/features/sync/presentation/screens/ajustes_de_cuenta_porcitech.dart';
import 'src/features/weight_estimation/presentation/screens/captura_cenital_screen.dart';
import 'src/features/weight_estimation/presentation/screens/registrar_pesaje_porcitech.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloqueo de orientación vertical preferida para operarios en galpón
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicialización de persistencia local previa a la inyección
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const PorciTechApp(),
    ),
  );
}

/// Aplicación principal de PorciTech (Sistema Integral de Gestión Porcina SENA).
class PorciTechApp extends ConsumerWidget {
  const PorciTechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SENA • PorciTech Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RootNavigationCoordinator(),
    );
  }
}

/// Coordinador de navegación base reactivo al estado de autenticación.
class RootNavigationCoordinator extends ConsumerWidget {
  const RootNavigationCoordinator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isAuthenticated) {
      return const MainDashboardFlow();
    }

    return InicioDeSesionPorcitech(
      onLoginSuccess: () {
        // Redirige reactivamente mediante el cambio de estado de Riverpod
      },
    );
  }
}

/// Contenedor de flujo principal para las pantallas del ecosistema de campo.
class MainDashboardFlow extends ConsumerStatefulWidget {
  const MainDashboardFlow({super.key});

  @override
  ConsumerState<MainDashboardFlow> createState() => _MainDashboardFlowState();
}

class _MainDashboardFlowState extends ConsumerState<MainDashboardFlow> {
  PorcinoEntity? _activePorcino;

  PorcinoEntity _fallbackPorcino({bool female = false}) {
    final all = ref.read(animalsNotifierProvider).porcinos;
    if (female) {
      final sow = all.where((p) => p.sexo.toLowerCase() == 'hembra').firstOrNull;
      if (sow != null) return sow;
    }
    if (_activePorcino != null) return _activePorcino!;
    if (all.isNotEmpty) return all.first;
    return PorcinoEntity(
      id: 4092,
      codigo: female ? 'CERDA-H-104' : 'POR-4092',
      raza: female ? 'Landrace' : 'Landrace x Pietrain',
      sexo: female ? 'Hembra' : 'Macho',
      fechaNacimiento: DateTime.now().subtract(const Duration(days: 145)),
      loteId: 1,
      loteNombre: female ? 'Corral Gestación' : 'Corral Ceba',
      pesoActual: female ? 210.0 : 82.5,
      estadoSanitario: 'Sano',
      fase: female ? 'Gestación' : 'Ceba',
      gdpActualGramoDia: 820.0,
      diasEnFase: 65,
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _selectAndOpenPesaje() async {
    final picked = await PorcinoPickerSheet.show(
      context,
      title: 'Seleccionar Porcino para Pesaje',
      subtitle: 'Elija un ejemplar del hato o escanee su arete QR',
      onScanQr: _openScanner,
    );
    if (picked != null && mounted) {
      setState(() => _activePorcino = picked);
      _openPesajeScreen(picked);
    }
  }

  Future<void> _selectAndOpenSanidad() async {
    final picked = await PorcinoPickerSheet.show(
      context,
      title: 'Seleccionar Porcino para Sanidad',
      subtitle: 'Elija el animal para aplicar vacuna o consultar kárdex',
      onScanQr: _openScanner,
    );
    if (picked != null && mounted) {
      setState(() => _activePorcino = picked);
      _openSanidadScreen(picked);
    }
  }

  Future<void> _selectAndOpenReproduccion() async {
    final picked = await PorcinoPickerSheet.show(
      context,
      title: 'Seleccionar Hembra Reproductora',
      subtitle: 'Elija la cerda para registrar parto, servicio o destete',
      soloHembrasReproductoras: true,
      onScanQr: _openScanner,
    );
    if (picked != null && mounted) {
      setState(() => _activePorcino = picked);
      _openPartoScreen(picked);
    }
  }

  void _openScanner() {
    _navigateTo(
      EscaneoQrDetalleRapido(
        onOpenDetalleCompleto: (porcino) {
          setState(() => _activePorcino = porcino);
          _navigateTo(
            DetallePorcino4092Porcitech(
              porcino: porcino,
              onRegistrarPesaje: () => _openPesajeScreen(porcino),
              onRegistrarSanidad: () => _openSanidadScreen(porcino),
              onRegistrarParto: porcino.esHembraReproductora
                  ? () => _openPartoScreen(porcino)
                  : null,
            ),
          );
        },
        onOpenPesaje: _openPesajeScreen,
        onOpenSanidad: _openSanidadScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardDeCampoPorcitech(
      onScanQr: _openScanner,
      onOpenPesaje: _selectAndOpenPesaje,
      onOpenSanidad: _selectAndOpenSanidad,
      onOpenPartos: _selectAndOpenReproduccion,
      onOpenAlimentacion: () {
        _navigateTo(const AlimentacionEInventarioPorcitech());
      },
      onOpenLotes: () {
        _navigateTo(
          ListadoDeLotesYPorcinosPorcitech(
            onSelectPorcino: (p) {
              setState(() => _activePorcino = p);
              _navigateTo(
                DetallePorcino4092Porcitech(
                  porcino: p,
                  onRegistrarPesaje: () => _openPesajeScreen(p),
                  onRegistrarSanidad: () => _openSanidadScreen(p),
                  onRegistrarParto:
                      p.esHembraReproductora ? () => _openPartoScreen(p) : null,
                ),
              );
            },
          ),
        );
      },
      onOpenAjustes: () {
        _navigateTo(
          AjustesDeCuentaPorcitech(
            onLogout: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        );
      },
    );
  }

  void _openPesajeScreen(PorcinoEntity? porcino, {double? initialWeight}) {
    final target = porcino ?? _fallbackPorcino();
    _navigateTo(
      RegistrarPesajePorcitech(
        porcino: target,
        initialWeight: initialWeight,
        onOpenCapturaIa: () {
          _navigateTo(
            CapturaCenitalScreen(
              porcino: target,
              onPesoAplicado: (pesoEstimado) {
                ref.read(animalsNotifierProvider.notifier).fetchPorcinos();
                Navigator.of(context).pop();
                _openPesajeScreen(target, initialWeight: pesoEstimado);
              },
            ),
          );
        },
        onPesajeGuardado: () {
          ref.read(animalsNotifierProvider.notifier).fetchPorcinos();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openSanidadScreen(PorcinoEntity? porcino) {
    final target = porcino ?? _fallbackPorcino();
    _navigateTo(
      RegistroDeVacunacionPorcitech(
        porcino: target,
        onEventoGuardado: () {
          ref.read(animalsNotifierProvider.notifier).fetchPorcinos();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openPartoScreen(PorcinoEntity? sow) {
    final target = sow ?? _fallbackPorcino(female: true);
    _navigateTo(
      RegistroDePartoCerdaH104(
        cerda: target,
        onPartoGuardado: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
