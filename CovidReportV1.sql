SELECT TOP (1000) [iso_code]
      ,[continent]
      ,[location]
      ,[date]
      ,[population]
      ,[total_cases]
      ,[new_cases]
      ,[new_cases_smoothed]
      ,[total_deaths]
      ,[new_deaths]
      ,[new_deaths_smoothed]
      ,[total_cases_per_million]
      ,[new_cases_per_million]
      ,[new_cases_smoothed_per_million]
      ,[total_deaths_per_million]
      ,[new_deaths_per_million]
      ,[new_deaths_smoothed_per_million]
      ,[reproduction_rate]
      ,[icu_patients]
      ,[icu_patients_per_million]
      ,[hosp_patients]
      ,[hosp_patients_per_million]
      ,[weekly_icu_admissions]
      ,[weekly_icu_admissions_per_million]
      ,[weekly_hosp_admissions]
      ,[weekly_hosp_admissions_per_million]
  FROM [PortfolioProject].[dbo].[Covid_Deaths$]


  -- Select data we will be using

  SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM PortfolioProject..Covid_Deaths$
  ORDER BY 1, 2;

  -- Looking at Total cases vs Total Deaths
  -- Also looks at the likelihood of dying if one contracts covid in your country (death percentage)

  SELECT location, date, total_cases, total_deaths,
  (CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS DeathPercentage
  FROM PortfolioProject..Covid_Deaths$
  --WHERE Location = 'Nigeria'
  ORDER BY 1, 2;

  -- Looking at the total cases vs Population
  --shows what percentage of the population has covid

  SELECT Location, date, total_cases, population,
  (CONVERT(float,total_cases)/NULLIF(CONVERT(float,Population),0))*100 AS PercentageCases
  FROM PortfolioProject..Covid_Deaths$
  ORDER BY 1, 2;


-- Look at the countries with the highest infection rate compared to population
--THIS GIVES WRONG PERCENTAGE RESULTS. Got it right. I just needed to add the CONVERT function to the 'Total_Cases' column on the select
SELECT Location, population, MAX(CONVERT(float, total_cases)) AS HighestInfectionCount,
  MAX(CONVERT(float,total_cases)/NULLIF(CONVERT(float,Population),0))*100 AS PercetagePopulationInfected
  FROM PortfolioProject..Covid_Deaths$
  GROUP BY population, Location
  ORDER BY PercetagePopulationInfected DESC;


-- Shows the countries with the highest death count per population
/*THere is an issue with the date where it shows some locations as continents
because there is an issue with the data where the continent column of some countries is null
and therefore it shows the location to be null. The second query therefore we will be adding
the expression; "where continent is not null" to filter out wrong data*/


SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
  FROM PortfolioProject..Covid_Deaths$
  GROUP BY Location
  ORDER BY TotalDeathCount DESC;

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..Covid_Deaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Breaking it down by continent

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..Covid_Deaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--GLOBAL NUMBERS
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths,
	SUM(CAST(new_deaths AS int))/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM PortfolioProject..Covid_Deaths$
WHERE continent IS NOT NULL
ORDER BY 1,2;

--LOOKING AT TOTAL POPULATION VS VACCINATIONS
--WHAT ARE THE TOTAL PEOPLE PER LOCATION THAT HAVE BEEN VACCINATED
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingVaccinations-- This OVER argument sums successive rows
FROM PortfolioProject..Covid_Deaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
 ON dea.location = vac.location
 AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 ORDER BY 2,3;

 /*people vac'd in the population. We need to use a Common Table Expression cos we cannot 
 use the "RollingVaccinations" reference column to 
 calculate this, so we need to wrap it in a CTE.
  CTEs often act as a bridge to transform the data in source tables to the format expected by the query.*/
 -- Remember you need to add every column from the source query


WITH  PopulationVsVaccinations (Continent, Location, Date, Population, new_vaccinations, RollingVaccinations) 
 AS
 (
 SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingVaccinations-- This OVER argument sums successive rows
FROM PortfolioProject..Covid_Deaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
 ON dea.location = vac.location
 AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 --We took out the ORDER BY clause cos it is not valid for views
 )
 SELECT *, (RollingVaccinations/Population)*100  AS PercentageVaccs  /*We now run the CTE Above with this select
 statement to calculate the percentage vacs vs population*/
 FROM PopulationVsVaccinations


 --CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATIONS
 CREATE VIEW RollingVaccinations  AS -- I used this as opposed to Percentage Vacinations on the course cos this query calculates rolling 
 SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingVaccinations-- This OVER argument sums successive rows
FROM PortfolioProject..Covid_Deaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
 ON dea.location = vac.location
 AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 --ORDER BY 2,3;

 SELECT * 
 FROM RollingVaccinations;
