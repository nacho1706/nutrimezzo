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

  test('guardar Meta reemplaza la Meta por defecto', () async {
    final diario = Diario();
    await diario.guardarMeta(
      const Meta(
        macros: Macros(kcal: 1800, proteina: 140, carbos: 180, grasa: 55),
      ),
    );

    final meta = diario.meta;
    expect(meta.macros.kcal, 1800);
    expect(meta.macros.proteina, 140);
    expect(meta.macros.carbos, 180);
    expect(meta.macros.grasa, 55);
  });

  test('guardar Meta de nuevo reemplaza la Meta anterior', () async {
    final diario = Diario();
    await diario.guardarMeta(
      const Meta(
        macros: Macros(kcal: 1800, proteina: 140, carbos: 180, grasa: 55),
      ),
    );
    await diario.guardarMeta(
      const Meta(
        macros: Macros(kcal: 2500, proteina: 180, carbos: 220, grasa: 80),
      ),
    );

    final meta = diario.meta;
    expect(meta.macros.kcal, 2500);
    expect(meta.macros.proteina, 180);
    expect(meta.macros.carbos, 220);
    expect(meta.macros.grasa, 80);
  });

  test('la Meta guardada se lee al reabrir el Diario', () async {
    Meta? persistida;
    final primero = Diario(
      persistir: (meta, _) async {
        persistida = meta;
      },
    );
    await primero.guardarMeta(
      const Meta(
        macros: Macros(kcal: 1800, proteina: 140, carbos: 180, grasa: 55),
      ),
    );

    final reabierto = Diario(meta: persistida);
    expect(reabierto.meta.macros.kcal, 1800);
    expect(reabierto.meta.macros.proteina, 140);
    expect(reabierto.meta.macros.carbos, 180);
    expect(reabierto.meta.macros.grasa, 55);
  });

  test('BYOK arranca en blanco', () {
    final byok = Diario().byok;

    expect(byok.urlBase, '');
    expect(byok.claveApi, '');
    expect(byok.idModelo, '');
  });

  test('guardar BYOK persiste URL, clave e id de modelo', () async {
    final diario = Diario();
    await diario.guardarByok(
      const Byok(
        urlBase: 'https://api.ejemplo.com/v1',
        claveApi: 'sk-secreto',
        idModelo: 'gpt-4o-mini',
      ),
    );

    final byok = diario.byok;
    expect(byok.urlBase, 'https://api.ejemplo.com/v1');
    expect(byok.claveApi, 'sk-secreto');
    expect(byok.idModelo, 'gpt-4o-mini');
  });

  test('guardar BYOK vacío borra URL, clave e id de modelo', () async {
    final diario = Diario();
    await diario.guardarByok(
      const Byok(
        urlBase: 'https://api.ejemplo.com/v1',
        claveApi: 'sk-secreto',
        idModelo: 'gpt-4o-mini',
      ),
    );
    await diario.guardarByok(Byok.vacio);

    final byok = diario.byok;
    expect(byok.urlBase, '');
    expect(byok.claveApi, '');
    expect(byok.idModelo, '');
  });

  test('el BYOK guardado se lee al reabrir el Diario', () async {
    Byok? persistido;
    final primero = Diario(
      persistir: (_, byok) async {
        persistido = byok;
      },
    );
    await primero.guardarByok(
      const Byok(
        urlBase: 'https://api.ejemplo.com/v1',
        claveApi: 'sk-secreto',
        idModelo: 'gpt-4o-mini',
      ),
    );

    final reabierto = Diario(byok: persistido);
    expect(reabierto.byok.urlBase, 'https://api.ejemplo.com/v1');
    expect(reabierto.byok.claveApi, 'sk-secreto');
    expect(reabierto.byok.idModelo, 'gpt-4o-mini');
  });

  test('el texto de Byok muestra URL y modelo, no la clave', () {
    const byok = Byok(
      urlBase: 'https://api.ejemplo.com/v1',
      claveApi: 'sk-secreto-que-no-debe-verse',
      idModelo: 'gpt-4o-mini',
    );

    expect('$byok', contains('https://api.ejemplo.com/v1'));
    expect('$byok', contains('gpt-4o-mini'));
    expect('$byok', isNot(contains('sk-secreto-que-no-debe-verse')));
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
