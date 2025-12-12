// 1. Tạo Constraints (Ràng buộc duy nhất & Index)
// Lưu ý: Cú pháp tạo constraint trong Neo4j 5.x có thể dùng CREATE CONSTRAINT IF NOT EXISTS
CREATE CONSTRAINT airline_id_unique IF NOT EXISTS FOR (a:Airline) REQUIRE a.airlineID IS UNIQUE;
CREATE CONSTRAINT airport_id_unique IF NOT EXISTS FOR (p:Airport) REQUIRE p.airportID IS UNIQUE;

// 2. Load Airlines
LOAD CSV WITH HEADERS FROM 'file:///airlines.csv' AS row
WITH row WHERE row.`Airline ID` IS NOT NULL AND row.`Airline ID` <> '-1'
MERGE (a:Airline {airlineID: row.`Airline ID`})
ON CREATE SET a.name = row.Name, a.country = row.Country;

// 3. Load Airports
// File airports.csv không có header, dùng index
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
    // Neo4j 5.x hỗ trợ kiểu dữ liệu Point
    p.location = point({latitude: toFloat(row[6]), longitude: toFloat(row[7])});

// 4. Load Routes
LOAD CSV WITH HEADERS FROM 'file:///routes.csv' AS row
WITH row WHERE row.` source airport id` IS NOT NULL AND row.` destination airport id` IS NOT NULL
MATCH (source:Airport {airportID: row.` source airport id`})
MATCH (target:Airport {airportID: row.` destination airport id`})
MERGE (source)-[r:ROUTE]->(target)
ON CREATE SET
    r.airlineID = row.`airline ID`,
    r.stops = toInteger(row.` stops`),
    r.equipment = row.` equipment`,
    // Tính sẵn khoảng cách (km) để truy vấn nhanh hơn
    r.distance = point.distance(source.location, target.location) / 1000.0;
