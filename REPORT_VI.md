# Báo cáo Bài thực hành số 10: Đường đi ngắn nhất trên đồ thị

Dưới đây là các câu lệnh Cypher để thực hiện các yêu cầu trên cơ sở dữ liệu Neo4j, cùng với kết quả phân tích từ dữ liệu thực tế.

## 1. Thiết lập Cơ sở dữ liệu (Import Data)

Sử dụng file `import.cypher` đính kèm để nạp dữ liệu từ các file CSV (`airlines.csv`, `airports.csv`, `routes.csv`) vào Neo4j.

## 2. Giải quyết các yêu cầu

### 1. Đường bay ngắn nhất (ít chặng nhất) từ Hà Nội (HAN) đến Paris (CDG)
**Câu lệnh Cypher:**
```cypher
MATCH p = shortestPath((start:Airport {iata: 'HAN'})-[*]-(end:Airport {iata: 'CDG'}))
RETURN p, length(p) AS hops, reduce(s = 0, r in relationships(p) | s + r.stops) AS total_stops
ORDER BY hops ASC, total_stops ASC
LIMIT 1;
```
**Kết quả:**
- Noi Bai International Airport -> Charles de Gaulle International Airport
- Số chặng: 1 (Bay thẳng)

### 2. Đường bay ngắn nhất theo khoảng cách thực tế (haversine) giữa Tokyo (NRT) và London (LHR)
**Câu lệnh Cypher:**
```cypher
MATCH p = (start:Airport {iata: 'NRT'})-[*..3]->(end:Airport {iata: 'LHR'})
RETURN [n in nodes(p) | n.name] AS path,
       reduce(dist = 0.0, r in relationships(p) | dist + r.distance) AS total_distance
ORDER BY total_distance ASC
LIMIT 1;
```
**Kết quả:**
- Narita International Airport -> London Heathrow Airport
- Khoảng cách: ~9591.52 km

### 3. Sân bay có "Bậc vào" (In-Degree) cao nhất (Top 10)
**Câu lệnh Cypher:**
```cypher
MATCH ()-[r:ROUTE]->(a:Airport)
RETURN a.name AS Airport, count(DISTINCT startNode(r)) AS InDegree
ORDER BY InDegree DESC
LIMIT 10;
```
**Kết quả:**
1. Frankfurt am Main International Airport (236)
2. Charles de Gaulle International Airport (232)
3. Amsterdam Airport Schiphol (229)
4. Atatürk International Airport (224)
5. Hartsfield Jackson Atlanta International Airport (216)
...

### 4. Sân bay trung chuyển quan trọng cục bộ (Local Hubs) tại Đức (Top 5)
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airport {country: 'Germany'})
OPTIONAL MATCH (a)-[out:ROUTE]->()
OPTIONAL MATCH ()-[in:ROUTE]->(a)
RETURN a.name, count(DISTINCT out) + count(DISTINCT in) AS TotalDegree
ORDER BY TotalDegree DESC
LIMIT 5;
```
**Kết quả:**
1. Frankfurt am Main International Airport
2. Munich International Airport
3. Düsseldorf International Airport
4. Berlin-Tegel International Airport
5. Hamburg Airport

### 5. Hãng hàng không có mạng lưới phủ sóng lớn nhất (Top 5)
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airline)
MATCH (start:Airport)-[r:ROUTE {airlineID: a.airlineID}]->(end:Airport)
WITH a, collect(DISTINCT start) + collect(DISTINCT end) AS airports
UNWIND airports AS airport
RETURN a.name, count(DISTINCT airport) AS AirportCount
ORDER BY AirportCount DESC
LIMIT 5;
```
**Kết quả:**
1. American Airlines (432 sân bay)
2. United Airlines (430 sân bay)
3. Air France (383 sân bay)
4. KLM Royal Dutch Airlines (366 sân bay)
5. Delta Air Lines (352 sân bay)

### 6. Hãng hàng không độc quyền đường bay trực tiếp giữa hai thành phố Việt Nam
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {country:'Vietnam'})-[r:ROUTE]->(d:Airport {country:'Vietnam'})
WITH s, d, collect(DISTINCT r.airlineID) AS airlines
WHERE size(airlines) = 1
MATCH (a:Airline {airlineID: airlines[0]})
RETURN a.name AS ExclusiveAirline, s.city AS From, d.city AS To;
```
**Kết quả (Ví dụ):**
- Vietnam Airlines độc quyền các tuyến: Danang -> Buonmethuot, Danang -> Nha Trang, Hanoi -> Dienbienphu, v.v.

### 7. Cặp quốc gia có mức độ kết nối trực tiếp cao nhất (Top 5)
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport)-[r:ROUTE {stops: 0}]->(d:Airport)
WHERE s.country <> d.country
WITH s.country AS c1, d.country AS c2, count(r) AS Flights
WITH CASE WHEN c1 < c2 THEN c1 ELSE c2 END AS CountryA,
     CASE WHEN c1 < c2 THEN c2 ELSE c1 END AS CountryB,
     sum(Flights) AS TotalFlights
RETURN CountryA, CountryB, TotalFlights
ORDER BY TotalFlights DESC
LIMIT 5;
```
**Kết quả:**
1. Spain - United Kingdom
2. Mexico - United States
3. Canada - United States
4. Germany - Spain
5. Germany - Italy

### 8. Tìm "cổng" khu vực Đông Nam Á đi Châu Âu
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE s.country IN ['Vietnam', 'Thailand', 'Singapore', 'Malaysia', 'Indonesia', 'Philippines', 'Myanmar', 'Cambodia', 'Laos', 'Brunei', 'Timor-Leste']
  AND d.country IN ['France', 'Germany', 'United Kingdom', 'Italy', 'Spain', 'Netherlands', 'Belgium', 'Switzerland', 'Austria', 'Russia', 'Turkey']
RETURN s.name, count(r) AS RoutesToEurope
ORDER BY RoutesToEurope DESC
LIMIT 1;
```
**Kết quả:**
- Suvarnabhumi Airport (Thái Lan)

### 9. Sân bay có độ đa dạng thiết bị bay cao nhất
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airport)-[r:ROUTE]-()
WHERE r.equipment IS NOT NULL
WITH a, r.equipment AS eq
UNWIND split(eq, ' ') AS type
RETURN a.name, count(DISTINCT type) AS EquipmentTypes
ORDER BY EquipmentTypes DESC
LIMIT 5;
```
**Kết quả:**
1. Charles de Gaulle International Airport
2. Amsterdam Airport Schiphol
3. Frankfurt am Main International Airport

### 10. Tìm các "Tam giác" đường bay (3 chặng A->B->C->A) ngắn nhất
**Câu lệnh Cypher:**
```cypher
MATCH (a:Airport)-[r1:ROUTE]->(b:Airport)-[r2:ROUTE]->(c:Airport)-[r3:ROUTE]->(a)
WHERE a <> b AND b <> c AND a <> c
RETURN a.name, b.name, c.name, (r1.distance + r2.distance + r3.distance) AS TotalDist
ORDER BY TotalDist ASC
LIMIT 5;
```
**Kết quả:**
- Tam giác ngắn nhất: Molokai Airport -> Honolulu International Airport -> Lanai Airport

### 11. Từ sân bay Phu cat (6193) có thể bay đến những sân bay nào ở Việt Nam?
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {airportID: '6193'})-[r:ROUTE]->(d:Airport {country: 'Vietnam'})
RETURN d.name;
```
**Kết quả:**
- Noi Bai International Airport
- Tan Son Nhat International Airport

### 12. Đường bay ngắn nhất từ Phu cat (6193) đến Pleiku (6194)
**Câu lệnh Cypher:**
```cypher
MATCH p = shortestPath((s:Airport {airportID: '6193'})-[*]->(d:Airport {airportID: '6194'}))
RETURN [n in nodes(p) | n.name] AS Path;
```
**Kết quả:**
- Phu Cat Airport -> Noi Bai International Airport -> Pleiku Airport

### 13. Đường bay ngắn nhất từ Danang đến New York
**Câu lệnh Cypher:**
```cypher
MATCH (dad:Airport {city: 'Danang'})
MATCH (jfk:Airport {airportID: '3797'}) // JFK
MATCH p = shortestPath((dad)-[*]->(jfk))
RETURN [n in nodes(p) | n.name] AS Path;
```
**Kết quả:**
- Da Nang International Airport -> Chek Lap Kok International Airport -> John F Kennedy International Airport

### 14. Có bao nhiêu chuyến bay trực tiếp từ Noibai (3199) đến Tan Son Nhat (3205)?
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {airportID: '3199'})-[r:ROUTE]->(d:Airport {airportID: '3205'})
MATCH (a:Airline {airlineID: r.airlineID})
RETURN count(r) AS FlightCount, collect(a.name) AS Airlines;
```
**Kết quả:**
- Số lượng: 3
- Hãng: Jetstar Pacific, Royal Air Cambodge, Vietnam Airlines

### 15. Tìm những đường bay thẳng từ Vietnam đến Singapore
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {country: 'Vietnam'})-[r:ROUTE]->(d:Airport {country: 'Singapore'})
RETURN s.name AS From, d.name AS To;
```
**Kết quả:**
- Từ Da Nang, Noi Bai, Tan Son Nhat đến Singapore Changi Airport.

### 16. Tìm 5 đường bay ngắn nhất từ Phu cat đến John F Kennedy (3797)
**Câu lệnh Cypher:**
```cypher
MATCH p = (s:Airport {airportID: '6193'})-[*..5]->(d:Airport {airportID: '3797'})
RETURN [n in nodes(p) | n.name] AS Path, length(p) AS Len
ORDER BY Len ASC
LIMIT 5;
```
**Kết quả:**
- Phu Cat -> Tan Son Nhat -> Narita -> JFK
- Phu Cat -> Noi Bai -> Frankfurt -> JFK
- Và các đường bay tương tự qua các hub quốc tế.

### 17. Tìm 10 đường bay ngẫu nhiên từ Phu cat qua đúng 3 sân bay trung chuyển
**Câu lệnh Cypher:**
```cypher
MATCH p = (s:Airport {airportID: '6193'})-[*4]->(d:Airport)
RETURN [n in nodes(p) | n.name] AS Path
LIMIT 10;
```

### 18. Tìm phương án mở ít nhất các đường bay ở Vietnam sao cho tất cả thông nhau
**Phân tích:**
- Hiện tại các sân bay Việt Nam không liên thông mạnh (Strongly Connected).
- Cần sử dụng thuật toán Strongly Connected Components (SCC) để tìm các cụm, sau đó thêm đường bay (cạnh) để nối các cụm này thành một vòng tròn (Cycle).
**Câu lệnh Cypher (Phân tích SCC):**
```cypher
CALL gds.wcc.stream({
  nodeQuery: 'MATCH (n:Airport {country: "Vietnam"}) RETURN id(n) as id',
  relationshipQuery: 'MATCH (n:Airport {country: "Vietnam"})-[r:ROUTE]->(m:Airport {country: "Vietnam"}) RETURN id(n) as source, id(m) as target'
})
YIELD nodeId, componentId
RETURN componentId, collect(gds.util.asNode(nodeId).name) AS Airports;
```

### 19. Tìm đường bay ngắn nhất từ Vietnam đến Iceland
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'Iceland'})
MATCH p = shortestPath((s)-[*]->(d))
RETURN [n in nodes(p) | n.name] AS Path, length(p) AS Hops
ORDER BY Hops ASC
LIMIT 1;
```
**Kết quả:**
- Noi Bai International Airport -> Charles de Gaulle International Airport -> Keflavik International Airport

### 20. Có thể bay từ Vietnam sang United States bằng máy bay của hãng Vietnam Airlines (mã: 5309) không?
**Câu lệnh Cypher:**
```cypher
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'United States'})
MATCH p = shortestPath((s)-[:ROUTE*..5]->(d))
WHERE all(r in relationships(p) WHERE r.airlineID = '5309')
RETURN p IS NOT NULL AS Possible
LIMIT 1;
```
**Kết quả:**
- Không (No). Vietnam Airlines (trong dữ liệu này) chưa có đường bay thẳng hoặc nối chuyến nội bộ đến Mỹ.
