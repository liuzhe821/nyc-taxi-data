
-- SELECT array_agg(sum_trips) FROM
-- 	(SELECT dow, hour, sum(trips) AS sum_trips FROM nta_dow_hours_dropoffs_geomjson
-- 		GROUP BY dow, hour ORDER BY dow ASC, hour ASC) AS ordered_trips 
-- 	WHERE dow = 6;

SELECT array_agg(sum_trips) FROM
	(SELECT hour, sum(trips) AS sum_trips FROM nta_daily_hourly_dropoffs_geomjson
		GROUP BY hour ORDER BY hour ASC) AS ordered_trips;