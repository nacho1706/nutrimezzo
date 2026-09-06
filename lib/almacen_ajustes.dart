import 'package:shared_preferences/shared_preferences.dart';

import 'diario.dart';

const _kcal = 'meta.kcal';
const _proteina = 'meta.proteina';
const _carbos = 'meta.carbos';
const _grasa = 'meta.grasa';
const _urlBase = 'byok.urlBase';
const _claveApi = 'byok.claveApi';
const _idModelo = 'byok.idModelo';

Future<Diario> abrirDiario({DateTime Function()? ahora}) async {
  final prefs = await SharedPreferences.getInstance();
  return Diario(
    ahora: ahora,
    meta: _metaDe(prefs),
    byok: _byokDe(prefs),
    persistir: (meta, byok) => _guardar(prefs, meta, byok),
  );
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

Future<void> _guardar(SharedPreferences prefs, Meta meta, Byok byok) async {
  await prefs.setDouble(_kcal, meta.macros.kcal.toDouble());
  await prefs.setDouble(_proteina, meta.macros.proteina.toDouble());
  await prefs.setDouble(_carbos, meta.macros.carbos.toDouble());
  await prefs.setDouble(_grasa, meta.macros.grasa.toDouble());
  await prefs.setString(_urlBase, byok.urlBase);
  await prefs.setString(_claveApi, byok.claveApi);
  await prefs.setString(_idModelo, byok.idModelo);
}
