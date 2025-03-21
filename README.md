# CityTour Database Schema

## Overview
The **CityTour** database is designed to store and manage location-based information, including brands, categories, geographic data, and operational details. 
It supports hierarchical relationships among locations and includes spatial indexing for efficient geographic queries.

## Database Schema
The schema consists of the following tables:

### 1. Brand
Stores brand details.
- `ID` (Primary Key, Auto-increment)
- `BrandID` (Unique identifier for the brand)
- `Brand` (Brand name)

### 2. Category
Defines categories and subcategories for locations.
- `ID` (Primary Key, Auto-increment)
- `Category` (Category name)
- `ParentID` (Self-referencing category hierarchy)

### 3. Tag
Stores additional tags for classification.
- `ID` (Primary Key, Auto-increment)
- `Tag` (Tag name)

### 4. Country
Stores country-level location data.
- `ID` (Primary Key, Auto-increment)
- `CountryCode` (ISO country code)
- `CountryName` (Country name)

### 5. State
Represents states or regions within a country.
- `ID` (Primary Key, Auto-increment)
- `CountryID` (Foreign Key referencing `Country.ID`)
- `StateCode` (State abbreviation/code)
- `StateName` (State name)

### 6. City
Stores city-level location data.
- `ID` (Primary Key, Auto-increment)
- `StateID` (Foreign Key referencing `State.ID`)
- `City` (City name)

### 7. Week
Defines weekdays for scheduling.
- `ID` (Primary Key, Auto-increment)
- `WeekDay` (Day name, e.g., Monday)
- `WeekDayCode` (Short code, e.g., Mon)

### 8. Location
Stores detailed location information.
- `ID` (Primary Key, Auto-increment)
- `LocationID` (Unique location identifier)
- `CityID` (Foreign Key referencing `City.ID`)
- `BrandID` (Foreign Key referencing `Brand.ID`)
- `CategoryID` (Foreign Key referencing `Category.ID`)
- `PostalCode` (ZIP/Postal Code)
- `LocationName` (Location name)
- `Latitude`, `Longitude` (Geographic coordinates)
- `OperationHours` (Opening and closing hours as text)

### 9. LocationGeometry
Stores spatial data for locations.
- `ID` (Primary Key, Foreign Key referencing `Location.ID`)
- `GeometryType` (Point/Polygon)
- `Point` (Geographic point)
- `Polygon` (Geometry polygon)

### 10. LocationHook
Defines hierarchical relationships between locations.
- `ID` (Foreign Key referencing `Location.ID`)
- `ParentID` (Foreign Key referencing `Location.ID`)

### 11. WorkingHours
Stores operating hours per location and weekday.
- `ID` (Primary Key, Auto-increment)
- `WeekDayID` (Foreign Key referencing `Week.ID`)
- `LocationID` (Foreign Key referencing `Location.ID`)
- `OpensAt` (Opening time)
- `ClosesAt` (Closing time)

### 12. TagHook
Links tags to specific locations.
- `ID` (Primary Key, Auto-increment)
- `LocationID` (Foreign Key referencing `Location.ID`)
- `TagID` (Foreign Key referencing `Tag.ID`)

## Installation
To set up the database, execute the provided SQL script `CityTour_install.sql` in **SQL Server Management Studio (SSMS)** or any compatible database system that supports **T-SQL**,
or restore provided backup file. Database was created and tested in **Microsoft SQL Server 2019 (RTM-GDR) (KB5046859) - 15.0.2130.3 (X64)** and **SQL Server Management Studio (SSMS) 20.2**

## Importing Data
A **staging table (`DataStaging`)** is used for importing data from a CSV file. To import data:
1. Place the CSV file (`phoenix.csv`) in `C:\DATA\`.
2. Run the `BULK INSERT` command provided in the script.

## Provided scripts 
1. `CityTour_function_GeographyToJson.sql` - function needs to be created in database as it's used to parse geography data to json
2. `CityTour_function_GeometryToJson.sql` - function needs to be created in database as it's used to parse geography data to json
3. `CityTour_procedure.sql` - procedure that generates final json data
4. `CityTour_queries.sql` - script with test execution of procedure in various situation
5. `phoenix.csv` - containes compressed csv file with the data that needs to be imported
6. `CityTour.zip` - contains backup file that can be restored into SQL server with all data imported and all functions and procedures created
   
## Spatial Indexing
A **spatial index (`SPIX_Geocodes_Point`)** is created on the `Point` column in the `LocationGeometry` table to optimize geographic queries.

