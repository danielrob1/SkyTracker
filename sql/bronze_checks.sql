-- ============================================================
-- 0. Seleccionar catálogo y schema
-- ============================================================

USE CATALOG opensky_lakehouse;
USE SCHEMA bronze;


-- ============================================================
-- 1. Vista rápida de la tabla Bronze
-- ============================================================

SELECT *
FROM opensky_states_raw
LIMIT 10;


-- ============================================================
-- 2. Resumen general de la tabla Bronze
-- ============================================================

SELECT
  COUNT(*) AS total_raw_files,
  COUNT(DISTINCT raw_hash) AS unique_raw_files,
  MIN(bronze_ingestion_timestamp) AS first_ingestion,
  MAX(bronze_ingestion_timestamp) AS last_ingestion
FROM opensky_states_raw;


-- ============================================================
-- 3. Check de duplicados por raw_hash
-- Resultado esperado: 0 filas
-- ============================================================

SELECT
  raw_hash,
  COUNT(*) AS repetitions,
  COLLECT_SET(source_file) AS source_files
FROM opensky_states_raw
GROUP BY raw_hash
HAVING COUNT(*) > 1;


-- ============================================================
-- 4. Check de nulos, JSON vacío y archivos inválidos
-- Resultado esperado: todos los valores a 0
-- ============================================================

SELECT
  SUM(CASE WHEN source_file IS NULL THEN 1 ELSE 0 END) AS null_source_file,
  SUM(CASE WHEN raw_json IS NULL THEN 1 ELSE 0 END) AS null_raw_json,
  SUM(CASE WHEN TRIM(raw_json) = '' THEN 1 ELSE 0 END) AS empty_raw_json,
  SUM(CASE WHEN source_file_size_bytes <= 0 THEN 1 ELSE 0 END) AS invalid_file_size,
  SUM(CASE WHEN raw_hash IS NULL THEN 1 ELSE 0 END) AS null_raw_hash
FROM opensky_states_raw;


-- ============================================================
-- 5. Resumen por fecha de los archivos ingeridos
-- ============================================================

SELECT
  source_date,
  COUNT(*) AS total_files,
  MIN(source_file_modification_time) AS first_file_modification,
  MAX(source_file_modification_time) AS last_file_modification,
  MIN(bronze_ingestion_timestamp) AS first_bronze_ingestion,
  MAX(bronze_ingestion_timestamp) AS last_bronze_ingestion
FROM opensky_states_raw
GROUP BY source_date
ORDER BY source_date DESC;


-- ============================================================
-- 6. Check de campos obligatorios dentro del JSON raw
-- Resultado esperado: 0
-- ============================================================

SELECT
  COUNT(*) AS invalid_or_incomplete_json_files
FROM opensky_states_raw
WHERE get_json_object(raw_json, '$.source') IS NULL
   OR get_json_object(raw_json, '$.retrieved_at') IS NULL
   OR get_json_object(raw_json, '$.api_time') IS NULL
   OR get_json_object(raw_json, '$.aircraft_count') IS NULL
   OR get_json_object(raw_json, '$.states') IS NULL;


-- ============================================================
-- 7. Inspección de valores principales del JSON
-- ============================================================

SELECT
  source_file,
  get_json_object(raw_json, '$.source') AS json_source,
  get_json_object(raw_json, '$.retrieved_at') AS retrieved_at,
  CAST(get_json_object(raw_json, '$.api_time') AS BIGINT) AS api_time,
  CAST(get_json_object(raw_json, '$.aircraft_count') AS INT) AS aircraft_count
FROM opensky_states_raw
ORDER BY bronze_ingestion_timestamp DESC;


-- ============================================================
-- 8. Conteo de aircraft_count acumulado por fecha
-- ============================================================

SELECT
  source_date,
  COUNT(*) AS total_raw_files,
  SUM(CAST(get_json_object(raw_json, '$.aircraft_count') AS INT)) AS total_aircraft_records_reported,
  AVG(CAST(get_json_object(raw_json, '$.aircraft_count') AS INT)) AS avg_aircraft_per_file,
  MIN(CAST(get_json_object(raw_json, '$.aircraft_count') AS INT)) AS min_aircraft_per_file,
  MAX(CAST(get_json_object(raw_json, '$.aircraft_count') AS INT)) AS max_aircraft_per_file
FROM opensky_states_raw
GROUP BY source_date
ORDER BY source_date DESC;


-- ============================================================
-- 9. Archivos más recientes ingeridos en Bronze
-- ============================================================

SELECT
  source_file,
  source_date,
  source_file_size_bytes,
  CAST(get_json_object(raw_json, '$.aircraft_count') AS INT) AS aircraft_count,
  bronze_ingestion_timestamp
FROM opensky_states_raw
ORDER BY bronze_ingestion_timestamp DESC
LIMIT 20;