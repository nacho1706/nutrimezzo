# Hosted mode: one diary on a self-hosted server

_Supersedes ADR-0002: local-only is now one of two installation types, not the only one._

One person wants the same diary on the phone and on a PC browser. ADR-0012's web build kept a separate diary per browser, which is useless for that. NutriMezzo now has two installation types:

- **Offline**: the Android APK keeps the diary on the phone (SharedPreferences), with no server, as in ADR-0002. Default on Android while Ajustes → Servidor is empty.
- **Hosted**: a sync API (`server/`, Dart + one SQLite file) runs next to nginx behind the Tailscale sidecar (ADR-0012), under `/api/`. The server is the only source of truth. The web build is always hosted against its own origin; Android is hosted when Ajustes → Servidor has a URL (or the APK was built with `--dart-define=NUTRIMEZZO_SERVIDOR=...`).

Decisions, all chosen for simplicity over one person's data:

- **Whole-snapshot sync.** `GET /api/diario` returns the whole diary; `PUT` replaces it in one transaction (`contrato/`). Years of entries for one person are still a small JSON body, so no deltas or per-entity endpoints.
- **Optimistic revision.** Each `PUT` carries `revisionBase`; a stale device gets `409`, reloads from the server and asks the user to repeat the last change. On resume the app checks the revision and reloads if another device wrote, unless a Comida capture is in progress. No merging.
- **No offline writes while hosted.** Without the server the app shows "No se pudo conectar con el servidor" and does not open the Día. A local queue would need merging and conflict UI; phone-only use without connection is what offline mode is for.
- **BYOK never leaves the device** (ADR-0001). The key is not in the contract; each device configures its own, in both modes.
- **No authentication.** The API is reachable only inside the tailnet, through nginx. Exposing it publicly needs something in front (e.g. Cloudflare Access), which the Android app cannot pass.
- **Switching modes moves no data.** The offline diary stays on the phone untouched; clearing Servidor shows it again. A new server starts empty; there is no import/export yet.
