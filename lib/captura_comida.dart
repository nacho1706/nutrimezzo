import 'package:flutter/material.dart';

import 'diario.dart';

class CapturaComida extends StatefulWidget {
  const CapturaComida({super.key, required this.diario});

  final Diario diario;

  @override
  State<CapturaComida> createState() => _CapturaComidaState();
}

class _CapturaComidaState extends State<CapturaComida> {
  final _notas = TextEditingController();
  Momento _momento = Momento.desayuno;

  @override
  void initState() {
    super.initState();
    widget.diario.redactarComida(momento: _momento, notas: _notas.text);
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
    widget.diario.redactarComida(momento: _momento, notas: _notas.text);
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
          title: const Text('Nueva comida'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar',
            onPressed: _cancelar,
          ),
          actions: [
            TextButton(onPressed: _cancelar, child: const Text('Cancelar')),
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
                    label: Text(_etiquetaMomento(momento)),
                    selected: _momento == momento,
                    onSelected: (_) => _elegirMomento(momento),
                  ),
              ],
            ),
            const SizedBox(height: 24),
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

String _etiquetaMomento(Momento momento) {
  return switch (momento) {
    Momento.desayuno => 'Desayuno',
    Momento.almuerzo => 'Almuerzo',
    Momento.cena => 'Cena',
    Momento.extra => 'Extra',
  };
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
