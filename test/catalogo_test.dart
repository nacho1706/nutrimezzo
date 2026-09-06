import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

import 'desactivar_animaciones.dart';

void main() {
  testWidgets(
    'crear un Alimento en el catálogo lo deja listo para un match local',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario();
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await tester.tap(find.byTooltip('Catálogo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre'),
        'yogur griego',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Calorías'),
        '97',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Proteína (P)'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Carbos (C)'),
        '3.6',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Grasa (F)'),
        '5',
      );
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('yogur griego'), findsOneWidget);
      expect(diario.alimentos.single.nombre, 'yogur griego');
      expect(diario.alimentos.single.patron, 'yogur griego');
    },
  );

  testWidgets('abrir un Alimento permite editar macros, Patrón y borrar', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario();
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));
    await tester.tap(find.byTooltip('Catálogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('yogur griego'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calorías'),
      '59',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Patrón'),
      r'yogur|yogurt',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(diario.alimentos.single.macrosPor100g.kcal, 59);
    expect(diario.alimentos.single.patron, r'yogur|yogurt');
    expect(find.text('yogur griego'), findsOneWidget);

    await tester.tap(find.text('yogur griego'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Borrar Alimento'));
    await tester.pumpAndSettle();

    expect(diario.alimentos, isEmpty);
    expect(find.text('yogur griego'), findsNothing);
  });
}
