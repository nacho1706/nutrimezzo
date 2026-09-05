class Diario {
  Diario({DateTime Function()? ahora}) : _ahora = ahora ?? DateTime.now;

  final DateTime Function() _ahora;

  Dia hoy() {
    final ahora = _ahora();
    return Dia(
      fecha: DateTime(ahora.year, ahora.month, ahora.day),
      macros: Macros.cero,
    );
  }

  Meta get meta => Meta.porDefecto;
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
