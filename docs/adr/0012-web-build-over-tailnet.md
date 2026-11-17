# Web build, self-hosted on a tailnet

The same local-only app is also built for the web (`flutter build web --no-web-resources-cdn`, CanvasKit bundled) and served as static files by nginx behind a Tailscale sidecar (`docker-compose.yml`). Tailscale Serve terminates HTTPS on the tailnet name; there is no `ports:` mapping, so nothing is exposed publicly. This is packaging, not a backend: consistent with ADR-0002, not superseding it.

Consequences:

- Data still lives where the app runs: in each browser's storage (SharedPreferences → localStorage). The phone app, a phone browser, and a PC browser each keep a separate diary. There is no server-side state and no sync; clearing site data loses that browser's history.
- BYOK calls (ADR-0001) go browser → provider, so the provider must allow CORS from the tailnet origin. Hosted APIs that do not will fail on web only; Ollama needs `OLLAMA_ORIGINS` set to include `https://nutrimezzo.<tailnet>.ts.net`.
- The Tailscale node state is a named volume; the auth key is only needed for the first login.
