import 'package:flutter/material.dart';

import 'motion.dart';
import 'tema.dart';

/// A month of Días, Monday first, shared by Cumplimiento and Pesaje.
///
/// The caller paints each cell ([celdaDe]) and decides what a tap means
/// ([onElegirDia]). Changing [mes] slides the title and the grid along the
/// horizontal axis, backwards when going to an earlier month. It does not
/// scroll or pad itself: put it in a card / scroll view.
class CalendarioMes extends StatefulWidget {
  const CalendarioMes({
    super.key,
    required this.mes,
    required this.fechaSeleccionada,
    required this.etiquetaDe,
    required this.celdaDe,
    required this.onElegirDia,
    required this.onMesAnterior,
    required this.onMesSiguiente,
    this.resaltarSemana = false,
    this.celdaCuadrada = false,
  });

  final DateTime mes;
  final DateTime fechaSeleccionada;
  final String Function(DateTime fecha) etiquetaDe;
  final Widget Function(BuildContext context, DateTime fecha) celdaDe;
  final ValueChanged<DateTime> onElegirDia;
  final VoidCallback onMesAnterior;
  final VoidCallback onMesSiguiente;

  /// Draw the Semana of [fechaSeleccionada] as a `primary` 8% band.
  final bool resaltarSemana;

  /// Square tiles (Pesaje) instead of circles (Cumplimiento).
  final bool celdaCuadrada;

  @override
  State<CalendarioMes> createState() => _CalendarioMesState();
}

class _CalendarioMesState extends State<CalendarioMes> {
  var _haciaAtras = false;

  @override
  void didUpdateWidget(CalendarioMes oldWidget) {
    super.didUpdateWidget(oldWidget);
    final antes = DateTime(oldWidget.mes.year, oldWidget.mes.month);
    final ahora = DateTime(widget.mes.year, widget.mes.month);
    if (antes != ahora) {
      _haciaAtras = ahora.isBefore(antes);
    }
  }

  double get _altoFila => widget.celdaCuadrada ? 48 : 52;

  double get _lado => widget.celdaCuadrada ? 40 : 42;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mes = widget.mes;
    final claveMes = ValueKey(DateTime(mes.year, mes.month));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _BotonMes(
              tooltip: 'Mes anterior',
              icono: IconosNutri.anterior,
              onPressed: widget.onMesAnterior,
            ),
            Expanded(
              child: ConmutadorEjeHorizontal(
                haciaAtras: _haciaAtras,
                child: Text.rich(
                  key: claveMes,
                  TextSpan(
                    children: [
                      TextSpan(
                        text: nombreMes(mes),
                        style: theme.textTheme.headlineSmall,
                      ),
                      TextSpan(
                        text: ' ${mes.year}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            _BotonMes(
              tooltip: 'Mes siguiente',
              icono: IconosNutri.siguiente,
              onPressed: widget.onMesSiguiente,
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
        const SizedBox(height: 6),
        ConmutadorEjeHorizontal(
          haciaAtras: _haciaAtras,
          child: KeyedSubtree(key: claveMes, child: _grilla(context)),
        ),
      ],
    );
  }

  Widget _grilla(BuildContext context) {
    final mes = widget.mes;
    final primer = DateTime(mes.year, mes.month, 1);
    final diasDelMes = DateTime(mes.year, mes.month + 1, 0).day;
    final huecos = primer.weekday - DateTime.monday;
    final fechas = <DateTime?>[
      for (var i = 0; i < huecos; i++) null,
      for (var dia = 1; dia <= diasDelMes; dia++)
        DateTime(mes.year, mes.month, dia),
    ];
    while (fechas.length % 7 != 0) {
      fechas.add(null);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < fechas.length; i += 7)
          _filaSemana(context, fechas.sublist(i, i + 7)),
      ],
    );
  }

  Widget _filaSemana(BuildContext context, List<DateTime?> semana) {
    final theme = Theme.of(context);
    final resaltada =
        widget.resaltarSemana &&
        semana.any(
          (fecha) =>
              fecha != null && _mismaSemana(fecha, widget.fechaSeleccionada),
        );
    final fila = Row(
      children: [
        for (final fecha in semana)
          Expanded(
            child: fecha == null
                ? const SizedBox.shrink()
                : _celda(context, fecha),
          ),
      ],
    );
    if (!resaltada) {
      return SizedBox(height: _altoFila, child: fila);
    }
    return SizedBox(
      height: _altoFila,
      child: DecoratedBox(
        key: const Key('semana-seleccionada'),
        decoration: ShapeDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          shape: const StadiumBorder(),
        ),
        child: fila,
      ),
    );
  }

  Widget _celda(BuildContext context, DateTime fecha) {
    final theme = Theme.of(context);
    final seleccionado = _mismoDia(fecha, widget.fechaSeleccionada);
    final cuadrada = widget.celdaCuadrada;
    final forma = cuadrada
        ? RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(12))
        : const CircleBorder();
    final borde = BorderSide(color: theme.colorScheme.onSurface, width: 2);

    Widget celda = SizedBox.square(
      dimension: _lado,
      child: widget.celdaDe(context, fecha),
    );
    if (seleccionado) {
      celda = cuadrada
          // Square: the 2 px border sits on the tile itself.
          ? DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: borde,
                ),
              ),
              child: celda,
            )
          // Circle: a 2 px ring with a 2 px gap around the cell.
          : Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                celda,
                Positioned(
                  left: -4,
                  top: -4,
                  right: -4,
                  bottom: -4,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: CircleBorder(side: borde),
                      ),
                    ),
                  ),
                ),
              ],
            );
    }

    return Semantics(
      button: true,
      selected: seleccionado,
      label: widget.etiquetaDe(fecha),
      excludeSemantics: true,
      child: Center(
        child: InkWell(
          customBorder: forma,
          onTap: () {
            hapticoSeleccion();
            widget.onElegirDia(fecha);
          },
          child: celda,
        ),
      ),
    );
  }
}

class _BotonMes extends StatelessWidget {
  const _BotonMes({
    required this.tooltip,
    required this.icono,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icono;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: esquema.secondaryContainer,
        foregroundColor: esquema.onSecondaryContainer,
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
      ),
      icon: Icon(icono, size: 20),
    );
  }
}

String nombreMes(DateTime fecha) => _meses[fecha.month - 1];

bool _mismoDia(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _mismaSemana(DateTime a, DateTime b) {
  return _lunesDe(a) == _lunesDe(b);
}

DateTime _lunesDe(DateTime fecha) {
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  return dia.subtract(Duration(days: fecha.weekday - DateTime.monday));
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
