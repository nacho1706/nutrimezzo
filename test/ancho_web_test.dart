import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/main.dart';

const _contenido = Key('contenido');

Future<void> _montar(WidgetTester tester, Size tamano, {required bool web}) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => ColumnaWeb(web: web, child: child!),
      home: const SizedBox.expand(key: _contenido),
    ),
  );
}

double _anchoMediaQuery(WidgetTester tester) =>
    MediaQuery.sizeOf(tester.element(find.byKey(_contenido))).width;

void main() {
  testWidgets('web en ventana ancha: columna centrada de 480', (tester) async {
    await _montar(tester, const Size(1400, 900), web: true);

    expect(tester.getSize(find.byKey(_contenido)), const Size(480, 900));
    expect(tester.getTopLeft(find.byKey(_contenido)).dx, (1400 - 480) / 2);
    expect(_anchoMediaQuery(tester), 480);
  });

  testWidgets('web en ventana angosta: ancho completo', (tester) async {
    await _montar(tester, const Size(400, 800), web: true);

    expect(tester.getSize(find.byKey(_contenido)), const Size(400, 800));
    expect(_anchoMediaQuery(tester), 400);
  });

  testWidgets('fuera de web en ventana ancha: ancho completo', (tester) async {
    await _montar(tester, const Size(1400, 900), web: false);

    expect(tester.getSize(find.byKey(_contenido)), const Size(1400, 900));
    expect(_anchoMediaQuery(tester), 1400);
  });
}
