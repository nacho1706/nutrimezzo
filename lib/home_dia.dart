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

enum _Destino { dia, cumplimiento }

class _HomeDiaState extends State<HomeDia> {
  late DateTime _fecha;
  late DateTime _mesMostrado;
  String? _renglonAbierto;
  var _destino = _Destino.dia;

  @override
  void initState() {
    super.initState();
    _fecha = widget.diario.hoy().fecha;
    _mesMostrado = DateTime(_fecha.year, _fecha.month);
  }

  bool get _esHoy {
    final hoy = widget.diario.hoy().fecha;
    return _fecha == hoy;
  }

  bool get _enDia => _destino == _Destino.dia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dia = widget.diario.dia(_fecha);
    final meta = widget.diario.meta;
    final consumidos = dia.macros;
    final objetivo = meta.macros;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _enDia ? (_esHoy ? 'Hoy' : _diaDeSemana(dia.fecha)) : 'Cumplimiento',
        ),
        leading: _enDia
            ? IconButton(
                tooltip: 'Día anterior',
                onPressed: _diaAnterior,
                icon: const Icon(Icons.chevron_left),
              )
            : null,
        actions: [
          if (_enDia)
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
      floatingActionButton: _enDia
          ? FloatingActionButton.extended(
              onPressed: _abrirCaptura,
              icon: const Icon(Icons.edit_note),
              label: const Text('Comida'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _destino.index,
        onDestinationSelected: (indice) {
          setState(() {
            _destino = _Destino.values[indice];
            if (_destino == _Destino.cumplimiento) {
              _mesMostrado = DateTime(_fecha.year, _fecha.month);
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Día',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Cumplimiento',
          ),
        ],
      ),
      body: _enDia
          ? ListView(
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
            )
          : _CalendarioMes(
              mes: _mesMostrado,
              fechaSeleccionada: _fecha,
              onElegirDia: _abrirFecha,
              onMesAnterior: _mesAnterior,
              onMesSiguiente: _mesSiguiente,
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
      _renglonAbierto = null;
      _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day - 1);
    });
  }

  void _diaSiguiente() {
    setState(() {
      _renglonAbierto = null;
      _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day + 1);
    });
  }

  void _abrirFecha(DateTime fecha) {
    setState(() {
      _renglonAbierto = null;
      _fecha = DateTime(fecha.year, fecha.month, fecha.day);
      _mesMostrado = DateTime(fecha.year, fecha.month);
      _destino = _Destino.dia;
    });
  }

  void _mesAnterior() {
    setState(() {
      _mesMostrado = DateTime(_mesMostrado.year, _mesMostrado.month - 1);
    });
  }

  void _mesSiguiente() {
    setState(() {
      _mesMostrado = DateTime(_mesMostrado.year, _mesMostrado.month + 1);
    });
  }

  void _alternarRenglon(Comida comida, int indice) {
    setState(() {
      final clave = '${comida.id}:$indice';
      _renglonAbierto = _renglonAbierto == clave ? null : clave;
    });
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
        for (var i = 0; i < comida.renglones.length; i++) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(comida.renglones[i].nombre),
            trailing: Text(
              '${comida.renglones[i].cantidad} g',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            onTap: () => _alternarRenglon(comida, i),
          ),
          if (_renglonAbierto == '${comida.id}:$i')
            entradaRenglon(
              context,
              _MacrosDeRenglon(
                macros: widget.diario.macrosDe(comida.renglones[i]),
              ),
              key: ValueKey('macros-${comida.id}-$i'),
            ),
        ],
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

const _diasCortos = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

const _meses = [
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

String _nombreMes(DateTime fecha) => _meses[fecha.month - 1];

String _etiquetaDia(DateTime fecha) => '${fecha.day} de ${_nombreMes(fecha)}';

String _fechaEnEspanol(DateTime fecha) {
  return '${_diaDeSemana(fecha)} ${fecha.day} de ${_nombreMes(fecha)}';
}

class _CalendarioMes extends StatelessWidget {
  const _CalendarioMes({
    required this.mes,
    required this.fechaSeleccionada,
    required this.onElegirDia,
    required this.onMesAnterior,
    required this.onMesSiguiente,
  });

  final DateTime mes;
  final DateTime fechaSeleccionada;
  final ValueChanged<DateTime> onElegirDia;
  final VoidCallback onMesAnterior;
  final VoidCallback onMesSiguiente;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primer = DateTime(mes.year, mes.month, 1);
    final diasDelMes = DateTime(mes.year, mes.month + 1, 0).day;
    final huecos = primer.weekday - DateTime.monday;
    final celdas = <Widget>[
      for (var i = 0; i < huecos; i++) const SizedBox.shrink(),
      for (var dia = 1; dia <= diasDelMes; dia++)
        _celdaDia(theme, DateTime(mes.year, mes.month, dia)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Mes anterior',
                      onPressed: onMesAnterior,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${_nombreMes(mes)} ${mes.year}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mes siguiente',
                      onPressed: onMesSiguiente,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final nombre in _diasCortos)
                      Expanded(
                        child: Center(
                          child: Text(
                            nombre,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  childAspectRatio: (constraints.maxWidth / 7) / 48,
                  children: celdas,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _celdaDia(ThemeData theme, DateTime fecha) {
    final seleccionado =
        fecha.year == fechaSeleccionada.year &&
        fecha.month == fechaSeleccionada.month &&
        fecha.day == fechaSeleccionada.day;
    return Semantics(
      button: true,
      label: _etiquetaDia(fecha),
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onElegirDia(fecha),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: seleccionado
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Center(
                child: Text(
                  '${fecha.day}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: seleccionado
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: seleccionado
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _entero(num valor) => valor.round().toString();

class _MacrosDeRenglon extends StatelessWidget {
  const _MacrosDeRenglon({required this.macros});

  final Macros macros;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          _lineaMacro(theme, 'Calorías', '${_textoNumero(macros.kcal)} kcal'),
          _lineaMacro(
            theme,
            'Proteína (P)',
            '${_textoNumero(macros.proteina)} g',
          ),
          _lineaMacro(theme, 'Carbos (C)', '${_textoNumero(macros.carbos)} g'),
          _lineaMacro(theme, 'Grasa (F)', '${_textoNumero(macros.grasa)} g'),
        ],
      ),
    );
  }
}

Widget _lineaMacro(ThemeData theme, String etiqueta, String valor) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(child: Text(etiqueta, style: theme.textTheme.bodyMedium)),
        Text(
          valor,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

String _textoNumero(num valor) {
  if (valor == valor.roundToDouble()) {
    return valor.round().toString();
  }
  return valor.toString();
}
