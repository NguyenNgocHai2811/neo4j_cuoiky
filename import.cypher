// 1. Tạo Constraints
CREATE CONSTRAINT ON (a:Airline) ASSERT a.airlineID IS UNIQUE;
CREATE CONSTRAINT ON (p:Airport) ASSERT p.airportID IS UNIQUE;

// 2. Load Airlines
LOAD CSV WITH HEADERS FROM 'file:///airlines.csv' AS row
WITH row WHERE row.`Airline ID` IS NOT NULL AND row.`Airline ID` <> '-1'
MERGE (a:Airline {airlineID: row.`Airline ID`})
ON CREATE SET a.name = row.Name, a.country = row.Country;

// 3. Load Airports
// Note: airports.csv has no headers in the file, but we treat it as if we supplied them or use column indices.
// However, the standard Neo4j LOAD CSV expects a header if WITH HEADERS is used.
// If the file actually has no header row, we must not use WITH HEADERS and use row[index].
// Based on exploration:
// 1,"Goroka Airport","Goroka","Papua New Guinea","GKA","AYGA",-6.081689834590001,145.391998291,5282,10,"U","Pacific/Port_Moresby","airport","OurAirports"
// Index 0: ID, 1: Name, 2: City, 3: Country, 4: IATA, 6: Lat, 7: Lon
LOAD CSV FROM 'file:///airports.csv' AS row
WITH row WHERE row[0] IS NOT NULL
MERGE (p:Airport {airportID: row[0]})
ON CREATE SET
    p.name = row[1],
    p.city = row[2],
    p.country = row[3],
    p.iata = row[4],
    p.latitude = toFloat(row[6]),
    p.longitude = toFloat(row[7]),
    p.location = point({latitude: toFloat(row[6]), longitude: toFloat(row[7])});

// 4. Load Routes
// Header: airline,airline ID, source airport, source airport id, destination apirport, destination airport id, codeshare, stops, equipment
LOAD CSV WITH HEADERS FROM 'file:///routes.csv' AS row
WITH row WHERE row.` source airport id` IS NOT NULL AND row.` destination airport id` IS NOT NULL
MATCH (source:Airport {airportID: row.` source airport id`})
MATCH (target:Airport {airportID: row.` destination airport id`})
MERGE (source)-[r:ROUTE]->(target)
ON CREATE SET
    r.airlineID = row.`airline ID`,
    r.stops = toInteger(row.` stops`),
    r.equipment = row.` equipment`,
    // Pre-calculate distance for efficiency in queries
    r.distance = distance(source.location, target.location) / 1000.0;
