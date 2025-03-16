DROP PROCEDURE IF EXISTS [dbo].[usp_QueryData]
GO

CREATE PROCEDURE [dbo].[usp_QueryData]
    @json varchar(MAX)
AS
BEGIN

	IF (@json IS NULL) 
	BEGIN
	    RAISERROR('Input JSON needs to be provided in the correct format.', 15, 1)
		RETURN 
	END
 
	-- Extract basic location details
	DECLARE @country NVARCHAR(2) = JSON_VALUE(@json, '$.features[0].properties.country');
	DECLARE @region NVARCHAR(2) = JSON_VALUE(@json, '$.features[0].properties.region');
	DECLARE @city NVARCHAR(100) = JSON_VALUE(@json, '$.features[0].properties.city');
	DECLARE @category NVARCHAR(100) = JSON_VALUE(@json, '$.features[0].properties.category');
	DECLARE @name NVARCHAR(100) = JSON_VALUE(@json, '$.features[0].properties.name');
	DECLARE @radius FLOAT = ISNULL(JSON_VALUE(@json, '$.features[0].properties.radius'),0);

	-- Extract exact location (Point geometry)
	DECLARE @longitude DECIMAL(9,6) = JSON_VALUE(@json, '$.features[0].geometry.coordinates[0]');
	DECLARE @latitude DECIMAL(9,6) = JSON_VALUE(@json, '$.features[0].geometry.coordinates[1]'); 
	DECLARE @point GEOGRAPHY = GEOGRAPHY::STPointFromText('POINT(' + CAST(@longitude AS VARCHAR(20)) + ' ' + CAST(@latitude AS VARCHAR(20)) + ')', 4326); 

	-- Extract Polygon coordinates as JSON
	DECLARE @polygon GEOMETRY;
	WITH
	q AS
	(SELECT ShapeType, 
		STUFF((
			SELECT CONCAT(',  ', JSON_VALUE(Value,'$[0]'),' ',JSON_VALUE(Value,'$[1]'))  
			FROM OPENJSON(s.Shape,'$[0]') 
			ORDER BY CAST([key] AS INT)
			FOR XML PATH('')
			),1,3,'') path
		FROM OPENJSON(@json) 
		WITH (ShapeType VARCHAR(100) '$.features[1].geometry.type', Shape NVARCHAR(MAX) '$.features[1].geometry.coordinates' AS JSON) s),
	q2 AS
	(SELECT CONCAT(UPPER(ShapeType),' ((',path,'))') WKT FROM q)
	SELECT @polygon = IIF(WKT = ' (())',NULL,GEOMETRY::STGeomFromText(WKT,4326)) FROM q2;

	-- Set point to random location if no input is provided
	IF (@country IS NULL AND 
		@region IS NULL AND  
		@city IS NULL AND 
		@category IS NULL AND 
		@name IS NULL AND 
		@radius= 0 AND 
		@longitude IS NULL AND 
		@latitude IS NULL AND
		@point IS NULL AND
		@polygon IS NULL) BEGIN
		DECLARE @id INT;
		SET @id = (SELECT TOP 1 ID FROM [dbo].Location ORDER BY NEWID());
		SET @latitude = (SELECT Latitude FROM [dbo].Location WHERE ID = @id);
		SET @longitude = (SELECT Longitude FROM [dbo].Location WHERE ID = @id);
		SET @radius = 200;
	END;

  -- Select filtered data based on hte input to the temporary table
	DROP TABLE IF EXISTS #prepared
	SELECT	l.LocationID AS ID,
			lp.LocationID AS ParentID,
			cn.CountryCode,
			s.StateCode as RegionCode,
			c.City,
			l.Latitude, 
			l.Longitude,
			ISNULL(cat.Category,scat.Category) AS Category,
			IIF(cat.Category IS NULL, NULL, scat.Category) AS SubCategory,
			lg.Polygon,
			lg.Point,
			l.LocationName,
			l.PostalCode,
			l.OperationHours
	INTO #prepared
	FROM [dbo].[Location] l
	LEFT JOIN [dbo].[Category] scat ON l.CategoryID = scat.ID
	LEFT JOIN [dbo].[Category] cat ON scat.ParentID = cat.ID
	LEFT JOIN [dbo].[City] c ON l.CityID = c.ID
	LEFT JOIN [dbo].[State] s ON c.StateID = s.ID
	LEFT JOIN [dbo].[Country] cn ON s.CountryID = cn.ID
	LEFT JOIN [dbo].[LocationHook] lh ON l.ID = lh.ID
	LEFT JOIN [dbo].[Location] lp ON lh.ID = lp.ID
	JOIN [dbo].[LocationGeometry] lg ON l.ID = lg.ID
	WHERE 1 = 1 
		AND (cn.CountryCode = @country OR @country IS NULL)
		AND (s.StateCode = @region OR @region IS NULL)
		AND (c.City = @city OR @city IS NULL)
		AND (ISNULL(cat.Category,scat.Category) = @category OR @category IS NULL)
		AND (l.LocationName = @name OR @name IS NULL)
		AND (((l.Latitude = @latitude AND l.Longitude = @longitude) OR (@latitude IS NULL AND @longitude IS NULL))
			OR ((lg.Point.STDistance(@point) <= @radius) OR @radius IS NULL))
		AND ((lg.Polygon.STEquals(@polygon) = 1) OR (@polygon.STContains(GEOMETRY::STPointFromText(lg.Point.STAsText(), 4326)) = 1) OR @polygon IS NULL);
	
	-- Create GEOJson data
	DECLARE @featureList NVARCHAR(MAX) =
	(
		SELECT
			'Feature' as 'type',
			ID AS 'properties.ID',
			ParentID AS 'properties.ParentID',
			CountryCode AS 'properties.CountryCode',
			RegionCode AS 'properties.RegionCode',
			City AS 'properties.City',
			Category AS 'properties.Category',
			SubCategory AS 'properties.SubCategory',
			LocationName AS 'properties.LocationName',
			PostalCode AS 'properties.PostalCode',
			JSON_QUERY(OperationHours) AS 'properties.OperationHours',
			(SELECT 'GeometryCollection' AS 'type',
					JSON_QUERY([dbo].[GeographyToJson](Point)) AS point,
					JSON_QUERY([dbo].[GeometryToJson](Polygon)) AS polygon
			FROM #prepared pi WHERE pi.ID = p.ID
			FOR JSON PATH
			) AS 'geometry'
		FROM #prepared p
			FOR JSON PATH
	);
 
	DECLARE @featureCollection NVARCHAR(MAX) = (
		SELECT 'FeatureCollection' as 'type',
		JSON_QUERY(@featureList)   as 'Features'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	);
	
	-- Outupt result as GEOJson data
	SELECT @featureCollection as result;
	SELECT * FROM #PREPARED

END;