-- run without json format 
EXECUTE [dbo].[usp_QueryData] @json = null;

--run with exact location, without radius
EXECUTE [dbo].[usp_QueryData] @json = '{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "country": "US",
        "region": "AZ",
        "city": "Phoenix",
        "category": "Health and Personal Care Stores",
        "name": "Walgreens Pharmacy" 
      },
      "geometry": {
        "type": "Point",
        "coordinates": [-112.133493, 33.568018]
      }
    } 
  ]
}
'


--run with exact location and radius
EXECUTE [dbo].[usp_QueryData] @json = '{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "country": "US",
        "region": "AZ",
        "city": "Phoenix",
        "category": "Health and Personal Care Stores",
        "name": "Walgreens Pharmacy",
        "radius": 4000
      },
      "geometry": {
        "type": "Point",
        "coordinates": [-112.133493, 33.568018]
      }
    } 
  ]
}
'

-- run without exact location
EXECUTE [dbo].[usp_QueryData] @json = '{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "country": "US",
        "region": "AZ",
        "city": "Phoenix",
        "category": "Health and Personal Care Stores",
        "name": "Walgreens Pharmacy",
        "radius": 200
      }
    }
  ]
}
'

-- run with country and region only
EXECUTE [dbo].[usp_QueryData] @json = '{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "country": "US",
        "region": "AZ"
      }
    }
  ]
}
'

-- run without any data provided ( in this cases it takes random location and radius 200m
EXECUTE [dbo].[usp_QueryData] @json = '{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": { 
      }
    }
  ]
}
'

-- run with fill json
EXECUTE [dbo].[usp_QueryData] @json = '{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "country": "US",
        "region": "AZ",
        "city": "Phoenix",
        "category": "Health and Personal Care Stores",
        "name": "Walgreens Pharmacy"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [-112.13322245599994, 33.56818378200006],
            [-112.13322346199999, 33.568109924000055],
            [-112.13330479999996, 33.568110680000075],
            [-112.13330736199998, 33.56792267800006],
            [-112.13366524999998, 33.56792599900007],
			[-112.13366561499998, 33.567899142000044],
			[-112.13379575699997, 33.56790035000006],
			[-112.13379575699997, 33.56790035000006],
			[-112.13379145999994, 33.56821592400007],
			[-112.13330342899997, 33.56821139500005],
			[-112.13330379399997, 33.568184537000036],
			[-112.13322245599994, 33.56818378200006]
          ]
        ]
      }
    } 	
  ]
}
'