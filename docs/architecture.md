# Arquitectura del proyecto

Este documento describe la arquitectura del proyecto **SkyTracker**, sus capas principales y las decisiones técnicas adoptadas.

---

## Visión general

El proyecto construye un pipeline de Data Engineering sobre datos de tráfico aéreo obtenidos desde OpenSky Network.

La arquitectura inicial prioriza Databricks como plataforma principal:

```text
OpenSky Network API
        ↓
Databricks Notebook Python
        ↓
Databricks Volume
        ↓
Bronze Delta Table
        ↓
Silver Delta Table
        ↓
Gold Delta Tables
        ↓
Databricks SQL / Dashboards
```

---

## Componentes principales

### OpenSky Network API

Fuente de datos del proyecto.

Se utiliza el endpoint de estados de aeronaves para obtener información de aviones en una zona geográfica concreta.

La respuesta contiene:

- timestamp de la API;
- número de aviones;
- lista de estados;
- información de posición, velocidad, altitud, país de origen y otros campos.

---

### Databricks

Es la plataforma principal del proyecto.

Se utiliza para:

- ejecutar notebooks;
- almacenar archivos raw;
- crear tablas Delta;
- procesar datos con Spark;
- ejecutar SQL;
- crear potenciales dashboards;
- programar workflows para la ejecución automática.

---

### Unity Catalog

Organiza los datos del proyecto en catálogo, schemas, volumes y tablas.

Estructura lógica:

```text
opensky_lakehouse
├── landing
│   └── raw_files
├── bronze
│   └── opensky_states_raw
├── silver
│   └── flight_states
└── gold
    ├── air_traffic_by_minute
    ├── air_traffic_by_country
    ├── aircraft_latest_position
    └── altitude_distribution
```

---

## Capas de datos

### Landing layer

Capa de almacenamiento de archivos crudos.

Ruta principal:

```text
/Volumes/opensky_lakehouse/landing/raw_files/opensky/states/
```

Particionado físico por fecha:

```text
/opensky/states/date=YYYY-MM-DD/opensky_states_YYYYMMDDTHHMMSS.json
```

Esta capa permite conservar el JSON original antes de cualquier transformación.

---

### Bronze layer

La capa Bronze almacena los JSON raw como registros en una tabla Delta.

Tabla:

```text
opensky_lakehouse.bronze.opensky_states_raw
```

Características:

- una fila por archivo JSON;
- conserva el JSON completo;
- incluye metadatos del archivo;
- incluye hash para evitar duplicados;
- permite trazabilidad desde el dato procesado hasta el archivo original.

Columnas principales:

```text
source_file
source_file_modification_time
source_file_size_bytes
raw_json
bronze_ingestion_timestamp
source_system
source_date
raw_hash
```

---

### Silver layer

La capa Silver transforma el JSON raw en datos estructurados.

Tabla prevista:

```text
opensky_lakehouse.silver.flight_states
```

Características:

- una fila por avión detectado;
- columnas tipadas;
- limpieza de valores;
- validación de coordenadas;
- conversión de velocidad;
- conversión de timestamps;
- eliminación o marcado de registros inválidos.

Ejemplo de columnas:

```text
event_time
retrieved_at
icao24
callsign
origin_country
longitude
latitude
baro_altitude_m
geo_altitude_m
on_ground
velocity_ms
velocity_kmh
true_track
vertical_rate
squawk
spi
position_source
source_file
bronze_ingestion_timestamp
silver_ingestion_timestamp
```

---

### Gold layer

La capa Gold contiene tablas agregadas y preparadas para análisis.

Tablas previstas:

```text
opensky_lakehouse.gold.air_traffic_by_minute
opensky_lakehouse.gold.air_traffic_by_country
opensky_lakehouse.gold.aircraft_latest_position
opensky_lakehouse.gold.altitude_distribution
```

Estas tablas están pensadas para consultas SQL, dashboards y análisis de negocio.

---

## Flujo de ejecución

### Paso 1: Setup

Notebook:

```text
00_setup_lakehouse
```

Responsabilidades:

- crear catálogo;
- crear schemas;
- crear volume.

---

### Paso 2: Ingesta raw

Notebook:

```text
01_ingest_opensky_raw
```

Responsabilidades:

- autenticarse contra OpenSky;
- llamar al endpoint de estados;
- construir payload raw;
- guardar JSON en Volume.

---

### Paso 3: Bronze

Notebook:

```text
02_bronze_from_raw_json
```

Responsabilidades:

- leer archivos JSON raw;
- convertir contenido binario a texto;
- añadir metadatos;
- calcular hash;
- guardar como tabla Delta Bronze.

---

### Paso 4: Silver

Notebook previsto:

```text
03_silver_flight_states
```

Responsabilidades:

- parsear `raw_json`;
- explotar el array `states`;
- mapear índices de OpenSky a columnas;
- limpiar y tipar campos;
- guardar como tabla Delta Silver.

---

### Paso 5: Gold

Notebook previsto:

```text
04_gold_analytics
```

Responsabilidades:

- crear agregaciones;
- calcular métricas;
- construir tablas listas para análisis.

---

## Decisiones de arquitectura

### Databricks-first

Se ha decidido empezar sin Kafka para evitar problemas de conectividad entre un Kafka local y Databricks.

La primera versión funcional será:

```text
OpenSky API → Databricks → Delta Lake → SQL
```

La extensión posterior será:

```text
OpenSky API → Kafka accesible desde Databricks → Structured Streaming → Delta Lake
```

---

### Mantener JSON raw en Bronze

La capa Bronze conserva el JSON completo para:

- trazabilidad;
- reproducibilidad;
- auditoría;
- reprocesamiento;
- depuración de errores.

---

### Usar Delta Lake

Delta Lake se utiliza para:

- almacenamiento fiable;
- manejo de schemas;
- soporte de SQL;
- tablas versionadas;
- integración nativa con Databricks.

---

## Consideraciones de escalabilidad


Kafka se integrará como capa intermedia cuando el pipeline base esté terminado.

Arquitectura futura:

```text
OpenSky API
        ↓
Python Kafka Producer
        ↓
Kafka Topic: opensky.raw.states
        ↓
Databricks Structured Streaming
        ↓
Bronze Delta Table
        ↓
Silver Delta Table
        ↓
Gold Delta Tables
```

Kafka deberá estar desplegado en un entorno accesible desde Databricks, por ejemplo:

- Kafka gestionado;
- Confluent Cloud;
- Kafka en una VM pública;
- Kafka en una red conectada al workspace.
