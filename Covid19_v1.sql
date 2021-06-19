SELECT * FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 3, 4

SELECT * FROM PortfolioProject.dbo.CovidVaccinations$
order by 3, 4

--Select Data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 1, 2

--Total cases vs total deaths
--Percentage deaths if contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location like '%states%'
ORDER BY 1, 2

--Total cases vs population
--Percentage of population got covid
SELECT Location, date, total_cases, population, (total_cases/population) * 100 AS CasesPercentage
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
ORDER BY 1, 2

--Countries with highest infection rate compared to population
SELECT Location, MAX(total_cases) AS HighestInfectionCount, population, 
MAX((total_cases/population)) * 100 AS PercentagePopulationInfected
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

--Countries with the highest death count per population
--total_deaths is nvarchar so needed to cast as an int
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--By location
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC


--by continent
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--global cases by date
SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths,
SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

--total global cases
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths,
SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 1, 2

--join death and vaccination tables
SELECT dea.continent, dea.location, dea.date, dea.population, 
vac.new_vaccinations AS DailyVacs,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY 
dea.location, dea.date) AS RollingCount
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN
PortfolioProject.dbo.CovidVaccinations$ vac
ON
dea.location = vac.location
AND
dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

--CTE or Common Table Expression population vs vaccination
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY 
dea.location, dea.date) AS RollingCount
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN
PortfolioProject.dbo.CovidVaccinations$ vac
ON
dea.location = vac.location
AND
dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3
)
--using the CTE
SELECT *, (RollingCount/population) * 100 AS PercentVaccinated
FROM PopvsVac


--temp table
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCount numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY 
dea.location, dea.date) AS RollingCount
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN
PortfolioProject.dbo.CovidVaccinations$ vac
ON
dea.location = vac.location
AND
dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

--using the CTE
SELECT *, (RollingCount/population) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated

--view to store data
GO
CREATE VIEW PercentPopVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY 
dea.location, dea.date) AS RollingCount
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN
PortfolioProject.dbo.CovidVaccinations$ vac
ON
dea.location = vac.location
AND
dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopVaccinated

