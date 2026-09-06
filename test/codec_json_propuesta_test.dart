import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/codec_json_propuesta.dart';

void main() {
  test('una Propuesta válida llena nombre, macros / 100 g y gramos nulos', () {
    const crudo = '''
{
  "propuestas": [
    {
      "nombre": "Yogur griego",
      "kcal_por_100g": 97,
      "proteina_g_por_100g": 10,
      "carbos_g_por_100g": 3.6,
      "grasa_g_por_100g": 5,
      "gramos_asumidos": null
    }
  ]
}
''';

    final propuestas = const CodecJsonPropuesta().decodificar(crudo);

    expect(propuestas, hasLength(1));
    expect(propuestas.single.nombre, 'Yogur griego');
    expect(propuestas.single.macrosPor100g.kcal, 97);
    expect(propuestas.single.macrosPor100g.proteina, 10);
    expect(propuestas.single.macrosPor100g.carbos, 3.6);
    expect(propuestas.single.macrosPor100g.grasa, 5);
    expect(propuestas.single.gramosAsumidos, isNull);
    expect(propuestas.single.alimentoId, isNull);
  });

  test('propuestas vacío es válido y no inventa filas', () {
    const crudo = '{"propuestas":[]}';

    expect(const CodecJsonPropuesta().decodificar(crudo), isEmpty);
  });

  test('dos Propuestas válidas quedan en orden', () {
    const crudo = '''
{
  "propuestas": [
    {
      "nombre": "Banana",
      "kcal_por_100g": 89,
      "proteina_g_por_100g": 1,
      "carbos_g_por_100g": 23,
      "grasa_g_por_100g": 0.3,
      "gramos_asumidos": 80
    },
    {
      "nombre": "Banana madura",
      "kcal_por_100g": 95,
      "proteina_g_por_100g": 1.2,
      "carbos_g_por_100g": 24,
      "grasa_g_por_100g": 0.3,
      "gramos_asumidos": 90
    }
  ]
}
''';

    final propuestas = const CodecJsonPropuesta().decodificar(crudo);

    expect(propuestas, hasLength(2));
    expect(propuestas[0].nombre, 'Banana');
    expect(propuestas[0].gramosAsumidos, 80);
    expect(propuestas[1].nombre, 'Banana madura');
    expect(propuestas[1].gramosAsumidos, 90);
  });

  test('gramos_asumidos omitido queda nulo', () {
    const crudo = '''
{
  "propuestas": [
    {
      "nombre": "Yogur griego",
      "kcal_por_100g": 97,
      "proteina_g_por_100g": 10,
      "carbos_g_por_100g": 3.6,
      "grasa_g_por_100g": 5
    }
  ]
}
''';

    expect(
      const CodecJsonPropuesta().decodificar(crudo).single.gramosAsumidos,
      isNull,
    );
  });

  test('una cerca markdown json se desenvuelve antes de decodificar', () {
    const crudo = '''
```json
{
  "propuestas": [
    {
      "nombre": "Yogur griego",
      "kcal_por_100g": 97,
      "proteina_g_por_100g": 10,
      "carbos_g_por_100g": 3.6,
      "grasa_g_por_100g": 5,
      "gramos_asumidos": null
    }
  ]
}
```
''';

    final propuestas = const CodecJsonPropuesta().decodificar(crudo);

    expect(propuestas.single.nombre, 'Yogur griego');
    expect(propuestas.single.macrosPor100g.kcal, 97);
  });

  test('claves extra en un ítem válido se ignoran', () {
    const crudo = '''
{
  "fuente": "modelo",
  "propuestas": [
    {
      "nombre": "Yogur griego",
      "kcal_por_100g": 97,
      "proteina_g_por_100g": 10,
      "carbos_g_por_100g": 3.6,
      "grasa_g_por_100g": 5,
      "gramos_asumidos": null,
      "origen": "usda"
    }
  ]
}
''';

    final propuestas = const CodecJsonPropuesta().decodificar(crudo);

    expect(propuestas.single.nombre, 'Yogur griego');
    expect(propuestas.single.macrosPor100g.kcal, 97);
  });

  test('rechaza JSON que no cumple el contrato', () {
    const item =
        '{"nombre":"Yogur griego","kcal_por_100g":97,"proteina_g_por_100g":10,"carbos_g_por_100g":3.6,"grasa_g_por_100g":5,"gramos_asumidos":80}';
    const casos = {
      'vacío': '',
      'roto': '{',
      'string': '"hello"',
      'lista raíz': '[]',
      'objeto vacío': '{}',
      'propuestas null': '{"propuestas": null}',
      'ítem vacío': '{"propuestas": [{}]}',
      'falta kcal': '{"propuestas":[{"nombre":"Yogur griego","proteina_g_por_100g":10,"carbos_g_por_100g":3.6,"grasa_g_por_100g":5}]}',
      'nombre vacío': '{"propuestas":[{"nombre":"","kcal_por_100g":97,"proteina_g_por_100g":10,"carbos_g_por_100g":3.6,"grasa_g_por_100g":5}]}',
      'kcal negativa': '{"propuestas":[{"nombre":"Yogur griego","kcal_por_100g":-1,"proteina_g_por_100g":10,"carbos_g_por_100g":3.6,"grasa_g_por_100g":5}]}',
      'gramos 0': '{"propuestas":[{"nombre":"Yogur griego","kcal_por_100g":97,"proteina_g_por_100g":10,"carbos_g_por_100g":3.6,"grasa_g_por_100g":5,"gramos_asumidos":0}]}',
      'gramos -1': '{"propuestas":[{"nombre":"Yogur griego","kcal_por_100g":97,"proteina_g_por_100g":10,"carbos_g_por_100g":3.6,"grasa_g_por_100g":5,"gramos_asumidos":-1}]}',
      'más de dos': '{"propuestas":[$item,$item,$item]}',
      'kcal string': '{"propuestas":[{"nombre":"Yogur griego","kcal_por_100g":"97","proteina_g_por_100g":10,"carbos_g_por_100g":3.6,"grasa_g_por_100g":5}]}',
      'kcal infinito': '{"propuestas":[{"nombre":"Yogur griego","kcal_por_100g":1e999,"proteina_g_por_100g":10,"carbos_g_por_100g":3.6,"grasa_g_por_100g":5}]}',
    };

    for (final caso in casos.entries) {
      expect(
        () => const CodecJsonPropuesta().decodificar(caso.value),
        throwsA(isA<FormatException>()),
        reason: caso.key,
      );
    }
  });
}
