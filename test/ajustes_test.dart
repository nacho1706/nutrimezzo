import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

void main() {
  testWidgets('guardar Meta en Ajustes actualiza los denominadores de Hoy', (
    tester,
  ) async {
    await tester.pumpWidget(NutriMezzoApp(diario: Diario()));

    expect(find.text('0 / 2000 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '1800');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 1800 kcal'), findsOneWidget);
    expect(find.text('0 / 2000 kcal'), findsNothing);
  });

  testWidgets('guardar y borrar BYOK queda en el Diario, sin HTTP', (
    tester,
  ) async {
    final diario = Diario();
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(4),
      'https://api.ejemplo.com/v1',
    );
    await tester.enterText(find.byType(TextFormField).at(5), 'sk-secreto');
    await tester.enterText(find.byType(TextFormField).at(6), 'gpt-4o-mini');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(diario.byok.urlBase, 'https://api.ejemplo.com/v1');
    expect(diario.byok.claveApi, 'sk-secreto');
    expect(diario.byok.idModelo, 'gpt-4o-mini');

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Borrar BYOK'));
    await tester.tap(find.text('Borrar BYOK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(diario.byok.urlBase, '');
    expect(diario.byok.claveApi, '');
    expect(diario.byok.idModelo, '');
  });

  testWidgets('Ajustes se puede guardar con BYOK en blanco', (tester) async {
    final diario = Diario();
    await tester.pumpWidget(NutriMezzoApp(diario: diario));

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 2000 kcal'), findsOneWidget);
    expect(diario.byok.urlBase, '');
    expect(diario.byok.claveApi, '');
    expect(diario.byok.idModelo, '');
  });
}
