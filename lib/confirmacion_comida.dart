import 'package:flutter/material.dart';

import 'diario.dart';
import 'motion.dart';
import 'tema.dart';

class ConfirmacionComida extends StatefulWidget {
  const ConfirmacionComida({super.key, required this.diario});

  final Diario diario;

  @override
  State<ConfirmacionComida> createState() => _ConfirmacionComidaState();
}

class _ConfirmacionComidaState extends State<ConfirmacionComida> {
  final _formKey = GlobalKey<FormState>();
  late final List<_FilaConfirmacion> _filas;
  final _sacudida = ControladorSacudida();
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
    _sacudida.dispose();
    super.dispose();
  }

  void _alCambiarFila() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: esquema.surface,
      appBar: AppBar(title: const Text('Confirmación')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  margenPantalla,
                  8,
                  margenPantalla,
                  entreSecciones,
                ),
                children: [
                  for (var i = 0; i < _filas.length; i++) ...[
                    if (i > 0) const SizedBox(height: entreRenglones + 4),
                    entradaRenglon(
                      context,
                      _RenglonConfirmacion(
                        fila: _filas[i],
                        onElegir: (indice) =>
                            _elegirPropuesta(_filas[i], indice),
                      ),
                      key: ValueKey(i),
                    ),
                  ],
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: esquema.surface,
                border: Border(top: hiloTarjeta(context)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    margenPantalla,
                    12,
                    margenPantalla,
                    16,
                  ),
                  child: Sacudible(
                    controlador: _sacudida,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _confirmando ? null : _confirmar,
                        child: const Text('Confirmar'),
                      ),
                    ),
                  ),
                ),
              ),
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
      _sacudida.sacudir();
      return;
    }
    setState(() => _confirmando = true);
    try {
      await widget.diario.confirmar([
        for (final fila in _filas) fila.eleccion(),
      ]);
      hapticoExito();
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
    final esquema = theme.colorScheme;
    final resuelto = fila.resuelto;
    final sinCantidad = resuelto.renglon.cantidad == null;
    final macrosCreados = _detalleMacrosPorCantidad(
      fila.macrosPor100gCreados,
      fila.gramos.text,
    );

    return TarjetaNutri(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            resuelto.renglon.nombre.isEmpty
                ? '${resuelto.renglon.cantidad} g'
                : resuelto.renglon.nombre,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: fila.gramos,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: cifra(theme.textTheme.bodyLarge),
            decoration: InputDecoration(
              labelText: 'Gramos',
              suffixText: 'g',
              fillColor: esquema.surfaceContainer,
              helperText: sinCantidad ? 'gramos asumidos' : null,
            ),
            validator: _validarCantidad,
          ),
          const SizedBox(height: 16),
          if (resuelto.ofreceCrearAlimento)
            _CrearAlimento(fila: fila, macrosCreados: macrosCreados)
          else
            RadioGroup<int>(
              groupValue: fila.elegida,
              onChanged: (valor) {
                if (valor != null) {
                  hapticoSeleccion();
                  onElegir(valor);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < resuelto.propuestas.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _TarjetaPropuesta(
                      propuesta: resuelto.propuestas[i],
                      indice: i,
                      elegida: fila.elegida == i,
                      gramosTexto: fila.gramos.text,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A Propuesta as a selectable card: still a [RadioListTile], tinted
/// `primaryContainer` with a 2 px `primary` border when chosen.
class _TarjetaPropuesta extends StatelessWidget {
  const _TarjetaPropuesta({
    required this.propuesta,
    required this.indice,
    required this.elegida,
    required this.gramosTexto,
  });

  final Propuesta propuesta;
  final int indice;
  final bool elegida;
  final String gramosTexto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final colorTexto = elegida ? esquema.onPrimaryContainer : esquema.onSurface;
    final colorDetalle = elegida
        ? esquema.onPrimaryContainer.withValues(alpha: 0.8)
        : esquema.onSurfaceVariant;
    return Presionable(
      child: RadioListTile<int>(
        value: indice,
        shape: formaTarjeta(
          radio: radioPopup,
          lado: elegida
              ? BorderSide(color: esquema.primary, width: 2)
              : BorderSide(color: esquema.outlineVariant),
        ),
        tileColor: elegida ? esquema.primaryContainer : Colors.transparent,
        contentPadding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                propuesta.nombre,
                style: theme.textTheme.titleMedium?.copyWith(color: colorTexto),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: _InsigniaOrigen(deCatalogo: propuesta.alimentoId != null),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _detallePropuesta(propuesta, gramosTexto),
            // DM Sans with tabular digits: DM Mono is too wide to keep
            // each detail on one line inside the card at 412 px.
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorDetalle,
              height: 1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        isThreeLine:
            _detalleMacrosPorCantidad(propuesta.macrosPor100g, gramosTexto) !=
            null,
      ),
    );
  }
}

/// Where a Propuesta comes from: the Catálogo or the IA.
class _InsigniaOrigen extends StatelessWidget {
  const _InsigniaOrigen({required this.deCatalogo});

  final bool deCatalogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final fondo = esquema.tertiaryContainer;
    final tinta = esquema.onTertiaryContainer;
    return DecoratedBox(
      decoration: ShapeDecoration(color: fondo, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              deCatalogo ? IconosNutri.origenCatalogo : IconosNutri.origenIa,
              size: 12,
              color: tinta,
            ),
            const SizedBox(width: 4),
            Text(
              deCatalogo ? 'Catálogo' : 'IA',
              style: theme.textTheme.labelSmall?.copyWith(color: tinta),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Crear Alimento block: a lino card, macro fields prefixed by
/// their hue dot.
class _CrearAlimento extends StatelessWidget {
  const _CrearAlimento({required this.fila, required this.macrosCreados});

  final _FilaConfirmacion fila;
  final String? macrosCreados;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final tonos = TonosNutri.of(context);

    InputDecoration decoracion(
      String etiqueta, {
      String? sufijo,
      MacroVisual? macro,
    }) {
      return InputDecoration(
        labelText: etiqueta,
        suffixText: sufijo,
        fillColor: tonos.papel,
        prefixIcon: macro == null ? null : _PuntoMacro(macro: macro),
        prefixIconConstraints: macro == null
            ? null
            : const BoxConstraints(minWidth: 36, minHeight: 0),
      );
    }

    final estiloNumero = cifra(theme.textTheme.bodyLarge);
    const teclado = TextInputType.numberWithOptions(decimal: true);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: esquema.tertiaryContainer,
        shape: formaTarjeta(radio: radioPopup),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  IconosNutri.crear,
                  size: 16,
                  color: esquema.onTertiaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Crear Alimento',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: esquema.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fila.nombre,
              decoration: decoracion('Nombre'),
              validator: _validarNombre,
            ),
            const SizedBox(height: entreRenglones),
            TextFormField(
              controller: fila.kcal,
              keyboardType: teclado,
              style: estiloNumero,
              decoration: decoracion(
                'Calorías',
                sufijo: 'kcal / 100 g',
                macro: MacroVisual.kcal,
              ),
              validator: _validarMacro,
            ),
            const SizedBox(height: entreRenglones),
            TextFormField(
              controller: fila.proteina,
              keyboardType: teclado,
              style: estiloNumero,
              decoration: decoracion(
                'Proteína (P)',
                sufijo: 'g / 100 g',
                macro: MacroVisual.proteina,
              ),
              validator: _validarMacro,
            ),
            const SizedBox(height: entreRenglones),
            TextFormField(
              controller: fila.carbos,
              keyboardType: teclado,
              style: estiloNumero,
              decoration: decoracion(
                'Carbos (C)',
                sufijo: 'g / 100 g',
                macro: MacroVisual.carbos,
              ),
              validator: _validarMacro,
            ),
            const SizedBox(height: entreRenglones),
            TextFormField(
              controller: fila.grasa,
              keyboardType: teclado,
              style: estiloNumero,
              decoration: decoracion(
                'Grasa (F)',
                sufijo: 'g / 100 g',
                macro: MacroVisual.grasa,
              ),
              validator: _validarMacro,
            ),
            if (macrosCreados != null) ...[
              const SizedBox(height: entreRenglones),
              Text(
                macrosCreados!,
                style: cifra(theme.textTheme.bodyMedium)
                    .copyWith(color: esquema.onSurface),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PuntoMacro extends StatelessWidget {
  const _PuntoMacro({required this.macro});

  final MacroVisual macro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 14, end: 4),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          dimension: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: macro.color(context),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
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
