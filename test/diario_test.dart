import 'dart:async';

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

  test('una fecha sin Comida tiene Cumplimiento ninguno aunque los macros sean cero', () {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));

    expect(diario.hoy().macros.kcal, 0);
    expect(diario.cumplimientoDe(DateTime(2026, 9, 6)), Cumplimiento.ninguno);
  });

  test('kcal por encima de la Meta es rojo aunque la proteína esté alta', () {
    const macros = Macros(kcal: 2100, proteina: 200, carbos: 10, grasa: 10);
    final alimento = Alimento(
      id: 'a1',
      nombre: 'prueba',
      macrosPor100g: macros,
      patron: 'prueba',
      usadoPorUltimaVez: DateTime(2026, 9, 5, 8),
    );
    final diario = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      alimentos: [alimento],
      comidas: [
        Comida(
          id: 'c1',
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 5),
          renglones: [
            Renglon(nombre: 'prueba', cantidad: 100, alimentoId: alimento.id),
          ],
        ),
      ],
    );

    expect(diario.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.rojo);
  });

  test('kcal no por encima y proteína bajo la Meta es amarillo', () {
    final diario = _diarioConDia(
      fecha: DateTime(2026, 9, 5),
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );

    expect(diario.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.amarillo);
  });

  test('kcal no por encima y proteína en o sobre la Meta es verde', () {
    final enElPiso = _diarioConDia(
      fecha: DateTime(2026, 9, 5),
      macrosPor100g: const Macros(
        kcal: 1800,
        proteina: 150,
        carbos: 10,
        grasa: 10,
      ),
    );
    final sobreElPiso = _diarioConDia(
      fecha: DateTime(2026, 9, 5),
      macrosPor100g: const Macros(
        kcal: 1800,
        proteina: 200,
        carbos: 10,
        grasa: 10,
      ),
    );

    expect(enElPiso.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.verde);
    expect(
      sobreElPiso.cumplimientoDe(DateTime(2026, 9, 5)),
      Cumplimiento.verde,
    );
  });

  test('kcal exactamente en la Meta no es rojo; proteína exactamente en la Meta no es amarillo', () {
    final justo = _diarioConDia(
      fecha: DateTime(2026, 9, 5),
      macrosPor100g: const Macros(
        kcal: 2000,
        proteina: 150,
        carbos: 10,
        grasa: 10,
      ),
    );
    final techoSinPiso = _diarioConDia(
      fecha: DateTime(2026, 9, 5),
      macrosPor100g: const Macros(
        kcal: 2000,
        proteina: 149,
        carbos: 10,
        grasa: 10,
      ),
    );

    expect(justo.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.verde);
    expect(
      techoSinPiso.cumplimientoDe(DateTime(2026, 9, 5)),
      Cumplimiento.amarillo,
    );
  });

  test('carbos y grasa no cambian el Cumplimiento', () {
    final verdeConCarbos = _diarioConDia(
      fecha: DateTime(2026, 9, 5),
      macrosPor100g: const Macros(
        kcal: 1800,
        proteina: 160,
        carbos: 900,
        grasa: 200,
      ),
    );
    final amarilloConGrasa = _diarioConDia(
      fecha: DateTime(2026, 9, 5),
      macrosPor100g: const Macros(
        kcal: 1800,
        proteina: 10,
        carbos: 900,
        grasa: 200,
      ),
    );

    expect(
      verdeConCarbos.cumplimientoDe(DateTime(2026, 9, 5)),
      Cumplimiento.verde,
    );
    expect(
      amarilloConGrasa.cumplimientoDe(DateTime(2026, 9, 5)),
      Cumplimiento.amarillo,
    );
  });

  test(
    'subir el techo de kcal de la Meta rejuzga un Día rojo a verde',
    () async {
      final diario = _diarioConDia(
        fecha: DateTime(2026, 9, 5),
        macrosPor100g: const Macros(
          kcal: 2100,
          proteina: 160,
          carbos: 10,
          grasa: 10,
        ),
      );
      expect(diario.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.rojo);

      await diario.guardarMeta(
        const Meta(
          macros: Macros(kcal: 2200, proteina: 150, carbos: 250, grasa: 70),
        ),
      );

      expect(diario.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.verde);
    },
  );

  test(
    'editar un Alimento para que las kcal superen la Meta deja el Día rojo',
    () async {
      final diario = _diarioConDia(
        fecha: DateTime(2026, 9, 5),
        macrosPor100g: const Macros(
          kcal: 1800,
          proteina: 160,
          carbos: 10,
          grasa: 10,
        ),
      );
      expect(diario.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.verde);

      await diario.editarAlimento(
        id: 'a1',
        macrosPor100g: const Macros(
          kcal: 2100,
          proteina: 160,
          carbos: 10,
          grasa: 10,
        ),
      );

      expect(diario.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.rojo);
    },
  );

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

  test(
    '2 huevos no parsea 2 g: el nombre es la línea y Cantidad queda vacía',
    () {
      final diario = Diario();
      diario.redactarComida(momento: Momento.desayuno, notas: '2 huevos');

      final renglon = diario.borrador!.renglones.single;
      expect(renglon.cantidad, isNull);
      expect(renglon.nombre, '2 huevos');
    },
  );

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

  test(
    'crear un Alimento lo lista en el catálogo con Patrón derivado del nombre',
    () async {
      final diario = Diario();
      final alimento = await diario.crearAlimento(
        nombre: 'Yogur Griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );

      expect(diario.alimentos, hasLength(1));
      expect(alimento.nombre, 'Yogur Griego');
      expect(alimento.patron, 'yogur griego');
      expect(alimento.macrosPor100g.kcal, 97);
      expect(alimento.macrosPor100g.proteina, 10);
      expect(alimento.macrosPor100g.carbos, 3.6);
      expect(alimento.macrosPor100g.grasa, 5);
      expect(diario.alimentos.single.id, alimento.id);
    },
  );

  test('Listo pone el Alimento local cuyo Patrón pega con el nombre, no la Cantidad', () async {
    final diario = Diario();
    final yogur = await diario.crearAlimento(
      nombre: 'Yogur Griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g Yogur Griego',
    );

    await diario.listo();

    final resuelto = diario.resoluciones.single;
    expect(resuelto.renglon.nombre, 'Yogur Griego');
    expect(resuelto.renglon.cantidad, 100);
    expect(resuelto.propuestas, hasLength(1));
    expect(resuelto.propuestas.single.alimentoId, yogur.id);
    expect(resuelto.propuestas.single.nombre, 'Yogur Griego');
  });

  test('entre coincidencias locales gana el Patrón más específico', () async {
    final diario = Diario();
    await diario.crearAlimento(
      nombre: 'avena',
      macrosPor100g: const Macros(
        kcal: 370,
        proteina: 13,
        carbos: 60,
        grasa: 7,
      ),
    );
    final instantanea = await diario.crearAlimento(
      nombre: 'avena instantanea',
      macrosPor100g: const Macros(
        kcal: 360,
        proteina: 12,
        carbos: 62,
        grasa: 6,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '60g avena instantanea',
    );

    await diario.listo();

    expect(
      diario.resoluciones.single.propuestas.single.alimentoId,
      instantanea.id,
    );
  });

  test(
    'si dos Patrones empatan, gana el Alimento usado más recientemente',
    () async {
      var ahora = DateTime(2026, 9, 6, 8);
      final diario = Diario(ahora: () => ahora);
      await diario.crearAlimento(
        nombre: 'Avena marca A',
        macrosPor100g: const Macros(
          kcal: 370,
          proteina: 13,
          carbos: 60,
          grasa: 7,
        ),
        patron: 'avena',
      );
      ahora = DateTime(2026, 9, 6, 9);
      final reciente = await diario.crearAlimento(
        nombre: 'Avena marca B',
        macrosPor100g: const Macros(
          kcal: 380,
          proteina: 14,
          carbos: 58,
          grasa: 8,
        ),
        patron: 'avena',
      );
      diario.redactarComida(momento: Momento.desayuno, notas: '60g avena');

      await diario.listo();

      expect(
        diario.resoluciones.single.propuestas.single.alimentoId,
        reciente.id,
      );
    },
  );

  test(
    'sin PuertoBusquedaIA, Listo igual resuelve el catálogo local',
    () async {
      final diario = Diario();
      final yogur = await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
      );

      await diario.listo();

      expect(diario.resoluciones.single.propuestas.single.alimentoId, yogur.id);
    },
  );

  test(
    'un PuertoBusquedaIA vacío o roto no tapa la coincidencia local',
    () async {
      final diario = Diario(busquedaIA: _PuertoBusquedaIARoto());
      final yogur = await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
      );

      await diario.listo();

      expect(diario.resoluciones.single.propuestas.single.alimentoId, yogur.id);
    },
  );

  test('confirmar una Propuesta local reutiliza el Alimento y lo anota en el Día de hoy', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    final yogur = await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();

    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    expect(diario.alimentos, hasLength(1));
    expect(diario.alimentos.single.id, yogur.id);
    expect(diario.borrador, isNull);
    final dia = diario.hoy();
    expect(dia.comidas, hasLength(1));
    expect(dia.comidas.single.momento, Momento.desayuno);
    expect(dia.comidas.single.renglones.single.alimentoId, yogur.id);
    expect(dia.comidas.single.renglones.single.cantidad, 100);
  });

  test('200 g del mismo Alimento duplican los macros de 100 g y no clonan el catálogo', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego\n200g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      for (final resolucion in diario.resoluciones)
        EleccionRenglon(
          cantidad: resolucion.renglon.cantidad!,
          propuesta: resolucion.propuestas.single,
        ),
    ]);

    expect(diario.alimentos, hasLength(1));
    final macros = diario.hoy().macros;
    expect(macros.kcal, 291);
    expect(macros.proteina, 30);
    expect(macros.carbos, 10.8);
    expect(macros.grasa, 15);
    expect(diario.hoy().comidas.single.renglones, hasLength(2));
    expect(
      diario
          .hoy()
          .comidas
          .single
          .renglones
          .map((renglon) => renglon.alimentoId)
          .toSet(),
      {diario.alimentos.single.id},
    );
  });

  test(
    'Hoy agrupa las Comidas por Momento, que no es un presupuesto',
    () async {
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 100,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);
      diario.redactarComida(
        momento: Momento.almuerzo,
        notas: '200g yogur griego',
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 200,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);

      final dia = diario.hoy();
      expect(dia.comidas, hasLength(2));
      expect(dia.comidas[0].momento, Momento.desayuno);
      expect(dia.comidas[1].momento, Momento.almuerzo);
      expect(dia.macros.kcal, 291);
      expect(diario.meta.macros.kcal, 2000);
    },
  );

  test('el catálogo y las Comidas se leen al reabrir el Diario', () async {
    List<Alimento>? alimentos;
    List<Comida>? comidas;
    final primero = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      persistirDiario: (catalogo, registradas, pesajes) async {
        alimentos = List.of(catalogo);
        comidas = List.of(registradas);
      },
    );
    await primero.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    primero.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await primero.listo();
    await primero.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: primero.resoluciones.single.propuestas.single,
      ),
    ]);

    final reabierto = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      alimentos: alimentos!,
      comidas: comidas!,
    );
    expect(reabierto.alimentos.single.nombre, 'yogur griego');
    expect(reabierto.hoy().macros.kcal, 97);
    expect(reabierto.hoy().comidas.single.momento, Momento.desayuno);
  });

  test('cada Renglón muestra a lo sumo dos Propuestas', () async {
    final diario = Diario(
      busquedaIA: _PuertoBusquedaIAFalso({
        'kiwi': [
          const Propuesta(
            nombre: 'Kiwi A',
            macrosPor100g: Macros(
              kcal: 60,
              proteina: 1,
              carbos: 14,
              grasa: 0.5,
            ),
          ),
          const Propuesta(
            nombre: 'Kiwi B',
            macrosPor100g: Macros(
              kcal: 61,
              proteina: 1,
              carbos: 15,
              grasa: 0.4,
            ),
          ),
          const Propuesta(
            nombre: 'Kiwi C',
            macrosPor100g: Macros(
              kcal: 62,
              proteina: 1,
              carbos: 16,
              grasa: 0.3,
            ),
          ),
        ],
      }),
    );
    diario.redactarComida(momento: Momento.extra, notas: 'kiwi');

    await diario.listo();

    expect(diario.resoluciones.single.propuestas, hasLength(2));
    expect(diario.resoluciones.single.propuestas[0].nombre, 'Kiwi A');
    expect(diario.resoluciones.single.propuestas[1].nombre, 'Kiwi B');
  });

  test('slot 1 es local y slot 2 es la Propuesta IA distinta', () async {
    final diario = Diario(
      busquedaIA: _PuertoBusquedaIAFalso({
        'yogur griego': [
          const Propuesta(
            nombre: 'Yogur light',
            macrosPor100g: Macros(kcal: 54, proteina: 8, carbos: 4, grasa: 0.2),
          ),
        ],
      }),
    );
    final yogur = await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );

    await diario.listo();

    final propuestas = diario.resoluciones.single.propuestas;
    expect(propuestas, hasLength(2));
    expect(propuestas[0].alimentoId, yogur.id);
    expect(propuestas[1].nombre, 'Yogur light');
    expect(propuestas[1].alimentoId, isNull);
  });

  test(
    'si la IA repite el Alimento local, no se muestra el duplicado',
    () async {
      final diario = Diario(
        busquedaIA: _PuertoBusquedaIAFalso({
          'yogur griego': [
            const Propuesta(
              nombre: 'Yogur Griego',
              macrosPor100g: Macros(
                kcal: 99,
                proteina: 11,
                carbos: 4,
                grasa: 5,
              ),
            ),
          ],
        }),
      );
      await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
      );

      await diario.listo();

      expect(diario.resoluciones.single.propuestas, hasLength(1));
      expect(
        diario.resoluciones.single.propuestas.single.nombre,
        'yogur griego',
      );
    },
  );

  test('slot 2 es la primera IA distinta aunque las primeras filas dupliquen lo local', () async {
    final diario = Diario(
      busquedaIA: _PuertoBusquedaIAFalso({
        'yogur griego': [
          const Propuesta(
            nombre: 'Yogur Griego',
            macrosPor100g: Macros(kcal: 99, proteina: 11, carbos: 4, grasa: 5),
          ),
          const Propuesta(
            nombre: 'yogur griego',
            macrosPor100g: Macros(kcal: 98, proteina: 10, carbos: 4, grasa: 5),
          ),
          const Propuesta(
            nombre: 'Yogur light',
            macrosPor100g: Macros(kcal: 54, proteina: 8, carbos: 4, grasa: 0.2),
          ),
        ],
      }),
    );
    final yogur = await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );

    await diario.listo();

    final propuestas = diario.resoluciones.single.propuestas;
    expect(propuestas, hasLength(2));
    expect(propuestas[0].alimentoId, yogur.id);
    expect(propuestas[1].nombre, 'Yogur light');
  });

  test('sin match local, hasta dos Propuestas IA llenan los slots', () async {
    final diario = Diario(
      busquedaIA: _PuertoBusquedaIAFalso({
        'banana chica': [
          const Propuesta(
            nombre: 'Banana',
            macrosPor100g: Macros(
              kcal: 89,
              proteina: 1,
              carbos: 23,
              grasa: 0.3,
            ),
            gramosAsumidos: 80,
          ),
          const Propuesta(
            nombre: 'Banana madura',
            macrosPor100g: Macros(
              kcal: 95,
              proteina: 1.2,
              carbos: 24,
              grasa: 0.3,
            ),
            gramosAsumidos: 90,
          ),
        ],
      }),
    );
    diario.redactarComida(momento: Momento.desayuno, notas: 'banana chica');

    await diario.listo();

    final resuelto = diario.resoluciones.single;
    expect(resuelto.ofreceCrearAlimento, isFalse);
    expect(resuelto.propuestas, hasLength(2));
    expect(resuelto.propuestas[0].nombre, 'Banana');
    expect(resuelto.propuestas[0].gramosAsumidos, 80);
    expect(resuelto.propuestas[1].nombre, 'Banana madura');
  });

  test('Renglón sin match y sin puerto usable ofrece crear Alimento', () async {
    final diario = Diario();
    diario.redactarComida(momento: Momento.desayuno, notas: 'banana chica');

    await diario.listo();

    expect(diario.resoluciones.single.propuestas, isEmpty);
    expect(diario.resoluciones.single.ofreceCrearAlimento, isTrue);
  });

  test(
    'Listo espera la IA de un Renglón antes de pedir el siguiente',
    () async {
      final alEntrarPrimero = Completer<void>();
      final liberarPrimero = Completer<void>();
      final alEntrarSegundo = Completer<void>();
      var indice = 0;
      final diario = Diario(
        busquedaIA: _PuertoBusquedaIAEnOrden(
          alBuscar: () async {
            final actual = indice++;
            if (actual == 0) {
              alEntrarPrimero.complete();
              await liberarPrimero.future;
            } else {
              alEntrarSegundo.complete();
            }
          },
        ),
      );
      diario.redactarComida(
        momento: Momento.almuerzo,
        notas: '30g queso dambo\n40g jamon cocido',
      );

      final listo = diario.listo();
      await alEntrarPrimero.future;
      expect(alEntrarSegundo.isCompleted, isFalse);

      liberarPrimero.complete();
      await listo;

      expect(alEntrarSegundo.isCompleted, isTrue);
      expect(diario.resoluciones, hasLength(2));
    },
  );

  test(
    'un puerto roto no bloquea el Renglón local y el sin match ofrece crear',
    () async {
      final diario = Diario(busquedaIA: _PuertoBusquedaIARoto());
      await diario.crearAlimento(
        nombre: 'avena',
        macrosPor100g: const Macros(
          kcal: 370,
          proteina: 13,
          carbos: 60,
          grasa: 7,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '60g avena\nbanana chica',
      );

      await diario.listo();

      expect(diario.resoluciones, hasLength(2));
      expect(diario.resoluciones[0].propuestas, hasLength(1));
      expect(diario.resoluciones[0].propuestas.single.nombre, 'avena');
      expect(diario.resoluciones[1].ofreceCrearAlimento, isTrue);
    },
  );

  test(
    'confirmar una Propuesta IA crea un Alimento; la próxima línea pega local',
    () async {
      const macros = Macros(kcal: 89, proteina: 1, carbos: 23, grasa: 0.3);
      final diario = Diario(
        ahora: () => DateTime(2026, 9, 6, 8),
        busquedaIA: _PuertoBusquedaIAFalso({
          'banana chica': [
            const Propuesta(
              nombre: 'Banana',
              macrosPor100g: macros,
              gramosAsumidos: 80,
            ),
          ],
        }),
      );
      diario.redactarComida(momento: Momento.desayuno, notas: 'banana chica');
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 80,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);

      expect(diario.alimentos, hasLength(1));
      expect(diario.alimentos.single.nombre, 'Banana');
      expect(diario.alimentos.single.patron, 'banana');
      expect(diario.hoy().macros.kcal, 89 * 80 / 100);

      final despues = Diario(
        ahora: () => DateTime(2026, 9, 6, 9),
        alimentos: diario.alimentos,
      );
      despues.redactarComida(momento: Momento.extra, notas: 'banana chica');
      await despues.listo();

      expect(
        despues.resoluciones.single.propuestas.single.alimentoId,
        isNotNull,
      );
      expect(
        despues.resoluciones.single.propuestas.single.alimentoId,
        diario.alimentos.single.id,
      );
    },
  );

  test(
    'sin Cantidad parseada, se pueden confirmar gramos asumidos o editarlos',
    () async {
      const macros = Macros(kcal: 89, proteina: 1, carbos: 23, grasa: 0.3);
      final diario = Diario(
        ahora: () => DateTime(2026, 9, 6, 8),
        busquedaIA: _PuertoBusquedaIAFalso({
          'banana chica': [
            const Propuesta(
              nombre: 'Banana',
              macrosPor100g: macros,
              gramosAsumidos: 120,
            ),
          ],
        }),
      );
      diario.redactarComida(momento: Momento.desayuno, notas: 'banana chica');
      await diario.listo();
      expect(diario.resoluciones.single.renglon.cantidad, isNull);
      expect(diario.resoluciones.single.propuestas.single.gramosAsumidos, 120);

      await diario.confirmar([
        EleccionRenglon(
          cantidad: 90,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);

      expect(diario.hoy().comidas.single.renglones.single.cantidad, 90);
      expect(diario.hoy().macros.kcal, 89 * 90 / 100);
    },
  );

  test(
    'si la línea ya trae gramos, se ignoran los gramos asumidos de la IA',
    () async {
      final diario = Diario(
        ahora: () => DateTime(2026, 9, 6, 8),
        busquedaIA: _PuertoBusquedaIAFalso({
          'banana': [
            const Propuesta(
              nombre: 'Banana',
              macrosPor100g: Macros(
                kcal: 89,
                proteina: 1,
                carbos: 23,
                grasa: 0.3,
              ),
              gramosAsumidos: 120,
            ),
          ],
        }),
      );
      diario.redactarComida(momento: Momento.desayuno, notas: '100g banana');
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: diario.resoluciones.single.renglon.cantidad!,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);

      expect(diario.hoy().comidas.single.renglones.single.cantidad, 100);
    },
  );

  test(
    'crear Alimento en confirmación es el mismo tipo que el del catálogo',
    () async {
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      diario.redactarComida(momento: Momento.desayuno, notas: 'banana chica');
      await diario.listo();
      expect(diario.resoluciones.single.ofreceCrearAlimento, isTrue);

      await diario.confirmar([
        const EleccionRenglon(
          cantidad: 110,
          crearNombre: 'Banana chica',
          crearMacros: Macros(kcal: 89, proteina: 1, carbos: 23, grasa: 0.3),
        ),
      ]);

      expect(diario.alimentos.single, isA<Alimento>());
      expect(diario.alimentos.single.nombre, 'Banana chica');
      expect(diario.alimentos.single.patron, 'banana chica');
      expect(diario.hoy().comidas.single.renglones.single.cantidad, 110);
    },
  );

  test('no se confirma un Renglón en 0 g', () async {
    final diario = Diario();
    diario.redactarComida(momento: Momento.desayuno, notas: 'banana chica');
    await diario.listo();

    expect(
      () => diario.confirmar([
        const EleccionRenglon(
          cantidad: 0,
          crearNombre: 'Banana',
          crearMacros: Macros(kcal: 89, proteina: 1, carbos: 23, grasa: 0.3),
        ),
      ]),
      throwsA(isA<ArgumentError>()),
    );
    expect(diario.hoy().comidas, isEmpty);
  });

  test('editar macros de un Alimento recalcula el Día ya confirmado', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    final yogur = await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);
    expect(diario.hoy().macros.kcal, 97);

    await diario.editarAlimento(
      id: yogur.id,
      macrosPor100g: const Macros(
        kcal: 59,
        proteina: 10,
        carbos: 3.6,
        grasa: 0.4,
      ),
    );

    expect(diario.hoy().macros.kcal, 59);
    expect(diario.hoy().macros.proteina, 10);
    expect(diario.hoy().macros.carbos, 3.6);
    expect(diario.hoy().macros.grasa, 0.4);
    expect(diario.alimentos, hasLength(1));
    expect(diario.hoy().comidas.single.renglones.single.alimentoId, yogur.id);
  });

  test('un Día pasado se abre con sus Comidas y totales', () async {
    var ahora = DateTime(2026, 9, 5, 8);
    final diario = Diario(ahora: () => ahora);
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    ahora = DateTime(2026, 9, 6, 8);
    final pasado = diario.dia(DateTime(2026, 9, 5));

    expect(diario.hoy().macros.kcal, 0);
    expect(diario.hoy().comidas, isEmpty);
    expect(pasado.fecha, DateTime(2026, 9, 5));
    expect(pasado.macros.kcal, 97);
    expect(pasado.comidas, hasLength(1));
    expect(pasado.comidas.single.momento, Momento.desayuno);
    expect(pasado.comidas.single.renglones.single.cantidad, 100);
  });

  test(
    'editar macros recalcula también un Día pasado que apunta al Alimento',
    () async {
      var ahora = DateTime(2026, 9, 5, 8);
      final diario = Diario(ahora: () => ahora);
      final yogur = await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '200g yogur griego',
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 200,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);
      ahora = DateTime(2026, 9, 6, 8);

      await diario.editarAlimento(
        id: yogur.id,
        macrosPor100g: const Macros(
          kcal: 59,
          proteina: 10,
          carbos: 3.6,
          grasa: 0.4,
        ),
      );

      expect(diario.dia(DateTime(2026, 9, 5)).macros.kcal, 118);
      expect(diario.hoy().macros.kcal, 0);
    },
  );

  test('un Patrón regex editado pega en capturas posteriores', () async {
    final diario = Diario();
    final yogur = await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(momento: Momento.desayuno, notas: '100g yogurt');
    await diario.listo();
    expect(diario.resoluciones.single.ofreceCrearAlimento, isTrue);

    await diario.editarAlimento(id: yogur.id, patron: r'yogur|yogurt');
    diario.redactarComida(momento: Momento.desayuno, notas: '100g yogurt');
    await diario.listo();

    expect(diario.resoluciones.single.propuestas.single.alimentoId, yogur.id);
  });

  test('un Patrón vacío vuelve al derivado del nombre', () async {
    final diario = Diario();
    final yogur = await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    await diario.editarAlimento(id: yogur.id, patron: r'yogurt');
    diario.redactarComida(momento: Momento.desayuno, notas: '100g yogurt');
    await diario.listo();
    expect(diario.resoluciones.single.propuestas.single.alimentoId, yogur.id);

    await diario.editarAlimento(id: yogur.id, patron: '');
    diario.redactarComida(momento: Momento.desayuno, notas: '100g yogurt');
    await diario.listo();
    expect(diario.resoluciones.single.ofreceCrearAlimento, isTrue);

    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    expect(diario.resoluciones.single.propuestas.single.alimentoId, yogur.id);
    expect(diario.alimentos.single.patron, 'yogur griego');
  });

  test(
    'cambiar Cantidad de un Renglón guardado actualiza los totales del Día',
    () async {
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 100,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);

      await diario.editarRenglon(
        comidaId: diario.hoy().comidas.single.id,
        indice: 0,
        cantidad: 200,
      );

      expect(diario.hoy().comidas.single.renglones.single.cantidad, 200);
      expect(diario.hoy().macros.kcal, 194);
      expect(diario.hoy().macros.proteina, 20);
    },
  );

  test('cambiar el Alimento de un Renglón guardado recalcula el Día', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    final avena = await diario.crearAlimento(
      nombre: 'avena',
      macrosPor100g: const Macros(
        kcal: 370,
        proteina: 13,
        carbos: 60,
        grasa: 7,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    await diario.editarRenglon(
      comidaId: diario.hoy().comidas.single.id,
      indice: 0,
      alimentoId: avena.id,
    );

    final renglon = diario.hoy().comidas.single.renglones.single;
    expect(renglon.alimentoId, avena.id);
    expect(renglon.nombre, 'avena');
    expect(renglon.cantidad, 100);
    expect(diario.hoy().macros.kcal, 370);
  });

  test('borrar un Renglón baja los totales del Día', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego\n200g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      for (final resolucion in diario.resoluciones)
        EleccionRenglon(
          cantidad: resolucion.renglon.cantidad!,
          propuesta: resolucion.propuestas.single,
        ),
    ]);
    expect(diario.hoy().macros.kcal, 291);

    await diario.eliminarRenglon(
      comidaId: diario.hoy().comidas.single.id,
      indice: 0,
    );

    expect(diario.hoy().comidas.single.renglones, hasLength(1));
    expect(diario.hoy().comidas.single.renglones.single.cantidad, 200);
    expect(diario.hoy().macros.kcal, 194);
  });

  test('borrar una Comida baja los totales del Día', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);
    diario.redactarComida(
      momento: Momento.almuerzo,
      notas: '200g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 200,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);
    expect(diario.hoy().macros.kcal, 291);

    await diario.eliminarComida(diario.hoy().comidas.first.id);

    expect(diario.hoy().comidas, hasLength(1));
    expect(diario.hoy().comidas.single.momento, Momento.almuerzo);
    expect(diario.hoy().macros.kcal, 194);
  });

  test('cambiar el Momento de una Comida no altera los totales', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.almuerzo,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    await diario.cambiarMomento(diario.hoy().comidas.single.id, Momento.extra);

    expect(diario.hoy().comidas.single.momento, Momento.extra);
    expect(diario.hoy().macros.kcal, 97);
  });

  test(
    'cambiarMomento a un Momento ocupado une las Comidas con destino primero',
    () async {
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 100,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);
      diario.redactarComida(
        momento: Momento.almuerzo,
        notas: '200g yogur griego',
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 200,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);
      final destino = diario.hoy().comidas.first;
      final origen = diario.hoy().comidas.last;
      expect(destino.momento, Momento.desayuno);
      expect(origen.momento, Momento.almuerzo);

      await diario.cambiarMomento(origen.id, Momento.desayuno);

      final dia = diario.hoy();
      expect(dia.comidas, hasLength(1));
      expect(dia.comidas.single.id, destino.id);
      expect(dia.comidas.single.momento, Momento.desayuno);
      expect(dia.comidas.single.renglones, hasLength(2));
      expect(dia.comidas.single.renglones[0].cantidad, 100);
      expect(dia.comidas.single.renglones[1].cantidad, 200);
      expect(dia.macros.kcal, 291);
    },
  );

  test('borrar un Alimento lo saca del catálogo y baja los totales', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    final yogur = await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    await diario.eliminarAlimento(yogur.id);

    expect(diario.alimentos, isEmpty);
    expect(diario.hoy().comidas, isEmpty);
    expect(diario.hoy().macros.kcal, 0);
  });

  test('borrar el último Renglón elimina la Comida', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    await diario.eliminarRenglon(
      comidaId: diario.hoy().comidas.single.id,
      indice: 0,
    );

    expect(diario.hoy().comidas, isEmpty);
    expect(diario.hoy().macros.kcal, 0);
  });

  test(
    'editar el nombre de un Alimento se ve en los Renglones guardados',
    () async {
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      final yogur = await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 100,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);

      await diario.editarAlimento(id: yogur.id, nombre: 'Yogur light');

      expect(diario.alimentos.single.nombre, 'Yogur light');
      expect(
        diario.hoy().comidas.single.renglones.single.nombre,
        'Yogur light',
      );
    },
  );

  test('abrir un Diario con dos Comidas del mismo fecha y Momento las une en el orden registrado', () {
    const macros = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
    final yogur = Alimento(
      id: 'a1',
      nombre: 'yogur griego',
      macrosPor100g: macros,
      patron: 'yogur griego',
      usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
    );
    final diario = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      alimentos: [yogur],
      comidas: [
        Comida(
          id: 'c1',
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 6),
          renglones: [
            Renglon(
              nombre: 'yogur griego',
              cantidad: 100,
              alimentoId: yogur.id,
            ),
          ],
        ),
        Comida(
          id: 'c2',
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 6),
          renglones: [
            Renglon(nombre: 'yogur griego', cantidad: 30, alimentoId: yogur.id),
          ],
        ),
      ],
    );

    final dia = diario.hoy();
    expect(dia.comidas, hasLength(1));
    expect(dia.comidas.single.id, 'c1');
    expect(dia.comidas.single.renglones, hasLength(2));
    expect(dia.comidas.single.renglones[0].cantidad, 100);
    expect(dia.comidas.single.renglones[1].cantidad, 30);
    expect(dia.macros.kcal, 126.1);
  });

  test('una Comida cargada sin id se puede editar', () async {
    const macros = Macros(kcal: 97, proteina: 10, carbos: 3.6, grasa: 5);
    final yogur = Alimento(
      id: 'a1',
      nombre: 'yogur griego',
      macrosPor100g: macros,
      patron: 'yogur griego',
      usadoPorUltimaVez: DateTime(2026, 9, 6, 8),
    );
    final diario = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      alimentos: [yogur],
      comidas: [
        Comida(
          momento: Momento.desayuno,
          fecha: DateTime(2026, 9, 6),
          renglones: [
            Renglon(
              nombre: 'yogur griego',
              cantidad: 100,
              alimentoId: yogur.id,
            ),
          ],
        ),
      ],
    );

    expect(diario.hoy().comidas.single.id, isNotEmpty);

    await diario.editarRenglon(
      comidaId: diario.hoy().comidas.single.id,
      indice: 0,
      cantidad: 200,
    );

    expect(diario.hoy().macros.kcal, 194);
  });

  test('confirmar Desayuno dos veces en el mismo Día deja una Comida y concatena Renglones', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);
    final id = diario.hoy().comidas.single.id;

    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '200g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 200,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    final dia = diario.hoy();
    expect(dia.comidas, hasLength(1));
    expect(dia.comidas.single.momento, Momento.desayuno);
    expect(dia.comidas.single.id, id);
    expect(dia.comidas.single.renglones, hasLength(2));
    expect(dia.comidas.single.renglones[0].cantidad, 100);
    expect(dia.comidas.single.renglones[1].cantidad, 200);
    expect(dia.macros.kcal, 291);
  });

  test(
    'confirmar sobre un Momento ocupado de un Día pasado une esa fecha, no Hoy',
    () async {
      var ahora = DateTime(2026, 9, 5, 8);
      final diario = Diario(ahora: () => ahora);
      await diario.crearAlimento(
        nombre: 'yogur griego',
        macrosPor100g: const Macros(
          kcal: 97,
          proteina: 10,
          carbos: 3.6,
          grasa: 5,
        ),
      );
      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '100g yogur griego',
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 100,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);
      ahora = DateTime(2026, 9, 6, 8);

      diario.redactarComida(
        momento: Momento.desayuno,
        notas: '200g yogur griego',
        fecha: DateTime(2026, 9, 5, 22),
      );
      await diario.listo();
      await diario.confirmar([
        EleccionRenglon(
          cantidad: 200,
          propuesta: diario.resoluciones.single.propuestas.single,
        ),
      ]);

      expect(diario.hoy().comidas, isEmpty);
      expect(diario.hoy().macros.kcal, 0);
      final pasado = diario.dia(DateTime(2026, 9, 5));
      expect(pasado.comidas, hasLength(1));
      expect(pasado.comidas.single.renglones, hasLength(2));
      expect(pasado.comidas.single.renglones[1].cantidad, 200);
      expect(pasado.macros.kcal, 291);
    },
  );

  test('confirmar una Comida en un Día pasado la anota en esa fecha', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
      fecha: DateTime(2026, 9, 5, 22),
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    expect(diario.hoy().comidas, isEmpty);
    expect(diario.dia(DateTime(2026, 9, 5)).macros.kcal, 97);
    expect(
      diario.dia(DateTime(2026, 9, 5)).comidas.single.momento,
      Momento.desayuno,
    );
  });

  test('un Día vacío arranca la captura en Desayuno', () {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));

    expect(diario.momentoDeCaptura(DateTime(2026, 9, 6)), Momento.desayuno);
  });

  test('después de confirmar Extra, ese Momento es el que último recibió Renglones', () async {
    var ahora = DateTime(2026, 9, 6, 8);
    final diario = Diario(ahora: () => ahora);
    await diario.crearAlimento(
      nombre: 'yogur griego',
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    diario.redactarComida(
      momento: Momento.desayuno,
      notas: '100g yogur griego',
    );
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 100,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);
    ahora = DateTime(2026, 9, 6, 9);
    diario.redactarComida(momento: Momento.extra, notas: '200g yogur griego');
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 200,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    expect(diario.momentoDeCaptura(DateTime(2026, 9, 6)), Momento.extra);

    ahora = DateTime(2026, 9, 6, 10);
    diario.redactarComida(momento: Momento.desayuno, notas: '30g yogur griego');
    await diario.listo();
    await diario.confirmar([
      EleccionRenglon(
        cantidad: 30,
        propuesta: diario.resoluciones.single.propuestas.single,
      ),
    ]);

    expect(diario.momentoDeCaptura(DateTime(2026, 9, 6)), Momento.desayuno);
  });

  test('guardar un Pesaje lo deja consultable por esa fecha', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(
      fecha: DateTime(2026, 9, 6, 8),
      kilogramos: 72.4,
    );

    final pesaje = diario.pesajeDe(DateTime(2026, 9, 6));
    expect(pesaje, isNotNull);
    expect(pesaje!.kilogramos, 72.4);
    expect(pesaje.fecha, DateTime(2026, 9, 6));
  });

  test('guardar de nuevo el mismo Día reemplaza el kg', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 71);

    expect(diario.pesajeDe(DateTime(2026, 9, 6))!.kilogramos, 71);
  });

  test('un Pesaje de 0 o negativo no se guarda', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));

    expect(
      () => diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 0),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: -1),
      throwsA(isA<ArgumentError>()),
    );
    expect(diario.pesajeDe(DateTime(2026, 9, 6)), isNull);
  });

  test('72.45 no se redondea: el Pesaje anterior queda', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72);

    expect(
      () =>
          diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.45),
      throwsA(isA<ArgumentError>()),
    );
    expect(diario.pesajeDe(DateTime(2026, 9, 6))!.kilogramos, 72);
  });

  test(
    'se puede guardar un Pesaje de hoy, de un Día pasado y de uno futuro',
    () async {
      final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
      await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72);
      await diario.guardarPesaje(fecha: DateTime(2026, 9, 5), kilogramos: 71.5);
      await diario.guardarPesaje(fecha: DateTime(2026, 9, 8), kilogramos: 73);

      expect(diario.pesajeDe(DateTime(2026, 9, 6))!.kilogramos, 72);
      expect(diario.pesajeDe(DateTime(2026, 9, 5))!.kilogramos, 71.5);
      expect(diario.pesajeDe(DateTime(2026, 9, 8))!.kilogramos, 73);
    },
  );

  test('un Pesaje sin Comida deja el Cumplimiento en ninguno', () async {
    final diario = Diario(ahora: () => DateTime(2026, 9, 6, 8));
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);

    expect(diario.cumplimientoDe(DateTime(2026, 9, 6)), Cumplimiento.ninguno);
  });

  test('una Comida pinta Cumplimiento aunque no haya Pesaje, y el Pesaje no lo cambia', () async {
    final diario = _diarioConDia(
      fecha: DateTime(2026, 9, 5),
      macrosPor100g: const Macros(
        kcal: 97,
        proteina: 10,
        carbos: 3.6,
        grasa: 5,
      ),
    );
    expect(diario.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.amarillo);

    await diario.guardarPesaje(fecha: DateTime(2026, 9, 5), kilogramos: 72.4);

    expect(diario.cumplimientoDe(DateTime(2026, 9, 5)), Cumplimiento.amarillo);
  });

  test('persistir el Diario recibe los Pesajes, no un Promedio', () async {
    List<Pesaje>? persistidos;
    final diario = Diario(
      ahora: () => DateTime(2026, 9, 6, 8),
      persistirDiario: (alimentos, comidas, pesajes) async {
        persistidos = List.of(pesajes);
      },
    );
    await diario.guardarPesaje(fecha: DateTime(2026, 9, 6), kilogramos: 72.4);

    expect(persistidos, hasLength(1));
    expect(persistidos!.single.kilogramos, 72.4);
    expect(persistidos!.single.fecha, DateTime(2026, 9, 6));
  });
}

Diario _diarioConDia({required DateTime fecha, required Macros macrosPor100g}) {
  final alimento = Alimento(
    id: 'a1',
    nombre: 'prueba',
    macrosPor100g: macrosPor100g,
    patron: 'prueba',
    usadoPorUltimaVez: fecha,
  );
  return Diario(
    ahora: () => DateTime(2026, 9, 6, 8),
    alimentos: [alimento],
    comidas: [
      Comida(
        id: 'c1',
        momento: Momento.desayuno,
        fecha: DateTime(fecha.year, fecha.month, fecha.day),
        renglones: [
          Renglon(nombre: 'prueba', cantidad: 100, alimentoId: alimento.id),
        ],
      ),
    ],
  );
}

class _PuertoBusquedaIAEnOrden implements PuertoBusquedaIA {
  _PuertoBusquedaIAEnOrden({required this.alBuscar});

  final Future<void> Function() alBuscar;

  @override
  Future<List<Propuesta>> buscar(Renglon renglon) async {
    await alBuscar();
    return const [];
  }
}

class _PuertoBusquedaIARoto implements PuertoBusquedaIA {
  @override
  Future<List<Propuesta>> buscar(Renglon renglon) async {
    throw StateError('sin red');
  }
}

class _PuertoBusquedaIAFalso implements PuertoBusquedaIA {
  _PuertoBusquedaIAFalso(this.porNombre);

  final Map<String, List<Propuesta>> porNombre;

  @override
  Future<List<Propuesta>> buscar(Renglon renglon) async {
    return List.of(porNombre[renglon.nombre] ?? const []);
  }
}
