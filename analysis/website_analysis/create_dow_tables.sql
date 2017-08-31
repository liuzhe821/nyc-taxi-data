-- A function to count the number of Mondays, Tuesdays, etc. in a given month for averaging purposes.
-- 0=Sunday, 1=Monday, etc.

CREATE OR REPLACE FUNCTION get_count(dow int, time_interval timestamp) RETURNS int AS $$
	SELECT COUNT(*)::int FROM
    	generate_series(time_interval, time_interval + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL, 
    		'1 day') AS g(mydate)
	WHERE EXTRACT(DOW FROM mydate) = dow;
$$ 
LANGUAGE SQL;


-- TABLE: nta average pickups per day of week per month/year
CREATE TABLE nta_dow_pickups_geomjson AS
SELECT
  time_period, count.ntacode, count.ntaname, count.boroname, dow, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT
    time_period, ntacode, ntaname, boroname, 
    (SELECT extract(dow FROM day)) as dow, 
     round(count(*)::numeric/ (SELECT get_count((SELECT extract(dow FROM time_period))::int, time_period)::int),0) AS trips
  FROM
    (SELECT
    	(SELECT date_trunc('month', pickup_datetime)) AS time_period,
      ntacode,
      CASE trips.pickup_nyct2010_gid
        WHEN 1840 THEN 'LGA'
        WHEN 2056 THEN 'JFK'
        ELSE ntaname
      END AS ntaname,
      boroname,
      (SELECT date_trunc('day', pickup_datetime)) AS day
    FROM
      trips INNER JOIN nyct2010 ON trips.pickup_nyct2010_gid = nyct2010.gid) AS trips_airport
  GROUP BY time_period, ntacode, ntaname, boroname, dow) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;


-- TABLE: nta average dropoffs per day of week per month/year
CREATE TABLE nta_dow_dropoffs_geomjson AS
SELECT
  time_period, count.ntacode, count.ntaname, count.boroname, dow, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT
    time_period, ntacode, ntaname, boroname, 
    (SELECT extract(dow FROM day)) as dow, 
     round(count(*)::numeric/ (SELECT get_count((SELECT extract(dow FROM time_period))::int, time_period)::int),0) AS trips
  FROM
    (SELECT
    	(SELECT date_trunc('month', dropoff_datetime)) AS time_period,
      ntacode,
      CASE trips.dropoff_nyct2010_gid
        WHEN 1840 THEN 'LGA'
        WHEN 2056 THEN 'JFK'
        ELSE ntaname
      END AS ntaname,
      boroname,
      (SELECT date_trunc('day', dropoff_datetime)) AS day
    FROM
      trips INNER JOIN nyct2010 ON trips.dropoff_nyct2010_gid = nyct2010.gid) AS trips_airport
  GROUP BY time_period, ntacode, ntaname, boroname, dow) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;


-- TABLE: nta intraday average pickups per day of week per month/year
CREATE TABLE nta_dow_hours_pickups_geomjson AS
SELECT
  time_period, count.ntacode, count.ntaname, count.boroname, dow, hour, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT
    time_period, ntacode, ntaname, boroname, 
    (SELECT extract(dow FROM day)) as dow, 
    (SELECT extract(hour FROM day)) as hour, 
    round(count(*)::numeric/ (SELECT get_count((SELECT extract(dow FROM time_period))::int, time_period)::int),0) AS trips
  FROM
    (SELECT
    	(SELECT date_trunc('month', pickup_datetime)) AS time_period,
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
  GROUP BY time_period, ntacode, ntaname, boroname, dow, hour) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;

-- TABLE: nta intraday average dropoffs per day of week per month/year
CREATE TABLE nta_dow_hours_dropoffs_geomjson AS
SELECT
  time_period, count.ntacode, count.ntaname, count.boroname, dow, hour, trips, round(trips/neighbor.area,0) as trips_per_sqm, neighbor.geomjson
FROM
  (SELECT
    time_period, ntacode, ntaname, boroname, 
    (SELECT extract(dow FROM day)) as dow, 
    (SELECT extract(hour FROM day)) as hour, 
    round(count(*)::numeric/ (SELECT get_count((SELECT extract(dow FROM time_period))::int, time_period)::int),0) AS trips
  FROM
    (SELECT
    	(SELECT date_trunc('month', dropoff_datetime)) AS time_period,
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
  GROUP BY time_period, ntacode, ntaname, boroname, dow, hour) AS count
    LEFT JOIN neighborhood_json AS neighbor ON count.ntaname = neighbor.ntaname
ORDER BY trips_per_sqm DESC;
