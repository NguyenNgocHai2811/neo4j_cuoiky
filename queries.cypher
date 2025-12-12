// 1. Đường bay ngắn nhất theo số chặng (Hops) từ Hà Nội (HAN) đến Paris (CDG)
MATCH (start:Airport {iata: 'HAN'}), (end:Airport {iata: 'CDG'})
MATCH p = shortestPath((start)-[*]->(end))
RETURN [n in nodes(p) | n.name] AS Path, length(p) AS Hops,
       reduce(s = 0, r in relationships(p) | s + r.stops) AS TotalStops;

// 2. Đường bay ngắn nhất theo khoảng cách (Haversine) Tokyo (NRT) -> London (LHR)
MATCH (start:Airport {iata: 'NRT'}), (end:Airport {iata: 'LHR'})
MATCH p = (start)-[*..3]->(end)
RETURN [n in nodes(p) | n.name] AS Path,
       reduce(dist = 0.0, r in relationships(p) | dist + r.distance) AS TotalDistanceKM
ORDER BY TotalDistanceKM ASC
LIMIT 1;

// 3. Top 10 Sân bay có Bậc vào (In-Degree) cao nhất
MATCH ()-[r:ROUTE]->(a:Airport)
RETURN a.name AS Airport, count(DISTINCT startNode(r)) AS InDegree
ORDER BY InDegree DESC
LIMIT 10;

// 4. Sân bay trung chuyển quan trọng tại Đức (Local Hubs)
MATCH (a:Airport {country: 'Germany'})
OPTIONAL MATCH (a)-[out:ROUTE]->()
OPTIONAL MATCH ()-[in:ROUTE]->(a)
RETURN a.name, count(DISTINCT out) + count(DISTINCT in) AS Degree
ORDER BY Degree DESC
LIMIT 5;

// 5. Hãng hàng không có mạng lưới phủ sóng lớn nhất
MATCH (a:Airline)
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE r.airlineID = a.airlineID
WITH a, collect(DISTINCT s) + collect(DISTINCT d) AS nodes
UNWIND nodes AS n
RETURN a.name, count(DISTINCT n) AS CoverageCount
ORDER BY CoverageCount DESC
LIMIT 5;

// 6. Hãng hàng không độc quyền đường bay trực tiếp giữa 2 thành phố Việt Nam
MATCH (s:Airport {country:'Vietnam'})-[r:ROUTE]->(d:Airport {country:'Vietnam'})
WITH s, d, collect(DISTINCT r.airlineID) AS aids
WHERE size(aids) = 1
MATCH (a:Airline {airlineID: aids[0]})
RETURN a.name AS ExclusiveAirline, s.city AS From, d.city AS To;

// 7. Cặp quốc gia có mức độ kết nối trực tiếp cao nhất
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE s.country <> d.country AND r.stops = 0
WITH s.country AS c1, d.country AS c2, count(r) AS FlightCount
// Sắp xếp tên quốc gia để gộp chiều đi/về (A-B và B-A thành một cặp)
WITH CASE WHEN c1 < c2 THEN c1 ELSE c2 END AS CountryA,
     CASE WHEN c1 < c2 THEN c2 ELSE c1 END AS CountryB,
     sum(FlightCount) AS TotalFlights
RETURN CountryA, CountryB, TotalFlights
ORDER BY TotalFlights DESC
LIMIT 5;

// 8. Cổng Đông Nam Á đi Châu Âu
MATCH (s:Airport)-[r:ROUTE]->(d:Airport)
WHERE s.country IN ['Vietnam', 'Thailand', 'Singapore', 'Malaysia', 'Indonesia', 'Philippines', 'Myanmar', 'Cambodia', 'Laos', 'Brunei', 'Timor-Leste']
  AND d.country IN ['France', 'Germany', 'United Kingdom', 'Italy', 'Spain', 'Netherlands', 'Belgium', 'Switzerland', 'Austria', 'Russia', 'Turkey', 'Denmark', 'Sweden', 'Norway', 'Finland', 'Poland', 'Greece']
RETURN s.name, count(r) AS RoutesToEurope
ORDER BY RoutesToEurope DESC
LIMIT 1;

// 9. Sân bay có độ đa dạng thiết bị bay cao nhất
MATCH (a:Airport)-[r:ROUTE]-()
WHERE r.equipment IS NOT NULL
WITH a, split(r.equipment, ' ') AS types
UNWIND types AS type
RETURN a.name, count(DISTINCT type) AS EquipmentCount
ORDER BY EquipmentCount DESC
LIMIT 5;

// 10. Tìm các "Tam giác" đường bay (A->B->C->A) ngắn nhất
MATCH (a:Airport)-[r1:ROUTE]->(b:Airport)-[r2:ROUTE]->(c:Airport)-[r3:ROUTE]->(a)
WHERE a <> b AND b <> c AND a <> c
WITH a, b, c, (r1.distance + r2.distance + r3.distance) AS TotalDist
RETURN a.name, b.name, c.name, TotalDist
ORDER BY TotalDist ASC
LIMIT 5;

// 11. Từ sân bay Phu cat (6193) bay đến đâu ở Việt Nam?
MATCH (s:Airport {airportID: '6193'})-[r:ROUTE]->(d:Airport {country: 'Vietnam'})
RETURN d.name;

// 12. Đường bay ngắn nhất từ Phu cat (6193) đến Pleiku (6194)
MATCH (s:Airport {airportID: '6193'}), (d:Airport {airportID: '6194'})
MATCH p = shortestPath((s)-[*]->(d))
RETURN [n in nodes(p) | n.name] AS Path;

// 13. Đường bay ngắn nhất từ Danang đến New York (JFK)
MATCH (dad:Airport {city: 'Danang'}), (jfk:Airport {iata: 'JFK'})
MATCH p = shortestPath((dad)-[*]->(jfk))
RETURN [n in nodes(p) | n.name] AS Path;

// 14. Chuyến bay trực tiếp Noi Bai -> Tan Son Nhat
MATCH (s:Airport {airportID: '3199'})-[r:ROUTE]->(d:Airport {airportID: '3205'})
MATCH (a:Airline {airlineID: r.airlineID})
RETURN count(r) AS Count, collect(a.name) AS Airlines;

// 15. Đường bay thẳng Vietnam -> Singapore
MATCH (s:Airport {country: 'Vietnam'})-[r:ROUTE]->(d:Airport {country: 'Singapore'})
RETURN DISTINCT s.name AS From, d.name AS To;

// 16. 5 đường bay ngắn nhất từ Phu Cat đến JFK
// Sử dụng shortestPath với limit (Cypher tiêu chuẩn tìm đường ngắn nhất, muốn k-shortest path thật sự cần GDS hoặc APOC)
// Ở đây dùng mô phỏng tìm các đường ngắn bằng cách mở rộng hop limit
MATCH (s:Airport {airportID: '6193'}), (d:Airport {iata: 'JFK'})
MATCH p = (s)-[*..5]->(d)
RETURN [n in nodes(p) | n.name] AS Path, length(p) AS Hops
ORDER BY Hops ASC
LIMIT 5;

// 17. 10 đường bay ngẫu nhiên từ Phu cat qua đúng 3 sân bay trung chuyển (4 hops)
MATCH p = (s:Airport {airportID: '6193'})-[*4]->(d:Airport)
RETURN [n in nodes(p) | n.name] AS Path
LIMIT 10;

// 18. Phương án mở ít nhất các đường bay ở Vietnam (Phân tích liên thông)
// Kiểm tra số lượng thành phần liên thông (Weakly Connected Components)
// Yêu cầu thư viện GDS (Graph Data Science) được cài đặt.
// Nếu chưa có GDS, dùng query đơn giản đếm số cụm.
CALL gds.wcc.stream({
    nodeQuery: 'MATCH (n:Airport {country: "Vietnam"}) RETURN id(n) AS id',
    relationshipQuery: 'MATCH (n:Airport {country: "Vietnam"})-[r:ROUTE]->(m:Airport {country: "Vietnam"}) RETURN id(n) AS source, id(m) AS target'
})
YIELD nodeId, componentId
RETURN componentId, count(*) AS AirportsInComponent, collect(gds.util.asNode(nodeId).name) AS Airports
ORDER BY AirportsInComponent DESC;

// 19. Đường bay ngắn nhất Vietnam -> Iceland
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'Iceland'})
MATCH p = shortestPath((s)-[*]->(d))
RETURN [n in nodes(p) | n.name] AS Path, length(p) AS Hops
ORDER BY Hops ASC
LIMIT 1;

// 20. Bay từ Vietnam sang US bằng Vietnam Airlines (5309)
MATCH (s:Airport {country: 'Vietnam'}), (d:Airport {country: 'United States'})
MATCH p = shortestPath((s)-[:ROUTE*..6]->(d))
WHERE ALL(r IN relationships(p) WHERE r.airlineID = '5309')
RETURN p IS NOT NULL AS Possible
LIMIT 1;
