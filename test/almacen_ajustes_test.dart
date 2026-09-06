import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/almacen_ajustes.dart';
import 'package:nutrimezzo/diario.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'abrirDiario usa la Meta por defecto si el teléfono está vacío',
    () async {
      final diario = await abrirDiario();

      expect(diario.meta.macros.kcal, 2000);
      expect(diario.meta.macros.proteina, 150);
      expect(diario.meta.macros.carbos, 250);
      expect(diario.meta.macros.grasa, 70);
      expect(diario.byok.urlBase, '');
      expect(diario.byok.claveApi, '');
      expect(diario.byok.idModelo, '');
    },
  );

  test('la Meta y el BYOK guardados se leen al reabrir el almacén', () async {
    final primero = await abrirDiario();
    await primero.guardarMeta(
      const Meta(
        macros: Macros(kcal: 1800, proteina: 140, carbos: 180, grasa: 55),
      ),
    );
    await primero.guardarByok(
      const Byok(
        urlBase: 'https://api.ejemplo.com/v1',
        claveApi: 'sk-secreto',
        idModelo: 'gpt-4o-mini',
      ),
    );

    final reabierto = await abrirDiario();
    expect(reabierto.meta.macros.kcal, 1800);
    expect(reabierto.meta.macros.proteina, 140);
    expect(reabierto.meta.macros.carbos, 180);
    expect(reabierto.meta.macros.grasa, 55);
    expect(reabierto.byok.urlBase, 'https://api.ejemplo.com/v1');
    expect(reabierto.byok.claveApi, 'sk-secreto');
    expect(reabierto.byok.idModelo, 'gpt-4o-mini');
  });

  test('borrar BYOK deja el almacén en blanco al reabrir', () async {
    final primero = await abrirDiario();
    await primero.guardarByok(
      const Byok(
        urlBase: 'https://api.ejemplo.com/v1',
        claveApi: 'sk-secreto',
        idModelo: 'gpt-4o-mini',
      ),
    );
    await primero.guardarByok(Byok.vacio);

    final reabierto = await abrirDiario();
    expect(reabierto.byok.urlBase, '');
    expect(reabierto.byok.claveApi, '');
    expect(reabierto.byok.idModelo, '');
  });

  test(
    'el catálogo y las Comidas del Día se leen al reabrir el almacén',
    () async {
      final primero = await abrirDiario(ahora: () => DateTime(2026, 9, 6, 8));
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

      final reabierto = await abrirDiario(ahora: () => DateTime(2026, 9, 6, 8));
      expect(reabierto.alimentos.single.nombre, 'yogur griego');
      expect(reabierto.alimentos.single.patron, 'yogur griego');
      expect(reabierto.hoy().macros.kcal, 97);
      expect(reabierto.hoy().comidas.single.momento, Momento.desayuno);
      expect(reabierto.hoy().comidas.single.renglones.single.cantidad, 100);
    },
  );

  test(
    'editar un Alimento persiste y el Día reabierto usa los macros nuevos',
    () async {
      final primero = await abrirDiario(ahora: () => DateTime(2026, 9, 6, 8));
      final yogur = await primero.crearAlimento(
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
      await primero.editarAlimento(
        id: yogur.id,
        macrosPor100g: const Macros(
          kcal: 59,
          proteina: 10,
          carbos: 3.6,
          grasa: 0.4,
        ),
      );

      final reabierto = await abrirDiario(ahora: () => DateTime(2026, 9, 6, 8));
      expect(reabierto.hoy().macros.kcal, 59);
      expect(reabierto.hoy().comidas.single.id, isNotEmpty);
      expect(reabierto.alimentos.single.macrosPor100g.kcal, 59);
    },
  );
}
