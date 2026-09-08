# NutriMezzo

Diario local de calorías y macros para Android. El home abre el **Día** de hoy (zona horaria local) y muestra kcal, proteína, carbos y grasa contra una **Meta** por defecto. Desde **Comida** se captura un borrador por **Momento** (notas → **Renglones**). Un Día tiene una Comida por Momento: confirmar otra vez une esos Renglones. **Listo** abre la **Confirmación**: como máximo dos **Propuestas** por Renglón nuevo (mejor match local y, si hay, una de `PuertoBusquedaIA`), o **crear Alimento** si nada pega. Los gramos se ven y se editan (incluidos los asumidos); no se confirma en 0 g. Confirmar anota o continúa la Comida de ese Momento y mueve el anillo y las barras. El **Catálogo** crea el mismo tipo de Alimento.

Licencia: [MIT](LICENSE).

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) 3.47.2 y **JDK 17** (el Gradle de Android no arranca con Java 26). Con [mise](https://mise.jdx.dev/): `mise trust && mise install` — el repo trae `mise.toml`.
- Android SDK y un emulador o un teléfono con depuración USB (`ANDROID_HOME`, por defecto `~/Android/Sdk` vía mise).

## Correr en Android

```bash
flutter pub get
flutter run
```

Para un teléfono físico:

1. En Android, activá **Opciones de desarrollador** y **Depuración USB**.
2. Conectá el teléfono por USB y aceptá en el aparato la huella RSA de la computadora cuando aparezca.
3. Verificá que `flutter devices` lo vea.
4. Recién ahí corré `flutter run` y elegí ese dispositivo si Flutter te pregunta.

La primera vez, `flutter doctor` indica si falta el SDK o las licencias (`flutter doctor --android-licenses`). Si `/tmp` es tmpfs chico (Omarchy), mise apunta `TMPDIR` al disco para que Gradle no se quede sin espacio.

Para un atajo local (`scripts/run-android.sh`), copiá `.env.example` a `.env` y poné el serial de `flutter devices`. Eso es solo desarrollo en tu máquina; `.env` no se commitea.

## Instalar un APK en un teléfono

Hoy el repo está preparado sobre todo para desarrollo local con `flutter run`.

Si querés generar un APK de prueba:

```bash
flutter build apk
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk` y se puede instalar manualmente en Android.

Importante: la variante `release` actual usa firma de `debug`, así que sirve para pruebas locales, no para publicar ni distribuir como build final. Si más adelante querés una instalación "real" fuera de desarrollo, hay que configurar firma de release propia.

## Tests

Los tests del dominio hablan con `Diario` (Dart puro, sin widgets):

```bash
flutter test
```

## Meta y BYOK

La Meta por defecto es 2000 kcal, 150 g de proteína, 250 g de carbos y 70 g de grasa. Un Día vacío muestra ceros contra esos números, no un error.

Desde **Ajustes** (engranaje en Hoy) se edita la Meta y, si hace falta, una clave propia (URL base, clave de API, id de modelo). Todo queda en el teléfono. BYOK en blanco es válido: el diario abre igual y no llama a ningún modelo. La clave de API no va a git.
