import 'package:flutter/material.dart';

class CalendarioMes extends StatelessWidget {
  const CalendarioMes({
    super.key,
    required this.mes,
    required this.fechaSeleccionada,
    required this.etiquetaDe,
    required this.celdaDe,
    required this.onElegirDia,
    required this.onMesAnterior,
    required this.onMesSiguiente,
  });

  final DateTime mes;
  final DateTime fechaSeleccionada;
  final String Function(DateTime fecha) etiquetaDe;
  final Widget Function(BuildContext context, DateTime fecha) celdaDe;
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
        _celda(context, DateTime(mes.year, mes.month, dia)),
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
                        '${nombreMes(mes)} ${mes.year}',
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

  Widget _celda(BuildContext context, DateTime fecha) {
    final theme = Theme.of(context);
    final seleccionado =
        fecha.year == fechaSeleccionada.year &&
        fecha.month == fechaSeleccionada.month &&
        fecha.day == fechaSeleccionada.day;
    return Semantics(
      button: true,
      label: etiquetaDe(fecha),
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onElegirDia(fecha),
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            foregroundDecoration: seleccionado
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.onSurface,
                      width: 2,
                    ),
                  )
                : null,
            child: celdaDe(context, fecha),
          ),
        ),
      ),
    );
  }
}

String nombreMes(DateTime fecha) => _meses[fecha.month - 1];

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
