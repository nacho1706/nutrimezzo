# NutriMezzo

Diario de calorías y macros para Android y web. Se instala de dos maneras: [offline, solo en el teléfono](#opción-1-offline-solo-el-teléfono), o [con hosting propio](#opción-2-con-hosting-sincronizado), donde un servidor en tu tailnet guarda un único diario que comparten el teléfono y el navegador. El home abre el **Día** de hoy (zona horaria local) y muestra kcal, proteína, carbos y grasa contra una **Meta** por defecto. Desde **Comida** se captura un borrador por **Momento** (notas → **Renglones**). Un Día tiene una Comida por Momento: confirmar otra vez une esos Renglones. **Listo** abre la **Confirmación**: como máximo dos **Propuestas** por Renglón nuevo (mejor match local y, si hay, una de `PuertoBusquedaIA`), o **crear Alimento** si nada pega. Los gramos se ven y se editan (incluidos los asumidos); no se confirma en 0 g. Confirmar anota o continúa la Comida de ese Momento y mueve el anillo y las barras. El **Catálogo** crea el mismo tipo de Alimento.

Licencia: [MIT](LICENSE).

## Instalación

| | Opción 1: offline | Opción 2: con hosting |
|---|---|---|
| Dónde viven los datos | En el teléfono | En tu servidor (SQLite), única fuente de verdad |
| Clientes | La app Android | Web (PC, teléfono, PWA) y la app Android, un solo diario |
| Sin conexión | Funciona igual | No anota: muestra “No se pudo conectar con el servidor” |
| Clave de IA (BYOK) | En el teléfono | En cada dispositivo; nunca va al servidor |

Ver [ADR-0013](docs/adr/0013-modo-alojado-sincronizado.md).

### Opción 1: offline (solo el teléfono)

Un APK, sin servidor ni cuenta. Es lo que hace la app Android mientras **Ajustes → Servidor** esté vacío.

Compilá el APK (hace falta Flutter, ver [Desarrollo](#desarrollo)):

```bash
flutter build apk --release
```

Queda en `build/app/outputs/flutter-apk/app-release.apk`. Para instalarlo:

- Por USB (con **Depuración USB** activada): `adb install -r build/app/outputs/flutter-apk/app-release.apk`.
- O copiá el APK al teléfono y abrilo (permití instalar apps de fuentes desconocidas).

`-r` reinstala sin borrar datos. La variante `release` usa firma de `debug`: sirve para uso personal, no para publicar. Si cambiás de máquina de build (otra firma), Android no deja actualizar encima: hay que desinstalar, y eso borra el diario offline.

### Opción 2: con hosting (sincronizado)

1. **Servidor.** Levantá el stack en un Linux con Docker siguiendo [Self-Hosting](#self-hosting). Queda en `https://nutrimezzo.<tu-tailnet>.ts.net`, solo dentro de tu tailnet.
2. **Navegador.** Desde un dispositivo con Tailscale abrí esa URL. Para tenerla como app: menú del navegador → **Agregar a pantalla de inicio** / **Instalar app** (PWA). La web siempre usa el servidor.
3. **Android.** Instalá la app de Tailscale, entrá a la misma tailnet y dejala encendida. Después, en NutriMezzo, **Ajustes → Servidor** = `https://nutrimezzo.<tu-tailnet>.ts.net`.

   O compilá un APK que ya venga apuntando al servidor (se usa solo si el campo nunca se tocó en ese teléfono):

   ```bash
   flutter build apk --release --dart-define=NUTRIMEZZO_SERVIDOR=https://nutrimezzo.<tu-tailnet>.ts.net
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Clave de IA.** Configurala en **Ajustes** de cada dispositivo: no se sincroniza.

Cómo se comporta:

- **Sin conexión** (servidor caído o Tailscale apagado): la app muestra “No se pudo conectar con el servidor” con **Reintentar** (y en Android, **Ajustes del servidor**). No hay escritura offline en este modo.
- **Dos dispositivos a la vez**: si uno anota con una versión vieja del diario, el servidor lo rechaza (409); la app recarga y avisa “Se actualizó desde otro dispositivo; repetí el último cambio”. Al volver a la app, recarga sola si otro dispositivo cambió algo (salvo en medio de una captura de Comida).
- **Cambiar de modo no borra ni migra nada.** El diario offline queda guardado en el teléfono: vaciar **Servidor** lo vuelve a mostrar. Un servidor nuevo arranca vacío; todavía no hay exportar/importar.

## Self-Hosting

Guía de la [opción 2](#opción-2-con-hosting-sincronizado): la app web y la API de sincronización en tu propio servidor, accesibles **solo dentro de tu tailnet** de [Tailscale](https://tailscale.com/) (ver [ADR-0012](docs/adr/0012-web-build-over-tailnet.md) y [ADR-0013](docs/adr/0013-modo-alojado-sincronizado.md)).

Cómo está armado (`docker-compose.yml`, proyecto `nutrimezzo`):

- `tailscale`: sidecar `tailscale/tailscale`. **Tailscale Serve** publica `https://nutrimezzo.<tu-tailnet>.ts.net` → `http://127.0.0.1:8080`.
- `app`: build web estático de Flutter servido por `nginx-unprivileged` (no root, puerto 8080). Reenvía `/api/` → `127.0.0.1:8081`.
- `api`: servidor de sincronización (Dart + SQLite, usuario 10001, puerto 8081 en loopback). Contrato en [`contrato/`](contrato/README.md).
- `app` y `api` comparten la red del sidecar (`network_mode: service:tailscale`), así que se hablan por `127.0.0.1`.
- Networking en espacio de usuario (`TS_USERSPACE=true`): sin `NET_ADMIN`, sin `/dev/net/tun`, no se instala nada en el host.
- No hay `ports:`: nada escucha en la IP pública del servidor. Funnel está apagado.

La API **no tiene autenticación**: la protege que solo se alcanza dentro de la tailnet, a través de nginx.

Estado en el servidor:

- `nutrimezzo_nutrimezzo-data`: el diario, un archivo SQLite en `/data/nutrimezzo.db` dentro de `api` (modo WAL: al lado aparecen `-wal` y `-shm`). **Esto es lo que hay que respaldar.**
- `nutrimezzo_tailscale-state`: identidad del nodo y certificados.

La clave de IA (BYOK) no pasa por el servidor: queda en cada dispositivo.

### Requisitos del servidor

- Un Linux cualquiera (un VPS sirve) con [Docker Engine](https://docs.docker.com/engine/install/) y el [plugin Compose v2](https://docs.docker.com/compose/install/linux/) (`docker compose`, no `docker-compose`).
- `git`.
- Una cuenta de Tailscale.
- ~2–3 GB de RAM libre durante el build de Flutter (pico) y ~4 GB de disco para las imágenes. Corriendo, el stack usa poco.
- amd64 o arm64: el build corre nativo en el servidor (sirve, p. ej., en una instancia Ampere del free tier de Oracle).

### Arranque rápido

```bash
git clone <url-del-repo> nutrimezzo
cd nutrimezzo
cp .env.example .env
# editá .env y poné TS_AUTHKEY=tskey-auth-...  (ver "Auth key" abajo)
chmod 600 .env
docker compose up -d --build
```

El primer build construye dos imágenes (la web de Flutter y el servidor Dart) y tarda varios minutos. Cuando termine, `docker compose ps` tiene que mostrar los tres servicios `healthy`. Abrí desde un dispositivo de tu tailnet:

```
https://nutrimezzo.<tu-tailnet>.ts.net
```

El nombre de tu tailnet (p. ej. `tail1234.ts.net`, o sea `<tu-tailnet>` = `tail1234`) está en el [admin console → DNS](https://login.tailscale.com/admin/dns) (“Tailnet name”), o desde cualquier máquina con Tailscale:

```bash
tailscale status --json | jq -r .MagicDNSSuffix
```

La primera petición HTTPS puede tardar unos segundos mientras Tailscale emite el certificado. Para probar la API desde un dispositivo de la tailnet:

```bash
curl https://nutrimezzo.<tu-tailnet>.ts.net/api/salud   # {"ok":true}
```

Un servidor nuevo arranca con el diario vacío y la Meta por defecto.

### Tailscale

#### Auth key

En el [admin console → Settings → Keys](https://login.tailscale.com/admin/settings/keys), **Generate auth key**:

- **No efímera**: el nodo tiene que sobrevivir reinicios.
- **Reutilizable**: no hace falta; se usa una sola vez.
- **Pre-aprobada**, si tu tailnet exige aprobar dispositivos.
- **Tag** (opcional, recomendado), p. ej. `tag:nutrimezzo`. Primero declaralo en la policy (Access controls):

  ```jsonc
  "tagOwners": {
    "tag:nutrimezzo": ["autogroup:admin"],
  },
  ```

  y en `.env`:

  ```bash
  TS_EXTRA_ARGS=--advertise-tags=tag:nutrimezzo
  ```

La key solo se usa en el primer login; después el estado queda en el volumen y `TS_AUTHKEY` puede quedar vacía. Los nodos **sin tag** heredan la expiración de tu sesión: en [Machines](https://login.tailscale.com/admin/machines) → `nutrimezzo` → **Disable key expiry**. Los nodos con tag no expiran.

#### MagicDNS y HTTPS

En el [admin console → DNS](https://login.tailscale.com/admin/dns) activá **MagicDNS** y **HTTPS Certificates**. Sin eso, Serve no puede emitir el certificado de `*.ts.net`.

#### `deploy/tailscale/serve.json`

```json
{
  "TCP": { "443": { "HTTPS": true } },
  "Web": {
    "${TS_CERT_DOMAIN}:443": {
      "Handlers": { "/": { "Proxy": "http://127.0.0.1:8080" } }
    }
  },
  "AllowFunnel": { "${TS_CERT_DOMAIN}:443": false }
}
```

- `TCP 443 HTTPS`: Tailscale termina TLS en el 443 del nodo.
- `Web`: todo `/` se reenvía a nginx en `127.0.0.1:8080` (misma red que el sidecar); nginx pasa `/api/` a la API. `${TS_CERT_DOMAIN}` lo completa el contenedor con `nutrimezzo.<tu-tailnet>.ts.net`.
- `AllowFunnel: false`: nunca se expone a internet.

Para otro nombre, cambiá `hostname: nutrimezzo` en `docker-compose.yml` (antes del primer login, o re-autenticá; ver Operación).

#### Dispositivos cliente

- Teléfono: instalá Tailscale desde la tienda de apps. PC: [tailscale.com/download](https://tailscale.com/download).
- Entrá con la misma cuenta (misma tailnet) y dejá Tailscale encendido: sin eso la app muestra “No se pudo conectar con el servidor”.
- Web como app (PWA): en el menú del navegador, **Agregar a pantalla de inicio** / **Instalar app**.
- App Android: **Ajustes → Servidor** = `https://nutrimezzo.<tu-tailnet>.ts.net`, o un APK compilado con `--dart-define=NUTRIMEZZO_SERVIDOR=...` (ver [opción 2](#opción-2-con-hosting-sincronizado)).

#### Limitar quién llega (opcional)

La policy por defecto deja que cualquier nodo de la tailnet llegue a cualquier otro. Para restringir, reemplazá la regla abierta por algo así (requiere el tag):

```jsonc
"grants": [
  // solo vos (o un grupo) al 443 de NutriMezzo
  { "src": ["tu-email@ejemplo.com"], "dst": ["tag:nutrimezzo"], "ip": ["443"] },
  // ...el resto de tus reglas
],
```

#### BYOK desde el navegador

En web, las llamadas a la IA van **navegador → proveedor** (ADR-0001), así que el proveedor tiene que permitir CORS desde `https://nutrimezzo.<tu-tailnet>.ts.net`. Si no lo permite, la búsqueda con IA falla en web pero no en Android. Con Ollama, agregá ese origen a `OLLAMA_ORIGINS`.

La clave se guarda en el navegador (como en Android, en el dispositivo); no se sincroniza.

### Alternativa: URL pública con login (Cloudflare Tunnel + Access)

Si no querés instalar Tailscale en cada dispositivo, podés publicar la app con [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) detrás de [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/applications/). Necesitás un dominio en Cloudflare.

> **NutriMezzo no tiene autenticación propia, ni la web ni la API.** Nunca la publiques sin una política de Access delante. Como `/api/` está en el mismo hostname, Access la protege también.

Limitación: la app Android no puede pasar el login de Access. Con esta variante usá la web (también desde el teléfono, como PWA) y dejá la app Android en modo offline.

1. En Zero Trust, **Access → Applications → Add an application → Self-hosted**, con el hostname que vas a usar (p. ej. `nutrimezzo.<tu-dominio>`) y una política **Allow** con *Emails* = tu email. Hacelo **antes** del paso 3, así el hostname nunca queda abierto.
2. **Networks → Tunnels → Create a tunnel** (tipo Cloudflared). Copiá el token y ponelo en `.env`:

   ```bash
   TUNNEL_TOKEN=eyJ...
   ```

3. En el túnel, agregá el **public hostname** `nutrimezzo.<tu-dominio>` → servicio `HTTP`, URL `app:8080`.
4. Creá `docker-compose.cloudflare.yml` en la raíz del repo. Reemplaza el sidecar de Tailscale por `cloudflared`; `app` usa la red normal de Compose y sigue sin `ports:`. `api` entra en la red de `app` (`network_mode: service:app`) para que nginx lo siga alcanzando en `127.0.0.1:8081`:

   ```yaml
   name: nutrimezzo

   services:
     cloudflared:
       image: cloudflare/cloudflared:2026.8.3   # fijá una versión vigente
       command: tunnel --no-autoupdate run
       environment:
         TUNNEL_TOKEN: ${TUNNEL_TOKEN:?definí TUNNEL_TOKEN en .env}
       depends_on:
         - app
       restart: unless-stopped

     app:
       build: .
       image: nutrimezzo-web:local
       healthcheck:
         test: ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/"]
         interval: 30s
         timeout: 5s
         start_period: 10s
         retries: 3
       restart: unless-stopped

     api:
       build: ./server
       image: nutrimezzo-api:local
       network_mode: service:app
       depends_on:
         - app
       environment:
         NUTRIMEZZO_DB: /data/nutrimezzo.db
         HOST: 127.0.0.1
         PORT: "8081"
       volumes:
         - nutrimezzo-data:/data
       healthcheck:
         test: ["CMD", "/app/bin/server", "--healthcheck"]
         interval: 30s
         timeout: 5s
         start_period: 10s
         retries: 3
       restart: unless-stopped
       stop_grace_period: 10s

   volumes:
     nutrimezzo-data:
   ```

   Mismo proyecto (`nutrimezzo`) y mismo volumen: si venías de Tailscale, el diario se conserva.

5. Levantalo (si venías usando Tailscale, `--remove-orphans` borra ese contenedor; su volumen queda):

   ```bash
   docker compose -f docker-compose.cloudflare.yml up -d --build --remove-orphans
   ```

Con esta variante, todos los comandos de Operación llevan `-f docker-compose.cloudflare.yml`; si recreás `app`, recreá también `api` (vive en su red). El CORS de BYOK se configura para `https://nutrimezzo.<tu-dominio>`.

### Operación

Todo desde el directorio del repo en el servidor.

Actualizar (el diario queda en su volumen):

```bash
git pull
docker compose up -d --build
docker image prune -f   # opcional: borra imágenes viejas sin usar
```

Logs y estado:

```bash
docker compose ps
docker compose logs -f api
docker compose logs -f app
docker compose logs -f tailscale
docker compose exec tailscale tailscale status
docker compose exec tailscale tailscale serve status
```

#### Backup del diario

En caliente, sin parar nada (`sqlite3 .backup` copia una foto consistente aunque la API esté escribiendo):

```bash
docker compose exec api sqlite3 /data/nutrimezzo.db ".backup /data/backup.db"
docker compose cp api:/data/backup.db ./nutrimezzo-$(date +%F).db
docker compose exec api rm /data/backup.db
```

Guardá el `.db` fuera del servidor. No copies `nutrimezzo.db` a mano con la API corriendo: en modo WAL los últimos cambios pueden estar en `nutrimezzo.db-wal`.

Restaurar (mismo servidor o uno nuevo, con el repo clonado y `.env` listo; cambiá `nutrimezzo-AAAA-MM-DD.db` por tu archivo):

```bash
docker compose stop api
docker volume create nutrimezzo_nutrimezzo-data   # no pasa nada si ya existe
docker run --rm \
  -v nutrimezzo_nutrimezzo-data:/data \
  -v "$PWD":/backup:ro \
  alpine:3.22 sh -c 'rm -f /data/nutrimezzo.db /data/nutrimezzo.db-wal /data/nutrimezzo.db-shm \
    && cp /backup/nutrimezzo-AAAA-MM-DD.db /data/nutrimezzo.db \
    && chown -R 10001:10001 /data'
docker compose up -d --build
```

El `chown` es necesario: la API corre como el usuario 10001 y tiene que poder escribir el archivo y crear `-wal`/`-shm` en `/data`. Los dispositivos con la app abierta reciben un 409 en el próximo cambio y recargan (o recargan solos al volver a la app).

#### Backup del estado de Tailscale

`nutrimezzo_tailscale-state` (identidad del nodo + certificados) evita tener que re-autenticar. Contiene la clave privada del nodo: guardá el archivo como un secreto.

```bash
docker compose stop
docker run --rm \
  -v nutrimezzo_tailscale-state:/data:ro \
  -v "$PWD":/backup \
  alpine:3.22 tar czf /backup/tailscale-state.tgz -C /data .
docker compose up -d
```

Restaurar (mismo servidor o uno nuevo, con el repo clonado y `.env` listo):

```bash
docker compose down
docker volume create nutrimezzo_tailscale-state
docker run --rm \
  -v nutrimezzo_tailscale-state:/data \
  -v "$PWD":/backup:ro \
  alpine:3.22 sh -c 'rm -rf /data/* && tar xzf /backup/tailscale-state.tgz -C /data'
docker compose up -d --build
```

Si Compose avisa que el volumen “already exists but was not created by Docker Compose”, es solo un aviso: lo usa igual.

#### Re-autenticar

Si se perdió el volumen o expiró la key del nodo:

1. Generá una auth key nueva y ponela en `TS_AUTHKEY` en `.env`.
2. En [Machines](https://login.tailscale.com/admin/machines), borrá la máquina `nutrimezzo` vieja; si no, el nodo nuevo queda como `nutrimezzo-1`.
3. Recreá los contenedores (los tres: `app` y `api` viven en la red de `tailscale`):

   ```bash
   docker compose up -d --force-recreate
   ```

#### Parar / borrar

```bash
docker compose down      # para y borra contenedores; los volúmenes quedan
docker compose down -v   # ¡también borra el diario y nutrimezzo_tailscale-state!
```

`down -v` borra **el diario** y la identidad del nodo. Hacé un backup antes; la próxima vez hace falta una auth key nueva y borrar la máquina vieja en el admin console.

### Problemas comunes

- **La app dice “No se pudo conectar con el servidor”.** En ese dispositivo: ¿Tailscale encendido y en la misma tailnet? ¿Abre `https://nutrimezzo.<tu-tailnet>.ts.net/api/salud`? En Android, revisá la URL en **Ajustes del servidor** (sin `/api` al final). Si la URL abre pero `/api/salud` no, mirá el punto del 502 de abajo.
- **“Se actualizó desde otro dispositivo; repetí el último cambio”.** No es un error: otro dispositivo guardó antes, así que el servidor rechazó el cambio (409) y la app recargó el diario. Repetí lo último que hiciste.
- **502 Bad Gateway en `/api/`.** nginx no llega a la API: `docker compose ps` debería mostrar `api` como `healthy`. Si no, `docker compose logs api` (p. ej. un volumen restaurado sin el `chown` a 10001). Si recreaste solo `tailscale`, recreá todo (`docker compose up -d --force-recreate`).
- **El nodo no aparece en Machines.** Mirá `docker compose logs tailscale`. Causas típicas: `TS_AUTHKEY` vacía, vencida, ya usada (no reutilizable) o efímera; el nodo está esperando aprobación (Machines → Approve, o usá una key pre-aprobada); el tag no está en `tagOwners`.
- **El nombre es `nutrimezzo-1`.** Ya existía una máquina `nutrimezzo`. Borrá la vieja en Machines y re-autenticá (ver arriba), o renombrala desde el admin console.
- **Error de certificado / HTTPS no responde (conexión rechazada en el 443).** Si los logs de `tailscale` dicen *“not able to issue TLS certs… ensure that HTTPS is enabled for your tailnet”* y `tailscale serve status` muestra *“No serve config”*, falta activar **HTTPS Certificates** (y MagicDNS) en el [admin console → DNS](https://login.tailscale.com/admin/dns). Después recreá todos los contenedores: `docker compose up -d --force-recreate`.
- **La primera carga es lenta.** Normal: emisión del certificado y descarga de CanvasKit (va incluido en la imagen, unos MB). Las siguientes revalidan por ETag.
- **502 Bad Gateway en toda la página.** Serve no llega a nginx: `docker compose ps` debería mostrar `app` como `healthy`. Si no, `docker compose logs app`. Si recreaste solo `tailscale`, recreá también `app` y `api` (`docker compose up -d --force-recreate`).
- **El build muere (OOM, `Killed`, exit 137).** Falta RAM. Agregá swap temporal:

  ```bash
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  docker compose up -d --build
  # después, para sacarlo:
  sudo swapoff /swapfile
  sudo rm /swapfile
  ```

- **arm64 vs amd64.** Las imágenes se construyen en el servidor para su propia arquitectura; Flutter se clona con git y la imagen `dart` es multi-arch. No copies una imagen construida en una PC amd64 a un servidor arm64 (o viceversa): construí en el servidor.
- **La búsqueda con IA falla solo en web.** CORS del proveedor (ver BYOK desde el navegador). En la consola del navegador vas a ver el error de CORS.
- **El cliente no resuelve `nutrimezzo.<tu-tailnet>.ts.net`.** Tailscale apagado en ese dispositivo, MagicDNS desactivado, o “Use Tailscale DNS” deshabilitado en el cliente.
- **Verificar que nada es público.** `docker compose ps` no debería mostrar puertos del host (`0.0.0.0:...`). Desde otra máquina fuera de la tailnet:

  ```bash
  curl -m5 http://<ip-pública>
  curl -m5 -k https://<ip-pública>
  ```

  Ambos tienen que fallar (timeout o conexión rechazada), salvo que otro servicio del host use esos puertos.

## Desarrollo

### Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) 3.47.2 y **JDK 17** (el Gradle de Android no arranca con Java 26). Con [mise](https://mise.jdx.dev/): `mise trust && mise install` — el repo trae `mise.toml`.
- Android SDK y un emulador o un teléfono con depuración USB (`ANDROID_HOME`, por defecto `~/Android/Sdk` vía mise).

### Correr en Android

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

`flutter run` arranca en modo offline salvo que configures **Ajustes → Servidor** o pases `--dart-define=NUTRIMEZZO_SERVIDOR=...`.

### Tests

Los tests del dominio hablan con `Diario` (Dart puro, sin widgets):

```bash
flutter test
```

El servidor de sincronización (`server/`) tiene sus propios tests, contra el mismo contrato (`contrato/diario.json`):

```bash
cd server && dart test
```

## Meta y BYOK

La Meta por defecto es 2000 kcal, 150 g de proteína, 250 g de carbos y 70 g de grasa. Un Día vacío muestra ceros contra esos números, no un error.

Desde **Ajustes** (engranaje en Hoy) se edita la Meta y, si hace falta, una clave propia (URL base, clave de API, id de modelo).

- **Meta**: es parte del diario. Offline queda en el teléfono; con hosting vive en el servidor y se comparte entre dispositivos.
- **BYOK**: siempre queda en el dispositivo, en los dos modos; nunca va al servidor. Con hosting, configurala en cada dispositivo que quieras usar con IA.

BYOK en blanco es válido: el diario abre igual y no llama a ningún modelo. La clave de API no va a git.
