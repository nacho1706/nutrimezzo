import 'package:flutter/material.dart';

import 'confirmacion_comida.dart';
import 'diario.dart';

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
    final renglones = widget.diario.borrador?.renglones ?? const <Renglon>[];
    final previos = _renglonesPrevios;
    _alinearPrevios(previos);

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
        appBar: AppBar(
          title: Text(_momento.etiqueta),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar',
            onPressed: _cancelar,
          ),
          actions: [
            TextButton(onPressed: _cancelar, child: const Text('Cancelar')),
            TextButton(
              onPressed: renglones.isEmpty || _esperandoListo ? null : _listo,
              child: const Text('Listo'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('Momento', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final momento in Momento.values)
                  ChoiceChip(
                    label: Text(momento.etiqueta),
                    selected: _momento == momento,
                    onSelected: (_) => _elegirMomento(momento),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < previos.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_tituloRenglon(previos[i])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 96,
                      child: TextFormField(
                        controller: _cantidadesPrevias[i],
                        focusNode: _focosPrevios[i],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          suffixText: 'g',
                        ),
                        onFieldSubmitted: (_) => _persistirCantidad(i),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Borrar Renglón',
                      onPressed: () => _borrarPrevio(i),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            if (previos.isNotEmpty) const SizedBox(height: 16),
            TextField(
              controller: _notas,
              autofocus: true,
              minLines: 6,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: '100g yogur griego',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Renglones', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (renglones.isEmpty)
              Text(
                'Escribí una línea por alimento. Enter abre el siguiente Renglón.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final renglon in renglones)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_tituloRenglon(renglon)),
                  trailing: Text(
                    _cantidadRenglon(renglon),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
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
