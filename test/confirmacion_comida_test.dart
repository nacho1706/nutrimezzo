import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

void main() {
  testWidgets('Listo muestra la Propuesta local y Confirmar actualiza Hoy', (
    tester,
  ) async {
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

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '100g yogur griego');
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmación'), findsOneWidget);
    expect(find.text('yogur griego'), findsWidgets);
    expect(find.text('100'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('97 / 2000 kcal'), findsOneWidget);
    expect(find.text('Desayuno'), findsOneWidget);
  });

  testWidgets('sin match se crea un Alimento con macros y gramos, no 0 g', (
    tester,
  ) async {
    final diario = Diario();
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'banana chica');
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Alimento'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Banana',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calorías'),
      '89',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Proteína (P)'),
      '1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carbos (C)'),
      '23',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Grasa (F)'),
      '0.3',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Gramos'), '110');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
    expect(diario.alimentos.single.nombre, 'Banana');
    expect(diario.hoy().comidas.single.renglones.single.cantidad, 110);
    expect(find.textContaining('0 / 2000 kcal'), findsNothing);
  });

  testWidgets('la Propuesta IA muestra gramos asumidos y se pueden editar', (
    tester,
  ) async {
    final diario = Diario(
      busquedaIA: _PuertoBusquedaIAFalso({
        'banana chica': [
          const Propuesta(
            nombre: 'Banana',
            macrosPor100g: Macros(
              kcal: 89,
              proteina: 1,
              carbos: 23,
              grasa: 0.3,
            ),
            gramosAsumidos: 120,
          ),
        ],
      }),
    );
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'banana chica');
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('gramos asumidos'), findsOneWidget);
    final gramos = find.widgetWithText(TextFormField, 'Gramos');
    expect(tester.widget<TextFormField>(gramos).controller?.text, '120');

    await tester.enterText(gramos, '90');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(diario.hoy().comidas.single.renglones.single.cantidad, 90);
    expect(diario.alimentos.single.nombre, 'Banana');
  });
}

class _PuertoBusquedaIAFalso implements PuertoBusquedaIA {
  _PuertoBusquedaIAFalso(this.porNombre);

  final Map<String, List<Propuesta>> porNombre;

  @override
  Future<List<Propuesta>> buscar(Renglon renglon) async {
    return List.of(porNombre[renglon.nombre] ?? const []);
  }
}
