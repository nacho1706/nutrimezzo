import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/diario.dart';

void main() {
  test('un Día vacío tiene macros en cero', () {
    final dia = Diario().hoy();

    expect(dia.macros.kcal, 0);
    expect(dia.macros.proteina, 0);
    expect(dia.macros.carbos, 0);
    expect(dia.macros.grasa, 0);
  });

  test('un Día vacío se mide contra la Meta por defecto', () {
    final diario = Diario();
    final dia = diario.hoy();
    final meta = diario.meta;

    expect(dia.macros.kcal, 0);
    expect(meta.macros.kcal, 2000);
    expect(meta.macros.proteina, 150);
    expect(meta.macros.carbos, 250);
    expect(meta.macros.grasa, 70);
  });

  test('hoy es la fecha local del reloj, no UTC', () {
    final diario = Diario(ahora: () => DateTime(2026, 9, 5, 23, 45));
    final fecha = diario.hoy().fecha;

    expect(fecha.year, 2026);
    expect(fecha.month, 9);
    expect(fecha.day, 5);
  });
}
