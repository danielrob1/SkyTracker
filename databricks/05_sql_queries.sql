-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 05 SQL Queries — OpenSky Flight Lakehouse
-- MAGIC
-- MAGIC Este notebook contiene consultas analíticas sobre la capa **Gold** del proyecto.
-- MAGIC
-- MAGIC A diferencia del notebook `04_gold_analytics`, este notebook **no crea tablas principales**. Su objetivo es explotar las tablas Gold para obtener insights, preparar visualizaciones y generar resultados para portfolio.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 0. Seleccionar catálogo y schema Gold
-- MAGIC
-- MAGIC Configuramos el catálogo y el schema donde están las tablas Gold.

-- COMMAND ----------

USE CATALOG opensky_lakehouse;
USE SCHEMA gold;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 1. Tablas Gold disponibles
-- MAGIC
-- MAGIC Muestra las tablas disponibles en el schema Gold.

-- COMMAND ----------

SHOW TABLES IN opensky_lakehouse.gold;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2. Resumen ejecutivo del tráfico aéreo
-- MAGIC
-- MAGIC Responde a preguntas generales:
-- MAGIC
-- MAGIC - ¿Cuántos registros hay por día?
-- MAGIC - ¿Cuántos aviones únicos se han detectado?
-- MAGIC - ¿Cuántos países aparecen?
-- MAGIC - ¿Cuál es la velocidad y altitud media?
-- MAGIC - ¿Qué porcentaje está en tierra o en vuelo?

-- COMMAND ----------

SELECT
  event_date,
  total_records,
  unique_aircraft,
  unique_origin_countries,
  source_files_processed,
  first_event_time,
  last_event_time,
  avg_velocity_kmh,
  min_velocity_kmh,
  max_velocity_kmh,
  avg_baro_altitude_m,
  min_baro_altitude_m,
  max_baro_altitude_m,
  records_on_ground,
  records_in_air,
  pct_records_on_ground,
  pct_records_in_air
FROM flight_activity_summary
ORDER BY event_date DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 3. Resumen global del proyecto

-- COMMAND ----------

SELECT
  SUM(total_records) AS total_records_processed,
  SUM(source_files_processed) AS total_source_files_processed,
  SUM(unique_aircraft) AS sum_daily_unique_aircraft,
  MAX(unique_aircraft) AS max_unique_aircraft_single_day,
  MAX(unique_origin_countries) AS max_unique_origin_countries_single_day,
  MIN(first_event_time) AS first_event_time,
  MAX(last_event_time) AS last_event_time,
  ROUND(AVG(avg_velocity_kmh), 2) AS avg_velocity_kmh,
  ROUND(AVG(avg_baro_altitude_m), 2) AS avg_baro_altitude_m,
  ROUND(AVG(pct_records_on_ground), 2) AS avg_pct_records_on_ground,
  ROUND(AVG(pct_records_in_air), 2) AS avg_pct_records_in_air
FROM flight_activity_summary;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 4. Evolución de aviones activos por minuto
-- MAGIC
-- MAGIC Buena consulta para un gráfico de líneas:
-- MAGIC
-- MAGIC - Eje X: `window_start`
-- MAGIC - Eje Y: `active_aircraft`

-- COMMAND ----------

SELECT
  window_start,
  window_end,
  active_aircraft,
  total_records,
  unique_origin_countries,
  avg_velocity_kmh,
  avg_baro_altitude_m,
  records_on_ground,
  records_in_air
FROM air_traffic_by_minute
ORDER BY window_start;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 5. Minuto con más tráfico aéreo
-- MAGIC
-- MAGIC Responde:
-- MAGIC
-- MAGIC - ¿En qué minuto se detectaron más aviones?
-- MAGIC - ¿Qué snapshot tuvo más actividad?

-- COMMAND ----------

SELECT
  window_start,
  window_end,
  active_aircraft,
  total_records,
  unique_origin_countries,
  avg_velocity_kmh,
  avg_baro_altitude_m,
  records_on_ground,
  records_in_air
FROM air_traffic_by_minute
ORDER BY active_aircraft DESC
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 6. Top países por aviones únicos detectados
-- MAGIC
-- MAGIC Buena consulta para gráfico de barras por país de origen.

-- COMMAND ----------

SELECT
  origin_country,
  SUM(total_records) AS total_records,
  SUM(unique_aircraft) AS total_unique_aircraft_observations,
  ROUND(AVG(avg_velocity_kmh), 2) AS avg_velocity_kmh,
  ROUND(AVG(avg_baro_altitude_m), 2) AS avg_baro_altitude_m,
  SUM(records_on_ground) AS records_on_ground,
  SUM(records_in_air) AS records_in_air,
  MIN(first_seen) AS first_seen,
  MAX(last_seen) AS last_seen
FROM air_traffic_by_country
GROUP BY origin_country
ORDER BY total_unique_aircraft_observations DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 7. Top países por registros en vuelo
-- MAGIC
-- MAGIC Responde:
-- MAGIC
-- MAGIC - ¿Qué países tienen más registros de aviones en el aire?
-- MAGIC - ¿Qué porcentaje de sus registros corresponde a aviones en vuelo?

-- COMMAND ----------

SELECT
  origin_country,
  SUM(records_in_air) AS total_records_in_air,
  SUM(records_on_ground) AS total_records_on_ground,
  SUM(total_records) AS total_records,
  ROUND(
    100.0 * SUM(records_in_air) / SUM(total_records),
    2
  ) AS pct_records_in_air
FROM air_traffic_by_country
GROUP BY origin_country
HAVING SUM(total_records) > 0
ORDER BY total_records_in_air DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 8. Países con mayor velocidad media
-- MAGIC
-- MAGIC Filtramos países con pocos registros para evitar resultados poco representativos.

-- COMMAND ----------

SELECT
  origin_country,
  SUM(total_records) AS total_records,
  SUM(unique_aircraft) AS unique_aircraft_observations,
  ROUND(AVG(avg_velocity_kmh), 2) AS avg_velocity_kmh,
  ROUND(AVG(avg_baro_altitude_m), 2) AS avg_baro_altitude_m
FROM air_traffic_by_country
GROUP BY origin_country
HAVING SUM(total_records) >= 3
ORDER BY avg_velocity_kmh DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 9. Última posición conocida de cada avión
-- MAGIC

-- COMMAND ----------

SELECT
  last_event_time,
  icao24,
  callsign,
  origin_country,
  longitude,
  latitude,
  baro_altitude_m,
  geo_altitude_m,
  on_ground,
  velocity_kmh,
  true_track,
  vertical_rate
FROM aircraft_latest_position
ORDER BY last_event_time DESC
LIMIT 100;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 10. Aviones más rápidos detectados
-- MAGIC
-- MAGIC Responde:
-- MAGIC
-- MAGIC - ¿Cuáles fueron los aviones con mayor velocidad registrada?

-- COMMAND ----------

SELECT
  last_event_time,
  icao24,
  callsign,
  origin_country,
  velocity_kmh,
  baro_altitude_m,
  geo_altitude_m,
  longitude,
  latitude,
  on_ground,
  true_track
FROM aircraft_latest_position
WHERE velocity_kmh IS NOT NULL
ORDER BY velocity_kmh DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 11. Aviones a mayor altitud
-- MAGIC
-- MAGIC Responde:
-- MAGIC
-- MAGIC - ¿Qué aviones estaban volando más alto?

-- COMMAND ----------

SELECT
  last_event_time,
  icao24,
  callsign,
  origin_country,
  baro_altitude_m,
  geo_altitude_m,
  velocity_kmh,
  longitude,
  latitude,
  on_ground
FROM aircraft_latest_position
WHERE baro_altitude_m IS NOT NULL
ORDER BY baro_altitude_m DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 12. Aviones actualmente en tierra según última posición
-- MAGIC
-- MAGIC Lista los aviones cuyo último estado registrado indica que estaban en tierra.

-- COMMAND ----------

SELECT
  last_event_time,
  icao24,
  callsign,
  origin_country,
  longitude,
  latitude,
  baro_altitude_m,
  velocity_kmh,
  on_ground
FROM aircraft_latest_position
WHERE on_ground = true
ORDER BY last_event_time DESC
LIMIT 50;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 13. Aviones actualmente en vuelo según última posición
-- MAGIC
-- MAGIC Lista los aviones cuyo último estado registrado indica que estaban en vuelo.

-- COMMAND ----------

SELECT
  last_event_time,
  icao24,
  callsign,
  origin_country,
  longitude,
  latitude,
  baro_altitude_m,
  geo_altitude_m,
  velocity_kmh,
  true_track
FROM aircraft_latest_position
WHERE on_ground = false
ORDER BY baro_altitude_m DESC
LIMIT 50;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 14. Distribución de altitud por día
-- MAGIC
-- MAGIC Buena consulta para gráfico de barras por bandas de altitud.

-- COMMAND ----------

SELECT
  event_date,
  altitude_band,
  total_records,
  unique_aircraft,
  avg_velocity_kmh,
  min_baro_altitude_m,
  max_baro_altitude_m
FROM altitude_distribution
ORDER BY event_date DESC, altitude_band_order;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 15. Distribución global de altitud
-- MAGIC
-- MAGIC Agrupa todos los días y muestra la distribución global de vuelos por bandas de altitud.
-- MAGIC

-- COMMAND ----------

SELECT
  altitude_band,
  altitude_band_order,
  SUM(total_records) AS total_records,
  SUM(unique_aircraft) AS unique_aircraft_observations,
  ROUND(AVG(avg_velocity_kmh), 2) AS avg_velocity_kmh,
  MIN(min_baro_altitude_m) AS min_baro_altitude_m,
  MAX(max_baro_altitude_m) AS max_baro_altitude_m
FROM altitude_distribution
GROUP BY altitude_band, altitude_band_order
ORDER BY altitude_band_order;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 16. Comparativa tierra vs vuelo por día
-- MAGIC

-- COMMAND ----------

SELECT
  event_date,
  records_on_ground,
  records_in_air,
  total_records,
  pct_records_on_ground,
  pct_records_in_air
FROM flight_activity_summary
ORDER BY event_date DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 17. Países con mayor altitud media
-- MAGIC
-- MAGIC Filtramos países con pocos registros para reducir ruido en el análisis.

-- COMMAND ----------

SELECT
  origin_country,
  SUM(total_records) AS total_records,
  SUM(unique_aircraft) AS unique_aircraft_observations,
  ROUND(AVG(avg_baro_altitude_m), 2) AS avg_baro_altitude_m,
  ROUND(AVG(avg_velocity_kmh), 2) AS avg_velocity_kmh
FROM air_traffic_by_country
GROUP BY origin_country
HAVING SUM(total_records) >= 3
ORDER BY avg_baro_altitude_m DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 18. Últimas posiciones preparadas para visualización en mapa
-- MAGIC
-- MAGIC Columnas mínimas para un mapa:
-- MAGIC
-- MAGIC - `latitude`
-- MAGIC - `longitude`
-- MAGIC - `aircraft_label`
-- MAGIC - métricas como velocidad, altitud y estado tierra/vuelo.

-- COMMAND ----------

SELECT
  latitude,
  longitude,
  CONCAT(
    COALESCE(callsign, 'Unknown'),
    ' - ',
    COALESCE(origin_country, 'Unknown')
  ) AS aircraft_label,
  icao24,
  callsign,
  origin_country,
  velocity_kmh,
  baro_altitude_m,
  on_ground,
  last_event_time
FROM aircraft_latest_position
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
ORDER BY last_event_time DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 19. Ranking de países por presencia relativa
-- MAGIC
-- MAGIC Calcula qué porcentaje de registros representa cada país sobre el total.

-- COMMAND ----------

WITH country_totals AS (
  SELECT
    origin_country,
    SUM(total_records) AS country_records
  FROM air_traffic_by_country
  GROUP BY origin_country
),

global_total AS (
  SELECT
    SUM(country_records) AS all_records
  FROM country_totals
)

SELECT
  c.origin_country,
  c.country_records,
  ROUND(100.0 * c.country_records / g.all_records, 2) AS pct_of_total_records
FROM country_totals c
CROSS JOIN global_total g
ORDER BY pct_of_total_records DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 20. Ventanas con mayor velocidad media
-- MAGIC
-- MAGIC Responde:
-- MAGIC
-- MAGIC - ¿En qué snapshots la velocidad media fue mayor?

-- COMMAND ----------

SELECT
  window_start,
  window_end,
  active_aircraft,
  total_records,
  avg_velocity_kmh,
  min_velocity_kmh,
  max_velocity_kmh,
  avg_baro_altitude_m
FROM air_traffic_by_minute
WHERE avg_velocity_kmh IS NOT NULL
ORDER BY avg_velocity_kmh DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 21. Ventanas con mayor altitud media
-- MAGIC
-- MAGIC Responde:
-- MAGIC
-- MAGIC - ¿En qué snapshots la altitud media fue mayor?

-- COMMAND ----------

SELECT
  window_start,
  window_end,
  active_aircraft,
  total_records,
  avg_baro_altitude_m,
  min_baro_altitude_m,
  max_baro_altitude_m,
  avg_velocity_kmh
FROM air_traffic_by_minute
WHERE avg_baro_altitude_m IS NOT NULL
ORDER BY avg_baro_altitude_m DESC
LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 22. Resumen para dashboard principal
-- MAGIC
-- MAGIC Devuelve una sola fila con KPIs generales.
-- MAGIC

-- COMMAND ----------

SELECT
  SUM(total_records) AS total_records,
  SUM(source_files_processed) AS source_files_processed,
  MAX(unique_aircraft) AS max_aircraft_detected_in_single_day,
  MAX(unique_origin_countries) AS max_origin_countries_single_day,
  MIN(first_event_time) AS first_event_time,
  MAX(last_event_time) AS last_event_time,
  ROUND(AVG(avg_velocity_kmh), 2) AS avg_velocity_kmh,
  ROUND(AVG(avg_baro_altitude_m), 2) AS avg_baro_altitude_m,
  ROUND(AVG(pct_records_on_ground), 2) AS avg_pct_on_ground,
  ROUND(AVG(pct_records_in_air), 2) AS avg_pct_in_air
FROM flight_activity_summary;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 23. Métricas del pipeline completo

-- COMMAND ----------

SELECT
  'bronze_raw_files' AS metric_name,
  COUNT(*) AS metric_value
FROM opensky_lakehouse.bronze.opensky_states_raw

UNION ALL

SELECT
  'silver_flight_state_records' AS metric_name,
  COUNT(*) AS metric_value
FROM opensky_lakehouse.silver.flight_states

UNION ALL

SELECT
  'gold_air_traffic_by_minute_rows' AS metric_name,
  COUNT(*) AS metric_value
FROM opensky_lakehouse.gold.air_traffic_by_minute

UNION ALL

SELECT
  'gold_air_traffic_by_country_rows' AS metric_name,
  COUNT(*) AS metric_value
FROM opensky_lakehouse.gold.air_traffic_by_country

UNION ALL

SELECT
  'gold_aircraft_latest_position_rows' AS metric_name,
  COUNT(*) AS metric_value
FROM opensky_lakehouse.gold.aircraft_latest_position

UNION ALL

SELECT
  'gold_altitude_distribution_rows' AS metric_name,
  COUNT(*) AS metric_value
FROM opensky_lakehouse.gold.altitude_distribution

UNION ALL

SELECT
  'gold_flight_activity_summary_rows' AS metric_name,
  COUNT(*) AS metric_value
FROM opensky_lakehouse.gold.flight_activity_summary;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 24. KPIs finales
-- MAGIC Combina:
-- MAGIC
-- MAGIC - métricas globales;
-- MAGIC - último snapshot;
-- MAGIC - aviones activos recientes;
-- MAGIC - velocidad y altitud media.

-- COMMAND ----------

WITH global_summary AS (
  SELECT
    SUM(total_records) AS total_records,
    SUM(source_files_processed) AS source_files_processed,
    MAX(unique_aircraft) AS max_unique_aircraft,
    MAX(unique_origin_countries) AS max_unique_origin_countries,
    ROUND(AVG(avg_velocity_kmh), 2) AS avg_velocity_kmh,
    ROUND(AVG(avg_baro_altitude_m), 2) AS avg_baro_altitude_m,
    ROUND(AVG(pct_records_in_air), 2) AS avg_pct_in_air
  FROM flight_activity_summary
),

latest_snapshot AS (
  SELECT
    window_start AS latest_window_start,
    active_aircraft AS latest_active_aircraft,
    unique_origin_countries AS latest_unique_origin_countries,
    avg_velocity_kmh AS latest_avg_velocity_kmh,
    avg_baro_altitude_m AS latest_avg_altitude_m
  FROM air_traffic_by_minute
  ORDER BY window_start DESC
  LIMIT 1
)

SELECT
  g.total_records,
  g.source_files_processed,
  g.max_unique_aircraft,
  g.max_unique_origin_countries,
  g.avg_velocity_kmh,
  g.avg_baro_altitude_m,
  g.avg_pct_in_air,
  l.latest_window_start,
  l.latest_active_aircraft,
  l.latest_unique_origin_countries,
  l.latest_avg_velocity_kmh,
  l.latest_avg_altitude_m
FROM global_summary g
CROSS JOIN latest_snapshot l;
