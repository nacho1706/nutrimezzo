import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'almacen_ajustes.dart';
import 'diario.dart';
import 'home_dia.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final diario = await abrirDiario();
  runApp(NutriMezzoApp(diario: diario));
}

class NutriMezzoApp extends StatelessWidget {
  const NutriMezzoApp({super.key, required this.diario});

  final Diario diario;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriMezzo',
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
      home: HomeDia(diario: diario),
      builder: (context, child) => ColumnaWeb(child: child!),
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
