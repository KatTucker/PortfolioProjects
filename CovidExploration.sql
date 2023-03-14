SELECT *
FROM CovidPortfolioProject..CovidDeaths
ORDER BY 3, 4

SELECT *
FROM CovidPortfolioProject..CovidVaccinations
ORDER BY 3, 4

--Select Data that I am going to be using

SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
ORDER BY 1, 2

--ALTER TABLE CovidDeaths
--ALTER COLUMN total_deaths float(2);

-- Looking at Total Cases vs Population

SELECT Location, Date, Population, total_cases, (total_cases/Population)*100 AS PopulationPercentage
FROM CovidPortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
ORDER BY 1, 2

-- Looking at countries with highest infection rate compared to population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths
-- WHERE Location LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Showing countries with the highest death count per population

SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- BREAK DOWN BY CONTINENT

-- Showing continents with highest death count

SELECT Continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
HAVING SUM(new_cases) <> 0
ORDER BY 1, 2

SELECT Date, SUM(new_cases) AS newCases
FROM CovidPortfolioProject..CovidDeaths
GROUP BY Date
ORDER BY 1, 2



-- Looking at total population vs vaccinations

SELECT dea.Continent, dea.Location, dea.Date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingVaxCount, 
	(RollingVaxCount/Population)*100
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON dea.Location = vac.Location
	AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL
ORDER BY 2, 3

-- Use CTE

WITH PopVsVax (Continent, Location, Date, Population, new_vaccinations, RollingVaxCount)
AS (
	SELECT dea.Continent, dea.Location, dea.Date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingVaxCount
	FROM CovidPortfolioProject..CovidDeaths AS dea
	JOIN CovidPortfolioProject..CovidVaccinations AS vac
		ON dea.Location = vac.Location
		AND dea.Date = vac.Date
	WHERE dea.Continent IS NOT NULL
	--ORDER BY 2, 3
)
SELECT *, (RollingVaxCount/Population)*100 AS RollingPercentVaccinated
FROM PopVsVax
ORDER BY 2, 3


-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopVaxed
CREATE TABLE #PercentPopVaxed
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime, 
Population numeric, 
New_Vaccinations numeric,
RollingVaxCount numeric
)

INSERT INTO #PercentPopVaxed
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vax.new_vaccinations,
	SUM(CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingVaxCount
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccinations AS vax
	ON dea.Location = vax.Location
	AND dea.Date = vax.Date
WHERE dea.Continent IS NOT NULL

SELECT *, (RollingVaxCount/Population)*100 AS RollingPercentVaccinated
FROM #PercentPopVaxed
ORDER BY 2, 3


-- Creating view to store data for later vixualizations

CREATE VIEW PercentPopVaxed AS
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vax.new_vaccinations,
	SUM(CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS RollingVaxCount
FROM CovidPortfolioProject..CovidDeaths AS dea
JOIN CovidPortfolioProject..CovidVaccinations AS vax
	ON dea.Location = vax.Location
	AND dea.Date = vax.Date
WHERE dea.Continent IS NOT NULL


SELECT *
FROM PercentPopVaxed
ORDER BY 2, 3