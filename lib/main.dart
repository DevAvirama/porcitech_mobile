import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/di/core_providers.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/animals/domain/entities/porcino_entity.dart';
import 'src/features/animals/presentation/controllers/animals_controller.dart';
import 'src/features/animals/presentation/screens/detalle_porcino_4092_porcitech.dart';
import 'src/features/animals/presentation/screens/escaneo_qr_detalle_rapido.dart';
import 'src/features/animals/presentation/screens/listado_de_lotes_y_porcinos_porcitech.dart';
import 'src/features/auth/presentation/controllers/auth_controller.dart';
import 'src/features/auth/presentation/screens/inicio_de_sesion_porcitech.dart';
import 'src/features/dashboard/presentation/screens/dashboard_de_campo_porcitech.dart';
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

/// Aplicación principal de PorciTech (Sistema Integral Porcino).
class PorciTechApp extends ConsumerWidget {
  const PorciTechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PorciTech Mobile',
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
  // Porcino por defecto para accesos directos desde el Dashboard
  PorcinoEntity _activePorcino = PorcinoEntity(
    id: 4092,
    codigo: 'POR-4092',
    raza: 'Landrace x Pietrain',
    sexo: 'Macho Castrado',
    fechaNacimiento: DateTime.now().subtract(const Duration(days: 145)),
    loteId: 3,
    loteNombre: 'Lote Ceba 03',
    pesoActual: 82.5,
    estadoSanitario: 'Sano',
    fase: 'Ceba',
    gdpActualGramoDia: 820.0,
    diasEnFase: 65,
  );

  final PorcinoEntity _cerdaReproductora = PorcinoEntity(
    id: 104,
    codigo: 'CERDA-H-104',
    raza: 'Landrace Puro',
    sexo: 'Hembra',
    fechaNacimiento: DateTime.now().subtract(const Duration(days: 480)),
    loteId: 1,
    loteNombre: 'Lote Reproductoras A',
    pesoActual: 215.0,
    estadoSanitario: 'Sana',
    fase: 'Gestación',
    gdpActualGramoDia: 380.0,
    diasEnFase: 110,
  );

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardDeCampoPorcitech(
      onScanQr: () {
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
      },
      onOpenPesaje: () => _openPesajeScreen(_activePorcino),
      onOpenSanidad: () => _openSanidadScreen(_activePorcino),
      onOpenPartos: () => _openPartoScreen(_cerdaReproductora),
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

  void _openPesajeScreen(PorcinoEntity porcino) {
    _navigateTo(
      RegistrarPesajePorcitech(
        porcino: porcino,
        onOpenCapturaIa: () {
          _navigateTo(
            CapturaCenitalScreen(
              porcino: porcino,
              onPesoAplicado: (pesoEstimado) {
                ref.read(animalsNotifierProvider.notifier).fetchPorcinos();
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

  void _openSanidadScreen(PorcinoEntity porcino) {
    _navigateTo(
      RegistroDeVacunacionPorcitech(
        porcino: porcino,
        onEventoGuardado: () {
          ref.read(animalsNotifierProvider.notifier).fetchPorcinos();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openPartoScreen(PorcinoEntity sow) {
    _navigateTo(
      RegistroDePartoCerdaH104(
        cerda: sow,
        onPartoGuardado: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
