import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'ajustes.dart';
import 'almacen_ajustes.dart';
import 'almacen_remoto.dart';
import 'diario.dart';
import 'home_dia.dart';
import 'servidor.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NutriMezzoRaiz());
}

/// The app on an already-open [Diario] (offline, or tests).
class NutriMezzoApp extends StatelessWidget {
  const NutriMezzoApp({super.key, required this.diario});

  final Diario diario;

  @override
  Widget build(BuildContext context) {
    return _MarcoApp(home: HomeDia(diario: diario));
  }
}

/// Theme, locale and the web column around [home].
class _MarcoApp extends StatelessWidget {
  const _MarcoApp({
    required this.home,
    this.navigatorKey,
    this.scaffoldMessengerKey,
    this.web = kIsWeb,
  });

  final Widget home;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final bool web;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriMezzo',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: temaClaro(),
      darkTheme: temaOscuro(),
      themeMode: ThemeMode.system,
      home: home,
      builder: (context, child) => ColumnaWeb(web: web, child: child!),
    );
  }
}

const _avisoConflicto =
    'Se actualizó desde otro dispositivo; repetí el último cambio.';
const _avisoFallo = 'No se pudo guardar: sin conexión con el servidor.';
const _avisoActualizado = 'Actualizado desde otro dispositivo';

/// Resolves the installation type (servidor.dart) and opens the Diario on
/// it. Hosted: the server is the only source of truth, so a failed write or
/// a conflict reopens the Diario from the server, and a failed open shows
/// [PantallaSinServidor] instead of the Día.
class NutriMezzoRaiz extends StatefulWidget {
  const NutriMezzoRaiz({
    super.key,
    this.web = kIsWeb,
    this.origen,
    this.cliente,
    this.ahora,
  });

  final bool web;

  /// Web only: the page origin the API lives on (default [Uri.base]).
  final Uri? origen;

  final http.Client? cliente;
  final DateTime Function()? ahora;

  @override
  State<NutriMezzoRaiz> createState() => _NutriMezzoRaizState();
}

class _NutriMezzoRaizState extends State<NutriMezzoRaiz>
    with WidgetsBindingObserver {
  final _mensajes = GlobalKey<ScaffoldMessengerState>();
  late final http.Client _cliente = widget.cliente ?? http.Client();

  // A fresh Navigator per opening: routes pushed on a stale Diario (Ajustes,
  // captura…) are dropped at once instead of animating out still mounted.
  var _navegador = GlobalKey<NavigatorState>();
  var _generacion = 0;
  Modo? _modo;
  Diario? _diario;
  AlmacenRemoto? _remoto;
  StreamSubscription<EventoSincronizacion>? _eventos;
  var _sinServidor = false;
  var _servidorUrl = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_cargar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _soltar();
    if (widget.cliente == null) {
      _cliente.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_revisarRevision());
    }
  }

  void _recargar({String? aviso}) {
    setState(() {
      _soltar();
      _diario = null;
      _sinServidor = false;
      _navegador = GlobalKey<NavigatorState>();
    });
    unawaited(_cargar(aviso: aviso));
  }

  Future<void> _cargar({String? aviso}) async {
    final generacion = ++_generacion;
    bool vigente() => mounted && generacion == _generacion;
    final modo = await resolverModo(web: widget.web, origen: widget.origen);
    final url = widget.web ? '' : await leerServidor();
    if (!vigente()) return;
    setState(() {
      _modo = modo;
      _servidorUrl = url;
    });
    final Diario diario;
    switch (modo) {
      case ModoOffline():
        diario = await abrirDiario(ahora: widget.ahora);
        if (!vigente()) return;
      case ModoAlojado(:final api):
        final AlmacenRemoto remoto;
        try {
          remoto = await abrirDiarioRemoto(
            api: api,
            cliente: _cliente,
            ahora: widget.ahora,
          );
        } on FalloServidor {
          if (vigente()) setState(() => _sinServidor = true);
          return;
        }
        if (!vigente()) {
          remoto.cerrar();
          return;
        }
        _remoto = remoto;
        _eventos = remoto.eventos.listen(_alEvento);
        diario = remoto.diario;
    }
    setState(() => _diario = diario);
    if (aviso != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mensajes.currentState?.showSnackBar(SnackBar(content: Text(aviso)));
      });
    }
  }

  void _soltar() {
    unawaited(_eventos?.cancel());
    _eventos = null;
    _remoto?.cerrar();
    _remoto = null;
  }

  void _alEvento(EventoSincronizacion evento) {
    if (!mounted) return;
    _recargar(
      aviso: switch (evento) {
        EventoSincronizacion.conflicto => _avisoConflicto,
        EventoSincronizacion.fallo => _avisoFallo,
      },
    );
  }

  /// Back in the foreground: if another device wrote meanwhile, show its
  /// diary — unless a capture is half-typed here, which a reload would lose.
  Future<void> _revisarRevision() async {
    final remoto = _remoto;
    if (remoto == null || remoto.escribiendo) return;
    final int revision;
    try {
      revision = await remoto.revisionRemota();
    } on FalloServidor {
      return;
    }
    if (!mounted || remoto != _remoto || remoto.escribiendo) return;
    if (revision != remoto.revision && remoto.diario.borrador == null) {
      _recargar(aviso: _avisoActualizado);
    }
  }

  Future<void> _cambiarServidor(String url) async {
    await guardarServidor(url);
    if (mounted) _recargar();
  }

  ServidorAjustable? get _servidor => widget.web
      ? null
      : ServidorAjustable(
          url: _servidorUrl,
          cambiar: (url) => unawaited(_cambiarServidor(url)),
        );

  @override
  Widget build(BuildContext context) {
    final modo = _modo;
    final diario = _diario;
    final Widget home;
    if (diario != null) {
      home = HomeDia(
        key: ValueKey(_generacion),
        diario: diario,
        servidor: _servidor,
        alojado: modo is ModoAlojado,
      );
    } else if (_sinServidor && modo is ModoAlojado) {
      home = PantallaSinServidor(
        servidor: modo.api.authority,
        onReintentar: _recargar,
        ajustesServidor: _servidor,
      );
    } else {
      home = _Cargando(alojado: modo is ModoAlojado);
    }
    return _MarcoApp(
      navigatorKey: _navegador,
      scaffoldMessengerKey: _mensajes,
      web: widget.web,
      home: home,
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({required this.alojado});

  final bool alojado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: alojado
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.expand(),
    );
  }
}

/// Hosted and the server did not answer: no diary to show, and nothing may
/// be logged offline.
@visibleForTesting
class PantallaSinServidor extends StatelessWidget {
  const PantallaSinServidor({
    super.key,
    required this.servidor,
    required this.onReintentar,
    this.ajustesServidor,
  });

  /// Host (and port) shown to the user.
  final String servidor;
  final VoidCallback onReintentar;

  /// Android only: edit or clear the URL.
  final ServidorAjustable? ajustesServidor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final ajustes = ajustesServidor;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(margenPantalla),
            child: TarjetaNutri(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(IconosNutri.servidor, size: 28, color: esquema.error),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo conectar con el servidor',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(servidor, style: cifra(theme.textTheme.bodyMedium)),
                  const SizedBox(height: 6),
                  Text(
                    '¿Está Tailscale encendido?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onReintentar,
                    child: const Text('Reintentar'),
                  ),
                  if (ajustes != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ServidorPagina(servidor: ajustes),
                        ),
                      ),
                      child: const Text('Ajustes del servidor'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// La UI está diseñada para teléfono; en un navegador de escritorio se
// estiraría a todo el ancho de la ventana, así que en web se limita a esto.
const double _anchoMaximoWeb = 480;

/// En web con ventana ancha, centra toda la app (rutas, diálogos, hojas,
/// snackbars) en una columna de [_anchoMaximoWeb] sobre un fondo del tema, y
/// ajusta el [MediaQuery] para que el contenido vea el ancho de la columna.
/// Fuera de web (Android) devuelve [child] tal cual.
@visibleForTesting
class ColumnaWeb extends StatelessWidget {
  const ColumnaWeb({super.key, required this.child, this.web = kIsWeb});

  final Widget child;
  final bool web;

  @override
  Widget build(BuildContext context) {
    if (!web) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _anchoMaximoWeb) return child;
        final tamano = Size(_anchoMaximoWeb, constraints.maxHeight);
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox.fromSize(
              size: tamano,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: tamano),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
