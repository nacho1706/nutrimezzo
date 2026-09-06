import 'package:flutter/material.dart';

import 'diario.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Meta', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Los denominadores del Día. Cambiarlos no pide reinstalar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _campoNumero(
                controller: _kcal,
                etiqueta: 'Calorías',
                sufijo: 'kcal',
              ),
              _campoNumero(
                controller: _proteina,
                etiqueta: 'Proteína (P)',
                sufijo: 'g',
              ),
              _campoNumero(
                controller: _carbos,
                etiqueta: 'Carbos (C)',
                sufijo: 'g',
              ),
              _campoNumero(
                controller: _grasa,
                etiqueta: 'Grasa (F)',
                sufijo: 'g',
              ),
              const SizedBox(height: 28),
              Text('Clave propia (BYOK)', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Opcional. URL, clave e id de modelo en este teléfono. '
                'En blanco el diario funciona igual.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlBase,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'URL base',
                  hintText: 'https://…',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _claveApi,
                obscureText: !_claveVisible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Clave de API',
                  suffixIcon: IconButton(
                    tooltip: _claveVisible ? 'Ocultar clave' : 'Mostrar clave',
                    onPressed: () {
                      setState(() => _claveVisible = !_claveVisible);
                    },
                    icon: Icon(
                      _claveVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idModelo,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Id del modelo'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _guardando ? null : _borrarByok,
                  child: const Text('Borrar BYOK'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoNumero({
    required TextEditingController controller,
    required String etiqueta,
    required String sufijo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: etiqueta, suffixText: sufijo),
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
