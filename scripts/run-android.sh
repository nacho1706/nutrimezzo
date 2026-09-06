#!/usr/bin/env bash
# Desarrollo local solamente.
#
# Atajo para correr la app en un Android conectado a *esta* máquina.
# El serial del teléfono no vive en este archivo: está en `.env`
# (ver `.env.example`). No es un secreto de producción; es un id de
# dispositivo de adb/Flutter, distinto en cada checkout.
#
# Uso:
#   cp .env.example .env   # una vez; pegá el id de `flutter devices`
#   ./scripts/run-android.sh
#   ./scripts/run-android.sh <otro-id>   # pisa el de .env
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
  mise install
fi

mkdir -p "${TMPDIR:-$HOME/.cache/tmp}"
export TMPDIR="${TMPDIR:-$HOME/.cache/tmp}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="${ANDROID_HOME}/platform-tools:${PATH}"

DEVICE="${1:-${ANDROID_DEVICE_ID:-}}"
if [[ -z "$DEVICE" ]]; then
  echo "Falta ANDROID_DEVICE_ID." >&2
  echo "Copiá .env.example a .env y poné el id de \`flutter devices\` (solo desarrollo local)." >&2
  exit 1
fi

if ! command -v java >/dev/null 2>&1; then
  echo "java not on PATH; install with: mise install" >&2
  exit 1
fi

JAVA_MAJOR="$(java -version 2>&1 | head -1 | sed -n 's/.*"\([0-9]*\).*/\1/p')"
if [[ "${JAVA_MAJOR}" != "17" ]]; then
  echo "Expected Java 17, got: $(java -version 2>&1 | head -1)" >&2
  echo "From the repo: mise install && eval \"\$(mise activate bash)\"" >&2
  exit 1
fi

exec flutter run -d "$DEVICE"
