# Modelo de datos

Este documento describe el modelo de datos del proyecto **SkyTracker**.

---

## Fuente de datos

La fuente principal es OpenSky Network.

La ingesta obtiene un JSON con esta estructura general:

```json
{
  "source": "opensky",
  "retrieved_at": "2026-07-01T11:16:09+00:00",
  "bounding_box": {
    "lamin": 35.0,
    "lomin": -10.0,
    "lamax": 44.5,
    "lomax": 4.5
  },
  "api_time": 1782904569,
  "aircraft_count": 123,
  "states": [
    [...]
  ]
}
```

El campo `states` contiene una lista de arrays. Cada array representa el estado de una aeronave.

---

## Landing

La capa Landing no tiene modelo tabular. Guarda archivos JSON completos.

Ruta:

```text
/Volumes/opensky_lakehouse/landing/raw_files/opensky/states/date=YYYY-MM-DD/
```

Nombre de archivo:

```text
opensky_states_YYYYMMDDTHHMMSS.json
```

---

## Bronze

Tabla:

```text
opensky_lakehouse.bronze.opensky_states_raw
```

Granularidad:

```text
1 fila = 1 archivo JSON raw
```

### Columnas

| Columna | Tipo esperado | Descripción |
|---|---|---|
| `source_file` | STRING | Ruta del archivo JSON original |
| `source_file_modification_time` | TIMESTAMP | Fecha de modificación del archivo |
| `source_file_size_bytes` | BIGINT | Tamaño del archivo |
| `raw_json` | STRING | JSON completo en texto |
| `bronze_ingestion_timestamp` | TIMESTAMP | Momento de ingesta en Bronze |
| `source_system` | STRING | Sistema origen, en este caso `opensky` |
| `source_date` | STRING | Fecha extraída de la ruta |
| `raw_hash` | STRING | Hash SHA-256 del JSON raw |

### Uso

Bronze se utiliza para:

- auditoría;
- deduplicación;
- trazabilidad;
- reprocesamiento;
- validación inicial.

---

## Silver

Tabla prevista:

```text
opensky_lakehouse.silver.flight_states
```

Granularidad:

```text
1 fila = 1 estado de avión detectado en una ingesta
```

### Columnas previstas

| Columna | Tipo esperado | Descripción |
|---|---|---|
| `event_time` | TIMESTAMP | Timestamp de OpenSky convertido desde `api_time` |
| `retrieved_at` | TIMESTAMP | Momento en que se consultó la API |
| `icao24` | STRING | Identificador único ICAO 24-bit |
| `callsign` | STRING | Callsign del avión |
| `origin_country` | STRING | País de origen |
| `time_position` | BIGINT | Timestamp de última posición |
| `last_contact` | BIGINT | Timestamp de último contacto |
| `longitude` | DOUBLE | Longitud |
| `latitude` | DOUBLE | Latitud |
| `baro_altitude_m` | DOUBLE | Altitud barométrica en metros |
| `on_ground` | BOOLEAN | Indica si el avión está en tierra |
| `velocity_ms` | DOUBLE | Velocidad en metros por segundo |
| `velocity_kmh` | DOUBLE | Velocidad en kilómetros por hora |
| `true_track` | DOUBLE | Rumbo en grados |
| `vertical_rate` | DOUBLE | Ratio vertical |
| `sensors` | STRING | Sensores asociados, si existen |
| `geo_altitude_m` | DOUBLE | Altitud geométrica |
| `squawk` | STRING | Código squawk |
| `spi` | BOOLEAN | Special Purpose Indicator |
| `position_source` | INT | Fuente de posición |
| `source_file` | STRING | Archivo origen |
| `raw_hash` | STRING | Hash del JSON origen |
| `silver_ingestion_timestamp` | TIMESTAMP | Momento de ingesta en Silver |

---

## Mapeo de `states`

OpenSky devuelve cada avión como un array posicional. El mapeo previsto es:

| Índice | Campo | Tipo esperado |
|---:|---|---|
| 0 | `icao24` | STRING |
| 1 | `callsign` | STRING |
| 2 | `origin_country` | STRING |
| 3 | `time_position` | BIGINT |
| 4 | `last_contact` | BIGINT |
| 5 | `longitude` | DOUBLE |
| 6 | `latitude` | DOUBLE |
| 7 | `baro_altitude_m` | DOUBLE |
| 8 | `on_ground` | BOOLEAN |
| 9 | `velocity_ms` | DOUBLE |
| 10 | `true_track` | DOUBLE |
| 11 | `vertical_rate` | DOUBLE |
| 12 | `sensors` | ARRAY |
| 13 | `geo_altitude_m` | DOUBLE |
| 14 | `squawk` | STRING |
| 15 | `spi` | BOOLEAN |
| 16 | `position_source` | INT |

---

## Reglas de limpieza en Silver

Reglas previstas:

- `icao24` no puede ser nulo.
- `callsign` debe recortarse con `trim`.
- `longitude` debe estar entre `-180` y `180`.
- `latitude` debe estar entre `-90` y `90`.
- registros sin coordenadas pueden descartarse o marcarse como inválidos.
- `velocity_kmh = velocity_ms * 3.6`.
- `event_time` se genera desde `api_time`.
- `retrieved_at` se convierte a timestamp.
- se añade `silver_ingestion_timestamp`.

---

## Gold

La capa Gold contiene tablas agregadas.

---

### `gold.air_traffic_by_minute`

Granularidad:

```text
1 fila = 1 minuto
```

Columnas previstas:

| Columna | Descripción |
|---|---|
| `window_start` | Inicio de ventana |
| `window_end` | Fin de ventana |
| `active_aircraft` | Aviones únicos |
| `avg_velocity_kmh` | Velocidad media |
| `avg_altitude_m` | Altitud media |
| `on_ground_aircraft` | Aviones en tierra |
| `in_air_aircraft` | Aviones en vuelo |

---

### `gold.air_traffic_by_country`

Granularidad:

```text
1 fila = país + ventana temporal
```

Columnas previstas:

| Columna | Descripción |
|---|---|
| `origin_country` | País de origen |
| `window_start` | Inicio de ventana |
| `window_end` | Fin de ventana |
| `active_aircraft` | Aviones únicos |
| `avg_velocity_kmh` | Velocidad media |
| `avg_altitude_m` | Altitud media |

---

### `gold.aircraft_latest_position`

Granularidad:

```text
1 fila = último estado conocido de cada avión
```

Columnas previstas:

| Columna | Descripción |
|---|---|
| `icao24` | Identificador del avión |
| `callsign` | Callsign |
| `origin_country` | País |
| `event_time` | Último evento |
| `longitude` | Última longitud |
| `latitude` | Última latitud |
| `baro_altitude_m` | Última altitud |
| `velocity_kmh` | Última velocidad |
| `on_ground` | Estado tierra/vuelo |

---

### `gold.altitude_distribution`

Granularidad:

```text
1 fila = rango de altitud
```

Columnas previstas:

| Columna | Descripción |
|---|---|
| `altitude_band` | Rango de altitud |
| `aircraft_count` | Número de aviones |
| `avg_velocity_kmh` | Velocidad media |
| `min_altitude_m` | Altitud mínima |
| `max_altitude_m` | Altitud máxima |

---

## Trazabilidad

La trazabilidad se mantiene mediante:

```text
source_file
raw_hash
bronze_ingestion_timestamp
silver_ingestion_timestamp
```

Esto permite saber de qué archivo raw procede cada registro procesado.
