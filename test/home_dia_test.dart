import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/home_dia.dart';
import 'package:nutrimezzo/main.dart';

import 'desactivar_animaciones.dart';
import 'opacidad.dart';

PintorAnilloKcal pintorAnillo(WidgetTester tester) {
  return tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(AnilloKcal),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!
      as PintorAnilloKcal;
}

void testDia(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(800, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await body(tester);
  });
}

void main() {
  testDia('el Día anterior se abre de golpe con sus Comidas y totales', (
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

  testDia('tocar un Renglón en el Día muestra sus Macros y no abre un editor', (
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

    expect(find.text('97 / 2000 kcal'), findsOneWidget);
    expect(find.text('Calorías'), findsNothing);

    await tester.tap(find.text('yogur griego'));
    await tester.pumpAndSettle();

    expect(find.text('100 g'), findsOneWidget);
    expect(find.text('Calorías'), findsOneWidget);
    expect(find.text('97 kcal'), findsNWidgets(2));
    expect(find.text('10 g'), findsOneWidget);
    expect(find.text('3.6 g'), findsOneWidget);
    expect(find.text('5 g'), findsOneWidget);
    expect(find.text('Proteína (P)'), findsNWidgets(2));
    expect(find.text('Carbos (C)'), findsNWidgets(2));
    expect(find.text('Grasa (F)'), findsNWidgets(2));
    expect(find.text('97 / 2000 kcal'), findsOneWidget);
    expect(find.text('Borrar Renglón'), findsNothing);
    expect(find.text('Guardar'), findsNothing);
    expect(find.text('Cantidad'), findsNothing);
    expect(find.text('Alimento'), findsNothing);
  });

  testDia('borrar una Comida desde Hoy baja los totales', (tester) async {
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

  testDia(
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
      expect(pintorAnillo(tester).progreso, lessThan(97 / 2000));
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .value,
        lessThan(10 / 150),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('97 / 2000 kcal'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('97 / 2000 kcal'), findsOneWidget);
      expect(pintorAnillo(tester).progreso, closeTo(97 / 2000, 0.0001));
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .value,
        closeTo(10 / 150, 0.0001),
      );
    },
  );

  testDia('disableAnimations deja las macros del mismo Día en el valor final', (
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
    expect(pintorAnillo(tester).progreso, closeTo(97 / 2000, 0.0001));
  });

  testDia(
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
      expect(pintorAnillo(tester).progreso, closeTo(97 / 2000, 0.0001));
      expect(find.byType(AnilloKcal), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    },
  );

  testDia('Confirmar no recrea HomeDia: se queda en el Día mostrado', (
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

  testDia(
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

  testDia(
    'tocar de nuevo oculta los Macros; tocar otro deja uno solo abierto',
    (tester) async {
      desactivarAnimaciones(tester);
      const macrosYogur = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
      const macrosAvena = Macros(kcal: 370, proteina: 13, carbos: 60, grasa: 7);
      final yogur = Alimento(
        id: 'a1',
        nombre: 'yogur griego',
        macrosPor100g: macrosYogur,
        patron: 'yogur griego',
        usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
      );
      final avena = Alimento(
        id: 'a2',
        nombre: 'avena',
        macrosPor100g: macrosAvena,
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
              Renglon(nombre: 'avena', cantidad: 30, alimentoId: avena.id),
            ],
          ),
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await tester.tap(find.text('yogur griego'));
      await tester.pumpAndSettle();
      expect(find.text('97 kcal'), findsOneWidget);
      expect(find.text('111 kcal'), findsNothing);

      await tester.scrollUntilVisible(find.text('avena'), 80);
      await tester.drag(find.byType(Scrollable), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.text('avena'));
      await tester.pumpAndSettle();
      expect(find.text('111 kcal'), findsOneWidget);
      expect(find.text('97 kcal'), findsNothing);
      expect(find.text('100 g'), findsOneWidget);
      expect(find.text('30 g'), findsOneWidget);

      await tester.tap(find.text('avena'));
      await tester.pumpAndSettle();
      expect(find.text('111 kcal'), findsNothing);
      expect(find.text('97 kcal'), findsNothing);
    },
  );

  testDia('tocar la fecha, el anillo o las barras no abre el detalle', (
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

    await tester.tap(find.text('domingo 6 de septiembre'));
    await tester.pumpAndSettle();
    expect(find.text('Calorías'), findsNothing);

    await tester.tap(find.byType(AnilloKcal));
    await tester.pumpAndSettle();
    expect(find.text('Calorías'), findsNothing);

    await tester.tap(find.byType(LinearProgressIndicator).first);
    await tester.pumpAndSettle();
    expect(find.text('Calorías'), findsNothing);
    expect(find.text('97 / 2000 kcal'), findsOneWidget);
  });

  testDia(
    'el detalle de un Renglón entra en fade; disableAnimations lo deja opaco',
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

      await tester.tap(find.text('yogur griego'));
      await tester.pump();
      expect(opacidadDe(tester, find.text('Calorías')), lessThan(1));

      await tester.pumpAndSettle();
      expect(opacidadDe(tester, find.text('Calorías')), 1);
    },
  );

  testDia('disableAnimations muestra los Macros expandidos de inmediato', (
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
    await tester.pump();
    expect(opacidadDe(tester, find.text('Calorías')), 1);
  });

  testDia('cambiar de Día cierra el Renglón abierto', (tester) async {
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
          fecha: DateTime(2026, 9, 7),
          renglones: [
            Renglon(
              nombre: 'yogur griego',
              cantidad: 200,
              alimentoId: yogur.id,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.text('yogur griego'));
    await tester.pumpAndSettle();
    expect(find.text('Calorías'), findsOneWidget);

    await tester.tap(find.byTooltip('Día siguiente'));
    await tester.pump();

    expect(find.text('Calorías'), findsNothing);
    expect(find.text('200 g'), findsOneWidget);
  });

  testDia('un Día pasado expande un Renglón igual que Hoy', (tester) async {
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

    await tester.tap(find.byTooltip('Día anterior'));
    await tester.pump();
    await tester.tap(find.text('yogur griego'));
    await tester.pumpAndSettle();

    expect(find.text('sábado 5 de septiembre'), findsOneWidget);
    expect(find.text('100 g'), findsOneWidget);
    expect(find.text('Calorías'), findsOneWidget);
    expect(find.text('3.6 g'), findsOneWidget);
  });

  testDia('el menú del Día sigue borrando la Comida y uniendo Momentos', (
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
        Comida(
          id: 'c2',
          momento: Momento.almuerzo,
          fecha: DateTime(2026, 9, 6),
          renglones: [
            Renglon(nombre: 'yogur griego', cantidad: 30, alimentoId: yogur.id),
          ],
        ),
      ],
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    expect(find.text('126 / 2000 kcal'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Almuerzo').last);
    await tester.pumpAndSettle();

    expect(find.text('Desayuno'), findsNothing);
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('100 g'), findsOneWidget);
    expect(find.text('30 g'), findsOneWidget);
    expect(find.text('126 / 2000 kcal'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar Comida'));
    await tester.pumpAndSettle();

    expect(find.text('Almuerzo'), findsNothing);
    expect(find.text('0 / 2000 kcal'), findsOneWidget);
    expect(diario.hoy().comidas, isEmpty);
  });

  testDia('2200 / 2000 kcal no se ve igual que un anillo lleno a la Meta', (
    tester,
  ) async {
    desactivarAnimaciones(tester);

    Diario diarioCon({required num kcal}) {
      final alimento = Alimento(
        id: 'a1',
        nombre: 'lote',
        macrosPor100g: Macros(kcal: kcal, proteina: 10, carbos: 3.6, grasa: 5),
        patron: 'lote',
        usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
      );
      return Diario(
        ahora: () => DateTime(2026, 9, 6, 8),
        alimentos: [alimento],
        comidas: [
          Comida(
            id: 'c1',
            momento: Momento.desayuno,
            fecha: DateTime(2026, 9, 6),
            renglones: [
              Renglon(nombre: 'lote', cantidad: 100, alimentoId: alimento.id),
            ],
          ),
        ],
      );
    }

    await tester.pumpWidget(NutriMezzoApp(diario: diarioCon(kcal: 2000)));
    expect(find.text('2000 / 2000 kcal'), findsOneWidget);
    expect(pintorAnillo(tester).progreso, 1.0);

    await tester.pumpWidget(NutriMezzoApp(diario: diarioCon(kcal: 2200)));
    expect(find.text('2200 / 2000 kcal'), findsOneWidget);
    expect(pintorAnillo(tester).progreso, closeTo(1.1, 0.0001));
  });

  testDia('proteína por encima de la Meta sigue viéndose como barra llena', (
    tester,
  ) async {
    desactivarAnimaciones(tester);
    const macros = Macros(kcal: 97, proteina: 160, carbos: 3.6, grasa: 5);
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

    expect(find.text('160 / 150 g'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator).first,
          )
          .value,
      1.0,
    );
  });

  testDia(
    'tocar el encabezado de un Momento oculta sus Renglones y deja etiqueta y kcal',
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
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('97 kcal'), findsOneWidget);
      expect(find.text('yogur griego'), findsOneWidget);
      expect(find.text('97 / 2000 kcal'), findsOneWidget);

      await tester.tap(find.text('Desayuno'));
      await tester.pump();

      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('97 kcal'), findsOneWidget);
      expect(find.text('yogur griego'), findsNothing);
      expect(find.text('97 / 2000 kcal'), findsOneWidget);

      await tester.tap(find.text('Desayuno'));
      await tester.pump();

      expect(find.text('yogur griego'), findsOneWidget);
    },
  );

  testDia(
    'cada Momento ocupado se pliega solo; Extra igual y Cena vacía no aparece',
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
                nombre: 'yogur mañana',
                cantidad: 100,
                alimentoId: yogur.id,
              ),
            ],
          ),
          Comida(
            id: 'c2',
            momento: Momento.almuerzo,
            fecha: DateTime(2026, 9, 6),
            renglones: [
              Renglon(
                nombre: 'yogur mediodía',
                cantidad: 30,
                alimentoId: yogur.id,
              ),
            ],
          ),
          Comida(
            id: 'c3',
            momento: Momento.extra,
            fecha: DateTime(2026, 9, 6),
            renglones: [
              Renglon(
                nombre: 'yogur noche',
                cantidad: 50,
                alimentoId: yogur.id,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('Desayuno'), findsOneWidget);
      expect(find.text('Almuerzo'), findsOneWidget);
      expect(find.text('Cena'), findsNothing);
      expect(find.text('Extra'), findsOneWidget);
      expect(find.text('97 kcal'), findsOneWidget);
      expect(find.text('29.1 kcal'), findsOneWidget);
      expect(find.text('48.5 kcal'), findsOneWidget);
      expect(find.text('Cerrar todo'), findsNothing);
      expect(find.text('yogur mañana'), findsOneWidget);
      expect(find.text('yogur mediodía'), findsOneWidget);
      expect(find.text('yogur noche'), findsOneWidget);

      await tester.tap(find.text('Desayuno'));
      await tester.pump();
      expect(find.text('yogur mañana'), findsNothing);
      expect(find.text('yogur mediodía'), findsOneWidget);
      expect(find.text('yogur noche'), findsOneWidget);
      expect(find.text('97 kcal'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Extra'), 80);
      await tester.tap(find.text('Extra'));
      await tester.pump();
      expect(find.text('yogur mañana'), findsNothing);
      expect(find.text('yogur mediodía'), findsOneWidget);
      expect(find.text('yogur noche'), findsNothing);
      expect(find.text('48.5 kcal'), findsOneWidget);
    },
  );

  testDia('abrir el menú ⋮ no pliega el Momento y sigue borrando la Comida', (
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

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('yogur griego'), findsOneWidget);
    expect(find.text('Borrar Comida'), findsOneWidget);

    await tester.tap(find.text('Borrar Comida'));
    await tester.pumpAndSettle();
    expect(find.text('Desayuno'), findsNothing);
    expect(find.text('0 / 2000 kcal'), findsOneWidget);
    expect(diario.hoy().comidas, isEmpty);
  });

  testDia('el menú ⋮ de un Momento cerrado sigue cambiando el Momento', (
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

    await tester.tap(find.text('Desayuno'));
    await tester.pump();
    expect(find.text('yogur griego'), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('yogur griego'), findsNothing);
    expect(find.text('Borrar Comida'), findsOneWidget);

    await tester.tap(find.text('Almuerzo'));
    await tester.pumpAndSettle();

    expect(find.text('Desayuno'), findsNothing);
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('yogur griego'), findsOneWidget);
    expect(find.text('97 kcal'), findsOneWidget);
    expect(find.text('97 / 2000 kcal'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desayuno').last);
    await tester.pumpAndSettle();

    expect(find.text('Desayuno'), findsOneWidget);
    expect(find.text('yogur griego'), findsOneWidget);
  });

  testDia(
    'cambiar de fecha abre los Momentos y cierra el Renglón; matar la app no recuerda el pliegue',
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
            fecha: DateTime(2026, 9, 7),
            renglones: [
              Renglon(
                nombre: 'yogur griego',
                cantidad: 200,
                alimentoId: yogur.id,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      await tester.tap(find.text('yogur griego'));
      await tester.pumpAndSettle();
      expect(find.text('Calorías'), findsOneWidget);

      await tester.tap(find.text('Desayuno'));
      await tester.pump();
      expect(find.text('yogur griego'), findsNothing);
      expect(find.text('Calorías'), findsNothing);

      await tester.tap(find.byTooltip('Día siguiente'));
      await tester.pump();
      expect(find.text('yogur griego'), findsOneWidget);
      expect(find.text('200 g'), findsOneWidget);
      expect(find.text('Calorías'), findsNothing);
      expect(find.text('194 kcal'), findsOneWidget);

      await tester.tap(find.byTooltip('Día anterior'));
      await tester.pump();
      expect(find.text('yogur griego'), findsOneWidget);
      expect(find.text('Calorías'), findsNothing);

      await tester.tap(find.text('Desayuno'));
      await tester.pump();
      expect(find.text('yogur griego'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(NutriMezzoApp(diario: diario));
      expect(find.text('yogur griego'), findsOneWidget);
    },
  );

  testDia('tocar un día en Cumplimiento reabre los Momentos de esa fecha', (
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
        Comida(
          id: 'c2',
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 7),
          renglones: [
            Renglon(
              nombre: 'yogur griego',
              cantidad: 200,
              alimentoId: yogur.id,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.text('Desayuno'));
    await tester.pump();
    expect(find.text('yogur griego'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cumplimiento'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('7 de septiembre, amarillo'));
    await tester.pumpAndSettle();

    expect(find.text('yogur griego'), findsOneWidget);
    expect(find.text('200 g'), findsOneWidget);
    expect(find.text('Calorías'), findsNothing);
  });

  testDia(
    'plegar un Momento no mueve el anillo; en uno abierto el Renglón sigue mostrando Macros',
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
        ],
      );
      await tester.pumpWidget(NutriMezzoApp(diario: diario));

      expect(find.text('97 / 2000 kcal'), findsOneWidget);
      expect(find.text('Calorías'), findsNothing);

      await tester.tap(find.text('yogur griego'));
      await tester.pumpAndSettle();
      expect(find.text('Calorías'), findsOneWidget);
      expect(find.text('10 g'), findsOneWidget);
      expect(find.text('97 / 2000 kcal'), findsOneWidget);

      await tester.tap(find.text('Desayuno'));
      await tester.pump();
      expect(find.text('Calorías'), findsNothing);
      expect(find.text('yogur griego'), findsNothing);
      expect(find.text('97 / 2000 kcal'), findsOneWidget);
    },
  );
}
