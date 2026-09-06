class Diario {
  Diario({
    DateTime Function()? ahora,
    Meta? meta,
    Byok? byok,
    PuertoBusquedaIA? busquedaIA,
    Iterable<Alimento> alimentos = const [],
    Iterable<Comida> comidas = const [],
    Future<void> Function(Meta meta, Byok byok)? persistir,
    Future<void> Function(List<Alimento> alimentos, List<Comida> comidas)?
    persistirDiario,
  }) : _ahora = ahora ?? DateTime.now,
       _meta = meta ?? Meta.porDefecto,
       _byok = byok ?? Byok.vacio,
       // Public names; the fields stay private.
       // ignore: prefer_initializing_formals
       _busquedaIA = busquedaIA,
       _alimentos = List.of(alimentos),
       _comidas = List.of(comidas),
       // ignore: prefer_initializing_formals
       _persistirDiario = persistirDiario,
       // Public name `persistir`; the field stays private.
       // ignore: prefer_initializing_formals
       _persistir = persistir {
    for (final alimento in _alimentos) {
      final numero = _numeroDeId(alimento.id);
      if (numero > _siguienteId) {
        _siguienteId = numero;
      }
    }
  }

  final DateTime Function() _ahora;
  final PuertoBusquedaIA? _busquedaIA;
  final Future<void> Function(Meta meta, Byok byok)? _persistir;
  final Future<void> Function(List<Alimento> alimentos, List<Comida> comidas)?
  _persistirDiario;
  Meta _meta;
  Byok _byok;
  Comida? _borrador;
  final List<Alimento> _alimentos;
  final List<Comida> _comidas;
  List<RenglonResuelto> _resoluciones = const [];
  var _siguienteId = 0;

  Comida? get borrador => _borrador;

  List<Alimento> get alimentos => List.unmodifiable(_alimentos);

  List<RenglonResuelto> get resoluciones => List.unmodifiable(_resoluciones);

  Future<Alimento> crearAlimento({
    required String nombre,
    required Macros macrosPor100g,
    String? patron,
  }) async {
    final alimento = Alimento(
      id: 'a${++_siguienteId}',
      nombre: nombre,
      macrosPor100g: macrosPor100g,
      patron: patron ?? _patronPorDefecto(nombre),
      usadoPorUltimaVez: _ahora(),
    );
    _alimentos.add(alimento);
    await _escribirDiario();
    return alimento;
  }

  void cancelarBorrador() {
    _borrador = null;
    _resoluciones = const [];
  }

  void redactarComida({required Momento momento, required String notas}) {
    _borrador = Comida(momento: momento, renglones: _parsearNotas(notas));
    _resoluciones = const [];
  }

  Future<void> listo() async {
    final renglones = _borrador?.renglones ?? const <Renglon>[];
    _resoluciones = await Future.wait(renglones.map(_resolver));
  }

  Future<RenglonResuelto> _resolver(Renglon renglon) async {
    final locales = _propuestasLocales(renglon);
    final ia = await _buscarIA(renglon);
    return RenglonResuelto(
      renglon: renglon,
      propuestas: _combinar(locales, ia),
    );
  }

  Future<List<Propuesta>> _buscarIA(Renglon renglon) async {
    final puerto = _busquedaIA;
    if (puerto == null) {
      return const [];
    }
    try {
      return (await puerto.buscar(renglon)).take(2).toList();
    } catch (_) {
      return const [];
    }
  }

  List<Propuesta> _combinar(List<Propuesta> locales, List<Propuesta> ia) {
    final propuestas = <Propuesta>[];
    if (locales.isNotEmpty) {
      propuestas.add(locales.first);
    }
    for (final candidata in ia) {
      if (propuestas.length >= 2) {
        break;
      }
      if (propuestas.any((ya) => _mismaPropuesta(ya, candidata))) {
        continue;
      }
      propuestas.add(candidata);
    }
    return propuestas;
  }

  bool _mismaPropuesta(Propuesta a, Propuesta b) {
    if (a.alimentoId != null &&
        b.alimentoId != null &&
        a.alimentoId == b.alimentoId) {
      return true;
    }
    return _normalizar(a.nombre) == _normalizar(b.nombre);
  }

  List<Propuesta> _propuestasLocales(Renglon renglon) {
    final coincidencias = _alimentos
        .where((alimento) => _patronPega(alimento.patron, renglon.nombre))
        .toList();
    if (coincidencias.isEmpty) {
      return const [];
    }
    coincidencias.sort(_compararEspecificidadLuegoRecencia);
    final mejor = coincidencias.first;
    return [
      Propuesta(
        nombre: mejor.nombre,
        macrosPor100g: mejor.macrosPor100g,
        alimentoId: mejor.id,
      ),
    ];
  }

  int _compararEspecificidadLuegoRecencia(Alimento a, Alimento b) {
    final porPalabras = _especificidad(b).compareTo(_especificidad(a));
    if (porPalabras != 0) {
      return porPalabras;
    }
    return b.usadoPorUltimaVez.compareTo(a.usadoPorUltimaVez);
  }

  Future<void> confirmar(List<EleccionRenglon> elecciones) async {
    final borrador = _borrador;
    if (borrador == null) {
      throw StateError('no hay borrador');
    }
    if (elecciones.length != borrador.renglones.length) {
      throw ArgumentError('elecciones');
    }
    final renglones = <Renglon>[];
    for (final eleccion in elecciones) {
      if (eleccion.cantidad <= 0) {
        throw ArgumentError('cantidad');
      }
      final alimento = await _alimentoDe(eleccion);
      renglones.add(
        Renglon(
          nombre: alimento.nombre,
          cantidad: eleccion.cantidad,
          alimentoId: alimento.id,
        ),
      );
    }
    final ahora = _ahora();
    _comidas.add(
      Comida(
        momento: borrador.momento,
        renglones: renglones,
        fecha: DateTime(ahora.year, ahora.month, ahora.day),
      ),
    );
    cancelarBorrador();
    await _escribirDiario();
  }

  Future<Alimento> _alimentoDe(EleccionRenglon eleccion) async {
    final propuesta = eleccion.propuesta;
    if (propuesta != null) {
      if (propuesta.alimentoId != null) {
        return _marcarUso(propuesta.alimentoId!);
      }
      return crearAlimento(
        nombre: propuesta.nombre,
        macrosPor100g: propuesta.macrosPor100g,
      );
    }
    final nombre = eleccion.crearNombre;
    final macros = eleccion.crearMacros;
    if (nombre == null || nombre.trim().isEmpty || macros == null) {
      throw ArgumentError('crear');
    }
    return crearAlimento(nombre: nombre, macrosPor100g: macros);
  }

  Alimento _marcarUso(String id) {
    final indice = _alimentos.indexWhere((alimento) => alimento.id == id);
    final actual = _alimentos[indice];
    final tocado = Alimento(
      id: actual.id,
      nombre: actual.nombre,
      macrosPor100g: actual.macrosPor100g,
      patron: actual.patron,
      usadoPorUltimaVez: _ahora(),
    );
    _alimentos[indice] = tocado;
    return tocado;
  }

  List<Renglon> _parsearNotas(String notas) {
    return notas
        .split(RegExp(r'\r?\n'))
        .map((linea) => linea.trim())
        .where((linea) => linea.isNotEmpty)
        .map(_parsearLinea)
        .toList();
  }

  Renglon _parsearLinea(String linea) {
    final match = RegExp(r'^(\d+)\s*[gG](?:\s+(.*))?$').firstMatch(linea);
    if (match == null) {
      return Renglon(nombre: linea);
    }
    return Renglon(
      nombre: match.group(2) ?? '',
      cantidad: int.parse(match.group(1)!),
    );
  }

  Dia hoy() {
    final ahora = _ahora();
    final fecha = DateTime(ahora.year, ahora.month, ahora.day);
    final comidas = [
      for (final comida in _comidas)
        if (comida.fecha == fecha) comida,
    ];
    var macros = Macros.cero;
    for (final comida in comidas) {
      for (final renglon in comida.renglones) {
        final alimento = _alimentos.firstWhere(
          (candidato) => candidato.id == renglon.alimentoId,
        );
        macros = macros + alimento.macrosPor100g.paraGramos(renglon.cantidad!);
      }
    }
    return Dia(fecha: fecha, macros: macros, comidas: comidas);
  }

  Meta get meta => _meta;

  Byok get byok => _byok;

  Future<void> guardarMeta(Meta meta) async {
    _meta = meta;
    await _escribir();
  }

  Future<void> guardarByok(Byok byok) async {
    _byok = byok;
    await _escribir();
  }

  Future<void> _escribir() async {
    await _persistir?.call(_meta, _byok);
  }

  Future<void> _escribirDiario() async {
    await _persistirDiario?.call(
      List.unmodifiable(_alimentos),
      List.unmodifiable(_comidas),
    );
  }
}

int _numeroDeId(String id) {
  if (!id.startsWith('a')) {
    return 0;
  }
  return int.tryParse(id.substring(1)) ?? 0;
}

String _patronPorDefecto(String nombre) => _normalizar(nombre);

String _normalizar(String texto) {
  return texto.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

bool _patronPega(String patron, String nombre) {
  final palabrasNombre = _normalizar(nombre)
      .split(' ')
      .where((palabra) => palabra.isNotEmpty)
      .toSet();
  final palabrasPatron = _normalizar(patron)
      .split(' ')
      .where((palabra) => palabra.isNotEmpty);
  if (palabrasPatron.isEmpty || palabrasNombre.isEmpty) {
    return false;
  }
  return palabrasPatron.every(palabrasNombre.contains);
}

int _especificidad(Alimento alimento) {
  final palabras = _normalizar(alimento.patron)
      .split(' ')
      .where((palabra) => palabra.isNotEmpty);
  return palabras.length * 1000 + alimento.patron.length;
}

abstract class PuertoBusquedaIA {
  Future<List<Propuesta>> buscar(Renglon renglon);
}

enum Momento {
  desayuno,
  almuerzo,
  cena,
  extra;

  String get etiqueta => switch (this) {
    desayuno => 'Desayuno',
    almuerzo => 'Almuerzo',
    cena => 'Cena',
    extra => 'Extra',
  };
}

class Alimento {
  const Alimento({
    required this.id,
    required this.nombre,
    required this.macrosPor100g,
    required this.patron,
    required this.usadoPorUltimaVez,
  });

  final String id;
  final String nombre;
  final Macros macrosPor100g;
  final String patron;
  final DateTime usadoPorUltimaVez;
}

class Propuesta {
  const Propuesta({
    required this.nombre,
    required this.macrosPor100g,
    this.alimentoId,
    this.gramosAsumidos,
  });

  final String? alimentoId;
  final String nombre;
  final Macros macrosPor100g;
  final num? gramosAsumidos;
}

class RenglonResuelto {
  const RenglonResuelto({required this.renglon, required this.propuestas});

  final Renglon renglon;
  final List<Propuesta> propuestas;

  bool get ofreceCrearAlimento => propuestas.isEmpty;

  num? get cantidadSugerida {
    final parseada = renglon.cantidad;
    if (parseada != null) {
      return parseada;
    }
    for (final propuesta in propuestas) {
      if (propuesta.gramosAsumidos != null) {
        return propuesta.gramosAsumidos;
      }
    }
    return null;
  }
}

class EleccionRenglon {
  const EleccionRenglon({
    required this.cantidad,
    this.propuesta,
    this.crearNombre,
    this.crearMacros,
  });

  final num cantidad;
  final Propuesta? propuesta;
  final String? crearNombre;
  final Macros? crearMacros;
}

class Renglon {
  const Renglon({required this.nombre, this.cantidad, this.alimentoId});

  final String nombre;
  final num? cantidad;
  final String? alimentoId;
}

class Comida {
  const Comida({required this.momento, required this.renglones, this.fecha});

  final Momento momento;
  final List<Renglon> renglones;
  final DateTime? fecha;
}

class Dia {
  const Dia({
    required this.fecha,
    required this.macros,
    this.comidas = const [],
  });

  final DateTime fecha;
  final Macros macros;
  final List<Comida> comidas;
}

class Meta {
  const Meta({required this.macros});

  static const porDefecto = Meta(
    macros: Macros(kcal: 2000, proteina: 150, carbos: 250, grasa: 70),
  );

  final Macros macros;
}

class Macros {
  const Macros({
    required this.kcal,
    required this.proteina,
    required this.carbos,
    required this.grasa,
  });

  static const cero = Macros(kcal: 0, proteina: 0, carbos: 0, grasa: 0);

  final num kcal;
  final num proteina;
  final num carbos;
  final num grasa;

  Macros operator +(Macros otro) {
    return Macros(
      kcal: kcal + otro.kcal,
      proteina: proteina + otro.proteina,
      carbos: carbos + otro.carbos,
      grasa: grasa + otro.grasa,
    );
  }

  Macros paraGramos(num gramos) {
    return Macros(
      kcal: kcal * gramos / 100,
      proteina: proteina * gramos / 100,
      carbos: carbos * gramos / 100,
      grasa: grasa * gramos / 100,
    );
  }
}

class Byok {
  const Byok({
    required this.urlBase,
    required this.claveApi,
    required this.idModelo,
  });

  static const vacio = Byok(urlBase: '', claveApi: '', idModelo: '');

  final String urlBase;
  final String claveApi;
  final String idModelo;

  @override
  String toString() => 'Byok(urlBase: $urlBase, idModelo: $idModelo)';
}
