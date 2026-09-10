import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrimezzo/calendario_mes.dart';

import 'desactivar_animaciones.dart';

void main() {
  testWidgets(
    'un segundo caller pinta el mes con celdas que no son Cumplimiento',
    (tester) async {
      desactivarAnimaciones(tester);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _MesConKg())),
      );

      expect(find.text('septiembre 2026'), findsOneWidget);
      expect(find.byTooltip('Mes anterior'), findsOneWidget);
      expect(find.byTooltip('Mes siguiente'), findsOneWidget);
      expect(find.text('lun'), findsOneWidget);
      expect(find.text('dom'), findsOneWidget);
      expect(find.text('72.4'), findsOneWidget);
      expect(find.bySemanticsLabel('5 de septiembre, 72.4 kg'), findsOneWidget);
      expect(find.bySemanticsLabel('6 de septiembre'), findsOneWidget);
      expect(find.bySemanticsLabel('5 de septiembre, rojo'), findsNothing);
      expect(find.bySemanticsLabel('5 de septiembre, amarillo'), findsNothing);
      expect(find.bySemanticsLabel('5 de septiembre, verde'), findsNothing);
    },
  );

  testWidgets('la semana del mes compartido empieza en lunes', (tester) async {
    desactivarAnimaciones(tester);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _MesConKg())),
    );

    final lun = tester.getCenter(find.text('lun'));
    final mar = tester.getCenter(find.text('mar'));
    expect(lun.dx, lessThan(mar.dx));

    final uno = tester.getCenter(find.bySemanticsLabel('1 de septiembre'));
    expect((uno.dx - mar.dx).abs(), lessThan((uno.dx - lun.dx).abs()));
  });

  testWidgets('tocar un día en el mes compartido no abre Día', (tester) async {
    desactivarAnimaciones(tester);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _MesConKg())),
    );

    expect(find.text('día: 6 de septiembre'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('8 de septiembre'));
    await tester.pump();

    expect(find.text('día: 8 de septiembre'), findsOneWidget);
    expect(find.text('día: 6 de septiembre'), findsNothing);
    expect(find.text('Comida'), findsNothing);
    expect(find.text('72.4'), findsOneWidget);
  });

  testWidgets(
    'cambiar de mes en el mes compartido no cambia el día hasta tocarlo',
    (tester) async {
      desactivarAnimaciones(tester);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _MesConKg())),
      );

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pump();

      expect(find.text('agosto 2026'), findsOneWidget);
      expect(find.text('septiembre 2026'), findsNothing);
      expect(find.text('día: 6 de septiembre'), findsOneWidget);
      expect(find.bySemanticsLabel('6 de septiembre'), findsNothing);

      await tester.tap(find.bySemanticsLabel('15 de agosto'));
      await tester.pump();

      expect(find.text('día: 15 de agosto'), findsOneWidget);
      expect(find.text('día: 6 de septiembre'), findsNothing);
      expect(find.text('agosto 2026'), findsOneWidget);
      expect(find.text('Comida'), findsNothing);
    },
  );
}

class _MesConKg extends StatefulWidget {
  const _MesConKg();

  @override
  State<_MesConKg> createState() => _MesConKgState();
}

class _MesConKgState extends State<_MesConKg> {
  var _mes = DateTime(2026, 9);
  var _seleccionado = DateTime(2026, 9, 6);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('día: ${_etiqueta(_seleccionado)}'),
        Expanded(
          child: CalendarioMes(
            mes: _mes,
            fechaSeleccionada: _seleccionado,
            etiquetaDe: _etiqueta,
            celdaDe: _celda,
            onElegirDia: (fecha) {
              setState(() => _seleccionado = fecha);
            },
            onMesAnterior: () {
              setState(() {
                _mes = DateTime(_mes.year, _mes.month - 1);
              });
            },
            onMesSiguiente: () {
              setState(() {
                _mes = DateTime(_mes.year, _mes.month + 1);
              });
            },
          ),
        ),
      ],
    );
  }

  String _etiqueta(DateTime fecha) {
    final dia = '${fecha.day} de ${_meses[fecha.month - 1]}';
    if (fecha.year == 2026 && fecha.month == 9 && fecha.day == 5) {
      return '$dia, 72.4 kg';
    }
    return dia;
  }

  Widget _celda(BuildContext context, DateTime fecha) {
    if (fecha.year == 2026 && fecha.month == 9 && fecha.day == 5) {
      return const Text('72.4');
    }
    return const SizedBox.shrink();
  }
}

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
