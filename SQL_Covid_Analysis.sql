--IN ORDER TO START THIS PROJECT, LET'S SELECT THE DATA WE WANT TO USE--

SELECT *
FROM CovidDeaths AS CD
ORDER BY 1,2



-- Looking at the Total Cases vs Total Deaths -- 

SELECT LOCATION, left(DATE,11) total_cases, total_deaths, round((total_deaths/total_cases)*100,02) as Death_Percentage
FROM CovidDeaths AS CD
where location = 'Brazil'
ORDER BY Death_Percentage desc

	-- This shows the likelihood of dying from contracting COVID in Brazil in terms of percentages, during the years of 2020-2021 --
	-- This data shows the peak of deaths in percentages in relation to the amount of infected people. During its peak, COVID killed approx. 7% of all infected people --

-- Now, let's look at the total cases vs Population --

SELECT LOCATION, left(DATE,11), total_cases, population, round((total_cases/population)*100,04) as Infected_Percentage
FROM CovidDeaths AS CD
where location = 'Brazil'
ORDER BY Infected_Percentage desc

	--This analysis now shows us the percentage of the entire population of Brazil that contracted COVID. At its peak, COVID was contracted by approx. 7% of the entire population of Brazil. This is more than 14 million people sick.  --

-- Now, let's look at countries with the highest infection rate compared to its population

SELECT LOCATION, max(total_cases) as max_cases, population, max(round((total_cases/population)*100,2)) as Infected_Percentage
FROM CovidDeaths AS CD
group by location, population
ORDER BY Infected_Percentage desc

	
-- Now, let's show the continents with the highest death count -- 

SELECT continent,max(cast(total_deaths as int)) as max_deaths_count
FROM CovidDeaths AS CD
where continent is not null and location <> 'World' and location <> 'International'
group by continent
ORDER BY max_deaths_count desc


-- Global numbers --

select left(date,11) as Dates,sum(new_Cases) as Total_Cases,sum(cast(new_deaths as int)) as Total_Deaths, round(sum(cast(new_deaths as int))/sum(new_cases)*100,2) as Death_Percentages
from CovidDeaths 
where continent is not null
group by date
order by 1,2


-- looking at total population vs vaccinated people --

SELECT cd.continent, cd.location, (cd.date), cd.population, cv.new_vaccinations, sum(cv.new_vaccinations) over (partition by cd.location order by cd.location, cd.date ) as Rolling_People_Vaccinated
from CovidDeaths as cd
join CovidVaccinations as cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2,3

-- USING A CTE --

With PopvsVAC (Continent, location, date, population, Rolling_People_Vaccinated, new_vaccinations)
as (
SELECT cd.continent, cd.location, (cd.date), cd.population, cv.new_vaccinations, sum(cv.new_vaccinations) over (partition by cd.location order by cd.location, cd.date ) as Rolling_People_Vaccinated
from CovidDeaths as cd
join CovidVaccinations as cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
--order by 2,3
)
select *, round((new_vaccinations/population)*100,2) as percentage_of_people_vaccinated
from PopvsVAC
where location = 'Albania' and Rolling_People_Vaccinated is not null
order by 1,2

-- TEMP TABLE --

DROP TABLE IF EXISTS #Percent_Pop_Vaccine

CREATE TABLE #Percent_Pop_Vaccine
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_Vaccinations numeric,
Rolling_people_vaccinated int)

INSERT INTO #Percent_Pop_Vaccine
SELECT cd.continent, cd.location, (cd.date), cd.population, cv.new_vaccinations, sum(cv.new_vaccinations) over (partition by cd.location order by cd.location, cd.date ) as Rolling_People_Vaccinated
from CovidDeaths as cd
join CovidVaccinations as cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null

select *, round((Rolling_people_vaccinated/population)*100,2) as percentage_of_people_vaccinated
from #Percent_Pop_Vaccine
where location = 'Brazil' and Rolling_People_Vaccinated is not null
order by 1,2

-- CREATING VIEW TO STORE FOR VISUALIZATION -- 

CREATE VIEW PercentPopulationVaccinated as 
SELECT cd.continent, cd.location, (cd.date), cd.population, cv.new_vaccinations, sum(cv.new_vaccinations) over (partition by cd.location order by cd.location, cd.date ) as Rolling_People_Vaccinated
from CovidDeaths as cd
join CovidVaccinations as cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null



SELECT *
FROM PercentPopulationVaccinated