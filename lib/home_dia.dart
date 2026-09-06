import 'package:flutter/material.dart';

import 'ajustes.dart';
import 'captura_comida.dart';
import 'catalogo.dart';
import 'diario.dart';
import 'motion.dart';

class HomeDia extends StatefulWidget {
  const HomeDia({super.key, required this.diario});

  final Diario diario;

  @override
  State<HomeDia> createState() => _HomeDiaState();
}

class _HomeDiaState extends State<HomeDia> {
  late DateTime _fecha;

  @override
  void initState() {
    super.initState();
    _fecha = widget.diario.hoy().fecha;
  }

  bool get _esHoy {
    final hoy = widget.diario.hoy().fecha;
    return _fecha == hoy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dia = widget.diario.dia(_fecha);
    final meta = widget.diario.meta;
    final consumidos = dia.macros;
    final objetivo = meta.macros;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esHoy ? 'Hoy' : _diaDeSemana(dia.fecha)),
        leading: IconButton(
          tooltip: 'Día anterior',
          onPressed: _diaAnterior,
          icon: const Icon(Icons.chevron_left),
        ),
        actions: [
          IconButton(
            tooltip: 'Día siguiente',
            onPressed: _diaSiguiente,
            icon: const Icon(Icons.chevron_right),
          ),
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
            key: ValueKey('${dia.fecha}-kcal'),
            etiqueta: 'Calorías',
            unidad: 'kcal',
            consumido: consumidos.kcal,
            objetivo: objetivo.kcal,
          ),
          _MacroContraMeta(
            key: ValueKey('${dia.fecha}-proteina'),
            etiqueta: 'Proteína (P)',
            unidad: 'g',
            consumido: consumidos.proteina,
            objetivo: objetivo.proteina,
          ),
          _MacroContraMeta(
            key: ValueKey('${dia.fecha}-carbos'),
            etiqueta: 'Carbos (C)',
            unidad: 'g',
            consumido: consumidos.carbos,
            objetivo: objetivo.carbos,
          ),
          _MacroContraMeta(
            key: ValueKey('${dia.fecha}-grasa'),
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
        builder: (_) => CapturaComida(diario: widget.diario, fecha: _fecha),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _diaAnterior() {
    setState(() {
      _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day - 1);
    });
  }

  void _diaSiguiente() {
    setState(() {
      _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day + 1);
    });
  }

  Future<void> _abrirRenglon(Comida comida, int indice) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _EditarRenglon(
          diario: widget.diario,
          comidaId: comida.id,
          indice: indice,
          renglon: comida.renglones[indice],
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _menuComida(Comida comida, String valor) async {
    if (valor == 'borrar') {
      await widget.diario.eliminarComida(comida.id);
    } else if (valor.startsWith('momento:')) {
      final nombre = valor.substring('momento:'.length);
      await widget.diario.cambiarMomento(
        comida.id,
        Momento.values.byName(nombre),
      );
    }
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
      for (final comida in comidas) ...[
        Row(
          children: [
            Expanded(
              child: Text(momento.etiqueta, style: theme.textTheme.titleMedium),
            ),
            PopupMenuButton<String>(
              onSelected: (valor) => _menuComida(comida, valor),
              itemBuilder: (context) => [
                for (final otro in Momento.values)
                  PopupMenuItem(
                    value: 'momento:${otro.name}',
                    child: Text(otro.etiqueta),
                  ),
                const PopupMenuItem(
                  value: 'borrar',
                  child: Text('Borrar Comida'),
                ),
              ],
            ),
          ],
        ),
        for (var i = 0; i < comida.renglones.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(comida.renglones[i].nombre),
            trailing: Text(
              '${comida.renglones[i].cantidad} g',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            onTap: () => _abrirRenglon(comida, i),
          ),
      ],
    ];
  }
}

class _MacroContraMeta extends StatelessWidget {
  const _MacroContraMeta({
    super.key,
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

    final duration = duracionMotionDe(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: consumido.toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, valor, child) {
          final progreso = objetivo <= 0
              ? 0.0
              : (valor / objetivo).clamp(0.0, 1.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(etiqueta, style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    '${_entero(valor)} / ${_entero(objetivo)} $unidad',
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
          );
        },
      ),
    );
  }
}

String _diaDeSemana(DateTime fecha) {
  const dias = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  return dias[fecha.weekday - 1];
}

String _fechaEnEspanol(DateTime fecha) {
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
  return '${_diaDeSemana(fecha)} ${fecha.day} de ${meses[fecha.month - 1]}';
}

String _entero(num valor) => valor.round().toString();

class _EditarRenglon extends StatefulWidget {
  const _EditarRenglon({
    required this.diario,
    required this.comidaId,
    required this.indice,
    required this.renglon,
  });

  final Diario diario;
  final String comidaId;
  final int indice;
  final Renglon renglon;

  @override
  State<_EditarRenglon> createState() => _EditarRenglonState();
}

class _EditarRenglonState extends State<_EditarRenglon> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidad;
  late String? _alimentoId;
  var _guardando = false;

  @override
  void initState() {
    super.initState();
    _cantidad = TextEditingController(
      text: _textoCantidad(widget.renglon.cantidad ?? 0),
    );
    _alimentoId = widget.renglon.alimentoId;
  }

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alimentos = widget.diario.alimentos;
    return Scaffold(
      appBar: AppBar(title: Text(widget.renglon.nombre)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            TextFormField(
              controller: _cantidad,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                suffixText: 'g',
              ),
              validator: (valor) {
                final numero = _parsearCantidad(valor ?? '');
                if (numero == null || numero <= 0) {
                  return 'Indicá gramos mayores a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _alimentoId,
              decoration: const InputDecoration(labelText: 'Alimento'),
              items: [
                for (final alimento in alimentos)
                  DropdownMenuItem(
                    value: alimento.id,
                    child: Text(alimento.nombre),
                  ),
              ],
              onChanged: (valor) => setState(() => _alimentoId = valor),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: const Text('Guardar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _guardando ? null : _borrar,
              child: const Text('Borrar Renglón'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _guardando = true);
    try {
      await widget.diario.editarRenglon(
        comidaId: widget.comidaId,
        indice: widget.indice,
        cantidad: _parsearCantidad(_cantidad.text),
        alimentoId: _alimentoId,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _borrar() async {
    setState(() => _guardando = true);
    try {
      await widget.diario.eliminarRenglon(
        comidaId: widget.comidaId,
        indice: widget.indice,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }
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
