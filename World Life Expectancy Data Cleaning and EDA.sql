-- World Life Expectancy world_life_expectancyProject (Data Cleaning)

SELECT * 
FROM world_life_expectancy
;

-- Remove duplicate data

SELECT country,
year,
CONCAT(Country, year) 
FROM world_life_expectancy
;

-- Concatenated column should all be unique (One country, one year)

SELECT country,
year,
CONCAT(Country, year),
COUNT(CONCAT(Country, year))
FROM world_life_expectancy
GROUP BY country, year, CONCAT(country,year)
;

-- Filter the concatenated column with HAVING function

SELECT country,
year,
CONCAT(Country, year),
COUNT(CONCAT(Country, year))
FROM world_life_expectancy
GROUP BY country, year, CONCAT(country,year)
HAVING COUNT(CONCAT(Country, year)) > 1
;

-- Identify Row ID, remove duplicate

SELECT Row_ID, 
CONCAT(Country, year),
ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, year) ORDER BY CONCAT(Country, year)) as Row_Num
FROM world_life_expectancy
;

-- Use Subquery to identify row number, must use alias in subquery

SELECT*
FROM (
SELECT Row_ID, 
CONCAT(Country, year),
ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, year) ORDER BY CONCAT(Country, year)) as Row_Num
FROM world_life_expectancy
) AS Row_table
WHERE Row_num > 1
;

-- Delete row IDs, utilize subquery to specify individual rows (NOTE: Always create backup table before deleting any data)

DELETE FROM world_life_expectancy
WHERE 
	Row_ID IN (
		SELECT Row_ID
FROM (
SELECT Row_ID, 
CONCAT(Country, year),
ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, year) ORDER BY CONCAT(Country, year)) as Row_Num
FROM world_life_expectancy
) AS Row_table
WHERE Row_num > 1
)
;

-- Double check rows were deleted by running subquery

SELECT *
FROM (
SELECT Row_ID, 
CONCAT(Country, year),
ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, year) ORDER BY CONCAT(Country, year)) as Row_Num
FROM world_life_expectancy
) AS Row_table
WHERE Row_num > 1
;

-- Double check additional missing data columns

SELECT * 
FROM world_life_expectancy
;

-- The 'Status' table has missing values

SELECT *
FROM world_life_expectancy
WHERE status = ''
;

-- Take status from different year and plug it into missing value cells

-- Let's first determine all the different possible statuses


SELECT DISTINCT(Status)
FROM world_life_expectancy
WHERE status <> ''
;


-- Let's first find all of the countries that are developing. Once we have that list, we can use it to fill in all of the countries that don't have statuses


SELECT DISTINCT(country)
FROM world_life_expectancy
WHERE Status = 'Developing'
;

-- Now let's update the table with Developing countries to make sure all statuses say "developing"


UPDATE world_life_expectancy
SET Status = 'Developing'
WHERE Country IN 
(SELECT DISTINCT(country)
FROM world_life_expectancy
WHERE Status = 'Developing')
;

-- error is given, must resolve by joining table to self


UPDATE world_life_expectancy AS t1
JOIN world_life_expectancy AS t2
	ON t1.country = t2.country
    SET  t1.Status = 'Developing'
    WHERE t1.status = ''
    AND t2.status <> ''
    AND t2.status = 'Developing'
;
    
-- utilize same query for developed nations


UPDATE world_life_expectancy AS t1
JOIN world_life_expectancy AS t2
	ON t1.country = t2.country
    SET  t1.Status = 'Developed'
    WHERE t1.status = ''
    AND t2.status <> ''
    AND t2.status = 'Developed'
;


-- now all statuses are not null or blank. Let's double check.


SELECT * 
FROM world_life_expectancy
;

-- Looks like life expectancy has missing values

SELECT * 
FROM world_life_expectancy
WHERE `Life expectancy` = ''
;

-- Let's populate the missing values with the averages of the next and previous year


SELECT Country,
year,
`Life expectancy`
FROM world_life_expectancy
;

-- let's self join the table to make two tables, and space the years apart by + and - 1 year. This will allow us to take the averages of each year

SELECT t1.Country,
t1.year,
t1.`Life expectancy`,
t2.Country,
t2.year,
t2.`Life expectancy`,
t3.Country,
t3.year,
t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2,1)
FROM world_life_expectancy AS t1
JOIN world_life_expectancy AS t2
	ON t1.country = t2.country
    AND t1.year = t2.year -1
    JOIN world_life_expectancy AS t3
	ON t1.country = t3.country
    AND t1.year = t3.year +1
WHERE t1.`Life expectancy` = ''
;

-- Now input calculation into table

UPDATE world_life_expectancy AS t1
JOIN world_life_expectancy AS t2
	ON t1.country = t2.country
    AND t1.year = t2.year -1
    JOIN world_life_expectancy AS t3
	ON t1.country = t3.country
    AND t1.year = t3.year +1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2,1)
Where t1.`Life expectancy` = ''
;

-- now entire life expectancy column is filled out! Our data looks clean.

-- Now, let's do some Exploratory Data Analysis (EDA)

SELECT *
FROM world_life_expectancy
;


-- Let's start simple. Let's ask which countries had the greatest and least life expectancy over the 15 year period.

SELECT Country, 	
MIN(`Life expectancy`) as Min_Life_Expectancy, 
MAX(`Life expectancy`) as Max_Life_Expectancy
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Country DESC
;


-- we excluded the countries with no available data (zero life expectancy)
-- now, let's see which countries had the largest difference, or greatest change

SELECT Country, 	
MIN(`Life expectancy`) as Min_Life_Expectancy, 
MAX(`Life expectancy`) as Max_Life_Expectancy,
ROUND((MAX(`Life expectancy`) - MIN(`Life expectancy`)), 1) as Expectancy_Change
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Expectancy_Change DESC
;


-- Fantastic. Now, what about which average year had the greatest increase?
-- Let's take a look at just the columns we need, year and the average life expectancy of those years

SELECT Year, ROUND(AVG(`Life expectancy`), 2)
FROM world_life_expectancy
WHERE `Life expectancy` <> 0
GROUP BY Year
ORDER BY Year DESC
;

-- Great! Now let's look at correlations.
-- Let's start with the correlation between GDP and life expectancy

SELECT country, 	
ROUND(AVG(`life expectancy`), 1) as Life_Expec,
 ROUND(AVG(GDP), 1) as Avg_GDP
FROM world_life_expectancy
GROUP BY country
HAVING Life_Expec > 0
AND Avg_GDP > 0
ORDER BY Avg_GDP DESC
;


-- Looks like GDP has a positive correlation with life expectancy
-- Let's use a CASE statement to  group countries above and below median GDP and life expectancy

SELECT 
SUM(CASE
	WHEN GDP >= 1500 THEN 1 
	ELSE 0
END) High_GDP_Count,
AVG(CASE
	WHEN GDP >= 1500 THEN `life expectancy` 
	ELSE NULL
END) High_GDP_life_expectancy,
SUM(CASE
	WHEN GDP <= 1500 THEN 1 
	ELSE 0
END) Low_GDP_Count,
AVG(CASE
	WHEN GDP <= 1500 THEN `life expectancy` 
	ELSE NULL
END) Low_GDP_life_expectancy
FROM world_life_expectancy
;

-- this show us that we can 1326 rows that are higher than the median GDP and their respective life expectancy, and same for the lower half of GDPs
-- These case statements tell us how many rows are above the media and how many are below, and their life expectancy averages


-- Now lets look at average life expectancy between statuses


SELECT Status, Round(AVG(`life expectancy`),1)
FROM world_life_expectancy
Group BY Status
;

-- Wow! The average life expectancy between developing and developed countries is over 10 years.

SELECT Status, COUNT(distinct country)
FROM world_life_expectancy
Group BY Status
;

-- this show us how many more developing countries there are than developed ones

-- Now let's look at BMI compared to each country and average life expectancy

SELECT country, 	
ROUND(AVG(`life expectancy`), 1) as Life_Expec,
 ROUND(AVG(BMI), 1) as Avg_BMI
FROM world_life_expectancy
GROUP BY country
HAVING Life_Expec > 0
AND Avg_BMI > 0
ORDER BY Avg_BMI DESC
;

-- Interesting insights found here. Some of the countries with the highest BMIs have very high life expectancies.
-- Now let's look at adult mortality rates compared to life expectancy.
-- Let's also use a rolling total on adult mortality too

SELECT country,
year,
`life expectancy`,
`Adult mortality`,
SUM(`Adult mortality`) OVER(PARTITION BY Country ORDER BY Year) as Rolling_Total
FROM world_life_expectancy
;

-- Great! Now let's sum what we've found
-- We found the min and max life expectancies, the averages of the world, the life expectancy correlated to the GDP, the medians of the world GDPs and developed status, the life expectancy versus the BMI, and finally we found the rolling total of the adult mortality of each nation. 













