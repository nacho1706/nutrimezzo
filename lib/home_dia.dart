import 'package:flutter/material.dart';

import 'ajustes.dart';
import 'captura_comida.dart';
import 'catalogo.dart';
import 'diario.dart';

class HomeDia extends StatefulWidget {
  const HomeDia({super.key, required this.diario});

  final Diario diario;

  @override
  State<HomeDia> createState() => _HomeDiaState();
}

class _HomeDiaState extends State<HomeDia> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dia = widget.diario.hoy();
    final meta = widget.diario.meta;
    final consumidos = dia.macros;
    final objetivo = meta.macros;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoy'),
        actions: [
          IconButton(
            tooltip: 'Catálogo',
            onPressed: _abrirCatalogo,
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: 'Ajustes',
            onPressed: _abrirAjustes,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCaptura,
        icon: const Icon(Icons.edit_note),
        label: const Text('Comida'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        children: [
          Text(
            _fechaEnEspanol(dia.fecha),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text('Contra la Meta', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          _MacroContraMeta(
            etiqueta: 'Calorías',
            unidad: 'kcal',
            consumido: consumidos.kcal,
            objetivo: objetivo.kcal,
          ),
          _MacroContraMeta(
            etiqueta: 'Proteína (P)',
            unidad: 'g',
            consumido: consumidos.proteina,
            objetivo: objetivo.proteina,
          ),
          _MacroContraMeta(
            etiqueta: 'Carbos (C)',
            unidad: 'g',
            consumido: consumidos.carbos,
            objetivo: objetivo.carbos,
          ),
          _MacroContraMeta(
            etiqueta: 'Grasa (F)',
            unidad: 'g',
            consumido: consumidos.grasa,
            objetivo: objetivo.grasa,
          ),
          for (final momento in Momento.values)
            ..._bloqueMomento(theme, dia, momento),
        ],
      ),
    );
  }

  Future<void> _abrirAjustes() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AjustesPagina(diario: widget.diario),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _abrirCatalogo() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CatalogoPagina(diario: widget.diario),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _abrirCaptura() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CapturaComida(diario: widget.diario),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  List<Widget> _bloqueMomento(ThemeData theme, Dia dia, Momento momento) {
    final comidas = [
      for (final comida in dia.comidas)
        if (comida.momento == momento) comida,
    ];
    if (comidas.isEmpty) {
      return const [];
    }
    return [
      const SizedBox(height: 12),
      Text(momento.etiqueta, style: theme.textTheme.titleMedium),
      for (final comida in comidas)
        for (final renglon in comida.renglones)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(renglon.nombre),
            trailing: Text(
              '${renglon.cantidad} g',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
    ];
  }
}

class _MacroContraMeta extends StatelessWidget {
  const _MacroContraMeta({
    required this.etiqueta,
    required this.unidad,
    required this.consumido,
    required this.objetivo,
  });

  final String etiqueta;
  final String unidad;
  final num consumido;
  final num objetivo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progreso = objetivo <= 0
        ? 0.0
        : (consumido / objetivo).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(etiqueta, style: theme.textTheme.titleMedium),
              ),
              Text(
                '${_entero(consumido)} / ${_entero(objetivo)} $unidad',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progreso.toDouble(),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

String _fechaEnEspanol(DateTime fecha) {
  const dias = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  const meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
}

String _entero(num valor) => valor.round().toString();
