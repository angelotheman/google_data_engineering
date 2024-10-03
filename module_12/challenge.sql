-- Task 1
-- Make sure to check the name of the table given

CREATE OR REPLACE TABLE
  taxirides.taxi_training_data_724 AS
SELECT
  (tolls_amount + fare_amount) AS fare_amount_589, -- Target column with correct name
  pickup_datetime,
  pickup_longitude AS pickuplon,
  pickup_latitude AS pickuplat,
  dropoff_longitude AS dropofflon,
  dropoff_latitude AS dropofflat,
  passenger_count AS passengers,
  trip_distance
FROM
  taxirides.historical_taxi_rides_raw
WHERE
  RAND() < 0.001 
  AND trip_distance > 3 
  AND fare_amount >= 2.5
  AND pickup_longitude BETWEEN -78 AND -70 
  AND dropoff_longitude BETWEEN -78 AND -70 
  AND pickup_latitude BETWEEN 37 AND 45 
  AND dropoff_latitude BETWEEN 37 AND 45 
  AND passenger_count > 3; 


-- Task 2  


CREATE OR REPLACE MODEL taxirides.fare_model_827 -- Replace with your model name
TRANSFORM(
  * EXCEPT(pickup_datetime) 
  , ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS euclidean 
  , CAST(EXTRACT(DAYOFWEEK FROM pickup_datetime) AS STRING) AS dayofweek 
  , CAST(EXTRACT(HOUR FROM pickup_datetime) AS STRING) AS hourofday 
)
OPTIONS(input_label_cols=['fare_amount_589'], model_type='linear_reg') 
AS
SELECT * FROM taxirides.taxi_training_data_724;

-- Task 3

CREATE OR REPLACE TABLE taxirides.2015_fare_amount_predictions AS
SELECT 
  pickup_datetime,
  pickuplon,
  pickuplat,
  dropofflon,
  dropofflat,
  passengers,
  trip_distance,
  predicted_fare_amount_589
FROM 
  ML.PREDICT(MODEL `taxirides.fare_model_827`, (
    SELECT 
      pickup_datetime,
      pickuplon,
      pickuplat,
      dropofflon,
      dropofflat,
      passengers,
      ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS trip_distance
    FROM 
      taxirides.report_prediction_data
  ));
