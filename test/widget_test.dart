import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:porcitech_mobile/main.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/core/widgets/brand_mark.dart';

void main() {
  testWidgets('Smoke test inicial de arranque SENA PorciTech Mobile', (WidgetTester tester) async {
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

    // Valida identidad institucional SENA + PorciTech y pantalla de login
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text('Sistema Integral de Gestión Porcina'), findsOneWidget);
    expect(find.text('TERMINAL MÓVIL DE CAMPO • SENA'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(
      find.text('PORCITECH MOBILE • SERVICIO NACIONAL DE APRENDIZAJE (SENA)'),
      findsOneWidget,
    );
  });
}
