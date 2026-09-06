import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'busqueda_ia.dart';
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

Future<Diario> abrirDiario({DateTime Function()? ahora}) async {
  final prefs = await SharedPreferences.getInstance();
  late final Diario diario;
  diario = Diario(
    ahora: ahora,
    meta: _metaDe(prefs),
    byok: _byokDe(prefs),
    alimentos: _alimentosDe(prefs),
    comidas: _comidasDe(prefs),
    busquedaIA: BusquedaIAOpenAI(byok: () => diario.byok),
    persistir: (meta, byok) => _guardar(prefs, meta, byok),
    persistirDiario: (alimentos, comidas) =>
        _guardarDiario(prefs, alimentos, comidas),
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

Byok _byokDe(SharedPreferences prefs) {
  return Byok(
    urlBase: prefs.getString(_urlBase) ?? '',
    claveApi: prefs.getString(_claveApi) ?? '',
    idModelo: prefs.getString(_idModelo) ?? '',
  );
}

List<Alimento> _alimentosDe(SharedPreferences prefs) {
  final crudo = prefs.getString(_alimentos);
  if (crudo == null || crudo.isEmpty) {
    return const [];
  }
  final lista = jsonDecode(crudo) as List<dynamic>;
  return [for (final item in lista) _alimentoDe(item as Map<String, dynamic>)];
}

List<Comida> _comidasDe(SharedPreferences prefs) {
  final crudo = prefs.getString(_comidas);
  if (crudo == null || crudo.isEmpty) {
    return const [];
  }
  final lista = jsonDecode(crudo) as List<dynamic>;
  return [for (final item in lista) _comidaDe(item as Map<String, dynamic>)];
}

Alimento _alimentoDe(Map<String, dynamic> json) {
  return Alimento(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    macrosPor100g: _macrosDe(json),
    patron: json['patron'] as String,
    usadoPorUltimaVez: DateTime.parse(json['usadoPorUltimaVez'] as String),
  );
}

Comida _comidaDe(Map<String, dynamic> json) {
  final fecha = DateTime.parse(json['fecha'] as String);
  return Comida(
    momento: Momento.values.byName(json['momento'] as String),
    fecha: DateTime(fecha.year, fecha.month, fecha.day),
    renglones: [
      for (final item in json['renglones'] as List<dynamic>)
        _renglonDe(item as Map<String, dynamic>),
    ],
  );
}

Renglon _renglonDe(Map<String, dynamic> json) {
  return Renglon(
    nombre: json['nombre'] as String,
    cantidad: json['cantidad'] as num?,
    alimentoId: json['alimentoId'] as String?,
  );
}

Macros _macrosDe(Map<String, dynamic> json) {
  return Macros(
    kcal: json['kcal'] as num,
    proteina: json['proteina'] as num,
    carbos: json['carbos'] as num,
    grasa: json['grasa'] as num,
  );
}

Future<void> _guardar(SharedPreferences prefs, Meta meta, Byok byok) async {
  await prefs.setDouble(_kcal, meta.macros.kcal.toDouble());
  await prefs.setDouble(_proteina, meta.macros.proteina.toDouble());
  await prefs.setDouble(_carbos, meta.macros.carbos.toDouble());
  await prefs.setDouble(_grasa, meta.macros.grasa.toDouble());
  await prefs.setString(_urlBase, byok.urlBase);
  await prefs.setString(_claveApi, byok.claveApi);
  await prefs.setString(_idModelo, byok.idModelo);
}

Future<void> _guardarDiario(
  SharedPreferences prefs,
  List<Alimento> alimentos,
  List<Comida> comidas,
) async {
  await prefs.setString(
    _alimentos,
    jsonEncode([for (final alimento in alimentos) _alimentoJson(alimento)]),
  );
  await prefs.setString(
    _comidas,
    jsonEncode([for (final comida in comidas) _comidaJson(comida)]),
  );
}

Map<String, Object?> _alimentoJson(Alimento alimento) {
  return {
    'id': alimento.id,
    'nombre': alimento.nombre,
    'kcal': alimento.macrosPor100g.kcal,
    'proteina': alimento.macrosPor100g.proteina,
    'carbos': alimento.macrosPor100g.carbos,
    'grasa': alimento.macrosPor100g.grasa,
    'patron': alimento.patron,
    'usadoPorUltimaVez': alimento.usadoPorUltimaVez.toIso8601String(),
  };
}

Map<String, Object?> _comidaJson(Comida comida) {
  final fecha = comida.fecha ?? DateTime(1970);
  return {
    'fecha':
        '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
    'momento': comida.momento.name,
    'renglones': [
      for (final renglon in comida.renglones) _renglonJson(renglon),
    ],
  };
}

Map<String, Object?> _renglonJson(Renglon renglon) {
  return {
    'nombre': renglon.nombre,
    'cantidad': renglon.cantidad,
    'alimentoId': renglon.alimentoId,
  };
}
