import 'dart:convert';

import 'diario.dart';

class CodecJsonPropuesta {
  const CodecJsonPropuesta();

  List<Propuesta> decodificar(String crudo) {
    final decoded = jsonDecode(_sinCercaMarkdown(crudo));
    if (decoded is! Map) {
      throw const FormatException('contrato');
    }
    final lista = decoded['propuestas'];
    if (lista is! List<dynamic>) {
      throw const FormatException('contrato');
    }
    if (lista.length > 2) {
      throw const FormatException('contrato');
    }
    return [for (final item in lista) _propuesta(item)];
  }
}

Propuesta _propuesta(dynamic crudo) {
  if (crudo is! Map) {
    throw const FormatException('contrato');
  }
  final nombre = crudo['nombre'];
  if (nombre is! String || nombre.trim().isEmpty) {
    throw const FormatException('contrato');
  }
  return Propuesta(
    nombre: nombre.trim(),
    macrosPor100g: Macros(
      kcal: _macro(crudo['kcal_por_100g']),
      proteina: _macro(crudo['proteina_g_por_100g']),
      carbos: _macro(crudo['carbos_g_por_100g']),
      grasa: _macro(crudo['grasa_g_por_100g']),
    ),
    gramosAsumidos: _gramos(crudo['gramos_asumidos']),
  );
}

num _macro(dynamic valor) {
  if (valor is! num || !valor.isFinite || valor < 0) {
    throw const FormatException('contrato');
  }
  return valor;
}

num? _gramos(dynamic valor) {
  if (valor == null) {
    return null;
  }
  if (valor is! num || !valor.isFinite || valor <= 0) {
    throw const FormatException('contrato');
  }
  return valor;
}

String _sinCercaMarkdown(String crudo) {
  final texto = crudo.trim();
  if (!texto.startsWith('```')) {
    return texto;
  }
  final sinApertura = texto.substring(3);
  final finLinea = sinApertura.indexOf('\n');
  if (finLinea == -1) {
    throw const FormatException('contrato');
  }
  var interior = sinApertura.substring(finLinea + 1).trim();
  if (interior.endsWith('```')) {
    interior = interior.substring(0, interior.length - 3).trim();
  }
  return interior;
}
