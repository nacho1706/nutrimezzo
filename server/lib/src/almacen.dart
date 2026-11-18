/// El diario en SQLite: la única fuente de verdad del modo hospedado.
library;

import 'package:sqlite3/sqlite3.dart';

import 'validacion.dart';

/// Resultado de [AlmacenDiario.reemplazar].
sealed class ResultadoReemplazo {
  const ResultadoReemplazo(this.revision);
  final int revision;
}

/// Se guardó la foto; [revision] es la nueva.
class Reemplazado extends ResultadoReemplazo {
  const Reemplazado(super.revision);
}

/// `revisionBase` no era la actual; [revision] es la actual. No se tocó nada.
class Conflicto extends ResultadoReemplazo {
  const Conflicto(super.revision);
}

/// Migraciones en orden; `PRAGMA user_version` cuenta cuántas se aplicaron.
const _migraciones = <String>[
  '''
  CREATE TABLE revision (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    valor INTEGER NOT NULL
  );
  INSERT INTO revision (id, valor) VALUES (1, 0);

  -- Sin fila = meta null (la app usa la Meta por defecto).
  CREATE TABLE meta (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    kcal REAL NOT NULL,
    proteina REAL NOT NULL,
    carbos REAL NOT NULL,
    grasa REAL NOT NULL
  );

  CREATE TABLE alimentos (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL,
    kcal REAL NOT NULL,
    proteina REAL NOT NULL,
    carbos REAL NOT NULL,
    grasa REAL NOT NULL,
    patron TEXT NOT NULL,
    usado_por_ultima_vez TEXT NOT NULL
  );

  CREATE TABLE comidas (
    id TEXT PRIMARY KEY,
    fecha TEXT NOT NULL,
    momento TEXT NOT NULL
      CHECK (momento IN ('desayuno', 'almuerzo', 'cena', 'extra')),
    recibido_por_ultima_vez TEXT,
    UNIQUE (fecha, momento)
  );

  CREATE TABLE renglones (
    comida_id TEXT NOT NULL REFERENCES comidas (id) ON DELETE CASCADE,
    posicion INTEGER NOT NULL,
    nombre TEXT NOT NULL,
    cantidad REAL,
    alimento_id TEXT,
    PRIMARY KEY (comida_id, posicion)
  );

  CREATE TABLE pesajes (
    fecha TEXT PRIMARY KEY,
    kilogramos REAL NOT NULL CHECK (kilogramos > 0)
  );
  ''',
];

class AlmacenDiario {
  AlmacenDiario._(this._db);

  /// Abre (o crea) la base en [ruta] y aplica las migraciones pendientes.
  factory AlmacenDiario.abrir(String ruta) =>
      AlmacenDiario._preparar(sqlite3.open(ruta));

  /// Base en memoria, para tests.
  factory AlmacenDiario.enMemoria() =>
      AlmacenDiario._preparar(sqlite3.openInMemory());

  factory AlmacenDiario._preparar(Database db) {
    db.execute('PRAGMA busy_timeout = 5000');
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA foreign_keys = ON');
    final almacen = AlmacenDiario._(db).._migrar();
    return almacen;
  }

  final Database _db;

  void _migrar() {
    final version = _db.userVersion;
    if (version > _migraciones.length) {
      throw StateError(
        'La base tiene user_version $version; este servidor conoce hasta '
        '${_migraciones.length}.',
      );
    }
    for (var v = version; v < _migraciones.length; v++) {
      _transaccion(() {
        _db.execute(_migraciones[v]);
        _db.userVersion = v + 1;
      });
    }
  }

  int revision() =>
      _db.select('SELECT valor FROM revision WHERE id = 1').first['valor']
          as int;

  /// El diario con la forma de `contrato/diario.json`.
  ///
  /// Los REAL enteros salen como enteros JSON (`89.0` → `89`), así lo que la
  /// app manda como `89` vuelve como `89`.
  Map<String, Object?> leer() => _transaccion(() {
    final meta = _db.select(
      'SELECT kcal, proteina, carbos, grasa FROM meta WHERE id = 1',
    );
    final renglonesPorComida = <String, List<Map<String, Object?>>>{};
    for (final r in _db.select(
      'SELECT comida_id, nombre, cantidad, alimento_id FROM renglones '
      'ORDER BY comida_id, posicion',
    )) {
      renglonesPorComida.putIfAbsent(r['comida_id'] as String, () => []).add({
        'nombre': r['nombre'],
        'cantidad': _numero(r['cantidad'] as num?),
        'alimentoId': r['alimento_id'],
      });
    }
    return {
      'revision': revision(),
      'meta': meta.isEmpty
          ? null
          : {
              for (final k in ['kcal', 'proteina', 'carbos', 'grasa'])
                k: _numero(meta.first[k] as num),
            },
      'alimentos': [
        for (final a in _db.select(
          'SELECT id, nombre, kcal, proteina, carbos, grasa, patron, '
          'usado_por_ultima_vez FROM alimentos ORDER BY rowid',
        ))
          {
            'id': a['id'],
            'nombre': a['nombre'],
            'kcal': _numero(a['kcal'] as num),
            'proteina': _numero(a['proteina'] as num),
            'carbos': _numero(a['carbos'] as num),
            'grasa': _numero(a['grasa'] as num),
            'patron': a['patron'],
            'usadoPorUltimaVez': a['usado_por_ultima_vez'],
          },
      ],
      'comidas': [
        for (final c in _db.select(
          'SELECT id, fecha, momento, recibido_por_ultima_vez FROM comidas '
          'ORDER BY rowid',
        ))
          {
            'id': c['id'],
            'fecha': c['fecha'],
            'momento': c['momento'],
            'renglones': renglonesPorComida[c['id']] ?? const [],
            if (c['recibido_por_ultima_vez'] != null)
              'recibidoPorUltimaVez': c['recibido_por_ultima_vez'],
          },
      ],
      'pesajes': [
        for (final p in _db.select(
          'SELECT fecha, kilogramos FROM pesajes ORDER BY rowid',
        ))
          {'fecha': p['fecha'], 'kilogramos': _numero(p['kilogramos'] as num)},
      ],
    };
  }, escritura: false);

  /// Reemplaza todo el diario si [revisionBase] es la revisión actual.
  ResultadoReemplazo reemplazar(int revisionBase, Diario diario) =>
      _transaccion(() {
        final actual = revision();
        if (revisionBase != actual) return Conflicto(actual);

        // Las tablas quedan vacías, así el rowid vuelve a empezar y el orden
        // de inserción es el orden en que la app mandó cada lista.
        _db.execute('''
          DELETE FROM renglones;
          DELETE FROM comidas;
          DELETE FROM alimentos;
          DELETE FROM pesajes;
          DELETE FROM meta;
        ''');

        final meta = diario.meta;
        if (meta != null) {
          _db.execute(
            'INSERT INTO meta (id, kcal, proteina, carbos, grasa) '
            'VALUES (1, ?, ?, ?, ?)',
            [meta.kcal, meta.proteina, meta.carbos, meta.grasa],
          );
        }

        final alimento = _db.prepare(
          'INSERT INTO alimentos (id, nombre, kcal, proteina, carbos, grasa, '
          'patron, usado_por_ultima_vez) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        );
        final comida = _db.prepare(
          'INSERT INTO comidas (id, fecha, momento, recibido_por_ultima_vez) '
          'VALUES (?, ?, ?, ?)',
        );
        final renglon = _db.prepare(
          'INSERT INTO renglones (comida_id, posicion, nombre, cantidad, '
          'alimento_id) VALUES (?, ?, ?, ?, ?)',
        );
        final pesaje = _db.prepare(
          'INSERT INTO pesajes (fecha, kilogramos) VALUES (?, ?)',
        );
        try {
          for (final a in diario.alimentos) {
            alimento.execute([
              a.id,
              a.nombre,
              a.kcal,
              a.proteina,
              a.carbos,
              a.grasa,
              a.patron,
              a.usadoPorUltimaVez,
            ]);
          }
          for (final c in diario.comidas) {
            comida.execute([c.id, c.fecha, c.momento, c.recibidoPorUltimaVez]);
            for (final (i, r) in c.renglones.indexed) {
              renglon.execute([c.id, i, r.nombre, r.cantidad, r.alimentoId]);
            }
          }
          for (final p in diario.pesajes) {
            pesaje.execute([p.fecha, p.kilogramos]);
          }
        } finally {
          alimento.close();
          comida.close();
          renglon.close();
          pesaje.close();
        }

        final nueva = actual + 1;
        _db.execute('UPDATE revision SET valor = ? WHERE id = 1', [nueva]);
        return Reemplazado(nueva);
      });

  void cerrar() => _db.close();

  /// Las escrituras usan `BEGIN IMMEDIATE`: toman el lock de escritura antes
  /// de leer la revisión, así nadie se cuela entre la comparación y el
  /// reemplazo. Las lecturas, `BEGIN` común: una foto consistente sin lock.
  T _transaccion<T>(T Function() cuerpo, {bool escritura = true}) {
    _db.execute(escritura ? 'BEGIN IMMEDIATE' : 'BEGIN');
    try {
      final resultado = cuerpo();
      _db.execute('COMMIT');
      return resultado;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }
}

/// Un REAL entero vuelve como entero JSON; el resto queda como double.
num? _numero(num? v) {
  if (v is double && v == v.truncateToDouble() && v.abs() < 1e15) {
    return v.toInt();
  }
  return v;
}
