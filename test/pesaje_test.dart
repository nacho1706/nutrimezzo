import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

import 'desactivar_animaciones.dart';

Future<void> irAPesaje(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Pesaje'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'el arranque sigue en Día (Hoy) con FAB, y los destinos son Día, Cumplimiento y Pesaje',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Comida'), findsOneWidget);
      expect(find.text('Día'), findsOneWidget);
      expect(find.text('Cumplimiento'), findsOneWidget);
      expect(find.text('Pesaje'), findsOneWidget);
    },
  );

  testWidgets(
    'Pesaje no tiene FAB de Comida ni chevrons de Día, y el título es Pesaje',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await irAPesaje(tester);

      expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
      expect(find.text('Comida'), findsNothing);
      expect(find.byTooltip('Día anterior'), findsNothing);
      expect(find.byTooltip('Día siguiente'), findsNothing);
      expect(find.byTooltip('Catálogo'), findsOneWidget);
      expect(find.byTooltip('Ajustes'), findsOneWidget);
    },
  );

  testWidgets('Catálogo y Ajustes abiertos en Pesaje vuelven a Pesaje', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    await tester.tap(find.byTooltip('Catálogo'));
    await tester.pumpAndSettle();
    expect(find.text('Catálogo'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
    expect(find.text('Comida'), findsNothing);
    expect(find.byTooltip('Catálogo'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
    expect(find.text('Comida'), findsNothing);
    expect(find.byTooltip('Ajustes'), findsOneWidget);
  });

  testWidgets(
    'Pesaje muestra un campo kg centrado, una pista de ayuno y Guardar',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await irAPesaje(tester);

      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.textAlign, TextAlign.center);
      expect(find.text('Mejor en ayunas, a la mañana.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Guardar'), findsOneWidget);
    },
  );

  testWidgets('tipear un kg sin Guardar no escribe un Pesaje', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    await tester.enterText(find.byType(TextField), '72.4');
    await tester.pump();

    expect(diario.pesajeDe(DateTime(2026, 9, 6)), isNull);
  });

  testWidgets(
    'un lunes en Día es el lunes que Pesaje guarda, y al volver sigue ese lunes',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await tester.tap(find.byTooltip('Día siguiente'));
      await tester.pump();
      expect(find.text('lunes'), findsOneWidget);

      await irAPesaje(tester);
      await tester.enterText(find.byType(TextField), '72.4');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(diario.pesajeDe(DateTime(2026, 9, 7))!.kilogramos, 72.4);
      expect(diario.pesajeDe(DateTime(2026, 9, 6)), isNull);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Día'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('lunes'), findsOneWidget);
      expect(find.text('lunes 7 de septiembre'), findsOneWidget);
    },
  );

  testWidgets('el campo vacío no guarda un Pesaje', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(diario.pesajeDe(DateTime(2026, 9, 6)), isNull);
  });

  testWidgets(
    'Guardar de nuevo reemplaza el kg y no hay control para borrar el Pesaje',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await irAPesaje(tester);
      await tester.enterText(find.byType(TextField), '72.4');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '71');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(diario.pesajeDe(DateTime(2026, 9, 6))!.kilogramos, 71);
      expect(find.textContaining('Borrar'), findsNothing);
    },
  );

  testWidgets('Guardar rechaza 0 y 72.45 y deja el Pesaje anterior', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    await tester.enterText(find.byType(TextField), '72');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(diario.pesajeDe(DateTime(2026, 9, 6))!.kilogramos, 72);

    await tester.enterText(find.byType(TextField), '72.45');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(diario.pesajeDe(DateTime(2026, 9, 6))!.kilogramos, 72);
  });

  testWidgets('tocar un día en Cumplimiento abre ese Día', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cumplimiento'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('8 de septiembre'));
    await tester.pumpAndSettle();

    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('martes 8 de septiembre'), findsOneWidget);
  });

  testWidgets('un Pesaje futuro no es una Meta y no aparece en Ajustes', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.byTooltip('Día siguiente'));
    await tester.pump();
    await irAPesaje(tester);
    await tester.enterText(find.byType(TextField), '73');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Meta'), findsOneWidget);
    expect(find.text('73'), findsNothing);
    expect(find.text('kg'), findsNothing);
    expect(find.text('Pesaje'), findsNothing);
    expect(find.text('Peso'), findsNothing);
  });

  testWidgets('el anillo, las barras y el FAB de Día no muestran el kg', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    await tester.enterText(find.byType(TextField), '72.4');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Día'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('72.4'), findsNothing);
    expect(find.text('kg'), findsNothing);
    expect(find.text('0.0 / 2000.0 kcal'), findsOneWidget);
  });

  testWidgets('un Pesaje no pinta Cumplimiento; una Comida sin Pesaje sí', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    const macros = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
    final yogur = Alimento(
      id: 'a1',
      nombre: 'yogur griego',
      macrosPor100g: macros,
      patron: 'yogur griego',
      usadoPorUltimaVez: DateTime(2026, 9, 5, 8),
    );
    final diario = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      alimentos: [yogur],
      comidas: [
        Comida(
          id: 'c1',
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 5),
          renglones: [
            Renglon(
              nombre: 'yogur griego',
              cantidad: 100,
              alimentoId: yogur.id,
            ),
          ],
        ),
      ],
    );
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cumplimiento'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('5 de septiembre, amarillo'), findsOneWidget);
    expect(find.bySemanticsLabel('6 de septiembre'), findsOneWidget);
    expect(find.bySemanticsLabel('6 de septiembre, rojo'), findsNothing);
    expect(find.bySemanticsLabel('6 de septiembre, amarillo'), findsNothing);
    expect(find.bySemanticsLabel('6 de septiembre, verde'), findsNothing);
  });

  testWidgets('Pesaje muestra el kg ya guardado de ese Día', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '72.4',
    );
  });
}
