import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

import 'desactivar_animaciones.dart';
import 'opacidad.dart';

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

  testWidgets(
    'tocar un Renglón en el Día muestra sus Macros y no abre un editor',
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
      expect(find.text('97 kcal'), findsNothing);

      await tester.tap(find.text('yogur griego'));
      await tester.pumpAndSettle();

      expect(find.text('100 g'), findsOneWidget);
      expect(find.text('97 kcal'), findsOneWidget);
      expect(find.text('10 g'), findsOneWidget);
      expect(find.text('3.6 g'), findsOneWidget);
      expect(find.text('5 g'), findsOneWidget);
      expect(find.text('Calorías'), findsNWidgets(2));
      expect(find.text('Proteína (P)'), findsNWidgets(2));
      expect(find.text('Carbos (C)'), findsNWidgets(2));
      expect(find.text('Grasa (F)'), findsNWidgets(2));
      expect(find.text('97 / 2000 kcal'), findsOneWidget);
      expect(find.text('Borrar Renglón'), findsNothing);
      expect(find.text('Guardar'), findsNothing);
      expect(find.text('Cantidad'), findsNothing);
      expect(find.text('Alimento'), findsNothing);
    },
  );

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

  testWidgets(
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

  testWidgets('tocar la fecha o las barras de Meta no abre el detalle', (
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
    expect(find.text('97 kcal'), findsNothing);

    await tester.tap(find.text('Calorías'));
    await tester.pumpAndSettle();
    expect(find.text('97 kcal'), findsNothing);

    await tester.tap(find.byType(LinearProgressIndicator).first);
    await tester.pumpAndSettle();
    expect(find.text('97 kcal'), findsNothing);
    expect(find.text('97 / 2000 kcal'), findsOneWidget);
  });

  testWidgets(
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
      expect(opacidadDe(tester, find.text('97 kcal')), lessThan(1));

      await tester.pumpAndSettle();
      expect(opacidadDe(tester, find.text('97 kcal')), 1);
    },
  );

  testWidgets('disableAnimations muestra los Macros expandidos de inmediato', (
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
    expect(opacidadDe(tester, find.text('97 kcal')), 1);
  });

  testWidgets('cambiar de Día cierra el Renglón abierto', (tester) async {
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
    expect(find.text('97 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Día siguiente'));
    await tester.pump();

    expect(find.text('97 kcal'), findsNothing);
    expect(find.text('194 kcal'), findsNothing);
    expect(find.text('200 g'), findsOneWidget);
  });

  testWidgets('un Día pasado expande un Renglón igual que Hoy', (tester) async {
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
    expect(find.text('97 kcal'), findsOneWidget);
    expect(find.text('3.6 g'), findsOneWidget);
  });

  testWidgets('el menú del Día sigue borrando la Comida y uniendo Momentos', (
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
}
