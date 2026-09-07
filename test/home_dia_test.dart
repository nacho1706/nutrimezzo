import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

import 'desactivar_animaciones.dart';

void main() {
  testWidgets('el Día anterior se abre de golpe con sus Comidas y totales', (
    tester,
  ) async {
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

    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('0 / 2000 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Día anterior'));
    await tester.pump();

    expect(find.text('97 / 2000 kcal'), findsOneWidget);
    expect(find.text('yogur griego'), findsOneWidget);
    expect(find.text('sábado 5 de septiembre'), findsOneWidget);
    expect(find.text('0 / 2000 kcal'), findsNothing);
  });

  testWidgets('un Renglón guardado se puede cambiar de Cantidad y borrar', (
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
        ),
      ],
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.text('yogur griego'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad'),
      '200',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('194 / 2000 kcal'), findsOneWidget);
    expect(find.text('200 g'), findsOneWidget);

    await tester.tap(find.text('yogur griego'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar Renglón'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 2000 kcal'), findsOneWidget);
    expect(diario.hoy().comidas, isEmpty);
  });

  testWidgets('borrar una Comida desde Hoy baja los totales', (tester) async {
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
        ),
      ],
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar Comida'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 2000 kcal'), findsOneWidget);
    expect(diario.hoy().comidas, isEmpty);
  });

  testWidgets(
    'confirmar una Comida interpola las kcal del mismo Día, no las salta',
    (tester) async {
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
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));
      expect(find.text('0 / 2000 kcal'), findsOneWidget);

      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
        fecha: DateTime(2026, 9, 6),
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 100,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('97 / 2000 kcal'), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .value,
        lessThan(97 / 2000),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('97 / 2000 kcal'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('97 / 2000 kcal'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .value,
        closeTo(97 / 2000, 0.0001),
      );
    },
  );

  testWidgets(
    'disableAnimations deja las macros del mismo Día en el valor final',
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
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
        fecha: DateTime(2026, 9, 6),
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 100,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('97 / 2000 kcal'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .value,
        closeTo(97 / 2000, 0.0001),
      );
    },
  );

  testWidgets(
    'el primer pintado de un Día muestra las macros finales, no llena desde 0',
    (tester) async {
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
          ),
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('97 / 2000 kcal'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .value,
        closeTo(97 / 2000, 0.0001),
      );
    },
  );

  testWidgets('Confirmar no recrea HomeDia: se queda en el Día mostrado', (
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
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.byTooltip('Día anterior'));
    await tester.pump();
    expect(find.text('sábado 5 de septiembre'), findsOneWidget);

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '100g yogur griego');
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('sábado 5 de septiembre'), findsOneWidget);
    expect(find.text('Hoy'), findsNothing);
    expect(find.text('97 / 2000 kcal'), findsOneWidget);
  });

  testWidgets(
    'Hoy con dos Comidas guardadas del mismo Momento muestra un solo encabezado',
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
          ),
          Comida(
            id: 'c2',
            momento: Momento.desayuno,
            fecha: DateTime(2026, 9, 6),
            renglones: [
              Renglon(
                nombre: 'yogur griego',
                cantidad: 30,
                alimentoId: yogur.id,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);
      expect(find.text('30 g'), findsOneWidget);
      expect(find.text('126 / 2000 kcal'), findsOneWidget);
    },
  );
}
