import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

import 'desactivar_animaciones.dart';

void main() {
  testWidgets(
    'un desayuno de tres líneas se ve parseado y Cancelar no escribe el Día',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario();
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Desayuno'));
      await tester.enterText(
        find.byType(TextField),
        '100g yogur griego\n60g avena\nbanana chica',
      );
      await tester.pump();

      expect(find.text('yogur griego'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);
      expect(find.text('avena'), findsOneWidget);
      expect(find.text('60 g'), findsOneWidget);
      expect(find.text('banana chica'), findsOneWidget);
      expect(find.text('sin cantidad'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Hoy'), findsOneWidget);
      expect(diario.borrador, isNull);
      expect(diario.hoy().macros.kcal, 0);
    },
  );

  testWidgets(
    'Momento se puede elegir entre desayuno, almuerzo, cena y extra',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario();
      await tester.pumpWidget(NutriMezzoApp(diario: diario));
      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      const opciones = {
        'Desayuno': Momento.desayuno,
        'Almuerzo': Momento.almuerzo,
        'Cena': Momento.cena,
        'Extra': Momento.extra,
      };
      for (final entrada in opciones.entries) {
        await tester.tap(find.text(entrada.key));
        await tester.pump();
        expect(diario.borrador!.momento, entrada.value);
      }
    },
  );
}
