import 'dart:math' as math;

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
  final _momentosCerrados = <Momento>{};
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
                const SizedBox(height: 16),
                AnilloKcal(
                  key: ValueKey('${dia.fecha}-kcal'),
                  consumido: consumidos.kcal,
                  objetivo: objetivo.kcal,
                ),
                _lineaSeparadora(
                  theme,
                  key: const Key('separador-anillo-barras'),
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
                if (dia.comidas.isNotEmpty)
                  _lineaSeparadora(
                    theme,
                    key: const Key('separador-meta-momentos'),
                    height: 24,
                  ),
                for (var i = 0; i < Momento.values.length; i++)
                  ..._bloqueMomento(
                    theme,
                    dia,
                    Momento.values[i],
                    separarArriba: _hayMomentoOcupadoAntes(dia, i),
                  ),
              ],
            )
          : _CalendarioMes(
              mes: _mesMostrado,
              fechaSeleccionada: _fecha,
              cumplimientoDe: widget.diario.cumplimientoDe,
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
      setState(_podarPliegues);
    }
  }

  Future<void> _abrirCatalogo() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CatalogoPagina(diario: widget.diario),
      ),
    );
    if (mounted) {
      setState(_podarPliegues);
    }
  }

  Future<void> _abrirCaptura() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CapturaComida(diario: widget.diario, fecha: _fecha),
      ),
    );
    if (mounted) {
      setState(_podarPliegues);
    }
  }

  void _diaAnterior() {
    setState(() {
      _alCambiarFecha();
      _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day - 1);
    });
  }

  void _diaSiguiente() {
    setState(() {
      _alCambiarFecha();
      _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day + 1);
    });
  }

  void _abrirFecha(DateTime fecha) {
    setState(() {
      _alCambiarFecha();
      _fecha = DateTime(fecha.year, fecha.month, fecha.day);
      _mesMostrado = DateTime(fecha.year, fecha.month);
      _destino = _Destino.dia;
    });
  }

  void _alCambiarFecha() {
    _renglonAbierto = null;
    _momentosCerrados.clear();
  }

  void _podarPliegues() {
    final ocupados = {
      for (final comida in widget.diario.dia(_fecha).comidas) comida.momento,
    };
    _momentosCerrados.removeWhere((momento) => !ocupados.contains(momento));
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

  void _alternarMomento(Momento momento) {
    setState(() {
      if (!_momentosCerrados.remove(momento)) {
        _momentosCerrados.add(momento);
      }
    });
  }

  num _kcalDe(Comida comida) {
    var total = 0.0;
    for (final renglon in comida.renglones) {
      total += widget.diario.macrosDe(renglon).kcal;
    }
    return total;
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
      setState(_podarPliegues);
    }
  }

  bool _hayMomentoOcupadoAntes(Dia dia, int indice) {
    for (var i = 0; i < indice; i++) {
      for (final comida in dia.comidas) {
        if (comida.momento == Momento.values[i]) {
          return true;
        }
      }
    }
    return false;
  }

  List<Widget> _bloqueMomento(
    ThemeData theme,
    Dia dia,
    Momento momento, {
    required bool separarArriba,
  }) {
    final comidas = [
      for (final comida in dia.comidas)
        if (comida.momento == momento) comida,
    ];
    if (comidas.isEmpty) {
      return const [];
    }
    final cerrado = _momentosCerrados.contains(momento);
    return [
      if (separarArriba)
        _lineaSeparadora(
          theme,
          key: Key('separador-momentos-${momento.name}'),
        )
      else
        const SizedBox(height: 4),
      Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(19, 2, 19, 4),
            child: Column(
              children: [
                for (final comida in comidas) ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _alternarMomento(momento),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                AnimatedRotation(
                                  turns: cerrado ? -0.25 : 0,
                                  duration: duracionMotionDe(context),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    Icons.expand_more,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    momento.etiqueta,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  '${_textoNumero(_kcalDe(comida))} kcal',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                  EntradaAlDesplegar(
                    cerrado: cerrado,
                    child: Column(
                      children: [
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        for (var i = 0; i < comida.renglones.length; i++) ...[
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            title: Text(comida.renglones[i].nombre),
                            trailing: Text(
                              '${comida.renglones[i].cantidad} g',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            onTap: () => _alternarRenglon(comida, i),
                          ),
                          if (_renglonAbierto == '${comida.id}:$i')
                            entradaRenglon(
                              context,
                              _MacrosDeRenglon(
                                macros: widget.diario.macrosDe(
                                  comida.renglones[i],
                                ),
                              ),
                              key: ValueKey('macros-${comida.id}-$i'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }
}

class AnilloKcal extends StatelessWidget {
  const AnilloKcal({
    super.key,
    required this.consumido,
    required this.objetivo,
  });

  final num consumido;
  final num objetivo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = duracionMotionDe(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: consumido.toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, valor, child) {
          final progreso = objetivo <= 0 ? 0.0 : valor / objetivo;
          return Center(
            child: CustomPaint(
              painter: PintorAnilloKcal(
                progreso: progreso,
                color: theme.colorScheme.primary,
                fondo: theme.colorScheme.secondaryContainer,
                exceso: theme.colorScheme.tertiary,
              ),
              child: SizedBox(
                width: 210,
                height: 210,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FittedBox(
                      child: Text(
                        '${_entero(valor)} / ${_entero(objetivo)} kcal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PintorAnilloKcal extends CustomPainter {
  const PintorAnilloKcal({
    required this.progreso,
    required this.color,
    required this.fondo,
    required this.exceso,
  });

  final double progreso;
  final Color color;
  final Color fondo;
  final Color exceso;

  static const _trazo = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (math.min(size.width, size.height) - _trazo) / 2;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    const inicio = -math.pi / 2;

    final pista = Paint()
      ..color = fondo
      ..style = PaintingStyle.stroke
      ..strokeWidth = _trazo;
    canvas.drawCircle(centro, radio, pista);

    final lleno = progreso.clamp(0.0, 1.0);
    if (lleno > 0) {
      final activo = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _trazo
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, inicio, lleno * 2 * math.pi, false, activo);
    }

    if (progreso > 1) {
      final extra = (progreso - 1).clamp(0.0, 1.0);
      final desborde = Paint()
        ..color = exceso
        ..style = PaintingStyle.stroke
        ..strokeWidth = _trazo
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, inicio, extra * 2 * math.pi, false, desborde);
    }
  }

  @override
  bool shouldRepaint(PintorAnilloKcal oldDelegate) {
    return oldDelegate.progreso != progreso ||
        oldDelegate.color != color ||
        oldDelegate.fondo != fondo ||
        oldDelegate.exceso != exceso;
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
      padding: const EdgeInsets.only(bottom: 4),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: consumido.toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, valor, child) {
          final progreso = objetivo <= 0
              ? 0.0
              : (valor / objetivo).clamp(0.0, 1.0);
          return Row(
            children: [
              SizedBox(
                width: 108,
                child: Text(etiqueta, style: theme.textTheme.bodyMedium),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progreso.toDouble(),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_entero(valor)} / ${_entero(objetivo)} $unidad',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
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

String _etiquetaCumplimiento(DateTime fecha, Cumplimiento cumplimiento) {
  final dia = _etiquetaDia(fecha);
  return switch (cumplimiento) {
    Cumplimiento.ninguno => dia,
    Cumplimiento.rojo => '$dia, rojo',
    Cumplimiento.amarillo => '$dia, amarillo',
    Cumplimiento.verde => '$dia, verde',
  };
}

String _fechaEnEspanol(DateTime fecha) {
  return '${_diaDeSemana(fecha)} ${fecha.day} de ${_nombreMes(fecha)}';
}

class _CalendarioMes extends StatelessWidget {
  const _CalendarioMes({
    required this.mes,
    required this.fechaSeleccionada,
    required this.cumplimientoDe,
    required this.onElegirDia,
    required this.onMesAnterior,
    required this.onMesSiguiente,
  });

  final DateTime mes;
  final DateTime fechaSeleccionada;
  final Cumplimiento Function(DateTime fecha) cumplimientoDe;
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
                const SizedBox(height: 2),
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
    final cumplimiento = cumplimientoDe(fecha);
    final fondo = _fondoCumplimiento(theme.colorScheme, cumplimiento);
    final sobre = _colorTextoCumplimiento(theme.colorScheme, cumplimiento);
    return Semantics(
      button: true,
      label: _etiquetaCumplimiento(fecha, cumplimiento),
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onElegirDia(fecha),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fondo ?? Colors.transparent,
              border: seleccionado
                  ? Border.all(color: theme.colorScheme.onSurface, width: 2)
                  : null,
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
                    color: sobre ?? theme.colorScheme.onSurface,
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

Color? _fondoCumplimiento(ColorScheme scheme, Cumplimiento cumplimiento) {
  return switch (cumplimiento) {
    Cumplimiento.ninguno => null,
    Cumplimiento.rojo => scheme.error,
    Cumplimiento.amarillo => const Color(0xFFE8B923),
    Cumplimiento.verde => scheme.primary,
  };
}

Color? _colorTextoCumplimiento(ColorScheme scheme, Cumplimiento cumplimiento) {
  return switch (cumplimiento) {
    Cumplimiento.ninguno => null,
    Cumplimiento.rojo => scheme.onError,
    Cumplimiento.amarillo => const Color(0xFF1C1B16),
    Cumplimiento.verde => scheme.onPrimary,
  };
}

String _entero(num valor) => valor.round().toString();

Widget _lineaSeparadora(ThemeData theme, {Key? key, double height = 24}) {
  return Divider(
    key: key,
    height: height,
    thickness: 1,
    color: theme.colorScheme.outlineVariant,
  );
}

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
