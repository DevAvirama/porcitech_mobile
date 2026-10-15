import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:porcitech_mobile/main.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';

void main() {
  testWidgets('Smoke test inicial de arranque PorciTech Mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const PorciTechApp(),
      ),
    );

    await tester.pump();

    // Valida cabecera corporativa y campos de login de campo
    expect(find.text('PorciTech'), findsOneWidget);
    expect(find.text('Sistema Integral Porcino • Operaciones de Campo'), findsOneWidget);
    expect(find.text('Usuario o Correo Institucional'), findsOneWidget);
    expect(find.text('Contraseña de Acceso'), findsOneWidget);
    expect(find.text('Modo Offline en Granja'), findsOneWidget);
    expect(find.text('Conectado a la API REST de FastAPI'), findsOneWidget);
  });
}
