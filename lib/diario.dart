class Diario {
  Diario({
    DateTime Function()? ahora,
    Meta? meta,
    Byok? byok,
    PuertoBusquedaIA? busquedaIA,
    Iterable<Alimento> alimentos = const [],
    Iterable<Comida> comidas = const [],
    Iterable<Pesaje> pesajes = const [],
    Future<void> Function(Meta meta, Byok byok)? persistir,
    Future<void> Function(
      List<Alimento> alimentos,
      List<Comida> comidas,
      List<Pesaje> pesajes,
    )?
    persistirDiario,
  }) : _ahora = ahora ?? DateTime.now,
       _meta = meta ?? Meta.porDefecto,
       _byok = byok ?? Byok.vacio,
       // Public names; the fields stay private.
       // ignore: prefer_initializing_formals
       _busquedaIA = busquedaIA,
       _alimentos = List.of(alimentos),
       _comidas = List.of(comidas),
       _pesajes = List.of(pesajes),
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
    for (final comida in _comidas) {
      final numero = _numeroDeComidaId(comida.id);
      if (numero > _siguienteComidaId) {
        _siguienteComidaId = numero;
      }
    }
    for (var i = 0; i < _comidas.length; i++) {
      final comida = _comidas[i];
      if (comida.id.isNotEmpty) {
        continue;
      }
      _comidas[i] = comida.copiaCon(id: 'c${++_siguienteComidaId}');
    }
    _unificarComidas();
  }

  final DateTime Function() _ahora;
  final PuertoBusquedaIA? _busquedaIA;
  final Future<void> Function(Meta meta, Byok byok)? _persistir;
  final Future<void> Function(
    List<Alimento> alimentos,
    List<Comida> comidas,
    List<Pesaje> pesajes,
  )?
  _persistirDiario;
  Meta _meta;
  Byok _byok;
  Comida? _borrador;
  final List<Alimento> _alimentos;
  final List<Comida> _comidas;
  final List<Pesaje> _pesajes;
  List<RenglonResuelto> _resoluciones = const [];
  var _siguienteId = 0;
  var _siguienteComidaId = 0;

  Comida? get borrador => _borrador;

  List<Alimento> get alimentos => List.unmodifiable(_alimentos);

  List<RenglonResuelto> get resoluciones => List.unmodifiable(_resoluciones);

  Future<void> editarAlimento({
    required String id,
    String? nombre,
    Macros? macrosPor100g,
    String? patron,
  }) async {
    final indice = _alimentos.indexWhere((alimento) => alimento.id == id);
    if (indice < 0) {
      throw ArgumentError('alimento');
    }
    final actual = _alimentos[indice];
    final nombreFinal = nombre ?? actual.nombre;
    final patronFinal = patron == null
        ? actual.patron
        : (patron.trim().isEmpty
              ? _patronPorDefecto(nombreFinal)
              : patron.trim());
    _alimentos[indice] = Alimento(
      id: actual.id,
      nombre: nombreFinal,
      macrosPor100g: macrosPor100g ?? actual.macrosPor100g,
      patron: patronFinal,
      usadoPorUltimaVez: actual.usadoPorUltimaVez,
    );
    if (nombre != null && nombre != actual.nombre) {
      for (var i = 0; i < _comidas.length; i++) {
        final comida = _comidas[i];
        final renglones = [
          for (final renglon in comida.renglones)
            renglon.alimentoId == id
                ? Renglon(
                    nombre: nombre,
                    cantidad: renglon.cantidad,
                    alimentoId: renglon.alimentoId,
                  )
                : renglon,
        ];
        _comidas[i] = comida.copiaCon(renglones: renglones);
      }
    }
    await _escribirDiario();
  }

  Future<void> eliminarAlimento(String id) async {
    final indice = _alimentos.indexWhere((alimento) => alimento.id == id);
    if (indice < 0) {
      throw ArgumentError('alimento');
    }
    _alimentos.removeAt(indice);
    for (var i = _comidas.length - 1; i >= 0; i--) {
      final comida = _comidas[i];
      final renglones = [
        for (final renglon in comida.renglones)
          if (renglon.alimentoId != id) renglon,
      ];
      if (renglones.isEmpty) {
        _comidas.removeAt(i);
      } else if (renglones.length != comida.renglones.length) {
        _comidas[i] = comida.copiaCon(renglones: renglones);
      }
    }
    await _escribirDiario();
  }

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

  void redactarComida({
    required Momento momento,
    required String notas,
    DateTime? fecha,
  }) {
    _borrador = Comida(
      momento: momento,
      renglones: _parsearNotas(notas),
      fecha: fecha == null
          ? null
          : DateTime(fecha.year, fecha.month, fecha.day),
    );
    _resoluciones = const [];
  }

  Future<void> listo() async {
    final renglones = _borrador?.renglones ?? const <Renglon>[];
    final resoluciones = <RenglonResuelto>[];
    for (final renglon in renglones) {
      resoluciones.add(await _resolver(renglon));
    }
    _resoluciones = resoluciones;
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
      return await puerto.buscar(renglon);
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
    final fecha =
        borrador.fecha ?? DateTime(ahora.year, ahora.month, ahora.day);
    final indiceExistente = _indiceComidaEn(fecha, borrador.momento);
    if (indiceExistente == null) {
      _comidas.add(
        Comida(
          id: 'c${++_siguienteComidaId}',
          momento: borrador.momento,
          renglones: renglones,
          fecha: fecha,
          recibidoPorUltimaVez: ahora,
        ),
      );
    } else {
      _anexarRenglones(
        indiceExistente,
        renglones: renglones,
        recibidoPorUltimaVez: ahora,
      );
    }
    cancelarBorrador();
    await _escribirDiario();
  }

  Future<void> editarRenglon({
    required String comidaId,
    required int indice,
    num? cantidad,
    String? alimentoId,
  }) async {
    if (cantidad != null && cantidad <= 0) {
      throw ArgumentError('cantidad');
    }
    final indiceComida = _indiceComida(comidaId);
    final comida = _comidas[indiceComida];
    if (indice < 0 || indice >= comida.renglones.length) {
      throw ArgumentError('indice');
    }
    final actual = comida.renglones[indice];
    var nombre = actual.nombre;
    var idAlimento = actual.alimentoId;
    if (alimentoId != null) {
      final alimento = _alimentos.firstWhere(
        (candidato) => candidato.id == alimentoId,
        orElse: () => throw ArgumentError('alimento'),
      );
      nombre = alimento.nombre;
      idAlimento = alimento.id;
      _marcarUso(alimentoId);
    }
    final renglones = List<Renglon>.of(comida.renglones);
    renglones[indice] = Renglon(
      nombre: nombre,
      cantidad: cantidad ?? actual.cantidad,
      alimentoId: idAlimento,
    );
    _comidas[indiceComida] = comida.copiaCon(renglones: renglones);
    await _escribirDiario();
  }

  Future<void> eliminarRenglon({
    required String comidaId,
    required int indice,
  }) async {
    final indiceComida = _indiceComida(comidaId);
    final comida = _comidas[indiceComida];
    if (indice < 0 || indice >= comida.renglones.length) {
      throw ArgumentError('indice');
    }
    final renglones = List<Renglon>.of(comida.renglones)..removeAt(indice);
    if (renglones.isEmpty) {
      _comidas.removeAt(indiceComida);
    } else {
      _comidas[indiceComida] = comida.copiaCon(renglones: renglones);
    }
    await _escribirDiario();
  }

  Future<void> eliminarComida(String comidaId) async {
    final indiceComida = _indiceComida(comidaId);
    _comidas.removeAt(indiceComida);
    await _escribirDiario();
  }

  Future<void> cambiarMomento(String comidaId, Momento momento) async {
    final indiceComida = _indiceComida(comidaId);
    final comida = _comidas[indiceComida];
    if (comida.momento == momento) {
      return;
    }
    final fecha = comida.fecha;
    final indiceDestino = fecha == null
        ? null
        : _indiceComidaEn(fecha, momento);
    if (indiceDestino == null) {
      _comidas[indiceComida] = comida.copiaCon(momento: momento);
    } else {
      final destino = _comidas[indiceDestino];
      _anexarRenglones(
        indiceDestino,
        renglones: comida.renglones,
        recibidoPorUltimaVez: _elMasTarde(
          destino.recibidoPorUltimaVez,
          comida.recibidoPorUltimaVez,
        ),
      );
      _comidas.removeAt(indiceComida);
    }
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
    return dia(_ahora());
  }

  Dia dia(DateTime fecha) {
    final fechaDia = DateTime(fecha.year, fecha.month, fecha.day);
    final comidas = [
      for (final comida in _comidas)
        if (comida.fecha == fechaDia) comida,
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
    return Dia(fecha: fechaDia, macros: macros, comidas: comidas);
  }

  Pesaje? pesajeDe(DateTime fecha) {
    final fechaDia = DateTime(fecha.year, fecha.month, fecha.day);
    for (final pesaje in _pesajes) {
      if (pesaje.fecha == fechaDia) {
        return pesaje;
      }
    }
    return null;
  }

  Future<void> guardarPesaje({
    required DateTime fecha,
    required num kilogramos,
  }) async {
    if (kilogramos <= 0 || !_unDecimalOEntero(kilogramos)) {
      throw ArgumentError('kilogramos');
    }
    final fechaDia = DateTime(fecha.year, fecha.month, fecha.day);
    final siguiente = Pesaje(fecha: fechaDia, kilogramos: kilogramos);
    final indice = _pesajes.indexWhere((pesaje) => pesaje.fecha == fechaDia);
    if (indice < 0) {
      _pesajes.add(siguiente);
    } else {
      _pesajes[indice] = siguiente;
    }
    await _escribirDiario();
  }

  Cumplimiento cumplimientoDe(DateTime fecha) {
    final dia = this.dia(fecha);
    if (dia.comidas.isEmpty) {
      return Cumplimiento.ninguno;
    }
    if (dia.macros.kcal > _meta.macros.kcal) {
      return Cumplimiento.rojo;
    }
    if (dia.macros.proteina < _meta.macros.proteina) {
      return Cumplimiento.amarillo;
    }
    return Cumplimiento.verde;
  }

  Momento momentoDeCaptura(DateTime fecha) {
    final fechaDia = DateTime(fecha.year, fecha.month, fecha.day);
    Comida? elegida;
    for (final comida in _comidas) {
      if (comida.fecha != fechaDia) {
        continue;
      }
      if (elegida == null) {
        elegida = comida;
        continue;
      }
      elegida = _masReciente(elegida, comida);
    }
    return elegida?.momento ?? Momento.desayuno;
  }

  List<Renglon> renglonesDe({
    required DateTime fecha,
    required Momento momento,
  }) {
    return comidaDe(fecha: fecha, momento: momento)?.renglones ?? const [];
  }

  Comida? comidaDe({required DateTime fecha, required Momento momento}) {
    final fechaDia = DateTime(fecha.year, fecha.month, fecha.day);
    final indice = _indiceComidaEn(fechaDia, momento);
    if (indice == null) {
      return null;
    }
    return _comidas[indice];
  }

  Macros macrosDe(Renglon renglon) {
    final id = renglon.alimentoId;
    final cantidad = renglon.cantidad;
    if (id == null || cantidad == null) {
      return Macros.cero;
    }
    final alimento = _alimentos.firstWhere((candidato) => candidato.id == id);
    return alimento.macrosPor100g.paraGramos(cantidad);
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
      List.unmodifiable(_pesajes),
    );
  }

  int _indiceComida(String comidaId) {
    final indice = _comidas.indexWhere((comida) => comida.id == comidaId);
    if (indice < 0) {
      throw ArgumentError('comida');
    }
    return indice;
  }

  int? _indiceComidaEn(DateTime fecha, Momento momento) {
    final indice = _comidas.indexWhere(
      (comida) => comida.fecha == fecha && comida.momento == momento,
    );
    if (indice < 0) {
      return null;
    }
    return indice;
  }

  void _anexarRenglones(
    int indice, {
    required List<Renglon> renglones,
    DateTime? recibidoPorUltimaVez,
  }) {
    final comida = _comidas[indice];
    _comidas[indice] = comida.copiaCon(
      renglones: [...comida.renglones, ...renglones],
      recibidoPorUltimaVez: recibidoPorUltimaVez,
    );
  }

  void _unificarComidas() {
    final unidas = <Comida>[];
    final indicePorClave = <String, int>{};
    for (final comida in _comidas) {
      final clave = '${comida.fecha}-${comida.momento.name}';
      final indice = indicePorClave[clave];
      if (indice == null) {
        indicePorClave[clave] = unidas.length;
        unidas.add(comida);
        continue;
      }
      final previa = unidas[indice];
      unidas[indice] = previa.copiaCon(
        renglones: [...previa.renglones, ...comida.renglones],
        recibidoPorUltimaVez: _elMasTarde(
          previa.recibidoPorUltimaVez,
          comida.recibidoPorUltimaVez,
        ),
      );
    }
    _comidas
      ..clear()
      ..addAll(unidas);
  }
}

DateTime? _elMasTarde(DateTime? a, DateTime? b) {
  if (a == null) {
    return b;
  }
  if (b == null) {
    return a;
  }
  return b.isAfter(a) ? b : a;
}

Comida _masReciente(Comida a, Comida b) {
  final ta = a.recibidoPorUltimaVez;
  final tb = b.recibidoPorUltimaVez;
  if (ta == null && tb == null) {
    return b;
  }
  if (ta == null) {
    return b;
  }
  if (tb == null) {
    return a;
  }
  return tb.isAfter(ta) ? b : a;
}

int _numeroDeId(String id) {
  if (!id.startsWith('a')) {
    return 0;
  }
  return int.tryParse(id.substring(1)) ?? 0;
}

int _numeroDeComidaId(String id) {
  if (!id.startsWith('c')) {
    return 0;
  }
  return int.tryParse(id.substring(1)) ?? 0;
}

bool _unDecimalOEntero(num valor) {
  final decimos = valor * 10;
  return (decimos - decimos.roundToDouble()).abs() < 1e-8;
}

String _patronPorDefecto(String nombre) => _normalizar(nombre);

String _normalizar(String texto) {
  return texto.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

bool _patronPega(String patron, String nombre) {
  final regex = _regexDePatron(patron);
  if (regex != null) {
    return regex.hasMatch(_normalizar(nombre));
  }
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

RegExp? _regexDePatron(String patron) {
  var fuente = patron.trim();
  if (!_pareceRegex(fuente)) {
    return null;
  }
  if (fuente.startsWith('(?i)')) {
    fuente = fuente.substring(4);
  }
  try {
    return RegExp(fuente, caseSensitive: false);
  } catch (_) {
    return null;
  }
}

bool _pareceRegex(String patron) {
  return patron.startsWith('(?i)') ||
      RegExp(r'[.\\^$*+?()\[\]{}|]').hasMatch(patron);
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

enum Cumplimiento { ninguno, rojo, amarillo, verde }

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
    if (propuestas.isEmpty) {
      return null;
    }
    return propuestas.first.gramosAsumidos;
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
  const Comida({
    required this.momento,
    required this.renglones,
    this.fecha,
    this.id = '',
    this.recibidoPorUltimaVez,
  });

  final String id;
  final Momento momento;
  final List<Renglon> renglones;
  final DateTime? fecha;
  final DateTime? recibidoPorUltimaVez;

  Comida copiaCon({
    String? id,
    Momento? momento,
    DateTime? fecha,
    List<Renglon>? renglones,
    DateTime? recibidoPorUltimaVez,
  }) {
    return Comida(
      id: id ?? this.id,
      momento: momento ?? this.momento,
      fecha: fecha ?? this.fecha,
      renglones: renglones ?? this.renglones,
      recibidoPorUltimaVez: recibidoPorUltimaVez ?? this.recibidoPorUltimaVez,
    );
  }
}

class Pesaje {
  const Pesaje({required this.fecha, required this.kilogramos});

  final DateTime fecha;
  final num kilogramos;
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
