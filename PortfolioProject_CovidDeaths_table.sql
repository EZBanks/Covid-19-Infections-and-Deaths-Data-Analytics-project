-- DATA CLEANING


-- Splitting row values containing "OWID_" into iso_code column
Select iso_code, location,
REPLACE(iso_code,'OWID_', '')
from [Portfolio Project]..CovidDeaths
Group by iso_code, location

Alter Table [Portfolio Project]..CovidDeaths
Add IsoCodeEdited Nvarchar(255)

Update [Portfolio Project]..CovidDeaths 
Set IsoCodeEdited = REPLACE(iso_code, 'OWID_', '')


Select iso_code, location,
REPLACE(iso_code,'OWID_', '')
from [Portfolio Project]..CovidVaccinations
Group by iso_code, location

Alter Table [Portfolio Project]..CovidVaccinations
Add IsoCodeEdited Nvarchar(255)

Update [Portfolio Project]..CovidVaccinations 
Set IsoCodeEdited = REPLACE(iso_code, 'OWID_', '')

-- Deleting Unused Columns

Alter Table [Portfolio Project]..CovidDeaths
DROP COLUMN iso_code

Alter Table [Portfolio Project]..CovidVaccinations
DROP COLUMN iso_code

-- Checking new columns

select*
from [Portfolio Project]..CovidDeaths

select*
from [Portfolio Project]..CovidVaccinations


-- DATA EXPLORATION AND ANALYSIS

-- showing likelihood of dying if an individual contracts covid in Brazil

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deaths_percentage
from [Portfolio Project]..CovidDeaths
where location = 'Brazil'
order by deaths_percentage desc


--Showing what percentage of population got Covid in Brazil

select location, date, total_cases, population, (total_cases/population)*100 as percent_population_infected
from [Portfolio Project]..CovidDeaths
where location = 'Brazil'
order by date desc


--Looking at countries with highest infection rate compared to population

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as percent_population_infected
from [Portfolio Project]..CovidDeaths
group by location, population
order by percent_population_infected DESC

--Showing countries with highest death count per population

select location, MAX(cast(total_deaths as int)) as total_death_count
from [Portfolio Project]..CovidDeaths
where continent is not null
group by location
order by total_death_count DESC

--Showing total death count by continent

select continent, SUM(cast(new_deaths as int)) as total_death_count
from [Portfolio Project]..CovidDeaths
where continent is not null
group by continent
order by total_death_count DESC

--Global numbers

select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int)) / SUM(new_cases)*100 as death_percentage
from [Portfolio Project]..CovidDeaths
where continent is not null



-- Total people vaccinated in the world by continent, country and date using Common Table Expressions (CTE)

With PopvsVac (Continent, date, Location, Population, New_Vaccinations, TotalVaccinated)
as
(
select dea.continent, dea.date, dea.location, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location) as TotalVaccinated
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
	 On dea.location = vac.location
	 and dea.date = vac.date
where dea.continent is not null
)
select*, (TotalVaccinated/population)*100 as PercentPopulationVaccinated
from PopvsVac

select continent, location, date, sum((TotalVaccinations/population))*100 as PercentPopulationVaccinated
from [Portfolio Project]..CovidVaccinations
where location = 'United States'
group by continent, location, date, PercentPopulationVaccinated


--Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.date, dea.location, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location) as TotalVaccinated
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccinations vac
	 On dea.location = vac.location
	 and dea.date = vac.date
where dea.continent is not null
