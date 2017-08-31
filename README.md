# Unified New York City Taxi and Uber data

Code in support of this post: [Analyzing 1.1 Billion NYC Taxi and Uber Trips, with a Vengeance](http://toddwschneider.com/posts/analyzing-1-1-billion-nyc-taxi-and-uber-trips-with-a-vengeance/)

This repo provides scripts to download, process, and analyze data for over 1.3 billion taxi and Uber trips originating in New York City. The data is stored in a [PostgreSQL](http://www.postgresql.org/) database, and uses [PostGIS](http://postgis.net/) for spatial calculations, in particular mapping latitude/longitude coordinates to census tracts.

The [yellow and green taxi data](http://www.nyc.gov/html/tlc/html/about/trip_record_data.shtml) comes from the NYC Taxi & Limousine Commission, and [Uber data](https://github.com/fivethirtyeight/uber-tlc-foil-response) comes via FiveThirtyEight, who obtained it via a FOIL request. In August 2016, the TLC began providing for-hire vehicle trip records as well.

## Instructions

Your mileage may vary, but on my MacBook Air, this process took about 3 days to complete. The unindexed database takes up 330 GB on disk. Adding indexes for improved query performance increases total disk usage by another 100 GB.

##### 1. Install [PostgreSQL](http://www.postgresql.org/download/) and [PostGIS](http://postgis.net/install)

Both are available via [Homebrew](http://brew.sh/) on Mac OS X

##### 2. Download raw taxi data

`./download_raw_data.sh`, which calls `raw_data_urls.txt`.

##### 3. Initialize database and set up schema

`./initialize_database.sh`, which calls `create_nyc_taxi_schema.sql`, `nyct2010_15b/nyct2010.shp` and `data/central_park_weather.csv`.

##### 4. Import taxi data into database and map to census tracts

`./import_trip_data.sh`, which calls `populate_yellow_trips.sql`.

##### 5. Optional: download and import Uber data from FiveThirtyEight's GitHub repository, and TLC for-hire vehicle records

`./download_raw_uber_data.sh`
<br>
`./import_uber_trip_data.sh`
<br>
`./import_fhv_trip_data.sh`

##### 6. Analysis

Additional Postgres and [R](https://www.r-project.org/) scripts for analysis are in the <code>analysis/</code> folder, or you can do your own!

1) Run `analysis/my_analysis.sql` without/comment-out the last section of codes (create FeatureCollection) to create tables;
2) Run only the last section of `analysis/my_analysis.sql` (create FeatureCollection) twice, with `nta_daily_pickups_geomjson` and `nta_daily_dropoffs_geomjson` in the last row; use the results to generate file `sample-geojson.js`.


##### 7. Website work and further analysis

The files for this section are located in the static_resources/ folder (CSS/JS) and analysis/website_analysis/ folder (SQL).

LIBRARIES/RESOURCES USED: The map is generated with the [Leaflet.js library](http://leafletjs.com/). Charts are generated using [Google Charts](https://developers.google.com/chart/). Show/hide arrows on the bottom right corner map are [Google Material Design Icons](https://material.io/icons/).


HTML/CSS: All HTML work is in NYC_taxi.html, styled with main.css, located in the static_resources folder.
1. Within the body there is the top nav bar containing the title, description, and two dropdown boxes. 
2. Then there is the div with id 'map' that the JavaScript will populate with the Leaflet map. 
3. Then there is the bottom right citywide intraday flow graph, with id 'overall_graph'. The overall graph can be hidden/shown with the google design icon in the div with id 'og-button'.


JAVASCRIPT: All JavaScript is in main.js, located in the static_resources folder.
1. There is a set of global variables to keep track of state so that the map is updated carefully, hold data (color ramps, map, painted layer, etc). Check inline comments for specific descriptions.
2. Then there is a number of functions, mainly to support drawing graphs (makeRows, drawChart, drawImbalChart) and to support updating the map (onEachNeighbor, getJson, updateMap).
3. Then there is the jQuery function that runs when the DOM is ready. Within the $(document).ready() there are event listeners for the two dropdowns, which update global variables and call updateMap and draw new overall graphs when the selected dropdown option changes, a click listener for the show/hide button on the overall graph, and a window resize listener to ensure the map resizes proportionally to the window.

GEOJSONS: All GeoJSONs are in dow_data.js. Each GeoJSON represents a different day of week, and contains that day of week's pickups, pickups per sqm, dropoffs, dropoffs per sqm, intraday pickups, intraday dropoffs, identifiers, and geographical info per NTA.


SQL/ANALYSIS OVERVIEW: The following sql files are to be run after the steps to create and populate the db. They are located in /analysis/website_analysis

create_overall_tables.sql contains the SQL commands to create tables with pickup, dropoff, and intraday pickup/dropoff data that averages all days in a given month.

create_dow_tables.sql contains the SQL commands to create similar tables above, but for individual days of the week (0=Sunday). There is an extra 'dow' column which keeps day of week values separate.

queries.sql contains the queries to retrieve GeoJSONS for specific months/days of week. Comment out unwanted queries and run the desired one. Modify the WHERE statements (see inline comments for specifics) to get geoJSONS for specific month and days of week.

The two table creation files can be run from the command line on mac with: psql nyc-taxi-data -f filename.sql
To run the query file and save output to a js file, run: psql nyc-taxi-data -f queries.sql > filename.js
Use >> in place of > to append to file instead of creating new/overwriting.

The two create_* files should only be run once. The queries in queries.sql will be joining the tables together to generate GeomJSONS.


NEXT STEPS

1. Charting for forecastable intraday variation and unpredictable forecast deviations. There exists [code to generate forecasts for 4-node network](https://github.com/victorialin898/nyc-taxi-forecasts), but the code would need to be modified for this network which is much more complex.
2. Charting imbalance (inflow-outflow) at nodes: histogram of log Imb(i,t) across i
3. Incorporate data beyond May 2016
4. Consolidate all data into one/a few geojson for faster loading times: all the geographical data is uselessly repeated. By putting all data into one geojson (and generating heatmaps by indicating which field to use), the site would load faster. This would involve modifying SQL queries to join tables etc. This would also remove the need to run sql queries repeatedly while changing the WHERE dow= or time_period= condition
5. Add exporting functionality to the graphs, so that users can download the data


## Schema

- `trips` table contains all yellow and green taxi trips, plus Uber pickups from April 2014 through September 2014. Each trip has a `cab_type_id`, which references the `cab_types` table and refers to one of `yellow`, `green`, or `uber`. Each trip maps to a census tract for pickup and dropoff
- `nyct2010` table contains NYC census tracts plus the Newark Airport. It also maps census tracts to NYC's official neighborhood tabulation areas
- `taxi_zones` table contains the TLC's official taxi zone boundaries. Starting in July 2016, the TLC no longer provides pickup and dropoff coordinates. Instead, each trip comes with taxi zone pickup and dropoff location IDs
- `uber_trips_2015` table contains Uber pickups from Jan–Jun, 2015. These are kept in a separate table because they don't have specific latitude/longitude coordinates, only location IDs. The location IDs are stored in the `taxi_zone_lookups` table, which also maps them (approximately) to neighborhood tabulation areas
- `fhv_trips` table contains all FHV trip records made available by the TLC
- `central_park_weather_observations` has summary weather data by date

## Other data sources

These are bundled with the repository, so no need to download separately, but:

- Shapefile for NYC census tracts and neighborhood tabulation areas comes from [Bytes of the Big Apple](http://www.nyc.gov/html/dcp/html/bytes/districts_download_metadata.shtml)
- Shapefile for taxi zone locations comes from the TLC
- Mapping of FHV base numbers to names comes from [the TLC](http://www.nyc.gov/html/tlc/html/about/statistics.shtml)
- Central Park weather data comes from the [National Climatic Data Center](http://www.ncdc.noaa.gov/)

## Data issues encountered

- Remove carriage returns and empty lines from TLC data before passing to Postgres `COPY` command
- Some raw data files have extra columns with empty data, had to create dummy columns `junk1` and `junk2` to absorb them
- Two of the `yellow` taxi raw data files had a small number of rows containing extra columns. I discarded these rows
- The official NYC neighborhood tabulation areas (NTAs) included in the shapefile are not exactly what I would have expected. Some of them are bizarrely large and contain more than one neighborhood, e.g. "Hudson Yards-Chelsea-Flat Iron-Union Square", while others are confusingly named, e.g. "North Side-South Side" for what I'd call "Williamsburg", and "Williamsburg" for what I'd call "South Williamsburg". In a few instances I modified NTA names, but I kept the NTA geographic definitions
- The shapefile includes only NYC census tracts. Trips to New Jersey, Long Island, Westchester, and Connecticut are not mapped to census tracts, with the exception of the Newark Airport, for which I manually added a fake census tract
- The Uber 2015 and FHV data uses location IDs instead of latitude/longitude. The location IDs do not exactly overlap with the NYC neighborhood tabulation areas (NTAs) or census tracts, but I did my best to map Uber location IDs to NYC NTAs

## Why not use BigQuery or Redshift?

[Google BigQuery](https://cloud.google.com/bigquery/) and [Amazon Redshift](https://aws.amazon.com/redshift/) would probably provide significant performance improvements over PostgreSQL. A lot of the data is already available on BigQuery, but in scattered tables, and each trip has only latitude and longitude coordinates, not census tracts and neighborhoods. PostGIS seemed like the easiest way to map coordinates to census tracts. Once the mapping is complete, it might make sense to load the data back into BigQuery or Redshift to make the analysis faster. Note that BigQuery and Redshift cost some amount of money, while PostgreSQL and PostGIS are free.

## TLC summary statistics

There's a Ruby script in the `tlc_statistics/` folder to import data from the TLC's [summary statistics reports](http://www.nyc.gov/html/tlc/html/about/statistics.shtml):

`ruby import_statistics_data.rb`

## Questions/issues/contact

todd@toddwschneider.com, or open a GitHub issue
