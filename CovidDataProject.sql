Select * From
Project_CovidData..CovidDeaths
Order by 3,4

--Select * From
--Project_CovidData..CovidVaccinations
--Order by 3,4

--Selecting Data

Select location, date, total_cases, new_cases, total_deaths, population
From Project_CovidData..CovidDeaths
Order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of people dying pf covid in a country
Select location, date, total_cases, total_deaths,
 ISNULL((CONVERT(FLOAT,total_deaths)/(CONVERT(FLOAT,total_cases)))*100,0) as DeathPercentage
From Project_CovidData..CovidDeaths
WHERE location = 'India'
Order by 1,2

-- Looking at Total Cases vs Population
-- Shows the percentage of population that got Covid
Select location, date, population, total_cases, 
 (CONVERT(FLOAT,total_cases)/population)*100 as CovidPatientPercentage
From Project_CovidData..CovidDeaths
--WHERE location = 'India'
Order by 1,2

-- Looking at countries with highest infection compared to population

Select location, population, MAX(total_cases) AS HighestInfectionCount, 
 MAX((CONVERT(FLOAT,total_cases)/population))*100 as HighestInfectionCountPercentage
From Project_CovidData..CovidDeaths
--WHERE location = 'India'
GROUP BY location,population
Order by HighestInfectionCountPercentage desc

-- Showing Countries with highest death count

Select location, population, MAX(cast(total_deaths as int)) AS TotalDeathCount
From Project_CovidData..CovidDeaths
where continent IS NOT NULL
GROUP BY location, population
Order by TotalDeathCount desc

-- Showing Continents with highest death count per population

Select continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
From Project_CovidData..CovidDeaths
where continent IS not NULL
GROUP BY continent
Order by TotalDeathCount desc

-- Global numbers

Select date, SUM(new_cases) AS TotalCases,SUM(new_deaths) AS TotalDeaths,ISNULL((SUM(new_deaths)/NULLIF(SUM(new_cases),0) )*100,0) as DeathPercentage
From Project_CovidData..CovidDeaths
--WHERE location = 'India'
WHERE continent IS NOT NULL
GROUP BY date
Order by 1,2

Select SUM(new_cases) AS TotalCases,SUM(new_deaths) AS TotalDeaths,ISNULL((SUM(new_deaths)/NULLIF(SUM(new_cases),0) )*100,0) as DeathPercentage
From Project_CovidData..CovidDeaths
--WHERE location = 'India'
WHERE continent IS NOT NULL
--GROUP BY date
Order by 1,2

--Looking at Total population vs Vaccinations

Select D.continent, D.location, D.date, D.population,V.new_vaccinations 
 ,SUM(CONVERT(FLOAT,V.new_vaccinations)) OVER (Partition by  D.location ORDER BY D.location, D.date)
 AS RollingPeopleVaccinated  
From Project_CovidData..CovidDeaths D
JOIN
	Project_CovidData..CovidVaccinations V
	ON D.location =V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL
Order by 2,3

--Use CTE
WITH PopvsVac(Contient, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
Select D.continent, D.location, D.date, D.population,V.new_vaccinations 
 ,SUM(CONVERT(FLOAT,V.new_vaccinations)) OVER (Partition by  D.location ORDER BY D.location, D.date)
 AS RollingPeopleVaccinated  
From Project_CovidData..CovidDeaths D
JOIN
	Project_CovidData..CovidVaccinations V
	ON D.location =V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL
--Order by 2,3
)
SELECT *,(RollingPeopleVaccinated/Population)*100
FROM PopvsVac


--Temp Table

--DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

Select D.continent, D.location, D.date, D.population,V.new_vaccinations 
 ,SUM(CONVERT(FLOAT,V.new_vaccinations)) OVER (Partition by  D.location ORDER BY D.location, D.date)
 AS RollingPeopleVaccinated  
From Project_CovidData..CovidDeaths D
JOIN
	Project_CovidData..CovidVaccinations V
	ON D.location =V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL
--Order by 2,3

SELECT *,(RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating View to store data for later Visualizations

CREATE VIEW PercentPopulationVaccinated AS
Select D.continent, D.location, D.date, D.population,V.new_vaccinations 
 ,SUM(CONVERT(FLOAT, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS RollingPeopleVaccinated
From Project_CovidData..CovidDeaths D
JOIN
	Project_CovidData..CovidVaccinations V
	ON D.location =V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL
--Order by 2,3
GO

SELECT * FROM PercentPopulationVaccinated
/*
QUERIES USED FOR TABLEAU PROJECT 
*/

--1 : Total Cases, Total Deaths
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Project_CovidData..CovidDeaths 
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, ISNULL(SUM(cast(new_deaths as int))/NULLIF(SUM(New_Cases),0)*100,0) as DeathPercentage
--From Project_CovidData..CovidDeaths																		
--Where location like '%states%'
--where location = 'World'
--Group By date
--order by 1,2

-- 2 : Total Cases Per Continent 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From Project_CovidData..CovidDeaths 
--Where location like '%states%'
Where continent is null 
and location not in ('High income','Upper middle income','Lower middle income','Low income','World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3 : Highest Infection Per Location

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Project_CovidData..CovidDeaths 
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4 : Highest Infection Per Location And Date


Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Project_CovidData..CovidDeaths 
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected DESC 



-- 

Select dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project_CovidData..CovidDeaths dea
Join Project_CovidData..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.date, dea.population
order by 1,2,3




-- 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Project_CovidData..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From Project_CovidData..CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From Project_CovidData..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc



-- 

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Project_CovidData..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc



-- 5.

--Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
--From Project_CovidData..CovidDeaths
----Where location like '%states%'
--where continent is not null 
--order by 1,2

-- took the above query and added population
Select Location, date, population, total_cases, total_deaths
From Project_CovidData..CovidDeaths
--Where location like '%states%'
where continent is not null 
order by 1,2


-- 6. 


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project_CovidData..CovidDeaths dea
Join Project_CovidData..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac


-- 7. 

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Project_CovidData..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc


