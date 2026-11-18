/// Las rutas de `contrato/README.md`, sobre un [AlmacenDiario].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpStatus;
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'almacen.dart';
import 'validacion.dart';

/// Tope del cuerpo de `PUT /api/diario`; nginx usa el mismo.
const limiteCuerpo = 10 * 1024 * 1024;

Handler crearHandler(AlmacenDiario almacen, {int limite = limiteCuerpo}) {
  final router =
      Router(notFoundHandler: (_) => _json(404, {'error': 'no encontrado'}))
        ..get('/api/salud', (Request _) => _json(200, {'ok': true}))
        ..get(
          '/api/revision',
          (Request _) => _json(200, {'revision': almacen.revision()}),
        )
        ..get('/api/diario', (Request _) => _json(200, almacen.leer()))
        ..put('/api/diario', (Request request) async {
          final String texto;
          try {
            texto = await _leerCuerpo(request, limite);
          } on _CuerpoDemasiadoGrande {
            return _json(HttpStatus.requestEntityTooLarge, {
              'error': 'cuerpo de más de $limite bytes',
            });
          } on FormatException {
            return _json(400, {'error': 'el cuerpo no es UTF-8 válido'});
          }

          final Object? json;
          try {
            json = jsonDecode(texto);
          } on FormatException {
            return _json(400, {'error': 'el cuerpo no es JSON válido'});
          }

          final Reemplazo reemplazo;
          try {
            reemplazo = validarReemplazo(json);
          } on DiarioInvalido catch (e) {
            return _json(400, {'error': e.mensaje});
          }

          return switch (almacen.reemplazar(
            reemplazo.revisionBase,
            reemplazo.diario,
          )) {
            Reemplazado(:final revision) => _json(200, {'revision': revision}),
            Conflicto(:final revision) => _json(409, {'revision': revision}),
          };
        });

  return const Pipeline()
      .addMiddleware(_registrar())
      .addMiddleware(_errorInterno())
      .addHandler(router.call);
}

Response _json(int status, Object? cuerpo) => Response(
  status,
  body: jsonEncode(cuerpo),
  headers: {
    'content-type': 'application/json; charset=utf-8',
    // El diario cambia con cada PUT: nada de caché intermedia.
    'cache-control': 'no-store',
  },
);

class _CuerpoDemasiadoGrande implements Exception {}

Future<String> _leerCuerpo(Request request, int limite) async {
  final declarado = request.contentLength;
  if (declarado != null && declarado > limite) throw _CuerpoDemasiadoGrande();
  final bytes = BytesBuilder(copy: false);
  await for (final trozo in request.read()) {
    bytes.add(trozo);
    if (bytes.length > limite) throw _CuerpoDemasiadoGrande();
  }
  return utf8.decode(bytes.takeBytes());
}

/// Una línea por pedido: método, ruta, estado, ms. Nunca el cuerpo.
Middleware _registrar() =>
    (inner) => (request) async {
      final reloj = Stopwatch()..start();
      final respuesta = await inner(request);
      print(
        '${request.method} /${request.url.path} ${respuesta.statusCode} '
        '${reloj.elapsedMilliseconds}ms',
      );
      return respuesta;
    };

Middleware _errorInterno() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on HijackException {
        rethrow;
      } catch (e, st) {
        // Sin el cuerpo: el error y la traza alcanzan para depurar.
        print(
          'error interno en ${request.method} /${request.url.path}: $e\n$st',
        );
        return _json(500, {'error': 'error interno'});
      }
    };
