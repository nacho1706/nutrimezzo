// JSON shapes of the diary entities. Shared by the on-device store
// (almacen_ajustes.dart) and the server sync (almacen_remoto.dart); the
// canonical example is `contrato/diario.json`. Changing a shape here changes
// what existing phones read back, and what the server accepts.

import 'diario.dart';

/// The whole diary as the server holds it: the Meta (null = never set, the
/// app uses [Meta.porDefecto]) plus the three lists. Never the BYOK.
class FotoDiario {
  const FotoDiario({
    required this.meta,
    required this.alimentos,
    required this.comidas,
    required this.pesajes,
  });

  factory FotoDiario.deJson(Map<String, dynamic> json) {
    return FotoDiario(
      meta: metaDeJson(json['meta'] as Map<String, dynamic>?),
      alimentos: [
        for (final item in json['alimentos'] as List<dynamic>)
          alimentoDeJson(item as Map<String, dynamic>),
      ],
      comidas: [
        for (final item in json['comidas'] as List<dynamic>)
          comidaDeJson(item as Map<String, dynamic>),
      ],
      pesajes: [
        for (final item in json['pesajes'] as List<dynamic>)
          pesajeDeJson(item as Map<String, dynamic>),
      ],
    );
  }

  final Meta? meta;
  final List<Alimento> alimentos;
  final List<Comida> comidas;
  final List<Pesaje> pesajes;

  /// The body without `revision` / `revisionBase`; the caller adds whichever.
  Map<String, Object?> aJson() {
    return {
      'meta': metaAJson(meta),
      'alimentos': [for (final alimento in alimentos) alimentoAJson(alimento)],
      'comidas': [for (final comida in comidas) comidaAJson(comida)],
      'pesajes': [for (final pesaje in pesajes) pesajeAJson(pesaje)],
    };
  }
}

Meta? metaDeJson(Map<String, dynamic>? json) {
  if (json == null) {
    return null;
  }
  return Meta(macros: _macrosDe(json));
}

Map<String, Object?>? metaAJson(Meta? meta) {
  if (meta == null) {
    return null;
  }
  return {
    'kcal': meta.macros.kcal,
    'proteina': meta.macros.proteina,
    'carbos': meta.macros.carbos,
    'grasa': meta.macros.grasa,
  };
}

Alimento alimentoDeJson(Map<String, dynamic> json) {
  return Alimento(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    macrosPor100g: _macrosDe(json),
    patron: json['patron'] as String,
    usadoPorUltimaVez: DateTime.parse(json['usadoPorUltimaVez'] as String),
  );
}

Map<String, Object?> alimentoAJson(Alimento alimento) {
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

Comida comidaDeJson(Map<String, dynamic> json) {
  final fecha = DateTime.parse(json['fecha'] as String);
  final recibido = json['recibidoPorUltimaVez'] as String?;
  return Comida(
    // Diaries saved before Comidas had ids; Diario assigns one.
    id: json['id'] as String? ?? '',
    momento: Momento.values.byName(json['momento'] as String),
    fecha: DateTime(fecha.year, fecha.month, fecha.day),
    renglones: [
      for (final item in json['renglones'] as List<dynamic>)
        _renglonDe(item as Map<String, dynamic>),
    ],
    recibidoPorUltimaVez: recibido == null ? null : DateTime.parse(recibido),
  );
}

Map<String, Object?> comidaAJson(Comida comida) {
  return {
    'id': comida.id,
    'fecha': _textoFecha(comida.fecha ?? DateTime(1970)),
    'momento': comida.momento.name,
    'renglones': [
      for (final renglon in comida.renglones) _renglonJson(renglon),
    ],
    if (comida.recibidoPorUltimaVez != null)
      'recibidoPorUltimaVez': comida.recibidoPorUltimaVez!.toIso8601String(),
  };
}

Pesaje pesajeDeJson(Map<String, dynamic> json) {
  final fecha = DateTime.parse(json['fecha'] as String);
  return Pesaje(
    fecha: DateTime(fecha.year, fecha.month, fecha.day),
    kilogramos: json['kilogramos'] as num,
  );
}

Map<String, Object?> pesajeAJson(Pesaje pesaje) {
  return {'fecha': _textoFecha(pesaje.fecha), 'kilogramos': pesaje.kilogramos};
}

Renglon _renglonDe(Map<String, dynamic> json) {
  return Renglon(
    nombre: json['nombre'] as String,
    cantidad: json['cantidad'] as num?,
    alimentoId: json['alimentoId'] as String?,
  );
}

Map<String, Object?> _renglonJson(Renglon renglon) {
  return {
    'nombre': renglon.nombre,
    'cantidad': renglon.cantidad,
    'alimentoId': renglon.alimentoId,
  };
}

Macros _macrosDe(Map<String, dynamic> json) {
  return Macros(
    kcal: json['kcal'] as num,
    proteina: json['proteina'] as num,
    carbos: json['carbos'] as num,
    grasa: json['grasa'] as num,
  );
}

String _textoFecha(DateTime fecha) {
  return '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';
}
