
-- In this project, we are going to clean a very messy dataset --
SELECT * 
FROM messy_IMDB_dataset$

-- The first step is to create a temp table that will be usable

DROP TABLE IF EXISTS #Imdb
CREATE TABLE #IMDB
(
ID nvarchar(255),
Title nvarchar(255),
Release_Year nvarchar(255),
Genre varchar(255),
Duration int,
)

-- Then proceed to load into the new dataset all the data from the previous table, note how we created now usable column header names

INSERT INTO #IMDB
SELECT *
FROM messy_IMDB_dataset$

--Now, let's take a look at the new table --

SELECT *
FROM #IMDB

-- Let's add a new column which will be NULLs, we will fix this

ALTER TABLE #IMDB
ADD COUNTRY VARCHAR(255)

--From looking at this table, the main problem seem to be a delimiter problem --
--Let's try separating some of these columns -- 

select PARSENAME(REPLACE(ID,';','.'),4)
FROM #IMDB

ALTER TABLE #imdb
ADD ID_FIXED varchar(255)

UPDATE #IMDB
SET ID_FIXED =  PARSENAME(REPLACE(ID,';','.'),4)


select PARSENAME(REPLACE(ID,';','.'),3)
FROM #IMDB

ALTER TABLE #imdb
ADD Title_FIXED varchar(255)

UPDATE #IMDB
SET TITLE_FIXED =  PARSENAME(REPLACE(ID,';','.'),3)

ALTER TABLE #IMDB
ADD RELEASE_YEAR_FIXED VARCHAR (255)

UPDATE #IMDB
SET RELEASE_YEAR_FIXED =  PARSENAME(REPLACE(ID,';','.'),2)

UPDATE #IMDB
SET RELEASE_YEAR_FIXED =  LEFT(RELEASE_YEAR_FIXED,4)


ALTER TABLE #IMDB
ADD GENRE_FIXED VARCHAR (255)

UPDATE #IMDB
SET GENRE_FIXED =  PARSENAME(REPLACE(ID,';','.'),1)

-- Let's drop these tables as the data from the dataset is too jumbled and unusable --
ALTER TABLE #IMDB
DROP COLUMN ID, TITLE, RELEASE_YEAR, GENRE, DURATION, COUNTRY

-- Now, even with the dataset fixed, we still have some discrepancies to be fixed, like these --
SELECT TRIM(RELEASE_YEAR_FIXED), TITLE_FIXED 
FROM #IMDB
WHERE Release_Year_FIXED LIKE '% %'

--Notice how some years were turned into random numbers --
-- In order to fix this, we need to manually search for these Titles' release year --

select title_fixed, release_year_fixed
from #imdb
where Release_Year_fixed like '% %'

UPDATE #IMDB
set Release_Year_fixed = 2003
WHERE TITLE_FIXED  like '%Return of the King'

UPDATE #IMDB
set Release_Year_fixed = 1972
WHERE TITLE_FIXED  like '%Godfather'

UPDATE #IMDB
set Release_Year_fixed = 2008
WHERE TITLE_FIXED  = 'The Dark Knight'

select title_fixed, release_year_fixed 
from #IMDB
where Release_Year_fixed like '%-%'

UPDATE #IMDB
set Release_Year_fixed = 1942
WHERE TITLE_FIXED  = 'Casablanca'

UPDATE #IMDB
set Release_Year_fixed = 2002
WHERE TITLE_FIXED  like '%Two Towers'

UPDATE #IMDB
set Release_Year_fixed = 1950
WHERE Release_Year_fixed is null

-- Now we can see some titles are named wrong. This has to do with the titling of the movie, which usually includes a character not found in the English keyboard (such as é, è, ã, â and the like) --
	-- Unfortunately, these titles don't follow a logical sequence --
select * 
from #imdb
order by Title_Fixed asc

SELECT *
FROM #IMDB
where Title_Fixed LIKE '%Ã%' 

UPDATE #IMDB
SET TITLE_FIXED = 'Leon'
WHERE TITLE_FIXED = 'LÃ©on'

UPDATE #IMDB
SET TITLE_FIXED = 'Le fabuleux destin d''Amélie Poulain'
WHERE TITLE_FIXED like '%Le fabuleux%'

UPDATE #IMDB
SET TITLE_FIXED = 'WALLE·E'
WHERE TITLE_FIXED like 'WALLÂ·E'

UPDATE #IMDB
SET TITLE_FIXED = 'La vita è bella'
WHERE TITLE_FIXED like 'La vita B9 bella'



-- Finally, let's drop the NULL rows --

DELETE FROM #IMDB
WHERE ID_FIXED IS NULL

-- This is the final result --

select *
from #IMDB

-- Compare it to the original --

SELECT * 
FROM messy_IMDB_dataset$


-- END OF PROJECT --





