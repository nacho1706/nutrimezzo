import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrimezzo/ajustes.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:nutrimezzo/home_dia.dart';
import 'package:nutrimezzo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'desactivar_animaciones.dart';

final _origen = Uri.parse('https://nutrimezzo.ejemplo.ts.net/');

/// Contract-following server that can be switched off.
class _Servidor {
  _Servidor() {
    final contrato = jsonDecode(
      File('contrato/diario.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    revision = contrato.remove('revision') as int;
    diario = contrato;
  }

  var encendido = true;
  int? respuestaPut;
  late int revision;
  late Map<String, dynamic> diario;
  final pedidos = <http.Request>[];

  late final cliente = MockClient((pedido) async {
    pedidos.add(pedido);
    if (!encendido) {
      throw http.ClientException('sin red');
    }
    if (pedido.method == 'GET' && pedido.url.path == '/api/diario') {
      return http.Response(jsonEncode({'revision': revision, ...diario}), 200);
    }
    if (pedido.method == 'GET' && pedido.url.path == '/api/revision') {
      return http.Response(jsonEncode({'revision': revision}), 200);
    }
    if (pedido.method == 'PUT') {
      final forzada = respuestaPut;
      if (forzada != null) {
        return http.Response(jsonEncode({'revision': revision}), forzada);
      }
      final cuerpo = jsonDecode(pedido.body) as Map<String, dynamic>;
      if (cuerpo.remove('revisionBase') != revision) {
        return http.Response(jsonEncode({'revision': revision}), 409);
      }
      diario = cuerpo;
      revision++;
      return http.Response(jsonEncode({'revision': revision}), 200);
    }
    return http.Response('', 404);
  });
}

Future<void> _montar(
  WidgetTester tester,
  _Servidor servidor, {
  required bool web,
}) async {
  desactivarAnimaciones(tester);
  await tester.pumpWidget(
    NutriMezzoRaiz(
      web: web,
      origen: _origen,
      cliente: servidor.cliente,
      ahora: () => DateTime(2026, 11, 17, 13),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _guardarMeta(WidgetTester tester, String kcal) async {
  await tester.tap(find.byTooltip('Ajustes'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), kcal);
  await tester.ensureVisible(find.text('Guardar'));
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('web abre el diario del servidor de su mismo origen', (
    tester,
  ) async {
    final servidor = _Servidor();

    await _montar(tester, servidor, web: true);

    expect(find.byType(HomeDia), findsOneWidget);
    expect(
      servidor.pedidos.first.url,
      Uri.parse('https://nutrimezzo.ejemplo.ts.net/api/diario'),
    );
    expect(find.bySemanticsLabel(RegExp(r'/ 2100(\.0)? kcal')), findsWidgets);
  });

  testWidgets(
    'sin servidor: pantalla de error con Reintentar, y reintentar abre el Día',
    (tester) async {
      final servidor = _Servidor()..encendido = false;

      await _montar(tester, servidor, web: true);

      expect(find.byType(HomeDia), findsNothing);
      expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
      expect(find.text('nutrimezzo.ejemplo.ts.net'), findsOneWidget);
      expect(find.text('¿Está Tailscale encendido?'), findsOneWidget);
      expect(find.text('Ajustes del servidor'), findsNothing);

      servidor.encendido = true;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeDia), findsOneWidget);
      expect(find.text('No se pudo conectar con el servidor'), findsNothing);
    },
  );

  testWidgets('Android sin Servidor abre el diario offline sin red', (
    tester,
  ) async {
    final servidor = _Servidor();

    await _montar(tester, servidor, web: false);

    expect(find.byType(HomeDia), findsOneWidget);
    expect(servidor.pedidos, isEmpty);
  });

  testWidgets(
    'Android sin servidor: Ajustes del servidor permite vaciar la URL y volver '
    'al diario offline, que sigue ahí',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'servidor.url': 'https://nutrimezzo.ejemplo.ts.net',
        'meta.kcal': 1500.0,
        'meta.proteina': 120.0,
        'meta.carbos': 150.0,
        'meta.grasa': 50.0,
      });
      final servidor = _Servidor()..encendido = false;

      await _montar(tester, servidor, web: false);

      expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
      await tester.tap(find.text('Ajustes del servidor'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'https://nutrimezzo.ejemplo.ts.net'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeDia), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'/ 1500(\.0)? kcal')), findsWidgets);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('servidor.url'), '');
    },
  );

  testWidgets('cambiar el Servidor en Ajustes reabre el diario en ese modo', (
    tester,
  ) async {
    final servidor = _Servidor();
    await _montar(tester, servidor, web: false);
    expect(servidor.pedidos, isEmpty);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL del servidor'),
      'https://nutrimezzo.ejemplo.ts.net',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeDia), findsOneWidget);
    expect(
      servidor.pedidos.single.url,
      Uri.parse('https://nutrimezzo.ejemplo.ts.net/api/diario'),
    );
    expect(find.bySemanticsLabel(RegExp(r'/ 2100(\.0)? kcal')), findsWidgets);
  });

  testWidgets('una URL inválida en Servidor no se guarda', (tester) async {
    final servidor = _Servidor();
    await _montar(tester, servidor, web: false);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL del servidor'),
      'nutrimezzo.local',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Tiene que ser una URL http:// o https://'), findsOne);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('servidor.url'), isNull);
  });

  testWidgets('un conflicto al guardar recarga desde el servidor y lo avisa', (
    tester,
  ) async {
    final servidor = _Servidor();
    await _montar(tester, servidor, web: true);
    servidor.revision = 8; // another device wrote

    await _guardarMeta(tester, '1800');

    expect(
      find.text(
        'Se actualizó desde otro dispositivo; repetí el último cambio.',
      ),
      findsOneWidget,
    );
    expect(find.byType(HomeDia), findsOneWidget);
    // The rejected Meta is not shown: the server's is.
    expect(find.bySemanticsLabel(RegExp(r'/ 2100(\.0)? kcal')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'/ 1800(\.0)? kcal')), findsNothing);
  });

  testWidgets('un fallo al guardar recarga desde el servidor y lo avisa', (
    tester,
  ) async {
    final servidor = _Servidor();
    await _montar(tester, servidor, web: true);
    servidor.respuestaPut = 500;

    await _guardarMeta(tester, '1800');

    expect(
      find.text('No se pudo guardar: sin conexión con el servidor.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'/ 2100(\.0)? kcal')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'/ 1800(\.0)? kcal')), findsNothing);
  });

  testWidgets('un fallo al guardar sin servidor al recargar muestra el error', (
    tester,
  ) async {
    final servidor = _Servidor();
    await _montar(tester, servidor, web: true);
    servidor.encendido = false;

    await _guardarMeta(tester, '1800');

    expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
  });

  testWidgets(
    'al volver a primer plano, si otro dispositivo escribió, recarga',
    (tester) async {
      final servidor = _Servidor();
      await _montar(tester, servidor, web: true);
      servidor.diario['meta'] = {
        'kcal': 1700,
        'proteina': 150,
        'carbos': 200,
        'grasa': 60,
      };
      servidor.revision = 8;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Actualizado desde otro dispositivo'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'/ 1700(\.0)? kcal')), findsWidgets);
    },
  );

  testWidgets('al volver a primer plano sin cambios, no recarga', (
    tester,
  ) async {
    final servidor = _Servidor();
    await _montar(tester, servidor, web: true);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(servidor.pedidos.last.url.path, '/api/revision');
    expect(
      servidor.pedidos.where((pedido) => pedido.url.path == '/api/diario'),
      hasLength(1),
    );
    expect(find.text('Actualizado desde otro dispositivo'), findsNothing);
  });

  group('Ajustes', () {
    Future<void> montarAjustes(WidgetTester tester, {required bool web}) {
      desactivarAnimaciones(tester);
      return tester.pumpWidget(
        MaterialApp(
          home: AjustesPagina(
            diario: Diario(),
            web: web,
            servidor: ServidorAjustable(url: '', cambiar: (_) {}),
          ),
        ),
      );
    }

    testWidgets('en Android muestra la sección Servidor', (tester) async {
      await montarAjustes(tester, web: false);

      expect(find.text('Servidor'), findsOneWidget);
      expect(find.text('Vacío = diario offline en este teléfono'), findsOne);
    });

    testWidgets('en web no muestra la sección Servidor', (tester) async {
      await montarAjustes(tester, web: true);

      expect(find.text('Servidor'), findsNothing);
      expect(
        find.widgetWithText(TextFormField, 'URL del servidor'),
        findsNothing,
      );
    });
  });
}
