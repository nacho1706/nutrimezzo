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
  late Momento _momento;
  var _esperandoListo = false;

  DateTime get _fecha {
    return widget.fecha ?? widget.diario.hoy().fecha;
  }

  List<Renglon> get _renglonesPrevios {
    return widget.diario.renglonesDe(fecha: _fecha, momento: _momento);
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
    _notas.addListener(_sincronizar);
  }

  @override
  void dispose() {
    _notas
      ..removeListener(_sincronizar)
      ..dispose();
    super.dispose();
  }

  void _sincronizar() {
    widget.diario.redactarComida(
      momento: _momento,
      notas: _notas.text,
      fecha: widget.fecha,
    );
    setState(() {});
  }

  void _cancelar() {
    widget.diario.cancelarBorrador();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _elegirMomento(Momento momento) {
    _momento = momento;
    _sincronizar();
  }

  Future<void> _listo() async {
    if (_esperandoListo) {
      return;
    }
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
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
            for (final renglon in _renglonesPrevios)
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
            if (_renglonesPrevios.isNotEmpty) const SizedBox(height: 16),
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
