/// NutriMezzo's design system ("Mercado") in code.
///
/// The contract is `docs/identidad-visual.md`; this file is its code. Widgets
/// read `Theme.of(context).colorScheme` for the standard roles and
/// [TonosNutri.of] for the extra ones (maíz, macro hues, papel, shadow).
library;

import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import 'diario.dart';

// ---------------------------------------------------------------------------
// Font families
// ---------------------------------------------------------------------------

/// Wide grotesque (Archivo Expanded, width 125): display numbers, screen and
/// card titles, month names, the wordmark.
const familiaDisplay = 'ArchivoExpanded';

/// Reading sans: everything you read.
const familiaDmSans = 'DMSans';

/// Mono for every number you compare in a row or column.
const familiaDmMono = 'DMMono';

// ---------------------------------------------------------------------------
// Color schemes
// ---------------------------------------------------------------------------

/// "Día de mercado": every role set explicitly (no `fromSeed`).
const esquemaClaro = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF2F6B4F),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFCDE8D4),
  onPrimaryContainer: Color(0xFF0E2F1F),
  primaryFixed: Color(0xFFCDE8D4),
  primaryFixedDim: Color(0xFF86CFA2),
  onPrimaryFixed: Color(0xFF0E2F1F),
  onPrimaryFixedVariant: Color(0xFF1F4D36),
  secondary: Color(0xFF4F6B5B),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFDCE7DE),
  onSecondaryContainer: Color(0xFF1D2620),
  secondaryFixed: Color(0xFFDCE7DE),
  secondaryFixedDim: Color(0xFFB3CCBD),
  onSecondaryFixed: Color(0xFF1D2620),
  onSecondaryFixedVariant: Color(0xFF2C3A31),
  tertiary: Color(0xFF1D2620),
  onTertiary: Color(0xFFF6F0E4),
  tertiaryContainer: Color(0xFFE6DFD0),
  onTertiaryContainer: Color(0xFF1D2620),
  tertiaryFixed: Color(0xFFE6DFD0),
  tertiaryFixedDim: Color(0xFFD4CBB8),
  onTertiaryFixed: Color(0xFF1D2620),
  onTertiaryFixedVariant: Color(0xFF2C352F),
  error: Color(0xFFC8432F),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFADAD3),
  onErrorContainer: Color(0xFF5C130A),
  surface: Color(0xFFF6F0E4),
  onSurface: Color(0xFF1D2620),
  surfaceDim: Color(0xFFE2D6BF),
  surfaceBright: Color(0xFFFFFCF5),
  surfaceContainerLowest: Color(0xFFFFFCF5),
  surfaceContainerLow: Color(0xFFF0E8D8),
  surfaceContainer: Color(0xFFEAE0CC),
  surfaceContainerHigh: Color(0xFFE2D6BF),
  surfaceContainerHighest: Color(0xFFD9CBB1),
  onSurfaceVariant: Color(0xFF5E625A),
  outline: Color(0xFFA99C84),
  outlineVariant: Color(0xFFDCD0BA),
  shadow: Color(0xFF1D2620),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF1D2620),
  onInverseSurface: Color(0xFFFFFCF5),
  inversePrimary: Color(0xFF86CFA2),
  surfaceTint: Colors.transparent,
);

/// "Sobremesa": every role set explicitly (no `fromSeed`).
const esquemaOscuro = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF86CFA2),
  onPrimary: Color(0xFF0B2918),
  primaryContainer: Color(0xFF1F4D36),
  onPrimaryContainer: Color(0xFFCDE8D4),
  primaryFixed: Color(0xFFCDE8D4),
  primaryFixedDim: Color(0xFF86CFA2),
  onPrimaryFixed: Color(0xFF0E2F1F),
  onPrimaryFixedVariant: Color(0xFF1F4D36),
  secondary: Color(0xFFB3CCBD),
  onSecondary: Color(0xFF1D2620),
  secondaryContainer: Color(0xFF2C3A31),
  onSecondaryContainer: Color(0xFFDCE7DE),
  secondaryFixed: Color(0xFFDCE7DE),
  secondaryFixedDim: Color(0xFFB3CCBD),
  onSecondaryFixed: Color(0xFF1D2620),
  onSecondaryFixedVariant: Color(0xFF2C3A31),
  tertiary: Color(0xFFEFE8DA),
  onTertiary: Color(0xFF141A16),
  tertiaryContainer: Color(0xFF2C352F),
  onTertiaryContainer: Color(0xFFEFE8DA),
  tertiaryFixed: Color(0xFFE6DFD0),
  tertiaryFixedDim: Color(0xFFD4CBB8),
  onTertiaryFixed: Color(0xFF1D2620),
  onTertiaryFixedVariant: Color(0xFF2C352F),
  error: Color(0xFFFF8A72),
  onError: Color(0xFF3B0B03),
  errorContainer: Color(0xFF6E1D12),
  onErrorContainer: Color(0xFFFADAD3),
  surface: Color(0xFF141A16),
  onSurface: Color(0xFFEFE8DA),
  surfaceDim: Color(0xFF141A16),
  surfaceBright: Color(0xFF323C34),
  surfaceContainerLowest: Color(0xFF1C231E),
  surfaceContainerLow: Color(0xFF1A201C),
  surfaceContainer: Color(0xFF212923),
  surfaceContainerHigh: Color(0xFF29322B),
  surfaceContainerHighest: Color(0xFF323C34),
  onSurfaceVariant: Color(0xFFB4B0A3),
  outline: Color(0xFF6F7A70),
  outlineVariant: Color(0xFF343E37),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFEFE8DA),
  onInverseSurface: Color(0xFF1C231E),
  inversePrimary: Color(0xFF2F6B4F),
  surfaceTint: Colors.transparent,
);

// ---------------------------------------------------------------------------
// Extra tones
// ---------------------------------------------------------------------------

/// Roles outside [ColorScheme]: maíz (Cumplimiento amarillo), the three macro
/// hues and their track tints, papel (card surface) and the card shadow.
@immutable
class TonosNutri extends ThemeExtension<TonosNutri> {
  const TonosNutri({
    required this.maiz,
    required this.onMaiz,
    required this.proteina,
    required this.carbos,
    required this.grasa,
    required this.pistaProteina,
    required this.pistaCarbos,
    required this.pistaGrasa,
    required this.papel,
    required this.sombra,
  });

  /// Cumplimiento amarillo.
  final Color maiz;

  /// Text/icons on [maiz].
  final Color onMaiz;

  /// Remolacha: the protein hue.
  final Color proteina;

  /// Trigo: the carbs hue.
  final Color carbos;

  /// Arándano: the fat hue.
  final Color grasa;

  /// Protein track (hue at 16% light / 24% dark).
  final Color pistaProteina;

  /// Carbs track (hue at 16% light / 24% dark).
  final Color pistaCarbos;

  /// Fat track (hue at 16% light / 24% dark).
  final Color pistaGrasa;

  /// Card surface (same as `surfaceContainerLowest`).
  final Color papel;

  /// Warm card shadow; empty in dark (border only).
  final List<BoxShadow> sombra;

  static const claro = TonosNutri(
    maiz: Color(0xFFE9B53F),
    onMaiz: Color(0xFF2A2006),
    proteina: Color(0xFFA63D6B),
    carbos: Color(0xFFB8901C),
    grasa: Color(0xFF4B63A8),
    pistaProteina: Color(0x29A63D6B),
    pistaCarbos: Color(0x29B8901C),
    pistaGrasa: Color(0x294B63A8),
    papel: Color(0xFFFFFCF5),
    sombra: [
      BoxShadow(color: Color(0x0A1D2620), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(
        color: Color(0x121D2620),
        blurRadius: 24,
        spreadRadius: -8,
        offset: Offset(0, 10),
      ),
    ],
  );

  static const oscuro = TonosNutri(
    maiz: Color(0xFFF2C760),
    onMaiz: Color(0xFF2A2006),
    proteina: Color(0xFFE77FA9),
    carbos: Color(0xFFE2BE55),
    grasa: Color(0xFF8EA6EA),
    pistaProteina: Color(0x3DE77FA9),
    pistaCarbos: Color(0x3DE2BE55),
    pistaGrasa: Color(0x3D8EA6EA),
    papel: Color(0xFF1C231E),
    sombra: [],
  );

  /// The tones of the current theme (falls back by brightness if missing).
  static TonosNutri of(BuildContext context) {
    final tema = Theme.of(context);
    return tema.extension<TonosNutri>() ??
        (tema.brightness == Brightness.dark ? oscuro : claro);
  }

  @override
  TonosNutri copyWith({
    Color? maiz,
    Color? onMaiz,
    Color? proteina,
    Color? carbos,
    Color? grasa,
    Color? pistaProteina,
    Color? pistaCarbos,
    Color? pistaGrasa,
    Color? papel,
    List<BoxShadow>? sombra,
  }) {
    return TonosNutri(
      maiz: maiz ?? this.maiz,
      onMaiz: onMaiz ?? this.onMaiz,
      proteina: proteina ?? this.proteina,
      carbos: carbos ?? this.carbos,
      grasa: grasa ?? this.grasa,
      pistaProteina: pistaProteina ?? this.pistaProteina,
      pistaCarbos: pistaCarbos ?? this.pistaCarbos,
      pistaGrasa: pistaGrasa ?? this.pistaGrasa,
      papel: papel ?? this.papel,
      sombra: sombra ?? this.sombra,
    );
  }

  @override
  TonosNutri lerp(TonosNutri? other, double t) {
    if (other == null) {
      return this;
    }
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return TonosNutri(
      maiz: c(maiz, other.maiz),
      onMaiz: c(onMaiz, other.onMaiz),
      proteina: c(proteina, other.proteina),
      carbos: c(carbos, other.carbos),
      grasa: c(grasa, other.grasa),
      pistaProteina: c(pistaProteina, other.pistaProteina),
      pistaCarbos: c(pistaCarbos, other.pistaCarbos),
      pistaGrasa: c(pistaGrasa, other.pistaGrasa),
      papel: c(papel, other.papel),
      sombra: BoxShadow.lerpList(sombra, other.sombra, t) ?? const [],
    );
  }
}

// ---------------------------------------------------------------------------
// Type
// ---------------------------------------------------------------------------

TextStyle _estilo(
  String familia,
  FontWeight peso,
  double tamano,
  double alto,
  double tracking, {
  FontStyle? estilo,
}) {
  return TextStyle(
    fontFamily: familia,
    fontWeight: peso,
    fontSize: tamano,
    height: alto,
    letterSpacing: tracking,
    fontStyle: estilo,
  );
}

/// The doc's type table, uncolored (the theme applies `onSurface`).
TextTheme textoNutri() {
  const f = familiaDisplay;
  const s = familiaDmSans;
  return TextTheme(
    displayLarge: _estilo(f, FontWeight.w800, 48, 1.0, -1.5),
    displayMedium: _estilo(f, FontWeight.w800, 38, 1.05, -1.0),
    displaySmall: _estilo(f, FontWeight.w800, 32, 1.1, -0.8),
    headlineLarge: _estilo(f, FontWeight.w800, 28, 1.15, -0.6),
    headlineMedium: _estilo(f, FontWeight.w800, 24, 1.2, -0.5),
    headlineSmall: _estilo(f, FontWeight.w700, 20, 1.25, -0.4),
    titleLarge: _estilo(f, FontWeight.w700, 18, 1.25, -0.3),
    titleMedium: _estilo(s, FontWeight.w600, 16, 1.35, 0),
    titleSmall: _estilo(s, FontWeight.w600, 14, 1.35, 0.1),
    bodyLarge: _estilo(s, FontWeight.w400, 16, 1.5, 0),
    bodyMedium: _estilo(s, FontWeight.w400, 14, 1.45, 0),
    bodySmall: _estilo(s, FontWeight.w400, 12, 1.4, 0.1),
    labelLarge: _estilo(s, FontWeight.w600, 14, 1.2, 0.2),
    labelMedium: _estilo(s, FontWeight.w600, 12, 1.2, 0.4),
    labelSmall: _estilo(s, FontWeight.w500, 11, 1.2, 0.6),
  );
}

/// [base] (size, color, height) re-set in DM Mono Medium with tabular digits,
/// for numbers compared in rows/columns or tweened.
TextStyle cifra(TextStyle? base) {
  return (base ?? const TextStyle()).copyWith(
    fontFamily: familiaDmMono,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.normal,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// The eyebrow: DM Sans SemiBold 12, tracking 1.4, `onSurfaceVariant`.
/// Small section labels and the date line. Keeps the text's case.
TextStyle ceja(BuildContext context) {
  return TextStyle(
    fontFamily: familiaDmSans,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.3,
    letterSpacing: 1.4,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

// ---------------------------------------------------------------------------
// Shape
// ---------------------------------------------------------------------------

/// Hero card radius.
const radioHeroe = 32.0;

/// Content card radius.
const radioTarjeta = 24.0;

/// Popups and sheets radius.
const radioPopup = 18.0;

/// Inputs radius.
const radioCampo = 16.0;

/// Screen gutter / card padding / between sections / between rows in a card.
const margenPantalla = 20.0;
const rellenoTarjeta = 20.0;
const entreSecciones = 24.0;
const entreRenglones = 12.0;

/// Superellipse card shape with radius [radio] and an optional [lado].
ShapeBorder formaTarjeta({
  double radio = radioTarjeta,
  BorderSide lado = BorderSide.none,
}) {
  return RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(radio),
    side: lado,
  );
}

/// The card hairline: `outlineVariant` at 70%, 1 px.
BorderSide hiloTarjeta(BuildContext context) {
  return BorderSide(
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.7),
  );
}

/// Papel surface + superellipse + hairline + warm shadow (light only).
///
/// The one owner of card depth. Use [radio] 32 for the hero card (and set
/// [brillo] for its faint `primary` glow from the top-right corner), 24 for
/// content cards. [onTap] adds an InkWell clipped to the shape. [color]
/// overrides papel (e.g. a tinted container card).
class TarjetaNutri extends StatelessWidget {
  const TarjetaNutri({
    super.key,
    required this.child,
    this.radio = radioTarjeta,
    this.padding = const EdgeInsets.all(rellenoTarjeta),
    this.brillo = false,
    this.color,
    this.onTap,
  });

  final Widget child;
  final double radio;
  final EdgeInsetsGeometry? padding;
  final bool brillo;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tonos = TonosNutri.of(context);
    final esquema = Theme.of(context).colorScheme;
    final forma = formaTarjeta(radio: radio, lado: hiloTarjeta(context));
    Widget contenido = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    if (onTap != null) {
      contenido = InkWell(
        onTap: onTap,
        customBorder: formaTarjeta(radio: radio),
        child: contenido,
      );
    }
    contenido = Material(type: MaterialType.transparency, child: contenido);
    if (brillo) {
      contenido = DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [
              esquema.primary.withValues(alpha: 0.08),
              esquema.primary.withValues(alpha: 0),
            ],
          ),
        ),
        child: contenido,
      );
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? tonos.papel,
        shape: forma,
        shadows: tonos.sombra,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: formaTarjeta(radio: radio)),
        child: contenido,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Themes
// ---------------------------------------------------------------------------

/// Light theme ("Día de mercado").
ThemeData temaClaro() => _tema(esquemaClaro, TonosNutri.claro);

/// Dark theme ("Sobremesa").
ThemeData temaOscuro() => _tema(esquemaOscuro, TonosNutri.oscuro);

ThemeData _tema(ColorScheme esquema, TonosNutri tonos) {
  final texto = textoNutri().apply(
    bodyColor: esquema.onSurface,
    displayColor: esquema.onSurface,
  );
  const estadio = StadiumBorder();
  final formaPopup = formaTarjeta(radio: radioPopup);
  // Filled fields with a rounded underline border: the floating label stays
  // inside the fill instead of sitting on an invisible outline's notch.
  UnderlineInputBorder borde(BorderSide lado) => UnderlineInputBorder(
    borderRadius: BorderRadius.circular(radioCampo),
    borderSide: lado,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: esquema.brightness,
    colorScheme: esquema,
    fontFamily: familiaDmSans,
    textTheme: texto,
    scaffoldBackgroundColor: esquema.surface,
    canvasColor: esquema.surface,
    splashFactory: InkSparkle.splashFactory,
    extensions: [tonos],
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final plataforma in TargetPlatform.values)
          plataforma: const SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: esquema.surface,
      foregroundColor: esquema.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: texto.titleLarge!.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 23,
        letterSpacing: -0.6,
      ),
      iconTheme: IconThemeData(color: esquema.onSurface),
      actionsIconTheme: IconThemeData(color: esquema.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tonos.papel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 76,
      indicatorColor: esquema.primaryContainer,
      indicatorShape: estadio,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => texto.labelMedium!.copyWith(
          color: estados.contains(WidgetState.selected)
              ? esquema.onSurface
              : esquema.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          size: 24,
          color: estados.contains(WidgetState.selected)
              ? esquema.onPrimaryContainer
              : esquema.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: estadio,
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: texto.labelLarge!.copyWith(fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: estadio, textStyle: texto.labelLarge),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: estadio,
        textStyle: texto.labelLarge,
        side: BorderSide(color: esquema.outline),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: esquema.onSurface),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: esquema.tertiary,
      foregroundColor: esquema.onTertiary,
      shape: estadio,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      extendedTextStyle: texto.labelLarge!.copyWith(fontSize: 16),
    ),
    chipTheme: ChipThemeData(
      shape: estadio,
      backgroundColor: tonos.papel,
      selectedColor: esquema.tertiary,
      secondarySelectedColor: esquema.tertiary,
      checkmarkColor: esquema.onTertiary,
      labelStyle: texto.labelLarge!.copyWith(color: esquema.onSurface),
      secondaryLabelStyle: texto.labelLarge!.copyWith(
        color: esquema.onTertiary,
      ),
      side: BorderSide(color: esquema.outlineVariant),
      surfaceTintColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      // Fields usually sit on papel cards; in dark, surfaceContainerLow is
      // almost papel, so step up to keep the field visible.
      fillColor: esquema.brightness == Brightness.dark
          ? esquema.surfaceContainerHigh
          : esquema.surfaceContainerLow,
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      border: borde(BorderSide.none),
      enabledBorder: borde(BorderSide.none),
      disabledBorder: borde(BorderSide.none),
      focusedBorder: borde(BorderSide(color: esquema.primary, width: 2)),
      errorBorder: borde(BorderSide(color: esquema.error)),
      focusedErrorBorder: borde(BorderSide(color: esquema.error, width: 2)),
      labelStyle: texto.bodyMedium!.copyWith(color: esquema.onSurfaceVariant),
      hintStyle: texto.bodyLarge!.copyWith(color: esquema.onSurfaceVariant),
      errorStyle: texto.bodySmall!.copyWith(color: esquema.error),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: tonos.papel,
      surfaceTintColor: Colors.transparent,
      shape: formaPopup,
      elevation: 3,
      textStyle: texto.bodyLarge,
      labelTextStyle: WidgetStatePropertyAll(texto.bodyLarge),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: esquema.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: texto.bodySmall!.copyWith(color: esquema.onInverseSurface),
    ),
    dividerTheme: DividerThemeData(
      color: esquema.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: esquema.primary,
      linearTrackColor: esquema.primary.withValues(alpha: 0.12),
      circularTrackColor: esquema.primary.withValues(alpha: 0.12),
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(4),
    ),
    cardTheme: CardThemeData(
      color: tonos.papel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: formaTarjeta(lado: BorderSide(color: esquema.outlineVariant)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: esquema.onSurfaceVariant,
      titleTextStyle: texto.titleMedium,
      subtitleTextStyle: texto.bodySmall!.copyWith(
        color: esquema.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tonos.papel,
      surfaceTintColor: Colors.transparent,
      shape: formaTarjeta(radio: radioPopup),
      titleTextStyle: texto.headlineSmall,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tonos.papel,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radioPopup)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: esquema.inverseSurface,
      contentTextStyle: texto.bodyMedium!.copyWith(
        color: esquema.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: formaTarjeta(radio: radioCampo),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected)
            ? esquema.primary
            : esquema.outline,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Icons and domain → visual mapping
// ---------------------------------------------------------------------------

/// The app's icons: Lucide (`lucide_icons_flutter`), regular stroke for
/// chrome. The "selected"/badge variants use the heavier 600 stroke, which
/// stands in for the design doc's Phosphor duotone (see the Iconography
/// section). All are plain [IconData]: use them in an `Icon`.
abstract final class IconosNutri {
  static const dia = LucideIcons.sun;
  static const diaSeleccionado = LucideIcons600.sun;
  static const cumplimiento = LucideIcons.calendarCheck;
  static const cumplimientoSeleccionado = LucideIcons600.calendarCheck;
  static const pesaje = LucideIcons.weight;
  static const pesajeSeleccionado = LucideIcons600.weight;
  static const catalogo = LucideIcons.bookOpenText;
  static const ajustes = LucideIcons.settings;
  static const anterior = LucideIcons.chevronLeft;
  static const siguiente = LucideIcons.chevronRight;
  static const desplegar = LucideIcons.chevronDown;
  static const menu = LucideIcons.ellipsisVertical;
  static const comida = LucideIcons.notebookPen;
  static const crear = LucideIcons.plus;
  static const borrar = LucideIcons.trash2;
  static const cerrar = LucideIcons.x;
  static const baja = LucideIcons.arrowDown;
  static const sube = LucideIcons.arrowUp;
  static const manana = LucideIcons.sunrise;
  static const origenCatalogo = LucideIcons.bookOpenText;
  static const origenIa = LucideIcons.sparkles;
  static const clave = LucideIcons.keyRound;
}

/// The Momento badge icon (coffee / utensils / moonStar / cookie).
/// [grueso] returns the heavier 600 stroke (badges, selected chips).
IconData iconoDeMomento(Momento momento, {bool grueso = false}) {
  if (grueso) {
    return switch (momento) {
      Momento.desayuno => LucideIcons600.coffee,
      Momento.almuerzo => LucideIcons600.utensils,
      Momento.cena => LucideIcons600.moonStar,
      Momento.extra => LucideIcons600.cookie,
    };
  }
  return switch (momento) {
    Momento.desayuno => LucideIcons.coffee,
    Momento.almuerzo => LucideIcons.utensils,
    Momento.cena => LucideIcons.moonStar,
    Momento.extra => LucideIcons.cookie,
  };
}

/// The four Macros as visuals. kcal has no macro hue: it is `primary`
/// (albahaca) until it overflows into `error`.
enum MacroVisual {
  kcal,
  proteina,
  carbos,
  grasa;

  /// The hue: `primary` for kcal, remolacha / trigo / arándano otherwise.
  Color color(BuildContext context) {
    final tonos = TonosNutri.of(context);
    return switch (this) {
      kcal => Theme.of(context).colorScheme.primary,
      proteina => tonos.proteina,
      carbos => tonos.carbos,
      grasa => tonos.grasa,
    };
  }

  /// The track behind a bar/ring: the hue at 16% (24% dark); kcal at 12%.
  Color pista(BuildContext context) {
    final tonos = TonosNutri.of(context);
    return switch (this) {
      kcal => Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      proteina => tonos.pistaProteina,
      carbos => tonos.pistaCarbos,
      grasa => tonos.pistaGrasa,
    };
  }

  /// Regular glyph: flame / egg / wheat / droplet.
  IconData get icono => switch (this) {
    kcal => LucideIcons.flame,
    proteina => LucideIcons.egg,
    carbos => LucideIcons.wheat,
    grasa => LucideIcons.droplet,
  };

  /// Heavier (600) glyph for badges, in place of duotone.
  IconData get iconoGrueso => switch (this) {
    kcal => LucideIcons600.flame,
    proteina => LucideIcons600.egg,
    carbos => LucideIcons600.wheat,
    grasa => LucideIcons600.droplet,
  };
}

/// Shorthand for [MacroVisual.color].
Color colorDeMacro(BuildContext context, MacroVisual macro) =>
    macro.color(context);

/// Shorthand for [MacroVisual.pista].
Color pistaDeMacro(BuildContext context, MacroVisual macro) =>
    macro.pista(context);

/// Fill and on-color for a Cumplimiento cell: verde = primary, amarillo =
/// maíz, rojo = error; ninguno = no fill (`null`) with `onSurface`.
({Color? fondo, Color texto}) coloresDeCumplimiento(
  BuildContext context,
  Cumplimiento cumplimiento,
) {
  final esquema = Theme.of(context).colorScheme;
  final tonos = TonosNutri.of(context);
  return switch (cumplimiento) {
    Cumplimiento.verde => (fondo: esquema.primary, texto: esquema.onPrimary),
    Cumplimiento.amarillo => (fondo: tonos.maiz, texto: tonos.onMaiz),
    Cumplimiento.rojo => (fondo: esquema.error, texto: esquema.onError),
    Cumplimiento.ninguno => (fondo: null, texto: esquema.onSurface),
  };
}

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------

/// Paints `assets/marca/marca.svg` (viewBox 1024) scaled to the canvas:
/// basil ring, ink half-full bowl (cream in dark), two-leaf sprout.
class PintorMarca extends CustomPainter {
  const PintorMarca({required this.anillo, required this.cuenco});

  /// Ring and sprout color (`primary`).
  final Color anillo;

  /// Bowl color (`onSurface`: ink in light, cream in dark).
  final Color cuenco;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = math.min(size.width, size.height) / 1024;
    canvas.save();
    canvas.translate(
      (size.width - 1024 * escala) / 2,
      (size.height - 1024 * escala) / 2,
    );
    canvas.scale(escala);

    final trazo = Paint()
      ..color = anillo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 72;
    canvas.drawCircle(const Offset(512, 512), 372, trazo);

    final bol = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(512, 548), radius: 250),
        0,
        math.pi,
      )
      ..close();
    canvas.drawPath(bol, Paint()..color = cuenco);

    canvas.drawLine(
      const Offset(512, 548),
      const Offset(512, 430),
      Paint()
        ..color = anillo
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round,
    );

    final hojas = Path()
      ..moveTo(512, 440)
      ..cubicTo(500, 360, 430, 320, 372, 334)
      ..cubicTo(384, 400, 440, 446, 512, 440)
      ..close()
      ..moveTo(512, 410)
      ..cubicTo(520, 330, 590, 284, 660, 296)
      ..cubicTo(650, 370, 590, 418, 512, 410)
      ..close();
    canvas.drawPath(hojas, Paint()..color = anillo);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorMarca oldDelegate) =>
      oldDelegate.anillo != anillo || oldDelegate.cuenco != cuenco;
}

/// The NutriMezzo mark, themed (`primary` + `onSurface`), [tamano] square.
class MarcaNutriMezzo extends StatelessWidget {
  const MarcaNutriMezzo({super.key, this.tamano = 48});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: tamano,
      child: CustomPaint(
        painter: PintorMarca(
          anillo: esquema.primary,
          cuenco: esquema.onSurface,
        ),
      ),
    );
  }
}

/// Paints the mark's plate drawn empty: the ring plus a faint inner fill.
class PintorPlatoVacio extends CustomPainter {
  const PintorPlatoVacio({required this.anillo, required this.relleno});

  final Color anillo;
  final Color relleno;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = math.min(size.width, size.height) / 1024;
    final centro = size.center(Offset.zero);
    canvas.drawCircle(centro, 336 * escala, Paint()..color = relleno);
    canvas.drawCircle(
      centro,
      372 * escala,
      Paint()
        ..color = anillo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 72 * escala,
    );
  }

  @override
  bool shouldRepaint(PintorPlatoVacio oldDelegate) =>
      oldDelegate.anillo != anillo || oldDelegate.relleno != relleno;
}

/// Empty-plate illustration for empty states (Día without Comida, empty
/// Catálogo). [tamano] defaults to 112.
class PlatoVacio extends StatelessWidget {
  const PlatoVacio({super.key, this.tamano = 112});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: tamano,
      child: CustomPaint(
        painter: PintorPlatoVacio(
          anillo: esquema.primary.withValues(alpha: 0.45),
          relleno: esquema.primary.withValues(alpha: 0.07),
        ),
      ),
    );
  }
}

/// The wordmark, lowercase, no space, all Archivo Expanded ExtraBold:
/// "nutri" in `onSurface` + "mezzo" in `primary`.
class PalabraMarca extends StatelessWidget {
  const PalabraMarca({super.key, this.tamano = 22});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'nutri',
            style: TextStyle(color: esquema.onSurface),
          ),
          TextSpan(
            text: 'mezzo',
            style: TextStyle(color: esquema.primary),
          ),
        ],
      ),
      style: TextStyle(
        fontFamily: familiaDisplay,
        fontWeight: FontWeight.w800,
        fontSize: tamano,
        height: 1.1,
        letterSpacing: -0.04 * tamano,
      ),
      semanticsLabel: 'NutriMezzo',
    );
  }
}
