// 1. Đường bay ngắn nhất theo số chặng với điều kiện quá cảnh ít nhất từ Hà Nội (HAN) đến Paris (CDG).
MATCH p = shortestPath((start:Airport {iata: 'HAN'})-[*]-(end:Airport {iata: 'CDG'}))
RETURN p, length(p) AS hops, reduce(s = 0, r in relationships(p) | s + r.stops) AS total_stops
ORDER BY hops ASC, total_stops ASC
LIMIT 1;

// 2. Đường bay ngắn nhất theo khoảng cách thực tế (haversine) giữa Tokyo (NRT) và London (LHR), giới hạn 3 chặng bay.
MATCH p = (start:Airport {iata: 'NRT'})-[*..3]->(end:Airport {iata: 'LHR'})
RETURN [n in nodes(p) | n.name] AS path,
       reduce(dist = 0.0, r in relationships(p) | dist + r.distance) AS total_distance
ORDER BY total_distance ASC
LIMIT 1;

// 3. Sân bay có "Bậc vào" (In-Degree) cao nhất
MATCH ()-[r:ROUTE]->(a:Airport)
RETURN a.name AS Airport, count(DISTINCT startNode(r)) AS InDegree
ORDER BY InDegree DESC
LIMIT 10;

// 4. Sân bay trung chuyển quan trọng cục bộ (Local Hubs) tại Đức
MATCH (a:Airport {country: 'Germany'})
OPTIONAL MATCH (a)-[out:ROUTE]->()
OPTIONAL MATCH ()-[in:ROUTE]->(a)
RETURN a.name, count(DISTINCT out) + count(DISTINCT in) AS TotalDegree
ORDER BY TotalDegree DESC
LIMIT 5;

// 5. Hãng hàng không có mạng lưới phủ sóng lớn nhất
MATCH (a:Airline)
MATCH (start:Airport)-[r:ROUTE {airlineID: a.airlineID}]->(end:Airport)
WITH a, collect(DISTINCT start) + collect(DISTINCT end) AS airports
UNWIND airports AS airport
RETURN a.name, count(DISTINCT airport) AS AirportCount
ORDER BY AirportCount DESC
LIMIT 5;

// 6. Hãng hàng không độc quyền đường bay (Trực tiếp giữa 2 thành phố Việt Nam)
MATCH (s:Airport {country:'Vietnam'})-[r:ROUTE]->(d:Airport {country:'Vietnam'})
WITH s, d, collect(DISTINCT r.airlineID) AS airlines
WHERE size(airlines) = 1
MATCH (a:Airline {airlineID: airlines[0]})
RETURN a.name AS ExclusiveAirline, s.city AS From, d.city AS To;

// 7. Cặp quốc gia có mức độ kết nối trực tiếp cao nhất
MATCH (s:Airport)-[r:ROUTE {stops: 0}]->(d:Airport)
WHERE s.country <> d.country
WITH s.country AS c1, d.country AS c2, count(r) AS Flights
// Sắp xếp để tránh trùng lặp (A-B và B-A)
WITH CASE WHEN c1 < c2 THEN c1 ELSE c2 END AS CountryA,
     CASE WHEN c1 < c2 THEN c2 ELSE c1 END AS CountryB,
     sum(Flights) AS TotalFlights
RETURN CountryA, CountryB, TotalFlights
ORDER BY TotalFlights DESC
LIMIT 5;

// 8. Tìm "cổng" khu vực Đông Nam Á đi Châu Âu
// Danh sách quốc gia cần được định nghĩa hoặc lọc theo danh sách.
// Ví dụ đơn giản:
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE s.country IN ['Vietnam', 'Thailand', 'Singapore', 'Malaysia', 'Indonesia', 'Philippines', 'Myanmar', 'Cambodia', 'Laos', 'Brunei', 'Timor-Leste']
  AND d.country IN ['France', 'Germany', 'United Kingdom', 'Italy', 'Spain', 'Netherlands', 'Belgium', 'Switzerland', 'Austria', 'Russia', 'Turkey'] // Thêm các nước Châu Âu khác
RETURN s.name, count(r) AS RoutesToEurope
ORDER BY RoutesToEurope DESC
LIMIT 1;

// 9. Sân bay có độ đa dạng thiết bị bay cao nhất
MATCH (a:Airport)-[r:ROUTE]-()
WHERE r.equipment IS NOT NULL
WITH a, r.equipment AS eq
UNWIND split(eq, ' ') AS type
RETURN a.name, count(DISTINCT type) AS EquipmentTypes
ORDER BY EquipmentTypes DESC
LIMIT 5;

// 10. Tìm các "Tam giác" đường bay (3 chặng A->B->C->A) ngắn nhất
MATCH (a:Airport)-[r1:ROUTE]->(b:Airport)-[r2:ROUTE]->(c:Airport)-[r3:ROUTE]->(a)
WHERE a <> b AND b <> c AND a <> c
RETURN a.name, b.name, c.name, (r1.distance + r2.distance + r3.distance) AS TotalDist
ORDER BY TotalDist ASC
LIMIT 5;

// 11. Từ sân bay Phu cat (6193) bay đến đâu ở Việt Nam?
MATCH (s:Airport {airportID: '6193'})-[r:ROUTE]->(d:Airport {country: 'Vietnam'})
RETURN d.name;

// 12. Đường bay ngắn nhất từ Phu cat (6193) đến Pleiku (6194)
MATCH p = shortestPath((s:Airport {airportID: '6193'})-[*]->(d:Airport {airportID: '6194'}))
RETURN [n in nodes(p) | n.name] AS Path;

// 13. Đường bay ngắn nhất từ Danang đến New York (JFK: 3797)
MATCH (dad:Airport {city: 'Danang'})
MATCH (jfk:Airport {airportID: '3797'})
MATCH p = shortestPath((dad)-[*]->(jfk))
RETURN [n in nodes(p) | n.name] AS Path;

// 14. Chuyến bay trực tiếp từ Noi Bai (3199) đến Tan Son Nhat (3205)
MATCH (s:Airport {airportID: '3199'})-[r:ROUTE]->(d:Airport {airportID: '3205'})
MATCH (a:Airline {airlineID: r.airlineID})
RETURN count(r) AS FlightCount, collect(a.name) AS Airlines;

// 15. Đường bay thẳng Vietnam -> Singapore
MATCH (s:Airport {country: 'Vietnam'})-[r:ROUTE]->(d:Airport {country: 'Singapore'})
RETURN s.name AS From, d.name AS To;

// 16. 5 đường bay ngắn nhất từ Phu Cat đến JFK
// Yêu cầu GDS hoặc APOC để tìm k-shortest paths. Với Cypher thuần:
MATCH p = (s:Airport {airportID: '6193'})-[*..5]->(d:Airport {airportID: '3797'})
RETURN [n in nodes(p) | n.name] AS Path, length(p) AS Len
ORDER BY Len ASC
LIMIT 5;

// 17. 10 đường bay ngẫu nhiên từ Phu cat qua đúng 3 sân bay trung chuyển (4 hops)
MATCH p = (s:Airport {airportID: '6193'})-[*4]->(d:Airport)
RETURN [n in nodes(p) | n.name] AS Path
LIMIT 10;

// 18. Phương án mở ít nhất các đường bay ở Vietnam để kết nối hết.
// Đây là bài toán tìm thành phần liên thông mạnh (SCC) và nối chúng.
// Cypher: Kiểm tra tính liên thông
MATCH (a:Airport {country: 'Vietnam'})
OPTIONAL MATCH (a)-[r:ROUTE]->(b:Airport {country: 'Vietnam'})
RETURN a.name, count(b) AS OutDegree;
// Để giải quyết bài toán "mở thêm", cần logic bên ngoài hoặc thuật toán GDS.
// Query này trả về các cụm hiện tại để phân tích.
CALL gds.wcc.stream({
  nodeQuery: 'MATCH (n:Airport {country: "Vietnam"}) RETURN id(n) as id',
  relationshipQuery: 'MATCH (n:Airport {country: "Vietnam"})-[r:ROUTE]->(m:Airport {country: "Vietnam"}) RETURN id(n) as source, id(m) as target'
})
YIELD nodeId, componentId
RETURN componentId, collect(gds.util.asNode(nodeId).name) AS Airports;

// 19. Đường bay ngắn nhất Vietnam -> Iceland
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'Iceland'})
MATCH p = shortestPath((s)-[*]->(d))
RETURN [n in nodes(p) | n.name] AS Path, length(p) AS Hops
ORDER BY Hops ASC
LIMIT 1;

// 20. Bay từ Vietnam sang US bằng Vietnam Airlines (5309)
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'United States'})
MATCH p = shortestPath((s)-[:ROUTE {airlineID: '5309'}]*->(d))
RETURN p IS NOT NULL AS Possible;
