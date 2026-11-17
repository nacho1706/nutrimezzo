// Run: mise exec -- flutter test tool/capturas/capturas_test.dart  → PNGs in build/capturas/
//
// Design-review screenshots of every screen in light and dark, with real fonts
// and icons. Not part of the normal suite (lives outside test/).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/main.dart';

const _anchoLogico = 412.0;
const _altoLogico = 915.0;
const _densidad = 2.625;
final _claveCaptura = GlobalKey();

Future<void> _cargarFuentes() async {
  final manifiesto = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entrada in manifiesto.cast<Map<String, dynamic>>()) {
    final cargador = FontLoader(entrada['family'] as String);
    for (final fuente in (entrada['fonts'] as List<dynamic>)) {
      final asset = (fuente as Map<String, dynamic>)['asset'] as String;
      cargador.addFont(rootBundle.load(asset));
    }
    await cargador.load();
  }
}

DateTime _d(int mes, int dia) => DateTime(2026, mes, dia);

Alimento _alimento(String id, String nombre, Macros macros) => Alimento(
  id: id,
  nombre: nombre,
  macrosPor100g: macros,
  patron: nombre,
  usadoPorUltimaVez: DateTime(2026, 9, 5, 12),
);

final _avena = _alimento(
  'a1',
  'avena',
  const Macros(kcal: 389, proteina: 13.2, carbos: 66, grasa: 6.9),
);
final _yogur = _alimento(
  'a2',
  'yogur griego',
  const Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5),
);
final _banana = _alimento(
  'a3',
  'banana',
  const Macros(kcal: 89, proteina: 1.1, carbos: 23, grasa: 0.3),
);
final _pollo = _alimento(
  'a4',
  'pechuga de pollo',
  const Macros(kcal: 165, proteina: 31, carbos: 0, grasa: 3.6),
);
final _arroz = _alimento(
  'a5',
  'arroz blanco cocido',
  const Macros(kcal: 130, proteina: 2.7, carbos: 28, grasa: 0.3),
);
final _aceite = _alimento(
  'a6',
  'aceite de oliva',
  const Macros(kcal: 884, proteina: 0, carbos: 0, grasa: 100),
);

Renglon _r(Alimento alimento, num gramos) =>
    Renglon(nombre: alimento.nombre, cantidad: gramos, alimentoId: alimento.id);

Comida _comida(String id, Momento momento, DateTime fecha, List<Renglon> r) =>
    Comida(id: id, momento: momento, fecha: fecha, renglones: r);

Diario _diario() {
  return Diario(
    ahora: () => DateTime(2026, 9, 6, 13, 30),
    busquedaIA: _BusquedaIAFalsa({
      'yogur griego': [
        const Propuesta(
          nombre: 'Yogur natural entero',
          macrosPor100g: Macros(
            kcal: 61,
            proteina: 3.5,
            carbos: 4.7,
            grasa: 3.3,
          ),
        ),
      ],
    }),
    alimentos: [_avena, _yogur, _banana, _pollo, _arroz, _aceite],
    comidas: [
      // Hoy (domingo 6): ~1180 kcal of 2000.
      _comida('c1', Momento.desayuno, _d(9, 6), [
        _r(_avena, 60),
        _r(_yogur, 200),
        _r(_banana, 120),
      ]),
      _comida('c2', Momento.almuerzo, _d(9, 6), [
        _r(_pollo, 180),
        _r(_arroz, 200),
        _r(_aceite, 10),
      ]),
      // The month: verde / amarillo / rojo.
      _comida('c3', Momento.almuerzo, _d(9, 1), [_r(_pollo, 500)]),
      _comida('c4', Momento.desayuno, _d(9, 2), [_r(_banana, 300)]),
      _comida('c5', Momento.almuerzo, _d(9, 3), [
        _r(_pollo, 520),
        _r(_arroz, 250),
      ]),
      _comida('c6', Momento.cena, _d(9, 4), [_r(_aceite, 240)]),
      _comida('c7', Momento.desayuno, _d(9, 5), [
        _r(_avena, 80),
        _r(_yogur, 150),
      ]),
      _comida('c8', Momento.cena, _d(8, 28), [_r(_pollo, 490)]),
      _comida('c9', Momento.cena, _d(8, 30), [_r(_aceite, 250)]),
    ],
    pesajes: [
      Pesaje(fecha: _d(8, 24), kilogramos: 73.4),
      Pesaje(fecha: _d(8, 27), kilogramos: 73.1),
      Pesaje(fecha: _d(8, 30), kilogramos: 72.9),
      Pesaje(fecha: _d(9, 1), kilogramos: 72.4),
      Pesaje(fecha: _d(9, 3), kilogramos: 72.0),
      Pesaje(fecha: _d(9, 5), kilogramos: 71.9),
    ],
  );
}

Future<void> _abrir(WidgetTester tester, Diario diario) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _claveCaptura,
      child: NutriMezzoApp(diario: diario),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _destino(WidgetTester tester, String etiqueta) => _tocar(
  tester,
  find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(etiqueta),
  ),
);

Future<void> _capturar(WidgetTester tester, String archivo) async {
  await tester.pumpAndSettle();
  final frontera =
      _claveCaptura.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final imagen = await frontera.toImage(pixelRatio: _densidad);
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    final destino = File('build/capturas/$archivo.png');
    await destino.parent.create(recursive: true);
    await destino.writeAsBytes(bytes!.buffer.asUint8List());
    imagen.dispose();
  });
}

final _pantallas = <String, Future<void> Function(WidgetTester)>{
  'dia': (tester) async {
    await _abrir(tester, _diario());
  },
  'dia_comidas': (tester) async {
    await _abrir(tester, _diario());
    await _tocar(tester, find.text('Desayuno'));
    await tester.ensureVisible(find.text('arroz blanco cocido'));
    await _tocar(tester, find.text('arroz blanco cocido'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
  },
  'dia_vacio': (tester) async {
    await _abrir(tester, _diario());
    await _tocar(tester, find.byTooltip('Día siguiente'));
  },
  'cumplimiento': (tester) async {
    await _abrir(tester, _diario());
    await _destino(tester, 'Cumplimiento');
  },
  'pesaje': (tester) async {
    await _abrir(tester, _diario());
    await _destino(tester, 'Pesaje');
  },
  'captura': (tester) async {
    await _abrir(tester, _diario());
    await _tocar(tester, find.text('Comida'));
    await _tocar(tester, find.widgetWithText(ChoiceChip, 'Cena'));
    await tester.enterText(
      find.byType(TextField).last,
      '150g salmón\n200g papa al horno\nensalada verde',
    );
    await tester.pumpAndSettle();
  },
  'confirmacion': (tester) async {
    await _abrir(tester, _diario());
    await _tocar(tester, find.text('Comida'));
    await _tocar(tester, find.widgetWithText(ChoiceChip, 'Cena'));
    await tester.enterText(
      find.byType(TextField).last,
      '200g yogur griego\n120g tarta de ricota',
    );
    await tester.pumpAndSettle();
    await _tocar(tester, find.text('Listo'));
  },
  'captura_previos': (tester) async {
    await _abrir(tester, _diario());
    await _tocar(tester, find.text('Comida'));
  },
  'editor': (tester) async {
    await _abrir(tester, _diario());
    await _tocar(tester, find.byTooltip('Catálogo'));
    await _tocar(tester, find.text('yogur griego'));
  },
  'catalogo': (tester) async {
    await _abrir(tester, _diario());
    await _tocar(tester, find.byTooltip('Catálogo'));
  },
  'ajustes': (tester) async {
    await _abrir(tester, _diario());
    await _tocar(tester, find.byTooltip('Ajustes'));
  },
};

void main() {
  setUpAll(_cargarFuentes);

  for (final modo in const {
    'claro': Brightness.light,
    'oscuro': Brightness.dark,
  }.entries) {
    for (final pantalla in _pantallas.entries) {
      testWidgets('${pantalla.key}_${modo.key}', (tester) async {
        tester.view.physicalSize = const Size(
          _anchoLogico * _densidad,
          _altoLogico * _densidad,
        );
        tester.view.devicePixelRatio = _densidad;
        tester.platformDispatcher.platformBrightnessTestValue = modo.value;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);

        await pantalla.value(tester);
        await _capturar(tester, '${pantalla.key}_${modo.key}');
      });
    }
  }
}

class _BusquedaIAFalsa implements PuertoBusquedaIA {
  _BusquedaIAFalsa(this.porNombre);

  final Map<String, List<Propuesta>> porNombre;

  @override
  Future<List<Propuesta>> buscar(Renglon renglon) async =>
      List.of(porNombre[renglon.nombre] ?? const []);
}
