--Flight delays and cancellations for the first quarter of 2023
-- GOALS--
	-- 1. Total Number of Flights for the first quarter of 2023. --
	-- 2. Average Delay Time --
	-- 3. Monthly Flight Trends --
	-- 4. Airlines with the Most Delays and Cancellations --
	-- 5. Reasons for Cancellations --


-- FIRST STEP --
	-- Let's look for duplicates --

WITH CTE_DUPLICATES AS 
(
SELECT *,
	   ROW_NUMBER() OVER (PARTITION BY OP_UNIQUE_CARRIER, DEP_TIME, ARR_TIME, CRS_DEP_TIME, CRS_ARR_TIME, ORIGIN_AIRPORT_ID, DEST_AIRPORT_ID, DAY ORDER BY FL_DATE) AS DUPLICATES
FROM JAN

)
SELECT *
FROM CTE_DUPLICATES
WHERE DUPLICATES > 1
ORDER BY DUPLICATES
--------------------------------
WITH CTE_DUPLICATES AS 
(
SELECT *,
	   ROW_NUMBER() OVER (PARTITION BY OP_UNIQUE_CARRIER, DEP_TIME, ARR_TIME, CRS_DEP_TIME, CRS_ARR_TIME, ORIGIN_AIRPORT_ID, DEST_AIRPORT_ID, DAY ORDER BY FL_DATE) AS DUPLICATES
FROM FEB

)
SELECT *
FROM CTE_DUPLICATES
WHERE DUPLICATES > 1
ORDER BY DUPLICATES DESC

--------------------------------

WITH CTE_DUPLICATES AS 
(
SELECT *,
	   ROW_NUMBER() OVER (PARTITION BY OP_UNIQUE_CARRIER, DEP_TIME, ARR_TIME, CRS_DEP_TIME, CRS_ARR_TIME, ORIGIN_AIRPORT_ID, DEST_AIRPORT_ID, DAY ORDER BY FL_DATE) AS DUPLICATES
FROM MAR

)
SELECT *
FROM CTE_DUPLICATES
WHERE DUPLICATES > 1
ORDER BY DUPLICATES DESC

----------------------------
-- No duplicates where found in the dataset --
----------------------------

-- 1. SOLUTION: Total Number of Flights for the first quarter of 2023

-- The solution for this one is simple, all we need to do is count the total amount of rows. --
SELECT COUNT(*) AS TOTAL_FLIGHTS_PLANNED
FROM JAN

--For January, the total number of planned flights is 538.837. Note how the world is 'planned'. Many of these flights were cancelled --
-- Now, for the cancelled flights --
SELECT COUNT(*) AS TOTAL_CANCELLED
FROM JAN
WHERE CANCELLED = 1

-- The total cancelled flights for Jan is 10.295 --
-- Let's find out the total amount of flights that weren't cancelled for January --

--METHOD 1 --

SELECT TOP 1 ((SELECT COUNT(*) FROM JAN)-(SELECT COUNT(*) FROM JAN WHERE CANCELLED = 1)) AS TOTAL_ACTUAL_FLIGHTS
FROM JAN

--METHOD 2 --

SELECT COUNT(*)
FROM JAN
WHERE CANCELLED = 0

--Even though method 1 is more conveluted than method 2, it confirms it. If both are the same, then the logic proves itself.
--Let's do the same for the other two months. --

-- FEB --

SELECT COUNT(*) AS TOTAL_FLIGHTS_PLANNED
FROM FEB

SELECT COUNT(*) AS TOTAL_CANCELLED
FROM FEB
WHERE CANCELLED = 1

SELECT TOP 1 ((SELECT COUNT(*) FROM FEB)-(SELECT COUNT(*) FROM FEB WHERE CANCELLED = 1)) AS TOTAL_ACTUAL_FLIGHTS
FROM FEB

SELECT COUNT(*)
FROM FEB
WHERE CANCELLED = 0

-- MAR --
SELECT COUNT(*) AS TOTAL_FLIGHTS_PLANNED
FROM MAR

SELECT COUNT(*) AS TOTAL_CANCELLED
FROM MAR
WHERE CANCELLED = 1

SELECT TOP 1 ((SELECT COUNT(*) FROM MAR)-(SELECT COUNT(*) FROM MAR WHERE CANCELLED = 1)) AS TOTAL_ACTUAL_FLIGHTS
FROM MAR

SELECT COUNT(*)
FROM MAR
WHERE CANCELLED = 0

--TOTAL_FLIGHTS_PLANNED → JAN: 538,837	FEB: 502,749	MAR: 580,322 --
--TOTAL FLIGHTS CANCELLED → JAN: 10,295	FEB: 9,019	MAR: 7,406 --
--TOTAL ACTUAL FLIGHTS → JAN: 528,542	FEB: 493,730	MAR: 572,916 --

--Now, for the sum of all of them --

select (SELECT COUNT(*) FROM MAR)+(SELECT COUNT(*) FROM FEB )+(SELECT COUNT(*) FROM JAN) AS TOTAL_PLANNED_Q1

select (SELECT COUNT(*) FROM MAR WHERE CANCELLED = 1)+(SELECT COUNT(*) FROM FEB WHERE CANCELLED = 1)+(SELECT COUNT(*) FROM JAN WHERE CANCELLED = 1) AS TOTAL_CANCELLED_Q1

select (SELECT COUNT(*) FROM MAR WHERE CANCELLED = 0)+(SELECT COUNT(*) FROM FEB WHERE CANCELLED = 0)+(SELECT COUNT(*) FROM JAN WHERE CANCELLED = 0) AS TOTAL_FLIGHTS_Q1

 -- TOTAL_PLANNED_Q1 → 1,621,908 --
 -- TOTAL_CANCELLED_Q1 → 26,720 --
 -- TOTAL_FLIGHTS_Q1 → 1,595,188 --

 --------------------------------------------
 -- 2. SOLUTION: Average Delay Time --

 SELECT COUNT(*) AS DELAYED
 FROM JAN
 WHERE DEP_DELAY > 0 

  SELECT COUNT(*)  AS NOT_DELAYED
 FROM JAN
 WHERE DEP_DELAY <= 0
 
 --To calculate the minutes of delay, I used the following formula in Excel --
 -- Duration (in minutes)=(End Hour−Start Hour)×60+(End Minute−Start Minute) --
 -- But this creates a problem... --
 -- The problem with the delay column is that the calculation used to achieve the minutes of delay only applies to some of the values.
 --If a flight is supposed to leave at 2200 hours, but it leaves de facto at 300 hours, the time difference isn't 19 hours, as the formula suggests. --
 -- Instead, it should be a 5 hour difference only, and not ahead, but behind. --
-- To remedy this, I need to concoct another formula for these specific cases --
-- I am going to assume that every flight that is supposed to depart after 6pm and its departure takes place during the early hours, then the flight is in fact, delayed --

SELECT CRS_DEP_TIME, DEP_TIME, DEP_DELAY
FROM JAN 
WHERE LEN(CRS_DEP_TIME) = 4 AND LEN(DEP_TIME) = 3 AND CRS_DEP_TIME >1800

-- Note how in this, the DEP_DELAY shows us wrong numbers. We need to understand that the early hours times are for the next day, and not earlier of the same day --
--Let's update the data, shall we? --
--Duration (in minutes)=((End Hour+24)−Start Hour)×60+(End Minute−Start Minute)

UPDATE JAN
SET DEP_DELAY =((LEFT(DEP_TIME,1)+24)-(CAST(LEFT(CRS_DEP_TIME,2)AS int)))*60+(cast(RIGHT(DEP_TIME,2)As int)-(cast(RIGHT(CRS_DEP_TIME,2)AS int)))
WHERE LEN(CRS_DEP_TIME) = 4 AND LEN(DEP_TIME) = 3 AND CRS_DEP_TIME >1800


SELECT CRS_DEP_TIME, DEP_TIME, DEP_DELAY
FROM JAN 
WHERE LEN(CRS_DEP_TIME) = 4 AND LEN(DEP_TIME) = 4 AND CRS_DEP_TIME >1800

-- With that fixed, we now can conclude that the total number of fights that had delayed departures are:
select COUNT(dep_time) AS DEPARTURE_DELAYS
from JAN
where DEP_DELAY > 0 

-- Delayed departures: 201,442 flights

-- Let's repeat the process for all the other months

--FEB--

SELECT CRS_DEP_TIME, DEP_TIME, DEP_DELAY
FROM FEB
WHERE LEN(CRS_DEP_TIME) = 4 AND LEN(DEP_TIME) = 3 AND CRS_DEP_TIME >1800

UPDATE FEB
SET DEP_DELAY =((LEFT(DEP_TIME,1)+24)-(CAST(LEFT(CRS_DEP_TIME,2)AS int)))*60+(cast(RIGHT(DEP_TIME,2)As int)-(cast(RIGHT(CRS_DEP_TIME,2)AS int)))
WHERE LEN(CRS_DEP_TIME) = 4 AND LEN(DEP_TIME) = 3 AND CRS_DEP_TIME >1800

select COUNT(dep_time) AS DEPARTURE_DELAYS
from FEB
where DEP_DELAY > 0

--MAR--

SELECT CRS_DEP_TIME, DEP_TIME, DEP_DELAY
FROM MAR
WHERE LEN(CRS_DEP_TIME) = 4 AND LEN(DEP_TIME) = 3 AND CRS_DEP_TIME >1800

UPDATE MAR
SET DEP_DELAY =((LEFT(DEP_TIME,1)+24)-(CAST(LEFT(CRS_DEP_TIME,2)AS int)))*60+(cast(RIGHT(DEP_TIME,2)As int)-(cast(RIGHT(CRS_DEP_TIME,2)AS int)))
WHERE LEN(CRS_DEP_TIME) = 4 AND LEN(DEP_TIME) = 3 AND CRS_DEP_TIME >1800

select COUNT(dep_time) AS DEPARTURE_DELAYS
from MAR
where DEP_DELAY > 0

-- TOTALS ---
--JAN: 201,442
--FEB 174,248
--MAR 232,706

SELECT (SELECT COUNT(*) FROM JAN WHERE DEP_DELAY > 0)+(SELECT COUNT(*) FROM FEB WHERE DEP_DELAY > 0)+(SELECT COUNT(*) FROM MAR WHERE DEP_DELAY > 0) AS TOTAL_DELAYS_DEPARTURES

--TOTAL DELAYS DEPARTURES: 608,396 --

--Now, the question is, how many flights arrived late? --

--JAN --
UPDATE JAN
SET ARR_DELAY_IN_MIN =((LEFT(ARR_TIME,1)+24)-(CAST(LEFT(CRS_ARR_TIME,2)AS int)))*60+(cast(RIGHT(ARR_TIME,2)As int)-(cast(RIGHT(CRS_ARR_TIME,2)AS int)))
WHERE LEN(CRS_ARR_TIME) = 4 AND LEN(ARR_TIME) = 3 AND CRS_ARR_TIME >1800

SELECT CRS_ARR_TIME,ARR_TIME,ARR_DELAY_IN_MIN
FROM JAN
WHERE LEN(CRS_ARR_TIME) = 4 AND LEN(ARR_TIME) = 3 AND CRS_ARR_TIME > 1800

--FEB --
 UPDATE FEB
SET ARR_DELAY =((LEFT(ARR_TIME,1)+24)-(CAST(LEFT(CRS_ARR_TIME,2)AS int)))*60+(cast(RIGHT(ARR_TIME,2)As int)-(cast(RIGHT(CRS_ARR_TIME,2)AS int)))
WHERE LEN(CRS_ARR_TIME) = 4 AND LEN(ARR_TIME) = 3 AND CRS_ARR_TIME >1800

SELECT CRS_ARR_TIME,ARR_TIME,ARR_DELAY
FROM FEB
WHERE LEN(CRS_ARR_TIME) = 4 AND LEN(ARR_TIME) = 3 AND CRS_ARR_TIME > 1800

--MAR--
 UPDATE MAR
SET ARR_DELAY =((LEFT(ARR_TIME,1)+24)-(CAST(LEFT(CRS_ARR_TIME,2)AS int)))*60+(cast(RIGHT(ARR_TIME,2)As int)-(cast(RIGHT(CRS_ARR_TIME,2)AS int)))
WHERE LEN(CRS_ARR_TIME) = 4 AND LEN(ARR_TIME) = 3 AND CRS_ARR_TIME >1800

SELECT CRS_ARR_TIME,ARR_TIME,ARR_DELAY
FROM MAR
WHERE LEN(CRS_ARR_TIME) = 4 AND LEN(ARR_TIME) = 3 AND CRS_ARR_TIME > 1800

-- TOTALS --
SELECT COUNT(ARR_DELAY_IN_MIN) AS DELAYED_ARRIVALS
FROM JAN 
WHERE ARR_DELAY_IN_MIN > 0

SELECT COUNT(ARR_DELAY) AS DELAYED_ARRIVALS
FROM FEB
WHERE ARR_DELAY > 0

SELECT COUNT(ARR_DELAY) AS DELAYED_ARRIVALS
FROM MAR
WHERE ARR_DELAY > 0


-- JAN: 199,327 --
-- FEB: 170230 --
-- MAR: 239,395 --


select (select COUNT(*) from JAN where ARR_DELAY_IN_MIN>0)+(select COUNT(*) from feb where ARR_DELAY>0)+(select COUNT(*) from mar where ARR_DELAY>0) AS	TOTAL_DELAYED_ARRIVALS

--TOTAL LATE ARRIVALS: 608,952 --

-- The total amount of late arrivals and delayed departures should be the same, but take a look here: --
--TOTAL DELAYS DEPARTURES: 608,396 --
--TOTAL LATE ARRIVALS: 608,952 --

select (select COUNT(*) from JAN where ARR_DELAY_IN_MIN>0)+(select COUNT(*) from feb where ARR_DELAY>0)+(select COUNT(*) from mar where ARR_DELAY>0)
-
(SELECT(SELECT COUNT(*) FROM JAN WHERE DEP_DELAY > 0)+(SELECT COUNT(*) FROM FEB WHERE DEP_DELAY > 0)+(SELECT COUNT(*) FROM MAR WHERE DEP_DELAY > 0))
AS LATE_ARRIVALS_BUT_ON_TIME_ARRIVALS

-- LATE DEPARTURES BUT ON TIME ARRIVALS: 556 --

--Let's find out the average delay time per month --

--FIRST, the DEPARTURES
SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM JAN WHERE DEP_DELAY > 0

SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM FEB WHERE DEP_DELAY > 0

SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM MAR WHERE DEP_DELAY > 0

--Now, the arrivals

SELECT  ROUND(AVG(ARR_DELAY_IN_MIN),0) AS AVG_ARR_DELAY FROM JAN WHERE ARR_DELAY_IN_MIN > 0

SELECT  ROUND(AVG(ARR_DELAY),0) AS AVG_ARR_DELAY FROM FEB WHERE ARR_DELAY > 0

SELECT  ROUND(AVG(ARR_DELAY),0) AS AVG_ARR_DELAY FROM MAR WHERE ARR_DELAY > 0


-- JAN: 43 min of delay in departures and 67 min of delays in arrivals --
-- FEV: 38 min of delay in departures and 39 min of delays in arrivals --
-- MAR: 40 min of delay in departures and 40 min of delays in arrivals --

with CTE_AVG_DEP_DELAYS AS
(
SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM JAN WHERE DEP_DELAY > 0
UNION
SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM FEB WHERE DEP_DELAY > 0
UNION
SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM MAR WHERE DEP_DELAY > 0
)
SELECT ROUND(AVG(AVG_DEP_DELAY),0) AS AVG_DEP_DELAY--, ROUND(AVG(AVG_ARR_DELAY),0)  AS AVG_ARR_DELAY
FROM CTE_AVG_DEP_DELAYS


with CTE_AVG_ARR_DELAYS AS
(
SELECT ROUND(AVG(ARR_DELAY_IN_MIN),0) AS AVG_ARR_DELAY FROM JAN WHERE ARR_DELAY_IN_MIN > 0
UNION
SELECT ROUND(AVG(ARR_DELAY),0) AS AVG_ARR_DELAY FROM FEB WHERE ARR_DELAY > 0
UNION
SELECT ROUND(AVG(ARR_DELAY),0) AS AVG_ARR_DELAY FROM MAR WHERE ARR_DELAY > 0
)
SELECT ROUND(AVG(AVG_ARR_DELAY),0)  AS AVG_ARR_DELAY
FROM CTE_AVG_ARR_DELAYS

-- All months: 40 min of delay in departures and 49 min of delays in arrivals --

-- 3. SOLUTION: Monthly Flight Trends --
-- Trends of what?--
-- 3.a) Let's find which companies had the most booked flights --
-- 3.b) Let's also find out which destination and origin was the most popular --

--3.a)

-- I noticed I didn't have a column with names for the carriers, only the code. It's not very descriptive though. So let's add some columns and fill them.
ALTER TABLE mar
ADD CARRIER_NAME NVARCHAR(255)

UPDATE JAN
SET CARRIER_NAME =
	CASE
		WHEN OP_UNIQUE_CARRIER LIKE '9E' THEN 'Endeavor Air' --1
		WHEN OP_UNIQUE_CARRIER LIKE 'AA' THEN 'American Airlines' --2
		WHEN OP_UNIQUE_CARRIER LIKE 'AS' THEN 'Alaska Airlines' --3
		WHEN OP_UNIQUE_CARRIER LIKE 'B6' THEN 'Jetblue Airways Corporation' --4
		WHEN OP_UNIQUE_CARRIER LIKE 'DL' THEN 'Delta Air Lines, Inc.'--5
		WHEN OP_UNIQUE_CARRIER LIKE 'F9' THEN 'Frontier Airlines, Inc.'--6
		WHEN OP_UNIQUE_CARRIER LIKE 'G4' THEN 'Allegiant Air LLC '--7
		WHEN OP_UNIQUE_CARRIER LIKE 'HA' THEN 'Hawaiian Airlines Inc.'--8
		WHEN OP_UNIQUE_CARRIER LIKE 'MQ' THEN 'Envoy Air '--9
		WHEN OP_UNIQUE_CARRIER LIKE 'NK' THEN 'Spirit Airlines, Inc. '--10
		WHEN OP_UNIQUE_CARRIER LIKE 'OH' THEN 'Jetstream Intl '--11
		WHEN OP_UNIQUE_CARRIER LIKE 'OO' THEN 'Skywest Airlines '--12
		WHEN OP_UNIQUE_CARRIER LIKE 'UA' THEN 'United Airlines, Inc.'--13
		WHEN OP_UNIQUE_CARRIER LIKE 'WN' THEN 'Southwest Airlines '--14
		WHEN OP_UNIQUE_CARRIER LIKE 'YX' THEN 'Republic Airlines '--15
		else NULL
		END

-- The process has been done for all months. --
-- Now let's find out the answer --

SELECT COUNT(DISTINCT(CARRIER_NAME)) AS TOTAL_CARRIERS
FROM JAN

SELECT  COUNT(FL_DATE) AS COUNT_OF_FLIGHTS, CARRIER_NAME
FROM JAN
GROUP BY CARRIER_NAME
ORDER BY 1 DESC

-- For the month of January, the champion of flights was Southwest Airlines with a whooping 112,430 flights.--

SELECT COUNT(DISTINCT(CARRIER_NAME)) AS TOTAL_CARRIERS
FROM feb

SELECT  COUNT(FL_DATE) AS COUNT_OF_FLIGHTS, CARRIER_NAME
FROM feb
GROUP BY CARRIER_NAME
ORDER BY 1 DESC

-- For February it was Southwest Airlines also with 101,445 flights --

SELECT COUNT(DISTINCT(CARRIER_NAME)) AS TOTAL_CARRIERS
FROM mar

SELECT  COUNT(FL_DATE) AS COUNT_OF_FLIGHTS, CARRIER_NAME
FROM mar
GROUP BY CARRIER_NAME
ORDER BY 1 DESC

-- And in March, again, Southwest Airlines with 117,997 flights --

--3.b)--

SELECT TOP 10 DEST_CITY_NAME, COUNT(DEST_CITY_NAME) AS DESTINATION_COUNT
FROM JAN
GROUP BY DEST_CITY_NAME 
ORDER BY 2 DESC

-- In January the most popular destination was Chicago --

SELECT TOP 10 DEST_CITY_NAME, COUNT(DEST_CITY_NAME) AS DESTINATION_COUNT
FROM feb
GROUP BY DEST_CITY_NAME 
ORDER BY 2 DESC

-- In February it was Chicago as well --

SELECT TOP 10 DEST_CITY_NAME, COUNT(DEST_CITY_NAME) AS DESTINATION_COUNT
FROM mar
GROUP BY DEST_CITY_NAME 
ORDER BY 2 DESC

-- In March as well, Chicago --
WITH CTE_DESTINATIONS AS
(
SELECT COUNT(DEST_CITY_NAME) AS COUNT_CITY, DEST_CITY_NAME
FROM JAN
GROUP BY DEST_CITY_NAME
UNION
SELECT COUNT(DEST_CITY_NAME) AS COUNT_CITY, DEST_CITY_NAME
FROM FEB
GROUP BY DEST_CITY_NAME
UNION
SELECT COUNT(DEST_CITY_NAME) AS COUNT_CITY, DEST_CITY_NAME
FROM MAR
GROUP BY DEST_CITY_NAME
)
SELECT TOP 10 DEST_CITY_NAME, SUM(COUNT_CITY) AS COUNT_CITY_TOTAL
FROM CTE_DESTINATIONS
GROUP BY DEST_CITY_NAME
ORDER BY 2 DESC

-- Chicago, the number one destination of the first quarter, had 80,738 flights to it --

-- We now repeat this process but with origins --

SELECT TOP 1 origin_CITY_NAME, COUNT(origin_CITY_NAME) AS ORIGIN_COUNT
FROM JAN
GROUP BY ORIGIN_CITY_NAME 
ORDER BY 2 DESC

SELECT TOP 1 origin_CITY_NAME, COUNT(origin_CITY_NAME) AS ORIGIN_COUNT
FROM FEB
GROUP BY ORIGIN_CITY_NAME 
ORDER BY 2 DESC

SELECT TOP 1 origin_CITY_NAME, COUNT(origin_CITY_NAME) AS ORIGIN_COUNT
FROM MAR
GROUP BY ORIGIN_CITY_NAME 
ORDER BY 2 DESC

-- The destination that had the most flights was Chicago in all three months --

with cte_origin as (
SELECT origin_CITY_NAME, COUNT(origin_CITY_NAME) AS ORIGIN_COUNT
FROM JAN
GROUP BY ORIGIN_CITY_NAME 
union
SELECT origin_CITY_NAME, COUNT(origin_CITY_NAME) AS ORIGIN_COUNT
FROM FEB
GROUP BY ORIGIN_CITY_NAME 
union
SELECT origin_CITY_NAME, COUNT(origin_CITY_NAME) AS ORIGIN_COUNT
FROM MAR
GROUP BY ORIGIN_CITY_NAME 
)
SELECT TOP 10 SUM(ORIGIN_COUNT) AS COUNT_CITY_TOTAL, ORIGIN_CITY_NAME
FROM cte_origin
GROUP BY ORIGIN_CITY_NAME
ORDER BY 1 DESC

-- Obviously, Chicago is the most popular origin of the quarter with 80,739 flights departing from it. --

--4. SOLUTION: Airlines with the Most Delays --

select distinct(carrier_name), COUNT(dep_delay) AS Count_Flights_delayed, COUNT(ARR_TIME) AS COUNT_FLIGHTS_LATE
from JAN
where DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
group by carrier_name
ORDER BY 2 DESC, 3 DESC

select  distinct(carrier_name), COUNT(dep_delay) AS Count_Flights_delayed, COUNT(ARR_TIME) AS COUNT_FLIGHTS_LATE
from FEB
where DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
group by carrier_name
ORDER BY 2 DESC, 3 DESC

select distinct(carrier_name), COUNT(dep_delay) AS Count_Flights_delayed, COUNT(ARR_TIME) AS COUNT_FLIGHTS_LATE
from MAR
where DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
group by carrier_name
ORDER BY 2 DESC, 3 DESC


with CTE AS(
select distinct(carrier_name), COUNT(dep_delay) AS Count_Flights_delayed, COUNT(ARR_TIME) AS COUNT_FLIGHTS_LATE
from JAN
where DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
group by carrier_name
UNION
select distinct(carrier_name), COUNT(dep_delay) AS Count_Flights_delayed, COUNT(ARR_TIME) AS COUNT_FLIGHTS_LATE
from FEB
where DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
group by carrier_name
UNION
select  distinct(carrier_name), COUNT(dep_delay) AS Count_Flights_delayed, COUNT(ARR_TIME) AS COUNT_FLIGHTS_LATE
from MAR
where DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
group by carrier_name
)

SELECT distinct(Carrier_name), sum(Count_Flights_delayed) AS Count_Flights_delayed , sum(COUNT_FLIGHTS_LATE) AS COUNT_FLIGHTS_LATE
FROM CTE
group by carrier_name
ORDER BY 2 DESC, 3 DESC
-----------

-- Carrier with most delayed departures and late arrivals --
-- SOUTHWEST AIRLINES was the one with most delayed departures and late arrivals for the entirety of the first quarter --
--JAN:	51,815 and 51,788 --
--FEB:	43,869 and 43,852 --
--MAR:	62,466 and 62,452 --
--TOTAL 158,150 and	158,092 --

-- This is in total quantity, but of course Southwest would have the most delays as it is also the carrier with most flights overall. --
--Let's find the answer in percentages --

SELECT J1.CARRIER_NAME,J2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/J2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM JAN AS J1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS J2
	ON J2.CARRIER_NAME = J1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY J1.CARRIER_NAME, J2.COUNT_FLIGHTS
ORDER BY 4 DESC

SELECT F1.CARRIER_NAME,F2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/F2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM FEB AS F1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM FEB GROUP BY CARRIER_NAME) AS F2
	ON F2.CARRIER_NAME = F1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY F1.CARRIER_NAME, F2.COUNT_FLIGHTS
ORDER BY 4 DESC

SELECT M1.CARRIER_NAME,M2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/M2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM MAR AS M1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS M2
	ON M2.CARRIER_NAME = M1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY M1.CARRIER_NAME, M2.COUNT_FLIGHTS
ORDER BY 4 DESC

WITH CTE AS
(
SELECT J1.CARRIER_NAME,J2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/J2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM JAN AS J1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS J2
	ON J2.CARRIER_NAME = J1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY J1.CARRIER_NAME, J2.COUNT_FLIGHTS

UNION
SELECT F1.CARRIER_NAME,F2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/F2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM FEB AS F1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM FEB GROUP BY CARRIER_NAME) AS F2
	ON F2.CARRIER_NAME = F1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY F1.CARRIER_NAME, F2.COUNT_FLIGHTS

UNION
SELECT M1.CARRIER_NAME,M2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/M2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM MAR AS M1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS M2
	ON M2.CARRIER_NAME = M1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY M1.CARRIER_NAME, M2.COUNT_FLIGHTS

)
SELECT DISTINCT(CARRIER_NAME), SUM(COUNT_FLIGHTS) AS COUNT_FLIGHTS, SUM(COUNT_DELAYS) AS COUNT_DELAYS, concat(((SUM(COUNT_DELAYS)*100)/SUM(COUNT_FLIGHTS)),'%') as Percentage_Carrier
FROM CTE
GROUP BY CARRIER_NAME
ORDER BY 4 DESC

-- Now we want to find out the same, but instead of departures, arrivals --

SELECT J1.CARRIER_NAME,J2.COUNT_FLIGHTS, COUNT(ARR_DELAY_IN_MIN) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY_IN_MIN)*100)/J2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM JAN AS J1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS J2
	ON J2.CARRIER_NAME = J1.CARRIER_NAME 
WHERE ARR_DELAY_IN_MIN > 0 AND ARR_DELAY_IN_MIN IS NOT NULL
GROUP BY J1.CARRIER_NAME, J2.COUNT_FLIGHTS
ORDER BY 4 DESC

SELECT F1.CARRIER_NAME,F2.COUNT_FLIGHTS, COUNT(ARR_DELAY) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY)*100)/F2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM FEB AS F1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM FEB GROUP BY CARRIER_NAME) AS F2
	ON F2.CARRIER_NAME = F1.CARRIER_NAME 
WHERE ARR_DELAY > 0 AND ARR_DELAY IS NOT NULL
GROUP BY F1.CARRIER_NAME, F2.COUNT_FLIGHTS
ORDER BY 4 DESC

SELECT M1.CARRIER_NAME,M2.COUNT_FLIGHTS, COUNT(ARR_DELAY) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY)*100)/M2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM MAR AS M1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM MAR GROUP BY CARRIER_NAME) AS M2
	ON M2.CARRIER_NAME = M1.CARRIER_NAME 
WHERE ARR_DELAY > 0 AND ARR_DELAY IS NOT NULL
GROUP BY M1.CARRIER_NAME, M2.COUNT_FLIGHTS
ORDER BY 4 DESC

WITH CTE AS (
SELECT J1.CARRIER_NAME,J2.COUNT_FLIGHTS, COUNT(ARR_DELAY_IN_MIN) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY_IN_MIN)*100)/J2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM JAN AS J1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS J2
	ON J2.CARRIER_NAME = J1.CARRIER_NAME 
WHERE ARR_DELAY_IN_MIN > 0 AND ARR_DELAY_IN_MIN IS NOT NULL
GROUP BY J1.CARRIER_NAME, J2.COUNT_FLIGHTS
UNION
SELECT F1.CARRIER_NAME,F2.COUNT_FLIGHTS, COUNT(ARR_DELAY) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY)*100)/F2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM FEB AS F1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM FEB GROUP BY CARRIER_NAME) AS F2
	ON F2.CARRIER_NAME = F1.CARRIER_NAME 
WHERE ARR_DELAY > 0 AND ARR_DELAY IS NOT NULL
GROUP BY F1.CARRIER_NAME, F2.COUNT_FLIGHTS
UNION
SELECT M1.CARRIER_NAME,M2.COUNT_FLIGHTS, COUNT(ARR_DELAY) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY)*100)/M2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM MAR AS M1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM MAR GROUP BY CARRIER_NAME) AS M2
	ON M2.CARRIER_NAME = M1.CARRIER_NAME 
WHERE ARR_DELAY > 0 AND ARR_DELAY IS NOT NULL
GROUP BY M1.CARRIER_NAME, M2.COUNT_FLIGHTS
)
SELECT DISTINCT(CARRIER_NAME), SUM(COUNT_FLIGHTS) AS COUNT_FLIGHTS, SUM(COUNT_DELAYS) AS COUNT_DELAYS, concat(((SUM(COUNT_DELAYS)*100)/SUM(COUNT_FLIGHTS)),'%') as Percentage_Carrier
FROM CTE
GROUP BY CARRIER_NAME
ORDER BY 4 DESC

-- With this information we can discover that for the months of January:

-- Frontier Airlines has the most departure delays, with 49% of their flights being delayed. As for arrivals, Hawaiian Airlines was late in 50% of their flights.

-- In FEB --

-- Hawaiian Airlines being in the number one stop in both departures and arrivals, with 49%  and 57%, respectively. 

-- In MAR --

-- Hawaiian Airlines in number one in departures with 62%, and in arrivals with 69% --

--For the first quarter it was:

-- DEPARTURES: Hawaiian Airlines 52% of their total flights
-- ARRIVALS: Hawaiian Airlines 59% of their total flights

-- Now we will find out the carriers that had the most cancellations overall and then in percentages. --

SELECT DISTINCT(CARRIER_NAME), COUNT(CANCELLED) AS FLIGHTS_CANCELLED
FROM JAN
WHERE CANCELLED = 1
GROUP BY CARRIER_NAME
ORDER BY 2 DESC

SELECT DISTINCT(CARRIER_NAME), COUNT(CANCELLED) AS FLIGHTS_CANCELLED
FROM FEB
WHERE CANCELLED = 1
GROUP BY CARRIER_NAME
ORDER BY 2 DESC

SELECT DISTINCT(CARRIER_NAME), COUNT(CANCELLED) AS FLIGHTS_CANCELLED
FROM MAR
WHERE CANCELLED = 1
GROUP BY CARRIER_NAME
ORDER BY 2 DESC

--Not surprisingly, Southwest Airlines had the most cancelled flights for the months of JAN and FEB, as it's also the company with most flights booked.
-- In MAR, the carrier with most cancellations was Delta

WITH CTE AS(
SELECT DISTINCT(CARRIER_NAME), COUNT(CANCELLED) AS FLIGHTS_CANCELLED
FROM JAN
WHERE CANCELLED = 1
GROUP BY CARRIER_NAME
union
SELECT DISTINCT(CARRIER_NAME), COUNT(CANCELLED) AS FLIGHTS_CANCELLED
FROM FEB
WHERE CANCELLED = 1
GROUP BY CARRIER_NAME
union
SELECT DISTINCT(CARRIER_NAME), COUNT(CANCELLED) AS FLIGHTS_CANCELLED
FROM MAR
WHERE CANCELLED = 1
GROUP BY CARRIER_NAME
)
SELECT DISTINCT(CARRIER_NAME), SUM(FLIGHTS_CANCELLED) AS FLIGHTS_CANCELLED
FROM CTE
GROUP BY CARRIER_NAME
ORDER BY 2 DESC

--For the first quarter, the carrier with most cancelled flights overall is Southwest Airlines. The problem we run into is the same as before. The company with most
-- flights will also be the one with most cancellations, it's obvious. We need to find the percentage of cancellations. --

SELECT DISTINCT(J1.CARRIER_NAME), COUNT(CANCELLED) AS CANCELLED_FLIGHTS, COUNT_FLIGHTS, concat((round(((SUM(cancelled)*100)/COUNT_FLIGHTS),2)),'%') AS CANC_PERCENT
FROM JAN AS J1
JOIN (SELECT DISTINCT(CARRIER_NAME), COUNT(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS J2
	ON J1.CARRIER_NAME = J2.CARRIER_NAME
WHERE CANCELLED = 1
GROUP BY J1.CARRIER_NAME, J2.COUNT_FLIGHTS
ORDER BY 4 DESC

SELECT DISTINCT(F1.CARRIER_NAME), COUNT(CANCELLED) AS CANCELLED_FLIGHTS, COUNT_FLIGHTS, concat((round(((SUM(cancelled)*100)/COUNT_FLIGHTS),2)),'%') AS CANC_PERCENT
FROM FEB AS F1
JOIN (SELECT DISTINCT(CARRIER_NAME), COUNT(FL_DATE) AS COUNT_FLIGHTS FROM FEB GROUP BY CARRIER_NAME) AS F2
	ON F1.CARRIER_NAME = F2.CARRIER_NAME
WHERE CANCELLED = 1
GROUP BY F1.CARRIER_NAME, F2.COUNT_FLIGHTS
ORDER BY 4 DESC

SELECT DISTINCT(M1.CARRIER_NAME), COUNT(CANCELLED) AS CANCELLED_FLIGHTS, COUNT_FLIGHTS, concat((round(((SUM(cancelled)*100)/COUNT_FLIGHTS),2)),'%') AS CANC_PERCENT
FROM MAR AS M1
JOIN (SELECT DISTINCT(CARRIER_NAME), COUNT(FL_DATE) AS COUNT_FLIGHTS FROM MAR GROUP BY CARRIER_NAME) AS M2
	ON M1.CARRIER_NAME = M2.CARRIER_NAME
WHERE CANCELLED = 1
GROUP BY M1.CARRIER_NAME, M2.COUNT_FLIGHTS
ORDER BY 4 DESC

WITH CTE AS (
SELECT DISTINCT(J1.CARRIER_NAME), COUNT(CANCELLED) AS CANCELLED_FLIGHTS, COUNT_FLIGHTS, concat((round(((SUM(cancelled)*100)/COUNT_FLIGHTS),2)),'%') AS CANC_PERCENT
FROM JAN AS J1
JOIN (SELECT DISTINCT(CARRIER_NAME), COUNT(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS J2
	ON J1.CARRIER_NAME = J2.CARRIER_NAME
WHERE CANCELLED = 1
GROUP BY J1.CARRIER_NAME, J2.COUNT_FLIGHTS
UNION
SELECT DISTINCT(F1.CARRIER_NAME), COUNT(CANCELLED) AS CANCELLED_FLIGHTS, COUNT_FLIGHTS, concat((round(((SUM(cancelled)*100)/COUNT_FLIGHTS),2)),'%') AS CANC_PERCENT
FROM FEB AS F1
JOIN (SELECT DISTINCT(CARRIER_NAME), COUNT(FL_DATE) AS COUNT_FLIGHTS FROM FEB GROUP BY CARRIER_NAME) AS F2
	ON F1.CARRIER_NAME = F2.CARRIER_NAME
WHERE CANCELLED = 1
GROUP BY F1.CARRIER_NAME, F2.COUNT_FLIGHTS
UNION
SELECT DISTINCT(M1.CARRIER_NAME), COUNT(CANCELLED) AS CANCELLED_FLIGHTS, COUNT_FLIGHTS, concat((round(((SUM(cancelled)*100)/COUNT_FLIGHTS),2)),'%') AS CANC_PERCENT
FROM MAR AS M1
JOIN (SELECT DISTINCT(CARRIER_NAME), COUNT(FL_DATE) AS COUNT_FLIGHTS FROM MAR GROUP BY CARRIER_NAME) AS M2
	ON M1.CARRIER_NAME = M2.CARRIER_NAME
WHERE CANCELLED = 1
GROUP BY M1.CARRIER_NAME, M2.COUNT_FLIGHTS
)
SELECT DISTINCT(CARRIER_NAME), SUM(CANCELLED_FLIGHTS) AS CANCELLED_FLIGHTS, SUM(COUNT_FLIGHTS) AS COUNT_FLIGHTS,
CONCAT(ROUND(CONVERT(float, (sum(cancelled_flights) * 100) / (convert(float, (sum(count_flights))))), 2),'%')
FROM CTE
GROUP BY CARRIER_NAME
order by 4 desc

--For the months of JAN, FEB and MAR, the carrier with most delays in percentages were, respectively)
--JAN: Skywest Airlines with 3.32%
--FEB: Alaska Airlines with 3.2%
--MAR: Delta Airlines with 1.92% --

-- First Quarter: Skywest Airlines with 2.52% 

-- Now we have a better outlook of which carriers honored the booked flights in percents. We can see now that even though Southwest had the most cancellation in numbers,
-- in percentages, it is only in the 4th spot, with only 1.96% of its flights cancelled. --

-- 5. SOLUTION: Reasons for Cancellations

--Now we want to find out the most cancellation reasons.

SELECT CANCELLATION_CODE, COUNT(CANCELLATION_CODE)
FROM JAN
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE
order by 2 desc

--The cancellation reasons are represented by the letters A through D.
--According to the Transtats websites, the codes represent:
-- A		Carrier
-- B		Weather
-- C		National Air System
-- D		Security 

--Let's update our tables.

ALTER TABLE MAR
ADD CANCELLATION_REASONS NVARCHAR(255)

UPDATE MAR
SET CANCELLATION_REASONS =
CASE 
	WHEN CANCELLATION_CODE = 'A' THEN 'Carrier'
	WHEN CANCELLATION_CODE = 'B' THEN 'Weather'
	WHEN CANCELLATION_CODE = 'C' THEN 'National Air System'
	WHEN CANCELLATION_CODE = 'D' THEN 'Security'
	END

-- The process was applied to all tables.

-- Now we will find out the reasons per month

SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM JAN
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
order by 3 desc

SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM FEB
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
order by 3 desc

SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM MAR
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
order by 3 desc

-- In January, the main cause of cancellations was the Weather. 6,611
-- In February it was the Weather also. 7,019
-- And in March, the  Weather once more. 4,444 times

WITH CTE AS (
SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM JAN
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
UNION
SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM FEB
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
UNION
SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM MAR
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
)
SELECT CANCELLATION_CODE, CANCELLATION_REASONS, SUM(QUANTITY) AS QUANTITY
FROM CTE
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
ORDER BY 3 DESC

-- With this we can get a rough estimate for each cancellation type for the whole first quarter

--Weather				18074
--Carrier				5877
--National Air System	2579
--Security				190

--Let's try to find out WHERE most cancellation types happenned. 

-- To start, I decided to create new columns for each table. Now with this I am able to count each time a flight got cancelled for specific reasons
--and see which location had the most cancellations of a specific type.--
-- The process is done with every table.
ALTER TABLE MAR
ADD A INT

UPDATE FEB
SET A =
	CASE
		WHEN CANCELLATION_CODE ='A' THEN 1
		END
		

ALTER TABLE MAR
ADD B INT

UPDATE FEB
SET B =
	CASE
		WHEN CANCELLATION_CODE ='B' THEN 1
		END

ALTER TABLE MAR
ADD C INT

UPDATE FEB
SET C =
	CASE
		WHEN CANCELLATION_CODE ='C' THEN 1
		END


ALTER TABLE MAR
ADD D INT

UPDATE FEB
SET D =
	CASE
		WHEN CANCELLATION_CODE ='D' THEN 1
		END

-- JAN--

SELECT top 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT top 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather--, SUM(C) National_Air_System, SUM(D) 'Security'
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT TOP 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) National_Air_System --, SUM(D) 'Security'
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT TOP 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) 'Security'
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

--In the month of January, The places that had the most of each type of cancellation. --

-- CARRIER: New York, NY, 84 flights cancelled due to Carrier problems
-- WEATHER: Denver, CO, 687 flights cancelled due to Weather reasons
-- NATIONAL AIR SYSTEM: New York, NY, 157 flights cancelled by the National Air System
-- SECURITY: Charlotte, NC, 40 flights cancelled due to security reasons

-- FEB --

SELECT top 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT top 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather--, SUM(C) National_Air_System, SUM(D) 'Security'
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT TOP 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) National_Air_System --, SUM(D) 'Security'
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT TOP 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) 'Security'
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

--In the month of February, The places that had the most of each type of cancellation. --

-- CARRIER: New York, NY, 144 flights cancelled due to Carrier problems
-- WEATHER: Dallas, TX, 843 flights cancelled due to Weather reasons
-- NATIONAL AIR SYSTEM: New York, NY, 36 flights cancelled by the National Air System
-- SECURITY: No flights were cancelled due to security reasons

-- MAR --

SELECT top 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT top 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather--, SUM(C) National_Air_System, SUM(D) 'Security'
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT TOP 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) National_Air_System --, SUM(D) 'Security'
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC

SELECT TOP 1 ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) 'Security'
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
ORDER BY 3 DESC


--In the month of March, The places that had the most of each type of cancellation. --

-- CARRIER: New York, NY, 221 flights cancelled due to Carrier problems
-- WEATHER: Dallas, TX, 450 flights cancelled due to Weather reasons
-- NATIONAL AIR SYSTEM: Las Vegas, NV, 61 flights cancelled by the National Air System
-- SECURITY: Boston, MA, only 1 flight got cancelled due to security reasons. It was the only time a flight got cancelled due to Security reasons in the month of March.

-- As usual, let's find out the place with most cancellation overall by reasons.

-- CARRIER
WITH CTE AS (
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT  ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
)
SELECT TOP 10 ORIGIN_CITY_NAME, SUM(CARRIER) CARRIER_CANCELLED
FROM CTE
GROUP BY ORIGIN_CITY_NAME
ORDER BY 2 DESC

-- Weather --
WITH CTE AS (
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
)
SELECT  TOP 10 ORIGIN_CITY_NAME, SUM(Weather) Weather_Cancellations
FROM CTE
group by ORIGIN_CITY_NAME
ORDER BY 2 DESC

--National Air System --
WITH CTE AS (
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) NAS
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) NAS
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) NAS
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
)
SELECT  TOP 10 ORIGIN_CITY_NAME, SUM(NAS) TIMES_CANCELLED
FROM CTE
group by ORIGIN_CITY_NAME
ORDER BY 2 DESC

-- Security --

WITH CTE AS (
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) SECURITY
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) SECURITY
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) SECURITY
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
)
SELECT  TOP 10 ORIGIN_CITY_NAME, SUM(SECURITY) TIMES_CANCELLED
FROM CTE
group by ORIGIN_CITY_NAME
ORDER BY 2 DESC

-- In the first quarter, flightes the places that cancelled their flights due to...

-- Carrier problems, New York, 449 times
-- Weather issues, Dallas, 1966 times
-- National Air Security reasons, New York, 227 times
-- Security reasons, Charlotte, 40 times --
----------------------------------------------------------------------

-- Thus, we conclude all the queries necessary for this project. There was a lot to go through, but, there is still something more. 
-- To clear things and make reading all of the data in a more organized way, I'll save the answer for each question is specific temp tables. --

SELECT * FROM #QUESTION1

SELECT * FROM #QUESTION2

SELECT * FROM #QUESTION3a

select * from #QUESTION3b

SELECT * FROM #QUESTION4a

SELECT * FROM #QUESTION4b

SELECT * FROM #QUESTION5a

SELECT * FROM #QUESTION5b

--That way I can have easy access to them to extract the specific information.

-----------------------------------------------------------------------
--Abandon all hope ye who enter here--
--This point onward is the mess used to create the temp tables, I was able to sort out throught the entire mess to retrieve all the necessary information --

DROP TABLE IF EXISTS #QUESTION1
	CREATE TABLE #QUESTION1 
	(
	PLANNED_FLIGHTS INT,
	CANCELLED INT,
	ACTUAL_FLIGHTS INT
	)
ALTER TABLE #QUESTION1
ADD PERIOD NVARCHAR(255)

UPDATE #QUESTION1
SET PERIOD = 
	CASE
		WHEN ACTUAL_FLIGHTS = 1595188 THEN 'Total Quarter'
		WHEN ACTUAL_FLIGHTS = 528542 THEN 'January'
		WHEN ACTUAL_FLIGHTS = 493730 THEN 'February'
		WHEN ACTUAL_FLIGHTS = 572916 THEN 'March'
		end

INSERT INTO #QUESTION1 (PLANNED_FLIGHTS, CANCELLED, ACTUAL_FLIGHTS) VALUES (
(select CONVERT(INT,(SELECT COUNT(*) FROM MAR)+(SELECT COUNT(*) FROM FEB )+(SELECT COUNT(*) FROM JAN))),
(select CONVERT(INT,(SELECT COUNT(*) FROM MAR WHERE CANCELLED = 1)+(SELECT COUNT(*) FROM FEB WHERE CANCELLED = 1)+(SELECT COUNT(*) FROM JAN WHERE CANCELLED = 1))),
(select CONVERT(INT,(SELECT COUNT(*) FROM MAR WHERE CANCELLED = 0)+(SELECT COUNT(*) FROM FEB WHERE CANCELLED = 0)+(SELECT COUNT(*) FROM JAN WHERE CANCELLED = 0))))


INSERT INTO #QUESTION1 (PLANNED_FLIGHTS, CANCELLED, ACTUAL_FLIGHTS) VALUES (
(SELECT COUNT(*) AS TOTAL_FLIGHTS_PLANNED FROM JAN),
(SELECT COUNT(*) AS TOTAL_CANCELLED FROM JAN WHERE CANCELLED = 1),
(SELECT COUNT(*) AS TOTAL_ACTUAL FROM JAN WHERE CANCELLED = 0))

INSERT INTO #QUESTION1 (PLANNED_FLIGHTS, CANCELLED, ACTUAL_FLIGHTS) VALUES (
(SELECT COUNT(*) AS TOTAL_FLIGHTS_PLANNED FROM FEB),
(SELECT COUNT(*) AS TOTAL_CANCELLED FROM FEB WHERE CANCELLED = 1),
(SELECT COUNT(*) AS TOTAL_ACTUAL FROM FEB WHERE CANCELLED = 0))

INSERT INTO #QUESTION1 (PLANNED_FLIGHTS, CANCELLED, ACTUAL_FLIGHTS) VALUES (
(SELECT COUNT(*) AS TOTAL_FLIGHTS_PLANNED FROM MAR),
(SELECT COUNT(*) AS TOTAL_CANCELLED FROM MAR WHERE CANCELLED = 1),
(SELECT COUNT(*) AS TOTAL_ACTUAL FROM MAR WHERE CANCELLED = 0))



DROP TABLE  IF EXISTS #QUESTION2

CREATE TABLE #QUESTION2 
(
Period nvarchar(255),
AVG_Departue_delays_in_min int,
AVG_Arrival_delays_in_min int,
COUNT_DEP_Delays INT,
COUNT_ARR_Delays INT
)

INSERT INTO #QUESTION2 (PERIOD) VALUES
(
--'Total_Quarter'
--'Jan'
--'Feb'
--'Mar'
)

SELECT * FROM #QUESTION2

UPDATE #QUESTION2
SET COUNT_DEP_Delays =
	CASE WHEN Period = 'Jan'  THEN (select COUNT(dep_time) AS DEPARTURE_DELAYS from JAN where DEP_DELAY > 0)
	WHEN Period = 'Feb' THEN (select COUNT(dep_time) AS DEPARTURE_DELAYS from FEB where DEP_DELAY > 0 )
	WHEN Period = 'Mar' THEN (select COUNT(dep_time) AS DEPARTURE_DELAYS from MAR where DEP_DELAY > 0 )
	WHEN Period = 'Total_Quarter' THEN 
	(SELECT (SELECT COUNT(*) FROM JAN WHERE DEP_DELAY > 0)+(SELECT COUNT(*) FROM FEB WHERE DEP_DELAY > 0)+(SELECT COUNT(*) FROM MAR WHERE DEP_DELAY > 0) AS TOTAL_DELAYS_DEPARTURES
	)
	END

UPDATE #QUESTION2
SET COUNT_ARR_Delays =
	CASE WHEN Period = 'Jan' THEN (SELECT COUNT(ARR_DELAY_IN_MIN) AS DELAYED_ARRIVALS FROM JAN  WHERE ARR_DELAY_IN_MIN > 0)
	WHEN Period = 'Feb' THEN (SELECT COUNT(ARR_DELAY) AS DELAYED_ARRIVALS FROM FEB WHERE ARR_DELAY > 0)
	WHEN Period = 'Mar' THEN (SELECT COUNT(ARR_DELAY) AS DELAYED_ARRIVALS FROM MAR WHERE ARR_DELAY > 0)
	WHEN Period = 'Total_Quarter' THEN
	(select (select COUNT(*) from JAN where ARR_DELAY_IN_MIN>0)+(select COUNT(*) from feb where ARR_DELAY>0)+(select COUNT(*) from mar where ARR_DELAY>0) AS TOTAL_DELAYED_ARRIVALS)
	END



;WITH
				CTE_AVG_DEP_DELAYS AS (
				SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM JAN WHERE DEP_DELAY > 0
				UNION 
				SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM FEB WHERE DEP_DELAY > 0
				UNION
				SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM MAR WHERE DEP_DELAY > 0)
UPDATE #QUESTION2
SET AVG_Departue_delays_in_min = 
	CASE WHEN Period = 'Jan' THEN ((SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM JAN WHERE DEP_DELAY > 0))
	WHEN Period = 'Feb' THEN ((SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM FEB WHERE DEP_DELAY > 0))
	 WHEN Period = 'Mar' THEN (SELECT ROUND(AVG(DEP_DELAY),0) AS AVG_DEP_DELAY FROM MAR WHERE DEP_DELAY > 0)
	 WHEN Period = 'Total_Quarter' THEN (SELECT ROUND(AVG(AVG_DEP_DELAY),0) AS AVG_DEP_DELAY FROM CTE_AVG_DEP_DELAYS)
	 end

;with CTE_AVG_ARR_DELAYS AS
(
SELECT ROUND(AVG(ARR_DELAY_IN_MIN),0) AS AVG_ARR_DELAY FROM JAN WHERE ARR_DELAY_IN_MIN > 0
UNION
SELECT ROUND(AVG(ARR_DELAY),0) AS AVG_ARR_DELAY FROM FEB WHERE ARR_DELAY > 0
UNION
SELECT ROUND(AVG(ARR_DELAY),0) AS AVG_ARR_DELAY FROM MAR WHERE ARR_DELAY > 0
)
UPDATE #QUESTION2
SET Avg_Arrival_delays_in_min =
	CASE WHEN Period = 'Jan' THEN (SELECT  ROUND(AVG(ARR_DELAY_IN_MIN),0) AS AVG_ARR_DELAY FROM JAN WHERE ARR_DELAY_IN_MIN > 0)
	WHEN Period = 'Feb' THEN (SELECT  ROUND(AVG(ARR_DELAY),0) AS AVG_ARR_DELAY FROM FEB WHERE ARR_DELAY > 0)
	WHEN Period = 'Mar' THEN (SELECT  ROUND(AVG(ARR_DELAY),0) AS AVG_ARR_DELAY FROM MAR WHERE ARR_DELAY > 0)
	WHEN Period = 'Total_Quarter' THEN (SELECT ROUND(AVG(AVG_ARR_DELAY),0)  AS AVG_ARR_DELAY FROM CTE_AVG_ARR_DELAYS)
	END 

UPDATE #QUESTION2
SET COUNT_ARR_Delays =
	CASE WHEN Period = 'Jan' THEN (SELECT COUNT(ARR_DELAY_IN_MIN) AS DELAYED_ARRIVALS FROM JAN WHERE ARR_DELAY_IN_MIN > 0)
	WHEN Period = 'Feb' THEN (SELECT COUNT(ARR_DELAY) AS DELAYED_ARRIVALS FROM FEB WHERE ARR_DELAY > 0)
	WHEN Period = 'Mar' THEN ((SELECT COUNT(ARR_DELAY) AS DELAYED_ARRIVALS FROM MAR WHERE ARR_DELAY > 0))
	WHEN Period = 'Total_Quarter' THEN (select (select COUNT(*) from JAN where ARR_DELAY_IN_MIN>0)+(select COUNT(*) from feb where ARR_DELAY>0)+(select COUNT(*) from mar where ARR_DELAY>0) AS	TOTAL_DELAYED_ARRIVALS)
	END 

UPDATE #QUESTION2
SET COUNT_DEP_Delays =
	CASE WHEN Period = 'Jan' THEN (SELECT COUNT(DEP_DELAY) AS DELAYED_DEPIVALS FROM JAN WHERE DEP_DELAY > 0)
	WHEN Period = 'Feb' THEN (SELECT COUNT(DEP_DELAY) AS DELAYED_DEPIVALS FROM FEB WHERE DEP_DELAY > 0)
	WHEN Period = 'Mar' THEN ((SELECT COUNT(DEP_DELAY) AS DELAYED_DEPIVALS FROM MAR WHERE DEP_DELAY > 0))
	WHEN Period = 'Total_Quarter' THEN (select (select COUNT(*) from JAN where DEP_DELAY>0)+(select COUNT(*) from feb where DEP_DELAY>0)+(select COUNT(*) from mar where DEP_DELAY>0) AS	TOTAL_DELAYED_DEPIVALS)
	END 

SELECT * FROM #QUESTION2

DROP TABLE IF EXISTS #QUESTION3a
CREATE TABLE #QUESTION3a 
(
CARRIER_NAME NVARCHAR(255),
JAN_COUNT_FLIGHTS INT,
FEB_COUNT_FLIGHTS INT,
MAR_COUNT_FLIGHTS INT,
FIRST_QUARTER_FLIGHTS INT
)

INSERT INTO #QUESTION3a (CARRIER_NAME)
(
SELECT DISTINCT(CARRIER_NAME) FROM JAN GROUP BY CARRIER_NAME
)

UPDATE #QUESTION3a
SET JAN_COUNT_FLIGHTS = (SELECT COUNT(FL_DATE) FROM JAN WHERE #QUESTION3a.CARRIER_NAME = JAN.CARRIER_NAME GROUP BY CARRIER_NAME)

UPDATE #QUESTION3a
SET FEB_COUNT_FLIGHTS = (SELECT COUNT(FL_DATE) FROM FEB WHERE #QUESTION3a.CARRIER_NAME = FEB.CARRIER_NAME GROUP BY CARRIER_NAME)

UPDATE #QUESTION3a
SET MAR_COUNT_FLIGHTS = (SELECT COUNT(FL_DATE) FROM MAR WHERE #QUESTION3a.CARRIER_NAME = MAR.CARRIER_NAME GROUP BY CARRIER_NAME)


UPDATE #QUESTION3a
SET FIRST_QUARTER_FLIGHTS = ((SELECT COUNT(FL_DATE) FROM JAN WHERE #QUESTION3a.CARRIER_NAME = JAN.CARRIER_NAME GROUP BY CARRIER_NAME)+(SELECT COUNT(FL_DATE) FROM FEB WHERE #QUESTION3a.CARRIER_NAME = FEB.CARRIER_NAME GROUP BY CARRIER_NAME)+(SELECT COUNT(FL_DATE) FROM MAR WHERE #QUESTION3a.CARRIER_NAME = MAR.CARRIER_NAME GROUP BY CARRIER_NAME))


SELECT COUNT(FL_DATE), CARRIER_NAME FROM JAN GROUP BY CARRIER_NAME ORDER BY 1 DESC



SELECT * FROM #QUESTION3a ORDER BY 2 DESC

DROP TABLE IF EXISTS #QUESTION3b
CREATE TABLE #QUESTION3b 
(
Jan_Top_10_Dest nvarchar(255),
Jan_Top_10_Dest_Count int,
Feb_Top_10_Dest nvarchar(255),
Feb_Top_10_Dest_Count int,
Mar_Top_10_Dest nvarchar(255),
Mar_Top_10_Dest_Count int,
Total_Top_10_Dest nvarchar(255),
Total_Top_10_Dest_Count int,
)
DROP TABLE IF EXISTS column1
CREATE TABLE column1
(
Jan_Top_10_Dest nvarchar(255),
Jan_Top_10_Dest_Count int,
Feb_Top_10_Dest nvarchar(255),
Feb_Top_10_Dest_Count int,
Mar_Top_10_Dest nvarchar(255),
Mar_Top_10_Dest_Count int,
Total_Top_10_Dest nvarchar(255),
Total_Top_10_Dest_Count int,
)


select * from #QUESTION3b
select * from column1


with cte as (
SELECT TOP 10 DEST_CITY_NAME, COUNT(DEST_CITY_NAME) AS DESTINATION_COUNT FROM JAN GROUP BY DEST_CITY_NAME order by DESTINATION_COUNT desc)
insert into column1 (Jan_Top_10_Dest, Jan_Top_10_Dest_Count) 
select dest_city_name, Destination_Count
from cte

with cte as (
SELECT TOP 10 DEST_CITY_NAME, COUNT(DEST_CITY_NAME) AS DESTINATION_COUNT FROM FEB GROUP BY DEST_CITY_NAME order by DESTINATION_COUNT desc)
INSERT INTO column1 (Feb_Top_10_Dest, Feb_Top_10_Dest_Count)
SELECT DEST_CITY_NAME, DESTINATION_COUNT
FROM CTE


;WITH CTE AS (
(SELECT DEST_CITY_NAME, COUNT(DEST_CITY_NAME) AS DESTINATION_COUNT FROM JAN GROUP BY DEST_CITY_NAME)
UNION
(SELECT DEST_CITY_NAME, COUNT(DEST_CITY_NAME) AS DESTINATION_COUNT FROM FEB GROUP BY DEST_CITY_NAME)
UNION
(SELECT DEST_CITY_NAME, COUNT(DEST_CITY_NAME) AS DESTINATION_COUNT FROM MAR GROUP BY DEST_CITY_NAME)
)
INSERT INTO column1 (Total_Top_10_Dest, Total_Top_10_Dest_Count)
SELECT TOP 10 DEST_CITY_NAME, SUM(DESTINATION_COUNT)
FROM CTE
GROUP BY DEST_CITY_NAME
ORDER BY 2 DESC

select * from column1

INSERT INTO #QUESTION3b
SELECT * FROM column1

select * from #QUESTION3b

CREATE TABLE #QUESTION4a
(
CARRIER_NAME NVARCHAR(255),
COUNT_FLIGHTS INT,
COUNT_DELAYS_DEP INT,
PERCENTAGE_COUNT CHAR(10)
)




WITH CTE AS
(
SELECT J1.CARRIER_NAME,J2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/J2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM JAN AS J1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS J2
	ON J2.CARRIER_NAME = J1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY J1.CARRIER_NAME, J2.COUNT_FLIGHTS

UNION
SELECT F1.CARRIER_NAME,F2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/F2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM FEB AS F1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM FEB GROUP BY CARRIER_NAME) AS F2
	ON F2.CARRIER_NAME = F1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY F1.CARRIER_NAME, F2.COUNT_FLIGHTS

UNION
SELECT M1.CARRIER_NAME,M2.COUNT_FLIGHTS, COUNT(DEP_DELAY) AS COUNT_DELAYS, concat(((COUNT(DEP_DELAY)*100)/M2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM MAR AS M1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS M2
	ON M2.CARRIER_NAME = M1.CARRIER_NAME 
WHERE DEP_DELAY > 0 AND DEP_DELAY IS NOT NULL
GROUP BY M1.CARRIER_NAME, M2.COUNT_FLIGHTS

)
INSERT INTO #QUESTION4a (CARRIER_NAME, COUNT_FLIGHTS, COUNT_DELAYS_DEP, PERCENTAGE_COUNT)
SELECT DISTINCT(CARRIER_NAME), SUM(COUNT_FLIGHTS) AS COUNT_FLIGHTS, SUM(COUNT_DELAYS) AS COUNT_DELAYS, concat(((SUM(COUNT_DELAYS)*100)/SUM(COUNT_FLIGHTS)),'%') as Percentage_Carrier
FROM CTE
GROUP BY CARRIER_NAME
ORDER BY CARRIER_NAME ASC

SELECT * FROM #QUESTION4a

CREATE TABLE #QUESTION4b (
CARRIER_NAME NVARCHAR(255),
COUNT_FLIGHTS INT,
COUNT_DELAYS_ARR INT,
PERCENTAGE_COUNT CHAR(10))


WITH CTE AS (
SELECT J1.CARRIER_NAME,J2.COUNT_FLIGHTS, COUNT(ARR_DELAY_IN_MIN) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY_IN_MIN)*100)/J2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM JAN AS J1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM JAN GROUP BY CARRIER_NAME) AS J2
	ON J2.CARRIER_NAME = J1.CARRIER_NAME 
WHERE ARR_DELAY_IN_MIN > 0 AND ARR_DELAY_IN_MIN IS NOT NULL
GROUP BY J1.CARRIER_NAME, J2.COUNT_FLIGHTS
UNION
SELECT F1.CARRIER_NAME,F2.COUNT_FLIGHTS, COUNT(ARR_DELAY) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY)*100)/F2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM FEB AS F1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM FEB GROUP BY CARRIER_NAME) AS F2
	ON F2.CARRIER_NAME = F1.CARRIER_NAME 
WHERE ARR_DELAY > 0 AND ARR_DELAY IS NOT NULL
GROUP BY F1.CARRIER_NAME, F2.COUNT_FLIGHTS
UNION
SELECT M1.CARRIER_NAME,M2.COUNT_FLIGHTS, COUNT(ARR_DELAY) AS COUNT_DELAYS, concat(((COUNT(ARR_DELAY)*100)/M2.COUNT_FLIGHTS),'%') as Percentage_Carrier
FROM MAR AS M1
join (select distinct(CARRIER_NAME), count(FL_DATE) AS COUNT_FLIGHTS FROM MAR GROUP BY CARRIER_NAME) AS M2
	ON M2.CARRIER_NAME = M1.CARRIER_NAME 
WHERE ARR_DELAY > 0 AND ARR_DELAY IS NOT NULL
GROUP BY M1.CARRIER_NAME, M2.COUNT_FLIGHTS
)
INSERT INTO #QUESTION4b
SELECT DISTINCT(CARRIER_NAME), SUM(COUNT_FLIGHTS) AS COUNT_FLIGHTS, SUM(COUNT_DELAYS) AS COUNT_DELAYS, concat(((SUM(COUNT_DELAYS)*100)/SUM(COUNT_FLIGHTS)),'%') as Percentage_Carrier
FROM CTE
GROUP BY CARRIER_NAME
ORDER BY CARRIER_NAME ASC


CREATE TABLE #QUESTION5a
(CODE CHAR(1),
REASON NVARCHAR(255),
QUANTITY INT)



;WITH CTE AS (
SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM JAN
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
UNION
SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM FEB
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
UNION
SELECT CANCELLATION_CODE, CANCELLATION_REASONS, COUNT(CANCELLATION_CODE) as Quantity
FROM MAR
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
)
INSERT INTO #QUESTION5a 
SELECT CANCELLATION_CODE, CANCELLATION_REASONS, SUM(QUANTITY) AS QUANTITY
FROM CTE
GROUP BY CANCELLATION_CODE, CANCELLATION_REASONS
ORDER BY CANCELLATION_CODE ASC


SELECT * FROM #QUESTION5a



CREATE TABLE #QUESTION5b (
ORIGIN_CITY_CARRIER NVARCHAR(255),
CARRIER_CANCELLATIONS INT,
ORIGIN_CITY_WEATHER NVARCHAR(255),
WEATHER_CANCELLATION INT,
ORIGIN_CITY_NAS NVARCHAR(255),
NAS_CANCELATTION INT,
ORIGIN_CITY_SECURITY NVARCHAR (255),
SECURITY_CANCELLATION INT
)



;WITH CTE AS (
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT  ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, sum(A) Carrier--,SUM(B) Weather, SUM(C) National_Air_System, SUM(D) 'Security'
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
)
INSERT INTO #QUESTION5b (ORIGIN_CITY_CARRIER, CARRIER_CANCELLATIONS)
SELECT TOP 10 ORIGIN_CITY_NAME, SUM(CARRIER) CARRIER_CANCELLED
FROM CTE
GROUP BY ORIGIN_CITY_NAME
ORDER BY 2 DESC


;WITH CTE AS (
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(B) Weather
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
)
INSERT INTO #QUESTION5b (ORIGIN_CITY_WEATHER, WEATHER_CANCELLATION)
SELECT  TOP 10 ORIGIN_CITY_NAME, SUM(Weather) Weather_Cancellations
FROM CTE
group by ORIGIN_CITY_NAME
ORDER BY 2 DESC


;WITH CTE AS (
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) NAS
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) NAS
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(C) NAS
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
)
INSERT INTO #QUESTION5b (ORIGIN_CITY_NAS, NAS_CANCELATTION)
SELECT  TOP 10 ORIGIN_CITY_NAME, SUM(NAS) TIMES_CANCELLED
FROM CTE
group by ORIGIN_CITY_NAME
ORDER BY 2 DESC


;WITH CTE AS (
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) SECURITY
FROM JAN
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) SECURITY
FROM FEB
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
UNION
SELECT ORIGIN_CITY_NAME, CANCELLATION_REASONS, SUM(D) SECURITY
FROM MAR
WHERE CANCELLED = 1 
GROUP BY ORIGIN_CITY_NAME, CANCELLATION_REASONS
)
INSERT INTO #QUESTION5b (ORIGIN_CITY_SECURITY, SECURITY_CANCELLATION)
SELECT  TOP 10 ORIGIN_CITY_NAME, SUM(SECURITY) TIMES_CANCELLED
FROM CTE
group by ORIGIN_CITY_NAME
ORDER BY 2 DESC


-- END OF QUERY --


