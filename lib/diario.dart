class Diario {
  Diario({DateTime Function()? ahora}) : _ahora = ahora ?? DateTime.now;

  final DateTime Function() _ahora;
  Comida? _borrador;

  Comida? get borrador => _borrador;

  void cancelarBorrador() {
    _borrador = null;
  }

  void redactarComida({required Momento momento, required String notas}) {
    _borrador = Comida(
      momento: momento,
      renglones: _parsearNotas(notas),
    );
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
    return Dia(
      fecha: DateTime(ahora.year, ahora.month, ahora.day),
      macros: Macros.cero,
    );
  }

  Meta get meta => Meta.porDefecto;
}

enum Momento { desayuno, almuerzo, cena, extra }

class Renglon {
  const Renglon({required this.nombre, this.cantidad});

  final String nombre;
  final num? cantidad;
}

class Comida {
  const Comida({required this.momento, required this.renglones});

  final Momento momento;
  final List<Renglon> renglones;
}

class Dia {
  const Dia({required this.fecha, required this.macros});

  final DateTime fecha;
  final Macros macros;
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

  static const cero = Macros(
    kcal: 0,
    proteina: 0,
    carbos: 0,
    grasa: 0,
  );

  final num kcal;
  final num proteina;
  final num carbos;
  final num grasa;
}
