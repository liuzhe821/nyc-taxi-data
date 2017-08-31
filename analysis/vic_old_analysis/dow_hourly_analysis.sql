-- CREATE TABLE nta_dow_hours_dropoffs_geomjson AS
-- SELECT
--   count.ntacode, count.ntaname, count.boroname, dow, hour, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
-- FROM
--   (SELECT
--     ntacode, ntaname, boroname, 
--     (SELECT extract(dow FROM day)) as dow, 
--     (SELECT extract(hour FROM day)) as hour, 
--     CASE 
--       WHEN (SELECT extract(dow FROM day)) < 3 THEN round(count(*)/5.,0)
--       ELSE round(count(*)/4.,0)
--       END AS trips
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
--   GROUP BY ntacode, ntaname, boroname, dow, hour) AS count
--     LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
-- ORDER BY trips_per_sqm DESC;

-- CREATE TABLE nta_dow_hours_pickups_geomjson AS
-- SELECT
--   count.ntacode, count.ntaname, count.boroname, dow, hour, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
-- FROM
--   (SELECT
--     ntacode, ntaname, boroname, 
--     (SELECT extract(dow FROM day)) as dow, 
--     (SELECT extract(hour FROM day)) as hour, 
--     CASE 
--       WHEN (SELECT extract(dow FROM day)) < 3 THEN round(count(*)/5.,0)
--       ELSE round(count(*)/4.,0)
--       END AS trips
--   FROM
--     (SELECT
--       ntacode,
--       CASE trips.pickup_nyct2010_gid
--         WHEN 1840 THEN 'LGA'
--         WHEN 2056 THEN 'JFK'
--         ELSE ntaname
--       END AS ntaname,
--       boroname,
--       pickup_datetime AS day
--     FROM
--       trips INNER JOIN nyct2010 ON trips.pickup_nyct2010_gid = nyct2010.gid) AS trips_airport
--   GROUP BY ntacode, ntaname, boroname, dow, hour) AS count
--     LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
-- ORDER BY trips_per_sqm DESC;



-- create FeatureCollection
-- Change nta_dow_pickups_geomjson or nta_dow_dropoffs_geomjson
-- Modify dow: 0-6, 0 is Sunday 

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
  FROM (SELECT table1.ntacode, table1.ntaname, table1.boroname, table0.trips as pickups,
    table1.trips as dropoffs, table1.trips - table0.trips as imbalance, intraday_pickups, intraday_dropoffs, 
    table0.trips_per_sqm as pickups_per_sqm, table1.trips_per_sqm as dropoffs_per_sqm, table1.geomjson 
    FROM nta_dow_dropoffs_geomjson AS table1 
    INNER JOIN nta_dow_pickups_geomjson AS table0 ON (table0.ntacode = table1.ntacode and table0.dow = table1.dow) 
    JOIN 
    (SELECT ntacode, dow, array_agg(trips) AS intraday_pickups
      FROM (
        SELECT ntacode, dow, hour, trips FROM nta_dow_hours_pickups_geomjson ORDER BY hour ASC) AS ordered_pickups 
      GROUP BY ntacode, dow) AS table2 
    ON (table1.ntacode = table2.ntacode and table1.dow = table2.dow)
    JOIN 
    (SELECT ntacode, dow, array_agg(trips) AS intraday_dropoffs 
      FROM (
        SELECT ntacode, dow, hour, trips FROM nta_dow_hours_dropoffs_geomjson ORDER BY hour ASC) AS ordered_dropoffs 
      GROUP BY ntacode, dow) AS table3
    ON (table1.ntacode = table3.ntacode and table1.dow = table3.dow) WHERE table1.dow=6) AS row) AS features;
