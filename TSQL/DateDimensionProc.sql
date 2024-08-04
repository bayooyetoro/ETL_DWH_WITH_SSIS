-- This scripts is a function that builds the Date Table from any source or object
----------------------------------------------------------------
--> Usage: EXEC spCreateDIMDATE(@StartDate='2024-01-01', @Year = 2)
----------------------------------------------------------------


SET DATEFIRST  7, -- 1 = Monday, 7 = Sunday
    DATEFORMAT mdy, 
    LANGUAGE   US_ENGLISH;

	
ALTER PROCEDURE spCreateDimDate
	@StartDate DATE, -- Input parameter for the start date
	@Years INT -- number of years
AS
BEGIN

-- TABLE CREATION
DROP TABLE IF EXISTS DimDate;
CREATE TABLE DimDate (
	TheDate DATE PRIMARY KEY,    
	TheDay  INT,  
	TheDayName VARCHAR(50), 
	TheWeek  INT,
	TheISOWeek INT,  
	TheDayOfWeek INT,
	TheMonth INT,        
	TheMonthName VARCHAR(50), 
	TheQuarter INT,
	TheYear INT, 
	TheFirstOfMonth DATE,
	TheLastOfYear DATE, 
	TheDayOfYear INT 
);


WITH YNumber(n) AS
(SELECT n=VALUE 
 FROM GENERATE_SERIES(0, DATEDIFF(DAY, @StartDate, DATEADD(YEAR, @Years, @StartDate))-1)
),

YDates(d) AS
(SELECT DATEADD(DAY, n, @StartDate) FROM YNumber),

YDim AS
(SELECT
	TheDate         = CONVERT(date, d),
	TheDay          = DATEPART(DAY, d),
	TheDayName      = DATENAME(WEEKDAY, d),
	TheWeek         = DATEPART(WEEK, d),
	TheISOWeek      = DATEPART(ISO_WEEK, d),
	TheDayOfWeek    = DATEPART(WEEKDAY, d),
	TheMonth        = DATEPART(MONTH, d),
	TheMonthName    = DATENAME(MONTH, d),
	TheQuarter      = DATEPART(Quarter, d),
	TheYear         = DATEPART(YEAR, d),
	TheFirstOfMonth = DATEFROMPARTS(YEAR(d), MONTH(d), 1),
	TheLastOfYear   = DATEFROMPARTS(YEAR(d), 12, 31),
	TheDayOfYear    = DATEPART(DAYOFYEAR, d)
 FROM YDates),

ExtraDim AS
(SELECT
	TheDate, 
	TheDay,
	TheDaySuffix        = CONVERT(char(2), CASE WHEN TheDay / 10 = 1 THEN 'th' ELSE 
							CASE RIGHT(TheDay, 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
							WHEN '3' THEN 'rd' ELSE 'th' END END),
	TheDayName,
	TheDayOfWeek,
	TheDayOfWeekInMonth = CONVERT(tinyint, ROW_NUMBER() OVER 
							(PARTITION BY TheFirstOfMonth, TheDayOfWeek ORDER BY TheDate)),
	TheDayOfYear,
	IsWeekend           = CASE WHEN TheDayOfWeek IN (CASE @@DATEFIRST WHEN 1 THEN 6 WHEN 7 THEN 1 END,7) 
							THEN 1 ELSE 0 END,
	TheWeek,
	TheISOweek,
	TheFirstOfWeek      = DATEADD(DAY, 1 - TheDayOfWeek, TheDate),
	TheLastOfWeek       = DATEADD(DAY, 6, DATEADD(DAY, 1 - TheDayOfWeek, TheDate)),
	TheWeekOfMonth      = CONVERT(tinyint, DENSE_RANK() OVER 
							(PARTITION BY TheYear, TheMonth ORDER BY TheWeek)),
	TheMonth,
	TheMonthName,
	TheFirstOfMonth,
	TheLastOfMonth      = MAX(TheDate) OVER (PARTITION BY TheYear, TheMonth),
	TheFirstOfNextMonth = DATEADD(MONTH, 1, TheFirstOfMonth),
	TheLastOfNextMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 2, TheFirstOfMonth)),
	TheQuarter,
	TheFirstOfQuarter   = MIN(TheDate) OVER (PARTITION BY TheYear, TheQuarter),
	TheLastOfQuarter    = MAX(TheDate) OVER (PARTITION BY TheYear, TheQuarter),
	TheYear,
	TheISOYear          = TheYear - CASE WHEN TheMonth = 1 AND TheISOWeek > 51 THEN 1 
							WHEN TheMonth = 12 AND TheISOWeek = 1  THEN -1 ELSE 0 END,      
	TheFirstOfYear      = DATEFROMPARTS(TheYear, 1,  1),
	TheLastOfYear,
	IsLeapYear          = CONVERT(bit, CASE WHEN (TheYear % 400 = 0) 
							OR (TheYear % 4 = 0 AND TheYear % 100 <> 0) 
							THEN 1 ELSE 0 END),
	Has53Weeks          = CASE WHEN DATEPART(WEEK,     TheLastOfYear) = 53 THEN 1 ELSE 0 END,
	Has53ISOWeeks       = CASE WHEN DATEPART(ISO_WEEK, TheLastOfYear) = 53 THEN 1 ELSE 0 END,
	MMYYYY              = CONVERT(char(2), CONVERT(char(8), TheDate, 101))
						  + CONVERT(char(4), TheYear),
	Style101            = CONVERT(char(10), TheDate, 101),
	Style103            = CONVERT(char(10), TheDate, 103),
	Style112            = CONVERT(char(8),  TheDate, 112),
	Style120            = CONVERT(char(10), TheDate, 120)
FROM YDim)

-- FECTHING FROM YDIM (AS THEY ARE THE NEEDED ATTRIBUTES)
DROP TABLE IF EXISTS dbo.DateDimensionTable;
SELECT * INTO dbo.DateDimension FROM dim
END;

-- Excecute and insert result into DateDimension table
EXEC spCreateDIMDATE @StartDate = '2010-01-01', @years = 1

-- Indexing for Optimization
CREATE UNIQUE CLUSTERED INDEX PK_DateDimension ON dbo.DateDimension(TheDate);