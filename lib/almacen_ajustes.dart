import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'busqueda_ia.dart';
import 'codec_diario.dart';
import 'diario.dart';

const _kcal = 'meta.kcal';
const _proteina = 'meta.proteina';
const _carbos = 'meta.carbos';
const _grasa = 'meta.grasa';
const _urlBase = 'byok.urlBase';
const _claveApi = 'byok.claveApi';
const _idModelo = 'byok.idModelo';
const _alimentos = 'alimentos';
const _comidas = 'comidas';
const _pesajes = 'pesajes';

Future<Diario> abrirDiario({DateTime Function()? ahora}) async {
  final prefs = await SharedPreferences.getInstance();
  late final Diario diario;
  diario = Diario(
    ahora: ahora,
    meta: _metaDe(prefs),
    byok: byokDe(prefs),
    alimentos: _alimentosDe(prefs),
    comidas: _comidasDe(prefs),
    pesajes: _pesajesDe(prefs),
    busquedaIA: BusquedaIAOpenAI(byok: () => diario.byok),
    persistir: (meta, byok) => _guardar(prefs, meta, byok),
    persistirDiario: (alimentos, comidas, pesajes) =>
        _guardarDiario(prefs, alimentos, comidas, pesajes),
  );
  return diario;
}

Meta _metaDe(SharedPreferences prefs) {
  final kcal = prefs.getDouble(_kcal);
  final proteina = prefs.getDouble(_proteina);
  final carbos = prefs.getDouble(_carbos);
  final grasa = prefs.getDouble(_grasa);
  if (kcal == null || proteina == null || carbos == null || grasa == null) {
    return Meta.porDefecto;
  }
  return Meta(
    macros: Macros(
      kcal: kcal,
      proteina: proteina,
      carbos: carbos,
      grasa: grasa,
    ),
  );
}

/// The BYOK stays on each device in both installation types (ADR-0001):
/// the hosted store reads and writes it here, never on the server.
Byok byokDe(SharedPreferences prefs) {
  return Byok(
    urlBase: prefs.getString(_urlBase) ?? '',
    claveApi: prefs.getString(_claveApi) ?? '',
    idModelo: prefs.getString(_idModelo) ?? '',
  );
}

List<Alimento> _alimentosDe(SharedPreferences prefs) {
  return [for (final item in _listaDe(prefs, _alimentos)) alimentoDeJson(item)];
}

List<Comida> _comidasDe(SharedPreferences prefs) {
  return [for (final item in _listaDe(prefs, _comidas)) comidaDeJson(item)];
}

List<Pesaje> _pesajesDe(SharedPreferences prefs) {
  return [for (final item in _listaDe(prefs, _pesajes)) pesajeDeJson(item)];
}

Iterable<Map<String, dynamic>> _listaDe(SharedPreferences prefs, String clave) {
  final crudo = prefs.getString(clave);
  if (crudo == null || crudo.isEmpty) {
    return const [];
  }
  return (jsonDecode(crudo) as List<dynamic>).cast<Map<String, dynamic>>();
}

Future<void> _guardar(SharedPreferences prefs, Meta meta, Byok byok) async {
  await prefs.setDouble(_kcal, meta.macros.kcal.toDouble());
  await prefs.setDouble(_proteina, meta.macros.proteina.toDouble());
  await prefs.setDouble(_carbos, meta.macros.carbos.toDouble());
  await prefs.setDouble(_grasa, meta.macros.grasa.toDouble());
  await guardarByokEn(prefs, byok);
}

Future<void> guardarByokEn(SharedPreferences prefs, Byok byok) async {
  await prefs.setString(_urlBase, byok.urlBase);
  await prefs.setString(_claveApi, byok.claveApi);
  await prefs.setString(_idModelo, byok.idModelo);
}

Future<void> _guardarDiario(
  SharedPreferences prefs,
  List<Alimento> alimentos,
  List<Comida> comidas,
  List<Pesaje> pesajes,
) async {
  await prefs.setString(
    _alimentos,
    jsonEncode([for (final alimento in alimentos) alimentoAJson(alimento)]),
  );
  await prefs.setString(
    _comidas,
    jsonEncode([for (final comida in comidas) comidaAJson(comida)]),
  );
  await prefs.setString(
    _pesajes,
    jsonEncode([for (final pesaje in pesajes) pesajeAJson(pesaje)]),
  );
}
