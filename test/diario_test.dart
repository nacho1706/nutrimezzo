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

  test('100g yogur griego extrae Cantidad 100 y el nombre', () {
    final diario = Diario();
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );

    final renglon = diario.borrador!.renglones.single;
    expect(renglon.cantidad, 100);
    expect(renglon.nombre, 'yogur griego');
  });

  test('100 g extrae Cantidad 100 aunque haya espacio antes de g', () {
    final diario = Diario();
    diario.redactarComida(momento: Momento.desayuno, notas: '100 g');

    final renglon = diario.borrador!.renglones.single;
    expect(renglon.cantidad, 100);
    expect(renglon.nombre, '');
  });

  test('100G extrae Cantidad 100 con g mayúscula', () {
    final diario = Diario();
    diario.redactarComida(momento: Momento.desayuno, notas: '100G');

    expect(diario.borrador!.renglones.single.cantidad, 100);
  });

  test('60g avena extrae Cantidad 60 y el nombre', () {
    final diario = Diario();
    diario.redactarComida(momento: Momento.desayuno, notas: '60g avena');

    final renglon = diario.borrador!.renglones.single;
    expect(renglon.cantidad, 60);
    expect(renglon.nombre, 'avena');
  });

  test('banana chica deja Cantidad vacía y conserva el nombre', () {
    final diario = Diario();
    diario.redactarComida(momento: Momento.desayuno, notas: 'banana chica');

    final renglon = diario.borrador!.renglones.single;
    expect(renglon.cantidad, isNull);
    expect(renglon.nombre, 'banana chica');
  });

  test('Enter parte las notas en un Renglón por línea', () {
    final diario = Diario();
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego\n60g avena\nbanana chica',
    );

    final renglones = diario.borrador!.renglones;
    expect(renglones, hasLength(3));
    expect(renglones[0].nombre, 'yogur griego');
    expect(renglones[0].cantidad, 100);
    expect(renglones[1].nombre, 'avena');
    expect(renglones[1].cantidad, 60);
    expect(renglones[2].nombre, 'banana chica');
    expect(renglones[2].cantidad, isNull);
  });

  test('las líneas en blanco no se vuelven Renglones', () {
    final diario = Diario();
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego\n\n60g avena\n   \nbanana chica\n',
    );

    expect(diario.borrador!.renglones, hasLength(3));
  });

  test('el borrador guarda el Momento elegido', () {
    final diario = Diario();
    for (final momento in Momento.values) {
      diario.redactarComida(momento: momento, notas: 'banana chica');
      expect(diario.borrador!.momento, momento);
    }
    expect(Momento.values, [
      Momento.desayuno,
      Momento.almuerzo,
      Momento.cena,
      Momento.extra,
    ]);
  });

  test('cancelar el borrador deja el Día de hoy sin cambios', () {
    final diario = Diario();
    final macrosAntes = diario.hoy().macros;
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego\n60g avena\nbanana chica',
    );

    diario.cancelarBorrador();

    expect(diario.borrador, isNull);
    expect(diario.hoy().macros.kcal, macrosAntes.kcal);
    expect(diario.hoy().macros.proteina, macrosAntes.proteina);
    expect(diario.hoy().macros.carbos, macrosAntes.carbos);
    expect(diario.hoy().macros.grasa, macrosAntes.grasa);
  });
}
