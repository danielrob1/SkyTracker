# Pasos del pipeline

Este documento resume el flujo de ejecución del proyecto **OpenSky Flight Lakehouse**.

---

## Flujo general

```text
00_setup_lakehouse
        ↓
01_ingest_opensky_raw
        ↓
02_bronze_from_raw_json
        ↓
sql/bronze_checks.sql
        ↓
03_silver_flight_states
        ↓
04_gold_analytics
        ↓
05_sql_queries
```

---

## Paso 0: Setup Lakehouse

Notebook:

```text
databricks/00_setup_lakehouse.sql
```

Objetivo:

- crear catálogo;
- crear schemas;
- crear volume.

Crea:

```text
opensky_lakehouse
├── landing
├── bronze
├── silver
└── gold
```

Y el volume:

```text
opensky_lakehouse.landing.raw_files
```

---

## Paso 1: Ingesta raw desde OpenSky

Notebook:

```text
databricks/01_ingest_opensky_raw.py
```

Objetivo:

```text
OpenSky API → JSON raw en Databricks Volume
```

Responsabilidades:

- cargar secrets;
- obtener token;
- consultar endpoint de estados;
- crear payload raw;
- guardar JSON en Volume.

Salida esperada:

```text
/Volumes/opensky_lakehouse/landing/raw_files/opensky/states/date=YYYY-MM-DD/opensky_states_YYYYMMDDTHHMMSS.json
```

---

## Paso 2: Crear tabla Bronze

Notebook:

```text
databricks/02_bronze_from_raw_json.py
```

Objetivo:

```text
JSON raw en Volume → Delta Bronze Table
```

Responsabilidades:

- leer archivos con `binaryFile`;
- convertir contenido a string;
- añadir metadatos;
- calcular hash;
- evitar duplicados;
- guardar como tabla Delta.

Salida esperada:

```text
opensky_lakehouse.bronze.opensky_states_raw
```

---

## Paso 3: Checks Bronze

Archivo:

```text
sql/bronze_checks.sql
```

Objetivo:

- comprobar que hay datos;
- comprobar duplicados;
- comprobar JSON vacío;
- comprobar tamaño de archivos;
- comprobar campos obligatorios;
- generar resumen PASS/FAIL.

Resultado esperado:

```text
Todos los checks principales en PASS
```

---

## Paso 4: Crear tabla Silver

Notebook previsto:

```text
databricks/03_silver_flight_states.py
```

Objetivo:

```text
Bronze raw_json → Silver flight states
```

Responsabilidades previstas:

- parsear JSON;
- extraer `api_time`, `retrieved_at` y `states`;
- explotar `states`;
- convertir arrays posicionales en columnas;
- tipar datos;
- limpiar `callsign`;
- validar coordenadas;
- calcular `velocity_kmh`;
- guardar como tabla Delta Silver.

Salida esperada:

```text
opensky_lakehouse.silver.flight_states
```

---

## Paso 5: Crear tablas Gold

Notebook previsto:

```text
databricks/04_gold_analytics.py
```

Objetivo:

```text
Silver → Gold analytics tables
```

Tablas previstas:

```text
opensky_lakehouse.gold.air_traffic_by_minute
opensky_lakehouse.gold.air_traffic_by_country
opensky_lakehouse.gold.aircraft_latest_position
opensky_lakehouse.gold.altitude_distribution
```

---

## Paso 6: Consultas SQL

Notebook previsto:

```text
databricks/05_sql_queries.sql
```

Objetivo:

- consultar tablas Gold;
- preparar métricas;
- generar queries para dashboard;
- validar resultados analíticos.

---

## Ejecución manual inicial

Mientras el proyecto está en desarrollo, la ejecución será manual:

```text
1. Ejecutar 00_setup_lakehouse
2. Ejecutar 01_ingest_opensky_raw
3. Ejecutar 02_bronze_from_raw_json
4. Ejecutar bronze_checks.sql
5. Ejecutar 03_silver_flight_states
6. Ejecutar 04_gold_analytics
7. Ejecutar 05_sql_queries
```

---

## Ejecución futura con Workflows

En una fase posterior se podrá crear un Databricks Workflow:

```text
Task 1: Ingest OpenSky Raw
Task 2: Bronze Load
Task 3: Bronze Checks
Task 4: Silver Transform
Task 5: Gold Aggregations
Task 6: SQL Validation
```


