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
    );
  }
}
