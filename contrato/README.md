# Contrato de la API de sincronización

`diario.json` es el ejemplo canónico del cuerpo que intercambian la app y `server/`. Los tests de los dos lados lo leen: si cambia el formato, cambia acá primero.

Las formas de cada entidad son las mismas que `lib/almacen_ajustes.dart` guardaba en el teléfono.

| Método | Ruta | Cuerpo | Respuesta |
|---|---|---|---|
| GET | `/api/salud` | — | `200 {"ok": true}` |
| GET | `/api/revision` | — | `200 {"revision": n}` |
| GET | `/api/diario` | — | `200` con la forma de `diario.json` |
| PUT | `/api/diario` | igual que `diario.json`, pero `revisionBase` en lugar de `revision` | `200 {"revision": n+1}` · `409 {"revision": actual}` si `revisionBase` ≠ actual · `400 {"error": "..."}` si el cuerpo no es válido |

- Un servidor nuevo responde `revision: 0`, `meta: null` (la app usa la Meta por defecto) y listas vacías.
- `PUT` reemplaza todo el diario en una transacción. Es la foto completa, no un parche.
- `meta` puede ser `null` en `PUT`: deja la Meta por defecto.
- `fecha` es `YYYY-MM-DD` (Día local). `usadoPorUltimaVez` y `recibidoPorUltimaVez` son ISO 8601 tal como los escribe `DateTime.toIso8601String()` en Dart; `recibidoPorUltimaVez` es opcional.
- `momento` ∈ `desayuno | almuerzo | cena | extra`.
- `cantidad` y `alimentoId` de un Renglón pueden ser `null`.
- Invariantes que el servidor rechaza con `400`: ids de Alimento o Comida repetidos, dos Comidas con el mismo `fecha`+`momento`, dos Pesajes con la misma `fecha`, `kilogramos` ≤ 0.
- La clave de la IA (BYOK) nunca viaja: no es parte del contrato.
- No hay autenticación: la API solo es alcanzable dentro de la tailnet (ADR-0013).
