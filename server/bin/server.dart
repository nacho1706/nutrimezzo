import 'dart:async';
import 'dart:io';

import 'package:nutrimezzo_server/nutrimezzo_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Variables de entorno:
///   NUTRIMEZZO_DB  ruta de la base SQLite (por defecto /data/nutrimezzo.db)
///   HOST           dirección de escucha (por defecto 127.0.0.1)
///   PORT           puerto (por defecto 8081)
///
/// `server --healthcheck` pide GET /api/salud a ese HOST:PORT y sale con 0 si
/// responde 200, 1 si no. Lo usa el HEALTHCHECK de la imagen, que no trae curl.
Future<void> main(List<String> args) async {
  final env = Platform.environment;
  final host = env['HOST'] ?? '127.0.0.1';
  final port = int.parse(env['PORT'] ?? '8081');

  if (args.contains('--healthcheck')) {
    exit(await _healthcheck(host, port) ? 0 : 1);
  }

  final ruta = env['NUTRIMEZZO_DB'] ?? '/data/nutrimezzo.db';
  final almacen = AlmacenDiario.abrir(ruta);
  final server = await shelf_io.serve(
    crearHandler(almacen),
    host,
    port,
    poweredByHeader: null,
  );
  // dart:io agrega X-Frame-Options & co. por defecto; los headers de
  // seguridad los pone nginx, una sola vez.
  server.defaultResponseHeaders.clear();
  print('nutrimezzo-api escuchando en http://$host:${server.port} (db: $ruta)');

  var cerrando = false;
  Future<void> cerrar(ProcessSignal senal) async {
    if (cerrando) return;
    cerrando = true;
    print('$senal: cerrando');
    await server.close();
    almacen.cerrar();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen(cerrar);
  ProcessSignal.sigint.watch().listen(cerrar);
}

Future<bool> _healthcheck(String host, int port) async {
  // Escuchar en 0.0.0.0 no sirve como destino: se prueba por loopback.
  final destino = host == '0.0.0.0'
      ? '127.0.0.1'
      : (host == '::' ? '::1' : host);
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final request = await client
        .getUrl(
          Uri(scheme: 'http', host: destino, port: port, path: '/api/salud'),
        )
        .timeout(const Duration(seconds: 3));
    final response = await request.close().timeout(const Duration(seconds: 3));
    await response.drain<void>();
    return response.statusCode == 200;
  } catch (e) {
    stderr.writeln('healthcheck: $e');
    return false;
  } finally {
    client.close(force: true);
  }
}
