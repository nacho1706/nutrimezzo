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
