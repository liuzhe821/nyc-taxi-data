-- TABLE: nta in geoJSON format-- directly taken from my_analysis.sql
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


-- Creates a table with time period (month, year specific) that contains average pickups per nta, day-of-week blind

CREATE TABLE nta_daily_pickups_geomjson AS
SELECT
  time_period, count.ntacode, count.ntaname, count.boroname, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT time_period, ntacode, ntaname, boroname, round(count(*)::numeric/
      (SELECT DATE_PART('days', 
        time_period + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL)::int)) as trips
  FROM
    (SELECT
      (SELECT date_trunc('month', pickup_datetime)) as time_period,
      ntacode,
      CASE trips.pickup_nyct2010_gid
        WHEN 1840 THEN 'LGA'
        WHEN 2056 THEN 'JFK'
        ELSE ntaname
      END AS ntaname,
      boroname
    FROM
      trips INNER JOIN nyct2010 ON trips.pickup_nyct2010_gid = nyct2010.gid) AS trips_airport
  GROUP BY time_period, ntacode, ntaname, boroname) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;


-- Creates a table with time period (month, year specific) that contains average dropoffs per nta, day-of-week blind

CREATE TABLE nta_daily_dropoffs_geomjson AS
SELECT
  time_period, count.ntacode, count.ntaname, count.boroname, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT time_period, ntacode, ntaname, boroname, round(count(*)::numeric/
      (SELECT DATE_PART('days', 
        time_period + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL)::int)) as trips
  FROM
    (SELECT
      (SELECT date_trunc('month', dropoff_datetime)) as time_period,
      ntacode,
      CASE trips.dropoff_nyct2010_gid
        WHEN 1840 THEN 'LGA'
        WHEN 2056 THEN 'JFK'
        ELSE ntaname
      END AS ntaname,
      boroname
    FROM
      trips INNER JOIN nyct2010 ON trips.dropoff_nyct2010_gid = nyct2010.gid) AS trips_airport
  GROUP BY time_period, ntacode, ntaname, boroname) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;

-- Creates a table of  intraday average pickups with time period (month, year specific) per nta, 
-- day-of-week blind

CREATE TABLE nta_daily_hourly_pickups_geomjson AS
SELECT
  time_period, count.ntacode, count.ntaname, count.boroname, hour, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT time_period, ntacode, ntaname, boroname, (SELECT extract(hour FROM day)) as hour, 
    round(count(*)::numeric/(SELECT DATE_PART('days', 
        time_period + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL)::int)) as trips
  FROM
    (SELECT
      (SELECT date_trunc('month', dropoff_datetime)) as time_period,
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
  GROUP BY time_period, ntacode, ntaname, boroname, hour) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;

-- Creates a table of  intraday average dropoffs with time period (month, year specific) per nta, 
-- day-of-week blind

CREATE TABLE nta_daily_hourly_dropoffs_geomjson AS
SELECT
  time_period, count.ntacode, count.ntaname, count.boroname, hour, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT time_period, ntacode, ntaname, boroname, (SELECT extract(hour FROM day)) as hour, 
    round(count(*)::numeric/(SELECT DATE_PART('days', 
        time_period + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL)::int)) as trips
  FROM
    (SELECT
      (SELECT date_trunc('month', dropoff_datetime)) as time_period,
      ntacode,
      CASE trips.dropoff_nyct2010_gid
        WHEN 1840 THEN 'LGA'
        WHEN 2056 THEN 'JFK'
        ELSE ntaname
      END AS ntaname,
      boroname,
      dropoff_datetime AS day
    FROM
      trips INNER JOIN nyct2010 ON trips.dropoff_nyct2010_gid = nyct2010.gid) AS trips_airport
  GROUP BY time_period, ntacode, ntaname, boroname, hour) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;

