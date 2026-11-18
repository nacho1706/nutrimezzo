# syntax=docker/dockerfile:1
# NutriMezzo API: the sync server (contrato/README.md), one SQLite file.
# Runs inside the Tailscale sidecar's network namespace; only nginx reaches it
# (docker-compose.yml). Build context: server/.

# ---- builder ---------------------------------------------------------------
# Multi-arch official image (amd64, arm64).
FROM dart:3.14.1 AS builder

WORKDIR /src

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile

COPY . .
# `dart compile exe` does not run build hooks; `dart build cli` does. The
# sqlite3 hook fetches a precompiled libsqlite3.so for the target arch
# (sha256-pinned by package:sqlite3) and bundles it next to the binary:
#   /out/bundle/bin/server, /out/bundle/lib/libsqlite3.so
RUN dart build cli --target bin/server.dart -o /out

# ---- runtime ---------------------------------------------------------------
FROM debian:bookworm-20261104-slim

# The server uses the bundled libsqlite3.so. The sqlite3 CLI is only for
# operators: online backups with `sqlite3 /data/nutrimezzo.db ".backup ..."`.
RUN apt-get update \
 && apt-get install -y --no-install-recommends sqlite3 \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 10001 nutrimezzo \
 && useradd --system --uid 10001 --gid 10001 --no-create-home \
      --shell /usr/sbin/nologin nutrimezzo \
 && mkdir /data \
 && chown nutrimezzo:nutrimezzo /data

COPY --from=builder /out/bundle /app

USER 10001:10001
ENV NUTRIMEZZO_DB=/data/nutrimezzo.db \
    HOST=127.0.0.1 \
    PORT=8081

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/app/bin/server", "--healthcheck"]

ENTRYPOINT ["/app/bin/server"]
