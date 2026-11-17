import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

const duracionMotion = Duration(milliseconds: 250);

Duration duracionMotionDe(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : duracionMotion;
}

Widget entradaRenglon(BuildContext context, Widget child, {Key? key}) {
  if (duracionMotionDe(context) == Duration.zero) {
    return KeyedSubtree(key: key, child: child);
  }
  return child
      .animate(key: key)
      .fadeIn(duration: duracionMotion, curve: Curves.easeOutCubic)
      .slideY(
        begin: 0.08,
        duration: duracionMotion,
        curve: Curves.easeOutCubic,
      );
}

/// Fade + slideY only when a section goes from folded to open.
/// First paint and date changes stay opaque so they do not look like new food.
class EntradaAlDesplegar extends StatefulWidget {
  const EntradaAlDesplegar({
    super.key,
    required this.cerrado,
    required this.child,
  });

  final bool cerrado;
  final Widget child;

  @override
  State<EntradaAlDesplegar> createState() => _EntradaAlDesplegarState();
}

class _EntradaAlDesplegarState extends State<EntradaAlDesplegar> {
  var _animarEntrada = false;
  Key? _claveEntrada;

  @override
  void didUpdateWidget(EntradaAlDesplegar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cerrado && !widget.cerrado) {
      _animarEntrada = true;
      _claveEntrada = UniqueKey();
    } else if (widget.cerrado) {
      _animarEntrada = false;
      _claveEntrada = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cerrado) {
      return const SizedBox.shrink();
    }
    if (_animarEntrada) {
      return entradaRenglon(context, widget.child, key: _claveEntrada);
    }
    return widget.child;
  }
}

// ---------------------------------------------------------------------------
// Tokens (docs/identidad-visual.md, "Motion system")
// ---------------------------------------------------------------------------

/// Motion durations. Read them through [duracion] so they collapse to zero
/// under `disableAnimations`.
abstract final class MotionNutri {
  /// 150 ms: press scale, chip/selection.
  static const corto = Duration(milliseconds: 150);

  /// 250 ms: same-Día tweens, Renglón enter, unfold, chevron.
  static const medio = duracionMotion;

  /// 400 ms: routes, fade-through, Día/month slide, container transform.
  static const largo = Duration(milliseconds: 400);

  /// 700 ms: the one-shot verde acknowledgement.
  static const enfasis = Duration(milliseconds: 700);
}

/// Standard curve (corto, medio, enfasis).
const Curve curvaEstandar = Curves.easeOutCubic;

/// Emphasized curve (largo).
const Curve curvaEnfatizada = Cubic(0.2, 0, 0, 1);

/// [base], or zero when the platform asks to disable animations.
Duration duracion(BuildContext context, Duration base) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : base;
}

// ---------------------------------------------------------------------------
// Destination and Día/month switches
// ---------------------------------------------------------------------------

/// Fade-through between top-level destinations (Día / Cumplimiento / Pesaje).
/// Give [child] a key that changes with the destination.
class ConmutadorFadeThrough extends StatelessWidget {
  const ConmutadorFadeThrough({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: duracion(context, MotionNutri.largo),
      transitionBuilder: (child, primaria, secundaria) => FadeThroughTransition(
        animation: primaria,
        secondaryAnimation: secundaria,
        fillColor: Colors.transparent,
        child: SoloLaEntrante(
          primaria: primaria,
          secundaria: secundaria,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Horizontal shared-axis slide for a Día or month change. Give [child] a key
/// that changes with the fecha/month; set [haciaAtras] when going to the
/// previous one so the page slides the other way.
class ConmutadorEjeHorizontal extends StatelessWidget {
  const ConmutadorEjeHorizontal({
    super.key,
    required this.child,
    this.haciaAtras = false,
  });

  final Widget child;
  final bool haciaAtras;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: duracion(context, MotionNutri.largo),
      reverse: haciaAtras,
      transitionBuilder: (child, primaria, secundaria) => SharedAxisTransition(
        animation: primaria,
        secondaryAnimation: secundaria,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: Colors.transparent,
        child: SoloLaEntrante(
          primaria: primaria,
          secundaria: secundaria,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Inside a [PageTransitionSwitcher] transition: the page that is leaving
/// stops taking taps and drops out of the semantics tree, so mid-transition
/// only the incoming page is "there" (one Día, one month, one destination).
class SoloLaEntrante extends StatefulWidget {
  const SoloLaEntrante({
    super.key,
    required this.primaria,
    required this.secundaria,
    required this.child,
  });

  final Animation<double> primaria;
  final Animation<double> secundaria;
  final Widget child;

  @override
  State<SoloLaEntrante> createState() => _SoloLaEntranteState();
}

class _SoloLaEntranteState extends State<SoloLaEntrante> {
  @override
  void initState() {
    super.initState();
    _escuchar(widget);
  }

  @override
  void didUpdateWidget(SoloLaEntrante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaria != widget.primaria ||
        oldWidget.secundaria != widget.secundaria) {
      _soltar(oldWidget);
      _escuchar(widget);
    }
  }

  @override
  void dispose() {
    _soltar(widget);
    super.dispose();
  }

  void _escuchar(SoloLaEntrante w) {
    w.primaria.addStatusListener(_cambio);
    w.secundaria.addStatusListener(_cambio);
  }

  void _soltar(SoloLaEntrante w) {
    w.primaria.removeStatusListener(_cambio);
    w.secundaria.removeStatusListener(_cambio);
  }

  void _cambio(AnimationStatus _) {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _saliendo {
    final secundaria = widget.secundaria.status;
    final primaria = widget.primaria.status;
    return secundaria == AnimationStatus.forward ||
        secundaria == AnimationStatus.completed ||
        primaria == AnimationStatus.reverse ||
        primaria == AnimationStatus.dismissed;
  }

  @override
  Widget build(BuildContext context) {
    final saliendo = _saliendo;
    return IgnorePointer(
      ignoring: saliendo,
      child: ExcludeSemantics(excluding: saliendo, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// Press feedback
// ---------------------------------------------------------------------------

/// Scales [child] to 0.97 while a pointer is down on it (corto, standard
/// curve). Uses a `Listener`, so taps still reach InkWell / RadioListTile
/// children. No-op under `disableAnimations` or when [habilitado] is false.
class Presionable extends StatefulWidget {
  const Presionable({
    super.key,
    required this.child,
    this.habilitado = true,
    this.escala = 0.97,
  });

  final Widget child;
  final bool habilitado;
  final double escala;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  var _presionado = false;

  void _cambiar(bool presionado) {
    if (_presionado != presionado && mounted) {
      setState(() => _presionado = presionado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duracionPresion = duracion(context, MotionNutri.corto);
    if (!widget.habilitado || duracionPresion == Duration.zero) {
      return widget.child;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _cambiar(true),
      onPointerUp: (_) => _cambiar(false),
      onPointerCancel: (_) => _cambiar(false),
      child: AnimatedScale(
        scale: _presionado ? widget.escala : 1,
        duration: duracionPresion,
        curve: curvaEstandar,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Validation shake
// ---------------------------------------------------------------------------

/// Triggers a [Sacudible]. Create one per shakeable widget (dispose it with
/// the owning State) and call [sacudir] when validation fails.
class ControladorSacudida extends ChangeNotifier {
  /// Shakes the attached [Sacudible] and fires [hapticoError].
  void sacudir() => notifyListeners();
}

/// Shakes [child] horizontally (3 cycles, 6 px, ~400 ms, flutter_animate
/// `shake`) each time [controlador] `.sacudir()` is called, with a heavy
/// haptic. Under `disableAnimations` only the haptic fires.
///
/// ```dart
/// final _sacudida = ControladorSacudida();
/// Sacudible(controlador: _sacudida, child: FilledButton(...));
/// if (!valido) _sacudida.sacudir();
/// ```
class Sacudible extends StatefulWidget {
  const Sacudible({super.key, required this.controlador, required this.child});

  final ControladorSacudida controlador;
  final Widget child;

  @override
  State<Sacudible> createState() => _SacudibleState();
}

class _SacudibleState extends State<Sacudible> {
  AnimationController? _animacion;

  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_sacudir);
  }

  @override
  void didUpdateWidget(Sacudible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      oldWidget.controlador.removeListener(_sacudir);
      widget.controlador.addListener(_sacudir);
    }
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_sacudir);
    super.dispose();
  }

  void _sacudir() {
    hapticoError();
    if (!mounted || MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _animacion?.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // No Animate under disableAnimations: it schedules a timer even with
    // autoPlay off, which tests flag as pending.
    if (MediaQuery.disableAnimationsOf(context)) {
      _animacion = null;
      return widget.child;
    }
    return widget.child
        .animate(autoPlay: false, onInit: (c) => _animacion = c)
        .shake(
          duration: MotionNutri.largo,
          hz: 7.5,
          offset: const Offset(6, 0),
          rotation: 0,
        );
  }
}

// ---------------------------------------------------------------------------
// Haptics
// ---------------------------------------------------------------------------

/// Nav, chips, Momento fold, calendar day taps.
Future<void> hapticoSeleccion() => HapticFeedback.selectionClick();

/// Guardar / Confirmar success.
Future<void> hapticoExito() => HapticFeedback.lightImpact();

/// The verde acknowledgement.
Future<void> hapticoVerde() => HapticFeedback.mediumImpact();

/// Validation failure.
Future<void> hapticoError() => HapticFeedback.heavyImpact();
