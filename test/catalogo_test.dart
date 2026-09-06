import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

void main() {
  testWidgets(
    'crear un Alimento en el catálogo lo deja listo para un match local',
    (tester) async {
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
}
