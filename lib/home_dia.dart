import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'ajustes.dart';
import 'anillo_kcal.dart';
import 'calendario_mes.dart';
import 'captura_comida.dart';
import 'catalogo.dart';
import 'diario.dart';
import 'motion.dart';
import 'tema.dart';

export 'anillo_kcal.dart' show AnilloKcal, PintorAnilloKcal;

class HomeDia extends StatefulWidget {
  const HomeDia({super.key, required this.diario});

  final Diario diario;

  @override
  State<HomeDia> createState() => _HomeDiaState();
}

enum _Destino { dia, cumplimiento, pesaje }

class _HomeDiaState extends State<HomeDia> {
  late DateTime _fecha;
  late DateTime _mesMostrado;
  String? _renglonAbierto;
  final _momentosCerrados = <Momento>{};
  var _destino = _Destino.dia;
  final _kilogramos = TextEditingController();

  /// Direction of the last Día change (chevrons), for the horizontal slide.
  var _haciaAtras = false;

  /// Verde acknowledgement bookkeeping: the Cumplimiento last shown for
  /// [_fechaJuzgada]. Only a same-fecha change to verde bumps [_acuseVerde].
  DateTime? _fechaJuzgada;
  Cumplimiento? _juicio;
  var _acuseVerde = 0;
  var _demorarAcuse = false;

  @override
  void initState() {
    super.initState();
    _fecha = widget.diario.hoy().fecha;
    _mesMostrado = DateTime(_fecha.year, _fecha.month);
  }

  @override
  void dispose() {
    _kilogramos.dispose();
    super.dispose();
  }

  bool get _esHoy {
    final hoy = widget.diario.hoy().fecha;
    return _fecha == hoy;
  }

  bool get _enDia => _destino == _Destino.dia;

  /// Bumps [_acuseVerde] when the shown Día turned verde since the last build
  /// of the same fecha. First paint, a date change, or coming back to Día
  /// from another destination only record the current Cumplimiento.
  void _juzgarVerde() {
    if (!_enDia) {
      _fechaJuzgada = null;
      _juicio = null;
      _demorarAcuse = false;
      return;
    }
    final actual = widget.diario.cumplimientoDe(_fecha);
    if (_fechaJuzgada == _fecha &&
        _juicio != null &&
        _juicio != Cumplimiento.verde &&
        actual == Cumplimiento.verde) {
      _acuseVerde++;
    }
    _fechaJuzgada = _fecha;
    _juicio = actual;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acuseAntes = _acuseVerde;
    _juzgarVerde();
    final demoraAcuse = _acuseVerde != acuseAntes && _demorarAcuse
        ? duracion(context, MotionNutri.largo)
        : Duration.zero;
    _demorarAcuse = false;

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_destino) {
          _Destino.dia => _esHoy ? 'Hoy' : _diaDeSemana(_fecha),
          _Destino.cumplimiento => 'Cumplimiento',
          _Destino.pesaje => 'Pesaje',
        }),
        leading: _enDia
            ? IconButton(
                tooltip: 'Día anterior',
                onPressed: _diaAnterior,
                icon: const Icon(IconosNutri.anterior),
              )
            : null,
        actions: [
          if (_enDia)
            IconButton(
              tooltip: 'Día siguiente',
              onPressed: _diaSiguiente,
              icon: const Icon(IconosNutri.siguiente),
            ),
          IconButton(
            tooltip: 'Catálogo',
            onPressed: _abrirCatalogo,
            icon: const Icon(IconosNutri.catalogo),
          ),
          IconButton(
            tooltip: 'Ajustes',
            onPressed: _abrirAjustes,
            icon: const Icon(IconosNutri.ajustes),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _enDia ? _botonComida(theme) : null,
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: Border(top: hiloTarjeta(context))),
        child: NavigationBar(
          selectedIndex: _destino.index,
          onDestinationSelected: _irA,
          destinations: const [
            NavigationDestination(
              icon: Icon(IconosNutri.dia),
              selectedIcon: Icon(IconosNutri.diaSeleccionado),
              label: 'Día',
            ),
            NavigationDestination(
              icon: Icon(IconosNutri.cumplimiento),
              selectedIcon: Icon(IconosNutri.cumplimientoSeleccionado),
              label: 'Cumplimiento',
            ),
            NavigationDestination(
              icon: Icon(IconosNutri.pesaje),
              selectedIcon: Icon(IconosNutri.pesajeSeleccionado),
              label: 'Pesaje',
            ),
          ],
        ),
      ),
      body: ConmutadorFadeThrough(
        child: SizedBox.expand(
          key: ValueKey(_destino),
          child: switch (_destino) {
            _Destino.dia => _cuerpoDia(theme, demoraAcuse),
            _Destino.cumplimiento => _cuerpoCumplimiento(theme),
            _Destino.pesaje => _cuerpoPesaje(theme),
          },
        ),
      ),
    );
  }

  void _irA(int indice) {
    final destino = _Destino.values[indice];
    if (destino == _destino) {
      return;
    }
    hapticoSeleccion();
    setState(() {
      _destino = destino;
      if (_destino == _Destino.cumplimiento || _destino == _Destino.pesaje) {
        _mesMostrado = DateTime(_fecha.year, _fecha.month);
      }
      if (_destino == _Destino.pesaje) {
        _cargarKilogramos();
      }
    });
  }

  // -------------------------------------------------------------------------
  // Comida FAB → Captura (container transform)
  // -------------------------------------------------------------------------

  Widget _botonComida(ThemeData theme) {
    final esquema = theme.colorScheme;
    final claro = theme.brightness == Brightness.light;
    // Soft ink shadow as a BoxShadow (no Material elevation: the doc's
    // depth rule, and tests paint elevation as a hard outline).
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        shadows: claro
            ? [
                BoxShadow(
                  color: esquema.tertiary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      // OpenContainer never restores its closed child when its transition is
      // Duration.zero, so reduced motion falls back to a plain route push.
      child: duracion(context, MotionNutri.largo) == Duration.zero
          ? Material(
              color: esquema.tertiary,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _abrirCapturaSinTransformar,
                child: _pildoraComida(theme),
              ),
            )
          : OpenContainer<void>(
              transitionDuration: duracion(context, MotionNutri.largo),
              transitionType: ContainerTransitionType.fadeThrough,
              closedShape: const StadiumBorder(),
              closedColor: esquema.tertiary,
              closedElevation: 0,
              openShape: const RoundedRectangleBorder(),
              openColor: esquema.surface,
              middleColor: esquema.surface,
              openElevation: 0,
              onClosed: (_) => _alCerrarCaptura(),
              openBuilder: (context, _) =>
                  CapturaComida(diario: widget.diario, fecha: _fecha),
              closedBuilder: (context, _) => _pildoraComida(theme),
            ),
    );
  }

  Widget _pildoraComida(ThemeData theme) {
    final esquema = theme.colorScheme;
    return Semantics(
      button: true,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 24, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconosNutri.comida, size: 22, color: esquema.onTertiary),
              const SizedBox(width: 10),
              Text(
                'Comida',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  color: esquema.onTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirCapturaSinTransformar() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CapturaComida(diario: widget.diario, fecha: _fecha),
      ),
    );
    _alCerrarCaptura();
  }

  void _alCerrarCaptura() {
    if (mounted) {
      setState(() {
        _demorarAcuse = true;
        _podarPliegues();
      });
    }
  }

  // -------------------------------------------------------------------------
  // Día
  // -------------------------------------------------------------------------

  Widget _cuerpoDia(ThemeData theme, Duration demoraAcuse) {
    final dia = widget.diario.dia(_fecha);
    final meta = widget.diario.meta;
    final consumidos = dia.macros;
    final objetivo = meta.macros;

    return ConmutadorEjeHorizontal(
      haciaAtras: _haciaAtras,
      child: SizedBox.expand(
        key: ValueKey(dia.fecha),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            margenPantalla,
            4,
            margenPantalla,
            112,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_fechaEnEspanol(dia.fecha), style: ceja(context)),
              const SizedBox(height: 12),
              TarjetaNutri(
                radio: radioHeroe,
                brillo: true,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Contra la Meta',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: AnilloKcal(
                        key: ValueKey('${dia.fecha}-kcal'),
                        consumido: consumidos.kcal,
                        objetivo: objetivo.kcal,
                        acuseVerde: _acuseVerde,
                        demoraAcuse: demoraAcuse,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _HiloPunteado(key: Key('separador-anillo-barras')),
                    const SizedBox(height: 18),
                    _MacroContraMeta(
                      key: ValueKey('${dia.fecha}-proteina'),
                      macro: MacroVisual.proteina,
                      etiqueta: 'Proteína (P)',
                      unidad: 'g',
                      consumido: consumidos.proteina,
                      objetivo: objetivo.proteina,
                    ),
                    const SizedBox(height: 16),
                    _MacroContraMeta(
                      key: ValueKey('${dia.fecha}-carbos'),
                      macro: MacroVisual.carbos,
                      etiqueta: 'Carbos (C)',
                      unidad: 'g',
                      consumido: consumidos.carbos,
                      objetivo: objetivo.carbos,
                    ),
                    const SizedBox(height: 16),
                    _MacroContraMeta(
                      key: ValueKey('${dia.fecha}-grasa'),
                      macro: MacroVisual.grasa,
                      etiqueta: 'Grasa (F)',
                      unidad: 'g',
                      consumido: consumidos.grasa,
                      objetivo: objetivo.grasa,
                    ),
                  ],
                ),
              ),
              if (dia.comidas.isNotEmpty)
                const SizedBox(
                  key: Key('separador-meta-momentos'),
                  height: entreSecciones,
                )
              else
                const _DiaVacio(),
              for (var i = 0; i < Momento.values.length; i++)
                ..._bloqueMomento(
                  theme,
                  dia,
                  Momento.values[i],
                  separarArriba: _hayMomentoOcupadoAntes(dia, i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Cumplimiento
  // -------------------------------------------------------------------------

  Widget _cuerpoCumplimiento(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        margenPantalla,
        8,
        margenPantalla,
        entreSecciones,
      ),
      child: TarjetaNutri(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalendarioMes(
              mes: _mesMostrado,
              fechaSeleccionada: _fecha,
              etiquetaDe: (fecha) => _etiquetaCumplimiento(
                fecha,
                widget.diario.cumplimientoDe(fecha),
              ),
              celdaDe: _celdaCumplimiento,
              onElegirDia: _abrirFecha,
              onMesAnterior: _mesAnterior,
              onMesSiguiente: _mesSiguiente,
            ),
            const SizedBox(height: 14),
            const _HiloPunteado(),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: [
                _itemLeyenda(
                  theme,
                  coloresDeCumplimiento(context, Cumplimiento.verde).fondo!,
                  'Dentro de la Meta',
                ),
                _itemLeyenda(
                  theme,
                  coloresDeCumplimiento(context, Cumplimiento.amarillo).fondo!,
                  'Falta proteína',
                ),
                _itemLeyenda(
                  theme,
                  coloresDeCumplimiento(context, Cumplimiento.rojo).fondo!,
                  'Kcal de más',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemLeyenda(ThemeData theme, Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _celdaCumplimiento(BuildContext context, DateTime fecha) {
    final theme = Theme.of(context);
    final colores = coloresDeCumplimiento(
      context,
      widget.diario.cumplimientoDe(fecha),
    );
    final esHoy = fecha == widget.diario.hoy().fecha;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colores.fondo ?? Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${fecha.day}',
            style: theme.textTheme.titleSmall?.copyWith(color: colores.texto),
          ),
          if (esHoy)
            Positioned(
              bottom: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colores.texto,
                ),
                child: const SizedBox.square(dimension: 5),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Pesaje
  // -------------------------------------------------------------------------

  Future<void> _guardarPesaje() async {
    final kilogramos = _parsearKilogramos(_kilogramos.text);
    if (kilogramos == null) {
      return;
    }
    try {
      await widget.diario.guardarPesaje(fecha: _fecha, kilogramos: kilogramos);
    } on ArgumentError {
      return;
    }
    hapticoExito();
    if (mounted) {
      setState(() {});
    }
  }

  void _cargarKilogramos() {
    final pesaje = widget.diario.pesajeDe(_fecha);
    _kilogramos.text = pesaje == null
        ? ''
        : _textoKilogramos(pesaje.kilogramos);
  }

  Widget _cuerpoPesaje(ThemeData theme) {
    final esquema = theme.colorScheme;
    final promedio = widget.diario.promedioDe(_fecha);
    final estiloKg = theme.textTheme.displayMedium;
    final sufijo = theme.textTheme.titleMedium?.copyWith(
      color: esquema.onSurfaceVariant,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        margenPantalla,
        8,
        margenPantalla,
        entreSecciones,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarjetaNutri(
            radio: radioHeroe,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                Text(_fechaEnEspanol(_fecha), style: ceja(context)),
                const SizedBox(height: 6),
                Center(
                  child: SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _kilogramos,
                      textAlign: TextAlign.center,
                      style: estiloKg,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        hintText: '00.0',
                        hintStyle: estiloKg?.copyWith(
                          color: esquema.outlineVariant,
                        ),
                        // Equal-width prefix keeps the number centered.
                        prefixIcon: const SizedBox(width: 32),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                        ),
                        suffixIcon: SizedBox(
                          width: 32,
                          child: Align(
                            alignment: const Alignment(-1, 0.45),
                            child: Text('kg', style: sufijo),
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconosNutri.manana,
                      size: 16,
                      color: esquema.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Mejor en ayunas, a la mañana.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _guardarPesaje,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(180, 48),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TarjetaNutri(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: CalendarioMes(
              mes: _mesMostrado,
              fechaSeleccionada: _fecha,
              etiquetaDe: _etiquetaPesaje,
              celdaDe: _celdaPesaje,
              onElegirDia: _seleccionarEnPesaje,
              onMesAnterior: _mesAnterior,
              onMesSiguiente: _mesSiguiente,
              resaltarSemana: true,
              celdaCuadrada: true,
            ),
          ),
          if (promedio != null) ...[
            const SizedBox(height: 16),
            _cuerpoPromedio(theme, promedio),
          ],
        ],
      ),
    );
  }

  Widget _cuerpoPromedio(ThemeData theme, Promedio promedio) {
    final esquema = theme.colorScheme;
    final kg = _unDecimal(promedio.kilogramos);
    final cuanto = promedio.delta == null
        ? null
        : _unDecimal(promedio.delta!.abs());
    final etiqueta = promedio.bajo
        ? 'Promedio Semanal $kg kg, bajó $cuanto kg'
        : promedio.subio
        ? 'Promedio Semanal $kg kg, subió $cuanto kg'
        : 'Promedio Semanal $kg kg';
    final fondo = promedio.bajo
        ? esquema.primaryContainer
        : esquema.errorContainer;
    final tinta = promedio.bajo
        ? esquema.onPrimaryContainer
        : esquema.onErrorContainer;
    return Semantics(
      label: etiqueta,
      excludeSemantics: true,
      child: TarjetaNutri(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Promedio Semanal', style: ceja(context)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: kg,
                          style: theme.textTheme.headlineMedium,
                        ),
                        TextSpan(
                          text: ' kg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: esquema.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (promedio.bajo || promedio.subio)
              Tooltip(
                message: promedio.bajo ? 'bajó $cuanto kg' : 'subió $cuanto kg',
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: fondo,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          promedio.bajo ? IconosNutri.baja : IconosNutri.sube,
                          size: 16,
                          color: tinta,
                        ),
                        const SizedBox(width: 6),
                        _cifraConUnidad(
                          '$cuanto kg',
                          theme.textTheme.labelLarge?.copyWith(color: tinta),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _celdaPesaje(BuildContext context, DateTime fecha) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final pesaje = widget.diario.pesajeDe(fecha);
    final forma = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(12),
      side: pesaje == null
          ? BorderSide(color: esquema.outlineVariant)
          : BorderSide.none,
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: forma,
        color: pesaje == null ? null : esquema.primaryContainer,
      ),
      child: Center(
        child: pesaje == null
            ? Text(
                '${fecha.day}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: esquema.onSurfaceVariant,
                ),
              )
            : Text(
                _unDecimal(pesaje.kilogramos),
                style: cifra(theme.textTheme.labelMedium).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: esquema.onPrimaryContainer,
                ),
              ),
      ),
    );
  }

  String _etiquetaPesaje(DateTime fecha) {
    final dia = _etiquetaDia(fecha);
    final pesaje = widget.diario.pesajeDe(fecha);
    if (pesaje == null) {
      return dia;
    }
    return '$dia, ${_unDecimal(pesaje.kilogramos)} kg';
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  Future<void> _abrirAjustes() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AjustesPagina(diario: widget.diario),
      ),
    );
    if (mounted) {
      setState(() {
        _demorarAcuse = true;
        _podarPliegues();
      });
    }
  }

  Future<void> _abrirCatalogo() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CatalogoPagina(diario: widget.diario),
      ),
    );
    if (mounted) {
      setState(() {
        _demorarAcuse = true;
        _podarPliegues();
      });
    }
  }

  void _diaAnterior() {
    hapticoSeleccion();
    setState(() {
      _alCambiarFecha();
      _haciaAtras = true;
      _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day - 1);
    });
  }

  void _diaSiguiente() {
    hapticoSeleccion();
    setState(() {
      _alCambiarFecha();
      _haciaAtras = false;
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

  void _seleccionarEnPesaje(DateTime fecha) {
    setState(() {
      _fecha = DateTime(fecha.year, fecha.month, fecha.day);
      _cargarKilogramos();
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

  // -------------------------------------------------------------------------
  // Momento cards
  // -------------------------------------------------------------------------

  void _alternarRenglon(Comida comida, int indice) {
    setState(() {
      final clave = '${comida.id}:$indice';
      _renglonAbierto = _renglonAbierto == clave ? null : clave;
    });
  }

  void _alternarMomento(Momento momento) {
    hapticoSeleccion();
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
        SizedBox(
          key: Key('separador-momentos-${momento.name}'),
          height: entreRenglones,
        ),
      TarjetaNutri(
        padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final comida in comidas) ...[
              _encabezadoMomento(theme, comida, momento, cerrado: cerrado),
              EntradaAlDesplegar(
                cerrado: cerrado,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < comida.renglones.length; i++) ...[
                        _renglon(theme, comida, i),
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
              ),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _encabezadoMomento(
    ThemeData theme,
    Comida comida,
    Momento momento, {
    required bool cerrado,
  }) {
    final esquema = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Presionable(
            child: InkWell(
              onTap: () => _alternarMomento(momento),
              customBorder: formaTarjeta(radio: radioCampo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: esquema.tertiaryContainer,
                      ),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          iconoDeMomento(momento, grueso: true),
                          size: 20,
                          color: esquema.onTertiaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        momento.etiqueta,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    _cifraConUnidad(
                      '${_textoNumero(_kcalDe(comida))} kcal',
                      theme.textTheme.titleMedium,
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: cerrado ? -0.25 : 0,
                      duration: duracion(context, MotionNutri.medio),
                      curve: curvaEstandar,
                      child: Icon(
                        IconosNutri.desplegar,
                        size: 20,
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(
            IconosNutri.menu,
            size: 20,
            color: esquema.onSurfaceVariant,
          ),
          onSelected: (valor) => _menuComida(comida, valor),
          itemBuilder: (context) => [
            for (final otro in Momento.values)
              PopupMenuItem(
                value: 'momento:${otro.name}',
                child: Text(otro.etiqueta),
              ),
            const PopupMenuItem(value: 'borrar', child: Text('Borrar Comida')),
          ],
        ),
      ],
    );
  }

  Widget _renglon(ThemeData theme, Comida comida, int indice) {
    final renglon = comida.renglones[indice];
    return InkWell(
      onTap: () => _alternarRenglon(comida, indice),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: LayoutBuilder(
          builder: (context, restricciones) => Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: restricciones.maxWidth * 0.72,
                ),
                child: Text(
                  renglon.nombre,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(child: _Puntos(estilo: theme.textTheme.bodyLarge)),
              _cifraConUnidad(
                '${renglon.cantidad} g',
                theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Día pieces
// ---------------------------------------------------------------------------

class _MacroContraMeta extends StatelessWidget {
  const _MacroContraMeta({
    super.key,
    required this.macro,
    required this.etiqueta,
    required this.unidad,
    required this.consumido,
    required this.objetivo,
  });

  final MacroVisual macro;
  final String etiqueta;
  final String unidad;
  final num consumido;
  final num objetivo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final tono = macro.color(context);
    final pista = macro.pista(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: consumido.toDouble()),
      duration: duracion(context, MotionNutri.medio),
      curve: curvaEstandar,
      builder: (context, valor, child) {
        final progreso = objetivo <= 0
            ? 0.0
            : (valor / objetivo).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pista,
                  ),
                  child: SizedBox.square(
                    dimension: 28,
                    child: Icon(macro.iconoGrueso, size: 15, color: tono),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(etiqueta, style: theme.textTheme.titleSmall),
                ),
                _cifraConUnidad(
                  '${_entero(valor)} / ${_entero(objetivo)} $unidad',
                  theme.textTheme.bodyMedium?.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                  destacarPrimero: esquema.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: LinearProgressIndicator(
                value: progreso.toDouble(),
                minHeight: 8,
                color: tono,
                backgroundColor: pista,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The empty Día: an empty plate and a nudge toward the Comida button.
class _DiaVacio extends StatelessWidget {
  const _DiaVacio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Plate beside the copy (not stacked) so the Comida pill never covers
    // the message on a phone-height screen.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 28, 8, 8),
      child: Row(
        children: [
          const PlatoVacio(tamano: 96),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plato vacío', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Tocá Comida para anotar lo que comiste.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A dashed hairline in `outlineVariant`.
class _HiloPunteado extends StatelessWidget {
  const _HiloPunteado({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _PintorPunteado(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _PintorPunteado extends CustomPainter {
  const _PintorPunteado({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), pincel);
    }
  }

  @override
  bool shouldRepaint(_PintorPunteado oldDelegate) => oldDelegate.color != color;
}

/// The dotted leader of a menu line. It carries the [estilo] line's baseline
/// so a baseline-aligned row puts the dots on the text's baseline.
class _Puntos extends StatelessWidget {
  const _Puntos({required this.estilo});

  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final medida = TextPainter(
      text: TextSpan(text: ' ', style: estilo),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final linea = medida.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    medida.dispose();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Stack(
        children: [
          Text(' ', style: estilo),
          Positioned.fill(
            child: CustomPaint(
              painter: _PintorPuntos(
                linea: linea,
                color: Theme.of(context).colorScheme.outline
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PintorPuntos extends CustomPainter {
  const _PintorPuntos({required this.linea, required this.color});

  final double linea;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()..color = color;
    const paso = 5.0;
    final cuantos = (size.width / paso).floor();
    if (cuantos <= 0) {
      return;
    }
    // Right-align the dots so every leader ends flush against the grams.
    final inicio = size.width - cuantos * paso + paso / 2;
    for (var i = 0; i < cuantos; i++) {
      canvas.drawCircle(Offset(inicio + i * paso, linea - 1), 1, pincel);
    }
  }

  @override
  bool shouldRepaint(_PintorPuntos oldDelegate) =>
      oldDelegate.color != color || oldDelegate.linea != linea;
}

/// A Renglón's Macros as a 2×2 grid of tiles, each with a 3 px accent in its
/// hue (Calorías in `primary`).
class _MacrosDeRenglon extends StatelessWidget {
  const _MacrosDeRenglon({required this.macros});

  final Macros macros;

  @override
  Widget build(BuildContext context) {
    Widget fila(Widget a, Widget b) => Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 8),
        Expanded(child: b),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Column(
        children: [
          fila(
            _TeselaMacro(
              macro: MacroVisual.kcal,
              etiqueta: 'Calorías',
              valor: '${_textoNumero(macros.kcal)} kcal',
            ),
            _TeselaMacro(
              macro: MacroVisual.proteina,
              etiqueta: 'Proteína (P)',
              valor: '${_textoNumero(macros.proteina)} g',
            ),
          ),
          const SizedBox(height: 8),
          fila(
            _TeselaMacro(
              macro: MacroVisual.carbos,
              etiqueta: 'Carbos (C)',
              valor: '${_textoNumero(macros.carbos)} g',
            ),
            _TeselaMacro(
              macro: MacroVisual.grasa,
              etiqueta: 'Grasa (F)',
              valor: '${_textoNumero(macros.grasa)} g',
            ),
          ),
        ],
      ),
    );
  }
}

class _TeselaMacro extends StatelessWidget {
  const _TeselaMacro({
    required this.macro,
    required this.etiqueta,
    required this.valor,
  });

  final MacroVisual macro;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: esquema.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: macro.color(context),
              child: const SizedBox(height: 3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _cifraConUnidad(valor, theme.textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text helpers
// ---------------------------------------------------------------------------

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

String _etiquetaDia(DateTime fecha) => '${fecha.day} de ${nombreMes(fecha)}';

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
  return '${_diaDeSemana(fecha)} ${fecha.day} de ${nombreMes(fecha)}';
}

String _entero(num valor) => valor.round().toString();

String _unDecimal(num valor) => valor.toStringAsFixed(1);

String _textoNumero(num valor) => _unDecimal(valor);

num? _parsearKilogramos(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) {
    return null;
  }
  return num.tryParse(limpio);
}

String _textoKilogramos(num valor) {
  if (valor == valor.roundToDouble()) {
    return valor.round().toString();
  }
  return valor.toString();
}

/// [texto] as one `Text.rich` (same plain text) with the digits in DM Mono
/// and the spaces and units ("kcal", "g", "kg") in the reading sans, so
/// columns of numbers line up without monospace gaps around the units.
/// [destacarPrimero] colors the first number (the consumed part).
Widget _cifraConUnidad(
  String texto,
  TextStyle? base, {
  Color? destacarPrimero,
}) {
  final partes = <TextSpan>[];
  var primero = true;
  for (final m in RegExp(r'[0-9.,/+-]+|[^0-9.,/+-]+').allMatches(texto)) {
    final trozo = m.group(0)!;
    final esCifra = RegExp(r'[0-9]').hasMatch(trozo);
    var estilo = esCifra ? cifra(base) : base;
    if (esCifra && primero) {
      primero = false;
      if (destacarPrimero != null) {
        estilo = estilo?.copyWith(color: destacarPrimero);
      }
    }
    partes.add(TextSpan(text: trozo, style: estilo));
  }
  return Text.rich(TextSpan(children: partes));
}
