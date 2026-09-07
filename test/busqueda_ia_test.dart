import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nutrimezzo/busqueda_ia.dart';
import 'package:nutrimezzo/diario.dart';

void main() {
  test('un Renglón dispara un chat.completions con ese Renglón, URL, clave y modelo', () async {
    Uri? url;
    Map<String, String>? cabeceras;
    String? cuerpo;
    var envios = 0;
    const contrato = '''
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
    final puerto = BusquedaIAOpenAI(
      byok: () => const Byok(
        urlBase: 'https://api.ejemplo.com/v1',
        claveApi: 'sk-secreto',
        idModelo: 'gpt-4o-mini',
      ),
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        envios += 1;
        url = destino;
        cabeceras = headers;
        cuerpo = body as String?;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': contrato},
              },
            ],
          }),
          200,
        );
      },
    );

    final propuestas = await puerto.buscar(
      const Renglon(nombre: 'yogur griego', cantidad: 100),
    );

    expect(envios, 1);
    expect(url, Uri.parse('https://api.ejemplo.com/v1/chat/completions'));
    expect(cabeceras, isNotNull);
    expect(cabeceras!['Authorization'], 'Bearer sk-secreto');
    expect(cabeceras!['Content-Type'], 'application/json');
    final pedido = jsonDecode(cuerpo!) as Map<String, dynamic>;
    expect(pedido['model'], 'gpt-4o-mini');
    final mensajes = pedido['messages'] as List<dynamic>;
    expect(mensajes, hasLength(2));
    expect(mensajes[0]['role'], 'system');
    expect(mensajes[0]['content'], contains('propuestas'));
    expect(mensajes[0]['content'], contains('kcal_por_100g'));
    expect(mensajes[1]['role'], 'user');
    expect(mensajes[1]['content'], '100g yogur griego');
    expect(mensajes[1]['content'], isNot(contains('avena')));
    expect(propuestas.single.nombre, 'Yogur griego');
    expect(propuestas.single.macrosPor100g.kcal, 97);
  });

  test(
    'un Renglón sin g envía la línea y pide gramos_asumidos del total, no unidades',
    () async {
      String? cuerpo;
      const contrato =
          '{"propuestas":[{"nombre":"Huevo","kcal_por_100g":155,"proteina_g_por_100g":13,"carbos_g_por_100g":1.1,"grasa_g_por_100g":11,"gramos_asumidos":110}]}';
      final puerto = BusquedaIAOpenAI(
        byok: () => _byokEjemplo,
        post: (destino, {Map<String, String>? headers, Object? body}) async {
          cuerpo = body as String?;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': contrato},
                },
              ],
            }),
            200,
          );
        },
      );

      final propuestas = await puerto.buscar(const Renglon(nombre: '2 huevos'));

      final pedido = jsonDecode(cuerpo!) as Map<String, dynamic>;
      final mensajes = pedido['messages'] as List<dynamic>;
      expect(mensajes[1]['content'], '2 huevos');
      expect(mensajes[1]['content'], isNot(contains('110g')));
      expect(mensajes[0]['content'], contains('gramos_asumidos'));
      expect(mensajes[0]['content'], contains('2 huevos'));
      expect(mensajes[0]['content'], contains('total grams'));
      expect(propuestas.single.gramosAsumidos, 110);
    },
  );

  test('BYOK en blanco no llama a la red y no inventa Propuestas', () async {
    var envios = 0;
    final puerto = BusquedaIAOpenAI(
      byok: () => Byok.vacio,
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        envios += 1;
        return http.Response('no', 500);
      },
    );

    final propuestas = await puerto.buscar(
      const Renglon(nombre: 'banana chica'),
    );

    expect(envios, 0);
    expect(propuestas, isEmpty);
  });

  test('HTTP no 2xx es fallo del puerto y no inventa macros', () async {
    final puerto = BusquedaIAOpenAI(
      byok: () => _byokEjemplo,
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        return http.Response('{"kcal_por_100g": 9000}', 500);
      },
    );

    expect(
      () => puerto.buscar(const Renglon(nombre: 'kiwi')),
      throwsA(isA<StateError>()),
    );
  });

  test('un 429 se reintenta y sigue siendo Propuesta', () async {
    var envios = 0;
    final esperas = <Duration>[];
    const contrato =
        '{"propuestas":[{"nombre":"Huevos","kcal_por_100g":155,"proteina_g_por_100g":13,"carbos_g_por_100g":1.1,"grasa_g_por_100g":11,"gramos_asumidos":100}]}';
    final puerto = BusquedaIAOpenAI(
      byok: () => _byokEjemplo,
      esperar: (duracion) async {
        esperas.add(duracion);
      },
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        envios += 1;
        if (envios == 1) {
          return http.Response('{"error":"rate"}', 429);
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': contrato},
              },
            ],
          }),
          200,
        );
      },
    );

    final propuestas = await puerto.buscar(const Renglon(nombre: 'huevos'));

    expect(envios, 2);
    expect(esperas, [const Duration(seconds: 2)]);
    expect(propuestas.single.nombre, 'Huevos');
    expect(propuestas.single.macrosPor100g.kcal, 155);
  });

  test('agotados los 429 el puerto falla y no inventa macros', () async {
    var envios = 0;
    final puerto = BusquedaIAOpenAI(
      byok: () => _byokEjemplo,
      esperar: (_) async {},
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        envios += 1;
        return http.Response('rate', 429);
      },
    );

    await expectLater(
      puerto.buscar(const Renglon(nombre: 'queso dambo')),
      throwsA(isA<StateError>()),
    );
    expect(envios, 3);
  });

  test('contenido vacío es fallo del puerto', () async {
    final puerto = BusquedaIAOpenAI(
      byok: () => _byokEjemplo,
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': ''},
              },
            ],
          }),
          200,
        );
      },
    );

    expect(
      () => puerto.buscar(const Renglon(nombre: 'kiwi')),
      throwsA(isA<FormatException>()),
    );
  });

  test('JSON inválido del modelo es fallo del puerto', () async {
    final puerto = BusquedaIAOpenAI(
      byok: () => _byokEjemplo,
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': '{'},
              },
            ],
          }),
          200,
        );
      },
    );

    expect(
      () => puerto.buscar(const Renglon(nombre: 'kiwi')),
      throwsA(isA<FormatException>()),
    );
  });

  test('cercas markdown en el contenido siguen siendo Propuestas', () async {
    const contrato = '''
```json
{
  "propuestas": [
    {
      "nombre": "Yogur griego",
      "kcal_por_100g": 97,
      "proteina_g_por_100g": 10,
      "carbos_g_por_100g": 3.6,
      "grasa_g_por_100g": 5,
      "gramos_asumidos": 120
    }
  ]
}
```
''';
    final puerto = BusquedaIAOpenAI(
      byok: () => _byokEjemplo,
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': contrato},
              },
            ],
          }),
          200,
        );
      },
    );

    final propuestas = await puerto.buscar(
      const Renglon(nombre: 'banana chica'),
    );

    expect(propuestas.single.nombre, 'Yogur griego');
    expect(propuestas.single.gramosAsumidos, 120);
  });

  test('un timeout es fallo del puerto', () async {
    final puerto = BusquedaIAOpenAI(
      byok: () => _byokEjemplo,
      timeout: const Duration(milliseconds: 1),
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      },
    );

    expect(
      () => puerto.buscar(const Renglon(nombre: 'kiwi')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('la URL base con barra final apunta a chat.completions', () async {
    Uri? url;
    final puerto = BusquedaIAOpenAI(
      byok: () => const Byok(
        urlBase: 'https://api.ejemplo.com/v1/',
        claveApi: 'sk-secreto',
        idModelo: 'gpt-4o-mini',
      ),
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        url = destino;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"propuestas":[{"nombre":"Kiwi","kcal_por_100g":61,"proteina_g_por_100g":1,"carbos_g_por_100g":15,"grasa_g_por_100g":0.5}]}',
                },
              },
            ],
          }),
          200,
        );
      },
    );

    await puerto.buscar(const Renglon(nombre: 'kiwi'));

    expect(url, Uri.parse('https://api.ejemplo.com/v1/chat/completions'));
  });

  test(
    'guardar BYOK hace que el siguiente Listo use URL, clave y modelo',
    () async {
      Uri? url;
      String? autorizacion;
      late final Diario diario;
      diario = Diario(
        busquedaIA: BusquedaIAOpenAI(
          byok: () => diario.byok,
          post: (destino, {Map<String, String>? headers, Object? body}) async {
            url = destino;
            autorizacion = headers?['Authorization'];
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {
                      'content': '{"propuestas":[{"nombre":"Kiwi","kcal_por_100g":61,"proteina_g_por_100g":1,"carbos_g_por_100g":15,"grasa_g_por_100g":0.5}]}',
                    },
                  },
                ],
              }),
              200,
            );
          },
        ),
      );
      diario.redactarComida(momento: Momento.extra, notas: 'kiwi');
      await diario.listo();
      expect(diario.resoluciones.single.ofreceCrearAlimento, isTrue);
      expect(url, isNull);

      await diario.guardarByok(_byokEjemplo);
      diario.redactarComida(momento: Momento.extra, notas: 'kiwi');
      await diario.listo();

      expect(url, Uri.parse('https://api.ejemplo.com/v1/chat/completions'));
      expect(autorizacion, 'Bearer sk-secreto');
      expect(diario.resoluciones.single.propuestas.single.nombre, 'Kiwi');
    },
  );

  test('BYOK con espacios recorta URL, clave y modelo', () async {
    Uri? url;
    String? autorizacion;
    String? cuerpo;
    final puerto = BusquedaIAOpenAI(
      byok: () => const Byok(
        urlBase: ' https://api.ejemplo.com/v1 ',
        claveApi: ' sk-secreto ',
        idModelo: ' gpt-4o-mini ',
      ),
      post: (destino, {Map<String, String>? headers, Object? body}) async {
        url = destino;
        autorizacion = headers?['Authorization'];
        cuerpo = body as String?;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"propuestas":[{"nombre":"Kiwi","kcal_por_100g":61,"proteina_g_por_100g":1,"carbos_g_por_100g":15,"grasa_g_por_100g":0.5}]}',
                },
              },
            ],
          }),
          200,
        );
      },
    );

    await puerto.buscar(const Renglon(nombre: 'kiwi'));

    expect(url, Uri.parse('https://api.ejemplo.com/v1/chat/completions'));
    expect(autorizacion, 'Bearer sk-secreto');
    expect(jsonDecode(cuerpo!)['model'], 'gpt-4o-mini');
  });
}

const _byokEjemplo = Byok(
  urlBase: 'https://api.ejemplo.com/v1',
  claveApi: 'sk-secreto',
  idModelo: 'gpt-4o-mini',
);
