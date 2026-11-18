import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/codec_diario.dart';
import 'package:nutrimezzo/diario.dart';

Map<String, dynamic> _contrato() =>
    jsonDecode(File('contrato/diario.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('contrato/diario.json se decodifica a objetos del dominio', () {
    final foto = FotoDiario.deJson(_contrato());

    expect(foto.meta!.macros.kcal, 2100);
    expect(foto.meta!.macros.grasa, 70);
    expect(foto.alimentos.map((a) => a.id), ['a1', 'a2']);
    expect(foto.alimentos.first.macrosPor100g.proteina, 1.1);
    expect(
      foto.alimentos.first.usadoPorUltimaVez,
      DateTime(2026, 11, 17, 8, 30),
    );
    final desayuno = foto.comidas.first;
    expect(desayuno.momento, Momento.desayuno);
    expect(desayuno.fecha, DateTime(2026, 11, 17));
    expect(desayuno.renglones.first.alimentoId, 'a1');
    expect(desayuno.recibidoPorUltimaVez, DateTime(2026, 11, 17, 8, 31, 12));
    final cena = foto.comidas.last;
    expect(cena.recibidoPorUltimaVez, isNull);
    expect(cena.renglones.single.cantidad, isNull);
    expect(cena.renglones.single.alimentoId, isNull);
    expect(foto.pesajes.first.fecha, DateTime(2026, 11, 17));
    expect(foto.pesajes.first.kilogramos, 78.4);
  });

  test('codificar lo decodificado devuelve contrato/diario.json sin revision', () {
    final contrato = _contrato()..remove('revision');

    final codificado = FotoDiario.deJson(_contrato()).aJson();

    expect(codificado, contrato);
    // Strict: same keys in the same order, ints stay ints, absent stays absent.
    expect(jsonEncode(codificado), jsonEncode(contrato));
  });

  test('meta null viaja como null', () {
    final json = _contrato()..['meta'] = null;

    final foto = FotoDiario.deJson(json);

    expect(foto.meta, isNull);
    expect(foto.aJson()['meta'], isNull);
    expect(foto.aJson().containsKey('meta'), isTrue);
  });
}
