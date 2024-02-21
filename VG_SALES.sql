-- The entire dataset --

SELECT *
FROM vgsales

-- What do we intend to find out from this dataset? --

-- 1. Which console has had the biggest amount accumulated of sales? --
	-- 1a. Which console has had the biggest amount of sales per region? --
-- 2. Which genre has proven to be most profitable? --
		-- 2a. Which genre is most profitable per region? --
-- 3. What are the top 10 Publishers, in terms of sales? --
-- 4. What are the most profitable years? --


-- Let's analyze! -- 

-- 1. Which console has had the biggest amount accumulated of sales? --

WITH CTE_SALES_TOTAL
AS 
(
select PLATFORM, (EU_SALES+JP_SALES+NA_SALES+OTHER_SALES) AS MILLION_TOTAL_SALES
from vgsales
)
SELECT DISTINCT(PLATFORM), SUM(MILLION_TOTAL_SALES) OVER (PARTITION BY PLATFORM) AS MILLION_SALES_PER_PLATFORM
FROM CTE_SALES_TOTAL
GROUP BY (PLATFORM), MILLION_TOTAL_SALES
ORDER BY 2 DESC

-- ANSWER: The console with the most accumulated sales is the PS2 throughout all regions. The top 10 are:
	-- PS2, WII, X360, PS3, DS, PS, GB, PS4, NES, 3DS--

--1a. Which console has had the biggest amount of sales per region? --

-- JAPAN --
select DISTINCT(platform),SUM(JP_SALES) OVER (PARTITION BY PLATFORM) AS SALES_JP_PER_PLATFORM_PER_MILLION
from vgsales
GROUP BY JP_SALES, PLATFORM
ORDER BY SALES_JP_PER_PLATFORM_PER_MILLION DESC

--NORTH AMERICA -- 
select DISTINCT(platform),SUM(NA_SALES) OVER (PARTITION BY PLATFORM) AS SALES_NA_PER_PLATFORM_PER_MILLION
from vgsales
GROUP BY NA_SALES, PLATFORM
ORDER BY SALES_NA_PER_PLATFORM_PER_MILLION DESC

-- EUROPE --
select DISTINCT(platform),SUM(EU_SALES) OVER (PARTITION BY PLATFORM) AS SALES_EU_PER_PLATFORM_PER_MILLION
from vgsales
GROUP BY EU_SALES, PLATFORM
ORDER BY SALES_EU_PER_PLATFORM_PER_MILLION DESC

--REST OF THE WORLD --
select DISTINCT(platform),SUM(OTHER_SALES) OVER (PARTITION BY PLATFORM) AS SALES_OTHER_PER_PLATFORM_PER_MILLION
from vgsales
GROUP BY OTHER_SALES, PLATFORM
ORDER BY SALES_OTHER_PER_PLATFORM_PER_MILLION DESC


--ANSWER: In the Japanese region, the games most sold were for the Nintendo DS --
	-- In the North American region, the games most sold were for the Xbox 360 --
		-- In the European region, the games most sold were for the Nintendo Wii --
			-- As for the rest of the world, the games most sold were for the PlayStation 2 --

-- 2. Which genre has proven to be most profitable? --

select Genre, sum(NA_SALES) NA_SALES, sum(EU_SALES) EU_SALES, sum(JP_SALES) JP_SALES, sum(OTHER_SALES) OTHER_SALES
from vgsales
GROUP BY Genre
ORDER BY GENRE ASC

DROP TABLE IF EXISTS #GENRE_REGION
CREATE TABLE #Genre_region (
GENRE VARCHAR(255),
NA_SALES FLOAT,
EU_SALES FLOAT,
JP_SALES FLOAT,
OTHER_SALES FLOAT)

INSERT INTO #Genre_region (GENRE, NA_SALES,EU_SALES,JP_SALES,OTHER_SALES)
(
select Genre, sum(NA_SALES) NA_SALES, sum(EU_SALES) EU_SALES, sum(JP_SALES) JP_SALES, sum(OTHER_SALES) OTHER_SALES
from vgsales
GROUP BY Genre
)

select genre, round((NA_SALES+eu_sales+jp_sales+other_sales),2) as Total_Sales
from #genre_region
order by 2 desc

--We learn that the most profitable genre of game in the world is the action genre --

select genre, name
from vgsales
where genre = 'action'
order by global_sales desc

-- Of which, the most profitable game of that genre is GTA V -- 

select genre, round(NA_SALES,2) as Total_Sales
from #genre_region
order by 2 desc

--2a. Which genre is most profitable per region? --

-- In NORTH AMERICA, nor surprisingly, it's the action genre that's the most profitable --

select genre, round(sum(NA_SALES),2)
from VGSALES
group by genre
order by 2 DESC


select genre, name, sum(NA_SALES)
FROM vgsales
where genre = 'action'
group by genre, name
order by 3 desc
-- And the most sold game of action in the NORTH AMERICAN region is also GTA V --

select genre, round(EU_SALES,2) as Total_Sales
from #genre_region
order by 2 desc

-- In the European region, the most profitable genre is also Action --

select genre, name, eu_SALES
from VGSALES
where genre = 'action' 
order by 3 DESC

-- Of which, the most profitable game of action is, once again, GTA V --

select genre, name, Global_Sales
from VGSALES 
order by 3 DESC

-- Which is weird, considering that GTA V is only the 17th ranked game in the list of most sold games overall --

select genre, round(jp_SALES,2) as Total_Sales
from #genre_region
order by 2 desc

-- Non-Surprisingly, in the Japanese region, the action genre takes a distant second place in favor of RPGs, which  occupies the number 1 spot --

select genre, name, jp_SALES
from VGSALES
where genre = 'Role-Playing' 
order by 3 DESC

-- The most profitable game of the RPG genre in Japan is Pokemon Red/Pokemon Blue --

select genre, round(other_SALES,2) as Total_Sales
from #genre_region
order by 2 desc

-- As for the rest of the world, the most profitable genre is Action once again --

select genre, name, global_SALES
from VGSALES
where genre = 'Action' 
order by 3 DESC

-- Once again, GTA V takes the cake as the most popular of the Action genre --

--ANSWER: Of the world, the most popular genre is ACTION.
	-- For the North American region, European region and the rest of the world, the most popular genre is Action --
		-- Japan is the only region with another most popular genre, it being the RPG genre --

--3. What are the top 10 Publishers, in terms of sales? --

select top 10 Publisher, round(sum(NA_Sales+JP_Sales+EU_Sales+Other_Sales),2) as Total_Sales
from vgsales
group by Publisher
order by 2 desc

-- ANSWER: The most profitable companies are, in order, Nintendo, EA, Activision, Sony, Ubisoft, Take-Two, THQ, Konami, Sega and Bandai --

-- 4. What are the most profitable years? --

with CTE_DECADES AS (
SELECT *,
CASE
	WHEN YEAR < 1990 THEN '80s'
	when YEAR < 2000 THEN '90s'
	WHEN YEAR <=2009 THEN '00s'
	ELSE '10s'
end as Decades
FROM VGSALES
)
SELECT DECADES, ROUND(SUM(NA_sALES+ JP_Sales+ EU_Sales+ Other_Sales),0) AS TOTAL_SALES
FROM CTE_DECADES
GROUP BY DECADES
ORDER BY 2 DESC

--ANSWER: The most profitable decade were the 2000s -- 

-- Now let's save this analysis in a new dataset -- 

-- 1. --
CREATE VIEW MOST_SOLD_CONSOLE AS 
WITH CTE_SALES_TOTAL
AS 
(
select PLATFORM, (EU_SALES+JP_SALES+NA_SALES+OTHER_SALES) AS MILLION_TOTAL_SALES
from vgsales
)
SELECT DISTINCT(PLATFORM), SUM(MILLION_TOTAL_SALES) OVER (PARTITION BY PLATFORM) AS MILLION_SALES_PER_PLATFORM
FROM CTE_SALES_TOTAL
GROUP BY (PLATFORM), MILLION_TOTAL_SALES

--1a-- 

-- JAPAN --
CREATE VIEW JP_SALES_MOST AS
select DISTINCT(platform),SUM(JP_SALES) OVER (PARTITION BY PLATFORM) AS SALES_JP_PER_PLATFORM_PER_MILLION
from vgsales
GROUP BY JP_SALES, PLATFORM

-- NORTH AMERICA -- 

CREATE VIEW NA_SALES_MOST AS
select DISTINCT(platform),SUM(NA_SALES) OVER (PARTITION BY PLATFORM) AS SALES_NA_PER_PLATFORM_PER_MILLION
from vgsales
GROUP BY NA_SALES, PLATFORM

-- EUROPE --
CREATE VIEW EU_SALES_MOST AS
select DISTINCT(platform),SUM(EU_SALES) OVER (PARTITION BY PLATFORM) AS SALES_EU_PER_PLATFORM_PER_MILLION
from vgsales
GROUP BY EU_SALES, PLATFORM

--REST OF THE WORLD --
CREATE VIEW REST_SALES_MOST AS 
select DISTINCT(platform),SUM(OTHER_SALES) OVER (PARTITION BY PLATFORM) AS SALES_OTHER_PER_PLATFORM_PER_MILLION
from vgsales
GROUP BY OTHER_SALES, PLATFORM

--2-- 

CREATE VIEW MOST_REGION AS 
select *
from genre_region

CREATE TABLE GENRE_REGION 
(GENRE VARCHAR(255),
TOTAL_SALES FLOAT
)

INSERT INTO Genre_region 
select genre, round((NA_SALES+eu_sales+jp_sales+other_sales),2) as Total_Sales
from #genre_region


--3-- 
CREATE VIEW TOP_10_PUBLISHER AS
select top 10 Publisher, round(sum(NA_Sales+JP_Sales+EU_Sales+Other_Sales),2) as Total_Sales
from vgsales
group by Publisher

--4--
CREATE VIEW DECADES_PROFITABLE AS
with CTE_DECADES AS (
SELECT *,
CASE
	WHEN YEAR < 1990 THEN '80s'
	when YEAR < 2000 THEN '90s'
	WHEN YEAR <=2009 THEN '00s'
	ELSE '10s'
end as Decades
FROM VGSALES
)
SELECT DECADES, ROUND(SUM(NA_sALES+ JP_Sales+ EU_Sales+ Other_Sales),0) AS TOTAL_SALES
FROM CTE_DECADES
GROUP BY DECADES

--END OF ANALYSIS --