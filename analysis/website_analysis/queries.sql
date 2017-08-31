-- OVERALL GRAPH QUERIES ===================================================================================

-- The two queries below for day of week specific and day of week nonspecific are different 
-- because one includes an extra WHERE block. These return arrays of size 24 with values where the index 
-- represents the hour corresponding to the value. 

-- Overall intraday data for day of week. Change WHERE dow= to change the day of week. Sun=0, Mon=1, etc.
-- In the second line, select from nta_dow_hours_pickups_geomjson for intraday pickups.
-- Likewise, select from nta_dow_hours_dropoffs_geomjson for intraday dropoffs.
-- Also in the second line, change the string after DATE with the desired month/year. YYYY-MM-DD, DD=01.

SELECT array_agg(sum_trips) FROM
 (SELECT dow, hour, sum(trips) AS sum_trips FROM nta_dow_hours_dropoffs_geomjson WHERE time_period= DATE '2016-05-01'
   GROUP BY dow, hour ORDER BY dow ASC, hour ASC) AS ordered_trips 
 WHERE dow = 6; -- Change things HERE!

-- Overall intraday data for day of week blind. There is no WHERE dow= block. Similar to above, change to
-- nta_daily_hourly_pickups_geomjson or nta_daily_hourly_dropoffs_geomjson depending on your needs.
-- Change the string after DATE to the desired month/year.

SELECT array_agg(sum_trips) FROM
  (SELECT hour, sum(trips) AS sum_trips FROM nta_daily_hourly_dropoffs_geomjson WHERE time_period= DATE '2016-05-01'
    GROUP BY hour ORDER BY hour ASC) AS ordered_trips;


-- ALL DAY SUMMARY: DAY-OF-WEEK BLIND QUERY =====================================================================

-- The query for the GeoJSON for all days (day of week blind) trip data. Change the WHERE block on the last line
-- to get data for different months/years. Example: For Dec 2016, substitute the string '2016-12-01'
-- Make sure its the first day of the given month. Formatting is important! YYYY-MM-DD

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
    INNER JOIN nta_daily_pickups_geomjson AS table0 ON (table0.ntacode = table1.ntacode AND table0.time_period = table1.time_period) 
    JOIN 
    (SELECT time_period, ntacode, array_agg(trips) AS intraday_pickups
      FROM (
        SELECT time_period, ntacode, hour, trips FROM nta_daily_hourly_pickups_geomjson ORDER BY hour ASC) AS ordered_pickups 
      GROUP BY time_period, ntacode) AS table2 
    ON (table1.ntacode = table2.ntacode AND table1.time_period = table2.time_period)
    JOIN 
    (SELECT time_period, ntacode, array_agg(trips) AS intraday_dropoffs 
      FROM (
        SELECT time_period, ntacode, hour, trips FROM nta_daily_hourly_dropoffs_geomjson ORDER BY hour ASC) AS ordered_dropoffs 
      GROUP BY time_period, ntacode) AS table3
    ON (table1.ntacode = table3.ntacode AND table1.time_period = table3.time_period) 
    WHERE table1.time_period= DATE '2016-05-01') AS row) AS features; -- Change things HERE!



-- DAY-OF-WEEK SPECIFIC QUERY =========================================================================

-- The query for the GeoJSON for day of week specific data. This must be run once PER day of week.
-- Change the WHERE block on the last line at two points:
-- table1.dow= 0 to specify the day of week (0=Sunday) 
-- Etable1.time_period= to specify the month/year. Example: For Dec 2016, substitute the string '2016-12-01'
-- Make sure its the first day of the given month. Formatting is important! YYYY-MM-DD

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
    INNER JOIN nta_dow_pickups_geomjson AS table0 ON (
      table0.ntacode = table1.ntacode and 
      table0.dow = table1.dow and
      table0.time_period = table1.time_period) 
    JOIN 
    (SELECT time_period, ntacode, dow, array_agg(trips) AS intraday_pickups
      FROM (
        SELECT time_period, ntacode, dow, hour, trips FROM nta_dow_hours_pickups_geomjson ORDER BY hour ASC) AS ordered_pickups 
      GROUP BY time_period, ntacode, dow) AS table2 
    ON (table1.ntacode = table2.ntacode and 
      table1.dow = table2.dow and
      table1.time_period = table2.time_period)
    JOIN 
    (SELECT time_period, ntacode, dow, array_agg(trips) AS intraday_dropoffs 
      FROM (
        SELECT time_period, ntacode, dow, hour, trips FROM nta_dow_hours_dropoffs_geomjson ORDER BY hour ASC) AS ordered_dropoffs 
      GROUP BY time_period, ntacode, dow) AS table3
    ON (table1.ntacode = table3.ntacode and 
      table1.dow = table3.dow and
      table1.time_period = table3.time_period) 
    WHERE table1.dow= 0 AND table1.time_period= DATE '2016-05-01') AS row) AS features; -- Change things HERE!