/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's (Common Table Expressions), Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--Selecting top 100 rows from both the tables CovidDeaths and CovidVaccinations

SELECT TOP 100* 
FROM CovidDeaths

SELECT TOP 100* 
FROM CovidVaccinations


-- Selecting the Data with important columns to have a look into it

SELECT continent, location, date, total_cases, new_cases, total_deaths, population 
FROM CovidDeaths
ORDER BY location, date

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if one has contracted COVID in India ordered by recent date

SELECT continent, location, date, total_cases, total_deaths, new_deaths, (total_deaths/total_cases) * 100 AS 'DeathPercentage'
FROM CovidDeaths
WHERE location like '%India%'
ORDER BY date desc

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in India ordered by recent date

SELECT continent, location, date, population, total_cases, (total_cases/population) * 100 AS 'InfectedPercentage'
FROM CovidDeaths
WHERE location like '%India%'
ORDER BY date desc

-- Countries with Highest Infection Percentage compared to Population

SELECT location, population, MAX(total_cases) AS 'TotalInfectedPopulation', MAX(total_cases/population) * 100 AS 'InfectedPopulationPercentage' 
FROM CovidDeaths
GROUP BY location,population
ORDER BY InfectedPopulationPercentage DESC


-- Countries with Highest Death Count

SELECT location, MAX(CAST(total_deaths AS int)) AS 'TotalDeathCount'
FROM CovidDeaths
WHERE continent IS NOT NULL    --To check the countries
GROUP BY location
ORDER BY TotalDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS int)) AS 'TotalDeathCount'
FROM CovidDeaths
WHERE continent IS NULL   
GROUP BY location
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

Select SUM(new_cases) as 'Total Infected People', SUM(cast(new_deaths as int)) as 'Total Death', SUM(cast(new_deaths as int))/SUM(New_Cases) * 100 AS 'Death Percentage'
From CovidDeaths
where continent is not null 


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(INT, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS 'RollingPeopleVaccinated'
FROM CovidDeaths CD
INNER JOIN CovidVaccinations CV
	ON CD.location= CV.location
	AND CD.date=CV.date
WHERE CD.continent IS NOT NULL
ORDER BY CD.location, CD.date


-- Using CTE (Common Table Expressions) to calculate Vaccination Percentage on Partition By in previous query


WITH VACCINE (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(bigint, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS 'RollingPeopleVaccinated'
FROM CovidDeaths CD
INNER JOIN CovidVaccinations CV
	ON CD.location= CV.location
	AND CD.date=CV.date
WHERE CD.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population) * 100 'RollingVaccinationPercentage'
FROM VACCINE


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PopulationVaccinatedPercentage
CREATE TABLE #PopulationVaccinatedPercentage
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PopulationVaccinatedPercentage
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(bigint, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS 'RollingPeopleVaccinated'
FROM CovidDeaths CD
JOIN CovidVaccinations CV
	ON CD.location= CV.location
	AND CD.date=CV.date
WHERE CD.continent IS NOT NULL

Select *, (RollingPeopleVaccinated/Population) * 100 AS 'RollingVaccinationPercentage'
From #PopulationVaccinatedPercentage 


-- Creating View to store data for later visualizations

CREATE VIEW V_PopulationVaccinatedPercentage 
AS 
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(bigint, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS 'RollingPeopleVaccinated'
FROM CovidDeaths CD
JOIN CovidVaccinations CV
	ON CD.location= CV.location
	AND CD.date=CV.date
WHERE CD.continent IS NOT NULL

SELECT * FROM V_PopulationVaccinatedPercentage

