# syntax=docker/dockerfile:1
# NutriMezzo web: static Flutter build served by unprivileged nginx.
# Meant to run behind the Tailscale sidecar in docker-compose.yml (ADR-0012).

# ---- builder ---------------------------------------------------------------
FROM debian:bookworm-20261104-slim AS builder

ARG FLUTTER_VERSION=3.47.2

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 builder
USER builder
WORKDIR /home/builder

# Plain git clone: no arch-specific tarball, works on arm64 and amd64.
RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" \
      https://github.com/flutter/flutter.git /home/builder/flutter
ENV PATH="/home/builder/flutter/bin:${PATH}"

RUN flutter config --no-analytics \
 && flutter config --no-cli-animations \
 && flutter precache --web

WORKDIR /home/builder/app

COPY --chown=builder:builder pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY --chown=builder:builder . .
# --no-web-resources-cdn bundles CanvasKit instead of loading it from gstatic.
RUN flutter build web --release --no-web-resources-cdn \
 && find build/web -name '*.symbols' -delete

# ---- runtime ---------------------------------------------------------------
FROM nginxinc/nginx-unprivileged:1.30.6-alpine

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /home/builder/app/build/web /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1
