import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'tema.dart';

/// The Día's kcal against the Meta: a 228 px ring with the consumed kcal in
/// its center (docs/identidad-visual.md, "Día" §2).
///
/// Same-Día changes tween (ADR-0007); a new key per fecha makes another Día
/// appear at its final value. Bumping [acuseVerde] plays the one-shot verde
/// acknowledgement: a soft halo in `primary` that expands once (after
/// [demoraAcuse], so it is not hidden behind a closing container) plus a
/// medium haptic.
class AnilloKcal extends StatefulWidget {
  const AnilloKcal({
    super.key,
    required this.consumido,
    required this.objetivo,
    this.acuseVerde = 0,
    this.demoraAcuse = Duration.zero,
  });

  final num consumido;
  final num objetivo;

  /// Each increase plays the verde acknowledgement once.
  final int acuseVerde;

  /// How long to wait before the acknowledgement starts.
  final Duration demoraAcuse;

  static const diametro = 228.0;

  @override
  State<AnilloKcal> createState() => _AnilloKcalState();
}

class _AnilloKcalState extends State<AnilloKcal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: MotionNutri.enfasis,
  );

  @override
  void didUpdateWidget(AnilloKcal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.acuseVerde > oldWidget.acuseVerde) {
      _acusar();
    }
  }

  void _acusar() {
    final demora = widget.demoraAcuse;
    if (demora == Duration.zero) {
      _empezarHalo();
    } else {
      Future<void>.delayed(demora, () {
        if (mounted) {
          _empezarHalo();
        }
      });
    }
  }

  void _empezarHalo() {
    hapticoVerde();
    final duracionHalo = duracion(context, MotionNutri.enfasis);
    if (duracionHalo == Duration.zero) {
      return;
    }
    _halo.forward(from: 0);
  }

  @override
  void dispose() {
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final tonos = TonosNutri.of(context);
    final objetivo = widget.objetivo;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.consumido.toDouble()),
      duration: duracion(context, MotionNutri.medio),
      curve: curvaEstandar,
      builder: (context, valor, child) {
        final progreso = objetivo <= 0 ? 0.0 : valor / objetivo;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _Halo(animacion: _halo, color: esquema.primary),
            CustomPaint(
              painter: PintorAnilloKcal(
                progreso: progreso,
                color: esquema.primary,
                pista: MacroVisual.kcal.pista(context),
                marcas: esquema.outlineVariant,
                exceso: esquema.error,
                cuenta: tonos.papel,
              ),
              child: SizedBox.square(
                dimension: AnilloKcal.diametro,
                child: _CentroAnillo(valor: valor, objetivo: objetivo),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CentroAnillo extends StatelessWidget {
  const _CentroAnillo({required this.valor, required this.objetivo});

  final double valor;
  final num objetivo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final excedido = valor.round() > objetivo.round();
    final pastilla = excedido
        ? '+${(valor - objetivo).round()} de más'
        : 'quedan ${math.max(0, (objetivo - valor).round())}';

    return Semantics(
      container: true,
      label: '${_unDecimal(valor)} / ${_unDecimal(objetivo)} kcal',
      excludeSemantics: true,
      child: Center(
        child: SizedBox(
          width: 156,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${valor.round()}',
                  style: theme.textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'de ${objetivo.round()} kcal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: excedido
                      ? esquema.errorContainer
                      : esquema.primaryContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Text(
                    pastilla,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: excedido
                          ? esquema.onErrorContainer
                          : esquema.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The verde acknowledgement: a ring of `primary` that grows past the kcal
/// ring and fades out. Invisible at rest.
class _Halo extends StatelessWidget {
  const _Halo({required this.animacion, required this.color});

  final Animation<double> animacion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacion,
      builder: (context, _) {
        final t = curvaEstandar.transform(animacion.value);
        if (animacion.isDismissed || animacion.isCompleted) {
          return const SizedBox.square(dimension: AnilloKcal.diametro);
        }
        final alfa = 0.45 * (1 - t);
        return Transform.scale(
          scale: 1 + 0.22 * t,
          child: SizedBox.square(
            dimension: AnilloKcal.diametro,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: alfa),
                  width: 2 + 16 * (1 - t),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: alfa * 0.6),
                    blurRadius: 24 * t,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints the kcal ring: a `primary` 12% track with ten tick marks (one per
/// 10% of the Meta), the progress arc as a sweep from `primary` to a lighter
/// `primary` with a bead at its end, and, past the Meta, an `error` arc from
/// the top with its own bead.
class PintorAnilloKcal extends CustomPainter {
  const PintorAnilloKcal({
    required this.progreso,
    required this.color,
    required this.pista,
    required this.marcas,
    required this.exceso,
    required this.cuenta,
  });

  /// Consumed / Meta; above 1 the overflow arc shows.
  final double progreso;
  final Color color;
  final Color pista;
  final Color marcas;
  final Color exceso;

  /// The bead's fill (papel).
  final Color cuenta;

  static const trazo = 18.0;
  static const _radioCuenta = 10.0;
  static const _bordeCuenta = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = (math.min(size.width, size.height) - trazo) / 2 - 2;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    const inicio = -math.pi / 2;

    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..color = pista
        ..style = PaintingStyle.stroke
        ..strokeWidth = trazo,
    );

    final pincelMarca = Paint()
      ..color = marcas
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final angulo = inicio + i * 2 * math.pi / 10;
      final direccion = Offset(math.cos(angulo), math.sin(angulo));
      canvas.drawLine(
        centro + direccion * (radio - 4),
        centro + direccion * (radio + 4),
        pincelMarca,
      );
    }

    final lleno = progreso.clamp(0.0, 1.0);
    if (lleno > 0) {
      _arco(canvas, centro, radio, rect, lleno, color, _aclarar(color, 0.18));
    }
    if (progreso > 1) {
      final extra = (progreso - 1).clamp(0.0, 1.0);
      _arco(canvas, centro, radio, rect, extra, exceso, exceso);
    }
  }

  void _arco(
    Canvas canvas,
    Offset centro,
    double radio,
    Rect rect,
    double fraccion,
    Color desde,
    Color hasta,
  ) {
    const inicio = -math.pi / 2;
    final barrido = fraccion * 2 * math.pi;
    // The round cap pokes out before the start; rotate the gradient back by
    // the cap's angle so the cap takes the start color, not the end one.
    final tapa = (trazo / 2) / radio;
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trazo
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        endAngle: math.max(barrido + tapa, 0.0001),
        colors: [desde, hasta],
        transform: GradientRotation(inicio - tapa),
      ).createShader(rect);
    canvas.drawArc(rect, inicio, barrido, false, pincel);

    final fin = inicio + barrido;
    final punto = centro + Offset(math.cos(fin), math.sin(fin)) * radio;
    canvas.drawCircle(punto, _radioCuenta, Paint()..color = cuenta);
    canvas.drawCircle(
      punto,
      _radioCuenta - _bordeCuenta / 2,
      Paint()
        ..color = hasta
        ..style = PaintingStyle.stroke
        ..strokeWidth = _bordeCuenta,
    );
    // A small center in the arc's own color: a highlight, never a new hue.
    canvas.drawCircle(punto, 3, Paint()..color = hasta);
  }

  @override
  bool shouldRepaint(PintorAnilloKcal oldDelegate) {
    return oldDelegate.progreso != progreso ||
        oldDelegate.color != color ||
        oldDelegate.pista != pista ||
        oldDelegate.marcas != marcas ||
        oldDelegate.exceso != exceso ||
        oldDelegate.cuenta != cuenta;
  }
}

Color _aclarar(Color color, double cuanto) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + cuanto).clamp(0.0, 1.0)).toColor();
}

String _unDecimal(num valor) => valor.toStringAsFixed(1);
