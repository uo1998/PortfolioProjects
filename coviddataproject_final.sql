
-- Skills used in this project: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Creating Subqueries, Converting Data Types

SELECT *
FROM covidcasestudy.coviddeaths_casestudy
WHERE continent is NOT NULL
Order By 3, 4

SELECT *
FROM covidcasestudy.covidvaccinations_casestudy
Order By 3, 4

-- Select Data we are going to be using

SELECT Location, date, total_cases, new_cases, total_death, population
FROM covidcasestudy.coviddeaths_casestudy
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM covidcasestudy.coviddeaths_casestudy
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at total cases vs population
-- Shows what percentage of total population got Covid

SELECT Location, date, Population, total_cases,(total_cases/Population)*100 as CasePercentage
FROM covidcasestudy.coviddeaths_casestudy
WHERE location like '%states%'
ORDER BY total_cases ASC

SELECT Location, date, Population, total_cases,(total_cases/Population)*100 as CasePercentage
FROM covidcasestudy.coviddeaths_casestudy
-- WHERE location like '%states%'
ORDER BY total_cases ASC

-- Looking at Countries with highest Infection Rate compared to population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/Population))*100 
as PercentOfPopulationInfected
FROM covidcasestudy.coviddeaths_casestudy
GROUP BY Location, Population
ORDER BY PercentOfPopulationInfected DESC

-- Showing Countries with highest death count per population

SELECT Location, Population, MAX(total_deaths) AS TotalDeathCount
FROM covidcasestudy.coviddeaths_casestudy
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY TotalDeathCount DESC;

-- LETS BREAK THINGS DOWN BY CONTINENT

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM covidcasestudy.coviddeaths_casestudy
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY CAST(TotalDeathCount AS SIGNED INTEGER) DESC;

-- renaming the name of my schema for organizational purposes 

-- Step 1: Creating the new schema
CREATE SCHEMA portfolio_project;

-- Step 2: Copying tables and data to the new schema
USE covidcasestudy; 

-- Copying "coviddeaths_casestudy" table and the data
CREATE TABLE portfolio_project.coviddeaths_casestudy LIKE covidcasestudy.coviddeaths_casestudy;
INSERT INTO portfolio_project.coviddeaths_casestudy SELECT * FROM covidcasestudy.coviddeaths_casestudy;

-- Copying "covidvaccinations_casestudy" table and the data
CREATE TABLE portfolio_project.covidvaccinations_casestudy LIKE covidcasestudy.covidvaccinations_casestudy;
INSERT INTO portfolio_project.covidvaccinations_casestudy SELECT * FROM covidcasestudy.covidvaccinations_casestudy;

-- Step 3: Dropping the old schema
DROP SCHEMA covidcasestudy;

-- showing continents with highest deathcounts per population

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM covidcasestudy.coviddeaths_casestudy
WHERE continent IS NOT NULL
GROUP BY continent
-- GROUP BY DATE
ORDER BY CAST(TotalDeathCount AS SIGNED INTEGER) DESC;

-- GLOBAL NUMBERS

SELECT date, SUM(total_cases) AS globalcases, SUM(CAST(total_deaths AS SIGNED)) AS globaldeaths, SUM(New_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM covidcasestudy.coviddeaths_casestudy
GROUP BY date
ORDER BY 1, 2;

-- TOTAL CASES without dates

SELECT SUM(total_cases) AS globalcases, SUM(CAST(total_deaths AS SIGNED)) AS globaldeaths, SUM(New_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM covidcasestudy.coviddeaths_casestudy
GROUP BY date
ORDER BY 1, 2;

-- Looking at total population vs vaccinations by using subqueries

SELECT
  continent,
  location,
  date,
  population,
  new_vaccinations,
  RollingPeopleVaccinated,
  CASE
    WHEN population <> 0 THEN (RollingPeopleVaccinated / population) * 100
    ELSE 0
  END AS VaccinationPercentage
FROM (
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM
    coviddeaths_casestudy dea
  JOIN
    covidvaccinations_casestudy vac ON dea.location = vac.location
    AND dea.date = vac.date
  WHERE
    dea.continent IS NOT NULL
) AS subquery
ORDER BY
  location, date;

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, RollingPeopleVaccinated) AS
(
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location) AS total_vaccinations
  FROM
    coviddeaths_casestudy dea
  JOIN
    covidvaccinations_casestudy vac ON dea.location = vac.location
    AND dea.date = vac.date
  WHERE
    dea.continent IS NOT NULL
)
SELECT
  *,
  (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM
  PopvsVac;
    
-- TEMP TABLE (final revision)

 -- Dropping the existing table
 DROP TABLE IF EXISTS PercentPopulationVaccinated;

 -- Creating a new table
CREATE TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population DECIMAL(18, 2),
    New_vaccinations DECIMAL(18, 2),
    RollingPeopleVaccinated DECIMAL(18, 2)
);

INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations AS New_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM
    coviddeaths_casestudy dea
    JOIN covidvaccinations_casestudy vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

-- order by 2,3


Select *, (RollingPeopleVaccinated/Population)*100
From  #PercentPopulationVaccinated

-- Creating View To store for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT date, SUM(total_cases) AS globalcases, SUM(total_deaths) AS globaldeaths, SUM(New_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM covidcasestudy.coviddeaths_casestudy
GROUP BY date
ORDER BY date;