-- TABLE: nta in geoJSON format
-- Differentiate LGA and JFK
-- YET TO ADD EWR!!!!!

CREATE TABLE neighborhood_json AS
SELECT
  ntacode, ntaname, boroname, SUM(shape_area)*3.58701e-8 as area, ST_AsGeoJSON(ST_Union(geom)) as geomjson
FROM nyct2010
WHERE ntaname != 'Airport'
GROUP BY ntacode, ntaname, boroname;

INSERT INTO neighborhood_json
(ntacode, ntaname, boroname, area, geomjson)
SELECT
  ntacode,
  CASE gid
    WHEN 1840 THEN 'LGA'
    WHEN 2056 THEN 'JFK'
  END,
  boroname,
  shape_area*3.58701e-8,
  ST_AsGeoJSON(geom)
FROM nyct2010
WHERE ntaname = 'Airport' AND boroname = 'Queens';



-- TABLE: nta daily pickups with geomJSON
-- Differentiate LGA and JFK
-- YET TO ADD EWR!!!!!

CREATE TABLE nta_daily_pickups_geomjson AS
SELECT
  count.ntacode, count.ntaname, count.boroname, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT
    ntacode, ntaname, boroname, round(count(*)/31.,0) as trips
  FROM
    (SELECT
      ntacode,
      CASE trips.pickup_nyct2010_gid
        WHEN 1840 THEN 'LGA'
        WHEN 2056 THEN 'JFK'
        ELSE ntaname
      END AS ntaname,
      boroname
    FROM
      trips INNER JOIN nyct2010 ON trips.pickup_nyct2010_gid = nyct2010.gid) AS trips_airport
  GROUP BY ntacode, ntaname, boroname) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;

-- TABLE: nta daily dropoffs with geomJSON
-- Differentiate LGA and JFK
-- YET TO ADD EWR!!!!!

CREATE TABLE nta_daily_dropoffs_geomjson AS
SELECT
  count.ntacode, count.ntaname, count.boroname, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT
    ntacode, ntaname, boroname, round(count(*)/31.,0) as trips
  FROM
    (SELECT
      ntacode,
      CASE trips.dropoff_nyct2010_gid
        WHEN 1840 THEN 'LGA'
        WHEN 2056 THEN 'JFK'
        ELSE ntaname
      END AS ntaname,
      boroname
    FROM
      trips INNER JOIN nyct2010 ON trips.dropoff_nyct2010_gid = nyct2010.gid) AS trips_airport
  GROUP BY ntacode, ntaname, boroname) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;


-- create Features
-- SELECT jsonb_build_object(
--     'type',       'Feature',
--     'geometry',   geomjson::jsonb,
--     'properties', to_jsonb(row) - 'geomjson'
-- ) FROM (SELECT * FROM manhattan_nta_daily_trips_geomjson) row;


-- create FeatureCollection
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
  FROM (SELECT * FROM nta_daily_dropoffs_geomjson) AS row) AS features;
