import 'package:flutter/material.dart';

import 'confirmacion_comida.dart';
import 'diario.dart';
import 'motion.dart';
import 'tema.dart';

class CapturaComida extends StatefulWidget {
  const CapturaComida({super.key, required this.diario, this.fecha});

  final Diario diario;
  final DateTime? fecha;

  @override
  State<CapturaComida> createState() => _CapturaComidaState();
}

class _CapturaComidaState extends State<CapturaComida> {
  final _notas = TextEditingController();
  final _cantidadesPrevias = <TextEditingController>[];
  final _focosPrevios = <FocusNode>[];
  late Momento _momento;
  var _esperandoListo = false;
  var _cerrandoPrevios = false;

  /// How many parsed Renglones were on screen last time, and which indices
  /// appeared after first paint (those enter with motion).
  var _renglonesVistos = 0;
  final _nacidos = <int>{};

  DateTime get _fecha {
    return widget.fecha ?? widget.diario.hoy().fecha;
  }

  List<Renglon> get _renglonesPrevios {
    return widget.diario.renglonesDe(fecha: _fecha, momento: _momento);
  }

  Comida? get _comidaPrevia {
    return widget.diario.comidaDe(fecha: _fecha, momento: _momento);
  }

  @override
  void initState() {
    super.initState();
    _momento = widget.diario.momentoDeCaptura(_fecha);
    widget.diario.redactarComida(
      momento: _momento,
      notas: _notas.text,
      fecha: widget.fecha,
    );
    _alinearPrevios(_renglonesPrevios);
    _renglonesVistos = widget.diario.borrador?.renglones.length ?? 0;
    _notas.addListener(_sincronizar);
  }

  @override
  void dispose() {
    _notas
      ..removeListener(_sincronizar)
      ..dispose();
    _desecharPrevios();
    super.dispose();
  }

  void _desecharPrevios() {
    _cerrandoPrevios = true;
    for (final foco in _focosPrevios) {
      foco.dispose();
    }
    for (final cantidad in _cantidadesPrevias) {
      cantidad.dispose();
    }
    _cantidadesPrevias.clear();
    _focosPrevios.clear();
    _cerrandoPrevios = false;
  }

  void _alinearPrevios(List<Renglon> renglones) {
    if (_cantidadesPrevias.length != renglones.length) {
      _desecharPrevios();
      for (final renglon in renglones) {
        _cantidadesPrevias.add(
          TextEditingController(text: _textoCantidad(renglon.cantidad ?? 0)),
        );
        final indice = _focosPrevios.length;
        final foco = FocusNode();
        foco.addListener(() {
          if (!foco.hasFocus && !_cerrandoPrevios) {
            _persistirCantidad(indice);
          }
        });
        _focosPrevios.add(foco);
      }
      return;
    }
    for (var i = 0; i < renglones.length; i++) {
      if (_focosPrevios[i].hasFocus) {
        continue;
      }
      final texto = _textoCantidad(renglones[i].cantidad ?? 0);
      if (_cantidadesPrevias[i].text != texto) {
        _cantidadesPrevias[i].text = texto;
      }
    }
  }

  void _sincronizar() {
    widget.diario.redactarComida(
      momento: _momento,
      notas: _notas.text,
      fecha: widget.fecha,
    );
    final cuantos = widget.diario.borrador?.renglones.length ?? 0;
    for (var i = _renglonesVistos; i < cuantos; i++) {
      _nacidos.add(i);
    }
    _nacidos.removeWhere((i) => i >= cuantos);
    _renglonesVistos = cuantos;
    setState(() {});
  }

  Future<void> _cancelar() async {
    await _persistirCantidades();
    widget.diario.cancelarBorrador();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _elegirMomento(Momento momento) async {
    await _persistirCantidades();
    _momento = momento;
    _desecharPrevios();
    _alinearPrevios(_renglonesPrevios);
    _sincronizar();
  }

  Future<void> _persistirCantidades() async {
    final textos = [for (final cantidad in _cantidadesPrevias) cantidad.text];
    await _aplicarCantidades(textos);
  }

  Future<void> _aplicarCantidades(List<String> textos) async {
    for (var i = 0; i < textos.length; i++) {
      await _persistirCantidad(i, texto: textos[i]);
    }
  }

  Future<void> _persistirCantidad(int indice, {String? texto}) async {
    final comida = _comidaPrevia;
    if (comida == null || indice >= comida.renglones.length) {
      return;
    }
    final crudo = texto ?? _cantidadesPrevias[indice].text;
    final numero = _parsearCantidad(crudo);
    if (numero == null || numero <= 0) {
      return;
    }
    if (comida.renglones[indice].cantidad == numero) {
      return;
    }
    await widget.diario.editarRenglon(
      comidaId: comida.id,
      indice: indice,
      cantidad: numero,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _borrarPrevio(int indice) async {
    final comida = _comidaPrevia;
    if (comida == null) {
      return;
    }
    await widget.diario.eliminarRenglon(comidaId: comida.id, indice: indice);
    _desecharPrevios();
    _alinearPrevios(_renglonesPrevios);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _listo() async {
    if (_esperandoListo) {
      return;
    }
    await _persistirCantidades();
    setState(() => _esperandoListo = true);
    try {
      await widget.diario.listo();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ConfirmacionComida(diario: widget.diario),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _esperandoListo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final renglones = widget.diario.borrador?.renglones ?? const <Renglon>[];
    final previos = _renglonesPrevios;
    _alinearPrevios(previos);
    final listoHabilitado = renglones.isNotEmpty && !_esperandoListo;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          final textos = [
            for (final cantidad in _cantidadesPrevias) cantidad.text,
          ];
          _aplicarCantidades(textos);
          widget.diario.cancelarBorrador();
        }
      },
      child: Scaffold(
        backgroundColor: esquema.surface,
        appBar: AppBar(
          backgroundColor: esquema.surface,
          titleSpacing: 4,
          title: Text(_momento.etiqueta),
          leading: IconButton(
            icon: const Icon(IconosNutri.cerrar),
            tooltip: 'Cancelar',
            onPressed: _cancelar,
          ),
          actions: [
            TextButton(
              onPressed: _cancelar,
              style: TextButton.styleFrom(
                foregroundColor: esquema.onSurfaceVariant,
              ),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: listoHabilitado ? _listo : null,
              style: TextButton.styleFrom(
                backgroundColor: esquema.primaryContainer,
                foregroundColor: esquema.onPrimaryContainer,
                disabledBackgroundColor: esquema.onSurface.withValues(
                  alpha: 0.06,
                ),
                disabledForegroundColor: esquema.onSurface.withValues(
                  alpha: 0.38,
                ),
                minimumSize: const Size(72, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Listo'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            margenPantalla,
            8,
            margenPantalla,
            32,
          ),
          children: [
            Text('Momento', style: ceja(context)),
            const SizedBox(height: 10),
            // Two by two: four chips do not fit one row at 412 px, and a
            // lone "Extra" on a second row reads as an afterthought.
            LayoutBuilder(
              builder: (context, restricciones) {
                final ancho = (restricciones.maxWidth - 8) / 2;
                // Chips keep their 48 px tap target, which already leaves
                // a visible gap between the two rows.
                return Wrap(
                  spacing: 8,
                  children: [
                    for (final momento in Momento.values)
                      SizedBox(
                        width: ancho,
                        child: ChoiceChip(
                          avatar: Icon(
                            iconoDeMomento(
                              momento,
                              grueso: _momento == momento,
                            ),
                            size: 18,
                            color: _momento == momento
                                ? esquema.onTertiary
                                : esquema.onSurfaceVariant,
                          ),
                          showCheckmark: false,
                          selectedColor: esquema.tertiary,
                          labelStyle: theme.textTheme.labelLarge?.copyWith(
                            color: _momento == momento
                                ? esquema.onTertiary
                                : esquema.onSurface,
                          ),
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(momento.etiqueta),
                          ),
                          selected: _momento == momento,
                          onSelected: (_) {
                            if (_momento != momento) {
                              hapticoSeleccion();
                            }
                            _elegirMomento(momento);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: entreSecciones),
            if (previos.isNotEmpty) ...[
              TarjetaNutri(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < previos.length; i++) ...[
                      if (i > 0)
                        Divider(
                          indent: 16,
                          endIndent: 16,
                          color: esquema.outlineVariant.withValues(alpha: 0.7),
                        ),
                      _FilaPrevia(
                        nombre: _tituloRenglon(previos[i]),
                        cantidad: _cantidadesPrevias[i],
                        foco: _focosPrevios[i],
                        onEnviar: () => _persistirCantidad(i),
                        onBorrar: () => _borrarPrevio(i),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: entreRenglones),
            ],
            _HojaDeCuaderno(controller: _notas),
            const SizedBox(height: entreSecciones),
            Text('Renglones', style: ceja(context)),
            const SizedBox(height: 10),
            if (renglones.isEmpty)
              Text(
                'Escribí una línea por alimento. Enter abre el siguiente Renglón.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              )
            else
              TarjetaNutri(
                padding: const EdgeInsets.symmetric(
                  horizontal: rellenoTarjeta,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < renglones.length; i++)
                      _entrada(
                        context,
                        i,
                        Padding(
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : entreRenglones - 4,
                          ),
                          child: _FilaMenu(
                            nombre: _tituloRenglon(renglones[i]),
                            cantidad: _cantidadRenglon(renglones[i]),
                            sinCantidad:
                                renglones[i].nombre.isNotEmpty &&
                                renglones[i].cantidad == null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Rows that appeared after first paint enter with [entradaRenglon]; the
  /// key keeps a finished entrance from replaying while the row's text changes.
  Widget _entrada(BuildContext context, int indice, Widget fila) {
    if (!_nacidos.contains(indice)) {
      return fila;
    }
    return entradaRenglon(context, fila, key: ValueKey('nacido-$indice'));
  }
}

/// A Renglón already saved in this Comida: name, a stadium Cantidad, delete.
class _FilaPrevia extends StatelessWidget {
  const _FilaPrevia({
    required this.nombre,
    required this.cantidad,
    required this.foco,
    required this.onEnviar,
    required this.onBorrar,
  });

  final String nombre;
  final TextEditingController cantidad;
  final FocusNode foco;
  final VoidCallback onEnviar;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    const estadio = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(rellenoTarjeta, 6, 4, 6),
      child: Row(
        children: [
          Expanded(child: Text(nombre, style: theme.textTheme.bodyLarge)),
          const SizedBox(width: 12),
          SizedBox(
            width: 112,
            child: TextFormField(
              controller: cantidad,
              focusNode: foco,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.end,
              style: cifra(theme.textTheme.bodyLarge),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                suffixText: 'g',
                suffixStyle: cifra(theme.textTheme.bodyMedium)
                    .copyWith(color: esquema.onSurfaceVariant),
                isDense: true,
                filled: true,
                fillColor: esquema.surfaceContainer,
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
                border: estadio,
                enabledBorder: estadio,
                focusedBorder: estadio.copyWith(
                  borderSide: BorderSide(color: esquema.primary, width: 2),
                ),
              ),
              onFieldSubmitted: (_) => onEnviar(),
            ),
          ),
          IconButton(
            tooltip: 'Borrar Renglón',
            onPressed: onBorrar,
            color: esquema.onSurfaceVariant,
            icon: const Icon(IconosNutri.borrar, size: 20),
          ),
        ],
      ),
    );
  }
}

/// The notes field as a notebook page: papel, a rule under every line, and a
/// tomato margin line. The field's strut pins each line to [_alturaLinea] so
/// the text sits on the rules however many lines it has.
class _HojaDeCuaderno extends StatelessWidget {
  const _HojaDeCuaderno({required this.controller});

  final TextEditingController controller;

  static const _arriba = 18.0;
  static const _margen = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final cuerpo = theme.textTheme.bodyLarge!;
    final alturaLinea = cuerpo.fontSize! * cuerpo.height!;
    final estilo = cuerpo.copyWith(color: esquema.onSurface);
    return TarjetaNutri(
      padding: null,
      child: CustomPaint(
        painter: _PintorRenglones(
          arriba: _arriba,
          alturaLinea: alturaLinea,
          margen: _margen,
          renglon: esquema.outlineVariant,
          lineaMargen: esquema.error.withValues(alpha: 0.3),
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          minLines: 6,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: estilo,
          strutStyle: StrutStyle.fromTextStyle(estilo, forceStrutHeight: true),
          cursorColor: esquema.tertiary,
          decoration: InputDecoration(
            hintText: '100g yogur griego',
            hintStyle: estilo.copyWith(color: esquema.onSurfaceVariant),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: const EdgeInsets.fromLTRB(
              _margen + 14,
              _arriba,
              rellenoTarjeta,
              _arriba + alturaLineaSobrante,
            ),
          ),
        ),
      ),
    );
  }

  /// Extra bottom room so the last rule is not flush with the card's edge.
  static const alturaLineaSobrante = 6.0;
}

class _PintorRenglones extends CustomPainter {
  const _PintorRenglones({
    required this.arriba,
    required this.alturaLinea,
    required this.margen,
    required this.renglon,
    required this.lineaMargen,
  });

  final double arriba;
  final double alturaLinea;
  final double margen;
  final Color renglon;
  final Color lineaMargen;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = renglon
      ..strokeWidth = 1;
    // A rule just under each line's descenders.
    for (
      var y = arriba + alturaLinea - 4;
      y < size.height - 4;
      y += alturaLinea
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pincel);
    }
    canvas.drawLine(
      Offset(margen, 0),
      Offset(margen, size.height),
      Paint()
        ..color = lineaMargen
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PintorRenglones old) {
    return old.arriba != arriba ||
        old.alturaLinea != alturaLinea ||
        old.margen != margen ||
        old.renglon != renglon ||
        old.lineaMargen != lineaMargen;
  }
}

/// A parsed Renglón read like a menu: name, a dotted leader that fills the gap
/// after the name's last line, grams in DM Mono.
class _FilaMenu extends StatelessWidget {
  const _FilaMenu({
    required this.nombre,
    required this.cantidad,
    required this.sinCantidad,
  });

  final String nombre;
  final String cantidad;
  final bool sinCantidad;

  static const _hueco = 6.0;
  static const _guiaMinima = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final estiloNombre = theme.textTheme.bodyLarge!.copyWith(
      color: esquema.onSurface,
    );
    final alturaLinea = estiloNombre.fontSize! * estiloNombre.height!;
    final base = theme.textTheme.bodyMedium!;
    final estiloCantidad = sinCantidad
        ? base.copyWith(
            color: esquema.onSurfaceVariant,
            fontStyle: FontStyle.italic,
            height: alturaLinea / base.fontSize!,
          )
        : cifra(base).copyWith(
            color: esquema.onSurface,
            height: alturaLinea / base.fontSize!,
          );
    final escala = MediaQuery.textScalerOf(context);
    final direccion = Directionality.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, restricciones) {
              final ancho = restricciones.maxWidth;
              final conGuia = cantidad.isNotEmpty;
              final anchoTexto = conGuia ? ancho - _guiaMinima : ancho;
              final pintor = TextPainter(
                text: TextSpan(text: nombre, style: estiloNombre),
                textDirection: direccion,
                textScaler: escala,
              )..layout(maxWidth: anchoTexto);
              final lineas = pintor.computeLineMetrics();
              final ultima = lineas.isEmpty ? null : lineas.last;
              pintor.dispose();
              return CustomPaint(
                foregroundPainter: conGuia && ultima != null
                    ? _PintorGuia(
                        desde: ultima.left + ultima.width + _hueco,
                        hasta: ancho,
                        y: ultima.baseline,
                        color: esquema.outline,
                      )
                    : null,
                child: Padding(
                  padding: EdgeInsets.only(right: ancho - anchoTexto),
                  child: Text(nombre, style: estiloNombre),
                ),
              );
            },
          ),
        ),
        if (cantidad.isNotEmpty) ...[
          const SizedBox(width: _hueco),
          Text(cantidad, style: estiloCantidad),
        ],
      ],
    );
  }
}

class _PintorGuia extends CustomPainter {
  const _PintorGuia({
    required this.desde,
    required this.hasta,
    required this.y,
    required this.color,
  });

  final double desde;
  final double hasta;
  final double y;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()..color = color;
    const paso = 5.0;
    // Right-align the dots so every row's leader ends at the grams.
    for (var x = hasta - 1.5; x >= desde; x -= paso) {
      canvas.drawCircle(Offset(x, y - 1), 1, pincel);
    }
  }

  @override
  bool shouldRepaint(_PintorGuia old) {
    return old.desde != desde ||
        old.hasta != hasta ||
        old.y != y ||
        old.color != color;
  }
}

String _tituloRenglon(Renglon renglon) {
  if (renglon.nombre.isEmpty) {
    return '${renglon.cantidad} g';
  }
  return renglon.nombre;
}

String _cantidadRenglon(Renglon renglon) {
  if (renglon.nombre.isEmpty) {
    return '';
  }
  if (renglon.cantidad == null) {
    return 'sin cantidad';
  }
  return '${renglon.cantidad} g';
}

String _textoCantidad(num valor) {
  if (valor == valor.roundToDouble()) {
    return valor.round().toString();
  }
  return valor.toString();
}

num? _parsearCantidad(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) {
    return null;
  }
  return num.tryParse(limpio);
}
