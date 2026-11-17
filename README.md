# NutriMezzo

Diario local de calorías y macros para Android, con un build web opcional para autoalojar (ver [Self-Hosting](#self-hosting)). El home abre el **Día** de hoy (zona horaria local) y muestra kcal, proteína, carbos y grasa contra una **Meta** por defecto. Desde **Comida** se captura un borrador por **Momento** (notas → **Renglones**). Un Día tiene una Comida por Momento: confirmar otra vez une esos Renglones. **Listo** abre la **Confirmación**: como máximo dos **Propuestas** por Renglón nuevo (mejor match local y, si hay, una de `PuertoBusquedaIA`), o **crear Alimento** si nada pega. Los gramos se ven y se editan (incluidos los asumidos); no se confirma en 0 g. Confirmar anota o continúa la Comida de ese Momento y mueve el anillo y las barras. El **Catálogo** crea el mismo tipo de Alimento.

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

## Self-Hosting

La misma app se puede compilar para web y servir desde tu propio servidor, accesible **solo dentro de tu tailnet** de [Tailscale](https://tailscale.com/) (ver [ADR-0012](docs/adr/0012-web-build-over-tailnet.md)).

Cómo está armado:

- `app`: build web estático de Flutter servido por `nginx-unprivileged` (no root, puerto 8080).
- `tailscale`: sidecar `tailscale/tailscale`. `app` comparte su red (`network_mode: service:tailscale`) y **Tailscale Serve** publica `https://nutrimezzo.<tu-tailnet>.ts.net` → `http://127.0.0.1:8080`.
- Networking en espacio de usuario (`TS_USERSPACE=true`): sin `NET_ADMIN`, sin `/dev/net/tun`, no se instala nada en el host.
- No hay `ports:`: nada escucha en la IP pública del servidor. Funnel está apagado.

No hay backend ni base de datos. **El servidor no guarda datos del usuario**: el diario vive en el `localStorage` de cada navegador (y la app Android en su propio almacenamiento). El navegador del teléfono y el de la PC son diarios separados; no hay sincronización. Lo único con estado en el servidor es el volumen `nutrimezzo_tailscale-state` (identidad del nodo y certificados).

### Requisitos del servidor

- Un Linux cualquiera (un VPS sirve) con [Docker Engine](https://docs.docker.com/engine/install/) y el [plugin Compose v2](https://docs.docker.com/compose/install/linux/) (`docker compose`, no `docker-compose`).
- `git`.
- Una cuenta de Tailscale.
- ~2 GB de RAM libre para el build y ~2 GB de disco.
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

El primer build descarga Flutter y tarda varios minutos. Cuando termine, abrí desde un dispositivo de tu tailnet:

```
https://nutrimezzo.<tu-tailnet>.ts.net
```

El nombre de tu tailnet (p. ej. `tail1234.ts.net`, o sea `<tu-tailnet>` = `tail1234`) está en el [admin console → DNS](https://login.tailscale.com/admin/dns) (“Tailnet name”), o desde cualquier máquina con Tailscale:

```bash
tailscale status --json | jq -r .MagicDNSSuffix
```

La primera petición HTTPS puede tardar unos segundos mientras Tailscale emite el certificado.

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
- `Web`: todo `/` se reenvía a nginx en `127.0.0.1:8080` (misma red que el sidecar). `${TS_CERT_DOMAIN}` lo completa el contenedor con `nutrimezzo.<tu-tailnet>.ts.net`.
- `AllowFunnel: false`: nunca se expone a internet.

Para otro nombre, cambiá `hostname: nutrimezzo` en `docker-compose.yml` (antes del primer login, o re-autenticá; ver Operación).

#### Dispositivos cliente

- Teléfono: instalá Tailscale desde la tienda de apps.
- PC: [tailscale.com/download](https://tailscale.com/download).
- Entrá con la misma cuenta (misma tailnet) y dejá Tailscale encendido.
- “Instalar como app” (PWA): en el menú del navegador, **Agregar a pantalla de inicio** / **Instalar app**.

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

### Alternativa: URL pública con login (Cloudflare Tunnel + Access)

Si no querés instalar Tailscale en cada dispositivo, podés publicar la app con [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) detrás de [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/applications/). Necesitás un dominio en Cloudflare.

> **NutriMezzo no tiene autenticación propia.** Nunca la publiques sin una política de Access delante.

1. En Zero Trust, **Access → Applications → Add an application → Self-hosted**, con el hostname que vas a usar (p. ej. `nutrimezzo.<tu-dominio>`) y una política **Allow** con *Emails* = tu email. Hacelo **antes** del paso 3, así el hostname nunca queda abierto.
2. **Networks → Tunnels → Create a tunnel** (tipo Cloudflared). Copiá el token y ponelo en `.env`:

   ```bash
   TUNNEL_TOKEN=eyJ...
   ```

3. En el túnel, agregá el **public hostname** `nutrimezzo.<tu-dominio>` → servicio `HTTP`, URL `app:8080`.
4. Creá `docker-compose.cloudflare.yml` en la raíz del repo. Reemplaza el sidecar de Tailscale por `cloudflared`; `app` usa la red normal de Compose y sigue sin `ports:`:

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
   ```

5. Levantalo (si venías usando Tailscale, `--remove-orphans` borra ese contenedor; el volumen queda):

   ```bash
   docker compose -f docker-compose.cloudflare.yml up -d --build --remove-orphans
   ```

Con esta variante, todos los comandos de Operación llevan `-f docker-compose.cloudflare.yml`, y el CORS de BYOK se configura para `https://nutrimezzo.<tu-dominio>`.

### Operación

Todo desde el directorio del repo en el servidor.

Actualizar:

```bash
git pull
docker compose up -d --build
docker image prune -f   # opcional: borra imágenes viejas sin usar
```

Logs y estado:

```bash
docker compose ps
docker compose logs -f app
docker compose logs -f tailscale
docker compose exec tailscale tailscale status
docker compose exec tailscale tailscale serve status
```

#### Backup del estado de Tailscale

Lo único a respaldar en el servidor es `nutrimezzo_tailscale-state` (identidad del nodo + certificados). Contiene la clave privada del nodo: guardá el archivo como un secreto.

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

#### Datos del diario

No están en el servidor: están en cada navegador. Borrar los datos del sitio, usar modo incógnito o cambiar de navegador es empezar un diario vacío. Hoy **no hay exportar/importar** (ADR-0002 lo deja para más adelante), así que no hay forma de respaldar el diario web desde la app.

#### Re-autenticar

Si se perdió el volumen o expiró la key del nodo:

1. Generá una auth key nueva y ponela en `TS_AUTHKEY` en `.env`.
2. En [Machines](https://login.tailscale.com/admin/machines), borrá la máquina `nutrimezzo` vieja; si no, el nodo nuevo queda como `nutrimezzo-1`.
3. Recreá los contenedores (los dos: `app` vive en la red de `tailscale`):

   ```bash
   docker compose up -d --force-recreate
   ```

#### Parar / borrar

```bash
docker compose down      # para y borra contenedores; el volumen queda
docker compose down -v   # ¡también borra nutrimezzo_tailscale-state!
```

`down -v` borra la identidad del nodo: la próxima vez hace falta una auth key nueva y borrar la máquina vieja en el admin console.

### Problemas comunes

- **El nodo no aparece en Machines.** Mirá `docker compose logs tailscale`. Causas típicas: `TS_AUTHKEY` vacía, vencida, ya usada (no reutilizable) o efímera; el nodo está esperando aprobación (Machines → Approve, o usá una key pre-aprobada); el tag no está en `tagOwners`.
- **El nombre es `nutrimezzo-1`.** Ya existía una máquina `nutrimezzo`. Borrá la vieja en Machines y re-autenticá (ver arriba), o renombrala desde el admin console.
- **Error de certificado / HTTPS no responde (conexión rechazada en el 443).** Si los logs de `tailscale` dicen *“not able to issue TLS certs… ensure that HTTPS is enabled for your tailnet”* y `tailscale serve status` muestra *“No serve config”*, falta activar **HTTPS Certificates** (y MagicDNS) en el [admin console → DNS](https://login.tailscale.com/admin/dns). Después recreá los dos contenedores: `docker compose up -d --force-recreate`.
- **La primera carga es lenta.** Normal: emisión del certificado y descarga de CanvasKit (va incluido en la imagen, unos MB). Las siguientes revalidan por ETag.
- **502 Bad Gateway.** Serve no llega a nginx: `docker compose ps` debería mostrar `app` como `healthy`. Si no, `docker compose logs app`. Si recreaste solo `tailscale`, recreá también `app` (`docker compose up -d --force-recreate`).
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

- **arm64 vs amd64.** La imagen se construye en el servidor para su propia arquitectura; Flutter se clona con git, sin tarballs por arquitectura. No copies una imagen construida en una PC amd64 a un servidor arm64 (o viceversa): construí en el servidor.
- **La búsqueda con IA falla solo en web.** CORS del proveedor (ver BYOK desde el navegador). En la consola del navegador vas a ver el error de CORS.
- **El cliente no resuelve `nutrimezzo.<tu-tailnet>.ts.net`.** Tailscale apagado en ese dispositivo, MagicDNS desactivado, o “Use Tailscale DNS” deshabilitado en el cliente.
- **Verificar que nada es público.** `docker compose ps` no debería mostrar puertos del host (`0.0.0.0:...`). Desde otra máquina fuera de la tailnet:

  ```bash
  curl -m5 http://<ip-pública>
  curl -m5 -k https://<ip-pública>
  ```

  Ambos tienen que fallar (timeout o conexión rechazada), salvo que otro servicio del host use esos puertos.

## Tests

Los tests del dominio hablan con `Diario` (Dart puro, sin widgets):

```bash
flutter test
```

## Meta y BYOK

La Meta por defecto es 2000 kcal, 150 g de proteína, 250 g de carbos y 70 g de grasa. Un Día vacío muestra ceros contra esos números, no un error.

Desde **Ajustes** (engranaje en Hoy) se edita la Meta y, si hace falta, una clave propia (URL base, clave de API, id de modelo). Todo queda en el teléfono. BYOK en blanco es válido: el diario abre igual y no llama a ningún modelo. La clave de API no va a git.
