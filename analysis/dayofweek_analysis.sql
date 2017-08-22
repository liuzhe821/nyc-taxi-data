-- -- TABLE: nta average pickups per day of week

-- CREATE TABLE nta_dow_pickups_geomjson AS
-- SELECT
--   count.ntacode, count.ntaname, count.boroname, dow, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
-- FROM
--   (SELECT
--     ntacode, ntaname, boroname, 
--     (SELECT extract(dow FROM day)) as dow, 
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
--       (SELECT date_trunc('day', pickup_datetime)) AS day
--     FROM
--       trips INNER JOIN nyct2010 ON trips.pickup_nyct2010_gid = nyct2010.gid) AS trips_airport
--   GROUP BY ntacode, ntaname, boroname, dow) AS count
--     LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
-- ORDER BY trips_per_sqm DESC;

-- -- TABLE: nta average dropoffs per day of week

-- CREATE TABLE nta_dow_dropoffs_geomjson AS
-- SELECT
--   count.ntacode, count.ntaname, count.boroname, dow, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
-- FROM
--   (SELECT
--     ntacode, ntaname, boroname, 
--     (SELECT extract(dow FROM day)) as dow, 
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
--       (SELECT date_trunc('day', dropoff_datetime)) AS day
--     FROM
--       trips INNER JOIN nyct2010 ON trips.dropoff_nyct2010_gid = nyct2010.gid) AS trips_airport
--   GROUP BY ntacode, ntaname, boroname, dow) AS count
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
  FROM (SELECT ntacode, ntaname, boroname, trips, trips_per_sqm, geomjson 
  	FROM nta_dow_dropoffs_geomjson WHERE dow=6) AS row) AS features;
