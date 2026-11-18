import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrimezzo/almacen_ajustes.dart';
import 'package:nutrimezzo/almacen_remoto.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _api = Uri.parse('https://nutrimezzo.ejemplo.ts.net/api/');
DateTime _ahora() => DateTime(2026, 11, 17, 13);

const _byok = {
  'byok.urlBase': 'https://ia.ejemplo.com/v1',
  'byok.claveApi': 'sk-secreto-123',
  'byok.idModelo': 'modelo-x',
};

/// In-memory server that follows contrato/README.md.
class _ServidorFalso {
  _ServidorFalso() {
    final contrato = jsonDecode(
      File('contrato/diario.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    revision = contrato.remove('revision') as int;
    diario = contrato;
  }

  late int revision;
  late Map<String, dynamic> diario;
  final pedidos = <http.Request>[];

  /// Overrides the answer to PUT (the request is still recorded).
  Future<http.Response> Function(http.Request pedido)? alPut;

  List<Map<String, dynamic>> get puts => [
    for (final pedido in pedidos)
      if (pedido.method == 'PUT')
        jsonDecode(pedido.body) as Map<String, dynamic>,
  ];

  late final cliente = MockClient((pedido) async {
    pedidos.add(pedido);
    final ruta = pedido.url.path;
    if (pedido.method == 'GET' && ruta == '/api/diario') {
      return http.Response(jsonEncode({'revision': revision, ...diario}), 200);
    }
    if (pedido.method == 'GET' && ruta == '/api/revision') {
      return http.Response(jsonEncode({'revision': revision}), 200);
    }
    if (pedido.method == 'PUT' && ruta == '/api/diario') {
      final especial = alPut;
      if (especial != null) {
        return especial(pedido);
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

  Future<AlmacenRemoto> abrir({Duration? espera}) => abrirDiarioRemoto(
    api: _api,
    cliente: cliente,
    ahora: _ahora,
    espera: espera ?? const Duration(seconds: 10),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('abre el Diario desde el servidor y recuerda la revisión', () async {
    final servidor = _ServidorFalso();

    final almacen = await servidor.abrir();
    final diario = almacen.diario;

    expect(almacen.revision, 7);
    expect(diario.meta.macros.kcal, 2100);
    expect(diario.alimentos.map((a) => a.nombre), ['Banana', 'Huevo']);
    expect(diario.dia(DateTime(2026, 11, 17)).comidas.single.id, 'c1');
    expect(diario.pesajeDe(DateTime(2026, 11, 17))!.kilogramos, 78.4);
    expect(servidor.pedidos.single.url, _api.resolve('diario'));
  });

  test('un servidor sin Meta deja la Meta por defecto', () async {
    final servidor = _ServidorFalso()..diario['meta'] = null;

    final almacen = await servidor.abrir();

    expect(almacen.diario.meta.macros.kcal, Meta.porDefecto.macros.kcal);
  });

  test('el BYOK sale del teléfono, no del servidor', () async {
    SharedPreferences.setMockInitialValues(_byok);
    final servidor = _ServidorFalso();

    final almacen = await servidor.abrir();

    expect(almacen.diario.byok.claveApi, 'sk-secreto-123');
    expect(almacen.diario.byok.idModelo, 'modelo-x');
  });

  test(
    'si el servidor no responde 200, abrir falla con FalloServidor',
    () async {
      final cliente = MockClient((_) async => http.Response('', 502));

      expect(
        abrirDiarioRemoto(api: _api, cliente: cliente),
        throwsA(isA<FalloServidor>()),
      );
    },
  );

  test('sin red, abrir falla con FalloServidor', () async {
    final cliente = MockClient((_) async => throw http.ClientException('x'));

    expect(
      abrirDiarioRemoto(api: _api, cliente: cliente),
      throwsA(isA<FalloServidor>()),
    );
  });

  test('confirmar una Comida manda la foto entera con revisionBase', () async {
    final servidor = _ServidorFalso();
    final almacen = await servidor.abrir();
    final diario = almacen.diario;

    diario.redactarComida(momento: Momento.almuerzo, notas: '120g banana');
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 120,
        propuesta: diario.resoluciones.single.propuestas.first,
      ),
    ]);

    final put = servidor.puts.single;
    expect(put['revisionBase'], 7);
    expect(put.containsKey('revision'), isFalse);
    expect(put['meta'], {
      'kcal': 2100,
      'proteina': 160,
      'carbos': 230,
      'grasa': 70,
    });
    final comidas = put['comidas'] as List<dynamic>;
    final almuerzo = comidas.singleWhere(
      (comida) => comida['momento'] == 'almuerzo',
    );
    expect(almuerzo['fecha'], '2026-11-17');
    expect(almuerzo['renglones'], [
      {'nombre': 'Banana', 'cantidad': 120, 'alimentoId': 'a1'},
    ]);
    expect(comidas, hasLength(3));
    expect(put['alimentos'], hasLength(2));
    expect(put['pesajes'], hasLength(2));
    expect(almacen.revision, 8);
  });

  test('guardar un Pesaje hace PUT y avanza la revisión', () async {
    final servidor = _ServidorFalso();
    final almacen = await servidor.abrir();

    await almacen.diario.guardarPesaje(
      fecha: DateTime(2026, 11, 18),
      kilogramos: 78.1,
    );
    await almacen.diario.guardarPesaje(
      fecha: DateTime(2026, 11, 18),
      kilogramos: 78,
    );

    expect(servidor.puts.map((put) => put['revisionBase']), [7, 8]);
    expect(
      servidor.puts.last['pesajes'],
      contains(equals({'fecha': '2026-11-18', 'kilogramos': 78})),
    );
    expect(almacen.revision, 9);
  });

  test('guardar la Meta manda la Meta nueva', () async {
    final servidor = _ServidorFalso();
    final almacen = await servidor.abrir();

    await almacen.diario.guardarMeta(
      const Meta(
        macros: Macros(kcal: 1900, proteina: 150, carbos: 200, grasa: 60),
      ),
    );

    expect(servidor.puts.single['meta'], {
      'kcal': 1900,
      'proteina': 150,
      'carbos': 200,
      'grasa': 60,
    });
    expect(servidor.puts.single['revisionBase'], 7);
  });

  test(
    'guardar solo el BYOK no toca el servidor y queda en el teléfono',
    () async {
      final servidor = _ServidorFalso();
      final almacen = await servidor.abrir();
      final pedidosAlAbrir = servidor.pedidos.length;

      await almacen.diario.guardarByok(
        const Byok(
          urlBase: 'https://ia.ejemplo.com/v1',
          claveApi: 'sk-secreto-123',
          idModelo: 'modelo-x',
        ),
      );

      expect(servidor.pedidos, hasLength(pedidosAlAbrir));
      final prefs = await SharedPreferences.getInstance();
      expect(byokDe(prefs).claveApi, 'sk-secreto-123');
      expect(byokDe(prefs).urlBase, 'https://ia.ejemplo.com/v1');
    },
  );

  test('ningún pedido lleva el BYOK', () async {
    SharedPreferences.setMockInitialValues(_byok);
    final servidor = _ServidorFalso();
    final almacen = await servidor.abrir();
    final diario = almacen.diario;

    // Ajustes saves both in a row; the Meta one PUTs, the BYOK one doesn't.
    await diario.guardarMeta(
      const Meta(
        macros: Macros(kcal: 1900, proteina: 150, carbos: 200, grasa: 60),
      ),
    );
    await diario.guardarByok(
      const Byok(
        urlBase: 'https://otra.ejemplo.com/v1',
        claveApi: 'sk-otra-456',
        idModelo: 'modelo-y',
      ),
    );
    await diario.guardarPesaje(fecha: DateTime(2026, 11, 18), kilogramos: 78);

    expect(servidor.puts, hasLength(2));
    for (final pedido in servidor.pedidos) {
      final todo = '${pedido.url} ${pedido.headers} ${pedido.body}';
      for (final prohibido in [
        'byok',
        'urlBase',
        'claveApi',
        'idModelo',
        ..._byok.values,
        'otra.ejemplo.com',
        'sk-otra-456',
        'modelo-y',
      ]) {
        expect(todo, isNot(contains(prohibido)));
      }
    }
    for (final put in servidor.puts) {
      expect(
        put.keys,
        unorderedEquals([
          'revisionBase',
          'meta',
          'alimentos',
          'comidas',
          'pesajes',
        ]),
      );
    }
  });

  test('409 emite conflicto y deja de escribir', () async {
    final servidor = _ServidorFalso();
    final almacen = await servidor.abrir();
    final eventos = <EventoSincronizacion>[];
    almacen.eventos.listen(eventos.add);
    servidor.revision = 9; // another device wrote twice

    await almacen.diario.guardarPesaje(
      fecha: DateTime(2026, 11, 18),
      kilogramos: 78,
    );
    await almacen.diario.guardarPesaje(
      fecha: DateTime(2026, 11, 19),
      kilogramos: 77.9,
    );
    await pumpEventQueue();

    expect(eventos, [EventoSincronizacion.conflicto]);
    expect(servidor.puts, hasLength(1));
    expect(almacen.revision, 7);
  });

  test('sin red, una escritura emite fallo', () async {
    final servidor = _ServidorFalso()
      ..alPut = (_) async => throw http.ClientException('sin red');
    final almacen = await servidor.abrir();
    final eventos = <EventoSincronizacion>[];
    almacen.eventos.listen(eventos.add);

    await almacen.diario.guardarPesaje(
      fecha: DateTime(2026, 11, 18),
      kilogramos: 78,
    );
    await pumpEventQueue();

    expect(eventos, [EventoSincronizacion.fallo]);
  });

  test('un 5xx o un 400 emiten fallo', () async {
    for (final codigo in [500, 503, 400]) {
      final servidor = _ServidorFalso()
        ..alPut = (_) async => http.Response('{"error":"x"}', codigo);
      final almacen = await servidor.abrir();
      final eventos = <EventoSincronizacion>[];
      almacen.eventos.listen(eventos.add);

      await almacen.diario.guardarPesaje(
        fecha: DateTime(2026, 11, 18),
        kilogramos: 78,
      );
      await pumpEventQueue();

      expect(eventos, [EventoSincronizacion.fallo], reason: '$codigo');
    }
  });

  test('si el servidor no contesta a tiempo, emite fallo', () async {
    final servidor = _ServidorFalso()
      ..alPut = (_) => Completer<http.Response>().future;
    final almacen = await servidor.abrir(
      espera: const Duration(milliseconds: 20),
    );
    final eventos = <EventoSincronizacion>[];
    almacen.eventos.listen(eventos.add);

    await almacen.diario.guardarPesaje(
      fecha: DateTime(2026, 11, 18),
      kilogramos: 78,
    );
    await pumpEventQueue();

    expect(eventos, [EventoSincronizacion.fallo]);
  });

  test(
    'las escrituras van de a una y las que esperan se juntan en la última',
    () async {
      final servidor = _ServidorFalso();
      final almacen = await servidor.abrir();
      final diario = almacen.diario;
      final liberar = Completer<void>();
      var enVuelo = 0;
      var maximo = 0;
      servidor.alPut = (pedido) async {
        enVuelo++;
        if (enVuelo > maximo) maximo = enVuelo;
        if (servidor.puts.length == 1) {
          await liberar.future;
        }
        final cuerpo = jsonDecode(pedido.body) as Map<String, dynamic>;
        servidor.revision = (cuerpo['revisionBase'] as int) + 1;
        enVuelo--;
        return http.Response(jsonEncode({'revision': servidor.revision}), 200);
      };

      final escrituras = [
        diario.guardarPesaje(fecha: DateTime(2026, 11, 18), kilogramos: 78),
        diario.guardarPesaje(fecha: DateTime(2026, 11, 19), kilogramos: 77.9),
        diario.guardarPesaje(fecha: DateTime(2026, 11, 20), kilogramos: 77.8),
      ];
      await pumpEventQueue();
      expect(servidor.puts, hasLength(1));
      expect(almacen.escribiendo, isTrue);

      liberar.complete();
      await Future.wait(escrituras);

      expect(maximo, 1);
      expect(servidor.puts, hasLength(2));
      expect(servidor.puts.map((put) => put['revisionBase']), [7, 8]);
      final ultimos = servidor.puts.last['pesajes'] as List<dynamic>;
      expect(
        ultimos,
        contains(equals({'fecha': '2026-11-20', 'kilogramos': 77.8})),
      );
      expect(ultimos, hasLength(5));
      expect(almacen.revision, 9);
      expect(almacen.escribiendo, isFalse);
    },
  );

  test('revisionRemota lee GET /api/revision', () async {
    final servidor = _ServidorFalso();
    final almacen = await servidor.abrir();
    servidor.revision = 12;

    expect(await almacen.revisionRemota(), 12);
    expect(servidor.pedidos.last.url, _api.resolve('revision'));
  });
}
