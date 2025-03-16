-- Create the CityTour Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CityTour')
BEGIN
	CREATE DATABASE [CityTour];
END; 

USE [CityTour];

-- Create the Staging table
DROP TABLE IF EXISTS [dbo].[DataStaging];
CREATE TABLE [dbo].[DataStaging] (
    ID NVARCHAR(50),
    ParentID NVARCHAR(50),
    Brand NVARCHAR(255),
    BrandID NVARCHAR(255),
    TopCategory NVARCHAR(255),
    SubCategory NVARCHAR(255),
    CategoryTags NVARCHAR(255),
    PostalCode NVARCHAR(20),
    LocationName NVARCHAR(255),
    Latitude DECIMAL(9, 6),
    Longitude DECIMAL(9, 6),
    CountryCode NVARCHAR(10),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    OperationHours NVARCHAR(MAX),
    GeometryType NVARCHAR(100),
    PolygonWKT NVARCHAR(MAX)
);

-- Import data from CSV file into the Staging table
BULK INSERT  [dbo].[DataStaging]
FROM 'C:\DATA\phoenix.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-- Drop tables
DROP TABLE IF EXISTS [LocationHook];
DROP TABLE IF EXISTS [LocationGeometry];
DROP TABLE IF EXISTS [Location];
DROP TABLE IF EXISTS [City];
DROP TABLE IF EXISTS [State];
DROP TABLE IF EXISTS [Country];
DROP TABLE IF EXISTS [Brand];
DROP TABLE IF EXISTS [Category];
DROP TABLE IF EXISTS [Tag];
DROP TABLE IF EXISTS [WorkingHours];
DROP TABLE IF EXISTS [Week];

-- Create the Brand Table
CREATE TABLE [Brand] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
    BrandID NVARCHAR(255) NOT NULL,
    Brand NVARCHAR(255) NOT NULL
);

-- Create the Category Table
CREATE TABLE [Category] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
    Category NVARCHAR(100) NOT NULL,
    ParentID INT NULL
);

-- Create the Tag Table
CREATE TABLE [Tag] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
    Tag NVARCHAR(100) NOT NULL
);

-- Create the Country Table
CREATE TABLE [Country] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
    CountryCode NVARCHAR(10) NOT NULL,
    CountryName NVARCHAR(255) NULL
);

-- Create the State Table
CREATE TABLE [State] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
	CountryID INT,
    StateCode NVARCHAR(10) NOT NULL,
    StateName NVARCHAR(255) NULL,
    FOREIGN KEY (CountryID) REFERENCES [Country](ID)
);

-- Create the City Table
CREATE TABLE [City] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
	StateID INT,
    City NVARCHAR(10) NOT NULL,
    FOREIGN KEY (StateId) REFERENCES [State](ID)
);

-- Create the Week Table
CREATE TABLE [Week] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
    WeekDay NVARCHAR(10) NOT NULL,
	WeekDayCode NVARCHAR(3) NOT NULL
);

-- Create the Location Table
CREATE TABLE [Location] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
	LocationID NVARCHAR(100) NOT NULL,
	CityID INT NOT NULL,
	BrandID INT NULL,
	CategoryID INT NULL,
    PostalCode NVARCHAR(10) NOT NULL,
    LocationName NVARCHAR(255) NOT NULL,
    Latitude DECIMAL(9, 6),
    Longitude DECIMAL(9, 6),
	OperationHours NVARCHAR(MAX),
    FOREIGN KEY (CityID) REFERENCES [City](ID),
    FOREIGN KEY (BrandID) REFERENCES [Brand](ID),
    FOREIGN KEY (CategoryID) REFERENCES [Category](ID)
);

-- Create the LocationGeometry Table
CREATE TABLE [LocationGeometry] (
    ID INT PRIMARY KEY, 
    GeometryType NVARCHAR(100),
	Point GEOGRAPHY,
    Polygon GEOMETRY,
    FOREIGN KEY (ID) REFERENCES [Location](ID)
); 
CREATE SPATIAL INDEX SPIX_Geocodes_Point ON [LocationGeometry](Point) USING geography_auto_grid;

 
-- Create the LocationHook Relationships Table
CREATE TABLE [LocationHook] (
    ID INT,
    ParentID INT,
    PRIMARY KEY (ID, ParentID),
    FOREIGN KEY (ID) REFERENCES [Location](ID),
    FOREIGN KEY (ParentID) REFERENCES [Location](ID)
);

-- Create the Tag Hook Table
CREATE TABLE [TagHook] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
    LocationID INT,
	TagID INT, 
    FOREIGN KEY (LocationID) REFERENCES [Location](ID),
    FOREIGN KEY (TagID) REFERENCES [Tag](ID)
);

-- Create the WorkingHours Table
CREATE TABLE [WorkingHours] (
	ID INT IDENTITY(1,1) PRIMARY KEY,
    WeekDayID INT NOT NULL,
	LocationID INT NOT NULL,
	OpensAt TIME,
	ClosesAt TIME,
    FOREIGN KEY (WeekDayID) REFERENCES [Week](ID)
);

-- Insert data into the Brand table
INSERT INTO [dbo].[Brand] (BrandID, Brand)
SELECT DISTINCT ds.BrandID, ds.Brand 
FROM [dbo].[DataStaging] ds
WHERE ds.BrandID IS NOT NULL
ORDER BY ds.Brand;

-- Insert data into the Category table
INSERT INTO [dbo].[Category] (Category)
SELECT DISTINCT ds.TopCategory 
FROM [dbo].[DataStaging] ds
WHERE ds.TopCategory IS NOT NULL
ORDER BY ds.TopCategory;

INSERT INTO [dbo].[Category] (Category, ParentID)
SELECT DISTINCT ds1.SubCategory, c.ID
FROM [dbo].[DataStaging] ds1
LEFT JOIN [dbo].[Category] c ON ds1.TopCategory = c.Category
WHERE ds1.SubCategory IS NOT NULL
ORDER BY c.ID;

-- Insert data into the Tag table
INSERT INTO [dbo].[Tag] (Tag)
SELECT DISTINCT Tags.Value
FROM [dbo].[DataStaging] ds
CROSS APPLY STRING_SPLIT(ds.CategoryTags, ',') as Tags
ORDER BY Tags.Value;

-- Insert data into the Country table
INSERT INTO [dbo].[Country] (CountryCode)
SELECT DISTINCT ds.CountryCode
FROM [dbo].[DataStaging] ds
WHERE ds.CountryCode IS NOT NULL
ORDER BY ds.CountryCode;

-- Insert data into the Country table
INSERT INTO [dbo].[State] (StateCode, CountryID)
SELECT DISTINCT ds.Region, c.ID
FROM [dbo].[DataStaging] ds
LEFT JOIN [dbo].[Country] c ON ds.CountryCode = c.CountryCode
WHERE ds.Region IS NOT NULL
ORDER BY ds.Region;

-- Insert data into the Country table
INSERT INTO [dbo].[City] (City, StateID)
SELECT DISTINCT ds.City, s.ID
FROM [dbo].[DataStaging] ds
LEFT JOIN [dbo].[State] s ON ds.Region = s.StateCode
WHERE ds.City IS NOT NULL
ORDER BY ds.City;

-- Insert data into the Week table
INSERT INTO [dbo].[Week] (WeekDay, WeekDayCode)
VALUES	 ('Monday', 'Mon')
		,('Tuesday', 'Tue')
		,('Wednesday', 'Wed')
		,('Thursday', 'Thu')
		,('Friday', 'Fri')
		,('Saturday', 'Sat')
		,('Sunday' , 'Sun');
		
-- Insert data into the Location table
INSERT INTO [dbo].[Location] (LocationID, CityID, BrandID, CategoryID, PostalCode, LocationName, Latitude, Longitude, OperationHours)
SELECT ds.ID, c.ID, b.ID, cat.ID, ds.PostalCode, ds.LocationName, ds.Latitude, ds.Longitude, ds.OperationHours
FROM [dbo].[DataStaging] ds
LEFT JOIN [dbo].[Country] cn ON ds.CountryCode = cn.CountryCode 
LEFT JOIN [dbo].[State] s ON ds.Region = s.StateCode AND s.CountryID = cn.ID
LEFT JOIN [dbo].[City] c ON ds.City = c.City AND c.StateID = s.ID
LEFT JOIN [dbo].[Brand] b ON ds.BrandID = b.BrandID
LEFT JOIN [dbo].[Category] cat ON IIF(ds.SubCategory IS NULL, ds.TopCategory, ds.SubCategory) = cat.Category 

 -- Insert data into the LocationGeometry table
INSERT INTO [dbo].[LocationGeometry] (ID, GeometryType, Point, Polygon)
SELECT l.ID, ds.GeometryType, GEOGRAPHY::STPointFromText('POINT(' + CAST(l.Longitude AS VARCHAR(20)) + ' ' +  CAST(l.Latitude AS VARCHAR(20)) + ')', 4326), GEOMETRY::STGeomFromText(REPLACE(ds.PolygonWKT,' ((','(('), 4326)
FROM [dbo].[Location] l
JOIN [dbo].[DataStaging] ds ON l.LocationID = ds.ID;


 -- Insert data into the LocationHook table
INSERT INTO [dbo].[LocationHook] (ID, ParentID)
SELECT l.ID, lp.ID
FROM [dbo].[DataStaging] ds
LEFT JOIN [dbo].[Location] l ON ds.ID = l.LocationID
LEFT JOIN [dbo].[Location] lp ON ds.ParentID = lp.LocationID
WHERE lp.ID IS NOT NULL;

-- Insert data into the TagHook table
INSERT INTO [dbo].TagHook (LocationID, TagID)
SELECT l.id, t.id
FROM [dbo].[DataStaging] ds
JOIN [dbo].[Location] l ON ds.ID = l.LocationID
CROSS APPLY STRING_SPLIT(ds.CategoryTags, ',') v
LEFT JOIN [dbo].[Tag] t ON v.value = t.Tag;

-- Insert data into the WorkingHours table
DECLARE @CurrentID INT = 1;
DECLARE @MaxID INT = (SELECT MAX(ID) FROM [dbo].[Location])
DECLARE @json NVARCHAR(MAX);

WHILE (@CurrentID <= @MaxID) BEGIN

	SET @json = (SELECT ds.OperationHours FROM DataStaging ds WHERE ds.ID = (SELECT l.LocationID FROM [dbo].[Location] l WHERE l.ID = @CurrentID));
	IF (@json IS NULL) BEGIN
		SET @CurrentID = @CurrentID + 1; 
		END
	ELSE BEGIN
		DROP TABLE IF EXISTS #temp;
		SELECT @CurrentID AS ID, WeekDay, TRY_CAST(TimeSlots.[value] AS TIME) AS OpensAt, TRY_CAST(IIF(TimeSlots2.[value]='10:00:00.0000000', '23:59:59.0000000',TimeSlots2.[value]) AS TIME) AS ClosesAt
		INTO #temp
		FROM 
		(
			SELECT 
				[key] COLLATE SQL_Latin1_General_CP1_CI_AS AS WeekDay, 
				value COLLATE SQL_Latin1_General_CP1_CI_AS AS TimeRangesJson
			FROM OPENJSON(@json)
		) AS Days
		CROSS APPLY OPENJSON(Days.TimeRangesJson) AS TimeRanges
		CROSS APPLY OPENJSON(TimeRanges.value) AS TimeSlots
		CROSS APPLY OPENJSON(TimeRanges.value) AS TimeSlots2
		WHERE TimeSlots.[key] = '0' AND TimeSlots2.[key] = '1';

		INSERT INTO [dbo].[WorkingHours] (LocationID, WeekDayID, OpensAt, ClosesAt)
		SELECT l.ID, w.ID, t.OpensAt, t.ClosesAt
		FROM #temp t 
		JOIN [dbo].[Location] l ON t.ID = l.ID
		JOIN [dbo].[Week] w ON t.WeekDay = w.WeekDayCode;

		SET @CurrentID = @CurrentID + 1;
	END
END;
