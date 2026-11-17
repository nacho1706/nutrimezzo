# Identidad visual — "Mercado"

The design contract for NutriMezzo's look and motion. Decisions live here; `lib/tema.dart` and `lib/motion.dart` are their code. Why motion is allowed is in ADR-0011 (and the honesty rule it keeps from ADR-0007).

## Concept

NutriMezzo = nutrición + *mezzo* (the middle, balance). The app should feel like a kitchen notebook on a market table: warm paper, ink, basil; a wide grotesque from a Buenos Aires foundry for the moments that matter (like a price sign at the almacén), a clean sans for everything you read, a mono for every number you compare. Avoid the generic "AI warm editorial" look: no soft display serif, no tangerine/terracotta accent. Not a clinical dashboard, not a neon gym app.

Three rules decide close calls:

1. **Numbers are the heroes.** Big, serif, calm. Units and labels step back.
2. **Color means something.** Each macro owns one hue everywhere; Cumplimiento owns verde/amarillo/rojo; ink (tinta) is the action color. There is no orange anywhere. Never use a macro hue for a state or a state hue for decoration.
3. **Motion explains or acknowledges.** It shows where you went, what changed, or that the app heard you. It never invents data (ADR-0011).

## Mark

`assets/marca/marca.svg`: a plate (basil ring) holding a half-full bowl (ink half-disc; cream in dark) with a two-leaf basil sprout. Half full = *mezzo*. Raster exports in `assets/marca/` feed the launcher icon and splash. In-app, draw it with a `CustomPainter` (`MarcaNutriMezzo`) so it scales and themes; do not ship an SVG renderer for it.

Wordmark: `nutrimezzo` in Archivo Expanded ExtraBold, lowercase, no space: `nutri` in `onSurface`, `mezzo` in `primary`.

## Color tokens

Light theme is "Día de mercado", dark is "Sobremesa". Use `ColorScheme` roles in widgets; the extra roles live in a `ThemeExtension` (`TonosNutri`).

| Token | Role | Light | Dark |
|---|---|---|---|
| masa | `surface` (scaffold) | `#F6F0E4` | `#141A16` |
| papel | `surfaceContainerLowest` (cards) | `#FFFCF5` | `#1C231E` |
| — | `surfaceContainerLow` | `#F0E8D8` | `#1A201C` |
| — | `surfaceContainer` | `#EAE0CC` | `#212923` |
| — | `surfaceContainerHigh` | `#E2D6BF` | `#29322B` |
| — | `surfaceContainerHighest` | `#D9CBB1` | `#323C34` |
| tinta | `onSurface` | `#1D2620` | `#EFE8DA` |
| tinta suave | `onSurfaceVariant` | `#5E625A` | `#B4B0A3` |
| — | `outline` | `#A99C84` | `#6F7A70` |
| — | `outlineVariant` | `#DCD0BA` | `#343E37` |
| albahaca | `primary` / on | `#2F6B4F` / `#FFFFFF` | `#86CFA2` / `#0B2918` |
| — | `primaryContainer` / on | `#CDE8D4` / `#0E2F1F` | `#1F4D36` / `#CDE8D4` |
| tinta (acción) | `tertiary` / on | `#1D2620` / `#F6F0E4` | `#EFE8DA` / `#141A16` |
| lino | `tertiaryContainer` / on | `#E6DFD0` / `#1D2620` | `#2C352F` / `#EFE8DA` |
| tomate | `error` / on | `#C8432F` / `#FFFFFF` | `#FF8A72` / `#3B0B03` |
| — | `errorContainer` / on | `#FADAD3` / `#5C130A` | `#6E1D12` / `#FADAD3` |
| maíz | `TonosNutri.maiz` / on | `#E9B53F` / `#2A2006` | `#F2C760` / `#2A2006` |
| remolacha | `TonosNutri.proteina` | `#A63D6B` | `#E77FA9` |
| trigo | `TonosNutri.carbos` | `#B8901C` | `#E2BE55` |
| arándano | `TonosNutri.grasa` | `#4B63A8` | `#8EA6EA` |

`secondary` = albahaca slightly desaturated (`#4F6B5B` light / `#B3CCBD` dark), `secondaryContainer` = `#DCE7DE` / `#2C3A31`. Set every role explicitly; do not rely on `fromSeed` for these.

Meaning:

- **Cumplimiento**: verde = albahaca (`primary`), amarillo = maíz, rojo = tomate (`error`). Only for Cumplimiento cells, the ring's overflow, and the Promedio's up arrow.
- **Macros**: proteína = remolacha, carbos = trigo, grasa = arándano. kcal has no macro hue: the ring is albahaca until it overflows into tomate. A macro's track is its hue at 16% alpha (24% in dark).
- **Action**: tinta (`tertiary`) for the creation actions (Comida, Crear) and the selected Momento chip — an ink pill with cream text, cream with ink text in dark. Lino (`tertiaryContainer`) is the neutral warm container for Momento badges, origin badges and the Crear Alimento block. Small highlights (today dot, ring bead) use ink or the arc's own color, never a new hue. Primary confirm buttons (Guardar, Confirmar) are albahaca filled pills.

## Type

Bundled in `assets/fonts/` (OFL, licenses alongside). Never fetched at runtime.

- **Archivo Expanded** (Omnibus-Type, Buenos Aires; width 125 instances): SemiBold, Bold, ExtraBold. Display numbers, screen titles, card titles, month names, the wordmark. It is wide, so sizes are smaller than a serif would need and tracking is slightly negative.
- **DM Sans**: Regular, Medium, SemiBold, Bold. Everything you read.
- **DM Mono**: Regular, Medium. Every number you compare in a row or column (grams, kcal in rows, macro values, calendar kg, Promedio delta). Monospace keeps digits from jittering during tweens.

`TextTheme` mapping:

| Style | Family / weight | Size / height | Tracking |
|---|---|---|---|
| displayLarge | Archivo Expanded ExtraBold | 48 / 1.0 | -1.5 |
| displayMedium | Archivo Expanded ExtraBold | 38 / 1.05 | -1.0 |
| displaySmall | Archivo Expanded ExtraBold | 32 / 1.1 | -0.8 |
| headlineLarge | Archivo Expanded ExtraBold | 28 / 1.15 | -0.6 |
| headlineMedium | Archivo Expanded ExtraBold | 24 / 1.2 | -0.5 |
| headlineSmall | Archivo Expanded Bold | 20 / 1.25 | -0.4 |
| titleLarge | Archivo Expanded Bold | 18 / 1.25 | -0.3 |
| titleMedium | DM Sans SemiBold | 16 / 1.35 | 0 |
| titleSmall | DM Sans SemiBold | 14 / 1.35 | 0.1 |
| bodyLarge | DM Sans Regular | 16 / 1.5 | 0 |
| bodyMedium | DM Sans Regular | 14 / 1.45 | 0 |
| bodySmall | DM Sans Regular | 12 / 1.4 | 0.1 |
| labelLarge | DM Sans SemiBold | 14 / 1.2 | 0.2 |
| labelMedium | DM Sans SemiBold | 12 / 1.2 | 0.4 |
| labelSmall | DM Sans Medium | 11 / 1.2 | 0.6 |

Helpers in `tema.dart`: `cifra(TextStyle?)` → same size in DM Mono Medium; `ceja(BuildContext)` → the eyebrow (DM Sans SemiBold 12, tracking 1.4, `onSurfaceVariant`) for small section labels and the date line. Text strings keep their existing case (tests and copy depend on it); the eyebrow is tracking, not uppercase.

## Shape, depth, spacing

- Cards: `RoundedSuperellipseBorder` (built into Flutter). Radius 32 hero card, 24 content cards, 18 popups/sheets, 16 inputs. Buttons, chips, nav indicator, small badges: `StadiumBorder`.
- Depth: no Material elevation tint. Light: a warm soft shadow (`tinta` at 6%, blur 24, y 8) plus a hairline border in `outlineVariant` at 70%. Dark: border only, no shadow. One helper (`decoracionTarjeta` / `TarjetaNutri`) owns this.
- Spacing on a 4-pt grid. Screen gutter 20. Card padding 20. Between sections 24. Between rows inside a card 12.
- Background: scaffold is masa. The Día hero card carries a faint radial glow of `primary` (8% → 0) from its top-right corner; nothing else uses gradients.

## Iconography

**Deviation (phase 1):** `phosphor_flutter` 2.1.0 does not compile on Flutter 3.47 (`IconData` is now a `final` class and the package subclasses it), so the app uses **`lucide_icons_flutter`** (Lucide). Lucide has no duotone; the heavier **600 stroke** (`LucideIcons600`) stands in for duotone/fill on selected nav destinations and badges. All names below live in `IconosNutri`, `iconoDeMomento` and `MacroVisual` in `lib/tema.dart`.

Regular stroke for chrome, 600 stroke for selected nav destinations and badges. Momento badges: desayuno `coffee`, almuerzo `utensils` (Phosphor `forkKnife`), cena `moonStar`, extra `cookie`. Macros: proteína `egg`, carbos `wheat` (Phosphor `grains`), grasa `droplet`; kcal `flame`. Nav: Día `sun`, Cumplimiento `calendarCheck`, Pesaje `weight` (Phosphor `scales`). App bar: Catálogo `bookOpenText`, Ajustes `settings` (Phosphor `gearSix`), day/month arrows `chevronLeft`/`chevronRight`, Momento caret `chevronDown`, popup `ellipsisVertical`. Promedio arrows `arrowDown`/`arrowUp`. Comida FAB `notebookPen`. Pesaje hint `sunrise` (Phosphor `sunHorizon`). Propuesta origin: Catálogo `bookOpenText`, IA `sparkles`. BYOK `keyRound`. Where a screen spec below names a Phosphor icon, use the Lucide equivalent listed here.

## Motion system

All of it goes through `lib/motion.dart`; every duration is zero under `disableAnimations`.

| Token | Duration | Curve | Used for |
|---|---|---|---|
| corto | 150 ms | `easeOutCubic` | press scale, chip/selection |
| medio | 250 ms | `easeOutCubic` | existing tweens, Renglón enter, unfold, chevron |
| largo | 400 ms | emphasized `Cubic(0.2, 0, 0, 1)` | routes, fade-through, Día/month slide, container transform |
| enfasis | 700 ms | `easeOutCubic` | the one-shot verde acknowledgement |

Inventory:

- **Routes**: `SharedAxisPageTransitionsBuilder` (horizontal) for every platform in `pageTransitionsTheme`.
- **Destinations** (Día / Cumplimiento / Pesaje): `PageTransitionSwitcher` + `FadeThroughTransition`.
- **Día change** (chevrons): `PageTransitionSwitcher` + `SharedAxisTransition` horizontal, reversed for the previous Día. The whole body slides; the ring of the new Día appears at its final value. Opening a fecha from Cumplimiento uses the destination fade-through, not the slide.
- **Month change** (both calendars): same horizontal shared axis, direction from the chevron.
- **Comida button → Captura**: `OpenContainer` container transform from the pill FAB.
- **Press**: `Presionable` scales its child to 0.97 on press, back on release (corto). Momento cards, Catálogo cards, Propuesta cards.
- **Validation shake**: when Confirmar or a Guardar fails validation, shake the button horizontally (flutter_animate `shake`, 3 cycles, 6 px) and give a heavy haptic.
- **Catálogo**: cards enter staggered (fade + slideY 0.06, 40 ms apart, at most the first 10) when the screen opens.
- **Verde acknowledgement**: when a confirm or edit on the shown Día turns its Cumplimiento into verde (from anything else, same fecha), the ring emits one soft expanding halo in `primary` and a medium haptic. Never on first paint, date change, or when it was already verde.
- **Haptics**: `selectionClick` on nav, chips, Momento fold, calendar day taps; `lightImpact` on Guardar/Confirmar success; `heavyImpact` on validation failure.

Unchanged from ADR-0007: same-Día tweens of ring/bars/numbers with `TweenAnimationBuilder`; no fill-from-zero; Renglones opaque on first paint and date change; folding removes Renglones immediately.

## Screens

Keep every existing string, tooltip, semantics label, key, and widget type that tests use unless this section changes it on purpose. Where the visible text changes, keep the old string as the `Semantics` label and point tests at `find.bySemanticsLabel`.

### Shell (HomeDia)

- `AppBar`: masa background, no scroll tint, `centerTitle: false`, title in Archivo Expanded ExtraBold 23, tracking -0.6. Arrows and actions are `IconosNutri` icons, same tooltips.
- `NavigationBar`: papel background with a top hairline, height 76, stadium indicator in `primaryContainer`, `IconosNutri` icons (regular → 600 stroke when selected), labels always shown in labelMedium.
- FAB "Comida": `OpenContainer` whose closed child is an extended stadium button in tinta (`tertiary`) with `onTertiary` text and `IconosNutri.comida`. A soft ink `BoxShadow` at ~18% (light only) instead of Material elevation. Under reduced motion the button pushes Captura on a plain route: `OpenContainer` never restores its closed child when its duration is zero.

### Día

Top to bottom, left-aligned except the ring:

1. Date line in the eyebrow style ("martes 17 de noviembre", same text as today).
2. **Hero card** (papel, radius 32, radial glow): "Contra la Meta" in headlineSmall. The ring (`AnilloKcal`, 228 px, stroke 18):
   - Track: `primary` at 12% with 10 short tick marks (one per 10% of the Meta) in `outlineVariant`.
   - Progress arc: sweep gradient from `primary` to `primary` lightened 18%, round caps, with a **bead** at the arc's end (papel fill, 3 px ring in the arc color, radius 10).
   - Overflow: arc in `error` from the top, with its own bead.
   - Center: the consumed kcal rounded, displayLarge Archivo Expanded; under it "de 2000 kcal" in bodyMedium `onSurfaceVariant`; under that a stadium pill — "quedan 832" (`primaryContainer`) or "+168 de más" (`errorContainer`). Wrap the center in `Semantics(label: '<consumido 1 dec> / <objetivo 1 dec> kcal', excludeSemantics: true)` so the accessible text equals today's string.
   - `PintorAnilloKcal` keeps its `progreso` field.
3. Inside the same card, under a dashed hairline: the three macro rows. Each row: a 28 px circle in the macro tint with its icon, label ("Proteína (P)" etc., unchanged), value in `cifra` right-aligned ("62 / 150 g", unchanged text), and below it a 8 px rounded `LinearProgressIndicator` (keep the type) in the macro hue over its track.
4. **Momento cards** (papel, radius 24, 12 between them): header row = Momento badge (40 px circle, `tertiaryContainer`, 600-stroke icon in `onTertiaryContainer`), title in titleLarge Archivo Expanded, kcal in `cifra` titleMedium (text unchanged, e.g. "97.0 kcal"), rotating caret, the popup menu (`PopupMenuButton<String>`, `IconosNutri.menu`). No left color bar. Renglones read like a menu card: name, a dotted leader that fills the gap, grams in `cifra` ("100 g", unchanged). Expanded Macros of a Renglón: a 2×2 grid of small tiles (label + value, a 3 px top accent in the macro hue; Calorías tile uses `primary`).
5. **Empty Día** (no Comida): the mark's plate drawn empty (`PlatoVacio`) beside "Plato vacío" in titleLarge and "Tocá Comida para anotar lo que comiste." in bodyMedium `onSurfaceVariant`, below the hero card. Side by side, not stacked, so the Comida button never covers the copy.

### Cumplimiento

- Month header: caret buttons inside 40 px tonal circles; title "septiembre 2026" as one `Text.rich`: month in headlineSmall Archivo Expanded, year in titleMedium `onSurfaceVariant`.
- Weekday header in labelMedium `onSurfaceVariant`, text unchanged ("lun").
- Cells: 42 px circles. verde = `primary` fill + `onPrimary` number; amarillo = maíz + `onMaiz`; rojo = `error` + `onError`; ninguno = no fill, `onSurface` number. Today: a 5 px dot under the number in the cell's text color (ink on an empty cell). Selected: 2 px `onSurface` ring with 2 px gap.
- Legend under the grid, a `Wrap` of three items (8 px dot + labelMedium): "Dentro de la Meta", "Falta proteína", "Kcal de más".
- Whole calendar sits in a papel card (radius 24).

### Pesaje

- **Scale card** (papel, radius 32): the kg `TextField` stays 220 px wide, borderless, centered, displayMedium Archivo Expanded, suffix "kg" in titleMedium `onSurfaceVariant`. Above the field, the selected Día's date in the eyebrow style so you know which day you're weighing; under it the hint with `IconosNutri.manana`. An empty field shows a faint "00.0" hint, like a scale at rest. "Guardar" stays a `FilledButton` (albahaca pill).
- Calendar card with square cells: a Día with a Pesaje is a `primaryContainer` tile with the kg in `cifra` labelMedium bold; without, the day number in `onSurfaceVariant` on a hairline `outlineVariant` tile. The selected Semana keeps `Key('semana-seleccionada')`, drawn as a `primary` 8% stadium band. Selected cell: 2 px `onSurface` border.
- **Promedio Semanal card**: eyebrow "Promedio Semanal" (keep exact text and semantics), value "72.1 kg" in headlineMedium Archivo Expanded, and a delta pill: `primaryContainer` with arrow-down + "1.4 kg" when it dropped, `errorContainer` with arrow-up when it rose, nothing on a tie or with no previous Promedio. Tooltips unchanged.

### Captura

- Title = Momento in Archivo Expanded. Close / Cancelar / Listo keep types and labels; "Listo" stays a `TextButton` styled as a filled tonal pill when enabled.
- Momento selector: the four `ChoiceChip`s in a 2×2 grid (one row does not fit 412 px) with `iconoDeMomento` as avatar; selected = `tertiary` fill (ink pill) with `onTertiary` label and icon.
- Notes field as a **notebook page**: papel card, ruled lines every line-height in `outlineVariant`, a vertical margin line in `error` at 30% alpha, borderless `TextField` in bodyLarge with a line height that sits on the rules. Hint unchanged.
- Existing Renglones of the Comida: compact rows with a stadium "Cantidad" field and the delete icon (tooltip unchanged).
- "Renglones" eyebrow; parsed rows use the dotted-leader style; new rows enter with `entradaRenglon`.

### Confirmación

- Each Renglón is a papel card: name in titleLarge Archivo Expanded, then "Gramos".
- Propuestas are selectable cards (keep `RadioListTile`, give it a stadium-ish superellipse shape, `primaryContainer` tint and a 2 px `primary` border when selected, wrapped in `Presionable`). A tiny origin badge: "Catálogo" (`IconosNutri.origenCatalogo`) when `alimentoId != null`, else "IA" (`IconosNutri.origenIa`). Subtitle text unchanged, in DM Sans (DM Mono is too wide there and breaks mid-value).
- "Crear Alimento" block in a `tertiaryContainer` (lino) card with macro fields prefixed by their hue dot.
- Confirmar: full-width albahaca pill pinned in a bottom bar (reachable above the keyboard and with tall cards), shakes on invalid.

### Catálogo and editor

- Each Alimento is a papel card (radius 24): an initial-letter avatar (Archivo Expanded on a tint picked deterministically from the name among lino/remolacha/trigo/arándano/albahaca containers), name in titleMedium, the unchanged subtitle "97 kcal / 100 g" in `cifra` bodySmall, and on the right a 64×6 stacked bar of where its kcal come from (P×4, C×4, F×9 grams, normalized) in the macro hues.
- Empty state: `PlatoVacio` + existing copy. FAB "Crear" like the Comida FAB (ink pill), no container transform needed.
- Editor: fields grouped in a papel card; macro fields prefixed by their hue dot; Guardar pill shakes on invalid.

### Ajustes

- Two papel cards: "Meta" (macro fields with hue dots) and "Clave propia (BYOK)" (`IconosNutri.clave`). Headings keep their text.
- Footer: the wordmark and "Todo queda en este teléfono." in bodySmall `onSurfaceVariant`.

## Launcher icon and splash

`flutter_launcher_icons` and `flutter_native_splash` (dev dependencies), configured in `pubspec.yaml`, from `assets/marca/`:

- Adaptive icon: background `#F6F0E4`, foreground `icono_frente.png`, monochrome `icono_mono.png`; legacy `icono_1024.png`.
- Splash: color `#F6F0E4` / dark `#141A16`, image `splash.png` / `splash_noche.png`; Android 12 uses `splash_android12*.png` with the same colors.

## Reviewing the look

`mise exec -- flutter test tool/capturas/capturas_test.dart` renders every screen in light and dark to `build/capturas/` with the bundled fonts. The test renderer ignores shadow blur and draws shadows as hard offset shapes; on a device they are soft.
