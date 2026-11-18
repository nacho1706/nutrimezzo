/// Validación del cuerpo de `PUT /api/diario` (ver `contrato/README.md`).
///
/// Se valida todo antes de tocar la base: un cuerpo inválido nunca deja el
/// diario a medio escribir.
library;

const momentos = {'desayuno', 'almuerzo', 'cena', 'extra'};

/// Error de validación: se responde `400 {"error": mensaje}`.
class DiarioInvalido implements Exception {
  DiarioInvalido(this.mensaje);
  final String mensaje;
  @override
  String toString() => 'DiarioInvalido: $mensaje';
}

class Meta {
  Meta(this.kcal, this.proteina, this.carbos, this.grasa);
  final num kcal, proteina, carbos, grasa;
}

class Alimento {
  Alimento({
    required this.id,
    required this.nombre,
    required this.kcal,
    required this.proteina,
    required this.carbos,
    required this.grasa,
    required this.patron,
    required this.usadoPorUltimaVez,
  });
  final String id, nombre, patron, usadoPorUltimaVez;
  final num kcal, proteina, carbos, grasa;
}

class Renglon {
  Renglon(this.nombre, this.cantidad, this.alimentoId);
  final String nombre;
  final num? cantidad;
  final String? alimentoId;
}

class Comida {
  Comida({
    required this.id,
    required this.fecha,
    required this.momento,
    required this.renglones,
    required this.recibidoPorUltimaVez,
  });
  final String id, fecha, momento;
  final List<Renglon> renglones;
  final String? recibidoPorUltimaVez;
}

class Pesaje {
  Pesaje(this.fecha, this.kilogramos);
  final String fecha;
  final num kilogramos;
}

/// La foto completa del diario que manda la app.
class Diario {
  Diario({
    required this.meta,
    required this.alimentos,
    required this.comidas,
    required this.pesajes,
  });
  final Meta? meta;
  final List<Alimento> alimentos;
  final List<Comida> comidas;
  final List<Pesaje> pesajes;
}

/// Cuerpo de `PUT`: la base sobre la que la app editó más la foto nueva.
class Reemplazo {
  Reemplazo(this.revisionBase, this.diario);
  final int revisionBase;
  final Diario diario;
}

/// Valida el JSON ya decodificado de un `PUT /api/diario`.
///
/// Lanza [DiarioInvalido] con un mensaje corto que nombra el campo.
Reemplazo validarReemplazo(Object? json) {
  final raiz = _objeto(json, 'cuerpo');
  final revisionBase = raiz['revisionBase'];
  if (revisionBase is! int || revisionBase < 0) {
    throw DiarioInvalido('revisionBase debe ser un entero >= 0');
  }

  final metaJson = raiz['meta'];
  final meta = metaJson == null ? null : _meta(_objeto(metaJson, 'meta'));

  final alimentos = [
    for (final (i, a) in _lista(raiz, 'alimentos', 'diario').indexed)
      _alimento(_objeto(a, 'alimentos[$i]'), 'alimentos[$i]'),
  ];
  final comidas = [
    for (final (i, c) in _lista(raiz, 'comidas', 'diario').indexed)
      _comida(_objeto(c, 'comidas[$i]'), 'comidas[$i]'),
  ];
  final pesajes = [
    for (final (i, p) in _lista(raiz, 'pesajes', 'diario').indexed)
      _pesaje(_objeto(p, 'pesajes[$i]'), 'pesajes[$i]'),
  ];

  _sinRepetidos(alimentos.map((a) => a.id), 'id de Alimento repetido');
  _sinRepetidos(comidas.map((c) => c.id), 'id de Comida repetido');
  _sinRepetidos(
    comidas.map((c) => '${c.fecha} ${c.momento}'),
    'dos Comidas con la misma fecha y momento',
  );
  _sinRepetidos(pesajes.map((p) => p.fecha), 'dos Pesajes con la misma fecha');

  return Reemplazo(
    revisionBase,
    Diario(
      meta: meta,
      alimentos: alimentos,
      comidas: comidas,
      pesajes: pesajes,
    ),
  );
}

Meta _meta(Map<String, Object?> m) => Meta(
  _numero(m, 'kcal', 'meta'),
  _numero(m, 'proteina', 'meta'),
  _numero(m, 'carbos', 'meta'),
  _numero(m, 'grasa', 'meta'),
);

Alimento _alimento(Map<String, Object?> m, String donde) => Alimento(
  id: _id(m, 'id', donde),
  nombre: _texto(m, 'nombre', donde),
  kcal: _numero(m, 'kcal', donde),
  proteina: _numero(m, 'proteina', donde),
  carbos: _numero(m, 'carbos', donde),
  grasa: _numero(m, 'grasa', donde),
  patron: _texto(m, 'patron', donde),
  usadoPorUltimaVez: _instante(
    m['usadoPorUltimaVez'],
    '$donde.usadoPorUltimaVez',
  ),
);

Comida _comida(Map<String, Object?> m, String donde) {
  final momento = m['momento'];
  if (momento is! String || !momentos.contains(momento)) {
    throw DiarioInvalido(
      '$donde.momento debe ser uno de ${momentos.join(', ')}',
    );
  }
  final recibido = m['recibidoPorUltimaVez'];
  return Comida(
    id: _id(m, 'id', donde),
    fecha: _fecha(m['fecha'], '$donde.fecha'),
    momento: momento,
    renglones: [
      for (final (i, r) in _lista(m, 'renglones', donde).indexed)
        _renglon(_objeto(r, '$donde.renglones[$i]'), '$donde.renglones[$i]'),
    ],
    recibidoPorUltimaVez: recibido == null
        ? null
        : _instante(recibido, '$donde.recibidoPorUltimaVez'),
  );
}

Renglon _renglon(Map<String, Object?> m, String donde) {
  final cantidad = m['cantidad'];
  if (cantidad != null && cantidad is! num) {
    throw DiarioInvalido('$donde.cantidad debe ser un número o null');
  }
  final alimentoId = m['alimentoId'];
  if (alimentoId != null && alimentoId is! String) {
    throw DiarioInvalido('$donde.alimentoId debe ser un texto o null');
  }
  return Renglon(
    _texto(m, 'nombre', donde),
    cantidad as num?,
    alimentoId as String?,
  );
}

Pesaje _pesaje(Map<String, Object?> m, String donde) {
  final kilogramos = _numero(m, 'kilogramos', donde);
  if (kilogramos <= 0) {
    throw DiarioInvalido('$donde.kilogramos debe ser > 0');
  }
  return Pesaje(_fecha(m['fecha'], '$donde.fecha'), kilogramos);
}

Map<String, Object?> _objeto(Object? v, String donde) {
  if (v is! Map<String, Object?>) {
    throw DiarioInvalido('$donde debe ser un objeto');
  }
  return v;
}

List<Object?> _lista(Map<String, Object?> m, String clave, String donde) {
  final v = m[clave];
  if (v is! List<Object?>) {
    throw DiarioInvalido('$donde.$clave debe ser una lista');
  }
  return v;
}

String _texto(Map<String, Object?> m, String clave, String donde) {
  final v = m[clave];
  if (v is! String) throw DiarioInvalido('$donde.$clave debe ser un texto');
  return v;
}

String _id(Map<String, Object?> m, String clave, String donde) {
  final v = _texto(m, clave, donde);
  if (v.isEmpty) throw DiarioInvalido('$donde.$clave no puede estar vacío');
  return v;
}

num _numero(Map<String, Object?> m, String clave, String donde) {
  final v = m[clave];
  if (v is! num || !v.isFinite) {
    throw DiarioInvalido('$donde.$clave debe ser un número');
  }
  return v;
}

final _patronFecha = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// `YYYY-MM-DD` y una fecha que existe (rechaza `2026-02-30`).
String _fecha(Object? v, String donde) {
  if (v is String && _patronFecha.hasMatch(v)) {
    final partes = v.split('-').map(int.parse).toList();
    final d = DateTime.utc(partes[0], partes[1], partes[2]);
    if (d.year == partes[0] && d.month == partes[1] && d.day == partes[2]) {
      return v;
    }
  }
  throw DiarioInvalido('$donde debe ser una fecha YYYY-MM-DD');
}

/// ISO 8601 como lo escribe `DateTime.toIso8601String()`. Se guarda tal cual.
String _instante(Object? v, String donde) {
  if (v is String && DateTime.tryParse(v) != null) return v;
  throw DiarioInvalido('$donde debe ser una fecha y hora ISO 8601');
}

void _sinRepetidos(Iterable<String> claves, String mensaje) {
  final vistas = <String>{};
  for (final c in claves) {
    if (!vistas.add(c)) throw DiarioInvalido('$mensaje: $c');
  }
}
