-- ============================================================
-- 0. Seleccionar catálogo y schema
-- ============================================================

USE CATALOG opensky_lakehouse;
USE SCHEMA silver;


-- ============================================================
-- 1. Vista rápida de la tabla Silver
-- ============================================================

SELECT *
FROM flight_states
LIMIT 20;


-- ============================================================
-- 2. Resumen general de la tabla Silver
-- ============================================================

SELECT
  COUNT(*) AS total_records,
  COUNT(DISTINCT state_hash) AS unique_state_hashes,
  COUNT(DISTINCT icao24) AS unique_aircraft,
  COUNT(DISTINCT origin_country) AS unique_origin_countries,
  MIN(event_time) AS first_event_time,
  MAX(event_time) AS last_event_time,
  MIN(silver_ingestion_timestamp) AS first_silver_ingestion,
  MAX(silver_ingestion_timestamp) AS last_silver_ingestion
FROM flight_states;


-- ============================================================
-- 3. Check de duplicados por state_hash
-- Resultado esperado: 0 filas
-- ============================================================

SELECT
  state_hash,
  COUNT(*) AS repetitions,
  COLLECT_SET(icao24) AS aircraft_ids,
  COLLECT_SET(source_file) AS source_files
FROM flight_states
GROUP BY state_hash
HAVING COUNT(*) > 1;


-- ============================================================
-- 4. Check de campos obligatorios nulos
-- Resultado esperado: todos los valores a 0
-- ============================================================

SELECT
  SUM(CASE WHEN state_hash IS NULL THEN 1 ELSE 0 END) AS null_state_hash,
  SUM(CASE WHEN raw_hash IS NULL THEN 1 ELSE 0 END) AS null_raw_hash,
  SUM(CASE WHEN source_file IS NULL THEN 1 ELSE 0 END) AS null_source_file,
  SUM(CASE WHEN event_time IS NULL THEN 1 ELSE 0 END) AS null_event_time,
  SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END) AS null_event_date,
  SUM(CASE WHEN icao24 IS NULL THEN 1 ELSE 0 END) AS null_icao24,
  SUM(CASE WHEN longitude IS NULL THEN 1 ELSE 0 END) AS null_longitude,
  SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) AS null_latitude,
  SUM(CASE WHEN silver_ingestion_timestamp IS NULL THEN 1 ELSE 0 END) AS null_silver_ingestion_timestamp
FROM flight_states;


-- ============================================================
-- 5. Check de coordenadas fuera de rango
-- Resultado esperado: 0 filas
-- ============================================================

SELECT
  icao24,
  callsign,
  origin_country,
  longitude,
  latitude,
  event_time,
  source_file
FROM flight_states
WHERE longitude < -180
   OR longitude > 180
   OR latitude < -90
   OR latitude > 90
   OR longitude IS NULL
   OR latitude IS NULL;


-- ============================================================
-- 6. Resumen de validez de coordenadas
-- Resultado esperado:
-- invalid_coordinates = 0
-- valid_coordinates = total_records
-- ============================================================

SELECT
  COUNT(*) AS total_records,
  SUM(
    CASE
      WHEN longitude BETWEEN -180 AND 180
       AND latitude BETWEEN -90 AND 90
      THEN 1
      ELSE 0
    END
  ) AS valid_coordinates,
  SUM(
    CASE
      WHEN longitude NOT BETWEEN -180 AND 180
        OR latitude NOT BETWEEN -90 AND 90
        OR longitude IS NULL
        OR latitude IS NULL
      THEN 1
      ELSE 0
    END
  ) AS invalid_coordinates
FROM flight_states;


-- ============================================================
-- 7. Check de identificadores ICAO24 inválidos
-- ICAO24 debería tener 6 caracteres hexadecimales.
-- Resultado esperado: 0 filas
-- ============================================================

SELECT
  icao24,
  callsign,
  origin_country,
  event_time,
  source_file
FROM flight_states
WHERE icao24 IS NULL
   OR NOT regexp_like(icao24, '^[0-9a-f]{6}$');


-- ============================================================
-- 8. Distribución tierra / aire
-- ============================================================

SELECT
  CASE
    WHEN on_ground = true THEN 'on_ground'
    WHEN on_ground = false THEN 'in_air'
    ELSE 'unknown'
  END AS flight_status,
  COUNT(*) AS total_records,
  COUNT(DISTINCT icao24) AS unique_aircraft
FROM flight_states
GROUP BY
  CASE
    WHEN on_ground = true THEN 'on_ground'
    WHEN on_ground = false THEN 'in_air'
    ELSE 'unknown'
  END
ORDER BY total_records DESC;



-- ============================================================
-- 9. Resumen por país de origen
-- ============================================================

SELECT
  origin_country,
  COUNT(*) AS total_records,
  COUNT(DISTINCT icao24) AS unique_aircraft,
  AVG(velocity_kmh) AS avg_velocity_kmh,
  AVG(baro_altitude_m) AS avg_baro_altitude_m,
  MIN(event_time) AS first_event_time,
  MAX(event_time) AS last_event_time
FROM flight_states
GROUP BY origin_country
ORDER BY total_records DESC;


-- ============================================================
-- 9. Check de callsign vacío
-- No siempre es error porque OpenSky puede devolver callsign nulo,
-- pero sirve para medir calidad.
-- ============================================================

SELECT
  COUNT(*) AS total_records,
  SUM(CASE WHEN callsign IS NULL THEN 1 ELSE 0 END) AS null_callsign,
  SUM(CASE WHEN TRIM(callsign) = '' THEN 1 ELSE 0 END) AS empty_callsign,
  ROUND(
    100.0 * SUM(CASE WHEN callsign IS NULL OR TRIM(callsign) = '' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS pct_missing_callsign
FROM flight_states;


-- ============================================================
-- 10. Métricas finales para documentación
-- ============================================================

SELECT
  COUNT(*) AS total_silver_records,
  COUNT(DISTINCT icao24) AS unique_aircraft,
  COUNT(DISTINCT origin_country) AS unique_origin_countries,
  COUNT(DISTINCT source_file) AS source_files_processed,
  MIN(event_time) AS first_event_time,
  MAX(event_time) AS last_event_time,
  ROUND(AVG(velocity_kmh), 2) AS avg_velocity_kmh,
  ROUND(AVG(baro_altitude_m), 2) AS avg_baro_altitude_m,
  ROUND(
    100.0 * SUM(CASE WHEN on_ground = true THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS pct_records_on_ground,
  ROUND(
    100.0 * SUM(CASE WHEN on_ground = false THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS pct_records_in_air
FROM flight_states;