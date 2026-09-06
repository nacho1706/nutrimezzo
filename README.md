# NutriMezzo

Diario local de calorías y macros para Android. El home abre el **Día** de hoy (zona horaria local) y muestra kcal, proteína, carbos y grasa contra una **Meta** por defecto. Desde **Comida** se captura un borrador por **Momento** (notas → **Renglones**). **Listo** abre la **Confirmación**: como máximo dos **Propuestas** por Renglón (mejor match local y, si hay, una de `PuertoBusquedaIA`), o **crear Alimento** si nada pega. Los gramos se ven y se editan (incluidos los asumidos); no se confirma en 0 g. Confirmar anota la Comida en hoy, agrupa por Momento y mueve las barras. El **Catálogo** crea el mismo tipo de Alimento.

Licencia: [MIT](LICENSE).

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) 3.47.2 y **JDK 17** (el Gradle de Android no arranca con Java 26). Con [mise](https://mise.jdx.dev/): `mise trust && mise install` — el repo trae `mise.toml`.
- Android SDK y un emulador o un teléfono con depuración USB (`ANDROID_HOME`, por defecto `~/Android/Sdk` vía mise).

## Correr en Android

```bash
flutter pub get
flutter run
```

Elegí un dispositivo Android cuando `flutter devices` lo liste. La primera vez, `flutter doctor` indica si falta el SDK o las licencias (`flutter doctor --android-licenses`). Si `/tmp` es tmpfs chico (Omarchy), mise apunta `TMPDIR` al disco para que Gradle no se quede sin espacio.

Para un atajo local (`scripts/run-android.sh`), copiá `.env.example` a `.env` y poné el serial de `flutter devices`. Eso es solo desarrollo en tu máquina; `.env` no se commitea.

## Tests

Los tests del dominio hablan con `Diario` (Dart puro, sin widgets):

```bash
flutter test
```

## Meta y BYOK

La Meta por defecto es 2000 kcal, 150 g de proteína, 250 g de carbos y 70 g de grasa. Un Día vacío muestra ceros contra esos números, no un error.

Desde **Ajustes** (engranaje en Hoy) se edita la Meta y, si hace falta, una clave propia (URL base, clave de API, id de modelo). Todo queda en el teléfono. BYOK en blanco es válido: el diario abre igual y no llama a ningún modelo. La clave de API no va a git.
