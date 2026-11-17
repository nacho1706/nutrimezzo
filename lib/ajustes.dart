import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'diario.dart';
import 'motion.dart';
import 'tema.dart';

class AjustesPagina extends StatefulWidget {
  const AjustesPagina({super.key, required this.diario});

  final Diario diario;

  @override
  State<AjustesPagina> createState() => _AjustesPaginaState();
}

class _AjustesPaginaState extends State<AjustesPagina> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kcal;
  late final TextEditingController _proteina;
  late final TextEditingController _carbos;
  late final TextEditingController _grasa;
  late final TextEditingController _urlBase;
  late final TextEditingController _claveApi;
  late final TextEditingController _idModelo;
  final _sacudida = ControladorSacudida();
  var _claveVisible = false;
  var _guardando = false;

  @override
  void initState() {
    super.initState();
    final macros = widget.diario.meta.macros;
    final byok = widget.diario.byok;
    _kcal = TextEditingController(text: _textoNumero(macros.kcal));
    _proteina = TextEditingController(text: _textoNumero(macros.proteina));
    _carbos = TextEditingController(text: _textoNumero(macros.carbos));
    _grasa = TextEditingController(text: _textoNumero(macros.grasa));
    _urlBase = TextEditingController(text: byok.urlBase);
    _claveApi = TextEditingController(text: byok.claveApi);
    _idModelo = TextEditingController(text: byok.idModelo);
  }

  @override
  void dispose() {
    _kcal.dispose();
    _proteina.dispose();
    _carbos.dispose();
    _grasa.dispose();
    _urlBase.dispose();
    _claveApi.dispose();
    _idModelo.dispose();
    _sacudida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esquema = theme.colorScheme;
    final explicacion = theme.textTheme.bodyMedium?.copyWith(
      color: esquema.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Form(
        key: _formKey,
        child: _camposSobrePapel(
          context,
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              margenPantalla,
              8,
              margenPantalla,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TarjetaNutri(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Meta', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        'Los denominadores del Día. Cambiarlos no pide reinstalar.',
                        style: explicacion,
                      ),
                      const SizedBox(height: 20),
                      _campoNumero(
                        controller: _kcal,
                        etiqueta: 'Calorías',
                        sufijo: 'kcal',
                        matiz: esquema.primary,
                      ),
                      _campoNumero(
                        controller: _proteina,
                        etiqueta: 'Proteína (P)',
                        sufijo: 'g',
                        matiz: MacroVisual.proteina.color(context),
                      ),
                      _campoNumero(
                        controller: _carbos,
                        etiqueta: 'Carbos (C)',
                        sufijo: 'g',
                        matiz: MacroVisual.carbos.color(context),
                      ),
                      _campoNumero(
                        controller: _grasa,
                        etiqueta: 'Grasa (F)',
                        sufijo: 'g',
                        matiz: MacroVisual.grasa.color(context),
                        ultimo: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: entreSecciones),
                TarjetaNutri(
                  padding: const EdgeInsets.fromLTRB(
                    rellenoTarjeta,
                    rellenoTarjeta,
                    rellenoTarjeta,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            IconosNutri.clave,
                            size: 22,
                            color: esquema.onSurface,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Clave propia (BYOK)',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Opcional. URL, clave e id de modelo en este teléfono. '
                        'En blanco el diario funciona igual.',
                        style: explicacion,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _urlBase,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'URL base',
                          hintText: 'https://…',
                        ),
                      ),
                      const SizedBox(height: entreRenglones),
                      TextFormField(
                        controller: _claveApi,
                        obscureText: !_claveVisible,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Clave de API',
                          suffixIcon: IconButton(
                            tooltip: _claveVisible
                                ? 'Ocultar clave'
                                : 'Mostrar clave',
                            onPressed: () {
                              setState(() => _claveVisible = !_claveVisible);
                            },
                            icon: Icon(
                              _claveVisible
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: entreRenglones),
                      TextFormField(
                        controller: _idModelo,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Id del modelo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: _guardando ? null : _borrarByok,
                          child: const Text('Borrar BYOK'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: entreSecciones),
                Sacudible(
                  controlador: _sacudida,
                  child: FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: const Text('Guardar'),
                  ),
                ),
                const SizedBox(height: 40),
                const _PieMarca(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoNumero({
    required TextEditingController controller,
    required String etiqueta,
    required String sufijo,
    required Color matiz,
    bool ultimo = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : entreRenglones),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: cifra(Theme.of(context).textTheme.bodyLarge),
        decoration: InputDecoration(
          labelText: etiqueta,
          suffixText: sufijo,
          prefixIcon: _PuntoMatiz(color: matiz),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
        ),
        validator: _validarNumero,
      ),
    );
  }

  String? _validarNumero(String? valor) {
    final numero = _parsearNumero(valor ?? '');
    if (numero == null) {
      return 'Indicá un número';
    }
    if (numero < 0) {
      return 'Tiene que ser 0 o más';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _sacudida.sacudir();
      return;
    }
    setState(() => _guardando = true);
    try {
      await widget.diario.guardarMeta(
        Meta(
          macros: Macros(
            kcal: _parsearNumero(_kcal.text)!,
            proteina: _parsearNumero(_proteina.text)!,
            carbos: _parsearNumero(_carbos.text)!,
            grasa: _parsearNumero(_grasa.text)!,
          ),
        ),
      );
      await widget.diario.guardarByok(_byokDelFormulario());
      hapticoExito();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _borrarByok() {
    _urlBase.clear();
    _claveApi.clear();
    _idModelo.clear();
    setState(() {});
  }

  Byok _byokDelFormulario() {
    return Byok(
      urlBase: _urlBase.text.trim(),
      claveApi: _claveApi.text.trim(),
      idModelo: _idModelo.text.trim(),
    );
  }
}

/// The 8 px dot in a macro's hue that prefixes its field.
class _PuntoMatiz extends StatelessWidget {
  const _PuntoMatiz({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 8),
        ),
      ),
    );
  }
}

/// Mark, wordmark and the privacy line under everything.
class _PieMarca extends StatelessWidget {
  const _PieMarca();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const MarcaNutriMezzo(tamano: 36),
        const SizedBox(height: 8),
        const PalabraMarca(tamano: 18),
        const SizedBox(height: 4),
        Text(
          'Todo queda en este teléfono.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Inside a papel card in dark theme the default field fill
/// (`surfaceContainerLow`) is nearly papel itself; lift it one step.
Widget _camposSobrePapel(BuildContext context, Widget child) {
  final theme = Theme.of(context);
  if (theme.brightness != Brightness.dark) {
    return child;
  }
  return Theme(
    data: theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        fillColor: theme.colorScheme.surfaceContainerHigh,
      ),
    ),
    child: child,
  );
}

String _textoNumero(num valor) {
  if (valor == valor.roundToDouble()) {
    return valor.round().toString();
  }
  return valor.toString();
}

num? _parsearNumero(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) {
    return null;
  }
  return num.tryParse(limpio);
}
