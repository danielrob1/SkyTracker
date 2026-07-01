# SkyTracker

Proyecto de **Data Engineering** basado en la API de **OpenSky Network** y desarrollado con **Python, Databricks, Spark, Delta Lake y SQL**.

El objetivo principal es construir un pipeline completo de datos sobre tráfico aéreo, desde la ingesta de datos crudos hasta la creación de tablas analíticas listas para consulta y visualización.

Este proyecto está diseñado con enfoque de portfolio, priorizando una arquitectura clara, buenas prácticas de ingeniería de datos, trazabilidad, calidad de datos y documentación.

---

## Objetivos del proyecto

- Practicar Databricks desde cero en un caso real.
- Consumir datos reales desde la API de OpenSky Network.
- Construir un flujo Lakehouse usando arquitectura Medallion.
- Guardar datos raw en Volumes.
- Crear tablas Delta Bronze, Silver y Gold.
- Aplicar transformaciones con Spark.
- Realizar análisis mediante SQL.
- Añadir checks de calidad de datos.
- Preparar una futura integración con Kafka.

---

## Stack tecnológico

| Tecnología | Uso en el proyecto |
|---|---|
| Python | Ingesta desde la API de OpenSky |
| Requests | Cliente HTTP para consumir la API |
| Databricks | Plataforma principal del proyecto |
| Spark | Procesamiento distribuido |
| Delta Lake | Almacenamiento transaccional |
| SQL | Validaciones y análisis |
| Unity Catalog | Organización de catálogos, schemas, tablas y volumes |
| Databricks Volumes | Almacenamiento de JSON raw |
| Kafka | Extensión futura para streaming |

---

## Arquitectura general

```text
OpenSky Network API
        ↓
Databricks Notebook Python
        ↓
Raw JSON en Databricks Volume
        ↓
Bronze Delta Table
        ↓
Silver Delta Table
        ↓
Gold Delta Tables
        ↓
Databricks SQL / Dashboards
```

La versión inicial del proyecto prioriza que todo funcione correctamente en Databricks. Kafka se plantea como una evolución posterior para evitar problemas de conectividad entre brokers locales y el workspace de Databricks.

---

## Arquitectura Medallion

El proyecto sigue una arquitectura por capas:

### Landing

Zona donde se almacenan los archivos JSON crudos descargados desde OpenSky.

Ejemplo de ruta:

```text
/Volumes/opensky_lakehouse/landing/raw_files/opensky/states/
```

### Bronze

Tabla con los archivos raw convertidos en registros Delta, manteniendo trazabilidad del fichero original.

Tabla:

```text
opensky_lakehouse.bronze.opensky_states_raw
```

### Silver

Tabla limpia y normalizada, con una fila por avión detectado.

Tabla prevista:

```text
opensky_lakehouse.silver.flight_states
```

### Gold

Tablas agregadas para análisis y dashboards.

Tablas previstas:

```text
opensky_lakehouse.gold.air_traffic_by_minute
opensky_lakehouse.gold.air_traffic_by_country
opensky_lakehouse.gold.aircraft_latest_position
opensky_lakehouse.gold.altitude_distribution
```

---

## Estructura del repositorio

```text
SkyTracker/
│
├── README.md
├── .gitignore
│
├── databricks/
│   ├── 00_setup_lakehouse.sql
│   ├── 01_ingest_opensky_raw.py
│   ├── 02_bronze_from_raw_json.py
│   ├── 03_silver_flight_states.py
│   ├── 04_gold_analytics.py
│   └── 05_sql_queries.sql
│
├── sql/
│   └── bronze_checks.sql
│
├── docs/
│   ├── architecture.md
│   ├── databricks_setup.md
│   ├── data_model.md
│   ├── pipeline_steps.md
│   ├── data_quality.md
│   ├── kafka_extension.md
│   ├── troubleshooting.md
│   └── portfolio_notes.md
│
└── assets/
    └── architecture.png
```

---

## Notebooks del proyecto

| Notebook | Descripción |
|---|---|
| `00_setup_lakehouse` | Crea catálogo, schemas y volume |
| `01_ingest_opensky_raw` | Consume la API de OpenSky y guarda JSON raw |
| `02_bronze_from_raw_json` | Convierte archivos raw en tabla Delta Bronze |
| `03_silver_flight_states` | Normaliza los datos a una fila por avión |
| `04_gold_analytics` | Crea tablas agregadas para análisis |
| `05_sql_queries` | Consultas SQL de explotación |

---


---

## Cómo ejecutar el proyecto

### 1. Ejecutar setup inicial

Ejecutar el notebook:

```text
databricks/00_setup_lakehouse.sql
```

Este notebook crea:

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

### 2. Configurar secrets

El notebook de ingesta espera estos secrets:

```text
scope: opensky
keys:
  - client_id
  - client_secret
```

### 3. Ejecutar ingesta raw

Ejecutar:

```text
databricks/01_ingest_opensky_raw.py
```

Resultado esperado:

```text
Raw JSON guardado en:
/Volumes/opensky_lakehouse/landing/raw_files/opensky/states/date=YYYY-MM-DD/
```

### 4. Crear tabla Bronze

Ejecutar:

```text
databricks/02_bronze_from_raw_json.py
```

Resultado esperado:

```text
opensky_lakehouse.bronze.opensky_states_raw
```

### 5. Ejecutar checks Bronze

Ejecutar:

```text
sql/bronze_checks.sql
```

Resultado esperado:

```text
Todos los checks principales en PASS
```

---

## Preguntas analíticas previstas

Cuando las capas Silver y Gold estén completas, el proyecto permitirá responder preguntas como:

- ¿Cuántos aviones hay activos por minuto?
- ¿Qué países de origen aparecen con más frecuencia?
- ¿Cuál es la altitud media de los aviones detectados?
- ¿Qué aviones están en tierra?
- ¿Cuáles son los aviones con mayor velocidad?
- ¿Cuál es la última posición conocida de cada avión?
- ¿Cómo evoluciona el tráfico aéreo en una ventana temporal?

---


---

## Seguridad

Este repositorio no debe contener:

- `client_id`
- `client_secret`
- tokens
- archivos `.env`
- dumps grandes de datos
- archivos raw descargados desde la API

Las credenciales se gestionan mediante Databricks Secrets.

---


