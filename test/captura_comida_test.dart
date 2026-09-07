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

      await tester.tap(find.widgetWithText(ChoiceChip, 'Desayuno'));
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
        await tester.tap(find.widgetWithText(ChoiceChip, entrada.key));
        await tester.pump();
        expect(diario.borrador!.momento, entrada.value);
      }
    },
  );

  testWidgets(
    'abrir Comida con Desayuno ya confirmado lista esos Renglones y deja Listo apagado',
    (tester) async {
      desactivarAnimaciones(tester);
      const macros = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
      final yogur = Alimento(
        id: 'a1',
        nombre: 'yogur griego',
        macrosPor100g: macros,
        patron: 'yogur griego',
        usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
      );
      final diario = Diario(
        ahora: () => DateTime(2026, 9, 6, 8),
        alimentos: [yogur],
        comidas: [
          Comida(
            id: 'c1',
            momento: Momento.desayuno,
            fecha: DateTime(2026, 9, 6),
            renglones: [
              Renglon(
                nombre: 'yogur griego',
                cantidad: 100,
                alimentoId: yogur.id,
              ),
            ],
            recibidoPorUltimaVez: DateTime(2026, 9, 6, 8),
          ),
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Desayuno'), findsOneWidget);
      expect(find.text('Nueva comida'), findsNothing);
      expect(find.text('yogur griego'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Listo'))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('notas nuevas van a Confirmación; los Renglones previos no', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    const macros = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
    final yogur = Alimento(
      id: 'a1',
      nombre: 'yogur griego',
      macrosPor100g: macros,
      patron: 'yogur griego',
      usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
    );
    final avena = Alimento(
      id: 'a2',
      nombre: 'avena',
      macrosPor100g: const Macros(
        kcal: 370,
        proteina: 13,
        carbos: 60,
        grasa: 7,
      ),
      patron: 'avena',
      usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
    );
    final diario = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      alimentos: [yogur, avena],
      comidas: [
        Comida(
          id: 'c1',
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 6),
          renglones: [
            Renglon(
              nombre: 'yogur griego',
              cantidad: 100,
              alimentoId: yogur.id,
            ),
          ],
          recibidoPorUltimaVez: DateTime(2026, 9, 6, 8),
        ),
      ],
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '60g avena');
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmación'), findsOneWidget);
    expect(find.text('avena'), findsWidgets);
    expect(find.text('yogur griego'), findsNothing);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Desayuno'), findsOneWidget);
    expect(find.text('yogur griego'), findsOneWidget);
    expect(find.text('avena'), findsOneWidget);
    expect(diario.hoy().comidas, hasLength(1));
    expect(diario.hoy().comidas.single.renglones, hasLength(2));
  });

  testWidgets('Cancelar tira las notas y no borra los Renglones ya guardados', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    const macros = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
    final yogur = Alimento(
      id: 'a1',
      nombre: 'yogur griego',
      macrosPor100g: macros,
      patron: 'yogur griego',
      usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
    );
    final diario = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      alimentos: [yogur],
      comidas: [
        Comida(
          id: 'c1',
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 6),
          renglones: [
            Renglon(
              nombre: 'yogur griego',
              cantidad: 100,
              alimentoId: yogur.id,
            ),
          ],
          recibidoPorUltimaVez: DateTime(2026, 9, 6, 8),
        ),
      ],
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '200g yogur griego');
    await tester.pump();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
    expect(diario.borrador, isNull);
    expect(diario.hoy().comidas.single.renglones, hasLength(1));
    expect(diario.hoy().comidas.single.renglones.single.cantidad, 100);
  });

  testWidgets(
    'el chip de Momento cambia la lista previa y deja el texto de las notas',
    (tester) async {
      desactivarAnimaciones(tester);
      const macros = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
      final yogur = Alimento(
        id: 'a1',
        nombre: 'yogur griego',
        macrosPor100g: macros,
        patron: 'yogur griego',
        usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
      );
      final diario = Diario(
        ahora: () => DateTime(2026, 9, 6, 8),
        alimentos: [yogur],
        comidas: [
          Comida(
            id: 'c1',
            momento: Momento.desayuno,
            fecha: DateTime(2026, 9, 6),
            renglones: [
              Renglon(
                nombre: 'yogur griego',
                cantidad: 100,
                alimentoId: yogur.id,
              ),
            ],
            recibidoPorUltimaVez: DateTime(2026, 9, 6, 8),
          ),
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '60g avena');
      await tester.pump();
      expect(find.text('yogur griego'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Extra'));
      await tester.pump();

      expect(find.widgetWithText(AppBar, 'Extra'), findsOneWidget);
      expect(find.text('yogur griego'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '60g avena',
      );
      expect(diario.borrador!.momento, Momento.extra);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Desayuno'));
      await tester.pump();

      expect(find.text('yogur griego'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '60g avena',
      );
    },
  );

  testWidgets('después de confirmar Extra, abrir Comida elige Extra', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    const macros = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
    final yogur = Alimento(
      id: 'a1',
      nombre: 'yogur griego',
      macrosPor100g: macros,
      patron: 'yogur griego',
      usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
    );
    final diario = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      alimentos: [yogur],
      comidas: [
        Comida(
          id: 'c1',
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 6),
          renglones: [
            Renglon(
              nombre: 'yogur griego',
              cantidad: 100,
              alimentoId: yogur.id,
            ),
          ],
          recibidoPorUltimaVez: DateTime(2026, 9, 6, 8),
        ),
        Comida(
          id: 'c2',
          momento: Momento.extra,
          fecha: DateTime(2026, 9, 6),
          renglones: [
            Renglon(nombre: 'yogur griego', cantidad: 30, alimentoId: yogur.id),
          ],
          recibidoPorUltimaVez: DateTime(2026, 9, 6, 9),
        ),
      ],
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Extra'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Extra'))
          .selected,
      isTrue,
    );
    expect(find.text('30 g'), findsOneWidget);
  });
}
