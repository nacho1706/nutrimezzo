import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'diario.dart';
import 'motion.dart';
import 'tema.dart';

/// Cards that stagger in when the Catálogo opens (doc: at most the first 10).
const _maximoEscalonados = 10;

/// Delay between two staggered cards.
const _pasoEscalonado = Duration(milliseconds: 40);

class CatalogoPagina extends StatefulWidget {
  const CatalogoPagina({super.key, required this.diario});

  final Diario diario;

  @override
  State<CatalogoPagina> createState() => _CatalogoPaginaState();
}

class _CatalogoPaginaState extends State<CatalogoPagina> {
  /// True only while the screen is being opened; returning from the editor
  /// must not replay the entrance.
  var _animarEntrada = true;

  @override
  Widget build(BuildContext context) {
    final alimentos = widget.diario.alimentos;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(IconosNutri.crear),
        label: const Text('Crear'),
      ),
      body: alimentos.isEmpty
          ? const _CatalogoVacio()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                margenPantalla,
                8,
                margenPantalla,
                104,
              ),
              itemCount: alimentos.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: entreRenglones),
              itemBuilder: (context, indice) {
                final alimento = alimentos[indice];
                return _entrada(
                  context,
                  indice,
                  _TarjetaAlimento(
                    alimento: alimento,
                    onTap: () => _abrir(alimento),
                  ),
                );
              },
            ),
    );
  }

  Widget _entrada(BuildContext context, int indice, Widget tarjeta) {
    final base = duracion(context, MotionNutri.medio);
    if (!_animarEntrada ||
        indice >= _maximoEscalonados ||
        base == Duration.zero) {
      return tarjeta;
    }
    return tarjeta
        .animate(delay: _pasoEscalonado * indice)
        .fadeIn(duration: base, curve: curvaEstandar)
        .slideY(begin: 0.06, end: 0, duration: base, curve: curvaEstandar);
  }

  Future<void> _crear() async {
    await _abrir(null);
  }

  Future<void> _abrir(Alimento? alimento) async {
    // The entrance belongs to opening the screen, not to coming back.
    _animarEntrada = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            _EditorAlimento(diario: widget.diario, alimento: alimento),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }
}

class _CatalogoVacio extends StatelessWidget {
  const _CatalogoVacio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 104),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlatoVacio(),
            const SizedBox(height: 20),
            Text(
              'Todavía no hay Alimentos. Creá uno acá o al confirmar una Comida.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAlimento extends StatelessWidget {
  const _TarjetaAlimento({required this.alimento, required this.onTap});

  final Alimento alimento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final macros = alimento.macrosPor100g;
    return Presionable(
      child: TarjetaNutri(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 14, rellenoTarjeta, 14),
        child: Row(
          children: [
            _AvatarInicial(nombre: alimento.nombre),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alimento.nombre,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_textoNumero(macros.kcal)} kcal / 100 g',
                    style: cifra(theme.textTheme.bodySmall)
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _BarraOrigenKcal(macros: macros),
          ],
        ),
      ),
    );
  }
}

/// First letter of the name on a tint picked deterministically from it.
class _AvatarInicial extends StatelessWidget {
  const _AvatarInicial({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = _tintaDeNombre(context, nombre);
    final limpio = nombre.trim();
    final inicial = limpio.isEmpty
        ? '?'
        : String.fromCharCode(limpio.runes.first).toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: fondo,
          shape: formaTarjeta(radio: 14),
        ),
        child: Text(
          inicial,
          style: TextStyle(
            fontFamily: familiaDisplay,
            fontWeight: FontWeight.w800,
            fontSize: 19,
            height: 1,
            color: texto,
          ),
        ),
      ),
    );
  }
}

/// (background, foreground) among lino / remolacha / trigo / arándano /
/// albahaca containers, by the sum of the name's char codes (stable).
(Color, Color) _tintaDeNombre(BuildContext context, String nombre) {
  final esquema = Theme.of(context).colorScheme;
  final tonos = TonosNutri.of(context);
  final oscuro = esquema.brightness == Brightness.dark;
  final suma = nombre.trim().toLowerCase().codeUnits.fold<int>(
    0,
    (total, codigo) => total + codigo,
  );
  (Color, Color) tono(Color matiz) => (
    matiz.withValues(alpha: oscuro ? 0.26 : 0.18),
    Color.lerp(matiz, esquema.onSurface, oscuro ? 0.15 : 0.4)!,
  );
  return switch (suma % 5) {
    0 => (esquema.tertiaryContainer, esquema.onTertiaryContainer),
    1 => tono(tonos.proteina),
    2 => tono(tonos.carbos),
    3 => tono(tonos.grasa),
    _ => (esquema.primaryContainer, esquema.onPrimaryContainer),
  };
}

/// 64×6 stacked bar of where the kcal come from (P×4, C×4, F×9).
/// Visual only: excluded from semantics.
class _BarraOrigenKcal extends StatelessWidget {
  const _BarraOrigenKcal({required this.macros});

  final Macros macros;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final partes = [
      (MacroVisual.proteina, macros.proteina * 4),
      (MacroVisual.carbos, macros.carbos * 4),
      (MacroVisual.grasa, macros.grasa * 9),
    ];
    final total = partes.fold<num>(0, (suma, parte) => suma + parte.$2);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Container(
          width: 64,
          height: 6,
          color: esquema.outlineVariant.withValues(alpha: 0.7),
          child: total <= 0
              ? null
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (macro, kcal) in partes)
                      if (kcal > 0)
                        Expanded(
                          flex: (kcal / total * 1000).round().clamp(1, 1000),
                          child: ColoredBox(color: macro.color(context)),
                        ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EditorAlimento extends StatefulWidget {
  const _EditorAlimento({required this.diario, this.alimento});

  final Diario diario;
  final Alimento? alimento;

  @override
  State<_EditorAlimento> createState() => _EditorAlimentoState();
}

class _EditorAlimentoState extends State<_EditorAlimento> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _kcal = TextEditingController();
  final _proteina = TextEditingController();
  final _carbos = TextEditingController();
  final _grasa = TextEditingController();
  final _patron = TextEditingController();
  final _sacudida = ControladorSacudida();
  var _guardando = false;

  @override
  void initState() {
    super.initState();
    final alimento = widget.alimento;
    if (alimento != null) {
      _nombre.text = alimento.nombre;
      _kcal.text = _textoNumero(alimento.macrosPor100g.kcal);
      _proteina.text = _textoNumero(alimento.macrosPor100g.proteina);
      _carbos.text = _textoNumero(alimento.macrosPor100g.carbos);
      _grasa.text = _textoNumero(alimento.macrosPor100g.grasa);
      _patron.text = alimento.patron;
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _kcal.dispose();
    _proteina.dispose();
    _carbos.dispose();
    _grasa.dispose();
    _patron.dispose();
    _sacudida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existente = widget.alimento;
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          existente == null ? 'Nuevo Alimento' : existente.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (existente != null)
            IconButton(
              tooltip: 'Borrar Alimento',
              onPressed: _guardando ? null : _borrar,
              icon: const Icon(IconosNutri.borrar),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: _camposSobrePapel(
          context,
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              margenPantalla,
              8,
              margenPantalla,
              entreSecciones,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TarjetaNutri(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nombre,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (valor) {
                          if ((valor ?? '').trim().isEmpty) {
                            return 'Indicá un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _campoMacro(
                        _kcal,
                        'Calorías',
                        'kcal / 100 g',
                        esquema.primary,
                      ),
                      _campoMacro(
                        _proteina,
                        'Proteína (P)',
                        'g / 100 g',
                        MacroVisual.proteina.color(context),
                      ),
                      _campoMacro(
                        _carbos,
                        'Carbos (C)',
                        'g / 100 g',
                        MacroVisual.carbos.color(context),
                      ),
                      _campoMacro(
                        _grasa,
                        'Grasa (F)',
                        'g / 100 g',
                        MacroVisual.grasa.color(context),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _patron,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Patrón',
                          helperText: 'Palabras o regex. Vacío usa el nombre.',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoMacro(
    TextEditingController controller,
    String etiqueta,
    String sufijo,
    Color matiz,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: entreRenglones),
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
      _sacudida.sacudir();
      return;
    }
    setState(() => _guardando = true);
    try {
      final macros = Macros(
        kcal: _parsearNumero(_kcal.text)!,
        proteina: _parsearNumero(_proteina.text)!,
        carbos: _parsearNumero(_carbos.text)!,
        grasa: _parsearNumero(_grasa.text)!,
      );
      final existente = widget.alimento;
      final patron = _patron.text.trim();
      if (existente == null) {
        await widget.diario.crearAlimento(
          nombre: _nombre.text.trim(),
          macrosPor100g: macros,
          patron: patron.isEmpty ? null : patron,
        );
      } else {
        await widget.diario.editarAlimento(
          id: existente.id,
          nombre: _nombre.text.trim(),
          macrosPor100g: macros,
          patron: patron,
        );
      }
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

  Future<void> _borrar() async {
    final existente = widget.alimento;
    if (existente == null) {
      return;
    }
    setState(() => _guardando = true);
    try {
      await widget.diario.eliminarAlimento(existente.id);
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
