import 'package:flutter/material.dart';

import 'diario.dart';

class CatalogoPagina extends StatefulWidget {
  const CatalogoPagina({super.key, required this.diario});

  final Diario diario;

  @override
  State<CatalogoPagina> createState() => _CatalogoPaginaState();
}

class _CatalogoPaginaState extends State<CatalogoPagina> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alimentos = widget.diario.alimentos;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.add),
        label: const Text('Crear'),
      ),
      body: alimentos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay Alimentos. Creá uno acá o al confirmar una Comida.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
              itemCount: alimentos.length,
              itemBuilder: (context, indice) {
                final alimento = alimentos[indice];
                final macros = alimento.macrosPor100g;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(alimento.nombre),
                  subtitle: Text('${_textoNumero(macros.kcal)} kcal / 100 g'),
                );
              },
            ),
    );
  }

  Future<void> _crear() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _AltaAlimento(diario: widget.diario),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }
}

class _AltaAlimento extends StatefulWidget {
  const _AltaAlimento({required this.diario});

  final Diario diario;

  @override
  State<_AltaAlimento> createState() => _AltaAlimentoState();
}

class _AltaAlimentoState extends State<_AltaAlimento> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _kcal = TextEditingController();
  final _proteina = TextEditingController();
  final _carbos = TextEditingController();
  final _grasa = TextEditingController();
  var _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _kcal.dispose();
    _proteina.dispose();
    _carbos.dispose();
    _grasa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Alimento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (valor) {
                if ((valor ?? '').trim().isEmpty) {
                  return 'Indicá un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _campoMacro(_kcal, 'Calorías', 'kcal / 100 g'),
            _campoMacro(_proteina, 'Proteína (P)', 'g / 100 g'),
            _campoMacro(_carbos, 'Carbos (C)', 'g / 100 g'),
            _campoMacro(_grasa, 'Grasa (F)', 'g / 100 g'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoMacro(
    TextEditingController controller,
    String etiqueta,
    String sufijo,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: etiqueta, suffixText: sufijo),
        validator: _validarMacro,
      ),
    );
  }

  String? _validarMacro(String? valor) {
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
      await widget.diario.crearAlimento(
        nombre: _nombre.text.trim(),
        macrosPor100g: Macros(
          kcal: _parsearNumero(_kcal.text)!,
          proteina: _parsearNumero(_proteina.text)!,
          carbos: _parsearNumero(_carbos.text)!,
          grasa: _parsearNumero(_grasa.text)!,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
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
