CREATE EXTENSION postgis;

CREATE TABLE yellow_tripdata_staging (
  id serial primary key,
  vendor_id varchar,
  tpep_pickup_datetime varchar,
  tpep_dropoff_datetime varchar,
  passenger_count varchar,
  trip_distance varchar,
  pickup_longitude numeric,
  pickup_latitude numeric,
  rate_code_id varchar,
  store_and_fwd_flag varchar,
  dropoff_longitude numeric,
  dropoff_latitude numeric,
  payment_type varchar,
  fare_amount varchar,
  extra varchar,
  mta_tax varchar,
  tip_amount varchar,
  tolls_amount varchar,
  improvement_surcharge varchar,
  total_amount varchar,
  pickup_location_id varchar,
  dropoff_location_id varchar,
  junk1 varchar,
  junk2 varchar
);


CREATE TABLE cab_types (
  id serial primary key,
  type varchar
);

INSERT INTO cab_types (type) SELECT 'yellow';
INSERT INTO cab_types (type) SELECT 'green';
INSERT INTO cab_types (type) SELECT 'uber';

CREATE TABLE trips (
  id serial primary key,
  cab_type_id integer,
  vendor_id varchar,
  pickup_datetime timestamp without time zone,
  dropoff_datetime timestamp without time zone,
  store_and_fwd_flag char(1),
  rate_code_id integer,
  pickup_longitude numeric,
  pickup_latitude numeric,
  dropoff_longitude numeric,
  dropoff_latitude numeric,
  passenger_count integer,
  trip_distance numeric,
  fare_amount numeric,
  extra numeric,
  mta_tax numeric,
  tip_amount numeric,
  tolls_amount numeric,
  ehail_fee numeric,
  improvement_surcharge numeric,
  total_amount numeric,
  payment_type varchar,
  trip_type integer,
  pickup_nyct2010_gid integer,
  dropoff_nyct2010_gid integer,
  pickup_location_id integer,
  dropoff_location_id integer
);

SELECT AddGeometryColumn('trips', 'pickup', 4326, 'POINT', 2);
SELECT AddGeometryColumn('trips', 'dropoff', 4326, 'POINT', 2);

CREATE TABLE central_park_weather_observations (
  station_id varchar,
  station_name varchar,
  date date,
  precipitation numeric,
  snow_depth numeric,
  snowfall numeric,
  max_temperature numeric,
  min_temperature numeric,
  average_wind_speed numeric
);

CREATE UNIQUE INDEX index_weather_observations ON central_park_weather_observations (date);
