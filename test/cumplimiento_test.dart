import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

import 'desactivar_animaciones.dart';

Future<void> irACumplimiento(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Cumplimiento'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'el arranque sigue en Día (Hoy) con FAB, chevrons, Catálogo y Ajustes',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Comida'), findsOneWidget);
      expect(find.byTooltip('Día anterior'), findsOneWidget);
      expect(find.byTooltip('Día siguiente'), findsOneWidget);
      expect(find.byTooltip('Catálogo'), findsOneWidget);
      expect(find.byTooltip('Ajustes'), findsOneWidget);
      expect(find.text('Día'), findsOneWidget);
      expect(find.text('Cumplimiento'), findsOneWidget);
    },
  );

  testWidgets('Cumplimiento no tiene FAB de Comida ni chevrons de Día', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irACumplimiento(tester);

    expect(find.text('Comida'), findsNothing);
    expect(find.byTooltip('Día anterior'), findsNothing);
    expect(find.byTooltip('Día siguiente'), findsNothing);
    expect(find.byTooltip('Catálogo'), findsOneWidget);
    expect(find.byTooltip('Ajustes'), findsOneWidget);
  });

  testWidgets(
    'Catálogo y Ajustes abiertos en Cumplimiento vuelven a Cumplimiento',
    (tester) async {
      desactivarAnimaciones(tester);
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await irACumplimiento(tester);

      await tester.tap(find.byTooltip('Catálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Comida'), findsNothing);
      expect(find.byTooltip('Catálogo'), findsOneWidget);

      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Comida'), findsNothing);
      expect(find.byTooltip('Ajustes'), findsOneWidget);
    },
  );

  testWidgets('tocar un día del mes abre ese Día, incluso sin Comida', (
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
    await tester.pumpWidget(NutriMezzoApp(diario: diario));
    await irACumplimiento(tester);

    await tester.tap(find.bySemanticsLabel('5 de septiembre, amarillo'));
    await tester.pumpAndSettle();

    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('sábado 5 de septiembre'), findsOneWidget);
    expect(find.text('yogur griego'), findsOneWidget);
    expect(find.text('97 / 2000 kcal'), findsOneWidget);

    await irACumplimiento(tester);
    await tester.tap(find.bySemanticsLabel('8 de septiembre'));
    await tester.pumpAndSettle();

    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('martes 8 de septiembre'), findsOneWidget);
    expect(find.text('yogur griego'), findsNothing);
    expect(find.text('0 / 2000 kcal'), findsOneWidget);
  });

  testWidgets('cambiar de mes no cambia la fecha del Día hasta tocar un día', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await irACumplimiento(tester);
    expect(find.text('septiembre 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('agosto 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('6 de septiembre'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Día'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('domingo 6 de septiembre'), findsOneWidget);
    expect(find.text('Comida'), findsOneWidget);

    await irACumplimiento(tester);
    expect(find.text('septiembre 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('15 de agosto'));
    await tester.pumpAndSettle();
    expect(find.text('sábado 15 de agosto'), findsOneWidget);
    expect(find.text('Comida'), findsOneWidget);

    await irACumplimiento(tester);
    expect(find.text('agosto 2026'), findsOneWidget);
  });

  testWidgets('la semana del calendario empieza en lunes', (tester) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await tester.pumpWidget(NutriMezzoApp(diario: diario));
    await irACumplimiento(tester);

    final lun = tester.getCenter(find.text('lun'));
    final mar = tester.getCenter(find.text('mar'));
    expect(lun.dx, lessThan(mar.dx));

    final uno = tester.getCenter(find.bySemanticsLabel('1 de septiembre'));
    expect((uno.dx - mar.dx).abs(), lessThan((uno.dx - lun.dx).abs()));
  });

  testWidgets(
    'el mes pinta rojo, amarillo y verde, y un día sin Comida no tiene color',
    (tester) async {
      desactivarAnimaciones(tester);
      await tester.pumpWidget(NutriMezzoApp(diario: _diarioPintado()));
      await irACumplimiento(tester);

      expect(
        find.bySemanticsLabel('5 de septiembre, amarillo'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('7 de septiembre, rojo'), findsOneWidget);
      expect(find.bySemanticsLabel('8 de septiembre, verde'), findsOneWidget);
      expect(find.bySemanticsLabel('6 de septiembre'), findsOneWidget);
      expect(find.bySemanticsLabel('6 de septiembre, rojo'), findsNothing);
      expect(find.bySemanticsLabel('6 de septiembre, amarillo'), findsNothing);
      expect(find.bySemanticsLabel('6 de septiembre, verde'), findsNothing);
    },
  );

  testWidgets(
    'subir el techo de kcal en Ajustes rejuzga el mes y vuelve a Cumplimiento',
    (tester) async {
      desactivarAnimaciones(tester);
      final alimento = Alimento(
        id: 'a1',
        nombre: 'exceso kcal',
        macrosPor100g: const Macros(
          kcal: 2100,
          proteina: 160,
          carbos: 10,
          grasa: 10,
        ),
        patron: 'exceso kcal',
        usadoPorUltimaVez: DateTime(2026, 9, 5, 8),
      );
      final diario = Diario(
        ahora: () => DateTime(2026, 9, 6, 8),
        alimentos: [alimento],
        comidas: [
          Comida(
            id: 'c1',
            momento: Momento.desayuno,
            fecha: DateTime(2026, 9, 5),
            renglones: [
              Renglon(
                nombre: alimento.nombre,
                cantidad: 100,
                alimentoId: alimento.id,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));
      await irACumplimiento(tester);
      expect(find.bySemanticsLabel('5 de septiembre, rojo'), findsOneWidget);

      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '2200');
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Comida'), findsNothing);
      expect(find.bySemanticsLabel('5 de septiembre, verde'), findsOneWidget);
      expect(find.bySemanticsLabel('5 de septiembre, rojo'), findsNothing);
    },
  );

  testWidgets('editar un Alimento en Catálogo pinta rojo el Día que lo usó', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = _diarioPintado();
    await tester.pumpWidget(NutriMezzoApp(diario: diario));
    await irACumplimiento(tester);
    expect(find.bySemanticsLabel('8 de septiembre, verde'), findsOneWidget);

    await tester.tap(find.byTooltip('Catálogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('en meta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calorías'),
      '2100',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Comida'), findsNothing);
    expect(find.bySemanticsLabel('8 de septiembre, rojo'), findsOneWidget);
    expect(find.bySemanticsLabel('8 de septiembre, verde'), findsNothing);
  });

  testWidgets('confirmar una Comida de hoy pinta ese día sin reiniciar', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
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
    await irACumplimiento(tester);
    expect(find.bySemanticsLabel('6 de septiembre'), findsOneWidget);
    expect(find.bySemanticsLabel('6 de septiembre, amarillo'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Día'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '100g yogur griego');
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    await irACumplimiento(tester);
    expect(find.bySemanticsLabel('6 de septiembre, amarillo'), findsOneWidget);
  });
}

Diario _diarioPintado() {
  final amarillo = Alimento(
    id: 'a1',
    nombre: 'bajo proteina',
    macrosPor100g: const Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5),
    patron: 'bajo proteina',
    usadoPorUltimaVez: DateTime(2026, 9, 5, 8),
  );
  final rojo = Alimento(
    id: 'a2',
    nombre: 'exceso kcal',
    macrosPor100g: const Macros(
      kcal: 2100,
      proteina: 200,
      carbos: 10,
      grasa: 10,
    ),
    patron: 'exceso kcal',
    usadoPorUltimaVez: DateTime(2026, 9, 7, 8),
  );
  final verde = Alimento(
    id: 'a3',
    nombre: 'en meta',
    macrosPor100g: const Macros(
      kcal: 1800,
      proteina: 160,
      carbos: 10,
      grasa: 10,
    ),
    patron: 'en meta',
    usadoPorUltimaVez: DateTime(2026, 9, 8, 8),
  );
  return Diario(
    ahora: () => DateTime(2026, 9, 6, 8),
    alimentos: [amarillo, rojo, verde],
    comidas: [
      Comida(
        id: 'c1',
        momento: Momento.desayuno,
        fecha: DateTime(2026, 9, 5),
        renglones: [
          Renglon(
            nombre: amarillo.nombre,
            cantidad: 100,
            alimentoId: amarillo.id,
          ),
        ],
      ),
      Comida(
        id: 'c2',
        momento: Momento.desayuno,
        fecha: DateTime(2026, 9, 7),
        renglones: [
          Renglon(nombre: rojo.nombre, cantidad: 100, alimentoId: rojo.id),
        ],
      ),
      Comida(
        id: 'c3',
        momento: Momento.desayuno,
        fecha: DateTime(2026, 9, 8),
        renglones: [
          Renglon(nombre: verde.nombre, cantidad: 100, alimentoId: verde.id),
        ],
      ),
    ],
  );
}
