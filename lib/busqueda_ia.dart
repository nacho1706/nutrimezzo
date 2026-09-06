import 'dart:convert';

import 'package:http/http.dart' as http;

import 'codec_json_propuesta.dart';
import 'diario.dart';

typedef PostChat = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

class BusquedaIAOpenAI implements PuertoBusquedaIA {
  BusquedaIAOpenAI({
    required Byok Function() byok,
    PostChat? post,
    Duration timeout = const Duration(seconds: 20),
  }) : // Public names; the fields stay private.
       // ignore: prefer_initializing_formals
       _byok = byok,
       _post = post ?? _postPorDefecto,
       // ignore: prefer_initializing_formals
       _timeout = timeout;

  final Byok Function() _byok;
  final PostChat _post;
  final Duration _timeout;

  @override
  Future<List<Propuesta>> buscar(Renglon renglon) async {
    final byok = _byok();
    final urlBase = byok.urlBase.trim();
    final claveApi = byok.claveApi.trim();
    final idModelo = byok.idModelo.trim();
    if (urlBase.isEmpty || claveApi.isEmpty || idModelo.isEmpty) {
      return const [];
    }
    final url = Uri.parse('${_urlBase(urlBase)}/chat/completions');
    final respuesta = await _post(
      url,
      headers: {
        'Authorization': 'Bearer $claveApi',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': idModelo,
        'messages': [
          {'role': 'system', 'content': _instrucciones},
          {'role': 'user', 'content': _textoRenglon(renglon)},
        ],
      }),
    ).timeout(_timeout);
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw StateError('http ${respuesta.statusCode}');
    }
    return const CodecJsonPropuesta().decodificar(
      _contenidoChat(respuesta.body),
    );
  }
}

String _urlBase(String base) {
  var recortada = base.trim();
  while (recortada.endsWith('/')) {
    recortada = recortada.substring(0, recortada.length - 1);
  }
  return recortada;
}

String _contenidoChat(String cuerpo) {
  final decoded = jsonDecode(cuerpo);
  if (decoded is! Map || decoded['choices'] is! List) {
    throw const FormatException('respuesta');
  }
  final choices = decoded['choices'] as List<dynamic>;
  if (choices.isEmpty || choices.first is! Map) {
    throw const FormatException('respuesta');
  }
  final message = (choices.first as Map)['message'];
  if (message is! Map) {
    throw const FormatException('respuesta');
  }
  final content = message['content'];
  if (content is! String || content.trim().isEmpty) {
    throw const FormatException('respuesta');
  }
  return content;
}

String _textoRenglon(Renglon renglon) {
  if (renglon.cantidad == null) {
    return renglon.nombre;
  }
  if (renglon.nombre.isEmpty) {
    return '${renglon.cantidad}g';
  }
  return '${renglon.cantidad}g ${renglon.nombre}';
}

const _instrucciones = '''
You fill a calorie-tracker JSON contract. Reply with a single JSON object, no other text:
{"propuestas":[{"nombre":"string","kcal_por_100g":0,"proteina_g_por_100g":0,"carbos_g_por_100g":0,"grasa_g_por_100g":0,"gramos_asumidos":null}]}
Rules: at most two propuestas; macros are per 100 g; numbers must be JSON numbers >= 0; gramos_asumidos is a number > 0 when the line has no grams, otherwise null.
''';

Future<http.Response> _postPorDefecto(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
}) {
  return http.post(url, headers: headers, body: body);
}
