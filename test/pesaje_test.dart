import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/calendario_mes.dart';
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

  testWidgets('Pesaje pone el mes compartido bajo el campo, sin Promedio', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    expect(find.byType(CalendarioMes), findsOneWidget);
    expect(find.text('septiembre 2026'), findsOneWidget);
    expect(find.byTooltip('Mes anterior'), findsOneWidget);
    expect(find.byTooltip('Mes siguiente'), findsOneWidget);
    expect(find.text('lun'), findsOneWidget);
    expect(find.text('dom'), findsOneWidget);
    expect(find.text('Promedio'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Guardar'), findsOneWidget);

    final campo = tester.getTopLeft(find.byType(TextField));
    final mes = tester.getTopLeft(find.byType(CalendarioMes));
    expect(campo.dy, lessThan(mes.dy));
  });

  testWidgets(
    'un Día con Pesaje muestra el kg en la celda; uno sin Pesaje queda vacío',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await diario.guardarPesaje(fecha: DateTime(2026, 9, 5), kilogramos: 72.4);
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await irAPesaje(tester);

      expect(find.text('72.4'), findsOneWidget);
      expect(find.text('0.0'), findsNothing);
      expect(find.bySemanticsLabel('5 de septiembre, 72.4 kg'), findsOneWidget);
      expect(find.bySemanticsLabel('6 de septiembre'), findsOneWidget);
      expect(find.bySemanticsLabel('5 de septiembre, rojo'), findsNothing);
      expect(find.bySemanticsLabel('5 de septiembre, amarillo'), findsNothing);
      expect(find.bySemanticsLabel('5 de septiembre, verde'), findsNothing);
      expect(find.bySemanticsLabel('6 de septiembre, rojo'), findsNothing);
      expect(find.bySemanticsLabel('6 de septiembre, amarillo'), findsNothing);
      expect(find.bySemanticsLabel('6 de septiembre, verde'), findsNothing);
    },
  );

  testWidgets('tocar un día en Pesaje lo selecciona, se queda y carga ese kg', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 8), kilogramos: 71.5);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );

    await tester.tap(find.bySemanticsLabel('8 de septiembre, 71.5 kg'));
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
    expect(find.text('Comida'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '71.5',
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Día'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('martes 8 de septiembre'), findsOneWidget);
  });

  testWidgets(
    'tocar un Día sin Pesaje deja el campo vacío y se queda en Pesaje',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await irAPesaje(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '72.4',
      );

      await tester.tap(find.bySemanticsLabel('8 de septiembre'));
      await tester.pump();

      expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
      expect(find.text('Comida'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    },
  );

  testWidgets(
    'los chevrons del mes no cambian el Día seleccionado hasta tocar una celda',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await irAPesaje(tester);
      expect(find.text('septiembre 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pump();

      expect(find.text('agosto 2026'), findsOneWidget);
      expect(find.text('septiembre 2026'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '72.4',
      );
      expect(find.bySemanticsLabel('6 de septiembre, 72.4 kg'), findsNothing);

      await tester.tap(find.bySemanticsLabel('15 de agosto'));
      await tester.pump();

      expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Día'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('sábado 15 de agosto'), findsOneWidget);
    },
  );

  testWidgets('entrar a Pesaje abre el mes del Día seleccionado', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pump();
    expect(find.text('agosto 2026'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Día'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hoy'), findsOneWidget);

    await irAPesaje(tester);
    expect(find.text('septiembre 2026'), findsOneWidget);
    expect(find.text('agosto 2026'), findsNothing);
  });

  testWidgets('después de Guardar la celda muestra el kg nuevo', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    await tester.enterText(find.byType(TextField), '72.4');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('72.4'), findsWidgets);
    expect(find.bySemanticsLabel('6 de septiembre, 72.4 kg'), findsOneWidget);
    expect(diario.pesajeDe(DateTime(2026, 9, 6))!.kilogramos, 72.4);
  });

  testWidgets('un día futuro se elige y se guarda desde la grilla', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    await tester.tap(find.bySemanticsLabel('8 de septiembre'));
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
    expect(find.text('Comida'), findsNothing);

    await tester.enterText(find.byType(TextField), '73');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(diario.pesajeDe(DateTime(2026, 9, 8))!.kilogramos, 73);
    expect(find.text('73.0'), findsOneWidget);
    expect(find.bySemanticsLabel('8 de septiembre, 73.0 kg'), findsOneWidget);
  });

  testWidgets('el Promedio queda arriba del campo y es la media de la Semana', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 8, 31), kilogramos: 72.4);
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 2), kilogramos: 71.8);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    final promedio = find.bySemanticsLabel('Promedio 72.1 kg');
    expect(promedio, findsOneWidget);
    expect(
      tester.getTopLeft(promedio).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets('una Semana sin Pesajes no muestra Promedio ni 0 kg', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    expect(find.textContaining('Promedio'), findsNothing);
    expect(find.textContaining('0.0 kg'), findsNothing);
    expect(find.textContaining('0 kg'), findsNothing);
  });

  testWidgets('Guardar actualiza el Promedio sin salir de Pesaje', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 8, 31), kilogramos: 72.4);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    expect(find.bySemanticsLabel('Promedio 72.4 kg'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '71.8');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
    expect(find.bySemanticsLabel('Promedio 72.1 kg'), findsOneWidget);
  });

  testWidgets('cambiar el Día mueve el Promedio a esa Semana', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 7), kilogramos: 71);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    expect(find.bySemanticsLabel('Promedio 72.4 kg'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Día'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Día siguiente'));
    await tester.pump();
    await irAPesaje(tester);

    expect(
      find.bySemanticsLabel('Promedio 71.0 kg, bajó 1.4 kg'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Promedio 72.4 kg'), findsNothing);
  });

  testWidgets('si el Promedio bajó, hay flecha verde y cuánto bajó', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 7, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 7), kilogramos: 71);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    expect(
      find.bySemanticsLabel('Promedio 71.0 kg, bajó 1.4 kg'),
      findsOneWidget,
    );
    expect(find.byTooltip('bajó 1.4 kg'), findsOneWidget);
    expect(find.text('1.4 kg'), findsOneWidget);
  });

  testWidgets('si el Promedio subió, hay flecha roja y cuánto subió', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 7, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 71);
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 7), kilogramos: 72.4);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    expect(
      find.bySemanticsLabel('Promedio 72.4 kg, subió 1.4 kg'),
      findsOneWidget,
    );
    expect(find.byTooltip('subió 1.4 kg'), findsOneWidget);
    expect(find.byTooltip('bajó 1.4 kg'), findsNothing);
  });

  testWidgets('si el Promedio empata, no hay flecha', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 7, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 7), kilogramos: 72.4);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    expect(find.bySemanticsLabel('Promedio 72.4 kg'), findsOneWidget);
    expect(find.byTooltip('bajó 0.0 kg'), findsNothing);
    expect(find.byTooltip('subió 0.0 kg'), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
  });

  testWidgets('sin Promedio anterior no hay flecha ni delta', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);

    expect(find.bySemanticsLabel('Promedio 72.4 kg'), findsOneWidget);
    expect(find.byTooltip('bajó 0.0 kg'), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
  });

  testWidgets('Guardar también actualiza la flecha', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 7, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irAPesaje(tester);
    expect(find.textContaining('Promedio'), findsNothing);

    await tester.enterText(find.byType(TextField), '71');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Pesaje'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Promedio 71.0 kg, bajó 1.4 kg'),
      findsOneWidget,
    );
    expect(find.byTooltip('bajó 1.4 kg'), findsOneWidget);
  });
}
