import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double opacidadDe(WidgetTester tester, Finder finder) {
  var opacidad = 1.0;
  tester.element(finder).visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Opacity) {
      opacidad *= widget.opacity;
    } else if (widget is FadeTransition) {
      opacidad *= widget.opacity.value;
    } else if (widget is AnimatedOpacity) {
      opacidad *= widget.opacity;
    }
    return true;
  });
  return opacidad;
}
