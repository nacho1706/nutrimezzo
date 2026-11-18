// Hosted installation: the server is the only source of truth for the diary
// (contrato/README.md). Every change is a full-snapshot PUT guarded by the
// revision it was based on. The BYOK never travels; it stays in this
// device's SharedPreferences exactly as in the offline store.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'almacen_ajustes.dart';
import 'busqueda_ia.dart';
import 'codec_diario.dart';
import 'diario.dart';

/// What went wrong with a write. After either one the store stops sending:
/// the caller reopens the diary from the server.
enum EventoSincronizacion {
  /// The server moved on (another device wrote first): `409`.
  conflicto,

  /// Network error, timeout, or any other non-200 answer.
  fallo,
}

/// The server could not be read (open or revision check).
class FalloServidor implements Exception {
  const FalloServidor(this.detalle);

  final String detalle;

  @override
  String toString() => 'FalloServidor($detalle)';
}

/// GET `diario` under [api] (which ends in `/api/`) and builds the [Diario]
/// on it. Throws [FalloServidor] when the server can't be read. When
/// [cliente] is null the store owns one and closes it in
/// [AlmacenRemoto.cerrar].
Future<AlmacenRemoto> abrirDiarioRemoto({
  required Uri api,
  http.Client? cliente,
  DateTime Function()? ahora,
  Duration espera = const Duration(seconds: 10),
}) async {
  final propio = cliente == null;
  final http.Client conexion = cliente ?? http.Client();
  try {
    final respuesta = await _leer(conexion, api.resolve('diario'), espera);
    final json = respuesta as Map<String, dynamic>;
    final revision = json['revision'] as int;
    final foto = FotoDiario.deJson(json);
    final prefs = await SharedPreferences.getInstance();
    final almacen = AlmacenRemoto._(
      api,
      conexion,
      propio,
      espera,
      prefs,
      revision,
      foto,
    );
    late final Diario diario;
    diario = Diario(
      ahora: ahora,
      meta: foto.meta ?? Meta.porDefecto,
      byok: byokDe(prefs),
      alimentos: foto.alimentos,
      comidas: foto.comidas,
      pesajes: foto.pesajes,
      busquedaIA: BusquedaIAOpenAI(byok: () => diario.byok),
      persistir: almacen._persistir,
      persistirDiario: almacen._persistirDiario,
    );
    almacen._diario = diario;
    return almacen;
  } on FalloServidor {
    if (propio) conexion.close();
    rethrow;
  } catch (error) {
    if (propio) conexion.close();
    throw FalloServidor('$error');
  }
}

class AlmacenRemoto {
  AlmacenRemoto._(
    this._api,
    this._cliente,
    this._propio,
    this._espera,
    this._prefs,
    this._revision,
    FotoDiario foto,
  ) : _meta = foto.meta,
      _alimentos = foto.alimentos,
      _comidas = foto.comidas,
      _pesajes = foto.pesajes;

  final Uri _api;
  final http.Client _cliente;
  final bool _propio;
  final Duration _espera;
  final SharedPreferences _prefs;
  final _eventos = StreamController<EventoSincronizacion>.broadcast();
  late final Diario _diario;

  // The latest snapshot, from the initial load and every hook since.
  int _revision;
  Meta? _meta;
  List<Alimento> _alimentos;
  List<Comida> _comidas;
  List<Pesaje> _pesajes;

  Completer<void>? _pendiente;
  var _escribiendo = false;
  var _detenido = false;

  Diario get diario => _diario;

  /// The server revision this device's diary is based on.
  int get revision => _revision;

  /// A PUT is in flight or queued; [revision] may be about to move.
  bool get escribiendo => _escribiendo || _pendiente != null;

  /// At most one event per store: it stops writing after the first.
  Stream<EventoSincronizacion> get eventos => _eventos.stream;

  /// GET `revision`. Throws [FalloServidor].
  Future<int> revisionRemota() async {
    try {
      final json = await _leer(
        _cliente,
        _api.resolve('revision'),
        _espera,
      ) as Map<String, dynamic>;
      return json['revision'] as int;
    } on FalloServidor {
      rethrow;
    } catch (error) {
      throw FalloServidor('$error');
    }
  }

  /// Stops writing and drops queued writes. Closes the http client only if
  /// the store created it.
  void cerrar() {
    _detenido = true;
    _pendiente?.complete();
    _pendiente = null;
    unawaited(_eventos.close());
    if (_propio) {
      _cliente.close();
    }
  }

  Future<void> _persistir(Meta meta, Byok byok) async {
    await guardarByokEn(_prefs, byok);
    if (_mismosMacros(meta.macros, (_meta ?? Meta.porDefecto).macros)) {
      return;
    }
    _meta = meta;
    await _encolar();
  }

  Future<void> _persistirDiario(
    List<Alimento> alimentos,
    List<Comida> comidas,
    List<Pesaje> pesajes,
  ) {
    _alimentos = alimentos;
    _comidas = comidas;
    _pesajes = pesajes;
    return _encolar();
  }

  /// One PUT in flight at a time. Writes that arrive meanwhile collapse into
  /// one follow-up PUT carrying the latest snapshot; their callers all wait
  /// for that one.
  Future<void> _encolar() {
    if (_detenido) {
      return Future.value();
    }
    final pendiente = _pendiente ??= Completer<void>();
    if (!_escribiendo) {
      unawaited(_bombear());
    }
    return pendiente.future;
  }

  Future<void> _bombear() async {
    _escribiendo = true;
    while (_pendiente != null && !_detenido) {
      final pendiente = _pendiente!;
      _pendiente = null;
      await _enviar();
      pendiente.complete();
    }
    _escribiendo = false;
  }

  Future<void> _enviar() async {
    final cuerpo = {
      'revisionBase': _revision,
      ...FotoDiario(
        meta: _meta,
        alimentos: _alimentos,
        comidas: _comidas,
        pesajes: _pesajes,
      ).aJson(),
    };
    try {
      final respuesta = await _cliente
          .put(
            _api.resolve('diario'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(cuerpo),
          )
          .timeout(_espera);
      switch (respuesta.statusCode) {
        case 200:
          final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
          _revision = json['revision'] as int;
        case 409:
          _detener(EventoSincronizacion.conflicto);
        default:
          _detener(EventoSincronizacion.fallo);
      }
    } catch (_) {
      _detener(EventoSincronizacion.fallo);
    }
  }

  void _detener(EventoSincronizacion evento) {
    if (_detenido) {
      return;
    }
    _detenido = true;
    _pendiente?.complete();
    _pendiente = null;
    _eventos.add(evento);
  }
}

Future<Object?> _leer(http.Client cliente, Uri uri, Duration espera) async {
  final respuesta = await cliente.get(uri).timeout(espera);
  if (respuesta.statusCode != 200) {
    throw FalloServidor('HTTP ${respuesta.statusCode} en $uri');
  }
  return jsonDecode(respuesta.body);
}

bool _mismosMacros(Macros a, Macros b) {
  return a.kcal == b.kcal &&
      a.proteina == b.proteina &&
      a.carbos == b.carbos &&
      a.grasa == b.grasa;
}
