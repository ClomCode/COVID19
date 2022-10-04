-- COVID Data Exploration 

Select *
From COVID..CovidDeaths$
Where continent is not null 
order by location, date

Select *
From COVID..CovidVacs$
Where continent is not null and location like '%Kingdom%'
order by location, date

-- Selecting Data

Select location, date, total_cases, new_cases, total_deaths, population
From COVID..CovidDeaths$
Where continent is not null 
order by location, date

-- Total Cases vs Deaths
-- Shows the mortality rate in the UK

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as MortalityPercent
From COVID..CovidDeaths$
Where location like '%Kingdom%' and continent is not null 
order by location, date

-- Total Cases vs Population
-- Shows COVID infection percentage in the UK

Select location, date, population, total_cases,  (total_cases/population)*100 as PercentPopInfected
From COVID..CovidDeaths$
Where location like '%Kingdom%'
order by location, date

-- Countries with highest Infection Rate compared to Population

Select location, population, MAX(total_cases) as PeakInfectionCount,  Max((total_cases/population))*100 as PeakInfectionPercent
From COVID..CovidDeaths$
Group by location, population
order by PeakInfectionPercent desc

-- Current Infection Rates

Select Location, Population, date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From COVID..CovidDeaths$
Where location IN ('United States', 'United Kingdom', 'China', 'India', 'Canada', 'France', 'Germany', 'Spain',
'Australia', 'New Zealand', 'Japan', 'South Korea', 'Brazil')
Group by Location, Population, date
order by PercentPopulationInfected desc

-- Countries with highest mortality count

Select location, MAX(cast(Total_deaths as int)) as TotalMortalities
From COVID..CovidDeaths$
Where continent is not null
Group by location
order by TotalMortalities desc


-- Showing contintents with the highest death count

Select continent, SUM(cast(new_deaths as bigint)) as TotalMortalities
From COVID..CovidDeaths$
Where continent is not null 
Group by continent
order by TotalMortalities desc


-- Worldwide

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as MortalityPercent
From COVID..CovidDeaths$
where continent is not null


-- Total Population vs Vaccinations
-- Shows number of total Vaccine or Booster doses 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalDoses
From COVID..CovidDeaths$ dea
Join COVID..CovidVacs$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by location, date


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, TotalDoses, PopVaxxed, PopFullyVaxxed) as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalDoses,
vac.people_vaccinated, vac.people_fully_vaccinated
From COVID..CovidDeaths$ dea
Join COVID..CovidVacs$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (PopVaxxed/Population)*100 as PercentPopVaxxed, (PopFullyVaxxed/Population)*100 as PercentPopFullyVaxxed,
(TotalDoses/Population) as NumberOfDosesPerPerson
From PopvsVac
Where location like '%Kingdom%'
order by location, date


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #DosesPerPerson
Create Table #DosesPerPerson
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
TotalDoses numeric
)

Insert into #DosesPerPerson
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalDoses
From COVID..CovidDeaths$ dea
Join CovidVacs$ vac
	On dea.location = vac.location
	and dea.date = vac.date


Select *, (TotalDoses/Population) as DosesPerPerson
From #DosesPerPerson
Where location like '%Kingdom%'
order by location, date



-- Creating View for visualizations

DROP View if exists DosesPerPerson
Create View DosesPerPerson as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalDoses
From COVID..CovidDeaths$ dea
Join COVID..CovidVacs$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *
From DosesPerPerson