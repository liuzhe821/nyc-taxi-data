CREATE TABLE nta_daily_hourly_pickups_geomjson AS
SELECT
  count.ntacode, count.ntaname, count.boroname, hour, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT
    ntacode, ntaname, boroname, 
    (SELECT extract(hour FROM day)) as hour, round(count(*)/31.,0) as trips
  FROM
    (SELECT
      ntacode,
      CASE trips.pickup_nyct2010_gid
        WHEN 1840 THEN 'LGA'
        WHEN 2056 THEN 'JFK'
        ELSE ntaname
      END AS ntaname,
      boroname,
      pickup_datetime AS day
    FROM
      trips INNER JOIN nyct2010 ON trips.pickup_nyct2010_gid = nyct2010.gid) AS trips_airport
  GROUP BY ntacode, ntaname, boroname, hour) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;


-- CREATE TABLE nta_daily_hourly_dropoffs_geomjson AS
-- SELECT
--   count.ntacode, count.ntaname, count.boroname, hour, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
-- FROM
--   (SELECT
--     ntacode, ntaname, boroname, 
--     (SELECT extract(hour FROM day)) as hour, round(count(*)/31.,0) as trips
--   FROM
--     (SELECT
--       ntacode,
--       CASE trips.dropoff_nyct2010_gid
--         WHEN 1840 THEN 'LGA'
--         WHEN 2056 THEN 'JFK'
--         ELSE ntaname
--       END AS ntaname,
--       boroname,
--       dropoff_datetime AS day
--     FROM
--       trips INNER JOIN nyct2010 ON trips.dropoff_nyct2010_gid = nyct2010.gid) AS trips_airport
--   GROUP BY ntacode, ntaname, boroname, hour) AS count
--     LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
-- ORDER BY trips_per_sqm DESC;


SELECT jsonb_build_object(
    'type',     'FeatureCollection',
    'features', jsonb_agg(feature)
)
FROM (
  SELECT jsonb_build_object(
    'type',       'Feature',
    'geometry',   geomjson::jsonb,
    'properties', to_jsonb(row) - 'geomjson'
  ) AS feature
  FROM 
  (SELECT table1.ntacode, table1.ntaname, table1.boroname, table0.trips as pickups,
    table1.trips as dropoffs, table1.trips - table0.trips as imbalance, intraday_pickups, intraday_dropoffs, 
    table0.trips_per_sqm as pickups_per_sqm, table1.trips_per_sqm as dropoffs_per_sqm, table1.geomjson 
    FROM nta_daily_dropoffs_geomjson AS table1 
    INNER JOIN nta_daily_pickups_geomjson AS table0 ON (table0.ntacode = table1.ntacode) 
    JOIN 
    (SELECT ntacode, array_agg(trips) AS intraday_pickups
      FROM (
        SELECT ntacode, hour, trips FROM nta_daily_hourly_pickups_geomjson ORDER BY hour ASC) AS ordered_pickups 
      GROUP BY ntacode) AS table2 
    ON (table1.ntacode = table2.ntacode)
    JOIN 
    (SELECT ntacode, array_agg(trips) AS intraday_dropoffs 
      FROM (
        SELECT ntacode, hour, trips FROM nta_daily_hourly_dropoffs_geomjson ORDER BY hour ASC) AS ordered_dropoffs 
      GROUP BY ntacode) AS table3
    ON (table1.ntacode = table3.ntacode)) AS row) AS features;

