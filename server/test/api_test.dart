import 'dart:convert';
import 'dart:io';

import 'package:nutrimezzo_server/nutrimezzo_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// `dart test` corre desde `server/`; el contrato vive al lado.
final contrato =
    jsonDecode(File('../contrato/diario.json').readAsStringSync())
        as Map<String, Object?>;

/// El fixture como cuerpo de PUT: `revisionBase` en lugar de `revision`.
Map<String, Object?> cuerpoPut(int revisionBase, [Map<String, Object?>? base]) {
  final copia = _copiar(base ?? contrato);
  copia.remove('revision');
  copia['revisionBase'] = revisionBase;
  return copia;
}

Map<String, Object?> _copiar(Map<String, Object?> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, Object?>;

Map<String, Object?> sinRevision(Map<String, Object?> m) =>
    Map.of(m)..remove('revision');

class Cliente {
  Cliente(this.handler);
  final Handler handler;

  Future<(int, Map<String, Object?>)> pedir(
    String metodo,
    String ruta, {
    Object? cuerpo,
    String? texto,
  }) async {
    final respuesta = await handler(
      Request(
        metodo,
        Uri.parse('http://localhost$ruta'),
        body: texto ?? (cuerpo == null ? null : jsonEncode(cuerpo)),
        headers: {'content-type': 'application/json'},
      ),
    );
    expect(respuesta.headers['content-type'], startsWith('application/json'));
    expect(respuesta.headers['cache-control'], 'no-store');
    final json = jsonDecode(await respuesta.readAsString());
    return (respuesta.statusCode, json as Map<String, Object?>);
  }

  Future<(int, Map<String, Object?>)> get(String ruta) => pedir('GET', ruta);
  Future<(int, Map<String, Object?>)> put(Object? cuerpo) =>
      pedir('PUT', '/api/diario', cuerpo: cuerpo);
}

/// Compara estado y cuerpo JSON (los records comparan mapas por identidad).
void esperar((int, Map<String, Object?>) r, int status, Object? json) {
  expect(r.$1, status);
  expect(r.$2, json);
}

void main() {
  late Directory dir;
  late String ruta;
  late AlmacenDiario almacen;
  late Cliente api;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nutrimezzo_server_test');
    ruta = '${dir.path}/nutrimezzo.db';
    almacen = AlmacenDiario.abrir(ruta);
    api = Cliente(crearHandler(almacen));
  });

  tearDown(() {
    almacen.cerrar();
    dir.deleteSync(recursive: true);
  });

  test('salud', () async {
    esperar(await api.get('/api/salud'), 200, {'ok': true});
  });

  test('un servidor nuevo: revisión 0, meta null, listas vacías', () async {
    esperar(await api.get('/api/revision'), 200, {'revision': 0});
    esperar(await api.get('/api/diario'), 200, {
      'revision': 0,
      'meta': null,
      'alimentos': <Object?>[],
      'comidas': <Object?>[],
      'pesajes': <Object?>[],
    });
  });

  test('PUT del contrato y GET devuelve lo mismo', () async {
    esperar(await api.put(cuerpoPut(0)), 200, {'revision': 1});
    final (status, diario) = await api.get('/api/diario');
    expect(status, 200);
    expect(diario['revision'], 1);
    expect(sinRevision(diario), sinRevision(contrato));
    // Mismo texto JSON: los enteros siguen siendo enteros, el orden se respeta.
    expect(jsonEncode(sinRevision(diario)), jsonEncode(sinRevision(contrato)));
    esperar(await api.get('/api/revision'), 200, {'revision': 1});
  });

  test(
    'revisionBase vieja: 409 con la revisión actual y nada cambia',
    () async {
      await api.put(cuerpoPut(0));
      final otro = cuerpoPut(0)..['pesajes'] = <Object?>[];
      esperar(await api.put(otro), 409, {'revision': 1});
      esperar(await api.put(cuerpoPut(5)), 409, {'revision': 1});
      final (_, diario) = await api.get('/api/diario');
      expect(sinRevision(diario), sinRevision(contrato));
    },
  );

  test('PUT reemplaza todo y la revisión avanza', () async {
    await api.put(cuerpoPut(0));
    final vacio = {
      'revisionBase': 1,
      'meta': null,
      'alimentos': <Object?>[],
      'comidas': <Object?>[],
      'pesajes': <Object?>[],
    };
    esperar(await api.put(vacio), 200, {'revision': 2});
    final (_, diario) = await api.get('/api/diario');
    expect(diario, {...vacio..remove('revisionBase'), 'revision': 2});
  });

  test('persiste al reabrir el archivo', () async {
    await api.put(cuerpoPut(0));
    almacen.cerrar();
    almacen = AlmacenDiario.abrir(ruta);
    api = Cliente(crearHandler(almacen));
    final (_, diario) = await api.get('/api/diario');
    expect(diario['revision'], 1);
    expect(sinRevision(diario), sinRevision(contrato));
  });

  test('cuerpo de más de 10 MB: 413', () async {
    final relleno = 'x' * (limiteCuerpo + 1);
    final (status, json) = await api.pedir(
      'PUT',
      '/api/diario',
      texto: relleno,
    );
    expect(status, 413);
    expect(json['error'], isA<String>());
  });

  test('límite configurable, también sin content-length', () async {
    final chico = Cliente(crearHandler(almacen, limite: 100));
    final respuesta = await chico.handler(
      Request(
        'PUT',
        Uri.parse('http://localhost/api/diario'),
        body: Stream.value(utf8.encode(jsonEncode(cuerpoPut(0)))),
      ),
    );
    expect(respuesta.statusCode, 413);
  });

  test('ruta desconocida: 404', () async {
    expect((await api.get('/api/nada')).$1, 404);
    expect((await api.get('/')).$1, 404);
    expect((await api.pedir('POST', '/api/diario', cuerpo: {})).$1, 404);
  });

  group('400', () {
    Future<void> rechaza(
      String motivo,
      void Function(Map<String, Object?> c) romper,
    ) async {
      final c = cuerpoPut(0);
      romper(c);
      final (status, json) = await api.put(c);
      expect(status, 400, reason: motivo);
      expect(json['error'], isA<String>(), reason: motivo);
      // Nada se escribió.
      esperar(await api.get('/api/revision'), 200, {'revision': 0});
    }

    List<Map<String, Object?>> lista(Map<String, Object?> c, String k) =>
        (c[k] as List).cast<Map<String, Object?>>();

    test('JSON roto', () async {
      final (status, _) = await api.pedir(
        'PUT',
        '/api/diario',
        texto: '{"revisionBase":',
      );
      expect(status, 400);
    });

    test('no es un objeto', () async {
      expect((await api.put([1, 2])).$1, 400);
    });

    test('invariantes del contrato', () async {
      await rechaza('id de Alimento repetido', (c) {
        lista(c, 'alimentos')[1]['id'] = 'a1';
      });
      await rechaza('id de Comida repetido', (c) {
        lista(c, 'comidas')[1]['id'] = 'c1';
      });
      await rechaza('misma fecha + momento', (c) {
        lista(c, 'comidas')[1]
          ..['fecha'] = '2026-11-17'
          ..['momento'] = 'desayuno';
      });
      await rechaza('dos Pesajes en la misma fecha', (c) {
        lista(c, 'pesajes')[1]['fecha'] = '2026-11-17';
      });
      await rechaza('kilogramos 0', (c) {
        lista(c, 'pesajes')[0]['kilogramos'] = 0;
      });
      await rechaza('kilogramos negativos', (c) {
        lista(c, 'pesajes')[0]['kilogramos'] = -1.5;
      });
    });

    test('tipos, requeridos, enums y fechas', () async {
      await rechaza('sin revisionBase', (c) => c.remove('revisionBase'));
      await rechaza('revisionBase texto', (c) => c['revisionBase'] = '0');
      await rechaza('revisionBase negativa', (c) => c['revisionBase'] = -1);
      await rechaza('revisionBase double', (c) => c['revisionBase'] = 0.5);
      await rechaza('meta no objeto', (c) => c['meta'] = 3);
      await rechaza('meta sin kcal', (c) {
        (c['meta'] as Map).remove('kcal');
      });
      await rechaza('sin alimentos', (c) => c.remove('alimentos'));
      await rechaza('comidas no lista', (c) => c['comidas'] = {});
      await rechaza('pesajes null', (c) => c['pesajes'] = null);
      await rechaza('kcal texto', (c) {
        lista(c, 'alimentos')[0]['kcal'] = '89';
      });
      await rechaza('alimento sin nombre', (c) {
        lista(c, 'alimentos')[0].remove('nombre');
      });
      await rechaza('alimento id vacío', (c) {
        lista(c, 'alimentos')[0]['id'] = '';
      });
      await rechaza('usadoPorUltimaVez no ISO', (c) {
        lista(c, 'alimentos')[0]['usadoPorUltimaVez'] = 'ayer';
      });
      await rechaza('momento desconocido', (c) {
        lista(c, 'comidas')[0]['momento'] = 'merienda';
      });
      await rechaza('fecha con otro formato', (c) {
        lista(c, 'comidas')[0]['fecha'] = '17/11/2026';
      });
      await rechaza('fecha inexistente', (c) {
        lista(c, 'comidas')[0]['fecha'] = '2026-02-30';
      });
      await rechaza('fecha con hora', (c) {
        lista(c, 'pesajes')[0]['fecha'] = '2026-11-17T00:00:00';
      });
      await rechaza('recibidoPorUltimaVez no texto', (c) {
        lista(c, 'comidas')[0]['recibidoPorUltimaVez'] = 1;
      });
      await rechaza('renglones no lista', (c) {
        lista(c, 'comidas')[0]['renglones'] = null;
      });
      await rechaza('cantidad texto', (c) {
        (lista(c, 'comidas')[0]['renglones'] as List)[0]['cantidad'] = '90';
      });
      await rechaza('alimentoId número', (c) {
        (lista(c, 'comidas')[0]['renglones'] as List)[0]['alimentoId'] = 1;
      });
      await rechaza('kilogramos texto', (c) {
        lista(c, 'pesajes')[0]['kilogramos'] = '78.4';
      });
    });
  });

  test('meta null en PUT deja meta null; los decimales sobreviven', () async {
    final c = cuerpoPut(0)
      ..['meta'] = null
      ..['pesajes'] = [
        {'fecha': '2026-11-17', 'kilogramos': 78.0},
        {'fecha': '2026-11-18', 'kilogramos': 0.1},
      ];
    esperar(await api.put(c), 200, {'revision': 1});
    final (_, diario) = await api.get('/api/diario');
    expect(diario['meta'], isNull);
    // 78.0 vuelve como 78 (ver _numero en almacen.dart); 0.1 queda igual.
    expect(diario['pesajes'], [
      {'fecha': '2026-11-17', 'kilogramos': 78},
      {'fecha': '2026-11-18', 'kilogramos': 0.1},
    ]);
  });
}
