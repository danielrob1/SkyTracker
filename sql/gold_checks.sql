-- Comprobar tablas Gold
SHOW TABLES IN opensky_lakehouse.gold;

-- 1. Conteo de registros por tabla Gold
SELECT 'air_traffic_by_minute' AS table_name, COUNT(*) AS total_rows
FROM opensky_lakehouse.gold.air_traffic_by_minute

UNION ALL

SELECT 'air_traffic_by_country' AS table_name, COUNT(*) AS total_rows
FROM opensky_lakehouse.gold.air_traffic_by_country

UNION ALL

SELECT 'aircraft_latest_position' AS table_name, COUNT(*) AS total_rows
FROM opensky_lakehouse.gold.aircraft_latest_position

UNION ALL

SELECT 'altitude_distribution' AS table_name, COUNT(*) AS total_rows
FROM opensky_lakehouse.gold.altitude_distribution

UNION ALL

SELECT 'flight_activity_summary' AS table_name, COUNT(*) AS total_rows
FROM opensky_lakehouse.gold.flight_activity_summary;

-- 2. Check de duplicados en latest_position
-- Resultado esperado: 0 filas
SELECT
  icao24,
  COUNT(*) AS repetitions
FROM opensky_lakehouse.gold.aircraft_latest_position
GROUP BY icao24
HAVING COUNT(*) > 1;

-- 3. Check de métricas negativas en tráfico por minuto
-- Resultado esperado: 0 filas
SELECT *
FROM opensky_lakehouse.gold.air_traffic_by_minute
WHERE total_records < 0
   OR active_aircraft < 0
   OR unique_origin_countries < 0
   OR records_on_ground < 0
   OR records_in_air < 0;


-- 4. Check de coherencia en records_on_ground + records_in_air
-- Resultado esperado: 0 filas
SELECT *
FROM opensky_lakehouse.gold.air_traffic_by_minute
WHERE records_on_ground + records_in_air > total_records;


-- 5. Check de ventanas temporales
-- Resultado esperado: 0 filas
SELECT *
FROM opensky_lakehouse.gold.air_traffic_by_minute
WHERE window_start IS NULL
   OR window_end IS NULL
   OR window_start >= window_end;