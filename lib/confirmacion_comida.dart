import 'package:flutter/material.dart';

import 'diario.dart';
import 'motion.dart';

class ConfirmacionComida extends StatefulWidget {
  const ConfirmacionComida({super.key, required this.diario});

  final Diario diario;

  @override
  State<ConfirmacionComida> createState() => _ConfirmacionComidaState();
}

class _ConfirmacionComidaState extends State<ConfirmacionComida> {
  final _formKey = GlobalKey<FormState>();
  late final List<_FilaConfirmacion> _filas;
  var _confirmando = false;

  @override
  void initState() {
    super.initState();
    _filas = [
      for (final resuelto in widget.diario.resoluciones)
        _FilaConfirmacion(resuelto),
    ];
    for (final fila in _filas) {
      fila.gramos.addListener(_alCambiarFila);
      fila.kcal.addListener(_alCambiarFila);
      fila.proteina.addListener(_alCambiarFila);
      fila.carbos.addListener(_alCambiarFila);
      fila.grasa.addListener(_alCambiarFila);
    }
  }

  @override
  void dispose() {
    for (final fila in _filas) {
      fila.gramos.removeListener(_alCambiarFila);
      fila.kcal.removeListener(_alCambiarFila);
      fila.proteina.removeListener(_alCambiarFila);
      fila.carbos.removeListener(_alCambiarFila);
      fila.grasa.removeListener(_alCambiarFila);
      fila.dispose();
    }
    super.dispose();
  }

  void _alCambiarFila() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (var i = 0; i < _filas.length; i++) ...[
              if (i > 0) const SizedBox(height: 28),
              entradaRenglon(
                context,
                _RenglonConfirmacion(
                  fila: _filas[i],
                  onElegir: (indice) => _elegirPropuesta(_filas[i], indice),
                ),
                key: ValueKey(i),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _confirmando ? null : _confirmar,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  void _elegirPropuesta(_FilaConfirmacion fila, int indice) {
    setState(() {
      fila.elegida = indice;
      if (fila.resuelto.renglon.cantidad == null) {
        final asumidos = fila.resuelto.propuestas[indice].gramosAsumidos;
        if (asumidos != null) {
          fila.gramos.text = _textoNumero(asumidos);
        }
      }
    });
  }

  Future<void> _confirmar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _confirmando = true);
    try {
      await widget.diario.confirmar([
        for (final fila in _filas) fila.eleccion(),
      ]);
      if (mounted) {
        Navigator.of(context).popUntil((ruta) => ruta.isFirst);
      }
    } finally {
      if (mounted) {
        setState(() => _confirmando = false);
      }
    }
  }
}

class _FilaConfirmacion {
  _FilaConfirmacion(this.resuelto)
    : elegida = resuelto.propuestas.isEmpty ? null : 0,
      gramos = TextEditingController(
        text: _textoNumeroOVacio(resuelto.cantidadSugerida),
      ),
      nombre = TextEditingController(text: resuelto.renglon.nombre),
      kcal = TextEditingController(),
      proteina = TextEditingController(),
      carbos = TextEditingController(),
      grasa = TextEditingController();

  final RenglonResuelto resuelto;
  int? elegida;
  final TextEditingController gramos;
  final TextEditingController nombre;
  final TextEditingController kcal;
  final TextEditingController proteina;
  final TextEditingController carbos;
  final TextEditingController grasa;

  Macros? get macrosPor100gCreados {
    final kcalValor = _parsearNumero(kcal.text);
    final proteinaValor = _parsearNumero(proteina.text);
    final carbosValor = _parsearNumero(carbos.text);
    final grasaValor = _parsearNumero(grasa.text);
    if (kcalValor == null ||
        proteinaValor == null ||
        carbosValor == null ||
        grasaValor == null) {
      return null;
    }
    if (kcalValor < 0 ||
        proteinaValor < 0 ||
        carbosValor < 0 ||
        grasaValor < 0) {
      return null;
    }
    return Macros(
      kcal: kcalValor,
      proteina: proteinaValor,
      carbos: carbosValor,
      grasa: grasaValor,
    );
  }

  void dispose() {
    gramos.dispose();
    nombre.dispose();
    kcal.dispose();
    proteina.dispose();
    carbos.dispose();
    grasa.dispose();
  }

  EleccionRenglon eleccion() {
    final cantidad = _parsearNumero(gramos.text)!;
    if (resuelto.ofreceCrearAlimento) {
      return EleccionRenglon(
        cantidad: cantidad,
        crearNombre: nombre.text.trim(),
        crearMacros: Macros(
          kcal: _parsearNumero(kcal.text)!,
          proteina: _parsearNumero(proteina.text)!,
          carbos: _parsearNumero(carbos.text)!,
          grasa: _parsearNumero(grasa.text)!,
        ),
      );
    }
    return EleccionRenglon(
      cantidad: cantidad,
      propuesta: resuelto.propuestas[elegida!],
    );
  }
}

class _RenglonConfirmacion extends StatelessWidget {
  const _RenglonConfirmacion({required this.fila, required this.onElegir});

  final _FilaConfirmacion fila;
  final ValueChanged<int> onElegir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resuelto = fila.resuelto;
    final sinCantidad = resuelto.renglon.cantidad == null;
    final macrosCreados = _detalleMacrosPorCantidad(
      fila.macrosPor100gCreados,
      fila.gramos.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          resuelto.renglon.nombre.isEmpty
              ? '${resuelto.renglon.cantidad} g'
              : resuelto.renglon.nombre,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fila.gramos,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Gramos',
            suffixText: 'g',
            helperText: sinCantidad ? 'gramos asumidos' : null,
          ),
          validator: _validarCantidad,
        ),
        if (resuelto.ofreceCrearAlimento) ...[
          const SizedBox(height: 16),
          Text('Crear Alimento', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: fila.nombre,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: _validarNombre,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: fila.kcal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Calorías',
              suffixText: 'kcal / 100 g',
            ),
            validator: _validarMacro,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: fila.proteina,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Proteína (P)',
              suffixText: 'g / 100 g',
            ),
            validator: _validarMacro,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: fila.carbos,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Carbos (C)',
              suffixText: 'g / 100 g',
            ),
            validator: _validarMacro,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: fila.grasa,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Grasa (F)',
              suffixText: 'g / 100 g',
            ),
            validator: _validarMacro,
          ),
          if (macrosCreados != null) ...[
            const SizedBox(height: 12),
            Text(macrosCreados, style: theme.textTheme.bodyMedium),
          ],
        ] else
          RadioGroup<int>(
            groupValue: fila.elegida,
            onChanged: (valor) {
              if (valor != null) {
                onElegir(valor);
              }
            },
            child: Column(
              children: [
                for (var i = 0; i < resuelto.propuestas.length; i++)
                  RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(resuelto.propuestas[i].nombre),
                    subtitle: Text(
                      _detallePropuesta(
                        resuelto.propuestas[i],
                        fila.gramos.text,
                      ),
                    ),
                    isThreeLine: _detalleMacrosPorCantidad(
                          resuelto.propuestas[i].macrosPor100g,
                          fila.gramos.text,
                        ) !=
                        null,
                    value: i,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

String _textoNumeroOVacio(num? valor) {
  if (valor == null) {
    return '';
  }
  return _textoNumero(valor);
}

String _detallePropuesta(Propuesta propuesta, String gramosTexto) {
  final por100g = _detalleMacros(propuesta.macrosPor100g, 100);
  final porCantidad = _detalleMacrosPorCantidad(
    propuesta.macrosPor100g,
    gramosTexto,
  );
  if (porCantidad == null) {
    return por100g;
  }
  return '$por100g\n$porCantidad';
}

String? _detalleMacrosPorCantidad(Macros? macrosPor100g, String gramosTexto) {
  if (macrosPor100g == null) {
    return null;
  }
  final gramos = _parsearNumero(gramosTexto);
  if (gramos == null || gramos <= 0) {
    return null;
  }
  return _detalleMacros(macrosPor100g.paraGramos(gramos), gramos);
}

String _detalleMacros(Macros macros, num gramos) {
  return '${_textoNumero(macros.kcal)} kcal / ${_textoNumero(gramos)} g · '
      'P ${_textoNumero(macros.proteina)} · '
      'C ${_textoNumero(macros.carbos)} · '
      'F ${_textoNumero(macros.grasa)}';
}

String? _validarCantidad(String? valor) {
  final numero = _parsearNumero(valor ?? '');
  if (numero == null) {
    return 'Indicá los gramos';
  }
  if (numero <= 0) {
    return 'Tiene que ser más que 0 g';
  }
  return null;
}

String? _validarMacro(String? valor) {
  final numero = _parsearNumero(valor ?? '');
  if (numero == null) {
    return 'Indicá un número';
  }
  if (numero < 0) {
    return 'Tiene que ser 0 o más';
  }
  return null;
}

String? _validarNombre(String? valor) {
  if ((valor ?? '').trim().isEmpty) {
    return 'Indicá un nombre';
  }
  return null;
}

String _textoNumero(num valor) {
  if (valor == valor.roundToDouble()) {
    return valor.round().toString();
  }
  return valor.toString();
}

num? _parsearNumero(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) {
    return null;
  }
  return num.tryParse(limpio);
}
