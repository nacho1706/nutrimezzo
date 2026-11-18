// Which installation type this device runs: offline (diary in
// SharedPreferences) or hosted (the server is the only source of truth).
// Web is always hosted against its own origin; Android reads the device
// setting "Servidor".

import 'package:shared_preferences/shared_preferences.dart';

const _claveServidor = 'servidor.url';

/// Build-time default for a device that never saved the setting:
/// `--dart-define=NUTRIMEZZO_SERVIDOR=https://nutrimezzo.<tailnet>.ts.net`.
const servidorPorDefecto = String.fromEnvironment('NUTRIMEZZO_SERVIDOR');

sealed class Modo {
  const Modo();
}

class ModoOffline extends Modo {
  const ModoOffline();
}

class ModoAlojado extends Modo {
  const ModoAlojado(this.api);

  /// Base of the sync API, ending in `/api/`.
  final Uri api;

  @override
  bool operator ==(Object other) => other is ModoAlojado && other.api == api;

  @override
  int get hashCode => api.hashCode;
}

/// Web: always hosted on [origen] (the page's own origin). Android: the
/// "Servidor" setting; empty means offline.
Future<Modo> resolverModo({required bool web, Uri? origen}) async {
  if (web) {
    return ModoAlojado((origen ?? Uri.base).resolve('/api/'));
  }
  final api = apiDeServidor(await leerServidor());
  return api == null ? const ModoOffline() : ModoAlojado(api);
}

/// The saved "Servidor" URL, or [servidorPorDefecto] when it was never set.
Future<String> leerServidor() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_claveServidor) ?? servidorPorDefecto;
}

Future<void> guardarServidor(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_claveServidor, url.trim());
}

/// `https://host[/ruta]` → `https://host[/ruta]/api/`; empty → null.
Uri? apiDeServidor(String url) {
  final limpio = url.trim();
  if (limpio.isEmpty || validarServidor(limpio) != null) {
    return null;
  }
  final base = Uri.parse(limpio);
  final ruta = base.path.endsWith('/') ? base.path : '${base.path}/';
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: '${ruta}api/',
  );
}

/// Null when [url] is empty or an http(s) URL with a host; else the message
/// for the field.
String? validarServidor(String url) {
  final limpio = url.trim();
  if (limpio.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(limpio);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    return 'Tiene que ser una URL http:// o https://';
  }
  return null;
}
