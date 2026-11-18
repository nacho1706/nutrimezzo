# Local-only diary for the MVP

_Superseded by ADR-0013: local-only is now the offline installation type; a self-hosted server can hold the diary instead._

Alimentos, Comidas, Días, and the Meta live on the device with no account and no NutriMezzo server. The AI key is already on-device (ADR-0001); keeping the diary there avoids auth and hosting for an OSS personal tracker. Lost phone without OS backup means lost history until a later export/import (JSON) or optional file sync. Cloud-first would contradict the BYOK MVP.
