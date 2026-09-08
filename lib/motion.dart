import 'package:flutter/material.dart';
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
